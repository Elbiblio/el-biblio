import { makeAutoObservable, runInAction, action } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { BibleVerse, Book, BibleVersion, VerseActivityMap } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { bibleBooks } from '@/constants/bibleBooks';
import BibleDBService, { generateVPLId, parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import { Share } from 'react-native';
import * as Clipboard from 'expo-clipboard';
import { formatVerseShareMessage } from '@/utils/share';
import * as Notifications from 'expo-notifications';
import { estimateChaptersPerDay, DEFAULT_TIME_PER_DAY, DEFAULT_READING_MODE, buildPlanPhases } from '@/constants/readingPlanModes';

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

type ReadingPlanPhase = {
  id: 'reading' | 'meditation' | 'prayer' | 'contemplation';
  label: string;
  minutes: number;
  hint?: string;
};

type ReadingPlanSegment = {
  id: string;
  bookAbbreviation: string;
  bookName: string;
  chapterStart: number;
  chapterEnd: number;
  verseStart?: number | null;
  verseEnd?: number | null;
  completedAt?: string | null;
};

type ReadingPlanMode = 'plain' | 'reading_meditation' | 'lectio_divina';

type BibleReadingPlan = {
  id: string;
  createdAt: string;
  books: string[];
  timePerDay: number;
  readingMode: ReadingPlanMode;
  phases: ReadingPlanPhase[];
  segments: ReadingPlanSegment[];
  currentIndex: number;
  reminderTime?: string | null;
  versionTable: string;
  versionName?: string | null;
};
export type DailyPhaseProgress = {
  id: ReadingPlanPhase['id'];
  label: string;
  plannedSeconds: number;
  elapsedSeconds: number;
};

export type DailyReadingSession = {
  date: string; // YYYY-MM-DD
  planId: string;
  segmentId: string | null;
  bookAbbr?: string | null;
  chapterStart?: number | null;
  chapterEnd?: number | null;
  verseStart?: number | null;
  verseEnd?: number | null;
  phases: DailyPhaseProgress[];
  currentPhaseIndex: number;
  secondsRemainingInPhase: number;
  chaptersCompleted: number;
  completed: boolean;
};

type ReadingReminder = {
  time: string;
  notificationId: string;
};

type ExplainVerseOptions = {
  prompt?: string;
  versionOverride?: string;
};

type CreateReadingPlanParams = {
  books: string[];
  timePerDay: number;
  readingMode: ReadingPlanMode;
  phases: ReadingPlanPhase[];
  reminderTime?: string | null;
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
  READING_PLAN: 'bible_reading_plan',
  READING_REMINDER: 'bible_reading_reminder',
  PLAN_MODE: 'bible_plan_mode',
  SHOW_APOCRYPHA: 'bible_show_apocrypha',
  DAILY_SESSION_PREFIX: 'bible_daily_session_',
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
  readingPlan: BibleReadingPlan | null = null;
  readingReminder: ReadingReminder | null = null;

  // UI state
  fontSize: number = 16;
  searchQuery: string = '';
  showSearch: boolean = false;
  showActivityPanel: boolean = false;
  isInitialized = false;
  selectedVerseId: string | null = null;
  shareFallback: boolean = false;
  comparisonResults: VerseComparisonItem[] = [];
  isComparisonLoading: boolean = false;
  comparisonError: string | null = null;
  comparisonReference: string | null = null;
  aiInsightSections: { title: string; content: string }[] = [];
  aiInsightReference: string | null = null;
  isAIInsightLoading = false;
  aiInsightError: string | null = null;
  // Bible versions
  installedVersions: string[] = [];
  installedVersionTables: string[] = [];
  availableVersions: ExtendedBibleVersion[] = [];
  availableBooks: ExtendedBook[] = [];
  chapterCountByBook: Map<string, number> = new Map();
  showApocrypha: boolean = true;

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
  browsePositionBeforePlan: LastReadPosition | null = null;
  isPlanMode = false;
  dailySession: DailyReadingSession | null = null;

  // Pagination (for compatibility with BibleScreen)
  pagination = {
    currentPage: 1,
    lastPage: 1,
    perPage: 0,
    total: 0,
    hasMore: false,
  };
  
  constructor() {
    makeAutoObservable(this, {}, { autoBind: true });

    this.initialize();
  }

  private getTodayDate(): string {
    try {
      return new Date().toISOString().slice(0, 10);
    } catch {
      const d = new Date();
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${y}-${m}-${day}`;
    }
  }

  private getDailySessionKey(planId: string): string {
    const today = this.getTodayDate();
    return `${STORAGE_KEYS.DAILY_SESSION_PREFIX}${planId}:${today}`;
  }

  async ensureDailySessionPrepared() {
    if (!this.readingPlan || !this.isPlanMode) {
      runInAction(() => {
        this.dailySession = null;
      });
      return;
    }

    const key = this.getDailySessionKey(this.readingPlan.id);

    try {
      const stored = await AsyncStorage.getItem(key);
      if (stored) {
        const parsed = JSON.parse(stored) as DailyReadingSession;
        // Validate phases align with current plan
        const plannedPhases = this.readingPlan.phases;
        const sameShape = parsed.phases.length === plannedPhases.length && parsed.phases.every((p, i) => p.id === plannedPhases[i].id && p.plannedSeconds === plannedPhases[i].minutes * 60);
        runInAction(() => {
          this.dailySession = sameShape ? parsed : null;
        });
      }
    } catch (error) {
      console.warn('Failed to load daily session', error);
    }

    if (!this.dailySession) {
      const phases: DailyPhaseProgress[] = (this.readingPlan.phases || []).map(p => ({
        id: p.id,
        label: p.label,
        plannedSeconds: Math.max(0, (p.minutes || 0) * 60),
        elapsedSeconds: 0,
      }));
      const firstPlanned = phases[0]?.plannedSeconds ?? 0;
      const segment = this.activeReadingSegment;
      const session: DailyReadingSession = {
        date: this.getTodayDate(),
        planId: this.readingPlan.id,
        segmentId: segment?.id ?? null,
        bookAbbr: segment?.bookAbbreviation ?? null,
        chapterStart: segment?.chapterStart ?? null,
        chapterEnd: segment?.chapterEnd ?? null,
        verseStart: segment?.verseStart ?? null,
        verseEnd: segment?.verseEnd ?? null,
        phases,
        currentPhaseIndex: 0,
        secondsRemainingInPhase: firstPlanned,
        chaptersCompleted: 0,
        completed: false,
      };
      await this.saveDailySession(session);
      runInAction(() => {
        this.dailySession = session;
      });
    }
  }

  private async saveDailySession(session: DailyReadingSession | null) {
    if (!this.readingPlan) return;
    const key = this.getDailySessionKey(this.readingPlan.id);
    try {
      if (!session) {
        await AsyncStorage.removeItem(key);
      } else {
        await AsyncStorage.setItem(key, JSON.stringify(session));
      }
    } catch (error) {
      console.warn('Failed to persist daily session', error);
    }
  }

  async applyTimerState(state: { currentPhaseIndex: number; secondsRemainingInPhase: number; phaseSummaries: Array<{ id: DailyPhaseProgress['id']; label: string; plannedSeconds: number; elapsedSeconds: number; }>; }) {
    if (!this.readingPlan) return;
    const segment = this.activeReadingSegment;
    const session: DailyReadingSession = {
      date: this.getTodayDate(),
      planId: this.readingPlan.id,
      segmentId: segment?.id ?? this.dailySession?.segmentId ?? null,
      bookAbbr: segment?.bookAbbreviation ?? this.dailySession?.bookAbbr ?? null,
      chapterStart: segment?.chapterStart ?? this.dailySession?.chapterStart ?? null,
      chapterEnd: segment?.chapterEnd ?? this.dailySession?.chapterEnd ?? null,
      verseStart: segment?.verseStart ?? this.dailySession?.verseStart ?? null,
      verseEnd: segment?.verseEnd ?? this.dailySession?.verseEnd ?? null,
      phases: state.phaseSummaries.map(s => ({ id: s.id, label: s.label, plannedSeconds: s.plannedSeconds, elapsedSeconds: Math.max(0, s.elapsedSeconds) })),
      currentPhaseIndex: Math.max(0, Math.min(state.currentPhaseIndex, (this.readingPlan?.phases.length ?? 1) - 1)),
      secondsRemainingInPhase: Math.max(0, state.secondsRemainingInPhase),
      chaptersCompleted: this.dailySession?.chaptersCompleted ?? 0,
      completed: state.phaseSummaries.length > 0 && state.phaseSummaries.every(p => p.elapsedSeconds >= p.plannedSeconds),
    };
    await this.saveDailySession(session);
    runInAction(() => {
      this.dailySession = session;
    });
  }

  async markTodaySessionCompleted() {
    if (!this.dailySession || !this.readingPlan) return;
    const session = { ...this.dailySession, completed: true, secondsRemainingInPhase: 0 };
    await this.saveDailySession(session);
    runInAction(() => {
      this.dailySession = session;
    });
  }

  async incrementChaptersCompletedBy(count: number) {
    if (!this.dailySession || !this.readingPlan) return;
    const next = { ...this.dailySession, chaptersCompleted: Math.max(0, (this.dailySession.chaptersCompleted || 0) + Math.max(0, count)) };
    await this.saveDailySession(next);
    runInAction(() => {
      this.dailySession = next;
    });
  }

  async startOverPlan() {
    if (!this.readingPlan) return false;

    const segments = this.readingPlan.segments.map(segment => ({
      ...segment,
      completedAt: null,
    }));

    const nextPlan: BibleReadingPlan = {
      ...this.readingPlan,
      segments,
      currentIndex: 0,
      createdAt: new Date().toISOString(),
    };

    await this.saveReadingPlan(nextPlan);
    await this.saveDailySession(null);

    runInAction(() => {
      this.readingPlan = nextPlan;
      this.dailySession = null;
    });

    await this.ensureDailySessionPrepared();
    return true;
  }

  async resetPlanStartDateToToday() {
    if (!this.readingPlan) return false;
    const nextPlan: BibleReadingPlan = {
      ...this.readingPlan,
      createdAt: new Date().toISOString(),
    };
    await this.saveReadingPlan(nextPlan);
    await this.saveDailySession(null);
    runInAction(() => {
      this.readingPlan = nextPlan;
      this.dailySession = null;
    });
    await this.ensureDailySessionPrepared();
    return true;
  }

  async repairPlanToExpectedByToday() {
    if (!this.readingPlan) return false;
    const total = this.readingPlan.segments.length;
    const start = new Date(this.readingPlan.createdAt);
    start.setHours(0,0,0,0);
    const now = new Date();
    now.setHours(0,0,0,0);
    const daysSinceStart = Math.max(1, Math.floor((now.getTime() - start.getTime()) / (24*60*60*1000)) + 1);
    const expectedByToday = Math.min(total, daysSinceStart);
    const nowIso = new Date().toISOString();
    const segments = this.readingPlan.segments.map((segment, index) => ({
      ...segment,
      completedAt: index < expectedByToday ? (segment.completedAt || nowIso) : null,
    }));
    const currentIndex = this.resolveCurrentSegmentIndex(segments);
    const nextPlan: BibleReadingPlan = { ...this.readingPlan, segments, currentIndex };
    await this.saveReadingPlan(nextPlan);
    await this.saveDailySession(null);
    runInAction(() => {
      this.readingPlan = nextPlan;
      this.dailySession = null;
    });
    await this.ensureDailySessionPrepared();
    return true;
  }

  setCurrentBook(book: Book): void;
  setCurrentBook(book: ExtendedBook): void;
  setCurrentBook(book: Book | ExtendedBook) {
    const extended = 'id' in book ? book : toExtendedBook(book);
    this.currentBook = extended;
  }

  setCurrentChapter(chapter: number) {
    this.currentChapter = Math.max(1, Math.floor(chapter || 1));
  }

  get filteredBooks(): ExtendedBook[] {
    if (this.showApocrypha) {
      return this.availableBooks.length ? this.availableBooks : bibleBooks.map(toExtendedBook);
    }

    const baseBooks = this.availableBooks.length ? this.availableBooks : bibleBooks.map(toExtendedBook);
    return baseBooks.filter(book => !this.isApocryphaBook(book.abbreviation));
  }

  setShowApocrypha(show: boolean) {
    this.showApocrypha = show;
    void AsyncStorage.setItem(STORAGE_KEYS.SHOW_APOCRYPHA, show ? '1' : '0').catch(error => {
      console.warn('Failed to persist apocrypha preference', error);
    });

    if (!show && this.currentBook && this.isApocryphaBook(this.currentBook.abbreviation)) {
      const fallback = this.filteredBooks[0];
      if (fallback) {
        this.setCurrentBook(fallback);
        this.setCurrentChapter(1);
      }
    }
  }

  private isApocryphaBook(abbreviation: string): boolean {
    const apocryphaPrefixes = [
      'TOB', 'JDT', 'WIS', 'SIR', 'BAR', 'LJE', '1MA', '2MA', '3MA', '4MA', '1ES', '2ES', 'MAN', 'PS2', 'BEL', 'SUS'
    ];
    const upper = abbreviation.toUpperCase();
    return apocryphaPrefixes.some(prefix => upper.startsWith(prefix));
  }

  setCurrentVersion(version: BibleVersion): void;
  setCurrentVersion(version: ExtendedBibleVersion): void;
  setCurrentVersion(version: BibleVersion | ExtendedBibleVersion) {
    const extended = 'id' in version ? version : toExtendedVersion(version);
    this.currentVersion = extended;
  }

  setCurrentBookByCode(abbreviation: string) {
    if (!abbreviation) return;
    const meta = this.availableBooks.find(book => book.abbreviation === abbreviation)
      || this.getBookMetadata(abbreviation)
      || null;
    if (meta) {
      this.setCurrentBook(meta);
    }
  }

  setFontSize(size: number) {
    const clamped = Math.max(12, Math.min(36, Math.floor(size)));
    this.fontSize = clamped;
    void AsyncStorage.setItem(STORAGE_KEYS.FONT_SIZE, clamped.toString()).catch(error => {
      console.warn('Failed to persist Bible font size', error);
    });
  }

  async loadApocryphaPreference() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.SHOW_APOCRYPHA);
      if (stored === '0') {
        runInAction(() => {
          this.showApocrypha = false;
        });
      }
    } catch (error) {
      console.warn('Failed to load apocrypha preference', error);
    }
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

  clearAIInsights() {
    this.aiInsightSections = [];
    this.aiInsightReference = null;
    this.aiInsightError = null;
    this.isAIInsightLoading = false;
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

  async explainVerse(verse: BibleVerse | null, options?: ExplainVerseOptions) {
    if (!verse) {
      return;
    }

    if (this.isOffline) {
      runInAction(() => {
        this.aiInsightError = 'AI insights require an internet connection.';
        this.aiInsightSections = [];
        this.aiInsightReference = verse.reference ?? null;
      });
      return;
    }

    this.aiInsightReference = verse.reference ?? null;
    this.aiInsightError = null;
    this.isAIInsightLoading = true;
    this.aiInsightSections = [];

    try {
      const verseId = verse.id;
      const reference = verse.reference ?? verseId;
      const verseVersion = (verse as any)?.versionId ?? (verse as any)?.version ?? null;
      const version = options?.versionOverride ?? verseVersion ?? this.currentVersion?.tableName ?? this.readingPlan?.versionTable ?? DEFAULT_BIBLE_TABLE;
      const payload: Record<string, any> = {
        reference,
        text: verse.text?.trim?.() ?? verse.text,
        version,
      };

      const prompt = options?.prompt?.trim();
      if (prompt) {
        payload.prompt = prompt;
      }

      const { success, data, message } = await apiClient.post(endpoints.bible.explain(verseId), payload);
      if (!success || !data) {
        throw new Error(message || 'Unable to generate insight.');
      }

      const sections = this.normalizeInsightPayload(data);
      const normalizedReference = (data as any)?.verse?.reference ?? reference;

      runInAction(() => {
        this.aiInsightReference = normalizedReference ?? reference;
        this.aiInsightSections = sections.length ? sections : [{ title: 'Insight', content: typeof data === 'string' ? data : JSON.stringify(data, null, 2) }];
        this.aiInsightError = null;
      });
    } catch (error) {
      const fallback = error instanceof Error ? error.message : 'Unable to fetch AI insight.';
      console.error('BibleStore.explainVerse error', error);
      runInAction(() => {
        this.aiInsightError = fallback;
        this.aiInsightSections = [];
      });
    } finally {
      runInAction(() => {
        this.isAIInsightLoading = false;
      });
    }
  }

  private normalizeInsightPayload(data: any): { title: string; content: string }[] {
    if (!data) {
      return [];
    }

    if (typeof data === 'string') {
      return [{ title: 'Summary', content: data.trim() }];
    }

    if (Array.isArray(data)) {
      return data
        .map((entry, index) => {
          if (!entry) return null;
          if (typeof entry === 'string') {
            return { title: `Section ${index + 1}`, content: entry.trim() };
          }
          if (typeof entry === 'object') {
            const title = this.humanizeKey(entry.title ?? `Section ${index + 1}`);
            const body = this.serializeInsightContent(entry.content ?? entry.body ?? entry.summary ?? entry.text ?? entry);
            return body ? { title, content: body } : null;
          }
          return null;
        })
        .filter(Boolean) as { title: string; content: string }[];
    }

    if (typeof data === 'object') {
      const entries: { title: string; content: string }[] = [];
      const candidates: Record<string, any> = data;
      const orderedKeys = [
        'summary',
        'quick_insight',
        'deeper_exploration',
        'living_this_out',
        'reflection_questions',
        'universal_human_experience',
        'theological_notes',
        'historical_context',
        'cultural_background',
        'application',
        'practical_application',
        'reflection',
        'prayer',
        'keywords',
      ];

      const keys = new Set([...orderedKeys, ...Object.keys(candidates)]);
      keys.forEach(key => {
        const value = candidates[key];
        if (value === undefined || value === null) return;
        if (key === 'verse') {
          const verseSection = this.normalizeInsightVerseSection(value);
          if (verseSection) {
            entries.push(verseSection);
          }
          return;
        }
        const content = this.serializeInsightContent(value);
        if (!content) return;
        const title = this.humanizeKey(key);
        entries.push({ title, content });
      });

      return entries;
    }

    return [];
  }

  private humanizeKey(key: string): string {
    if (!key) return 'Insight';
    return key
      .replace(/_/g, ' ')
      .replace(/\b\w/g, char => char.toUpperCase())
      .trim();
  }

  private serializeInsightContent(value: any): string {
    if (value === null || value === undefined) {
      return '';
    }
    if (typeof value === 'string') {
      return value.trim();
    }
    if (Array.isArray(value)) {
      return value
        .map(item => {
          if (item === null || item === undefined) {
            return '';
          }
          if (typeof item === 'string') {
            const trimmed = item.trim();
            if (!trimmed) {
              return '';
            }
            return trimmed.startsWith('- ') ? trimmed : `- ${trimmed}`;
          }
          return this.serializeInsightContent(item);
        })
        .filter(Boolean)
        .join('\n\n');
    }
    if (typeof value === 'object') {
      const lines = Object.entries(value)
        .map(([k, v]) => {
          const serialized = this.serializeInsightContent(v);
          const trimmed = serialized.trim();
          if (!trimmed) {
            return '';
          }
          return `${this.humanizeKey(k)}: ${trimmed}`;
        })
        .filter(Boolean);
      return lines.join('\n\n');
    }
    return String(value);
  }

  private normalizeInsightVerseSection(value: any): { title: string; content: string } | null {
    if (!value || typeof value !== 'object') {
      return null;
    }

    const text = typeof value.text === 'string' ? value.text.trim() : '';
    const intention = typeof value.primary_intention === 'string' ? value.primary_intention.trim() : '';
    const discernment = typeof value.discernment_note === 'string' ? value.discernment_note.trim() : '';

    const lines: string[] = [];
    if (text) {
      lines.push(text);
    }
    if (intention) {
      lines.push(`Primary Intention: ${this.humanizeKey(intention)}`);
    }
    if (discernment) {
      lines.push(`Discernment Note: ${discernment}`);
    }

    if (!lines.length) {
      return null;
    }

    return {
      title: 'Verse Insight',
      content: lines.join('\n\n'),
    };
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
        this.loadAvailableBooks(),
        this.loadInstalledVersions(),
        this.loadUserPreferences(),
        this.loadSavedSearches(),
        this.loadReadingPlan(),
        this.loadReadingReminder(),
        this.loadApocryphaPreference(),
      ]);

      runInAction(() => {
        this.isInitialized = true;
      });
    } catch (error) {
      console.error('Failed to initialize BibleStore', error);
    }
  }

  async loadReadingReminder() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.READING_REMINDER);
      if (!stored) {
        runInAction(() => {
          this.readingReminder = null;
        });
        return;
      }

      const parsed = JSON.parse(stored) as ReadingReminder;
      runInAction(() => {
        this.readingReminder = parsed;
      });
    } catch (error) {
      console.error('Failed to load reading reminder', error);
      runInAction(() => {
        this.readingReminder = null;
      });
    }
  }

  private async savePlanModePreference(enabled: boolean) {
    try {
      if (enabled) {
        await AsyncStorage.setItem(STORAGE_KEYS.PLAN_MODE, 'true');
      } else {
        await AsyncStorage.removeItem(STORAGE_KEYS.PLAN_MODE);
      }
    } catch (error) {
      console.warn('Failed to persist plan mode preference', error);
    }
  }

  private setPlanModeState(enabled: boolean) {
    this.isPlanMode = enabled;
  }

  async loadPlanModePreference() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.PLAN_MODE);
      runInAction(() => {
        this.isPlanMode = stored === 'true';
      });
    } catch (error) {
      console.warn('Failed to load plan mode preference', error);
      runInAction(() => {
        this.isPlanMode = false;
      });
    }
  }

  enablePlanMode() {
    if (!this.readingPlan) {
      return;
    }
    if (!this.isPlanMode) {
      this.captureBrowsePosition();
    }
    runInAction(() => {
      this.setPlanModeState(true);
    });
    void this.savePlanModePreference(true);
  }

  disablePlanMode() {
    if (!this.isPlanMode) {
      return;
    }
    runInAction(() => {
      this.setPlanModeState(false);
    });
    void this.savePlanModePreference(false);
  }

  togglePlanMode() {
    if (this.isPlanMode) {
      this.disablePlanMode();
    } else {
      this.enablePlanMode();
    }
  }

  private captureBrowsePosition() {
    if (!this.currentBook) {
      return;
    }
    this.browsePositionBeforePlan = {
      book: this.currentBook.abbreviation,
      chapter: this.currentChapter,
      version: this.currentVersion?.tableName,
    };
  }

  async focusPlanSegment(segmentId?: string) {
    if (!this.readingPlan) {
      return false;
    }

    const segment = segmentId
      ? this.readingPlan.segments.find(item => item.id === segmentId) ?? null
      : this.activeReadingSegment;

    if (!segment) {
      return false;
    }

    if (!this.currentVersion || this.currentVersion.tableName !== this.readingPlan.versionTable) {
      if (!this.availableVersions.length) {
        await this.fetchBibleVersions();
      }
      const targetVersion = this.availableVersions.find(v => v.tableName === this.readingPlan?.versionTable);
      if (targetVersion) {
        this.setCurrentVersion(targetVersion);
      }
    }

    if (!this.currentVersion) {
      return false;
    }

    if (!this.availableBooks.length) {
      await this.loadAvailableBooks();
    }

    const bookMeta = this.availableBooks.find(b => b.abbreviation === segment.bookAbbreviation)
      || this.getBookMetadata(segment.bookAbbreviation)
      || null;

    if (!bookMeta) {
      console.warn('Plan segment book not found', segment.bookAbbreviation);
      return false;
    }

    this.setCurrentBook(bookMeta);
    this.setCurrentChapter(segment.chapterStart);

    if (this.currentBook && this.currentVersion) {
      await this.fetchVerses(this.currentBook, this.currentChapter, this.currentVersion, 1);
    }

    return true;
  }

  async restoreBrowsePosition() {
    const target = this.browsePositionBeforePlan || this.lastReadPosition;
    if (!target) {
      return false;
    }

    if (target.version && (!this.currentVersion || this.currentVersion.tableName !== target.version)) {
      if (!this.availableVersions.length) {
        await this.fetchBibleVersions();
      }
      const versionMatch = this.availableVersions.find(v => v.tableName === target.version);
      if (versionMatch) {
        this.setCurrentVersion(versionMatch);
      }
    }

    if (!this.currentVersion) {
      return false;
    }

    if (!this.availableBooks.length) {
      await this.loadAvailableBooks();
    }

    const bookMeta = this.availableBooks.find(b => b.abbreviation === target.book)
      || this.getBookMetadata(target.book)
      || null;

    if (!bookMeta) {
      console.warn('Browse position book not found', target.book);
      return false;
    }

    this.setCurrentBook(bookMeta);
    this.setCurrentChapter(target.chapter);

    if (this.currentBook && this.currentVersion) {
      await this.fetchVerses(this.currentBook, this.currentChapter, this.currentVersion, 1);
    }

    return true;
  }

  // Bible Studio plan helpers
  get activeReadingSegment(): ReadingPlanSegment | null {
    if (!this.readingPlan) {
      return null;
    }
    return this.readingPlan.segments[this.readingPlan.currentIndex] ?? null;
  }

  get readingPlanProgress() {
    if (!this.readingPlan) {
      return { completed: 0, total: 0 };
    }
    const completed = this.readingPlan.segments.filter(segment => !!segment.completedAt).length;
    const total = this.readingPlan.segments.length;
    return { completed, total };
  }

  get upcomingSegments(): ReadingPlanSegment[] {
    if (!this.readingPlan) {
      return [];
    }
    return this.readingPlan.segments.slice(this.readingPlan.currentIndex, this.readingPlan.currentIndex + 5);
  }

  async loadReadingPlan() {
    try {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.READING_PLAN);
      if (!stored) {
        runInAction(() => {
          this.readingPlan = null;
        });
        return;
      }

      const parsed = JSON.parse(stored) as BibleReadingPlan;
      runInAction(() => {
        this.readingPlan = parsed;
      });
    } catch (error) {
      console.error('Failed to load reading plan', error);
      runInAction(() => {
        this.readingPlan = null;
      });
    }
  }

  async createReadingPlan(params: CreateReadingPlanParams) {
    if (!params.books?.length) {
      throw new Error('Please choose at least one book for your plan.');
    }
    if (!params.timePerDay || params.timePerDay <= 0) {
      throw new Error('Please choose a daily time goal for your plan.');
    }

    const timePerDay = Math.max(1, Math.floor(params.timePerDay));
    const chaptersPerDay = Math.max(1, estimateChaptersPerDay(timePerDay));
    const versionTable = this.currentVersion?.tableName ?? DEFAULT_BIBLE_TABLE;
    const versionName = this.currentVersion?.englishName ?? this.currentVersion?.shortName ?? null;

    const segments = this.buildReadingSegments(params.books, chaptersPerDay);
    const plan: BibleReadingPlan = {
      id: `plan-${Date.now()}`,
      createdAt: new Date().toISOString(),
      books: params.books,
      timePerDay,
      readingMode: params.readingMode,
      phases: params.phases,
      segments,
      currentIndex: this.resolveCurrentSegmentIndex(segments),
      reminderTime: params.reminderTime ?? null,
      versionTable,
      versionName,
    };

    await this.saveReadingPlan(plan);
    runInAction(() => {
      this.readingPlan = plan;
    });

    if (params.reminderTime) {
      await this.setReadingReminder(params.reminderTime);
    }

    return plan;
  }

  async togglePlanSegmentCompletion(segmentId: string) {
    if (!this.readingPlan) return;

    const segments = this.readingPlan.segments.map(segment => {
      if (segment.id !== segmentId) return segment;
      const isCompleted = Boolean(segment.completedAt);
      return {
        ...segment,
        completedAt: isCompleted ? null : new Date().toISOString(),
      };
    });

    const currentIndex = this.resolveCurrentSegmentIndex(segments);
    const nextPlan: BibleReadingPlan = {
      ...this.readingPlan,
      segments,
      currentIndex,
    };

    await this.saveReadingPlan(nextPlan);
    runInAction(() => {
      this.readingPlan = nextPlan;
    });
  }

  async markSegmentComplete(segmentId: string) {
    if (!this.readingPlan) {
      return false;
    }

    const segments = this.readingPlan.segments.map(segment => {
      if (segment.id !== segmentId) {
        return segment;
      }
      if (segment.completedAt) {
        return segment;
      }
      return {
        ...segment,
        completedAt: new Date().toISOString(),
      };
    });

    const currentIndex = this.resolveCurrentSegmentIndex(segments);
    const nextPlan: BibleReadingPlan = {
      ...this.readingPlan,
      segments,
      currentIndex,
    };

    await this.saveReadingPlan(nextPlan);
    runInAction(() => {
      this.readingPlan = nextPlan;
    });

    if (currentIndex < segments.length) {
      void this.focusPlanSegment(segments[currentIndex].id);
    }

    return true;
  }

  async clearReadingPlan() {
    await this.saveReadingPlan(null);
    runInAction(() => {
      this.readingPlan = null;
      this.browsePositionBeforePlan = null;
    });
    this.disablePlanMode();
  }

  async setReadingReminder(time: string | null) {
    if (!time) {
      if (this.readingReminder?.notificationId) {
        await this.cancelReadingReminder(this.readingReminder.notificationId);
      }
      await this.saveReadingReminder(null);
      runInAction(() => {
        this.readingReminder = null;
        if (this.readingPlan) {
          this.readingPlan = { ...this.readingPlan, reminderTime: null };
        }
      });
      return;
    }

    const notificationId = await this.scheduleReadingReminder(time);
    if (!notificationId) return;

    const reminder: ReadingReminder = {
      time,
      notificationId,
    };

    await this.saveReadingReminder(reminder);

    runInAction(() => {
      this.readingReminder = reminder;
      if (this.readingPlan) {
        this.readingPlan = { ...this.readingPlan, reminderTime: time };
      }
    });
  }

  private buildReadingSegments(bookInputs: string[], chaptersPerDay: number): ReadingPlanSegment[] {
    const segments: ReadingPlanSegment[] = [];

    bookInputs.forEach(bookInput => {
      const book = this.resolveBookMeta(bookInput);
      if (!book) return;

      let chapter = 1;
      const totalChapters = book.chapters;
      while (chapter <= totalChapters) {
        const start = chapter;
        const end = Math.min(totalChapters, chapter + chaptersPerDay - 1);
        segments.push({
          id: `${book.abbreviation}-${start}-${end}`,
          bookAbbreviation: book.abbreviation,
          bookName: book.name,
          chapterStart: start,
          chapterEnd: end,
          completedAt: null,
        });
        chapter = end + 1;
      }
    });

    return segments;
  }

  private resolveBookMeta(input: string) {
    const normalized = input.trim().toLowerCase();
    return bibleBooks.find(book =>
      book.abbreviation.toLowerCase() === normalized || book.name.toLowerCase() === normalized
    );
  }

  private resolveCurrentSegmentIndex(segments: ReadingPlanSegment[]) {
    const nextIndex = segments.findIndex(segment => !segment.completedAt);
    return nextIndex === -1 ? segments.length : nextIndex;
  }

  private async saveReadingPlan(plan: BibleReadingPlan | null) {
    if (!plan) {
      await AsyncStorage.removeItem(STORAGE_KEYS.READING_PLAN);
      return;
    }
    await AsyncStorage.setItem(STORAGE_KEYS.READING_PLAN, JSON.stringify(plan));
  }

  private async saveReadingReminder(reminder: ReadingReminder | null) {
    if (!reminder) {
      await AsyncStorage.removeItem(STORAGE_KEYS.READING_REMINDER);
      return;
    }
    await AsyncStorage.setItem(STORAGE_KEYS.READING_REMINDER, JSON.stringify(reminder));
  }

  private async scheduleReadingReminder(time: string): Promise<string | null> {
    try {
      const [hour, minute] = this.parseReminderTime(time);
      const { status } = await Notifications.getPermissionsAsync();
      let permissionStatus = status;
      if (status !== 'granted') {
        const request = await Notifications.requestPermissionsAsync();
        permissionStatus = request.status;
      }
      if (permissionStatus !== 'granted') {
        toast.error('Notification permissions are required for reading reminders.');
        return null;
      }

      if (this.readingReminder?.notificationId) {
        await this.cancelReadingReminder(this.readingReminder.notificationId);
      }

      const trigger: Notifications.DailyTriggerInput = {
        hour,
        minute,
        type: Notifications.SchedulableTriggerInputTypes.DAILY,
      };

      const notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Bible Studio — Reading Reminder',
          body: 'Take a moment to sit with today’s reading plan.',
          sound: true,
        },
        trigger,
      });

      return notificationId;
    } catch (error) {
      console.error('Failed to schedule reading reminder', error);
      toast.error('Unable to schedule the reading reminder.');
      return null;
    }
  }

  private async cancelReadingReminder(notificationId: string) {
    try {
      await Notifications.cancelScheduledNotificationAsync(notificationId);
    } catch (error) {
      console.error('Failed to cancel reading reminder', error);
    }
  }

  private parseReminderTime(time: string): [number, number] {
    const trimmed = time.trim();
    const parts = trimmed.split(':');
    if (parts.length < 2) {
      throw new Error('Reminder time must be in HH:MM format.');
    }
    const hour = Math.min(23, Math.max(0, Number(parts[0])));
    const minute = Math.min(59, Math.max(0, Number(parts[1])));
    return [hour, minute];
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
      const shareText = formatVerseShareMessage({
        text: verse.text,
        reference: verse.reference,
      });

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
    const fallbackBooks = bibleBooks.map(toExtendedBook);
    try {

      if (!this.currentVersion) {
        runInAction(() => {
          this.availableBooks = fallbackBooks;
          this.chapterCountByBook = new Map(fallbackBooks.map(book => [book.abbreviation, book.chapters]));
        });
        return;
      }

      const table = this.currentVersion.tableName;
      const cacheKeyBooks = `bible_books_${table}`;
      const cacheKeyChapters = `bible_chapters_${table}`;

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
      } catch {
        // Ignore cache hydration failures and continue with fresh load
      }

      const codes = await BibleDBService.getAvailableBooks(table);
      const mapped: ExtendedBook[] = [];

      for (const code of codes) {
        const found = bibleBooks.find(b => b.abbreviation === code);
        if (found) {
          mapped.push(toExtendedBook(found));
        } else {
          const maxChapter = await BibleDBService.getMaxChapter(table, code);
          mapped.push(toExtendedBook({ name: code, abbreviation: code, chapters: maxChapter || 1 } as Book));
        }
      }

      const effectiveBooks = mapped.length ? mapped : fallbackBooks;
      const chapterEntries: [string, number][] = effectiveBooks.map(book => [book.abbreviation, book.chapters]);

      runInAction(() => {
        this.availableBooks = effectiveBooks;
        this.chapterCountByBook = new Map(chapterEntries);
      });

      await AsyncStorage.multiSet([
        [cacheKeyBooks, JSON.stringify(effectiveBooks)],
        [cacheKeyChapters, JSON.stringify(chapterEntries)],
      ]);
    } catch (error) {
      console.error('Failed to load available books', error);
      runInAction(() => {
        this.availableBooks = fallbackBooks;
        this.chapterCountByBook = new Map(fallbackBooks.map(book => [book.abbreviation, book.chapters]));
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
