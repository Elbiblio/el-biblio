import { makeObservable, runInAction, action } from 'mobx';
import { BaseStore } from './BaseStore';
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
};

export class VerseBuilderStore extends BaseStore<VerseBuilderState> {
  private verseStore: VerseStore;
  private gameStore: GameStore;
  private verseQueue: VerseGame[] = [];

  constructor(verseStore: VerseStore, gameStore: GameStore) {
    super(initialState, 'verse_builder_store');
    this.verseStore = verseStore;
    this.gameStore = gameStore;
    makeObservable(this, {
      initialize: action,
      startNewRound: action,
      completeTransition: action,
      selectWordFromPool: action,
      returnWordToPool: action,
      checkAnswer: action,
      usePowerUp: action,
      decrementTime: action,
      retry: action,
      setVersion: action,
      undoLastWord: action,
    });
  }

  // Game Initialization and Setup
  async initialize() {
    this.setLoading(true);
        await this.loadVerseBatch();
    this.startNewRound();
    this.setLoading(false);
  }

  private async loadVerseBatch() {
    if (!this.state.selectedVersion) return;

    try {
      const verses = await BibleDBService.getRandomVerses(this.state.selectedVersion, 40);
      const processedVerses = verses
        .map(this.processVerse)
        .filter(Boolean) as VerseGame[];

      this.verseQueue = processedVerses;

      if (processedVerses.length === 0) {
        throw new Error('No suitable verses found for the current level');
      }
    } catch (err) {
      console.error('Failed to load verse batch:', err);
      runInAction(() => {
        this.state.error = 'Failed to load verses. Please try again.';
      });
    }
  }

  private processVerse = (verse: VerseResult): VerseGame | null => {
    if (!verse?.verseID || !verse.verseText) return null;
    try {
      const { bookAbbr, chapter, verse: v } = parseVPLId(verse.verseID);
      const book = bibleBooks.find((b) => b.abbreviation === bookAbbr);
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
  async startNewRound() {
    runInAction(() => {
      this.state.error = null;
    });

    if (this.verseQueue.length === 0) {
      await this.loadVerseBatch();
    }

    const verse = this.verseQueue.shift();
    if (!verse) {
      runInAction(() => {
        this.state.error = 'Failed to get next verse';
      });
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
  }

  completeTransition() {
    runInAction(() => {
      this.state.gameState = this.state.nextGameState;
      this.state.nextGameState = null;
      this.state.isTransitioning = false;
    });
  }

  selectWordFromPool(word: string) {
    if (!this.state.gameState || !this.state.isPlaying) return;

    runInAction(() => {
      if (!this.state.gameState) return;
      const newArrangedWords = [...this.state.gameState.arrangedWords, word];
      const newPoolWords = this.state.gameState.poolWords.filter((w) => w !== word);
      this.state.gameState = { ...this.state.gameState, poolWords: newPoolWords, arrangedWords: newArrangedWords };

      if (newPoolWords.length === 0) {
        this.checkAnswer();
      }
    });
  }

  undoLastWord() {
    if (!this.state.gameState || !this.state.isPlaying) return;
    const { arrangedWords, prefilledCount } = this.state.gameState;
    if (arrangedWords.length <= prefilledCount) return;

    runInAction(() => {
      if (!this.state.gameState) return;
      const lastWord = this.state.gameState.arrangedWords[this.state.gameState.arrangedWords.length - 1];
      const newArrangedWords = this.state.gameState.arrangedWords.slice(0, -1);
      const newPoolWords = [...this.state.gameState.poolWords, lastWord];
      this.state.gameState = { ...this.state.gameState, arrangedWords: newArrangedWords, poolWords: newPoolWords };
    });
  }

  returnWordToPool(word: string, index: number) {
    if (!this.state.gameState || !this.state.isPlaying) return;
    
    runInAction(() => {
      if (!this.state.gameState) return;
      const newArranged = [...this.state.gameState.arrangedWords];
      newArranged.splice(index, 1);
      this.state.gameState = { ...this.state.gameState, arrangedWords: newArranged, poolWords: [...this.state.gameState.poolWords, word] };
    });
  }

  async checkAnswer() {
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

  private handleCorrectAnswer() {
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
  }

  private handleIncorrectAnswer() {
    runInAction(() => {
      this.state.streak = 0;
      this.state.showCorrectAnswer = true;
      this.state.isPlaying = false;
    });
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

    // This part requires the user from AuthStore, which should be passed in or accessed differently
    // For now, we'll skip the API call.
  }

  usePowerUp(type: PowerUpType) {
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
  }

  decrementTime() {
    if (!this.state.isPlaying || this.state.timeLeft <= 0) return;
    runInAction(() => {
        this.state.timeLeft -= 1;
        if (this.state.timeLeft <= 0) {
            this.state.isPlaying = false;
        }
    });
  }

  setVersion(version: string) {
    runInAction(() => {
      this.state.selectedVersion = version;
      this.state.gameState = null;
      this.state.nextGameState = null;
      this.verseQueue = [];
    });
    this.initialize();
  }

  retry() {
    runInAction(() => {
        this.state.score = 0;
        this.state.streak = 0;
        this.startNewRound();
    });
  }
}
