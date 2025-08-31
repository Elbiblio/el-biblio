import { makeObservable, action, runInAction } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient, endpoints } from '@/api/client';
import { LeaderboardEntry, UserStats, PaginatedResponse } from '@/types';

export type Timeframe = 'all' | 'day' | 'week' | 'month';

interface PaginationState {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
}

interface LeaderboardStoreState {
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
  pagination: PaginationState;

  // Filters
  filters: {
    timeframe: Timeframe;
    themeId?: string;
    perPage: number;
  };
}

export class LeaderboardStore extends BaseStore<LeaderboardStoreState> {
  constructor() {
    super({
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
    });

    makeObservable(this, {
      fetchGlobalLeaderboard: action.bound,
      fetchThemeLeaderboard: action.bound,
      fetchTimeframeLeaderboard: action.bound,
      fetchUserRank: action.bound,
      fetchUserStats: action.bound,
      fetchGlobalStats: action.bound,
      setFilters: action.bound,
      resetFilters: action.bound,
      clearErrors: action.bound,
    });
  }

  private computePagination(meta: any, fallbackPage: number, currentTotal: number): PaginationState {
    const current_page = (meta && typeof meta.current_page === 'number') ? meta.current_page : fallbackPage;
    const last_page = (meta && typeof meta.last_page === 'number') ? meta.last_page : current_page;
    const per_page = (meta && typeof meta.per_page === 'number') ? meta.per_page : this.state.pagination.perPage;
    const total = (meta && typeof meta.total === 'number') ? meta.total : (currentTotal ?? 0);
    const hasMore = (typeof current_page === 'number' && typeof last_page === 'number')
      ? current_page < last_page
      : currentTotal >= per_page;

    return {
      currentPage: current_page,
      lastPage: last_page,
      perPage: per_page,
      total,
      hasMore,
    };
  }

  async fetchGlobalLeaderboard(page = 1, timeframe: Timeframe = 'all') {
    try {
      runInAction(() => {
        this.state.isGlobalLoading = true;
        this.state.globalError = null;
      });

      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        endpoints.leaderboards.global,
        {
          per_page: this.state.filters.perPage,
          page,
          timeframe,
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch global leaderboard');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.globalLeaderboard = page === 1 ? data : [...this.state.globalLeaderboard, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters.timeframe = timeframe;
        this.state.isGlobalLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching global leaderboard:', error);
      runInAction(() => {
        this.state.isGlobalLoading = false;
        this.state.globalError = error instanceof Error ? error.message : 'Failed to fetch global leaderboard';
      });
      this.setError(this.state.globalError);
    }
  }

  async fetchThemeLeaderboard(themeId: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isThemeLoading = true;
        this.state.themeError = null;
      });

      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        endpoints.leaderboards.byTheme(themeId),
        {
          per_page: this.state.filters.perPage,
          page,
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch theme leaderboard');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.themeLeaderboard = page === 1 ? data : [...this.state.themeLeaderboard, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters.themeId = themeId;
        this.state.isThemeLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching theme leaderboard:', error);
      runInAction(() => {
        this.state.isThemeLoading = false;
        this.state.themeError = error instanceof Error ? error.message : 'Failed to fetch theme leaderboard';
      });
      this.setError(this.state.themeError);
    }
  }

  async fetchTimeframeLeaderboard(timeframe: Timeframe, page = 1) {
    try {
      runInAction(() => {
        this.state.isTimeframeLoading = true;
        this.state.timeframeError = null;
      });

      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        endpoints.leaderboards.byTimeframe(timeframe),
        {
          per_page: this.state.filters.perPage,
          page,
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch timeframe leaderboard');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.timeframeLeaderboard = page === 1 ? data : [...this.state.timeframeLeaderboard, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters.timeframe = timeframe;
        this.state.isTimeframeLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching timeframe leaderboard:', error);
      runInAction(() => {
        this.state.isTimeframeLoading = false;
        this.state.timeframeError = error instanceof Error ? error.message : 'Failed to fetch timeframe leaderboard';
      });
      this.setError(this.state.timeframeError);
    }
  }

  async fetchUserRank(userId: string, timeframe: Timeframe = 'all') {
    try {
      const response = await apiClient.get<{
        rank: number;
        total_users: number;
        user: any;
      }>(
        endpoints.leaderboards.userRank(userId),
        { timeframe }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch user rank');

      return response.data;
    } catch (error) {
      console.error('Error fetching user rank:', error);
      return null;
    }
  }

  async fetchUserStats(userId: string) {
    try {
      runInAction(() => {
        this.state.isUserStatsLoading = true;
        this.state.userStatsError = null;
      });

      const response = await apiClient.get<UserStats>(endpoints.stats.user(userId));

      if (!response.success) throw new Error(response.message || 'Failed to fetch user stats');

      runInAction(() => {
        this.state.userStats = response.data;
        this.state.isUserStatsLoading = false;
      });

      return response.data;
    } catch (error: any) {
      console.error('Error fetching user stats:', error);
      runInAction(() => {
        this.state.isUserStatsLoading = false;
        this.state.userStatsError = error instanceof Error ? error.message : 'Failed to fetch user stats';
      });
      this.setError(this.state.userStatsError);
      return null;
    }
  }

  async fetchGlobalStats() {
    try {
      runInAction(() => {
        this.state.isGlobalStatsLoading = true;
        this.state.globalStatsError = null;
      });

      const response = await apiClient.get<{
        total_users: number;
        total_verses: number;
        total_reflections: number;
        total_meditation_sessions: number;
        total_challenges_completed: number;
        total_activities_today: number;
        total_activities_this_week: number;
        total_activities_this_month: number;
      }>(endpoints.stats.global);

      if (!response.success) throw new Error(response.message || 'Failed to fetch global stats');

      runInAction(() => {
        this.state.globalStats = response.data;
        this.state.isGlobalStatsLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching global stats:', error);
      runInAction(() => {
        this.state.isGlobalStatsLoading = false;
        this.state.globalStatsError = error instanceof Error ? error.message : 'Failed to fetch global stats';
      });
      this.setError(this.state.globalStatsError);
    }
  }

  clearErrors() {
    runInAction(() => {
      this.state.globalError = null;
      this.state.themeError = null;
      this.state.timeframeError = null;
      this.state.userStatsError = null;
      this.state.globalStatsError = null;
    });
    this.setError(null);
  }

  setFilters(filters: Partial<LeaderboardStoreState['filters']>) {
    runInAction(() => {
      this.state.filters = { ...this.state.filters, ...filters };
    });
  }

  resetFilters() {
    runInAction(() => {
      this.state.filters = {
        timeframe: 'all',
        perPage: 20,
      };
    });
  }
}
