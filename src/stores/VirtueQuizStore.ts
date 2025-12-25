import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient } from '@/api/client';
import { Virtue, AppVirtue, VirtueProgress, VerseResult, UserLevel } from '@/types';
import { RootStore } from '@/stores/RootStore';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';
import BibleDBService, { parseVPLId } from '@/utils/database';
import { bibleBooks } from '@/constants/bibleBooks';

interface QuizQuestion {
  id: string;
  qid?: number;
  question: string;
  type: 'true_false' | 'multiple_choice';
  options?: string[];
  correctAnswer: string | number;
  explanation: string;
  verseReference?: string;
  virtue: string;
  level: number;
}

interface VirtueQuizStoreState {
  showConfetti: boolean;
  // Virtue and level selection
  selectedVirtue: AppVirtue | null;
  selectedLevel: number | null;

  // Quiz state
  quizStarted: boolean;
  quizCompleted: boolean;
  currentQuestionIndex: number;
  score: number;

  // Question-specific state
  questions: QuizQuestion[];
  selectedAnswer: string | number | null;
  isAnswerCorrect: boolean | null;
  showExplanation: boolean;

  answerMap: Record<number, string | number>;

  // Loading and error states
  isLoading: boolean;
  error: string | null;
}

export class VirtueQuizStore {
  state: VirtueQuizStoreState = {
    showConfetti: false,
    selectedVirtue: null,
    selectedLevel: null,
    quizStarted: false,
    quizCompleted: false,
    currentQuestionIndex: 0,
    score: 0,
    questions: [],
    selectedAnswer: null,
    isAnswerCorrect: null,
    showExplanation: false,
    answerMap: {},
    isLoading: false,
    error: null,
  };

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'virtue_quiz_store';

  private rootStore: RootStore;

