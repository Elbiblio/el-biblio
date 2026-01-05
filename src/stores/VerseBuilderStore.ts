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
const MIN_TIME = 5;
const MIN_POOL_WORDS = 3;
const MIN_TOTAL_WORDS = MIN_POOL_WORDS + 1;
const MAX_PREFILLED_WORDS = 16;
const MAX_VERSE_SELECTION_ATTEMPTS = 10;
const WORDS_BY_LEVEL: Record<UserLevel, [number, number]> = {
  novice: [3, 3],
  beginner: [4, 5],
  intermediate: [6, 7],
  advanced: [7, 8],
  expert: [9, 10],
};

const LEVEL_THRESHOLDS = {
  novice: 0,
  beginner: 5,
  intermediate: 15,
  advanced: 30,
  expert: 50,
};

const LEVEL_ORDER: UserLevel[] = ['novice', 'beginner', 'intermediate', 'advanced', 'expert'];

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

export type PassageInfo = {
  bookName: string;
  chapter: number;
  startVerse: number;
  endVerse: number;
  verses: Array<{ id: string; text: string; correct: boolean | null }>;
};

export type PassageSummary = {
  passage: PassageInfo;
  correctCount: number;
  totalCount: number;
  show: boolean;
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
  totalCorrectVerses: number;
  userLevel: UserLevel;
  consecutiveCorrect: number;
  showSuccess: boolean;
  showCorrectAnswer: boolean;
  error: string | null;
  wordsToLeave: number;
  userProgress: Record<string, VerseMastery>;
  selectedVersion: string;
  availableVersions: string[];
  recentVerseCacheKey?: string;
  hasPlayed?: boolean;
  currentPassage: PassageInfo | null;
  passageSummary: PassageSummary | null;
  gameMode: 'random' | 'passage';
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
  totalCorrectVerses: 0,
  userLevel: 'novice',
  consecutiveCorrect: 0,
  showSuccess: false,
  showCorrectAnswer: false,
  error: null,
  wordsToLeave: 3,
  userProgress: {},
  selectedVersion: 'RV',
  availableVersions: ['ASV', 'KJV', 'RV', 'AMP', 'WEB', 'BSB', 'YLT', 'DR'],
  recentVerseCacheKey: 'vb_recent_verses',
  hasPlayed: false,
  currentPassage: null,
  passageSummary: null,
  gameMode: 'passage',
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
  private saveTimeout: ReturnType<typeof setTimeout> | null = null;
  private hasPendingSave = false;
  private successRoundTimeout: ReturnType<typeof setTimeout> | null = null;

  constructor(verseStore: VerseStore, gameStore: GameStore) {
    this.state = initialState;
    this.storageKey = 'verse_builder_store';
    this.verseStore = verseStore;
    this.gameStore = gameStore;
    makeAutoObservable(this);
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey)
      .then(stored => {
        if (stored) {
          runInAction(() => {
            this.state = { ...this.state, ...JSON.parse(stored) };
          });
        }
      })
      .catch(error => {
        if (__DEV__) {
          console.error('Error loading verse builder store from storage:', error);
        }
      });
  }

  private setLoading = (value: boolean) => {
    this.isLoading = value;
  };

  private setError = (message: string | null) => {
    this.error = message;
  };

  private scheduleSave = () => {
    this.hasPendingSave = true;
    if (this.saveTimeout) {
      return;
    }
    this.saveTimeout = setTimeout(() => {
      this.saveTimeout = null;
      void this.flushSave();
    }, 300);
  };

  private async flushSave() {
    if (!this.hasPendingSave) {
      return;
    }
    this.hasPendingSave = false;
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      if (__DEV__) {
        console.error(`Error saving ${this.storageKey} to storage:`, error);
      }
      this.error = 'Failed to save data';
    }
  }

  // Game Initialization and Setup
  initialize = async () => {
    if (this.isInitializing) return;
    this.isInitializing = true;
    this.setLoading(true);
    try {
      // Fire-and-forget gameStore init so verse setup is never blocked by network
      if (!this.gameStore.state.lastSynced) {
        void this.gameStore.initialize().catch(() => {});
      }
      runInAction(() => {
        const personalBest = this.gameStore.getPersonalBest('verse_builder');
        if (personalBest > this.state.highScore) {
          this.state.highScore = personalBest;
        }
      });
      await this.loadVerseBatch();
      await this.startNewRound();
    } finally {
      this.setLoading(false);
      this.isInitializing = false;
      await this.flushSave();
    }
  }

  get potentialRoundPoints(): number {
    if (!this.state.isPlaying || this.state.timeLeft <= 0) return 0;

    const basePoints = 100;
    const projectedStreak = this.state.streak + 1;
    const streakMultiplier = 1 + projectedStreak * 0.1;
    const timeBonus = Math.max(0, Math.floor(this.state.timeLeft * 3));
    const difficultyBonus = this.calculateDifficultyBonus();

    const raw = (basePoints + timeBonus) * streakMultiplier + difficultyBonus;
    return Math.max(0, Math.floor(raw));
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
      const primaryTable = await this.resolveTableName(this.state.selectedVersion);
      
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

      const processedVerses: VerseGame[] = [];

      if (this.state.gameMode === 'random') {
        const randomVerses = await BibleDBService.getRandomVerses(primaryTable, 40);
        const filtered = randomVerses
          .map(this.processVerse)
          .filter((v): v is VerseGame => !!v)
          .filter((v) => !recent.has(v.id));
        processedVerses.push(...filtered);
      } else {
        const passagesNeeded = 10;
        for (let i = 0; i < passagesNeeded; i++) {
          const passage = await BibleDBService.getRandomPassage(primaryTable, 3, 6);
          if (passage) {
            const passageVerses = passage.verses
              .map(this.processVerse)
              .filter((v): v is VerseGame => !!v)
              .filter((v) => !recent.has(v.id));
            
            if (passageVerses.length >= 3) {
              processedVerses.push(...passageVerses);
            }
          }
        }
      }

      if (processedVerses.length === 0) {
        const fallbacks = ['KJV', 'ASV', 'WEB', 'BSB', 'YLT', 'DR'];
        for (const v of fallbacks) {
          if (v === this.state.selectedVersion) continue;
          try {
            const altTable = await this.resolveTableName(v);

            if (this.state.gameMode === 'random') {
              const randomVerses = await BibleDBService.getRandomVerses(altTable, 40);
              const proc = randomVerses
                .map(this.processVerse)
                .filter((vv): vv is VerseGame => !!vv);
              if (proc.length > 0) {
                runInAction(() => {
                  this.state.selectedVersion = v;
                });
                processedVerses.push(...proc);
                break;
              }
            } else {
              const passage = await BibleDBService.getRandomPassage(altTable, 3, 6);
              if (passage) {
                const proc = passage.verses
                  .map(this.processVerse)
                  .filter((vv): vv is VerseGame => !!vv);
                if (proc.length > 0) {
                  runInAction(() => {
                    this.state.selectedVersion = v;
                  });
                  processedVerses.push(...proc);
                  break;
                }
              }
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
      await this.flushSave();
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
  private prepareGameState = (verse: VerseGame): VerseGame | null => {
    const totalWords = verse.originalWords.length;
    if (totalWords < MIN_TOTAL_WORDS) {
      return null;
    }

    const maxPoolWords = Math.max(1, totalWords - 1);
    const dynamicWordsToLeave = this.calculateWordsToLeave(totalWords);
    let poolWordsCount = Math.min(
      maxPoolWords,
      Math.max(MIN_POOL_WORDS, dynamicWordsToLeave),
    );

    let prefilledCount = totalWords - poolWordsCount;
    const maxPrefillAllowed = Math.min(MAX_PREFILLED_WORDS, totalWords - MIN_POOL_WORDS);
    if (prefilledCount > maxPrefillAllowed) {
      const shift = prefilledCount - maxPrefillAllowed;
      prefilledCount -= shift;
      poolWordsCount += shift;
    }

    if (poolWordsCount < MIN_POOL_WORDS || prefilledCount < 0) {
      return null;
    }

    const arrangedWords = verse.originalWords.slice(0, prefilledCount);
    const poolWords = shuffleArray(verse.originalWords.slice(prefilledCount));

    if (poolWords.length < MIN_POOL_WORDS) {
      return null;
    }

    return {
      ...verse,
      arrangedWords,
      poolWords,
      prefilledCount,
    };
  };

  startNewRound = async () => {
    runInAction(() => {
      this.state.error = null;
    });
    this.scheduleSave();

    if (this.state.isPlaying && this.state.gameState && !this.state.isTransitioning) {
      if (__DEV__) {
        console.log('[VerseBuilder] Ignoring startNewRound because a round is active');
      }
      return;
    }

    let attempts = 0;
    let verse: VerseGame | null = null;
    let newGameState: VerseGame | null = null;

    while (attempts < MAX_VERSE_SELECTION_ATTEMPTS && !newGameState) {
      if (this.verseQueue.length === 0) {
        await this.loadVerseBatch();
      }

      const candidate = this.verseQueue.shift();
      if (!candidate) {
        break;
      }

      const prepared = this.prepareGameState(candidate);
      if (prepared) {
        verse = candidate;
        newGameState = prepared;
        break;
      }

      attempts += 1;
    }

    if (!verse || !newGameState) {
      runInAction(() => {
        this.state.error = 'Failed to get a playable verse. Please try again.';
        this.state.isPlaying = false;
      });
      await this.flushSave();
      return;
    }

    const { bookAbbr, chapter, verse: verseNum } = parseVPLId(verse.id);
    const book = bibleBooks.find((b) => b.abbreviation === bookAbbr);

    if (!this.state.currentPassage || 
        this.state.currentPassage.bookName !== book?.name || 
        this.state.currentPassage.chapter !== chapter) {
      runInAction(() => {
        this.state.currentPassage = {
          bookName: book?.name || bookAbbr,
          chapter,
          startVerse: verseNum,
          endVerse: verseNum,
          verses: [{ id: verse.id, text: verse.text, correct: null }],
        };
      });
    } else {
      runInAction(() => {
        if (this.state.currentPassage) {
          this.state.currentPassage.endVerse = verseNum;
          this.state.currentPassage.verses.push({ id: verse.id, text: verse.text, correct: null });
        }
      });
    }

    const nextInitial = this.computeInitialTime();
    runInAction(() => {
      if (!this.state.gameState) {
        this.state.gameState = newGameState;
      } else {
        this.state.nextGameState = newGameState;
        this.state.isTransitioning = true;
      }
      this.state.initialGameTime = nextInitial;
      this.state.timeLeft = nextInitial;
      this.state.isPlaying = true;
      this.state.showSuccess = false;
      this.state.showCorrectAnswer = false;
    });
    
    try {
      const cacheKey = this.state.recentVerseCacheKey || 'vb_recent_verses';
      const cacheRaw = (await AsyncStorage.getItem(cacheKey)) || '{}';
      const cache: Record<string, number> = JSON.parse(cacheRaw);
      cache[newGameState.id] = Date.now();
      await AsyncStorage.setItem(cacheKey, JSON.stringify(cache));
    } catch {}
    this.scheduleSave();
  }

  private calculateWordsToLeave(totalWords: number): number {
    const level = this.state.userLevel || 'novice';
    const [minWords, maxWords] = WORDS_BY_LEVEL[level];
    
    const streakBonus = Math.floor(this.state.streak / 3);
    const targetWords = Math.min(maxWords + streakBonus, totalWords - 1);
    
    return Math.max(minWords, Math.min(targetWords, totalWords - 1));
  }

  private computeInitialTime(): number {
    const level = this.state.userLevel || 'novice';
    const baselineByLevel: Record<UserLevel, number> = {
      novice: 25,
      beginner: 22,
      intermediate: 18,
      advanced: 14,
      expert: 10,
    };
    const base = baselineByLevel[level] ?? 25;
    
    const streakPenalty = Math.floor(this.state.streak / 3);
    const consecutivePairs = Math.floor(this.state.consecutiveCorrect / 2);
    const consecutivePenalty = Math.min(consecutivePairs * 0.5, 5);
    const influenced = base - streakPenalty - consecutivePenalty;
    
    return Math.max(MIN_TIME, influenced);
  }

  private checkLevelUp() {
    const currentLevel = this.state.userLevel;
    const currentIndex = LEVEL_ORDER.indexOf(currentLevel);
    
    if (currentIndex < LEVEL_ORDER.length - 1) {
      const nextLevel = LEVEL_ORDER[currentIndex + 1];
      const threshold = LEVEL_THRESHOLDS[nextLevel];
      
      if (this.state.totalCorrectVerses >= threshold) {
        runInAction(() => {
          this.state.userLevel = nextLevel;
          this.state.consecutiveCorrect = 0;
        });
        return true;
      }
    }
    return false;
  }

  completeTransition = () => {
    runInAction(() => {
      this.state.gameState = this.state.nextGameState;
      this.state.nextGameState = null;
      this.state.isTransitioning = false;
    });
    this.scheduleSave();
  }

  addGraceTime = (seconds: number = 1) => {
    const level = this.state.userLevel || 'novice';
    const graceMultiplier = level === 'novice' ? 1.0 : level === 'beginner' ? 0.8 : level === 'intermediate' ? 0.6 : level === 'advanced' ? 0.4 : 0.3;
    
    runInAction(() => {
      const adjustedSeconds = Math.floor(seconds * graceMultiplier);
      const inc = Math.max(0, adjustedSeconds);
      const cap = Math.max(0, this.state.initialGameTime || 0);
      const next = Math.min(cap > 0 ? cap : Number.MAX_SAFE_INTEGER, (this.state.timeLeft || 0) + inc);
      this.state.timeLeft = next;
    });
    this.scheduleSave();
  }

  // Deduct small points for a mistake (e.g., wrong slot tap)
  penalizeMistake = (points: number = 2, resetStreak: boolean = false) => {
    runInAction(() => {
      const deduction = Math.max(1, points);
      this.state.score = Math.max(0, this.state.score - deduction);
      if (resetStreak) {
        this.state.streak = 0;
      }
    });
    this.scheduleSave();
  }

  selectWordFromPool = (word: string) => {

    runInAction(() => {
      if (!this.state.gameState) return;
      const newArrangedWords = [...this.state.gameState.arrangedWords, word];
      const newPoolWords = [...this.state.gameState.poolWords];
      const wordIndex = newPoolWords.indexOf(word);
      if (wordIndex !== -1) {
        newPoolWords.splice(wordIndex, 1);
      }
      this.state.gameState = { ...this.state.gameState, poolWords: newPoolWords, arrangedWords: newArrangedWords };

      if (newPoolWords.length === 0) {
        this.checkAnswer();
      }
    });
    this.scheduleSave();
  }

  undoLastWord = () => {
    if (!this.state.gameState || this.state.showCorrectAnswer) return;
    const { arrangedWords, prefilledCount } = this.state.gameState;
    if (arrangedWords.length <= prefilledCount) return;

    runInAction(() => {
      if (!this.state.gameState) return;
      const lastWord = this.state.gameState.arrangedWords[this.state.gameState.arrangedWords.length - 1];
      const newArrangedWords = this.state.gameState.arrangedWords.slice(0, -1);
      const newPoolWords = [...this.state.gameState.poolWords, lastWord];
      this.state.gameState = { ...this.state.gameState, arrangedWords: newArrangedWords, poolWords: newPoolWords };
    });
    this.scheduleSave();
  }

  returnWordToPool = (word: string, index: number) => {
    if (!this.state.gameState || this.state.showCorrectAnswer) return;
    
    runInAction(() => {
      if (!this.state.gameState) return;
      const newArranged = [...this.state.gameState.arrangedWords];
      newArranged.splice(index, 1);
      this.state.gameState = { ...this.state.gameState, arrangedWords: newArranged, poolWords: [...this.state.gameState.poolWords, word] };
    });
    this.scheduleSave();
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
      this.state.consecutiveCorrect += 1;

      if (this.state.currentPassage && this.state.gameState) {
        const verseIndex = this.state.currentPassage.verses.findIndex(v => v.id === this.state.gameState?.id);
        if (verseIndex !== -1) {
          this.state.currentPassage.verses[verseIndex].correct = true;
        }
      }

      const basePoints = 100;
      const streakMultiplier = 1 + (newStreak * 0.1);
      const timeBonus = Math.floor(this.state.timeLeft * 3);
      const difficultyBonus = this.calculateDifficultyBonus();
      
      const roundPoints = Math.floor((basePoints + timeBonus) * streakMultiplier + difficultyBonus);
      const newScore = this.state.score + roundPoints;
      this.state.score = newScore;
      this.state.totalCorrectVerses += 1;

      const leveledUp = this.checkLevelUp();

      void this.gameStore.submitScore('verse_builder', newScore, {
        verses_correct: this.state.totalCorrectVerses,
        level: this.state.userLevel,
      });

      if (newScore > this.state.highScore) {
        this.state.highScore = newScore;
      }

      this.state.showSuccess = true;
      this.state.hasPlayed = true;
      
      if (this.successRoundTimeout) {
        clearTimeout(this.successRoundTimeout);
      }
      this.successRoundTimeout = setTimeout(() => {
        this.successRoundTimeout = null;
        this.checkAndShowPassageSummary();
      }, 3500);
    });
    this.scheduleSave();
  }

  private calculateDifficultyBonus(): number {
    const level = this.state.userLevel || 'novice';
    const levelBonus: Record<UserLevel, number> = {
      novice: 0,
      beginner: 20,
      intermediate: 50,
      advanced: 100,
      expert: 200,
    };
    
    const wordsBonus = (this.state.gameState?.poolWords.length || 0) * 10;
    
    return levelBonus[level] + wordsBonus;
  }

  private handleIncorrectAnswer = () => {
    runInAction(() => {
      this.state.streak = 0;
      this.state.consecutiveCorrect = 0;
      
      if (this.state.currentPassage && this.state.gameState) {
        const verseIndex = this.state.currentPassage.verses.findIndex(v => v.id === this.state.gameState?.id);
        if (verseIndex !== -1) {
          this.state.currentPassage.verses[verseIndex].correct = false;
        }
      }
      
      this.state.showCorrectAnswer = true;
      this.state.isPlaying = false;
      this.state.hasPlayed = true;
    });
    this.scheduleSave();
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

    await this.flushSave();

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
    this.scheduleSave();
  }

  decrementTime = () => {
    if (!this.state.isPlaying || this.state.timeLeft <= 0) return;
    runInAction(() => {
      this.state.timeLeft -= 1;
      if (this.state.timeLeft <= 0) {
        this.state.isPlaying = false;
        this.state.hasPlayed = true; // mark that at least one round has been attempted
      }
    });
    this.scheduleSave();
  }

  setVersion = async (version: string) => {
    runInAction(() => {
      this.state.selectedVersion = version;
      this.state.gameState = null;
      this.state.nextGameState = null;
      this.state.isTransitioning = false;
      this.state.showSuccess = false;
      this.state.showCorrectAnswer = false;
      this.verseQueue = [];
    });
    this.scheduleSave();
    // Avoid re-entrancy by not calling initialize(); explicitly load and start
    this.setLoading(true);
    try {
      await this.loadVerseBatch();
      await this.startNewRound();
    } finally {
      this.setLoading(false);
      await this.flushSave();
    }
  }

  retry = () => {
    runInAction(() => {
        this.state.score = 0;
        this.state.streak = 0;
        this.state.consecutiveCorrect = 0;
        this.startNewRound();
    });
    this.scheduleSave();
  }

  private checkAndShowPassageSummary = () => {
    const { currentPassage } = this.state;
    if (!currentPassage) {
      this.startNewRound();
      return;
    }

    const nextVerseInQueue = this.verseQueue[0];
    if (nextVerseInQueue) {
      const { bookAbbr, chapter } = parseVPLId(nextVerseInQueue.id);
      const book = bibleBooks.find((b) => b.abbreviation === bookAbbr);
      
      if (book?.name === currentPassage.bookName && chapter === currentPassage.chapter) {
        this.startNewRound();
        return;
      }
    }

    const correctCount = currentPassage.verses.filter(v => v.correct === true).length;
    const totalCount = currentPassage.verses.length;

    runInAction(() => {
      this.state.passageSummary = {
        passage: currentPassage,
        correctCount,
        totalCount,
        show: true,
      };
    });
    this.scheduleSave();
  }

  dismissPassageSummary = () => {
    runInAction(() => {
      this.state.passageSummary = null;
      this.state.currentPassage = null;
    });
    this.startNewRound();
  }

  toggleGameMode = async () => {
    const newMode = this.state.gameMode === 'random' ? 'passage' : 'random';
    runInAction(() => {
      this.state.gameMode = newMode;
      this.state.gameState = null;
      this.state.nextGameState = null;
      this.state.isTransitioning = false;
      this.state.showSuccess = false;
      this.state.showCorrectAnswer = false;
      this.state.currentPassage = null;
      this.state.passageSummary = null;
      this.state.isPlaying = false;
      this.state.timeLeft = INITIAL_TIME;
      this.verseQueue = [];
    });
    this.scheduleSave();
    this.setLoading(true);
    try {
      await this.loadVerseBatch();
      await this.startNewRound();
    } finally {
      this.setLoading(false);
      await this.flushSave();
    }
  }

  get currentLevelProgress(): { current: number; next: number; percentage: number } {
    const currentLevel = this.state.userLevel;
    const currentIndex = LEVEL_ORDER.indexOf(currentLevel);
    
    if (currentIndex === LEVEL_ORDER.length - 1) {
      return { current: this.state.totalCorrectVerses, next: this.state.totalCorrectVerses, percentage: 100 };
    }
    
    const nextLevel = LEVEL_ORDER[currentIndex + 1];
    const currentThreshold = LEVEL_THRESHOLDS[currentLevel];
    const nextThreshold = LEVEL_THRESHOLDS[nextLevel];
    
    const progress = this.state.totalCorrectVerses - currentThreshold;
    const range = nextThreshold - currentThreshold;
    const percentage = Math.min(100, Math.floor((progress / range) * 100));
    
    return {
      current: this.state.totalCorrectVerses,
      next: nextThreshold,
      percentage,
    };
  }

  cleanup = () => {
    if (this.successRoundTimeout) {
      clearTimeout(this.successRoundTimeout);
      this.successRoundTimeout = null;
    }
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
      this.saveTimeout = null;
    }
  }
}
