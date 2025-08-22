import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { Virtue, VirtueProgress, VIRTUE_NOTES, AppVirtue, VirtueGroups, AllVirtues, FoundationalVirtue } from '@/types';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

interface VirtueState {
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
  quizQuestions: Array<{
    id: string;
    question: string;
    options: string[];
    correctAnswer: string;
    explanation?: string;
    verseReference?: string;
    virtue: AllVirtues;
  }>;
  isQuizLoading: boolean;
  quizError: string | null;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Real-time updates
  isConnected: boolean;
  lastUpdate: Date | null;
  
  // Actions
  fetchVirtues: (page?: number) => Promise<void>;
  fetchVirtueById: (id: string) => Promise<Virtue | null>;
  fetchUserProgress: () => Promise<void>;
  updateUserProgress: (virtueId: string, progress: Partial<VirtueProgress>) => Promise<boolean>;
  
  // Virtue notes
  fetchVirtueNotes: (virtueId?: string, page?: number) => Promise<void>;
  createVirtueNote: (data: {
    title: string;
    content: string;
    theme_id: FoundationalVirtue;
    denomination?: string;
  }) => Promise<VIRTUE_NOTES | null>;
  updateVirtueNote: (id: string, data: Partial<VIRTUE_NOTES>) => Promise<boolean>;
  deleteVirtueNote: (id: string) => Promise<boolean>;
  
  // Featured content
  fetchFeaturedVirtues: () => Promise<void>;
  fetchVirtueGroups: () => Promise<void>;
  
  // Quiz functionality
  fetchQuizQuestions: (virtueId: string, level: number) => Promise<void>;
  submitQuizAnswer: (questionId: string, answer: string) => Promise<boolean>;
  completeQuiz: (virtueId: string, level: number, score: number) => Promise<boolean>;
  
  // Virtue interactions
  likeVirtue: (virtueId: string) => Promise<boolean>;
  bookmarkVirtue: (virtueId: string) => Promise<boolean>;
  shareVirtue: (virtueId: string) => Promise<boolean>;
  
  // Real-time updates
  setConnectionStatus: (isConnected: boolean) => void;
  updateVirtueInRealTime: (virtueId: string, updates: Partial<Virtue>) => void;
  updateProgressInRealTime: (virtueId: string, updates: Partial<VirtueProgress>) => void;
  
  // State management
  clearErrors: () => void;
  resetQuizState: () => void;
  getVirtueWithProgress: (virtueId: string) => AppVirtue | null;
  getVirtuesByGroup: (group: keyof VirtueGroups) => AppVirtue[];
}