  constructor(rootStore: RootStore) {
    this.state = {
      showConfetti: false,
      selectedVirtue: null,
      selectedLevel: null,
      quizStarted: false,
      quizCompleted: false,
      currentQuestionIndex: 0,
      score: 0,
      questions: [],
      selectedAnswer: null,
      isAnswerCorrect: null,
      showExplanation: false,
      answerMap: {},
      isLoading: false,
      error: null,
    };
    this.storageKey = 'virtue_quiz_store';
    this.rootStore = rootStore;
    makeAutoObservable(this, {}, { autoBind: true });
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading virtue quiz store from storage:', error);
    });
  }

  private setLoading = (value: boolean) => {
    runInAction(() => {
      this.state.isLoading = value;
    });
    this.isLoading = value;
  };

  private setError = (message: string | null) => {
    runInAction(() => {
      this.state.error = message;
    });
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

  // Computed Getters
  get selectedVirtue() {
    return this.state.selectedVirtue;
  }

  get selectedLevel() {
    return this.state.selectedLevel;
  }

  get quizStarted() {
    return this.state.quizStarted;
  }

  get quizCompleted() {
    return this.state.quizCompleted;
  }

  get currentQuestionIndex() {
    return this.state.currentQuestionIndex;
  }

  get score() {
    return this.state.score;
  }

  get questions() {
    return this.state.questions;
  }

  get selectedAnswer() {
    return this.state.selectedAnswer;
  }

  get isAnswerCorrect() {
    return this.state.isAnswerCorrect;
  }

  get showExplanation() {
    return this.state.showExplanation;
  }

  get isQuizLoading() {
    return this.state.isLoading || this.rootStore.virtueStore.isVirtuesLoading || this.rootStore.virtueStore.isProgressLoading;
  }

  get quizError() {
    return this.state.error || this.rootStore.virtueStore.virtuesError || this.rootStore.virtueStore.progressError;
  }

  get virtues() {
    return this.rootStore.virtueStore.virtues;
  }

  get virtueProgress() {
    return this.rootStore.virtueStore.userProgress;
  }

  get showConfetti() {
    return this.state.showConfetti;
  }

  // Actions
  async loadInitialData() {
    if (this.rootStore.virtueStore.virtues.length === 0) {
      await this.rootStore.virtueStore.fetchVirtues();
    }
    if (Object.keys(this.rootStore.virtueStore.userProgress).length === 0) {
        await this.rootStore.virtueStore.fetchUserProgress();
    }
    if (!this.rootStore.gameStore.state.lastSynced) {
      await this.rootStore.gameStore.initialize();
    }
  }
  selectVirtue(virtue: AppVirtue | null) {
    this.state.selectedVirtue = virtue;
    this.state.selectedLevel = null; // Reset level when virtue changes
    this.saveToStorage();
  }

  selectLevel(level: number) {
    this.state.selectedLevel = level;
    this.saveToStorage();
  }

  async startQuiz() {
    if (this.state.isLoading) return;
    if (!this.state.selectedVirtue || !this.state.selectedLevel) {
      toast.error('Please select a virtue and level to begin.');
      return;
    }

    this.setError(null);

    runInAction(() => {
      this.state.quizStarted = false;
      this.state.quizCompleted = false;
      this.state.currentQuestionIndex = 0;
      this.state.score = 0;
      this.state.selectedAnswer = null;
      this.state.isAnswerCorrect = null;
      this.state.showExplanation = false;
    });

    await this.fetchQuizQuestions(
      this.state.selectedVirtue.id,
      this.state.selectedLevel
    );

    if (this.state.questions.length > 0) {
      runInAction(() => {
        this.state.quizStarted = true;
      });
      await this.saveToStorage();
    } else {
      toast.error('No quiz questions available yet. Please try another level or virtue.');
    }
  }

  async fetchQuizQuestions(virtueId: string, level: number) {
    this.setLoading(true);
    this.setError(null);
    try {
      runInAction(() => {
        this.state.questions = [];
      });
      const response = await apiClient.get<QuizQuestion[]>(
        `/virtues/${virtueId}/quiz`,
        {
          level,
          include: ['explanations', 'verse_references'],
        }
      );

      if (response.success && response.data) {
        const payload = response.data as any;
        const extracted: QuizQuestion[] = Array.isArray(payload)
          ? payload
          : Array.isArray(payload?.data)
          ? payload.data
          : Array.isArray(payload?.questions)
          ? payload.questions
          : [];

        if (extracted.length > 0) {
          runInAction(() => {
            this.state.questions = extracted;
          });
        }
      } else {
        // Fallback to local generation
        const built = await this.buildLocalQuestions(virtueId, level as number);
        runInAction(() => { this.state.questions = built; });
      }
      
      await this.saveToStorage();
    } catch (error: any) {
      // As a fallback, try local generation before surfacing error
      try {
        const built = await this.buildLocalQuestions(virtueId, level as number);
        runInAction(() => { this.state.questions = built; });
        await this.saveToStorage();
        toast.info('Using offline quiz questions');
        return;
      } catch (fallbackErr) {
        const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
        this.setError(errorMessage);
        toast.error('Failed to load quiz questions. Please check your connection.');
      }
    } finally {
      this.setLoading(false);
    }
  }

  // Build questions locally from the bundled Bible DB if API is unavailable
  private async buildLocalQuestions(virtueId: string, level: number): Promise<QuizQuestion[]> {
    // Determine virtue keyword by id -> name mapping
    const virtueObj = this.rootStore.virtueStore.virtues.find(v => v.id === virtueId);
    const virtueKey = virtueObj?.name?.toLowerCase() || virtueId.toLowerCase();

    // Choose a version
    const versions = await BibleDBService.getInstalledVersions();
    const version = versions[0] || 'eng_rv_vpl';

    // Try to get verses by virtue, fallback to random
    let verses: VerseResult[] = [];
    try {
      verses = await BibleDBService.getVersesByVirtue(version, virtueKey, 10);
    } catch {
      verses = await BibleDBService.getRandomVerses(version, 10);
    }

    // Build questions
    const isExpert = level >= 3; // assume 3 is advanced/expert tier
    const questions: QuizQuestion[] = verses.slice(0, 10).map((v) => {
      const { bookAbbr, chapter, verse } = parseVPLId(v.verseID);
      const bookObj = bibleBooks.find(b => b.abbreviation === bookAbbr);
      const bookName = bookObj?.name || bookAbbr;
      const reference = `${bookName} ${chapter}:${verse}`;
      const correct = isExpert ? `${bookName} ${chapter}` : bookName;
      const options = isExpert
        ? this.generateBookChapterOptions(bookName, chapter)
        : this.generateBookOptions(bookName);
      return {
        id: v.verseID,
        question: 'Where is this verse found?',
        type: 'multiple_choice',
        options,
        correctAnswer: options.indexOf(correct),
        explanation: reference,
        verseReference: reference,
        virtue: virtueId,
        level,
      } as QuizQuestion;
    });

    return questions;
  }

  // Helpers to generate options
  private generateBookOptions(correctBook: string): string[] {
    const allBooks = bibleBooks.map(b => b.name);
    const other = allBooks.filter(b => b !== correctBook);
    const wrong = this.shuffle(other).slice(0, 3);
    return this.shuffle([correctBook, ...wrong]);
  }

  private generateBookChapterOptions(correctBook: string, correctChapter: number): string[] {
    const bookObj = bibleBooks.find(b => b.name === correctBook);
    const correct = `${correctBook} ${correctChapter}`;
    const set = new Set<string>();
    // same book different chapter
    if (bookObj && bookObj.chapters > 1) {
      let ch = correctChapter;
      for (let i = 0; i < 10 && set.size < 2; i++) {
        ch = Math.max(1, Math.ceil(Math.random() * bookObj.chapters));
        if (ch !== correctChapter) set.add(`${correctBook} ${ch}`);
      }
    }
    // different books random chapters
    while (set.size < 3) {
      const rb = bibleBooks[Math.floor(Math.random() * bibleBooks.length)];
      const rc = Math.max(1, Math.ceil(Math.random() * rb.chapters));
      const opt = `${rb.name} ${rc}`;
      if (opt !== correct) set.add(opt);
    }
    return this.shuffle([correct, ...Array.from(set).slice(0,3)]);
  }

  private shuffle<T>(arr: T[]): T[] {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  async handleAnswerSelection(answer: string | number) {
    const currentQuestion = this.state.questions[this.state.currentQuestionIndex];
    if (!currentQuestion) return;

    const isCorrect = String(answer) === String(currentQuestion.correctAnswer);

    runInAction(() => {
        this.state.selectedAnswer = answer;
        this.state.isAnswerCorrect = isCorrect;
        this.state.answerMap[this.state.currentQuestionIndex] = answer;
        if (isCorrect) {
            this.state.score += 1;
        }
        this.state.showExplanation = true;
    });
    
    await this.saveToStorage();

    // Individual answer submission removed - answers submitted in batch at quiz completion
  }

  goToNextQuestion() {
    if (this.state.currentQuestionIndex < this.state.questions.length - 1) {
      runInAction(() => {
        this.state.currentQuestionIndex++;
        this.state.selectedAnswer = null;
        this.state.isAnswerCorrect = null;
        this.state.showExplanation = false;
      });
      this.saveToStorage();
    } else {
      this.completeQuiz();
    }
  }

  async completeQuiz() {
    runInAction(() => {
        this.state.showConfetti = false; // Reset first
    });
    const { selectedVirtue, selectedLevel, score, questions } = this.state;
    if (!selectedVirtue || !selectedLevel) return;

    const points = score * 10; // 10 points per correct answer
    const percentageScore = (score / questions.length) * 100;

    try {
        // Call dedicated endpoint to complete quiz
        const response = await apiClient.post(
          `/virtues/${selectedVirtue.id}/complete-quiz`,
          {
            level: selectedLevel,
            score: percentageScore,
            points: points,
          }
        );

        if (!response.success) {
          throw new Error(response.message || 'Failed to complete quiz');
        }

        // Submit to game scores for leaderboard
        await this.rootStore.gameStore.submitScore('virtue_quiz', points);

        // Submit batch answers for analytics (optional - if backend needs detailed answer data)
        try {
          const answers = questions
            .map((q, idx) => {
              const selected = this.state.answerMap[idx];
              if (selected === undefined) {
                return null;
              }
              return {
                qid: (q as any)?.qid ?? null,
                selectedAnswer: selected,
              };
            })
            .filter(Boolean);

          await apiClient.post(
            `/virtues/${selectedVirtue.id}/quiz/answers`,
            {
              level: selectedLevel,
              answers,
            }
          );
        } catch (analyticsError) {
          // Analytics submission is optional, don't fail the quiz if it errors
          console.warn('Failed to submit quiz analytics:', analyticsError);
        }

        // Refresh user progress
        await this.rootStore.virtueStore.fetchUserProgress();

        runInAction(() => {
            this.state.quizCompleted = true;
            this.state.showConfetti = true;
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            toast.success(`Quiz completed! You earned ${points} points.`);
        });
        
        await this.saveToStorage();
    } catch (error) {
        console.error('Failed to complete quiz', error);
        toast.error('There was an error saving your quiz results.');
    }
  }

  restartQuiz() {
    this.state.quizCompleted = false;
    this.startQuiz();
  }

  selectDifferentVirtue() {
    this.reset();
    this.loadInitialData(); 
  }

  triggerConfetti(show: boolean) {
    runInAction(() => {
      this.state.showConfetti = show;
    });
    
    this.saveToStorage();
  }

  reset() {
    this.state.showConfetti = false;
    this.state.selectedVirtue = null;
    this.state.selectedLevel = null;
    this.state.quizStarted = false;
    this.state.quizCompleted = false;
    this.state.currentQuestionIndex = 0;
    this.state.score = 0;
    this.state.questions = [];
    this.state.selectedAnswer = null;
    this.state.isAnswerCorrect = null;
    this.state.showExplanation = false;
    this.state.answerMap = {};
    this.setError(null);
    this.setLoading(false);
    this.saveToStorage();
  }
}
