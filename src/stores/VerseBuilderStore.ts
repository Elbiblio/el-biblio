import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { VerseResult, VerseMastery, UserLevel, PowerUpType } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';
import { parseVPLId } from '@/utils/database';
import BibleDBService from '@/utils/database';
import { shuffleArray } from '@/utils/helpers';
import { VerseStore } from './VerseStore';
import { GameStore } from './GameStore';

const INITIAL_TIME = 16;
const MIN_TIME = 10;
const WORDS_BY_LEVEL: Record<UserLevel, [number, number]> = {
  novice: [3, 3],
  beginner: [4, 5],
  intermediate: [6, 7],
  advanced: [7, 8],
  expert: [9, 10],
};

export type VerseGame = {
  id: string;
  text: string;
  reference: string;
  originalWords: string[];
  poolWords: string[];
  arrangedWords: string[];
  mastery: VerseMastery;
  prefilledCount: number;
};


interface VerseBuilderState {
  gameState: VerseGame | null;
  nextGameState: VerseGame | null;
  isTransitioning: boolean;
  timeLeft: number;
  initialGameTime: number;
  score: number;
  highScore: number;
  powerUps: { grace: number; discernment: number };
  isPlaying: boolean;
  streak: number;
  userLevel: UserLevel;
  showSuccess: boolean;
  showCorrectAnswer: boolean;
  error: string | null;
  wordsToLeave: number;
  userProgress: Record<string, VerseMastery>;
  selectedVersion: string;
  availableVersions: string[];
  recentVerseCacheKey?: string;
}

const initialState: VerseBuilderState = {
  gameState: null,
  nextGameState: null,
  isTransitioning: false,
  timeLeft: INITIAL_TIME,
  initialGameTime: INITIAL_TIME,
  score: 0,
  highScore: 0,
  powerUps: { grace: 3, discernment: 2 },
  isPlaying: false,
  streak: 0,
  userLevel: 'novice',
  showSuccess: false,
  showCorrectAnswer: false,
  error: null,
  wordsToLeave: 3,
  userProgress: {},
  selectedVersion: 'RV',
  availableVersions: ['ASV', 'KJV', 'RV', 'AMP', 'WEB', 'BSB', 'YLT', 'DR'],
  recentVerseCacheKey: 'vb_recent_verses',
};

export class VerseBuilderStore {
  state: VerseBuilderState = initialState;

  // Common store props
  isLoading = false;
  private isInitializing = false;
  error: string | null = null;
  private storageKey = 'verse_builder_store';

  private verseStore: VerseStore;
  private gameStore: GameStore;
  private verseQueue: VerseGame[] = [];

