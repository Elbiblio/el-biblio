import { makeAutoObservable, runInAction } from 'mobx';
import { Activity } from '@/types';
import { apiClient, endpoints } from '@/api/client';
import { AuthStore } from './AuthStore';

type JourneyPhaseStatus = 'locked' | 'available' | 'completed';

export interface JourneyPhase {
  id: string;
  title: string;
  summary: string;
  description: string;
  quizQuestionCount: number;
  order: number;
}

export interface JourneyQuizQuestion {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
}

export interface JourneyPhaseWithStatus extends JourneyPhase {
  status: JourneyPhaseStatus;
}

interface QuizState {
  activePhaseId: string | null;
  questions: JourneyQuizQuestion[];
  currentIndex: number;
  correctCount: number;
  isComplete: boolean;
  result: 'pass' | 'fail' | null;
}

const PASS_RATIO = 0.7;

const createEmptyQuizState = (): QuizState => ({
  activePhaseId: null,
  questions: [],
  currentIndex: 0,
  correctCount: 0,
  isComplete: false,
  result: null,
});

export class JourneyStore {
  phases: JourneyPhase[] = [];
  phaseStatus: Record<string, JourneyPhaseStatus> = {};
  quizState: QuizState = createEmptyQuizState();
  activities: Activity[] = [];
  isActivitiesLoading = false;
  activityError: string | null = null;

  private authStore: AuthStore;

  constructor(authStore: AuthStore) {
    this.authStore = authStore;
    makeAutoObservable(this, {}, { autoBind: true });
    this.initializePhaseState();
  }

  private get orderedPhases(): JourneyPhase[] {
    return [...this.phases].sort((a, b) => a.order - b.order);
  }

  get journeyPhases(): JourneyPhaseWithStatus[] {
    return this.orderedPhases.map(phase => ({
      ...phase,
      status: this.getPhaseStatus(phase.id),
    }));
  }

  get currentPhase(): JourneyPhaseWithStatus | null {
    const next = this.journeyPhases.find(phase => phase.status !== 'completed');
    return next ?? (this.journeyPhases.length > 0 ? this.journeyPhases[this.journeyPhases.length - 1] : null);
  }

  get maxUnlockedOrder(): number {
    let max = 0;
    for (const phase of this.orderedPhases) {
      const status = this.phaseStatus[phase.id];
      if (status === 'available' || status === 'completed') {
        if (phase.order > max) {
          max = phase.order;
        }
      }
    }
    return max === 0 ? 1 : max;
  }

  initializePhaseState() {
    const defaultPhases: JourneyPhase[] = [
      {
        id: 'accept-jesus',
        title: 'Accept Jesus',
        summary: 'Embrace salvation through Jesus Christ.',
        description: 'Explore the foundations of faith and make a personal commitment to Jesus.',
        quizQuestionCount: 10,
        order: 1,
      },
      {
        id: 'repentance',
        title: 'Repentance',
        summary: 'Turn away from sin toward a transformed life.',
        description: 'Recognize areas requiring repentance and establish rhythms of confession.',
        quizQuestionCount: 10,
        order: 2,
      },
      {
        id: 'activation-holy-spirit',
        title: 'Activation of the Holy Spirit',
        summary: 'Invite and respond to the Holy Spirit’s leadership.',
        description: 'Identify spiritual gifts and cultivate sensitivity to the Spirit’s guidance.',
        quizQuestionCount: 10,
        order: 3,
      },
      {
        id: 'bearing-fruits',
        title: 'Bearing of Fruits',
        summary: 'Demonstrate growth through spiritual fruit.',
        description: 'Assess personal fruitfulness and pursue practices that nurture growth.',
        quizQuestionCount: 10,
        order: 4,
      },
      {
        id: 'storing-treasures',
        title: 'Storing up Treasures in Heaven',
        summary: 'Invest in eternal impact and kingdom priorities.',
        description: 'Align habits and resources with heavenly values and generosity.',
        quizQuestionCount: 10,
        order: 5,
      },
      {
        id: 'giving-of-self',
        title: 'Giving of Self',
        summary: 'Offer time, talent, and treasure sacrificially.',
        description: 'Practice selfless service and cultivate a posture of continual giving.',
        quizQuestionCount: 10,
        order: 6,
      },
      {
        id: 'divine-visions',
        title: 'Divine Visions',
        summary: 'Pursue the fullness of God’s calling and revelation.',
        description: 'Discern vision, stewardship, and obedience to divine assignments.',
        quizQuestionCount: 3,
        order: 7,
      },
    ];

    runInAction(() => {
      this.phases = defaultPhases;
      const status: Record<string, JourneyPhaseStatus> = {};
      defaultPhases.forEach((phase, index) => {
        if (index === 0) {
          status[phase.id] = 'available';
        } else {
          status[phase.id] = 'locked';
        }
      });
      this.phaseStatus = status;
    });
  }

