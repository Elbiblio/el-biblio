import { runInAction, makeAutoObservable } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { Virtue, VirtueProgress, VIRTUE_NOTES, AppVirtue, VirtueGroups, AllVirtues, FoundationalVirtue } from '@/types';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

interface PaginationState {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
}

interface QuizQuestion {
  id: string;
  question: string;
  options: string[];
  correctAnswer: string;
  explanation?: string;
  verseReference?: string;
  virtue: AllVirtues;
}

interface VirtueStoreState {
  // Virtues
  virtues: Virtue[];
  isVirtuesLoading: boolean;
  virtuesError: string | null;

  // User progress
  userProgress: Record<string, VirtueProgress>;
  isProgressLoading: boolean;
  progressError: string | null;

  // Virtue notes
  virtueNotes: VIRTUE_NOTES[];
  isNotesLoading: boolean;
  notesError: string | null;

  // Featured virtues
  featuredVirtues: Virtue[];
  isFeaturedLoading: boolean;
  featuredError: string | null;

  // Virtue groups
  virtueGroups: VirtueGroups;
  isGroupsLoading: boolean;
  groupsError: string | null;

  // Quiz data
  quizQuestions: QuizQuestion[];
  isQuizLoading: boolean;
  quizError: string | null;

  // Pagination
  pagination: PaginationState;

  // Real-time updates
  isConnected: boolean;
  lastUpdate: Date | null;
  // Current focus/goal virtue
  currentGoalVirtueId?: string;
}

export class VirtueStore {
  state: VirtueStoreState;
  error: string | null = null;
  // Public Getters
  get virtues() {
    return this.state.virtues;
  }

  // Current Goal persistence
  private CURRENT_GOAL_KEY = 'virtue_store.current_goal_virtue_id';

  get currentGoalVirtueId() {
    return this.state.currentGoalVirtueId;
  }

  async setCurrentGoal(virtueId?: string) {
    try {
      runInAction(() => {
        this.state.currentGoalVirtueId = virtueId;
      });
      if (virtueId) {
        await AsyncStorage.setItem(this.CURRENT_GOAL_KEY, virtueId);
      } else {
        await AsyncStorage.removeItem(this.CURRENT_GOAL_KEY);
      }
      toast.success(virtueId ? 'Current goal set' : 'Current goal cleared');
    } catch (error) {
      console.error('Error setting current goal virtue:', error);
    }
  }

  private async loadCurrentGoal() {
    try {
      const stored = await AsyncStorage.getItem(this.CURRENT_GOAL_KEY);
      if (stored) {
        runInAction(() => {
          this.state.currentGoalVirtueId = stored;
        });
      }
    } catch (error) {
      console.warn('Failed to load current goal virtue');
    }
  }

  get userProgress() {
    return this.state.userProgress;
  }

  get isVirtuesLoading() {
    return this.state.isVirtuesLoading;
  }

  get isProgressLoading() {
    return this.state.isProgressLoading;
  }

  get virtuesError() {
    return this.state.virtuesError;
  }

  get progressError() {
    return this.state.progressError;
  }

  get virtueNotes() {
    return this.state.virtueNotes;
  }

  get isNotesLoading() {
    return this.state.isNotesLoading;
  }

  get notesError() {
    return this.state.notesError;
  }

  get virtueGroups() {
    return this.state.virtueGroups;
  }

  constructor() {
    this.state = {
      virtues: [],
      isVirtuesLoading: false,
      virtuesError: null,

      userProgress: {},
      isProgressLoading: false,
      progressError: null,

      virtueNotes: [],
      isNotesLoading: false,
      notesError: null,

      featuredVirtues: [],
      isFeaturedLoading: false,
      featuredError: null,

      virtueGroups: {
        foundational: { name: 'Foundational Virtues', virtues: ['knowledge', 'humility', 'faith', 'love'] },
        derived: { name: 'Derived Virtues', virtues: ['wisdom', 'discernment', 'prudence', 'self-control', 'self-restraint', 'patience', 'gentleness', 'obedience', 'trust', 'hope', 'perseverance', 'courage', 'fortitude', 'compassion', 'kindness', 'generosity', 'goodness', 'selflessness'] },
        compound: { name: 'Compound Virtues', virtues: ['righteousness', 'justice', 'joy', 'peace', 'gratitude', 'respect', 'honesty'] }
      },
      isGroupsLoading: false,
      groupsError: null,

      quizQuestions: [],
      isQuizLoading: false,
      quizError: null,

      pagination: {
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
        hasMore: false,
      },

      isConnected: false,
      lastUpdate: null,
      currentGoalVirtueId: undefined,
    };

    makeAutoObservable(this, {}, { autoBind: true });

    // Load persisted goal from storage
    this.loadCurrentGoal().catch(() => {});
  }