  constructor(verseStore: VerseStore, gameStore: GameStore) {
    this.state = initialState;
    this.storageKey = 'verse_builder_store';
    this.verseStore = verseStore;
    this.gameStore = gameStore;
    makeAutoObservable(this);
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading verse builder store from storage:', error);
    });
  }

  private setLoading = (value: boolean) => {
    this.isLoading = value;
  };

  private setError = (message: string | null) => {
    this.error = message;
  };

  private async saveToStorage() {
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }

  // Game Initialization and Setup
  initialize = async () => {
    if (this.isInitializing) return;
    this.isInitializing = true;
    this.setLoading(true);
    try {
      await this.loadVerseBatch();
      await this.startNewRound();
    } finally {
      this.setLoading(false);
      this.isInitializing = false;
      await this.saveToStorage();
    }
  }

  // Resolve a display code like 'RV'/'KJV' to a DB table name like 'eng_rv_vpl'
  private async resolveTableName(code: string): Promise<string> {
    try {
      if (!code) return 'eng_rv_vpl';
      // If it already looks like a table name, return as-is
      if (code.includes('_')) return code;
      const versionsData = await AsyncStorage.getItem('bibleVersions');
      if (versionsData) {
        const versions = JSON.parse(versionsData) as Array<{ shortName?: string; tableName: string; englishName?: string }>;
        const found = versions.find(v => v.shortName?.toUpperCase() === code.toUpperCase());
        if (found?.tableName) return found.tableName;
      }
    } catch {}
    return 'eng_rv_vpl';
  }

  private async loadVerseBatch() {
    if (!this.state.selectedVersion) return;

    try {
      console.log('[VerseBuilder] Loading verses for version', this.state.selectedVersion);
      const primaryTable = await this.resolveTableName(this.state.selectedVersion);
      let verses = await BibleDBService.getRandomVerses(primaryTable, 40);

      // Filter out verses seen within the last 30 days
      const cacheKey = this.state.recentVerseCacheKey || 'vb_recent_verses';
      const cacheRaw = (await AsyncStorage.getItem(cacheKey)) || '{}';
      const cache: Record<string, number> = JSON.parse(cacheRaw);
      const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000;
      const now = Date.now();
      const recent = new Set(
        Object.entries(cache)
          .filter(([_, ts]) => now - (ts as number) < THIRTY_DAYS)
          .map(([id]) => id)
      );

      let processedVerses = verses
        .map(this.processVerse)
        .filter((v): v is VerseGame => !!v)
        .filter((v) => !recent.has(v.id));

      // Fallback: if no verses found for current version, try common alternatives
      if (processedVerses.length === 0) {
        const fallbacks = ['KJV', 'ASV', 'WEB', 'BSB', 'YLT', 'DR'];
        for (const v of fallbacks) {
          if (v === this.state.selectedVersion) continue;
          // eslint-disable-next-line no-console
          console.log('[VerseBuilder] No verses for version', this.state.selectedVersion, 'trying', v);
          try {
            const altTable = await this.resolveTableName(v);
            const alt = await BibleDBService.getRandomVerses(altTable, 40);
            const proc = alt.map(this.processVerse).filter(Boolean) as VerseGame[];
            if (proc.length > 0) {
              runInAction(() => {
                this.state.selectedVersion = v;
              });
              processedVerses = proc;
              break;
            }
          } catch {}
        }
      }

      this.verseQueue = processedVerses;

      if (processedVerses.length === 0) {
        throw new Error('No suitable verses found for the available versions');
      }
    } catch (err) {
      console.error('Failed to load verse batch:', err);
      runInAction(() => {
        this.state.error = 'Failed to load verses. Please try again.';
      });
      await this.saveToStorage();
    }
  }

  private processVerse = (verse: VerseResult | null): VerseGame | null => {
    if (!verse?.verseID || !verse.verseText) return null;
    try {
      const { bookAbbr, chapter, verse: v } = parseVPLId(verse.verseID);
      // Normalize DB abbreviations to our constants list
      const abbrAlias: Record<string, string> = {
        MAR: 'MRK', // Mark
      };
      const normalizedAbbr = abbrAlias[bookAbbr] || bookAbbr;
      const book = bibleBooks.find((b) => b.abbreviation === normalizedAbbr);
      if (!book) throw new Error(`Invalid book abbreviation: ${bookAbbr}`);
      const words = verse.verseText.split(' ').filter((w: string) => w.length > 0);
      const mastery = this.state.userProgress[verse.verseID] || {
        verseId: verse.verseID,
        attempts: 0,
        correct: 0,
        lastAttempt: 0,
        needsReview: true,
      };
      return {
        id: verse.verseID,
        text: verse.verseText,
        reference: `${book.name} ${chapter}:${v}`,
        originalWords: words,
        poolWords: [],
        arrangedWords: [],
        mastery,
        prefilledCount: 0,
      };
    } catch (err) {
      console.error('processVerse error:', err);
      return null;
    }
  };

  // Gameplay Actions
  startNewRound = async () => {
    console.log('[VerseBuilder] Starting new round');
    runInAction(() => {
      this.state.error = null;
    });
    await this.saveToStorage();

    // Prevent re-entrancy while a round is already active and not transitioning
    if (this.state.isPlaying && this.state.gameState && !this.state.isTransitioning) {
      console.log('[VerseBuilder] Ignoring startNewRound because a round is active');
      return;
    }

    if (this.verseQueue.length === 0) {
      await this.loadVerseBatch();
    }

    const verse = this.verseQueue.shift();
    if (!verse) {
      runInAction(() => {
        this.state.error = 'Failed to get next verse';
      });
      await this.saveToStorage();
      return;
    }

    const totalWords = verse.originalWords.length;
    const leaveCount = Math.min(this.state.wordsToLeave, totalWords - 1);
    const prefilledCount = totalWords - leaveCount;
    const arrangedWords = verse.originalWords.slice(0, prefilledCount);
    const poolWords = shuffleArray(verse.originalWords.slice(prefilledCount));

    const newGameState: VerseGame = {
      ...verse,
      poolWords,
      arrangedWords,
      prefilledCount,
    };

    runInAction(() => {
      if (!this.state.gameState) {
        this.state.gameState = newGameState;
      } else {
        this.state.nextGameState = newGameState;
        this.state.isTransitioning = true;
      }
      this.state.timeLeft = this.state.initialGameTime;
      this.state.isPlaying = true;
      this.state.showSuccess = false;
      this.state.showCorrectAnswer = false;
    });
    // Record this verse in recent cache
    try {
      const cacheKey = this.state.recentVerseCacheKey || 'vb_recent_verses';
      const cacheRaw = (await AsyncStorage.getItem(cacheKey)) || '{}';
      const cache: Record<string, number> = JSON.parse(cacheRaw);
      cache[newGameState.id] = Date.now();
      await AsyncStorage.setItem(cacheKey, JSON.stringify(cache));
    } catch {}
    await this.saveToStorage();
  }

  completeTransition = () => {
    runInAction(() => {
      this.state.gameState = this.state.nextGameState;
      this.state.nextGameState = null;
      this.state.isTransitioning = false;
    });
    this.saveToStorage();
  }

  // Add a bit of time, capped at initialGameTime, to keep rounds flowing
  addGraceTime = (seconds: number = 1) => {
    runInAction(() => {
      const inc = Math.max(0, Math.floor(seconds));
      const cap = Math.max(0, this.state.initialGameTime || 0);
      const next = Math.min(cap > 0 ? cap : Number.MAX_SAFE_INTEGER, (this.state.timeLeft || 0) + inc);
      this.state.timeLeft = next;
    });
    this.saveToStorage();
  }

  // Deduct small points for a mistake (e.g., wrong slot tap)
  penalizeMistake = (points: number = 2) => {
    runInAction(() => {
      const deduction = Math.max(1, points);
      this.state.score = Math.max(0, this.state.score - deduction);
    });
    this.saveToStorage();
  }

  selectWordFromPool = (word: string) => {
    if (!this.state.gameState || this.state.showCorrectAnswer || !this.state.isPlaying) return;

    runInAction(() => {
      if (!this.state.gameState) return;
      try { console.log('[VB][store] selectWordFromPool before', { poolLen: this.state.gameState.poolWords.length, arrangedLen: this.state.gameState.arrangedWords.length, word }); } catch {}
      const newArrangedWords = [...this.state.gameState.arrangedWords, word];
      const newPoolWords = this.state.gameState.poolWords.filter((w) => w !== word);
      this.state.gameState = { ...this.state.gameState, poolWords: newPoolWords, arrangedWords: newArrangedWords };
      try { console.log('[VB][store] selectWordFromPool after', { poolLen: newPoolWords.length, arrangedLen: newArrangedWords.length }); } catch {}

      if (newPoolWords.length === 0) {
        this.checkAnswer();
      }
    });
    this.saveToStorage();
  }

  undoLastWord = () => {
    if (!this.state.gameState || this.state.showCorrectAnswer) return;
    const { arrangedWords, prefilledCount } = this.state.gameState;
    if (arrangedWords.length <= prefilledCount) return;

    runInAction(() => {
      if (!this.state.gameState) return;
      try { console.log('[VB][store] undoLastWord before', { poolLen: this.state.gameState.poolWords.length, arrangedLen: this.state.gameState.arrangedWords.length }); } catch {}
      const lastWord = this.state.gameState.arrangedWords[this.state.gameState.arrangedWords.length - 1];
      const newArrangedWords = this.state.gameState.arrangedWords.slice(0, -1);
      const newPoolWords = [...this.state.gameState.poolWords, lastWord];
      this.state.gameState = { ...this.state.gameState, arrangedWords: newArrangedWords, poolWords: newPoolWords };
      try { console.log('[VB][store] undoLastWord after', { poolLen: newPoolWords.length, arrangedLen: newArrangedWords.length }); } catch {}
    });
    this.saveToStorage();
  }

  returnWordToPool = (word: string, index: number) => {
    if (!this.state.gameState || this.state.showCorrectAnswer) return;
    
    runInAction(() => {
      if (!this.state.gameState) return;
      try { console.log('[VB][store] returnWordToPool before', { poolLen: this.state.gameState.poolWords.length, arrangedLen: this.state.gameState.arrangedWords.length, index, word }); } catch {}
      const newArranged = [...this.state.gameState.arrangedWords];
      newArranged.splice(index, 1);
      this.state.gameState = { ...this.state.gameState, arrangedWords: newArranged, poolWords: [...this.state.gameState.poolWords, word] };
      try { console.log('[VB][store] returnWordToPool after', { poolLen: this.state.gameState.poolWords.length, arrangedLen: newArranged.length }); } catch {}
    });
    this.saveToStorage();
  }

  checkAnswer = async () => {
    const { gameState } = this.state;
    if (!gameState || !this.state.isPlaying || gameState.poolWords.length > 0) return;

    const isCorrect = gameState.arrangedWords.join(' ').trim() === gameState.text.trim();
    await this.updateMastery(gameState.id, isCorrect);

    if (isCorrect) {
      this.handleCorrectAnswer();
    } else {
      this.handleIncorrectAnswer();
    }
  }

  private handleCorrectAnswer = () => {
    runInAction(() => {
      this.state.isPlaying = false;
      const newStreak = this.state.streak + 1;
      this.state.streak = newStreak;

      const timeBonus = Math.floor(this.state.timeLeft * 2);
      const newScore = this.state.score + 100 + timeBonus;
      this.state.score = newScore;

      this.gameStore.submitScore('verse_builder', newScore);

      if (newScore > this.state.highScore) {
        this.state.highScore = newScore;
      }

      this.state.showSuccess = true;
      setTimeout(() => {
        this.startNewRound();
      }, 3500);
    });
    this.saveToStorage();
  }

  private handleIncorrectAnswer = () => {
    runInAction(() => {
      this.state.streak = 0;
      this.state.showCorrectAnswer = true;
      this.state.isPlaying = false;
    });
    this.saveToStorage();
  }

  private async updateMastery(verseId: string, correct: boolean) {
    const updated = { ...this.state.userProgress };
    const existing = updated[verseId];
    if (existing) {
      existing.attempts += 1;
      existing.correct += correct ? 1 : 0;
      existing.lastAttempt = Date.now();
      existing.needsReview = existing.correct < 3;
    } else {
      updated[verseId] = {
        verseId,
        attempts: 1,
        correct: correct ? 1 : 0,
        lastAttempt: Date.now(),
        needsReview: true,
      };
    }

    runInAction(() => {
      this.state.userProgress = updated;
    });

    await this.saveToStorage();

    // This part requires the user from AuthStore, which should be passed in or accessed differently
    // For now, we'll skip the API call.
  }

  usePowerUp = (type: PowerUpType) => {
    if (this.state.powerUps[type] <= 0 || !this.state.gameState || !this.state.isPlaying) return;

    runInAction(() => {
      this.state.powerUps[type] -= 1;
      if (type === 'grace') {
        this.state.timeLeft = Math.min(this.state.timeLeft + 15, this.state.initialGameTime);
      } else if (type === 'discernment' && this.state.gameState && this.state.gameState.poolWords.length > 0) {
        const nextCorrectWord = this.state.gameState.originalWords[this.state.gameState.arrangedWords.length];
        if (nextCorrectWord && this.state.gameState.poolWords.includes(nextCorrectWord)) {
          this.selectWordFromPool(nextCorrectWord);
        }
      }
    });
    this.saveToStorage();
  }

  decrementTime = () => {
    if (!this.state.isPlaying || this.state.timeLeft <= 0) return;
    runInAction(() => {
        this.state.timeLeft -= 1;
        if (this.state.timeLeft <= 0) {
            this.state.isPlaying = false;
        }
    });
    this.saveToStorage();
  }

  setVersion = async (version: string) => {
    console.log('[VerseBuilder] Setting version to', version);
    runInAction(() => {
      this.state.selectedVersion = version;
      this.state.gameState = null;
      this.state.nextGameState = null;
      this.state.isTransitioning = false;
      this.state.showSuccess = false;
      this.state.showCorrectAnswer = false;
      this.verseQueue = [];
    });
    await this.saveToStorage();
    // Avoid re-entrancy by not calling initialize(); explicitly load and start
    this.setLoading(true);
    try {
      await this.loadVerseBatch();
      await this.startNewRound();
    } finally {
      this.setLoading(false);
      await this.saveToStorage();
    }
  }

  retry = () => {
    runInAction(() => {
        this.state.score = 0;
        this.state.streak = 0;
        this.startNewRound();
    });
    this.saveToStorage();
  }
}