export const useVirtueStore = create<VirtueState>((set, get) => ({
  // Initial State
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
  
  // Actions
  fetchVirtues: async (page = 1) => {
    try {
      set({ isVirtuesLoading: true, virtuesError: null });
      
      const response = await apiClient.get<Virtue[]>(
        endpoints.themes.list,
        {
          params: {
            include: ['userProgress'],
            sort: 'name',
            per_page: get().pagination.perPage,
            page
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch virtues');
      }
      
      set({
        virtues: page === 1 ? response.data : [...get().virtues, ...response.data],
        isVirtuesLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching virtues:', error);
      set({ 
        isVirtuesLoading: false,
        virtuesError: error instanceof Error ? error.message : 'Failed to fetch virtues'
      });
    }
  },

  fetchVirtueById: async (id: string) => {
    try {
      set({ isVirtuesLoading: true, virtuesError: null });
      
      const response = await apiClient.get<Virtue>(
        endpoints.themes.show(id),
        {
          params: {
            include: ['userProgress']
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch virtue');
      }
      
      set({ 
        isVirtuesLoading: false,
        lastUpdate: new Date(),
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching virtue:', error);
      set({ 
        isVirtuesLoading: false,
        virtuesError: error instanceof Error ? error.message : 'Failed to fetch virtue'
      });
      return null;
    }
  },

  fetchUserProgress: async () => {
    try {
      set({ isProgressLoading: true, progressError: null });
      
      const response = await apiClient.get<VirtueProgress[]>(
        endpoints.themes.byUser('me'),
        {
          params: {
            include: ['userProgress']
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch user progress');
      }
      
      // Convert array to record for easier access
      const progressRecord: Record<string, VirtueProgress> = {};
      response.data.forEach(progress => {
        progressRecord[progress.virtue] = progress;
      });
      
      set({
        userProgress: progressRecord,
        isProgressLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching user progress:', error);
      set({ 
        isProgressLoading: false,
        progressError: error instanceof Error ? error.message : 'Failed to fetch user progress'
      });
    }
  },

  updateUserProgress: async (virtueId: string, progress: Partial<VirtueProgress>) => {
    try {
      const currentProgress = get().userProgress[virtueId];
      if (!currentProgress) {
        throw new Error('No progress found for this virtue');
      }
      
      const response = await apiClient.put(
        endpoints.themes.update(virtueId),
        { userProgress: progress }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update progress');
      }
      
      // Update local state
      set(state => ({
        userProgress: {
          ...state.userProgress,
          [virtueId]: { ...currentProgress, ...progress }
        }
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Progress updated!');
      
      return true;
    } catch (error) {
      console.error('Error updating progress:', error);
      const message = error instanceof Error ? error.message : 'Failed to update progress';
      toast.error(message);
      return false;
    }
  },

  fetchVirtueNotes: async (virtueId?: string, page = 1) => {
    try {
      set({ isNotesLoading: true, notesError: null });
      
      const params: any = {
        include: ['author', 'denomination'],
        sort: '-created_at',
        per_page: get().pagination.perPage,
        page
      };
      
      if (virtueId) {
        params.theme_id = virtueId;
      }
      
      const response = await apiClient.get<VIRTUE_NOTES[]>(
        endpoints.notes.list,
        { params }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch virtue notes');
      }
      
      set({
        virtueNotes: page === 1 ? response.data : [...get().virtueNotes, ...response.data],
        isNotesLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching virtue notes:', error);
      set({ 
        isNotesLoading: false,
        notesError: error instanceof Error ? error.message : 'Failed to fetch virtue notes'
      });
    }
  },

  createVirtueNote: async (data) => {
    try {
      const response = await apiClient.post<VIRTUE_NOTES>(
        endpoints.notes.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create note');
      }
      
      // Add to local state
      set(state => ({
        virtueNotes: [response.data, ...state.virtueNotes]
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Note created successfully!');
      
      return response.data;
    } catch (error) {
      console.error('Error creating note:', error);
      const message = error instanceof Error ? error.message : 'Failed to create note';
      toast.error(message);
      return null;
    }
  },

  updateVirtueNote: async (id: string, data: Partial<VIRTUE_NOTES>) => {
    try {
      const response = await apiClient.put(
        endpoints.notes.update(id),
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update note');
      }
      
      // Update local state
      set(state => ({
        virtueNotes: state.virtueNotes.map(note => 
          note.id === id ? { ...note, ...data } : note
        )
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Note updated successfully!');
      
      return true;
    } catch (error) {
      console.error('Error updating note:', error);
      const message = error instanceof Error ? error.message : 'Failed to update note';
      toast.error(message);
      return false;
    }
  },

  deleteVirtueNote: async (id: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.notes.delete(id)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete note');
      }
      
      // Remove from local state
      set(state => ({
        virtueNotes: state.virtueNotes.filter(note => note.id !== id)
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Note deleted successfully!');
      
      return true;
    } catch (error) {
      console.error('Error deleting note:', error);
      const message = error instanceof Error ? error.message : 'Failed to delete note';
      toast.error(message);
      return false;
    }
  },

  fetchFeaturedVirtues: async () => {
    try {
      set({ isFeaturedLoading: true, featuredError: null });
      
      const response = await apiClient.get<Virtue[]>(
        endpoints.themes.foundational,
        {
          params: {
            include: ['userProgress'],
            featured: true
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch featured virtues');
      }
      
      set({
        featuredVirtues: response.data,
        isFeaturedLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching featured virtues:', error);
      set({ 
        isFeaturedLoading: false,
        featuredError: error instanceof Error ? error.message : 'Failed to fetch featured virtues'
      });
    }
  },

  fetchVirtueGroups: async () => {
    try {
      set({ isGroupsLoading: true, groupsError: null });
      
      // This would typically come from an API endpoint
      // For now, we'll use the static groups defined in types
      const groups: VirtueGroups = {
        foundational: { name: 'Foundational Virtues', virtues: ['knowledge', 'humility', 'faith', 'love'] },
        derived: { name: 'Derived Virtues', virtues: ['wisdom', 'discernment', 'prudence', 'self-control', 'self-restraint', 'patience', 'gentleness', 'obedience', 'trust', 'hope', 'perseverance', 'courage', 'fortitude', 'compassion', 'kindness', 'generosity', 'goodness', 'selflessness'] },
        compound: { name: 'Compound Virtues', virtues: ['righteousness', 'justice', 'joy', 'peace', 'gratitude', 'respect', 'honesty'] }
      };
      
      set({
        virtueGroups: groups,
        isGroupsLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching virtue groups:', error);
      set({ 
        isGroupsLoading: false,
        groupsError: error instanceof Error ? error.message : 'Failed to fetch virtue groups'
      });
    }
  },

  fetchQuizQuestions: async (virtueId: string, level: number) => {
    try {
      set({ isQuizLoading: true, quizError: null });
      
      const response = await apiClient.get<Array<{
        id: string;
        question: string;
        options: string[];
        correctAnswer: string;
        explanation?: string;
        verseReference?: string;
        virtue: AllVirtues;
      }>>(
        `/virtues/${virtueId}/quiz`,
        {
          params: {
            level,
            include: ['explanations', 'verse_references']
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch quiz questions');
      }
      
      set({
        quizQuestions: response.data,
        isQuizLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching quiz questions:', error);
      set({ 
        isQuizLoading: false,
        quizError: error instanceof Error ? error.message : 'Failed to fetch quiz questions'
      });
    }
  },

  submitQuizAnswer: async (questionId: string, answer: string) => {
    try {
      const response = await apiClient.post<{ correct: boolean }>(
        `/quiz-questions/${questionId}/answer`,
        { answer }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to submit answer');
      }
      
      return response.data.correct;
    } catch (error) {
      console.error('Error submitting answer:', error);
      return false;
    }
  },

  completeQuiz: async (virtueId: string, level: number, score: number) => {
    try {
      const response = await apiClient.post(
        `/virtues/${virtueId}/quiz/complete`,
        { level, score }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to complete quiz');
      }
      
      // Update user progress
      const currentProgress = get().userProgress[virtueId];
      if (currentProgress) {
        const newProgress = {
          ...currentProgress,
          total_points: currentProgress.total_points + score,
          total_challenges: currentProgress.total_challenges + 1,
          current_level: Math.max(currentProgress.current_level, level)
        };
        
        set(state => ({
          userProgress: {
            ...state.userProgress,
            [virtueId]: newProgress
          }
        }));
      }
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success(`Quiz completed! You earned ${score} points.`);
      
      return true;
    } catch (error) {
      console.error('Error completing quiz:', error);
      const message = error instanceof Error ? error.message : 'Failed to complete quiz';
      toast.error(message);
      return false;
    }
  },

  likeVirtue: async (virtueId: string) => {
    try {
      const response = await apiClient.post(
        `/virtues/${virtueId}/like`
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to like virtue');
      }
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Virtue liked!');
      
      return true;
    } catch (error) {
      console.error('Error liking virtue:', error);
      const message = error instanceof Error ? error.message : 'Failed to like virtue';
      toast.error(message);
      return false;
    }
  },

  bookmarkVirtue: async (virtueId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.bookmarks.create,
        {
          bookmarkable_type: 'Virtue',
          bookmarkable_id: virtueId
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to bookmark virtue');
      }
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Virtue bookmarked!');
      
      return true;
    } catch (error) {
      console.error('Error bookmarking virtue:', error);
      const message = error instanceof Error ? error.message : 'Failed to bookmark virtue';
      toast.error(message);
      return false;
    }
  },

  shareVirtue: async (virtueId: string) => {
    try {
      const response = await apiClient.post(
        `/virtues/${virtueId}/share`
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to share virtue');
      }
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Virtue shared!');
      
      return true;
    } catch (error) {
      console.error('Error sharing virtue:', error);
      const message = error instanceof Error ? error.message : 'Failed to share virtue';
      toast.error(message);
      return false;
    }
  },

  // Real-time updates
  setConnectionStatus: (isConnected: boolean) => {
    set({ isConnected });
  },

  updateVirtueInRealTime: (virtueId: string, updates: Partial<Virtue>) => {
    set(state => ({
      virtues: state.virtues.map(virtue => 
        virtue.id === virtueId ? { ...virtue, ...updates } : virtue
      ),
      featuredVirtues: state.featuredVirtues.map(virtue => 
        virtue.id === virtueId ? { ...virtue, ...updates } : virtue
      )
    }));
  },

  updateProgressInRealTime: (virtueId: string, updates: Partial<VirtueProgress>) => {
    set(state => ({
      userProgress: {
        ...state.userProgress,
        [virtueId]: { ...state.userProgress[virtueId], ...updates }
      }
    }));
  },

  // State management
  clearErrors: () => {
    set({ 
      virtuesError: null, 
      progressError: null, 
      notesError: null, 
      featuredError: null, 
      groupsError: null,
      quizError: null
    });
  },

  resetQuizState: () => {
    set({
      quizQuestions: [],
      isQuizLoading: false,
      quizError: null,
    });
  },

  getVirtueWithProgress: (virtueId: string) => {
    const state = get();
    const virtue = state.virtues.find(v => v.id === virtueId);
    const progress = state.userProgress[virtueId];
    
    if (!virtue) return null;
    
    return {
      ...virtue,
      userProgress: progress
    } as AppVirtue;
  },

  getVirtuesByGroup: (group: keyof VirtueGroups) => {
    const state = get();
    const groupVirtues = state.virtueGroups[group].virtues;
    
    return groupVirtues.map(virtueId => {
      const virtue = state.virtues.find(v => v.id === virtueId);
      const progress = state.userProgress[virtueId];
      
      return {
        ...virtue,
        userProgress: progress
      } as AppVirtue;
    }).filter(Boolean);
  },
})); 