import { runInAction, makeAutoObservable } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { LeaderboardEntry, UserStats, PaginatedResponse, BackendUserStats } from '@/types';

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

export class LeaderboardStore {
  state: LeaderboardStoreState;
  // Optional general error holder
  error: string | null = null;

  constructor() {
    this.state = {
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
    };

    // Auto-bind class methods so `this` remains correct when methods are passed around
    makeAutoObservable(this, {}, { autoBind: true });
  }

  private setError(message: string | null) {
    this.error = message;
  }

  async refreshGlobalLeaderboard(timeframe: Timeframe = 'all') {
    // Refresh the first page with the selected timeframe
    await this.fetchGlobalLeaderboard(1, timeframe);
  }

  async loadMoreGlobalLeaderboard() {
    const { pagination, filters } = this.state;
    if (!pagination?.hasMore) return;
    const next = (pagination.currentPage || 1) + 1;
    await this.fetchGlobalLeaderboard(next, filters.timeframe);
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

      if (!response || !response.success || !response.data) {
        const errMsg = response?.message || 'Failed to fetch user rank';
        const err = new Error(errMsg);
        (err as any).status = (response as any)?.status;
        (err as any).response = response as any;
        throw err;
      }

      return response.data;
    } catch (error) {
      const status = (error as any)?.status || (error as any)?.response?.status;
      const message = (error as any)?.message ? String((error as any).message) : '';
      const serverMessage = (error as any)?.response?.message || (error as any)?.response?.data?.message;
      const details = (error as any)?.response?.data || (error as any)?.data || null;
      // Suppress noisy logs when user rank is simply not found yet
      if (status === 404 || message.includes('Resource not found')) {
        // Do not log, but rethrow so callers (e.g., HomeScreen) can handle logout for deleted guest accounts
        throw error;
      }
      console.error('Error fetching user rank:', { status, message, serverMessage, details });
      return null;
    }
  }

  async fetchUserStats(userId: string) {
    try {
      runInAction(() => {
        this.state.isUserStatsLoading = true;
        this.state.userStatsError = null;
      });

      const response = await apiClient.get<BackendUserStats>(endpoints.stats.user(userId));

      if (!response || !response.success || !response.data) {
        const errMsg = response?.message || 'Failed to fetch user stats';
        const err = new Error(errMsg);
        (err as any).status = (response as any)?.status;
        (err as any).response = response as any;
        throw err;
      }

      const b = response.data;
      const mapped: UserStats = {
        totalPoints: b.total_points ?? 0,
        totalReflections: b.total_reflections ?? 0,
        totalNotes: 0,
        totalChallenges: 0,
        totalBookmarks: b.total_bookmarks ?? 0,
        // Backend provides sessions count, not minutes; keep minutes as 0 and let UI compute from sessions if needed
        totalMeditationMinutes: 0,
        totalActiveDays: b.total_active_days ?? 0,
        currentStreak: b.current_streak ?? 0,
        longestStreak: b.longest_streak ?? 0,
        // Extra fields mapped when available
        totalMeditationSessions: b.total_meditation_sessions,
        totalChallengesCompleted: b.total_challenges_completed,
        totalActiveTime: b.total_active_time,
        totalVersesRead: b.total_verses_read,
        totalActivities: b.total_activities,
        rank: b.rank,
        level: b.level,
        favoriteThemes: b.favorite_themes,
        // Not provided by backend endpoints above
        topVirtues: [],
        recentActivity: [],
      };

      runInAction(() => {
        this.state.userStats = mapped;
        this.state.isUserStatsLoading = false;
      });

      return mapped;
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

  get userStats(): UserStats | null {
    return this.state.userStats;
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
