import { makeAutoObservable, runInAction, action } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { BibleVerse, Book, BibleVersion, VerseActivityMap } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { bibleBooks } from '@/constants/bibleBooks';
import BibleDBService, { generateVPLId, parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';

// Extend the BibleVersion type to include id
interface ExtendedBibleVersion extends Omit<BibleVersion, 'id'> {
  id: string;
}

// Extend the Book type to include id
interface ExtendedBook extends Omit<Book, 'id'> {
  id: string;
  name: string;
  abbreviation: string;
  chapters: number;
}

// Helper to convert Book to ExtendedBook
const toExtendedBook = (book: Book): ExtendedBook => ({
  ...book,
  id: book.name.toLowerCase().replace(/\s+/g, '-'),
});

// Helper to convert BibleVersion to ExtendedBibleVersion
const toExtendedVersion = (version: BibleVersion): ExtendedBibleVersion => ({
  ...version,
  id: version.englishName.toLowerCase().replace(/\s+/g, '-'),
});

// API Response type
type ApiResponse<T> = {
  data: T;
  // Add other response fields if needed
};

// Storage keys
const STORAGE_KEYS = {
  HIGHLIGHTED_VERSES: 'bible_highlighted_verses',
  BOOKMARKED_VERSES: 'bible_bookmarked_verses',
  LIKED_VERSES: 'bible_liked_verses',
  VERSE_ACTIVITY: 'bible_verse_activity',
  FONT_SIZE: 'bible_font_size',
  SELECTED_VERSION: 'bible_selected_version',
  INSTALLED_VERSIONS: 'bible_installed_versions',
} as const;

class BibleStore {
  // Current state
  currentBook: ExtendedBook | null = null;
  currentChapter: number = 1;
  currentVersion: ExtendedBibleVersion | null = null;
  verses: BibleVerse[] = [];
  searchResults: BibleVerse[] = [];
  
  // Loading states
  isVersesLoading: boolean = false;
  isSearchLoading: boolean = false;
  isInstallingVersion: boolean = false;
  isVersionsLoading: boolean = false;
  
  // Error states
  versesError: string | null = null;
  searchError: string | null = null;
  installError: string | null = null;
  versionsError: string | null = null;
  
  // User interactions
  highlightedVerses: Set<string> = new Set();
  bookmarkedVerses: Set<string> = new Set();
  likedVerses: Set<string> = new Set();
  verseActivity: VerseActivityMap = {};
  
  // UI state
  fontSize: number = 16;
  searchQuery: string = '';
  showSearch: boolean = false;
  showActivityPanel: boolean = false;
  selectedVerseId: string | null = null;
  
  // Bible versions
  installedVersions: string[] = [];
  availableVersions: ExtendedBibleVersion[] = [];
  availableBooks: ExtendedBook[] = [];
  chapterCountByBook: Map<string, number> = new Map();
  
  
  // Local storage
  localVerses: Map<string, BibleVerse[]> = new Map();
  isOffline: boolean = false;

  // Pagination (for compatibility with BibleScreen)
  pagination = {
    currentPage: 1,
    lastPage: 1,
    perPage: 0,
    total: 0,
    hasMore: false,
  };
  
  constructor() {
    makeAutoObservable(this, {
      // Mark actions for MobX
      setCurrentBook: action.bound,
      setCurrentChapter: action.bound,
      setCurrentVersion: action.bound,
      setFontSize: action.bound,
      setSearchQuery: action.bound,
      setShowSearch: action.bound,
      setShowActivityPanel: action.bound,
      setSelectedVerseId: action.bound,
      setIsOffline: action.bound,
      clearErrors: action.bound,
      clearSearch: action.bound,
    });
    
    this.initialize();
  }

  // Fetch available versions and detect installed ones
  async fetchBibleVersions() {
    runInAction(() => {
      this.isVersionsLoading = true;
      this.versionsError = null;
    });

    try {
      await BibleDBService.initialize();

      // Load available list from AsyncStorage (populated by BibleDBService on init)
      let versions: BibleVersion[] = [];
      try {
        const versionsData = await AsyncStorage.getItem('bibleVersions');
        versions = versionsData ? JSON.parse(versionsData) : [];
      } catch {}

      const installedTables = await BibleDBService.getInstalledVersions();
      // Map installed table names to shortName values for UI checks
      const installedShortNames: string[] = [];
      for (const v of versions) {
        if (installedTables.includes(v.tableName)) {
          installedShortNames.push(v.shortName || v.tableName);
        }
      }

      runInAction(() => {
        this.availableVersions = versions.map(v => toExtendedVersion(v));
        this.installedVersions = installedShortNames;
      });
    } catch (error) {
      console.error('Error loading Bible versions:', error);
      runInAction(() => {
        this.versionsError = 'Failed to load Bible versions';
      });
    } finally {
      runInAction(() => {
        this.isVersionsLoading = false;
      });
    }
  }
  
  // Initialization
  private async initialize() {
    try {
      await Promise.all([
        this.loadUserPreferences(),
        this.loadInstalledVersions(),
      ]);
    } catch (error) {
      console.error('Failed to initialize BibleStore:', error);
    }
  }
  
  // State setters
  async setCurrentBook(book: Book) {
    if (!book) return;
    const extendedBook = toExtendedBook(book);

    // If same book is selected, do nothing to avoid loops
    if (this.currentBook?.abbreviation === extendedBook.abbreviation) {
      return;
    }

    // Determine a valid chapter for the new book
    const desiredChapter = this.currentChapter || 1;
    const maxChapter = this.getChapterCount(extendedBook.abbreviation) || extendedBook.chapters || 1;
    const nextChapter = Math.min(Math.max(1, desiredChapter), maxChapter);

    runInAction(() => {
      this.currentBook = extendedBook;
      this.currentChapter = nextChapter;
      this.verses = [];
    });
  }
  
  setCurrentChapter(chapter: number) {
    // Clamp to valid range for current book
    const max = this.getChapterCount();
    const next = Math.min(Math.max(1, chapter), max);
    this.currentChapter = next;
    this.saveUserPreferences();
  }
  
  async setCurrentVersion(version: BibleVersion) {
    if (!version) return;
    
    const extendedVersion = toExtendedVersion(version);
    
    runInAction(() => {
      this.currentVersion = extendedVersion;
      this.verses = [];
    });
    
    // Save selected version to storage
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.SELECTED_VERSION, JSON.stringify(extendedVersion));
    } catch (error) {
      console.error('Error saving selected version:', error);
    }

    // Refresh dynamic books for this version
    try {
      await this.loadAvailableBooks();
      // If no book selected yet, set a sensible default
      if (!this.currentBook && this.availableBooks.length > 0) {
        runInAction(() => {
          this.currentBook = this.availableBooks[0];
          this.currentChapter = 1;
        });
      }
    } catch (e) {
      console.error('Error loading available books for version:', e);
    }
    
    // Reload verses if we have a book and chapter
    if (this.currentBook && this.currentChapter) {
      await this.loadVerses();
    }
  }
  
  setFontSize(size: number) {
    this.fontSize = size;
    AsyncStorage.setItem(STORAGE_KEYS.FONT_SIZE, size.toString());
  }
  
  setSearchQuery(query: string) {
    this.searchQuery = query;
  }
  
  setShowSearch(show: boolean) {
    this.showSearch = show;
  }
  
  setShowActivityPanel(show: boolean) {
    this.showActivityPanel = show;
  }
  
  setSelectedVerseId(id: string | null) {
    this.selectedVerseId = id;
  }
  
  setIsOffline(offline: boolean) {
    this.isOffline = offline;
  }
  
  // Clear state
  clearErrors() {
    this.versesError = null;
    this.searchError = null;
    this.installError = null;
    this.versionsError = null;
  }
  
  clearSearch() {
    this.searchQuery = '';
    this.searchResults = [];
    this.searchError = null;
  }
  
  // Verse fetching (offline-first using local SQLite via BibleDBService)
  async fetchVerses(book: Book, chapter: number, version: BibleVersion, page: number = 1) {
    if (!version) {
      this.versesError = 'No version selected';
      return;
    }

    this.isVersesLoading = true;
    this.versesError = null;

    try {
      // Ensure DB is ready
      await BibleDBService.initialize();

      const extendedBook = toExtendedBook(book);
      const extendedVersion = toExtendedVersion(version);

      // Read chapter from local DB
      const rows = await BibleDBService.getChapter(
        version.tableName,
        book.abbreviation,
        chapter
      );

      const versesArray: BibleVerse[] = rows.map(v => ({
        id: generateVPLId(book.abbreviation, chapter, v.verse),
        text: v.text,
        reference: `${book.name} ${chapter}:${v.verse}`,
      }));

      runInAction(() => {
        this.verses = page === 1 ? versesArray : [...this.verses, ...versesArray];
        this.currentBook = extendedBook;
        this.currentChapter = chapter;
        this.currentVersion = extendedVersion;
        this.pagination = {
          currentPage: 1,
          lastPage: 1,
          perPage: versesArray.length,
          total: versesArray.length,
          hasMore: false,
        };
      });

      // Save a copy for offline cache
      if (versesArray.length > 0) {
        await this.saveLocalVerses(extendedVersion.id, extendedBook.id, chapter, versesArray);
      }

      // Persist last position
      try {
        await AsyncStorage.setItem('bible_last_position', JSON.stringify({
          book: book.abbreviation,
          chapter,
          version: version.tableName,
        }));
      } catch {}
    } catch (error) {
      console.error('Error fetching verses:', error);
      runInAction(() => {
        this.versesError = 'Failed to load verses. Please try again.';
      });
    } finally {
      runInAction(() => {
        this.isVersesLoading = false;
      });
    }
  }

  // Search functionality (local DB)
  async searchVerses(query: string, version?: BibleVersion) {
    if (!query.trim()) {
      this.clearSearch();
      return;
    }

    const searchVersion = version || this.currentVersion;
    if (!searchVersion) {
      this.searchError = 'No version selected for search';
      return;
    }

    this.isSearchLoading = true;
    this.searchError = null;
    this.searchQuery = query;

    try {
      // Ensure DB is ready
      await BibleDBService.initialize();
      const results = await BibleDBService.searchVerses((searchVersion as BibleVersion).tableName, query);
      const mapped: BibleVerse[] = results.map(v => {
        const { bookAbbr, chapter, verse } = parseVPLId(v.verseID);
        const book = bibleBooks.find(b => b.abbreviation === bookAbbr)!;
        return {
          id: v.verseID,
          text: v.verseText,
          reference: `${book.name} ${chapter}:${verse}`,
        };
      });

      runInAction(() => {
        this.searchResults = mapped;
      });
    } catch (error) {
      console.error('Error searching verses:', error);
      runInAction(() => {
        this.searchError = 'Failed to search verses. Please try again.';
        if (this.isOffline) {
          this.searchError += ' You are currently offline.';
        }
      });
    } finally {
      runInAction(() => {
        this.isSearchLoading = false;
      });
    }
  }

  // Version Management
  async installVersion(version: BibleVersion) {
    if (!version) return;

    this.isInstallingVersion = true;
    this.installError = null;

    try {
      // In a real app, this would download and install the Bible version
      // For now, we'll just simulate the installation
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const ext = toExtendedVersion(version);
      runInAction(() => {
        if (!this.installedVersions.includes(ext.id)) {
          this.installedVersions = [...this.installedVersions, ext.id];
          this.saveInstalledVersions();
        }
      });
      
      return true;
    } catch (error) {
      console.error('Error installing version:', error);
      runInAction(() => {
        this.installError = 'Failed to install version. Please try again.';
      });
      return false;
    } finally {
      runInAction(() => {
        this.isInstallingVersion = false;
      });
    }
  }

  private async saveInstalledVersions() {
    try {
      await AsyncStorage.setItem(
        STORAGE_KEYS.INSTALLED_VERSIONS,
        JSON.stringify(this.installedVersions)
      );
    } catch (error) {
      console.error('Error saving installed versions:', error);
    }
  }

  // User Interactions
  async toggleHighlight(verseId: string) {
    try {
      const newSet = new Set(this.highlightedVerses);
      
      if (newSet.has(verseId)) {
        newSet.delete(verseId);
      } else {
        newSet.add(verseId);
      }

      runInAction(() => {
        this.highlightedVerses = newSet;
      });

      // Save to storage
      await AsyncStorage.setItem(
        STORAGE_KEYS.HIGHLIGHTED_VERSES,
        JSON.stringify(Array.from(newSet))
      );

      // Add to sync queue
      this.addToPendingSync('highlight', {
        verseId,
        highlighted: newSet.has(verseId)
      });

      return newSet.has(verseId);
    } catch (error) {
      console.error('Error toggling highlight:', error);
      return false;
    }
  }

  async toggleBookmark(verseId: string) {
    try {
      const newSet = new Set(this.bookmarkedVerses);
      
      if (newSet.has(verseId)) {
        newSet.delete(verseId);
      } else {
        newSet.add(verseId);
      }

      runInAction(() => {
        this.bookmarkedVerses = newSet;
      });

      // Save to storage
      await AsyncStorage.setItem(
        STORAGE_KEYS.BOOKMARKED_VERSES,
        JSON.stringify(Array.from(newSet))
      );

      // Add to sync queue
      this.addToPendingSync('bookmark', {
        verseId,
        bookmarked: newSet.has(verseId)
      });

      return newSet.has(verseId);
    } catch (error) {
      console.error('Error toggling bookmark:', error);
      return false;
    }
  }

  async likeVerse(verseId: string) {
    try {
      const newSet = new Set(this.likedVerses);
      
      if (newSet.has(verseId)) {
        newSet.delete(verseId);
      } else {
        newSet.add(verseId);
      }

      runInAction(() => {
        this.likedVerses = newSet;
      });

      // Save to storage
      await AsyncStorage.setItem(
        STORAGE_KEYS.LIKED_VERSES,
        JSON.stringify(Array.from(newSet))
      );

      // Add to sync queue
      this.addToPendingSync('like', {
        verseId,
        liked: newSet.has(verseId)
      });

      return newSet.has(verseId);
    } catch (error) {
      console.error('Error toggling like:', error);
      return false;
    }
  }

  async shareVerse(verseId: string) {
    try {
      const verse = this.verses.find(v => v.id === verseId);
      if (!verse) return false;

      // In a real app, this would use the Share API
      // For now, we'll just copy to clipboard
      const shareText = `${verse.text}\n- ${verse.reference}`;
      await navigator.clipboard.writeText(shareText);
      
      toast.success('Verse copied to clipboard');
      return true;
    } catch (error) {
      console.error('Error sharing verse:', error);
      toast.error('Failed to share verse');
      return false;
    }
  }

  // Sync Helpers
  private addToPendingSync(action: string, data: any) {
    // In a real app, this would add to a queue for syncing with the server
    // For now, we'll just log it
    console.log(`[Sync] ${action}:`, data);
  }

  // Cleanup method to clear all data
  async clearAllData() {
    try {
      await Promise.all([
        AsyncStorage.removeItem(STORAGE_KEYS.HIGHLIGHTED_VERSES),
        AsyncStorage.removeItem(STORAGE_KEYS.BOOKMARKED_VERSES),
        AsyncStorage.removeItem(STORAGE_KEYS.LIKED_VERSES),
        AsyncStorage.removeItem(STORAGE_KEYS.VERSE_ACTIVITY),
        AsyncStorage.removeItem(STORAGE_KEYS.FONT_SIZE),
        AsyncStorage.removeItem(STORAGE_KEYS.SELECTED_VERSION),
        AsyncStorage.removeItem(STORAGE_KEYS.INSTALLED_VERSIONS),
      ]);
      
      runInAction(() => {
        this.highlightedVerses.clear();
        this.bookmarkedVerses.clear();
        this.likedVerses.clear();
        this.verseActivity = {};
        this.verses = [];
        this.searchResults = [];
        this.fontSize = 16;
        this.currentVersion = null;
        this.currentBook = null;
        this.currentChapter = 1;
      });
      
      return true;
    } catch (error) {
      console.error('Error clearing BibleStore data:', error);
      return false;
    }
  }

  // Getter for computed properties
  get hasVerses() {
    return this.verses.length > 0;
  }

  get hasSearchResults() {
    return this.searchResults.length > 0;
  }

  get currentVerseCount() {
    return this.verses.length;
  }

  // Core Methods
  async loadVerses(forceRefresh = false) {
    if (!this.currentBook || !this.currentVersion || !this.currentChapter) {
      console.warn('Cannot load verses: Missing book, version, or chapter');
      return [];
    }

    const cacheKey = `verse_${this.currentVersion.id}_${this.currentBook.id}_${this.currentChapter}`;
    
    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        const cachedVerses = await AsyncStorage.getItem(cacheKey);
        if (cachedVerses) {
          const parsed = JSON.parse(cachedVerses);
          runInAction(() => {
            this.verses = parsed;
          });
          return parsed;
        }
      } catch (error) {
        console.error('Error loading cached verses:', error);
      }
    }

    // Set loading state
    runInAction(() => {
      this.isVersesLoading = true;
      this.versesError = null;
    });

    try {
      // Simulate API call - replace with actual API call
      // const response = await apiClient.get<ApiResponse<BibleVerse[]>>(
      //   `/verses/${this.currentVersion.id}/${this.currentBook.id}/${this.currentChapter}`
      // );
      
      // Mock data for now
      await new Promise(resolve => setTimeout(resolve, 500));
      const mockVerses: BibleVerse[] = Array.from({ length: 10 }, (_, i) => ({
        id: `${this.currentBook?.id}-${this.currentChapter}-${i + 1}`,
        text: `This is verse ${i + 1} of ${this.currentBook?.name} ${this.currentChapter}`,
        reference: `${this.currentBook?.name} ${this.currentChapter}:${i + 1}`,
      }));

      // Cache the result
      await AsyncStorage.setItem(cacheKey, JSON.stringify(mockVerses));

      runInAction(() => {
        this.verses = mockVerses;
      });

      return mockVerses;
    } catch (error) {
      console.error('Error loading verses:', error);
      runInAction(() => {
        this.versesError = 'Failed to load verses. Please check your connection and try again.';
      });
      return [];
    } finally {
      runInAction(() => {
        this.isVersesLoading = false;
      });
    }
  }

  

  // Helper methods
  async loadAvailableBooks() {
    try {
      if (!this.currentVersion) {
        runInAction(() => {
          this.availableBooks = bibleBooks.map(toExtendedBook);
        });
        return;
      }

      const table = this.currentVersion.tableName;
      const cacheKeyBooks = `bible_books_${table}`;
      const cacheKeyChapters = `bible_chapters_${table}`;

      // 1) Try cache first for instant UI
      try {
        const [cachedBooks, cachedChapters] = await Promise.all([
          AsyncStorage.getItem(cacheKeyBooks),
          AsyncStorage.getItem(cacheKeyChapters),
        ]);
        if (cachedBooks) {
          const parsedBooks: ExtendedBook[] = JSON.parse(cachedBooks);
          runInAction(() => {
            this.availableBooks = parsedBooks;
          });
        }
        if (cachedChapters) {
          const parsedChapters: [string, number][] = JSON.parse(cachedChapters);
          runInAction(() => {
            this.chapterCountByBook = new Map(parsedChapters);
          });
        }
      } catch {}

      // 2) Fetch fresh data from DB (overwrites cache/UI once ready)
      const codes = await BibleDBService.getAvailableBooks(table);

      // Map DB codes to Book entries; fallback to code label if missing
      const mapped: ExtendedBook[] = [];
      for (const code of codes) {
        const found = bibleBooks.find(b => b.abbreviation === code);
        let book: ExtendedBook;
        if (found) {
          book = toExtendedBook(found);
        } else {
          // Unknown code; fetch chapter count dynamically and create a placeholder
          const maxChapter = await BibleDBService.getMaxChapter(table, code);
          book = toExtendedBook({ name: code, abbreviation: code, chapters: maxChapter } as any);
        }
        mapped.push(book);
      }

      // Load chapter counts for known books dynamically for accuracy
      const chapterCounts = new Map<string, number>();
      for (const b of mapped) {
        const maxChapter = await BibleDBService.getMaxChapter(table, b.abbreviation);
        chapterCounts.set(b.abbreviation, maxChapter || b.chapters);
      }

      runInAction(() => {
        this.availableBooks = mapped;
        this.chapterCountByBook = chapterCounts;
      });

      // 3) Save to cache
      try {
        await Promise.all([
          AsyncStorage.setItem(cacheKeyBooks, JSON.stringify(mapped)),
          AsyncStorage.setItem(cacheKeyChapters, JSON.stringify(Array.from(chapterCounts.entries()))),
        ]);
      } catch {}
    } catch (error) {
      console.error('Failed to load available books:', error);
      runInAction(() => {
        this.availableBooks = bibleBooks.map(toExtendedBook);
      });
    }
  }

  getChapterCount(abbr?: string) {
    const code = abbr || this.currentBook?.abbreviation;
    if (!code) return this.currentBook?.chapters || 1;
    return this.chapterCountByBook.get(code) || (this.currentBook?.chapters || 1);
  }
  async loadUserPreferences() {
    try {
      const [fontSize, selectedVersion, highlightedVerses, bookmarkedVerses, likedVerses, verseActivity] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEYS.FONT_SIZE),
        AsyncStorage.getItem(STORAGE_KEYS.SELECTED_VERSION),
        this.loadHighlightedVerses(),
        this.loadBookmarkedVerses(),
        this.loadLikedVerses(),
        this.loadVerseActivity(),
      ]);
      
      // Process the selected version if it exists
      if (selectedVersion) {
        try {
          // Prefer JSON shape
          const versionObj = JSON.parse(selectedVersion);
          if (versionObj) {
            this.currentVersion = toExtendedVersion(versionObj);
          }
        } catch (e) {
          // It might have been stored as a plain ID previously; ignore and let fetchBibleVersions reconcile
        }
      }
    } catch (error) {
      console.error('Error loading user preferences:', error);
    }
  }

  // Placeholder for syncing interactions when online
  async syncUserInteractions() {
    // This app currently logs interactions locally; implement server sync here if needed
    return true;
  }
  
  private async loadInstalledVersions() {
    try {
      const installed = await AsyncStorage.getItem(STORAGE_KEYS.INSTALLED_VERSIONS);
      if (installed) {
        this.installedVersions = JSON.parse(installed);
      }
      
      // Load available versions from API
      const response = await apiClient.get<ApiResponse<ExtendedBibleVersion[]>>('/bible/versions');
      runInAction(() => {
        this.availableVersions = (response as unknown as { data: { data: ExtendedBibleVersion[] } }).data.data || [];
      });
    } catch (error) {
      console.error('Error loading installed versions:', error);
      this.versionsError = 'Failed to load Bible versions';
    }
  }
  
  async saveUserPreferences() {
    try {
      await AsyncStorage.multiSet([
        [STORAGE_KEYS.FONT_SIZE, this.fontSize.toString()],
        [STORAGE_KEYS.SELECTED_VERSION, this.currentVersion ? JSON.stringify(this.currentVersion) : ''],
      ]);
    } catch (error) {
      console.error('Error saving user preferences:', error);
    }
  }
  
  private async loadHighlightedVerses() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.HIGHLIGHTED_VERSES);
      if (stored) {
        this.highlightedVerses = new Set(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Error loading highlighted verses:', error);
    }
  }
  
  private async loadBookmarkedVerses() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.BOOKMARKED_VERSES);
      if (stored) {
        this.bookmarkedVerses = new Set(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Error loading bookmarked verses:', error);
    }
  }
  
  private async loadLikedVerses() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.LIKED_VERSES);
      if (stored) {
        this.likedVerses = new Set(JSON.parse(stored));
      }
    } catch (error) {
      console.error('Error loading liked verses:', error);
    }
  }
  
  private async loadVerseActivity() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.VERSE_ACTIVITY);
      if (stored) {
        this.verseActivity = JSON.parse(stored);
      }
    } catch (error) {
      console.error('Error loading verse activity:', error);
    }
  }
  
  private async saveLocalVerses(version: string, book: string, chapter: number, verses: BibleVerse[]) {
    try {
      const key = `${version}:${book}:${chapter}`;
      this.localVerses.set(key, verses);
      // Optionally save to AsyncStorage for persistence across app restarts
      await AsyncStorage.setItem(`bible_${key}`, JSON.stringify(verses));
    } catch (error) {
      console.error('Error saving local verses:', error);
    }
  }
  
  private async loadLocalVerses(version: string, book: string, chapter: number): Promise<BibleVerse[] | null> {
    try {
      const key = `${version}:${book}:${chapter}`;
      const cached = this.localVerses.get(key);
      if (cached) return cached;
      
      const stored = await AsyncStorage.getItem(`bible_${key}`);
      if (stored) {
        const verses = JSON.parse(stored);
        this.localVerses.set(key, verses);
        return verses;
      }
      return null;
    } catch (error) {
      console.error('Error loading local verses:', error);
      return null;
    }
  }
}

// Create a singleton instance
export const bibleStore = new BibleStore();

// For backward compatibility
export const useBibleStore = () => bibleStore;
export default bibleStore;
