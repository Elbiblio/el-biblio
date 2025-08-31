import { makeAutoObservable, runInAction, action } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { BibleVerse, Book, BibleVersion, VerseActivityMap } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { bibleBooks } from '@/constants/bibleBooks';
import { generateVPLId, parseVPLId } from '@/utils/database';
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
  
  // Local storage
  localVerses: Map<string, BibleVerse[]> = new Map();
  isOffline: boolean = false;
  
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
    
    runInAction(() => {
      this.currentBook = extendedBook;
      this.currentChapter = 1;
      this.verses = [];
    });
    
    await this.loadVerses();
  }
  
  setCurrentChapter(chapter: number) {
    this.currentChapter = chapter;
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
  
  // Verse fetching
  async fetchVerses(book: Book, chapter: number, version: BibleVersion, page: number = 1) {
    if (!version) {
      this.versesError = 'No version selected';
      return;
    }

    this.isVersesLoading = true;
    this.versesError = null;
    
    try {
      const extendedBook = toExtendedBook(book);
      const extendedVersion = toExtendedVersion(version);
      // Try to load from local storage first if offline
      if (this.isOffline) {
        const localVerses = await this.loadLocalVerses(extendedVersion.id, extendedBook.id, chapter);
        if (localVerses && localVerses.length > 0) {
          runInAction(() => {
            this.verses = localVerses;
            this.currentBook = extendedBook;
            this.currentChapter = chapter;
            this.currentVersion = extendedVersion;
          });
          return;
        } else {
          throw new Error('No offline data available');
        }
      }

      // Fetch from API
      const response = await apiClient.get<ApiResponse<BibleVerse[]>>(
        `/bible/${extendedVersion.id}/books/${extendedBook.id}/chapters/${chapter}`, 
        { page }
      );

      runInAction(() => {
        this.verses = (response as unknown as { data: { data: BibleVerse[] } }).data.data || [];
        this.currentBook = extendedBook;
        this.currentChapter = chapter;
        this.currentVersion = extendedVersion;
        
        // Save to local storage for offline access
        if (this.verses.length > 0) {
          this.saveLocalVerses(extendedVersion.id, extendedBook.id, chapter, this.verses);
        }
      });
    } catch (error) {
      console.error('Error fetching verses:', error);
      runInAction(() => {
        this.versesError = 'Failed to load verses. Please try again.';
        if (this.isOffline) {
          this.versesError += ' You are currently offline.';
        }
      });
    } finally {
      runInAction(() => {
        this.isVersesLoading = false;
      });
    }
  }

  // Search functionality
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
      const extVersion = toExtendedVersion(searchVersion as BibleVersion);
      const response = await apiClient.get<ApiResponse<BibleVerse[]>>(
        `/bible/${extVersion.id}/search`,
        { q: query }
      );

      runInAction(() => {
        this.searchResults = (response as unknown as { data: { data: BibleVerse[] } }).data.data || [];
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
  private async loadUserPreferences() {
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
          const version = JSON.parse(selectedVersion);
          if (version) {
            this.currentVersion = toExtendedVersion(version);
          }
        } catch (e) {
          console.error('Error parsing selected version:', e);
        }
      }

      runInAction(() => {
        if (fontSize) {
          this.fontSize = parseInt(fontSize, 10) || 16;
        }
      });
    } catch (error) {
      console.error('Error loading user preferences:', error);
    }
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
  
  private async saveUserPreferences() {
    try {
      await AsyncStorage.multiSet([
        [STORAGE_KEYS.FONT_SIZE, this.fontSize.toString()],
        [STORAGE_KEYS.SELECTED_VERSION, this.currentVersion?.id || ''],
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
