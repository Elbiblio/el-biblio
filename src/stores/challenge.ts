import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { PaginatedResponse } from '@/types';
import { Challenge, ChallengeType, DailyChallenge } from '@/types/challenges';
import { toast } from 'sonner-native';
import { User } from '@/types';

interface ChallengeState {
  // Challenge lists
  personalChallenges: Challenge[];
  communityChallenges: Challenge[];
  suggestedChallenges: Challenge[];
  
  // Loading states
  isPersonalLoading: boolean;
  isCommunityLoading: boolean;
  isSuggestedLoading: boolean;
  isCreatingLoading: boolean;
  isJoiningLoading: boolean;
  isUpvotingLoading: boolean;
  
  // Error states
  personalError: string | null;
  communityError: string | null;
  suggestedError: string | null;
  createError: string | null;
  
  // UI state
  activeCategory: 'personal' | 'community' | 'suggested';
  showNewChallengeForm: boolean;
  refreshing: boolean;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Actions
  fetchPersonalChallenges: (page?: number) => Promise<void>;
  fetchCommunityChallenges: (page?: number) => Promise<void>;
  fetchSuggestedChallenges: (page?: number) => Promise<void>;
  fetchDailyChallenges: () => Promise<void>;
  
  // Challenge management
  createChallenge: (data: {
    title: string;
    description?: string;
    type: 'virtue' | 'vice';
    category: 'personal' | 'community';
    endTime: string;
    mode?: 'attitude' | 'action';
    frequency?: 'd' | 'w' | 'm' | 'o';
  }) => Promise<Challenge | null>;
  
  updateChallenge: (id: string, data: Partial<Challenge>) => Promise<boolean>;
  deleteChallenge: (id: string) => Promise<boolean>;
  
  // Challenge interactions
  joinChallenge: (challengeId: string) => Promise<boolean>;
  leaveChallenge: (challengeId: string) => Promise<boolean>;
  upvoteChallenge: (challengeId: string) => Promise<boolean>;
  completeChallenge: (challengeId: string, isCompleted: boolean) => Promise<boolean>;
  
  // Add suggested challenge to personal
  addSuggestedToPersonal: (challengeId: string) => Promise<boolean>;
  
  // State management
  setActiveCategory: (category: ChallengeState['activeCategory']) => void;
  setShowNewChallengeForm: (show: boolean) => void;
  setRefreshing: (refreshing: boolean) => void;
  clearErrors: () => void;
  refreshAll: () => Promise<void>;
  refreshChallenges: () => Promise<void>;
  fetchChallengeParticipants: (challengeId: string, page: number) => Promise<{
    challenge: Challenge;
    participants: User[];
    pagination: {
      current_page: number;
      last_page: number;
      per_page: number;
      total: number;
    };
  } | null>;
}

