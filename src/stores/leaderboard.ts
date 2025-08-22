import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { LeaderboardEntry, UserStats, PaginatedResponse } from '@/types';

interface LeaderboardState {
  // Global leaderboard
  globalLeaderboard: LeaderboardEntry[];
  isGlobalLoading: boolean;
  globalError: string | null;
  
  // Theme leaderboard
  themeLeaderboard: LeaderboardEntry[];
  isThemeLoading: boolean;
  themeError: string | null;
  
  // Time-based leaderboard
  timeframeLeaderboard: LeaderboardEntry[];
  isTimeframeLoading: boolean;
  timeframeError: string | null;
  
  // User stats
  userStats: UserStats | null;
  isUserStatsLoading: boolean;
  userStatsError: string | null;
  
  // Global stats
  globalStats: {
    total_users: number;
    total_verses: number;
    total_reflections: number;
    total_meditation_sessions: number;
    total_challenges_completed: number;
    total_activities_today: number;
    total_activities_this_week: number;
    total_activities_this_month: number;
  } | null;
  isGlobalStatsLoading: boolean;
  globalStatsError: string | null;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Filters
  filters: {
    timeframe: 'all' | 'day' | 'week' | 'month';
    themeId?: string;
    perPage: number;
  };
  
  // Actions
  fetchGlobalLeaderboard: (page?: number, timeframe?: string) => Promise<void>;
  fetchThemeLeaderboard: (themeId: string, page?: number) => Promise<void>;
  fetchTimeframeLeaderboard: (timeframe: 'all' | 'day' | 'week' | 'month', page?: number) => Promise<void>;
  fetchUserRank: (userId: string, timeframe?: string) => Promise<{
    rank: number;
    total_users: number;
    user: any;
  } | null>;
  fetchUserStats: (userId: string) => Promise<UserStats | null>;
  fetchGlobalStats: () => Promise<void>;
  
  // State management
  clearErrors: () => void;
  setFilters: (filters: Partial<LeaderboardState['filters']>) => void;
  resetFilters: () => void;
}

export const useLeaderboardStore = create<LeaderboardState>((set, get) => ({
  // Initial State
  globalLeaderboard: [],
  isGlobalLoading: false,
  globalError: null,
  
  themeLeaderboard: [],
  isThemeLoading: false,
  themeError: null,
  
  timeframeLeaderboard: [],
  isTimeframeLoading: false,
  timeframeError: null,
  
  userStats: null,
  isUserStatsLoading: false,
  userStatsError: null,
  
  globalStats: null,
  isGlobalStatsLoading: false,
  globalStatsError: null,
  
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },
  
  filters: {
    timeframe: 'all',
    perPage: 20,
  },
  
  // Actions
  fetchGlobalLeaderboard: async (page = 1, timeframe = 'all') => {
    try {
      set({ isGlobalLoading: true, globalError: null });
      
      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        endpoints.leaderboards.global,
        {
          per_page: get().filters.perPage,
          page,
          timeframe,
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch global leaderboard');
      }
      
      const { data, meta } = response.data;
      
      set({
        globalLeaderboard: page === 1 ? data : [...get().globalLeaderboard, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        filters: { ...get().filters, timeframe: timeframe as 'all' | 'day' | 'week' | 'month' },
        isGlobalLoading: false,
      });

    } catch (error) {
      console.error('Error fetching global leaderboard:', error);
      set({
        isGlobalLoading: false,
        globalError: error instanceof Error ? error.message : 'Failed to fetch global leaderboard',
      });
    }
  },

  fetchThemeLeaderboard: async (themeId: string, page = 1) => {
    try {
      set({ isThemeLoading: true, themeError: null });
      
      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        endpoints.leaderboards.byTheme(themeId),
        {
          per_page: get().filters.perPage,
          page,
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch theme leaderboard');
      }
      
      const { data, meta } = response.data;
      
      set({
        themeLeaderboard: page === 1 ? data : [...get().themeLeaderboard, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        filters: { ...get().filters, themeId },
        isThemeLoading: false,
      });

    } catch (error) {
      console.error('Error fetching theme leaderboard:', error);
      set({
        isThemeLoading: false,
        themeError: error instanceof Error ? error.message : 'Failed to fetch theme leaderboard',
      });
    }
  },

  fetchTimeframeLeaderboard: async (timeframe: 'all' | 'day' | 'week' | 'month', page = 1) => {
    try {
      set({ isTimeframeLoading: true, timeframeError: null });
      
      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        endpoints.leaderboards.byTimeframe(timeframe),
        {
          per_page: get().filters.perPage,
          page,
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch timeframe leaderboard');
      }
      
      const { data, meta } = response.data;
      
      set({
        timeframeLeaderboard: page === 1 ? data : [...get().timeframeLeaderboard, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        filters: { ...get().filters, timeframe },
        isTimeframeLoading: false,
      });

    } catch (error) {
      console.error('Error fetching timeframe leaderboard:', error);
      set({
        isTimeframeLoading: false,
        timeframeError: error instanceof Error ? error.message : 'Failed to fetch timeframe leaderboard',
      });
    }
  },

  fetchUserRank: async (userId: string, timeframe = 'all') => {
    try {
      const response = await apiClient.get<{
        rank: number;
        total_users: number;
        user: any;
      }>(
        endpoints.leaderboards.userRank(userId),
        {
          timeframe,
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch user rank');
      }
      
      return response.data;
    } catch (error) {
      console.error('Error fetching user rank:', error);
      return null;
    }
  },

  fetchUserStats: async (userId: string) => {
    try {
      set({ isUserStatsLoading: true, userStatsError: null });
      
      const response = await apiClient.get<UserStats>(
        endpoints.stats.user(userId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch user stats');
      }
      
      set({
        userStats: response.data,
        isUserStatsLoading: false,
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching user stats:', error);
      set({
        isUserStatsLoading: false,
        userStatsError: error instanceof Error ? error.message : 'Failed to fetch user stats',
      });
      return null;
    }
  },

  fetchGlobalStats: async () => {
    try {
      set({ isGlobalStatsLoading: true, globalStatsError: null });
      
      const response = await apiClient.get<{
        total_users: number;
        total_verses: number;
        total_reflections: number;
        total_meditation_sessions: number;
        total_challenges_completed: number;
        total_activities_today: number;
        total_activities_this_week: number;
        total_activities_this_month: number;
      }>(
        endpoints.stats.global
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch global stats');
      }
      
      set({
        globalStats: response.data,
        isGlobalStatsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching global stats:', error);
      set({
        isGlobalStatsLoading: false,
        globalStatsError: error instanceof Error ? error.message : 'Failed to fetch global stats',
      });
    }
  },

  clearErrors: () => {
    set({
      globalError: null,
      themeError: null,
      timeframeError: null,
      userStatsError: null,
      globalStatsError: null,
    });
  },

  setFilters: (filters) => {
    set(state => ({
      filters: { ...state.filters, ...filters },
    }));
  },

  resetFilters: () => {
    set({
      filters: {
        timeframe: 'all',
        perPage: 20,
      },
    });
  },
})); 