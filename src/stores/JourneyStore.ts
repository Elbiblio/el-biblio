import { makeObservable, runInAction, observable, action, computed, reaction } from 'mobx';
import { Activity } from '@/types';
import { apiClient, endpoints } from '@/api/client';
import { AuthStore } from './AuthStore';
import JourneyQuizLibrary from '@/utils/JourneyQuizLibrary';
import { toast } from 'sonner-native';

export type JourneyPhaseStatus = 'locked' | 'available' | 'completed';

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

export interface QuizState {
  activePhaseId: string | null;
  questions: JourneyQuizQuestion[];
  currentIndex: number;
  correctCount: number;
  isComplete: boolean;
  result: 'pass' | 'fail' | null;
}

export interface JourneyPhaseWithStatus extends JourneyPhase {
  status: JourneyPhaseStatus;
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

export interface JourneyUserProgress {
  level?: number;
  phase?: number;
  bible_plan?: Record<string, unknown> | null;
  daily_plan?: Record<string, unknown> | null;
}

export class JourneyStore {
  phases: JourneyPhase[] = [];
  phaseStatus: Record<string, JourneyPhaseStatus> = {};
  quizState: QuizState = createEmptyQuizState();
  activities: Activity[] = [];
  isActivitiesLoading = false;
  activityError: string | null = null;
  justCompletedPhase: string | null = null;
  lastPhaseCompletedAt: number | null = null;

  private authStore: AuthStore;

  constructor(authStore: AuthStore) {
    this.authStore = authStore;
    
    makeObservable(this, {
      quizState: observable,
      activities: observable,
      isActivitiesLoading: observable,
      activityError: observable,
      justCompletedPhase: observable,
      biblePlan: observable,
      dailyPlan: observable,
      lastPhaseCompletedAt: observable,
      
      // computed
      level: computed,
      currentPhaseNumber: computed,
      userProgressPayload: computed,

      // Actions
      setJustCompletedPhase: action,
      clearJustCompletedPhase: action,
      setBiblePlan: action,
      setDailyPlan: action,
      updateUserLevelAndPhase: action,
      // Add other actions here as needed
    }, { autoBind: true });
    
    this.initializePhaseState();

    reaction(
      () => this.authStore.user?.phase,
      (phaseOrder) => {
        this.hydratePhaseProgress(phaseOrder);
      },
      { fireImmediately: true }
    );
  }

  biblePlan: Record<string, unknown> | null = null;
  dailyPlan: Record<string, unknown> | null = null;

  setBiblePlan(plan: Record<string, unknown> | null) {
    this.biblePlan = plan;
    void this.syncUserProgress();
  }

  setDailyPlan(plan: Record<string, unknown> | null) {
    this.dailyPlan = plan;
    void this.syncUserProgress();
  }

  get userProgressPayload(): JourneyUserProgress {
    return {
      level: this.level,
      phase: this.currentPhaseNumber,
      bible_plan: this.biblePlan,
      daily_plan: this.dailyPlan,
    };
  }

  async updateUserLevelAndPhase(level?: number, phase?: number) {
    const payload: JourneyUserProgress = {};
    if (typeof level === 'number') payload.level = level;
    if (typeof phase === 'number') payload.phase = phase;
    await this.syncUserProgress(payload);
  }

