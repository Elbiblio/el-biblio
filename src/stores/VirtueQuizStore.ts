import { makeObservable, action, runInAction, observable } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient } from '@/api/client';
import { Virtue, AppVirtue, VirtueProgress } from '@/types';
import { RootStore } from '@/stores/RootStore';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';

interface QuizQuestion {
  id: string;
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

  // Loading and error states
  isLoading: boolean;
  error: string | null;
}

export class VirtueQuizStore extends BaseStore<VirtueQuizStoreState> {
  private rootStore: RootStore;

  constructor(rootStore: RootStore) {
    super({
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
      isLoading: false,
      error: null,
    });

    this.rootStore = rootStore;

    makeObservable(this, {
      // Actions
      selectVirtue: action.bound,
      selectLevel: action.bound,
      startQuiz: action.bound,
      handleAnswerSelection: action.bound,
      goToNextQuestion: action.bound,
      restartQuiz: action.bound,
      reset: action.bound,
      fetchQuizQuestions: action.bound,
      loadInitialData: action.bound,
      selectDifferentVirtue: action.bound,
      triggerConfetti: action.bound,
    });
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
  }
  selectVirtue(virtue: AppVirtue | null) {
    this.state.selectedVirtue = virtue;
    this.state.selectedLevel = null; // Reset level when virtue changes
  }

  selectLevel(level: number) {
    this.state.selectedLevel = level;
  }

  async startQuiz() {
    if (!this.state.selectedVirtue || !this.state.selectedLevel) return;

    await this.fetchQuizQuestions(
      this.state.selectedVirtue.id,
      this.state.selectedLevel
    );

    if (this.state.questions.length > 0) {
        runInAction(() => {
            this.state.quizStarted = true;
            this.state.quizCompleted = false;
            this.state.currentQuestionIndex = 0;
            this.state.score = 0;
            this.state.selectedAnswer = null;
            this.state.isAnswerCorrect = null;
            this.state.showExplanation = false;
        });
    }
  }

  async fetchQuizQuestions(virtueId: string, level: number) {
    this.setLoading(true);
    this.setError(null);
    try {
      const response = await apiClient.get<QuizQuestion[]>(
        `/virtues/${virtueId}/quiz`,
        {
          level,
          include: ['explanations', 'verse_references'],
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch quiz questions');
      }

      runInAction(() => {
        this.state.questions = response.data!;
      });
    } catch (error: any) {
      const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
      this.setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      this.setLoading(false);
    }
  }

  async handleAnswerSelection(answer: string | number) {
    const currentQuestion = this.state.questions[this.state.currentQuestionIndex];
    if (!currentQuestion) return;

    const isCorrect = String(answer) === String(currentQuestion.correctAnswer);

    runInAction(() => {
        this.state.selectedAnswer = answer;
        this.state.isAnswerCorrect = isCorrect;
        if (isCorrect) {
            this.state.score += 1;
        }
        this.state.showExplanation = true;
    });

    try {
        await apiClient.post<{ correct: boolean }>(`/quiz-questions/${currentQuestion.id}/answer`, { answer });
    } catch (error) {
        console.error('Failed to submit quiz answer', error);
    }
  }

  goToNextQuestion() {
    if (this.state.currentQuestionIndex < this.state.questions.length - 1) {
      runInAction(() => {
        this.state.currentQuestionIndex++;
        this.state.selectedAnswer = null;
        this.state.isAnswerCorrect = null;
        this.state.showExplanation = false;
      });
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

    const points = score * 10; // Example scoring

    try {
        await this.rootStore.virtueStore.completeQuiz(selectedVirtue.id, selectedLevel, points);
        runInAction(() => {
            this.state.quizCompleted = true;
            this.state.showConfetti = true;
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            toast.success(`Quiz completed! You earned ${points} points.`);
        });
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
    this.setError(null);
    this.setLoading(false);
  }
}
