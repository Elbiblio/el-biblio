import { makeAutoObservable, runInAction, action } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { BibleVerse, Book, BibleVersion, VerseActivityMap } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { bibleBooks } from '@/constants/bibleBooks';
import BibleDBService, { generateVPLId, parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import { Share } from 'react-native';
import * as Clipboard from 'expo-clipboard';

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

const DEFAULT_BIBLE_TABLE = 'eng_rv_vpl';

// API Response type
type ApiResponse<T> = {
  data: T;
  // Add other response fields if needed
};

type RemoteBibleSearchMeta = {
  current_page?: number;
  last_page?: number;
  per_page?: number;
  total?: number;
  has_more?: boolean;
};

type RemoteBibleSearchResult = {
  id?: string | number;
  text: string;
  version?: string;
  reference?: string;
  verse_number?: number;
  book?: string | { name?: string; abbreviation?: string };
  chapter?: number;
  verse?: number;
  reference_text?: string;
};

type RemoteBibleSearchResponse = {
  data: RemoteBibleSearchResult[];
  meta?: RemoteBibleSearchMeta;
};

type RemoteVerseComparisonVersion = {
  tableName: string;
  shortName: string;
  englishName: string;
};

type RemoteVerseComparisonEntry = {
  version: RemoteVerseComparisonVersion;
  available: boolean;
  installed: boolean;
  text?: string | null;
  verses?: Array<{
    id?: string | number;
    text: string;
    verse: number;
    chapter: number;
    book: string;
    reference_text?: string;
  }>;
  message?: string | null;
};

type RemoteVerseComparisonReference = {
  formatted: string;
  book: string;
  book_abbreviation?: string;
  chapter: number;
  start_verse: number;
  end_verse?: number;
};

type RemoteVerseComparisonResponse = {
  reference: RemoteVerseComparisonReference;
  comparisons: RemoteVerseComparisonEntry[];
};

export type BibleSearchResult = BibleVerse & {
  bookAbbr?: string;
  chapter?: number;
  verseNumber?: number;
  versionId?: string;
  referenceText?: string;
  source?: 'remote' | 'local';
};

type LocalBibleSearchRow = {
  verseID: string;
  verseText: string;
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
  LAST_POSITION: 'bible_last_position',
  SAVED_SEARCHES: 'bible_saved_searches',
} as const;

type LastReadPosition = {
  book: string;
  chapter: number;
  version?: string;
};

export type HistoryEntry = {
  type: 'search' | 'verse' | 'navigation';
  version: string;
  timestamp: number;
  bookName?: string;
  bookAbbr?: string;
  chapter?: number;
  verse?: number;
  query?: string;
};

export type VerseComparisonItem = {
  versionId: string;
  shortName: string;
  englishName: string;
  text: string;
  source: 'remote' | 'local';
  available: boolean;
  installed: boolean;
};

class BibleStore {
  // Current state
  currentBook: ExtendedBook | null = null;
  currentChapter: number = 1;
  currentVersion: ExtendedBibleVersion | null = null;
  verses: BibleVerse[] = [];
  searchResults: BibleSearchResult[] = [];
  searchMeta: RemoteBibleSearchMeta | null = null;
  savedSearches: string[] = [];
  
  // Loading states
  isVersesLoading: boolean = false;
  isSearchLoading: boolean = false;
  isInstallingVersion: boolean = false;
  isVersionsLoading: boolean = false;
  isHistoryLoading: boolean = false;
  
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
  historyEntries: HistoryEntry[] = [];
  
  // UI state
  fontSize: number = 16;
  searchQuery: string = '';
  showSearch: boolean = false;
  showActivityPanel: boolean = false;
  selectedVerseId: string | null = null;
  shareFallback: boolean = false;
  comparisonResults: VerseComparisonItem[] = [];
  isComparisonLoading: boolean = false;
  comparisonError: string | null = null;
  comparisonReference: string | null = null;
  // Bible versions
  installedVersions: string[] = [];
  installedVersionTables: string[] = [];
  availableVersions: ExtendedBibleVersion[] = [];
  availableBooks: ExtendedBook[] = [];
  chapterCountByBook: Map<string, number> = new Map();

  private currentSearchRequestId: number = 0;
  private lastSavedSearchAt: number = 0;
  private lastSavedSearchQuery: string | null = null;

  // Comparison cache
  comparisonCache: Map<string, VerseComparisonItem[]> = new Map();
  comparisonReferenceCache: Map<string, string> = new Map();

  // Local storage
  localVerses: Map<string, BibleVerse[]> = new Map();
  isOffline: boolean = false;

  // Resume state
  lastReadPosition: LastReadPosition | null = null;
  hasAppliedLastPosition: boolean = false;
  isInitialized: boolean = false;

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
      loadHistory: action.bound,
    });
    
    this.initialize();
  }

  private getVersionSlug(version?: { shortName?: string; tableName?: string } | null): string | null {
    if (!version) {
      return null;
    }

    if (version.tableName) {
      const normalized = version.tableName
        .replace(/^eng[_-]?/, '')
        .replace(/_vpl$/i, '')
        .replace(/[^a-z0-9]+/gi, '')
        .toLowerCase();
      if (normalized) {
        return normalized;
      }
    }

    if (version.shortName) {
      const short = version.shortName.trim().toLowerCase();
      if (short.length >= 3) {
        return short;
      }
    }

    return null;
  }

  private mapRemoteComparisonEntry(entry: RemoteVerseComparisonEntry, installedTables: string[]): VerseComparisonItem | null {
    if (!entry?.version) {
      return null;
    }

    const { version } = entry;
    let versionSlug = this.getVersionSlug(version);
    if (!versionSlug && version.shortName) {
      const short = version.shortName.trim().toLowerCase();
      if (short) {
        versionSlug = short;
      }
    }
    if (!versionSlug && version.englishName) {
      versionSlug = version.englishName.trim().toLowerCase().replace(/[^a-z0-9]+/g, '');
    }
    if (!versionSlug) {
      versionSlug = 'unknown';
    }
    const isInstalled = version.tableName ? installedTables.includes(version.tableName) : false;
    const sourceText = entry.text || (entry.verses?.map(v => v.text).join(' ') ?? null);
    const finalText = sourceText && sourceText.trim().length
      ? sourceText.trim()
      : (entry.message ?? (isInstalled ? 'Not available locally' : 'Version not installed'));

    return {
      versionId: versionSlug,
      shortName: version.shortName,
      englishName: version.englishName,
      text: finalText,
      source: 'remote',
      available: entry.available ?? Boolean(sourceText),
      installed: entry.installed || isInstalled,
    } as VerseComparisonItem;
  }

  private async fetchLocalComparisonEntries(installedTables: string[], verses: number): Promise<VerseComparisonItem[]> {
    if (!this.currentBook || !this.currentChapter) {
      return [];
    }

    const bookAbbr = this.currentBook.abbreviation;
    const deriveSlug = (value?: string | null) => value ? value.trim().toLowerCase().replace(/[^a-z0-9]+/g, '') : null;

    const tasks = this.availableVersions.map(async version => {
      let versionSlug = this.getVersionSlug(version) || deriveSlug(version.tableName) || deriveSlug(version.shortName) || deriveSlug(version.englishName);
      if (!versionSlug) {
        versionSlug = 'unknown';
      }

      const isInstalled = installedTables.includes(version.tableName);
      if (!isInstalled) {
        return {
          versionId: versionSlug,
          shortName: version.shortName,
          englishName: version.englishName,
          text: 'Version not installed',
          source: 'local',
          available: false,
          installed: false,
        } as VerseComparisonItem;
      }

      try {
        const text = await BibleDBService.getVerse(version.tableName, bookAbbr, this.currentChapter!, verses);
        return {
          versionId: versionSlug,
          shortName: version.shortName,
          englishName: version.englishName,
          text: text || 'Not available',
          source: 'local',
          available: !!text,
          installed: true,
        } as VerseComparisonItem;
      } catch (error) {
        console.warn('Failed to fetch local comparison verses', version.tableName, error);
        return {
          versionId: versionSlug,
          shortName: version.shortName,
          englishName: version.englishName,
          text: 'Not available',
          source: 'local',
          available: false,
          installed: true,
        } as VerseComparisonItem;
      }
    });

    return (await Promise.all(tasks)).filter(Boolean) as VerseComparisonItem[];
  }

  private mapRemoteSearchResult(item: RemoteBibleSearchResult): BibleSearchResult | null {
    if (!item || !item.text) {
      return null;
    }

    const referenceText = item.reference_text || item.reference || '';
    const { bookMeta, chapter, verse } = this.resolveRemoteReference(item, referenceText);

    const bookAbbr = bookMeta?.abbreviation;
    const bookName = bookMeta?.name || this.extractReferenceParts(referenceText).bookName || bookAbbr;
    const verseNumber = item.verse_number ?? item.verse ?? verse ?? undefined;

    let reference = referenceText;
    if (!reference) {
      if (bookName && chapter) {
        reference = `${bookName} ${chapter}${verseNumber ? `:${verseNumber}` : ''}`;
      } else if (bookName) {
        reference = bookName;
      } else {
        reference = 'Scripture';
      }
    }

    const idCandidate = item.id ?? referenceText ?? reference;
    const id = typeof idCandidate === 'number' ? `${idCandidate}` : (idCandidate || `${bookAbbr || 'verse'}-${chapter || 0}-${verseNumber || 0}`);

    return {
      id,
      text: item.text,
      reference: reference || 'Scripture',
      bookAbbr,
      chapter: chapter ?? undefined,
      verseNumber,
      versionId: item.version,
      referenceText: referenceText || undefined,
      source: 'remote',
    };
  }

  private mapLocalSearchResult(row: LocalBibleSearchRow): BibleSearchResult | null {
    if (!row || !row.verseID) {
      return null;
    }

    try {
      const { bookAbbr, chapter, verse } = parseVPLId(row.verseID);
      const metadata = this.getBookMetadata(bookAbbr);
      const bookName = metadata?.name || bookAbbr;
      return {
        id: row.verseID,
        text: row.verseText,
        reference: `${bookName} ${chapter}:${verse}`,
        bookAbbr,
        chapter,
        verseNumber: verse,
        versionId: this.currentVersion?.tableName,
        source: 'local',
      };
    } catch (error) {
      console.warn('Failed to map local search row', row.verseID, error);
      return null;
    }
  }

  private shouldStoreSearchQuery(query: string, resultCount: number): boolean {
    const normalized = query.trim();
    if (resultCount <= 0) {
      return false;
    }
    if (normalized.length < 4) {
      return false;
    }

    if (this.lastSavedSearchQuery && this.lastSavedSearchQuery.toLowerCase() === normalized.toLowerCase()) {
      return false;
    }

    const now = Date.now();
    if (this.lastSavedSearchAt && (now - this.lastSavedSearchAt) < 2000) {
      return false;
    }

    return true;
  }

  private resolveRemoteReference(item: RemoteBibleSearchResult, referenceText: string) {
    let bookMeta: ExtendedBook | null = null;
    if (typeof item.book === 'string') {
      bookMeta = this.resolveBookByValue(item.book);
    } else if (item.book?.abbreviation) {
      bookMeta = this.getBookMetadata(item.book.abbreviation) || this.resolveBookByValue(item.book.abbreviation);
    } else if (item.book?.name) {
      bookMeta = this.resolveBookByValue(item.book.name);
    }

    const referenceParts = this.extractReferenceParts(referenceText);
    if (!bookMeta && referenceParts.bookName) {
      bookMeta = this.resolveBookByValue(referenceParts.bookName);
    }

    const chapter = item.chapter ?? referenceParts.chapter ?? undefined;
    const verse = item.verse ?? item.verse_number ?? referenceParts.verse ?? undefined;

    return { bookMeta, chapter, verse };
  }

  private resolveBookByValue(value?: string): ExtendedBook | null {
    if (!value) {
      return null;
    }
    const normalized = value.trim().toLowerCase();
    const found = bibleBooks.find(b => b.name.toLowerCase() === normalized || b.abbreviation.toLowerCase() === normalized);
    return found ? toExtendedBook(found) : null;
  }

  private extractReferenceParts(reference?: string): { bookName?: string; chapter?: number; verse?: number } {
    if (!reference) {
      return {};
    }

    const match = reference.trim().match(/^([0-9I]{0,3}\s*[A-Za-z\. ]+?)\s+(\d+)(?::(\d+))?/);
    if (!match) {
      return {};
    }

    const bookName = match[1]?.trim();
    const chapter = match[2] ? parseInt(match[2], 10) : undefined;
    const verse = match[3] ? parseInt(match[3], 10) : undefined;
    return { bookName, chapter, verse };
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

      const mappedVersions = versions.map(v => toExtendedVersion(v));
      mappedVersions.sort((a, b) => {
        if (a.tableName === DEFAULT_BIBLE_TABLE) return -1;
        if (b.tableName === DEFAULT_BIBLE_TABLE) return 1;
        return a.englishName.localeCompare(b.englishName);
      });

      runInAction(() => {
        this.availableVersions = mappedVersions;
        this.installedVersions = Array.from(new Set(installedShortNames));
        this.installedVersionTables = Array.from(new Set(installedTables));
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

  async loadComparisonForSelectedVerse(forceRefresh: boolean = false) {
    if (!this.selectedVerseId || !this.currentBook || !this.currentChapter || !this.currentVersion) {
      return;
    }

    const { verse } = parseVPLId(this.selectedVerseId);
    const cacheKey = `${this.currentBook.abbreviation}:${this.currentChapter}:${verse}`;

    if (!forceRefresh && this.comparisonCache.has(cacheKey)) {
      runInAction(() => {
        this.comparisonResults = this.comparisonCache.get(cacheKey)!;
        this.comparisonError = null;
        this.comparisonReference = this.comparisonReferenceCache.get(cacheKey) ?? null;
      });
      return;
    }

    runInAction(() => {
      this.isComparisonLoading = true;
      this.comparisonError = null;
    });

    try {
      if (!this.availableVersions.length) {
        await this.fetchBibleVersions();
      }

      const baseVersionSlug = this.getVersionSlug(this.currentVersion);
      const baseVersionTable = this.currentVersion.tableName;
      const installedTables = await BibleDBService.getInstalledVersions();
      const additionalVersionSlugs = this.availableVersions
        .filter(v => v.tableName !== baseVersionTable)
        .map(v => this.getVersionSlug(v))
        .filter((slug): slug is string => Boolean(slug));
      const versionsParam = additionalVersionSlugs.length ? `${additionalVersionSlugs.join(',')},` : undefined;

      let remoteComparisons: VerseComparisonItem[] | null = null;
      let remoteReference: string | undefined = undefined;

      if (!this.isOffline && baseVersionSlug) {
        try {
          const apiResponse = await apiClient.get<RemoteVerseComparisonResponse>(
            endpoints.bible.compare(baseVersionSlug, `${this.currentBook.abbreviation} ${this.currentChapter}:${verse}`),
            versionsParam ? { versions: versionsParam } : undefined
          );

          if (apiResponse.success && apiResponse.data?.comparisons) {
            const payload = apiResponse.data;
            remoteReference = payload.reference?.formatted;
            remoteComparisons = payload.comparisons.map((entry: RemoteVerseComparisonEntry) => this.mapRemoteComparisonEntry(entry, installedTables)).filter(Boolean) as VerseComparisonItem[];
          } else {
            throw new Error(apiResponse.message || 'Remote comparison failed');
          }
        } catch (error) {
          console.warn('Remote verse comparison failed; falling back to local data', error);
        }
      }

      let results: VerseComparisonItem[] = [];
      if (remoteComparisons && remoteComparisons.length) {
        results = remoteComparisons;
      } else {
        results = await this.fetchLocalComparisonEntries(installedTables, verse);
      }

      const referenceText = remoteReference || `${this.currentBook.name} ${this.currentChapter}:${verse}`;

      runInAction(() => {
        this.comparisonResults = results;
        this.comparisonReference = referenceText;
        this.comparisonCache.set(cacheKey, results);
        this.comparisonReferenceCache.set(cacheKey, referenceText);
      });
    } catch (error) {
      console.error('Error loading comparison verses:', error);
      runInAction(() => {
        this.comparisonError = 'Failed to load verse comparison.';
      });
    } finally {
      runInAction(() => {
        this.isComparisonLoading = false;
      });
    }
  }
  
  // Initialization
  private async initialize() {
    try {
      await Promise.all([
        this.loadUserPreferences(),
        this.loadInstalledVersions(),
        this.loadLastReadPosition(),
        this.loadSavedSearches(),
      ]);

      runInAction(() => {
        this.isInitialized = true;
      });
    } catch (error) {
      console.error('Failed to initialize BibleStore:', error);
      runInAction(() => {
        this.isInitialized = false;
      });
    }
  }
  
  // State setters
  async setCurrentBook(book: Book | ExtendedBook) {
    if (!book) return;
    const extendedBook = 'id' in book ? book as ExtendedBook : toExtendedBook(book);

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
    runInAction(() => {
      this.currentChapter = next;
    });
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
      await this.loadVerses(true);
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
    this.searchMeta = null;
    this.isSearchLoading = false;
  }
  
  // Verse fetching (offline-first using local SQLite via BibleDBService)
  async fetchVerses(book: Book | ExtendedBook, chapter: number, version: BibleVersion | ExtendedBibleVersion, page: number = 1) {
    if (!version) {
      this.versesError = 'No version selected';
      return;
    }

    this.isVersesLoading = true;
    this.versesError = null;

    try {
      // Ensure DB is ready
      await BibleDBService.initialize();

      const extendedBook = 'id' in book ? book as ExtendedBook : toExtendedBook(book);
      const extendedVersion = 'id' in version ? version as ExtendedBibleVersion : toExtendedVersion(version);

      const cacheVersionKey = extendedVersion.tableName;
      const cacheBookKey = extendedBook.abbreviation;

      if (page === 1) {
        const cached = await this.loadLocalVerses(cacheVersionKey, cacheBookKey, chapter);
        if (cached && cached.length) {
          runInAction(() => {
            this.verses = cached;
          });
        }
      }

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
        await this.saveLocalVerses(cacheVersionKey, cacheBookKey, chapter, versesArray);
      }

      await BibleDBService.recordHistory({
        type: 'navigation',
        version: extendedVersion.tableName,
        book: extendedBook,
        chapter,
      });

      await this.updateLastReadPosition({
        book: cacheBookKey,
        chapter,
        version: cacheVersionKey,
      });

      runInAction(() => {
        this.hasAppliedLastPosition = true;
      });
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
    const rawQuery = query ?? '';
    const normalizedQuery = rawQuery.trim();

    if (!normalizedQuery) {
      this.clearSearch();
      return;
    }

    const requestId = ++this.currentSearchRequestId;
    const searchVersion = version || this.currentVersion;

    runInAction(() => {
      this.isSearchLoading = true;
      this.searchError = null;
      this.searchMeta = null;
      this.searchQuery = rawQuery;
    });

    let aggregatedResults: BibleSearchResult[] = [];
    let meta: RemoteBibleSearchMeta | null = null;
    let usedSource: 'remote' | 'local' | null = null;

    const trySetResults = (results: BibleSearchResult[], source: 'remote' | 'local', responseMeta?: RemoteBibleSearchMeta | null) => {
      aggregatedResults = results;
      meta = responseMeta ?? null;
      usedSource = source;
    };

    // Attempt remote search first when online or when no version is selected locally
    if (!this.isOffline) {
      try {
        const response = await apiClient.get<RemoteBibleSearchResponse>(endpoints.bible.search, {
          query: normalizedQuery,
          version: searchVersion?.tableName,
          page: 1,
          per_page: 20,
        });

        if (response.success && response.data) {
          const remotePayload = response.data;
          const remoteResults = (remotePayload.data || [])
            .map(item => this.mapRemoteSearchResult(item))
            .filter(Boolean) as BibleSearchResult[];

          trySetResults(remoteResults, 'remote', remotePayload.meta ?? null);
        } else {
          throw new Error(response.message || 'Remote search failed');
        }
      } catch (error) {
        console.warn('Remote Bible search failed, falling back to local search', error);
      }
    }

    // Fallback to local search when remote fails or returns nothing
    if ((!aggregatedResults.length || !usedSource) && searchVersion) {
      try {
        await BibleDBService.initialize();
        const localRows = await BibleDBService.searchVerses(searchVersion.tableName, normalizedQuery);
        const localResults = localRows
          .map(row => this.mapLocalSearchResult(row))
          .filter(Boolean) as BibleSearchResult[];

        trySetResults(localResults, 'local');
      } catch (error) {
        console.error('Local Bible search failed:', error);
      }
    }

    // Persist history and saved searches for successful lookups
    const persistTracking = async () => {
      if (!aggregatedResults.length) {
        return;
      }

      const historyVersion = searchVersion?.tableName ?? (aggregatedResults[0]?.versionId ?? '');
      if (historyVersion) {
        await BibleDBService.recordHistory({
          type: 'search',
          version: historyVersion,
          query: normalizedQuery,
        });
      }

      if (this.shouldStoreSearchQuery(normalizedQuery, aggregatedResults.length)) {
        await this.addSavedSearch(normalizedQuery);
        runInAction(() => {
          this.lastSavedSearchAt = Date.now();
          this.lastSavedSearchQuery = normalizedQuery;
        });
      }
    };

    try {
      await persistTracking();
    } catch (error) {
      console.warn('Failed to persist search tracking:', error);
    }

    if (this.currentSearchRequestId !== requestId) {
      return;
    }

    runInAction(() => {
      this.searchResults = aggregatedResults;
      this.searchMeta = meta;
      this.isSearchLoading = false;
      if (!aggregatedResults.length) {
        this.searchError = this.isOffline
          ? 'No results found while offline. Try again when connected.'
          : 'No results found for that query.';
      }
    });
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

      try {
        const result = await Share.share({ message: shareText });
        if (result.action === Share.sharedAction) {
          toast.success('Verse shared');
          runInAction(() => {
            this.shareFallback = false;
          });
          return true;
        }
        // User dismissed share sheet
        return false;
      } catch (shareError) {
        console.warn('Native Share unavailable, falling back to clipboard', shareError);
        await Clipboard.setStringAsync(shareText);
        runInAction(() => {
          this.shareFallback = true;
        });
        toast.success('Verse copied to clipboard');
        return true;
      }
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
        AsyncStorage.removeItem(STORAGE_KEYS.LAST_POSITION),
        AsyncStorage.removeItem(STORAGE_KEYS.SAVED_SEARCHES),
        AsyncStorage.removeItem('bibleHistory'),
      ]);
      
      runInAction(() => {
        this.highlightedVerses.clear();
        this.bookmarkedVerses.clear();
        this.likedVerses.clear();
        this.verseActivity = {};
        this.verses = [];
        this.searchResults = [];
        this.savedSearches = [];
        this.fontSize = 16;
        this.currentVersion = null;
        this.currentBook = null;
        this.currentChapter = 1;
        this.lastReadPosition = null;
        this.hasAppliedLastPosition = false;
        this.isInitialized = false;
        this.comparisonResults = [];
        this.comparisonReference = null;
        this.comparisonCache.clear();
        this.comparisonReferenceCache.clear();
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
    if (!forceRefresh && this.verses.length > 0) {
      return this.verses;
    }

    await this.fetchVerses(this.currentBook, this.currentChapter, this.currentVersion);
    return this.verses;
  }

  async ensureInitialPassage(forceReload: boolean = false) {
    // Ensure we have a version selected
    let installedTables = this.installedVersionTables;
    if (!installedTables.length) {
      try {
        installedTables = await BibleDBService.getInstalledVersions();
        runInAction(() => {
          this.installedVersionTables = installedTables;
        });
      } catch (error) {
        console.warn('Unable to determine installed Bible versions', error);
        installedTables = [];
      }
    }

    const hasCurrentInstalled = this.currentVersion && installedTables.includes(this.currentVersion.tableName);

    if (!hasCurrentInstalled) {
      if (!this.availableVersions.length) {
        await this.fetchBibleVersions();
      }

      let targetVersion: ExtendedBibleVersion | undefined;

      const defaultVersion = this.availableVersions.find(v => v.tableName === DEFAULT_BIBLE_TABLE);
      if (defaultVersion && installedTables.includes(DEFAULT_BIBLE_TABLE)) {
        targetVersion = defaultVersion;
      } else if (installedTables.length) {
        targetVersion = this.availableVersions.find(v => installedTables.includes(v.tableName));
      } else {
        targetVersion = defaultVersion || this.availableVersions[0];
      }

      if (targetVersion) {
        await this.setCurrentVersion(targetVersion);
      }
    }

    if (!this.currentVersion || !installedTables.includes(this.currentVersion.tableName)) {
      console.warn('Unable to determine a Bible version for initial load');
      return;
    }

    // Ensure books metadata is available
    if (!this.availableBooks.length) {
      await this.loadAvailableBooks();
    }

    // Try to resume last read position first
    if (this.lastReadPosition && !this.hasAppliedLastPosition) {
      const resumed = await this.resumeLastRead(true);
      if (resumed && !forceReload) {
        return;
      }
    }

    if (!this.currentBook && this.availableBooks.length > 0) {
      await this.setCurrentBook(this.availableBooks[0]);
    }

    if (!this.currentBook) {
      console.warn('Unable to determine a book for initial load');
      return;
    }

    if (!this.currentChapter) {
      this.setCurrentChapter(1);
    }

    await this.fetchVerses(this.currentBook, this.currentChapter, this.currentVersion, 1);
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

  get resumeTarget() {
    if (!this.lastReadPosition) {
      return null;
    }

    const { book, chapter } = this.lastReadPosition;
    const currentBookCode = this.currentBook?.abbreviation?.toUpperCase();
    if (currentBookCode === book && this.currentChapter === chapter) {
      return null;
    }

    const isDefaultGenesis = (book === 'GEN' || book === 'GENESIS') && chapter === 1;
    if (isDefaultGenesis) {
      return null;
    }

    const metadata = this.getBookMetadata(book);
    return metadata ? {
      book,
      chapter,
      bookName: metadata.name,
    } : {
      book,
      chapter,
      bookName: book,
    };
  }

  async resumeLastRead(force = false) {
    if (!this.lastReadPosition) {
      return false;
    }

    const { book, chapter, version } = this.lastReadPosition;
    const currentBookCode = this.currentBook?.abbreviation?.toUpperCase();
    if (!force && currentBookCode === book && this.currentChapter === chapter) {
      runInAction(() => {
        this.hasAppliedLastPosition = true;
      });
      return false;
    }

    let targetVersion: ExtendedBibleVersion | undefined;
    if (version) {
      targetVersion = this.availableVersions.find(v => v.tableName === version) ?? targetVersion;
    }

    if (!targetVersion && this.availableVersions.length > 0) {
      targetVersion = this.availableVersions.find(v => v.tableName === DEFAULT_BIBLE_TABLE) || this.availableVersions[0];
    }

    if (targetVersion && (!this.currentVersion || this.currentVersion.tableName !== targetVersion.tableName)) {
      await this.setCurrentVersion(targetVersion);
    }

    const targetBook = this.availableBooks.find(b => b.abbreviation === book) || this.getBookMetadata(book);
    if (!targetBook) {
      return false;
    }

    await this.setCurrentBook(targetBook);
    this.setCurrentChapter(chapter);

    if (this.currentBook && this.currentChapter && this.currentVersion) {
      await this.fetchVerses(this.currentBook, this.currentChapter, this.currentVersion, 1);
    } else {
      runInAction(() => {
        this.hasAppliedLastPosition = true;
      });
    }

    return true;
  }
  async loadUserPreferences() {
    try {
      const [storedFontSize, selectedVersion] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEYS.FONT_SIZE),
        AsyncStorage.getItem(STORAGE_KEYS.SELECTED_VERSION),
      ]);

      await Promise.all([
        this.loadHighlightedVerses(),
        this.loadBookmarkedVerses(),
        this.loadLikedVerses(),
        this.loadVerseActivity(),
      ]);

      if (storedFontSize) {
        const parsed = parseInt(storedFontSize, 10);
        if (!Number.isNaN(parsed)) {
          runInAction(() => {
            this.fontSize = parsed;
          });
        }
      }

      if (selectedVersion) {
        try {
          const versionObj = JSON.parse(selectedVersion);
          if (versionObj) {
            const extended = toExtendedVersion(versionObj);
            runInAction(() => {
              this.currentVersion = extended;
            });
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
        const parsed = JSON.parse(installed);
        runInAction(() => {
          this.installedVersions = parsed;
        });
      }
      
      // Load available versions from API
      const response = await apiClient.get<ApiResponse<ExtendedBibleVersion[]>>('/bible/versions');
      const data = (response as unknown as { data: { data: ExtendedBibleVersion[] } }).data.data || [];
      const sorted = data.slice().sort((a, b) => {
        if (a.tableName === DEFAULT_BIBLE_TABLE) return -1;
        if (b.tableName === DEFAULT_BIBLE_TABLE) return 1;
        return a.englishName.localeCompare(b.englishName);
      });
      runInAction(() => {
        this.availableVersions = sorted.map(toExtendedVersion);
        if (!this.installedVersionTables.includes(DEFAULT_BIBLE_TABLE)) {
          this.installedVersionTables = [DEFAULT_BIBLE_TABLE, ...this.installedVersionTables];
        }
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
        const parsed = JSON.parse(stored);
        runInAction(() => {
          this.highlightedVerses = new Set(parsed);
        });
      }
    } catch (error) {
      console.error('Error loading highlighted verses:', error);
    }
  }
  
  private async loadBookmarkedVerses() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.BOOKMARKED_VERSES);
      if (stored) {
        const parsed = JSON.parse(stored);
        runInAction(() => {
          this.bookmarkedVerses = new Set(parsed);
        });
      }
    } catch (error) {
      console.error('Error loading bookmarked verses:', error);
    }
  }
  
  private async loadLikedVerses() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.LIKED_VERSES);
      if (stored) {
        const parsed = JSON.parse(stored);
        runInAction(() => {
          this.likedVerses = new Set(parsed);
        });
      }
    } catch (error) {
      console.error('Error loading liked verses:', error);
    }
  }
  
  private async loadVerseActivity() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.VERSE_ACTIVITY);
      if (stored) {
        const parsed = JSON.parse(stored);
        runInAction(() => {
          this.verseActivity = parsed;
        });
      }
    } catch (error) {
      console.error('Error loading verse activity:', error);
    }
  }

  async loadSavedSearches() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.SAVED_SEARCHES);
      if (stored) {
        runInAction(() => {
          this.savedSearches = JSON.parse(stored);
        });
      }
    } catch (error) {
      console.error('Error loading saved searches:', error);
    }
  }

  async addSavedSearch(query: string) {
    const trimmed = query.trim();
    if (!trimmed) return;
    const next = [trimmed, ...this.savedSearches.filter(q => q.toLowerCase() !== trimmed.toLowerCase())].slice(0, 20);
    runInAction(() => {
      this.savedSearches = next;
    });
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.SAVED_SEARCHES, JSON.stringify(next));
    } catch (error) {
      console.error('Error saving search query:', error);
    }
  }

  async removeSavedSearch(query: string) {
    const trimmed = query.trim();
    const next = this.savedSearches.filter(q => q.toLowerCase() !== trimmed.toLowerCase());
    runInAction(() => {
      this.savedSearches = next;
    });
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.SAVED_SEARCHES, JSON.stringify(next));
    } catch (error) {
      console.error('Error removing saved search query:', error);
    }
  }

  async clearSavedSearches() {
    runInAction(() => {
      this.savedSearches = [];
    });
    try {
      await AsyncStorage.removeItem(STORAGE_KEYS.SAVED_SEARCHES);
    } catch (error) {
      console.error('Error clearing saved searches:', error);
    }
  }

  async loadHistory(limit: number = 10) {
    runInAction(() => {
      this.isHistoryLoading = true;
    });
    try {
      const raw = await AsyncStorage.getItem('bibleHistory');
      if (!raw) {
        runInAction(() => {
          this.historyEntries = [];
        });
        return;
      }

      const parsed = JSON.parse(raw) as Array<{
        type: 'search' | 'verse' | 'navigation';
        version: string;
        timestamp: number;
        book?: Book;
        chapter?: number;
        verse?: number;
        query?: string;
      }>;

      const entries: HistoryEntry[] = parsed.slice(0, limit).map(entry => {
        const bookAbbr = entry.book?.abbreviation;
        const metadata = bookAbbr ? this.getBookMetadata(bookAbbr) : null;
        return {
          type: entry.type,
          version: entry.version,
          timestamp: entry.timestamp,
          bookName: entry.book?.name || metadata?.name,
          bookAbbr: bookAbbr || metadata?.abbreviation,
          chapter: entry.chapter,
          verse: entry.verse,
          query: entry.query,
        };
      });

      runInAction(() => {
        this.historyEntries = entries;
      });
    } catch (error) {
      console.error('Error loading history entries:', error);
    } finally {
      runInAction(() => {
        this.isHistoryLoading = false;
      });
    }
  }

  async clearHistory() {
    try {
      await AsyncStorage.removeItem('bibleHistory');
      runInAction(() => {
        this.historyEntries = [];
      });
    } catch (error) {
      console.error('Error clearing history entries:', error);
    }
  }

  private async loadLastReadPosition() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.LAST_POSITION);
      if (!stored) {
        return;
      }

      const parsed = JSON.parse(stored) as LastReadPosition;
      if (!parsed?.book || !parsed?.chapter) {
        return;
      }

      runInAction(() => {
        this.lastReadPosition = {
          book: parsed.book.toUpperCase(),
          chapter: Math.max(1, parsed.chapter),
          version: parsed.version,
        };
        this.hasAppliedLastPosition = false;
      });
    } catch (error) {
      console.error('Error loading last read position:', error);
    }
  }

  private async updateLastReadPosition(position: LastReadPosition) {
    const normalized: LastReadPosition = {
      book: position.book.toUpperCase(),
      chapter: Math.max(1, position.chapter),
      version: position.version,
    };

    runInAction(() => {
      this.lastReadPosition = normalized;
    });

    try {
      await AsyncStorage.setItem(STORAGE_KEYS.LAST_POSITION, JSON.stringify(normalized));
    } catch (error) {
      console.error('Error saving last read position:', error);
    }
  }

  private getBookMetadata(bookAbbr: string): ExtendedBook | null {
    if (!bookAbbr) {
      return null;
    }

    const normalized = bookAbbr.toUpperCase();
    const fromAvailable = this.availableBooks.find(b => b.abbreviation === normalized);
    if (fromAvailable) {
      return fromAvailable;
    }

    const fallback = bibleBooks.find(b => b.abbreviation === normalized);
    if (fallback) {
      return toExtendedBook(fallback);
    }

    return null;
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