  private setError(message: string | null) {
    this.error = message;
  }

  async fetchVirtues(page = 1) {
    try {
      runInAction(() => {
        this.state.isVirtuesLoading = true;
        this.state.virtuesError = null;
      });

      const response = await apiClient.get<Virtue[]>(
        endpoints.themes.list,
        {
          include: ['userProgress'],
          sort: 'name',
          per_page: this.state.pagination.perPage,
          page
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch virtues');

      runInAction(() => {
        this.state.virtues = page === 1 ? response.data : [...this.state.virtues, ...response.data];
        this.state.isVirtuesLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching virtues:', error);
      runInAction(() => {
        this.state.isVirtuesLoading = false;
        this.state.virtuesError = error instanceof Error ? error.message : 'Failed to fetch virtues';
      });
      this.setError(this.state.virtuesError);
    }
  }

  async fetchVirtueById(id: string) {
    try {
      runInAction(() => {
        this.state.isVirtuesLoading = true;
        this.state.virtuesError = null;
      });

      const response = await apiClient.get<Virtue>(
        endpoints.themes.show(id),
        { include: ['userProgress'] }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch virtue');

      runInAction(() => {
        this.state.isVirtuesLoading = false;
        this.state.lastUpdate = new Date();
      });

      return response.data;
    } catch (error: any) {
      console.error('Error fetching virtue:', error);
      runInAction(() => {
        this.state.isVirtuesLoading = false;
        this.state.virtuesError = error instanceof Error ? error.message : 'Failed to fetch virtue';
      });
      this.setError(this.state.virtuesError);
      return null;
    }
  }

  async fetchUserProgress() {
    try {
      runInAction(() => {
        this.state.isProgressLoading = true;
        this.state.progressError = null;
      });

      const response = await apiClient.get<VirtueProgress[]>(
        endpoints.themes.byUser('me'),
        { include: ['userProgress'] }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch user progress');

      // Convert array to record for easier access
      const progressRecord: Record<string, VirtueProgress> = {};
      response.data.forEach(progress => {
        progressRecord[progress.virtue] = progress;
      });

      runInAction(() => {
        this.state.userProgress = progressRecord;
        this.state.isProgressLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching user progress:', error);
      runInAction(() => {
        this.state.isProgressLoading = false;
        this.state.progressError = error instanceof Error ? error.message : 'Failed to fetch user progress';
      });
      this.setError(this.state.progressError);
    }
  }

  async updateUserProgress(virtueId: string, progress: Partial<VirtueProgress>) {
    try {
      const currentProgress = this.state.userProgress[virtueId];
      if (!currentProgress) {
        throw new Error('No progress found for this virtue');
      }

      const response = await apiClient.put(
        endpoints.themes.update(virtueId),
        { userProgress: progress }
      );

      if (!response.success) throw new Error(response.message || 'Failed to update progress');

      // Update local state
      runInAction(() => {
        this.state.userProgress[virtueId] = { ...currentProgress, ...progress };
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Progress updated!');

      return true;
    } catch (error: any) {
      console.error('Error updating progress:', error);
      const message = error instanceof Error ? error.message : 'Failed to update progress';
      toast.error(message);
      return false;
    }
  }

  async fetchVirtueNotes(virtueId?: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isNotesLoading = true;
        this.state.notesError = null;
      });

      const params: any = {
        include: ['author', 'denomination'],
        sort: '-created_at',
        per_page: this.state.pagination.perPage,
        page
      };

      if (virtueId) {
        params.theme_id = virtueId;
      }

      const response = await apiClient.get<VIRTUE_NOTES[]>(endpoints.notes.list, params);

      if (!response.success) throw new Error(response.message || 'Failed to fetch virtue notes');

      runInAction(() => {
        this.state.virtueNotes = page === 1 ? response.data : [...this.state.virtueNotes, ...response.data];
        this.state.isNotesLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching virtue notes:', error);
      runInAction(() => {
        this.state.isNotesLoading = false;
        this.state.notesError = error instanceof Error ? error.message : 'Failed to fetch virtue notes';
      });
      this.setError(this.state.notesError);
    }
  }

  async createVirtueNote(data: {
    title: string;
    content: string;
    theme_id: FoundationalVirtue;
    denomination?: string;
  }) {
    try {
      const response = await apiClient.post<VIRTUE_NOTES>(endpoints.notes.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create note');

      // Add to local state
      runInAction(() => {
        this.state.virtueNotes = [response.data, ...this.state.virtueNotes];
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Note created successfully!');

      return response.data;
    } catch (error: any) {
      console.error('Error creating note:', error);
      const message = error instanceof Error ? error.message : 'Failed to create note';
      toast.error(message);
      return null;
    }
  }

  async updateVirtueNote(id: string, data: Partial<VIRTUE_NOTES>) {
    try {
      const response = await apiClient.put(endpoints.notes.update(id), data);

      if (!response.success) throw new Error(response.message || 'Failed to update note');

      // Update local state
      runInAction(() => {
        this.state.virtueNotes = this.state.virtueNotes.map(note => 
          note.id === id ? { ...note, ...data } : note
        );
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Note updated successfully!');

      return true;
    } catch (error: any) {
      console.error('Error updating note:', error);
      const message = error instanceof Error ? error.message : 'Failed to update note';
      toast.error(message);
      return false;
    }
  }

  async deleteVirtueNote(id: string) {
    try {
      const response = await apiClient.delete(endpoints.notes.delete(id));

      if (!response.success) throw new Error(response.message || 'Failed to delete note');

      // Remove from local state
      runInAction(() => {
        this.state.virtueNotes = this.state.virtueNotes.filter(note => note.id !== id);
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Note deleted successfully!');

      return true;
    } catch (error: any) {
      console.error('Error deleting note:', error);
      const message = error instanceof Error ? error.message : 'Failed to delete note';
      toast.error(message);
      return false;
    }
  }

  async fetchFeaturedVirtues() {
    try {
      runInAction(() => {
        this.state.isFeaturedLoading = true;
        this.state.featuredError = null;
      });

      const response = await apiClient.get<Virtue[]>(
        endpoints.themes.foundational,
        {
          include: ['userProgress'],
          featured: true
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch featured virtues');

      runInAction(() => {
        this.state.featuredVirtues = response.data;
        this.state.isFeaturedLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching featured virtues:', error);
      runInAction(() => {
        this.state.isFeaturedLoading = false;
        this.state.featuredError = error instanceof Error ? error.message : 'Failed to fetch featured virtues';
      });
      this.setError(this.state.featuredError);
    }
  }

  async fetchVirtueGroups() {
    try {
      runInAction(() => {
        this.state.isGroupsLoading = true;
        this.state.groupsError = null;
      });

      // This would typically come from an API endpoint
      // For now, we'll use the static groups defined in types
      const groups: VirtueGroups = {
        foundational: { name: 'Foundational Virtues', virtues: ['knowledge', 'humility', 'faith', 'love'] },
        derived: { name: 'Derived Virtues', virtues: ['wisdom', 'discernment', 'prudence', 'self-control', 'self-restraint', 'patience', 'gentleness', 'obedience', 'trust', 'hope', 'perseverance', 'courage', 'fortitude', 'compassion', 'kindness', 'generosity', 'goodness', 'selflessness'] },
        compound: { name: 'Compound Virtues', virtues: ['righteousness', 'justice', 'joy', 'peace', 'gratitude', 'respect', 'honesty'] }
      };

      runInAction(() => {
        this.state.virtueGroups = groups;
        this.state.isGroupsLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching virtue groups:', error);
      runInAction(() => {
        this.state.isGroupsLoading = false;
        this.state.groupsError = error instanceof Error ? error.message : 'Failed to fetch virtue groups';
      });
      this.setError(this.state.groupsError);
    }
  }

  async fetchQuizQuestions(virtueId: string, level: number) {
    try {
      runInAction(() => {
        this.state.isQuizLoading = true;
        this.state.quizError = null;
      });

      const response = await apiClient.get<QuizQuestion[]>(
        `/virtues/${virtueId}/quiz`,
        {
          level,
          include: ['explanations', 'verse_references']
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch quiz questions');

      runInAction(() => {
        this.state.quizQuestions = response.data;
        this.state.isQuizLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching quiz questions:', error);
      runInAction(() => {
        this.state.isQuizLoading = false;
        this.state.quizError = error instanceof Error ? error.message : 'Failed to fetch quiz questions';
      });
      this.setError(this.state.quizError);
    }
  }

  async submitQuizAnswer(questionId: string, answer: string) {
    try {
      const response = await apiClient.post<{ correct: boolean }>(
        `/quiz-questions/${questionId}/answer`,
        { answer }
      );

      if (!response.success) throw new Error(response.message || 'Failed to submit answer');

      return response.data.correct;
    } catch (error) {
      console.error('Error submitting answer:', error);
      return false;
    }
  }

  async completeQuiz(virtueId: string, level: number, score: number) {
    try {
      const response = await apiClient.post(
        `/virtues/${virtueId}/quiz/complete`,
        { level, score }
      );

      if (!response.success) throw new Error(response.message || 'Failed to complete quiz');

      // Update user progress
      const currentProgress = this.state.userProgress[virtueId];
      if (currentProgress) {
        const newProgress = {
          ...currentProgress,
          total_points: currentProgress.total_points + score,
          total_challenges: currentProgress.total_challenges + 1,
          current_level: Math.max(currentProgress.current_level, level)
        };

        runInAction(() => {
          this.state.userProgress[virtueId] = newProgress;
        });
      }

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success(`Quiz completed! You earned ${score} points.`);

      return true;
    } catch (error: any) {
      console.error('Error completing quiz:', error);
      const message = error instanceof Error ? error.message : 'Failed to complete quiz';
      toast.error(message);
      return false;
    }
  }

  async likeVirtue(virtueId: string) {
    try {
      const response = await apiClient.post(`/virtues/${virtueId}/like`);

      if (!response.success) throw new Error(response.message || 'Failed to like virtue');

      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Virtue liked!');

      return true;
    } catch (error: any) {
      console.error('Error liking virtue:', error);
      const message = error instanceof Error ? error.message : 'Failed to like virtue';
      toast.error(message);
      return false;
    }
  }

  async bookmarkVirtue(virtueId: string) {
    try {
      const response = await apiClient.post(
        endpoints.bookmarks.create,
        {
          bookmarkable_type: 'Virtue',
          bookmarkable_id: virtueId
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to bookmark virtue');

      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Virtue bookmarked!');

      return true;
    } catch (error: any) {
      console.error('Error bookmarking virtue:', error);
      const message = error instanceof Error ? error.message : 'Failed to bookmark virtue';
      toast.error(message);
      return false;
    }
  }

  async shareVirtue(virtueId: string) {
    try {
      const response = await apiClient.post(`/virtues/${virtueId}/share`);

      if (!response.success) throw new Error(response.message || 'Failed to share virtue');

      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Virtue shared!');

      return true;
    } catch (error: any) {
      console.error('Error sharing virtue:', error);
      const message = error instanceof Error ? error.message : 'Failed to share virtue';
      toast.error(message);
      return false;
    }
  }

  // Real-time updates
  setConnectionStatus(isConnected: boolean) {
    runInAction(() => {
      this.state.isConnected = isConnected;
    });
  }

  updateVirtueInRealTime(virtueId: string, updates: Partial<Virtue>) {
    runInAction(() => {
      this.state.virtues = this.state.virtues.map(virtue => 
        virtue.id === virtueId ? { ...virtue, ...updates } : virtue
      );
      this.state.featuredVirtues = this.state.featuredVirtues.map(virtue => 
        virtue.id === virtueId ? { ...virtue, ...updates } : virtue
      );
    });
  }

  updateProgressInRealTime(virtueId: string, updates: Partial<VirtueProgress>) {
    runInAction(() => {
      if (this.state.userProgress[virtueId]) {
        this.state.userProgress[virtueId] = { ...this.state.userProgress[virtueId], ...updates };
      }
    });
  }

  // State management
  clearErrors() {
    runInAction(() => {
      this.state.virtuesError = null;
      this.state.progressError = null;
      this.state.notesError = null;
      this.state.featuredError = null;
      this.state.groupsError = null;
      this.state.quizError = null;
    });
    this.setError(null);
  }

  resetQuizState() {
    runInAction(() => {
      this.state.quizQuestions = [];
      this.state.isQuizLoading = false;
      this.state.quizError = null;
    });
  }

  getVirtueWithProgress(virtueId: string): AppVirtue | null {
    const virtue = this.state.virtues.find(v => v.id === virtueId);
    const progress = this.state.userProgress[virtueId];

    if (!virtue) return null;

    return {
      ...virtue,
      userProgress: progress
    } as AppVirtue;
  }

  getVirtuesByGroup(group: keyof VirtueGroups): AppVirtue[] {
    const groupVirtues = this.state.virtueGroups[group].virtues;

    return groupVirtues.map(virtueId => {
      const virtue = this.state.virtues.find(v => v.id === virtueId);
      const progress = this.state.userProgress[virtueId];

      return {
        ...virtue,
        userProgress: progress
      } as AppVirtue;
    }).filter(Boolean);
  }
}