  async syncUserProgress(extra?: JourneyUserProgress) {
    const userId = this.authStore.user?.id;
    if (!userId) {
      return;
    }

    const merged: JourneyUserProgress = {
      ...this.userProgressPayload,
      ...extra,
    };

    try {
      await apiClient.put(endpoints.users.update(userId), {
        level: merged.level,
        phase: merged.phase,
        bible_plan: merged.bible_plan,
        daily_plan: merged.daily_plan,
      });
    } catch (error) {
      console.warn('[JourneyStore] Failed to sync user progress', error);
    }
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

  get level(): number {
    const completedCount = this.journeyPhases.filter(phase => this.phaseStatus[phase.id] === 'completed').length;
    return Math.min(10, Math.max(1, completedCount + 1));
  }

  get currentPhaseNumber(): number {
    const current = this.currentPhase;
    if (!current) return 1;
    const ordered = this.orderedPhases;
    const index = ordered.findIndex(p => p.id === current.id);
    return index === -1 ? 1 : index + 1;
  }

  get currentPhase(): JourneyPhaseWithStatus | null {
    // If there's an active quiz, return the phase that's currently being quizzed
    if (this.quizState.activePhaseId) {
      const activePhase = this.journeyPhases.find(phase => phase.id === this.quizState.activePhaseId);
      if (activePhase) return activePhase;
    }

    // Otherwise, find the next available phase
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
        quizQuestionCount: 5, // Updated to match actual quiz questions
        order: 1,
      },
      {
        id: 'repentance',
        title: 'Repentance',
        summary: 'Turn away from sin toward a transformed life.',
        description: 'Recognize areas requiring repentance and establish rhythms of confession.',
        quizQuestionCount: 5, // Updated to match actual quiz questions
        order: 2,
      },
      {
        id: 'activation-holy-spirit',
        title: 'Activation of the Holy Spirit',
        summary: 'Invite and respond to the Holy Spirit’s leadership.',
        description: 'Identify spiritual gifts and cultivate sensitivity to the Spirit’s guidance.',
        quizQuestionCount: 5, // Updated to match actual quiz questions
        order: 3,
      },
      {
        id: 'bearing-fruits',
        title: 'Bearing of Fruits',
        summary: 'Demonstrate growth through spiritual fruit.',
        description: 'Assess personal fruitfulness and pursue practices that nurture growth.',
        quizQuestionCount: 5, // Updated to match actual quiz questions
        order: 4,
      },
      {
        id: 'storing-treasures',
        title: 'Storing up Treasures in Heaven',
        summary: 'Invest in eternal impact and kingdom priorities.',
        description: 'Align habits and resources with heavenly values and generosity.',
        quizQuestionCount: 5, // Updated to match actual quiz questions
        order: 5,
      },
      {
        id: 'giving-of-self',
        title: 'Giving of Self',
        summary: 'Offer time, talent, and treasure sacrificially.',
        description: 'Practice selfless service and cultivate a posture of continual giving.',
        quizQuestionCount: 5, // Updated to match actual quiz questions
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

  private hydratePhaseProgress(phaseOrder?: number | null) {
    const ordered = this.orderedPhases;
    if (ordered.length === 0) return;

    const normalizedPhase = typeof phaseOrder === 'number' && phaseOrder > 0 ? phaseOrder : 1;

    runInAction(() => {
      ordered.forEach((phase) => {
        if (phase.order < normalizedPhase) {
          this.phaseStatus[phase.id] = 'completed';
        } else if (phase.order === normalizedPhase) {
          this.phaseStatus[phase.id] = 'available';
        } else {
          this.phaseStatus[phase.id] = 'locked';
        }
      });

      // If user phase exceeds last defined phase, mark all as completed
      const lastPhase = ordered[ordered.length - 1];
      if (lastPhase && normalizedPhase > lastPhase.order) {
        ordered.forEach((phase) => {
          this.phaseStatus[phase.id] = 'completed';
        });
      }
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
        if (response?.success && Array.isArray(response.data)) {
          this.activities = response.data;
        } else {
          this.activities = [];
          this.activityError = response?.message || 'Invalid response format';
        }
        this.isActivitiesLoading = false;
      });
    } catch (error) {
      console.error('JourneyStore.fetchActivities error', error);
      runInAction(() => {
        this.activities = [];
        this.activityError = 'Failed to load activity feed';
        this.isActivitiesLoading = false;
      });
    }
  }

  startPhaseQuiz(phaseId: string) {
    const status = this.phaseStatus[phaseId];
    if (!status || status === 'locked') return;

    const phase = this.phases.find(p => p.id === phaseId);
    const now = Date.now();

    // Restrict guests from phases beyond 5
    if (this.authStore.isGuest && phase && phase.order > 5) {
      toast(
        'Account Upgrade Required',
        {
          description: 'We would like to know you better. Please create a full account to proceed.',
        }
      );

      runInAction(() => {
        this.authStore.authPromptIntent = 'guest_signup';
        this.authStore.authRequired = true;
      });
      return;
    }

    // Throttle phase progress: only one new phase per 4 hours
    if (status !== 'completed' && this.lastPhaseCompletedAt) {
      const elapsedMs = now - this.lastPhaseCompletedAt;
      const fourHourMs = 4 * 60 * 60 * 1000;
      if (elapsedMs < fourHourMs) {
        toast(
          'That was fast, please try again later.',
          {
            description: 'The journey of a thousand miles begins with one step.',
          }
        );
        return;
      }
    }

    const existingState = this.quizState;
    const questions = this.buildPlaceholderQuestions(phaseId);
    const isResumingSamePhase =
      existingState.activePhaseId === phaseId && !existingState.isComplete;

    runInAction(() => {
      const nextCurrentIndex = isResumingSamePhase
        ? Math.min(existingState.currentIndex, questions.length)
        : 0;
      const nextCorrectCount = isResumingSamePhase
        ? Math.min(existingState.correctCount, questions.length)
        : 0;

      this.quizState = {
        activePhaseId: phaseId,
        questions,
        currentIndex: nextCurrentIndex,
        correctCount: nextCorrectCount,
        isComplete: false,
        result: null,
      };
    });

    // Safety check: ensure currentIndex is within bounds
    runInAction(() => {
      if (this.quizState.currentIndex >= this.quizState.questions.length) {
        this.quizState.currentIndex = 0;
      }
    });
  }

  submitAnswer(optionIndex: number) {
    if (!this.quizState.activePhaseId || this.quizState.isComplete) return;
    // These are affirmations, not tests - any answer advances
    this.answerQuestion(true);
  }

  answerQuestion(isCorrect: boolean) {
    if (!this.quizState.activePhaseId || this.quizState.isComplete) return;

    const nextCorrectCount = this.quizState.correctCount + (isCorrect ? 1 : 0);
    const nextIndex = this.quizState.currentIndex + 1;
    const totalQuestions = this.quizState.questions.length;

    if (nextIndex >= totalQuestions) {
      // Affirmation complete - always pass
      runInAction(() => {
        this.quizState = {
          ...this.quizState,
          correctCount: totalQuestions,
          currentIndex: nextIndex,
          isComplete: true,
          result: 'pass',
        };
        if (this.quizState.activePhaseId) {
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

  setJustCompletedPhase(phaseId: string) {
    this.justCompletedPhase = phaseId;
  }

  clearJustCompletedPhase() {
    this.justCompletedPhase = null;
  }

  onQuizPassed(phaseId: string) {
    const ordered = [...this.phases].sort((a, b) => a.order - b.order);
    const index = ordered.findIndex(phase => phase.id === phaseId);
    if (index === -1) return;

    runInAction(() => {
      this.phaseStatus[phaseId] = 'completed';
      const nextPhase = ordered[index + 1];

      // Only unlock next phase automatically if within allowed range
      if (nextPhase) {
        if (this.authStore.isGuest && nextPhase.order > 5) {
          toast(
            'Upgrade to continue your journey',
            {
              description: 'To unlock phase ' + nextPhase.order + ' and beyond, please create a full account.',
            }
          );
        } else {
          this.phaseStatus[nextPhase.id] = 'available';
        }
      }

      this.lastPhaseCompletedAt = Date.now();
    });

    void this.updateUserLevelAndPhase(this.level, this.currentPhaseNumber);
  }

  getPhaseStatus(phaseId: string): JourneyPhaseStatus {
    return this.phaseStatus[phaseId] ?? 'locked';
  }

  private buildPlaceholderQuestions(phaseId: string): JourneyQuizQuestion[] {
    const quiz = JourneyQuizLibrary.getQuiz(phaseId);
    return quiz ? quiz.questions : [];
  }
}