export const useChallengeStore = create<ChallengeState>((set, get) => ({
  // Initial State
  personalChallenges: [],
  communityChallenges: [],
  suggestedChallenges: [],
  
  isPersonalLoading: false,
  isCommunityLoading: false,
  isSuggestedLoading: false,
  isCreatingLoading: false,
  isJoiningLoading: false,
  isUpvotingLoading: false,
  
  personalError: null,
  communityError: null,
  suggestedError: null,
  createError: null,
  
  activeCategory: 'personal',
  showNewChallengeForm: false,
  refreshing: false,
  
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },
  
  // Actions
  fetchPersonalChallenges: async (page = 1) => {
    try {
      set({ isPersonalLoading: true, personalError: null });
      
      const response = await apiClient.get<PaginatedResponse<Challenge>>(
        endpoints.challenges.personal,
        {
          page,
          per_page: get().pagination.perPage,
          include: ['user', 'participants'],
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch personal challenges');
      }
      
      const { data, meta } = response.data;
      
      set({
        personalChallenges: page === 1 ? data : [...get().personalChallenges, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isPersonalLoading: false,
      });

    } catch (error) {
      console.error('Error fetching personal challenges:', error);
      set({
        isPersonalLoading: false,
        personalError: error instanceof Error ? error.message : 'Failed to fetch personal challenges',
      });
    }
  },

  fetchCommunityChallenges: async (page = 1) => {
    try {
      set({ isCommunityLoading: true, communityError: null });
      
      const response = await apiClient.get<PaginatedResponse<Challenge>>(
        endpoints.challenges.community,
        {
          page,
          per_page: get().pagination.perPage,
          include: ['user', 'participants'],
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch community challenges');
      }
      
      const { data, meta } = response.data;
      
      set({
        communityChallenges: page === 1 ? data : [...get().communityChallenges, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isCommunityLoading: false,
      });

    } catch (error) {
      console.error('Error fetching community challenges:', error);
      set({
        isCommunityLoading: false,
        communityError: error instanceof Error ? error.message : 'Failed to fetch community challenges',
      });
    }
  },

  fetchSuggestedChallenges: async (page = 1) => {
    try {
      set({ isSuggestedLoading: true, suggestedError: null });
      
      const response = await apiClient.get<PaginatedResponse<Challenge>>(
        endpoints.challenges.suggested,
        {
          page,
          per_page: get().pagination.perPage,
          include: ['user'],
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch suggested challenges');
      }
      
      const { data, meta } = response.data;
      
      set({
        suggestedChallenges: page === 1 ? data : [...get().suggestedChallenges, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isSuggestedLoading: false,
      });

    } catch (error) {
      console.error('Error fetching suggested challenges:', error);
      set({
        isSuggestedLoading: false,
        suggestedError: error instanceof Error ? error.message : 'Failed to fetch suggested challenges',
      });
    }
  },

  fetchDailyChallenges: async () => {
    try {
      const response = await apiClient.get<DailyChallenge[]>(
        endpoints.challenges.daily
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch daily challenges');
      }
      
      // Process daily challenges and update relevant lists
      const dailyChallenges = response.data;
      
      // You might want to merge these with existing challenges or handle them differently
      // For now, we'll just log them
      console.log('Daily challenges fetched:', dailyChallenges);
      
    } catch (error) {
      console.error('Error fetching daily challenges:', error);
    }
  },

  createChallenge: async (data) => {
    try {
      set({ isCreatingLoading: true, createError: null });
      
      const response = await apiClient.post<Challenge>(
        endpoints.challenges.create,
        {
          title: data.title,
          description: data.description || '',
          type: data.type,
          category: data.category,
          mode: data.mode || 'action',
          frequency: data.frequency || 'd',
          end_time: data.endTime,
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create challenge');
      }
      
      const newChallenge = response.data;
      
      // Add to appropriate list
      if (data.category === 'personal') {
        set(state => ({
          personalChallenges: [newChallenge, ...state.personalChallenges],
        }));
      } else if (data.category === 'community') {
        set(state => ({
          communityChallenges: [newChallenge, ...state.communityChallenges],
        }));
      }
      
      set({ isCreatingLoading: false });
      toast.success('Challenge created successfully!');
      
      return newChallenge;
    } catch (error) {
      console.error('Error creating challenge:', error);
      set({
        isCreatingLoading: false,
        createError: error instanceof Error ? error.message : 'Failed to create challenge',
      });
      return null;
    }
  },

  updateChallenge: async (id: string, data: Partial<Challenge>) => {
    try {
      const response = await apiClient.put<Challenge>(
        endpoints.challenges.update(id),
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update challenge');
      }
      
      const updatedChallenge = response.data;
      
      // Update in all relevant lists
      set(state => ({
        personalChallenges: state.personalChallenges.map(c => 
          c.id === id ? updatedChallenge : c
        ),
        communityChallenges: state.communityChallenges.map(c => 
          c.id === id ? updatedChallenge : c
        ),
        suggestedChallenges: state.suggestedChallenges.map(c => 
          c.id === id ? updatedChallenge : c
        ),
      }));
      
      return true;
    } catch (error) {
      console.error('Error updating challenge:', error);
      return false;
    }
  },

  deleteChallenge: async (id: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.challenges.delete(id)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete challenge');
      }
      
      // Remove from all lists
      set(state => ({
        personalChallenges: state.personalChallenges.filter(c => c.id !== id),
        communityChallenges: state.communityChallenges.filter(c => c.id !== id),
        suggestedChallenges: state.suggestedChallenges.filter(c => c.id !== id),
      }));
      
      toast.success('Challenge deleted successfully');
      return true;
    } catch (error) {
      console.error('Error deleting challenge:', error);
      return false;
    }
  },

  joinChallenge: async (challengeId: string) => {
    try {
      set({ isJoiningLoading: true });
      
      const response = await apiClient.post(
        endpoints.challenges.join(challengeId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to join challenge');
      }
      
      // Update challenge in lists
      set(state => {
        const updateChallenge = (challenge: Challenge) => {
          if (challenge.id === challengeId) {
            return {
              ...challenge,
              hasJoined: true,
              participants: (challenge.participants || 0) + 1,
            };
          }
          return challenge;
        };

        return {
          communityChallenges: state.communityChallenges.map(updateChallenge),
          suggestedChallenges: state.suggestedChallenges.map(updateChallenge),
        };
      });
      
      set({ isJoiningLoading: false });
      toast.success('Joined challenge successfully!');
      return true;
    } catch (error) {
      console.error('Error joining challenge:', error);
      set({ isJoiningLoading: false });
      return false;
    }
  },

  leaveChallenge: async (challengeId: string) => {
    try {
      set({ isJoiningLoading: true });
      
      const response = await apiClient.post(
        endpoints.challenges.leave(challengeId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to leave challenge');
      }
      
      // Update challenge in lists
      set(state => {
        const updateChallenge = (challenge: Challenge) => {
          if (challenge.id === challengeId) {
            return {
              ...challenge,
              hasJoined: false,
              participants: Math.max(0, (challenge.participants || 1) - 1),
            };
          }
          return challenge;
        };

        return {
          communityChallenges: state.communityChallenges.map(updateChallenge),
          suggestedChallenges: state.suggestedChallenges.map(updateChallenge),
        };
      });
      
      set({ isJoiningLoading: false });
      toast.success('Left challenge successfully');
      return true;
    } catch (error) {
      console.error('Error leaving challenge:', error);
      set({ isJoiningLoading: false });
      return false;
    }
  },

  upvoteChallenge: async (challengeId: string) => {
    try {
      set({ isUpvotingLoading: true });
      
      const response = await apiClient.post(
        endpoints.challenges.upvote(challengeId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to upvote challenge');
      }
      
      // Update challenge in lists
      set(state => {
        const updateChallenge = (challenge: Challenge) => {
          if (challenge.id === challengeId) {
            return {
              ...challenge,
              hasUpvoted: !challenge.hasUpvoted,
              upvotes: challenge.hasUpvoted 
                ? Math.max(0, (challenge.upvotes || 1) - 1)
                : (challenge.upvotes || 0) + 1,
            };
          }
          return challenge;
        };

        return {
          communityChallenges: state.communityChallenges.map(updateChallenge),
          suggestedChallenges: state.suggestedChallenges.map(updateChallenge),
        };
      });
      
      set({ isUpvotingLoading: false });
      return true;
    } catch (error) {
      console.error('Error upvoting challenge:', error);
      set({ isUpvotingLoading: false });
      return false;
    }
  },

  completeChallenge: async (challengeId: string, isCompleted: boolean) => {
    try {
      const response = await apiClient.post(
        endpoints.challenges.complete(challengeId),
        { completed: isCompleted }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update challenge completion');
      }
      
      // Update challenge in lists
      set(state => {
        const updateChallenge = (challenge: Challenge) => {
          if (challenge.id === challengeId) {
            return {
              ...challenge,
              isCompleted,
              progress: isCompleted ? 100 : 0,
            };
          }
          return challenge;
        };

        return {
          personalChallenges: state.personalChallenges.map(updateChallenge),
          communityChallenges: state.communityChallenges.map(updateChallenge),
        };
      });
      
      toast.success(isCompleted ? 'Challenge completed! Great job!' : 'Challenge marked incomplete');
      return true;
    } catch (error) {
      console.error('Error completing challenge:', error);
      return false;
    }
  },

  addSuggestedToPersonal: async (challengeId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.challenges.addToPersonal(challengeId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to add challenge to personal');
      }
      
      const personalChallenge = response.data;
      
      // Add to personal challenges
      set(state => ({
        personalChallenges: [personalChallenge as Challenge, ...state.personalChallenges],
      }));
      
      toast.success('Challenge added to your personal challenges!');
      return true;
    } catch (error) {
      console.error('Error adding suggested challenge to personal:', error);
      return false;
    }
  },

  // State management
  setActiveCategory: (category) => set({ activeCategory: category }),
  setShowNewChallengeForm: (show) => set({ showNewChallengeForm: show }),
  setRefreshing: (refreshing) => set({ refreshing }),
  
  clearErrors: () => set({
    personalError: null,
    communityError: null,
    suggestedError: null,
    createError: null,
  }),
  
  refreshAll: async () => {
    set({ refreshing: true });
    
    const { activeCategory } = get();
    
    try {
      await Promise.all([
        get().fetchPersonalChallenges(1),
        get().fetchCommunityChallenges(1),
        get().fetchSuggestedChallenges(1),
      ]);
    } catch (error) {
      console.error('Error refreshing challenges:', error);
    } finally {
      set({ refreshing: false });
    }
  },

  refreshChallenges: async () => {
    try {
      await Promise.all([
        get().fetchPersonalChallenges(1),
        get().fetchCommunityChallenges(1),
        get().fetchSuggestedChallenges(1),
        get().fetchDailyChallenges(),
      ]);
    } catch (error) {
      console.error('Error refreshing challenges:', error);
    }
  },

  fetchChallengeParticipants: async (challengeId: string, page: number = 1) => {
    try {
      const response = await apiClient.get<{
        challenge: Challenge;
        participants: User[];
        pagination: {
          current_page: number;
          last_page: number;
          per_page: number;
          total: number;
        };
      }>(
        endpoints.challenges.participants(challengeId),
        {
          params: {
            page,
            per_page: 20,
            include: 'user'
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch challenge participants');
      }

      return response.data;
    } catch (error) {
      console.error('Error fetching challenge participants:', error);
      return null;
    }
  },
})); 