  async fetchActivities() {
    const userId = this.authStore.user?.id;
    if (!userId) {
      runInAction(() => {
        this.activities = [];
        this.activityError = 'User not authenticated';
      });
      return;
    }

    runInAction(() => {
      this.isActivitiesLoading = true;
      this.activityError = null;
    });

    try {
      const response = await apiClient.get<Activity[]>(endpoints.users.activity(String(userId)), {
        include: ['subject'],
        per_page: 20,
      });

      runInAction(() => {
        if (response.success) {
          this.activities = Array.isArray(response.data) ? response.data : [];
        } else {
          this.activityError = response.message || 'Failed to load activity feed';
        }
        this.isActivitiesLoading = false;
      });
    } catch (error) {
      console.error('JourneyStore.fetchActivities error', error);
      runInAction(() => {
        this.activityError = 'Failed to load activity feed';
        this.isActivitiesLoading = false;
      });
    }
  }

  startPhaseQuiz(phaseId: string) {
    if (!this.phaseStatus[phaseId] || this.phaseStatus[phaseId] === 'locked') return;
    const questions = this.buildPlaceholderQuestions(phaseId);

    runInAction(() => {
      this.quizState = {
        activePhaseId: phaseId,
        questions,
        currentIndex: 0,
        correctCount: 0,
        isComplete: false,
        result: null,
      };
    });
  }

  submitAnswer(optionIndex: number) {
    if (!this.quizState.activePhaseId || this.quizState.isComplete) return;
    const question = this.quizState.questions[this.quizState.currentIndex];
    const isCorrect = question ? optionIndex === question.correctIndex : false;
    this.answerQuestion(isCorrect);
  }

  answerQuestion(isCorrect: boolean) {
    if (!this.quizState.activePhaseId || this.quizState.isComplete) return;

    const nextCorrectCount = this.quizState.correctCount + (isCorrect ? 1 : 0);
    const nextIndex = this.quizState.currentIndex + 1;
    const totalQuestions = this.quizState.questions.length;

    if (nextIndex >= totalQuestions) {
      const passed = totalQuestions === 0 ? false : nextCorrectCount / totalQuestions >= PASS_RATIO;
      runInAction(() => {
        this.quizState = {
          ...this.quizState,
          correctCount: nextCorrectCount,
          currentIndex: nextIndex,
          isComplete: true,
          result: passed ? 'pass' : 'fail',
        };
        if (passed && this.quizState.activePhaseId) {
          this.onQuizPassed(this.quizState.activePhaseId);
        }
      });
      return;
    }

    runInAction(() => {
      this.quizState = {
        ...this.quizState,
        correctCount: nextCorrectCount,
        currentIndex: nextIndex,
      };
    });
  }

  resetQuiz() {
    runInAction(() => {
      this.quizState = createEmptyQuizState();
    });
  }

  onQuizPassed(phaseId: string) {
    const ordered = [...this.phases].sort((a, b) => a.order - b.order);
    const index = ordered.findIndex(phase => phase.id === phaseId);
    if (index === -1) return;

    runInAction(() => {
      this.phaseStatus[phaseId] = 'completed';
      const nextPhase = ordered[index + 1];
      if (nextPhase) {
        this.phaseStatus[nextPhase.id] = 'available';
      }
    });
  }

  getPhaseStatus(phaseId: string): JourneyPhaseStatus {
    return this.phaseStatus[phaseId] ?? 'locked';
  }

  private buildPlaceholderQuestions(phaseId: string): JourneyQuizQuestion[] {
    const phase = this.phases.find(item => item.id === phaseId);
    const total = phase?.quizQuestionCount ?? 10;
    const title = phase?.title ?? 'Journey';
    return Array.from({ length: total }).map((_, index) => ({
      id: `${phaseId}-${index + 1}`,
      prompt: `Question ${index + 1}: How are you applying ${title.toLowerCase()} in your life?`,
      options: ['Consistently', 'Sometimes', 'Rarely', 'Not yet'],
      correctIndex: 0,
    }));
  }
}
