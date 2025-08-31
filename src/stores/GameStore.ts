import { makeObservable, action, runInAction } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient } from '@/api/client';
import { GameId, GameScore, LeaderboardEntry, PaginatedResponse } from '@/types';

interface PaginationState {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
}

interface GameStoreState {
  // Game data
  personalBests: Record<GameId, number>;
  unsyncedScores: GameScore[];
  leaderboards: Record<GameId, LeaderboardEntry[]>;
  lastSynced: Date | null;

  // Loading states
  isLoading: boolean;
  isSyncing: boolean;

  // Error states
  error: string | null;

  // Pagination
  pagination: PaginationState;
}

export class GameStore extends BaseStore<GameStoreState> {
  constructor() {
    super({
      personalBests: {},
      unsyncedScores: [],
      leaderboards: {},
      lastSynced: null,
      isLoading: false,
      isSyncing: false,
      error: null,
      pagination: {
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
        hasMore: false,
      },
    });

    makeObservable(this, {
      initialize: action.bound,
      sync: action.bound,
      submitScore: action.bound,
      fetchLeaderboard: action.bound,
      clearErrors: action.bound,
    });
  }

  async initialize() {
    try {
      runInAction(() => {
        this.state.isLoading = true;
        this.state.error = null;
      });

      // Fetch user's game data from API
      const [personalBestsResponse, leaderboardsResponse] = await Promise.all([
        apiClient.get<{ scores: Record<GameId, number> }>('/game/personal-bests'),
        apiClient.get<{ leaderboards: Record<GameId, LeaderboardEntry[]> }>('/game/leaderboards'),
      ]);

      runInAction(() => {
        if (personalBestsResponse.success) {
          this.state.personalBests = personalBestsResponse.data?.scores || {};
        }

        if (leaderboardsResponse.success) {
          this.state.leaderboards = leaderboardsResponse.data?.leaderboards || {};
        }

        this.state.lastSynced = new Date();
        this.state.isLoading = false;
      });
    } catch (error: any) {
      console.error('Error initializing game data:', error);
      runInAction(() => {
        this.state.isLoading = false;
        this.state.error = 'Failed to initialize game data';
      });
      this.setError(this.state.error);
    }
  }

  async sync() {
    if (this.state.unsyncedScores.length === 0) return;

    try {
      runInAction(() => {
        this.state.isSyncing = true;
        this.state.error = null;
      });

      // Submit all unsynced scores
      for (const score of this.state.unsyncedScores) {
        await apiClient.post('/game/scores', {
          game_id: score.gameId,
          score: score.score,
          timestamp: score.timestamp,
        });
      }

      // Fetch updated data
      const [personalBestsResponse, leaderboardsResponse] = await Promise.all([
        apiClient.get<{ scores: Record<GameId, number> }>('/game/personal-bests'),
        apiClient.get<{ leaderboards: Record<GameId, LeaderboardEntry[]> }>('/game/leaderboards'),
      ]);

      runInAction(() => {
        const newPersonalBests = personalBestsResponse.success ? personalBestsResponse.data?.scores || {} : {};
        const newLeaderboards = leaderboardsResponse.success ? leaderboardsResponse.data?.leaderboards || {} : {};

        this.state.personalBests = newPersonalBests;
        this.state.leaderboards = newLeaderboards;
        this.state.unsyncedScores = [];
        this.state.lastSynced = new Date();
        this.state.isSyncing = false;
      });
    } catch (error: any) {
      console.error('Sync error:', error);
      runInAction(() => {
        this.state.isSyncing = false;
        this.state.error = 'Failed to sync game data';
      });
      this.setError(this.state.error);
    }
  }

  async submitScore(gameId: GameId, score: number) {
    const timestamp = new Date().toISOString();
    const currentBest = this.state.personalBests[gameId] || 0;

    // Update local state immediately
    runInAction(() => {
      this.state.unsyncedScores = [
        ...this.state.unsyncedScores,
        { gameId, score, timestamp },
      ];

      if (score > currentBest) {
        this.state.personalBests = { ...this.state.personalBests, [gameId]: score };
      }
    });

    // Attempt to sync immediately
    await this.sync();
    return true;
  }

  getPersonalBest(gameId: GameId): number {
    return this.state.personalBests[gameId] || 0;
  }

  getLeaderboard(gameId: GameId): LeaderboardEntry[] {
    return this.state.leaderboards[gameId] || [];
  }

  async fetchLeaderboard(gameId: GameId, page = 1) {
    try {
      runInAction(() => {
        this.state.isLoading = true;
        this.state.error = null;
      });

      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        `/game/leaderboards/${gameId}`,
        { page, per_page: 20 }
      );

      if (response.success && response.data) {
        const { data, meta } = response.data;
        
        runInAction(() => {
          this.state.leaderboards = {
            ...this.state.leaderboards,
            [gameId]: page === 1 ? data : [...(this.state.leaderboards[gameId] || []), ...data],
          };
          this.state.pagination = {
            currentPage: meta.current_page,
            lastPage: meta.last_page,
            perPage: meta.per_page,
            total: meta.total,
            hasMore: meta.current_page < meta.last_page,
          };
          this.state.isLoading = false;
        });
      }
    } catch (error: any) {
      console.error('Error fetching leaderboard:', error);
      runInAction(() => {
        this.state.isLoading = false;
        this.state.error = 'Failed to fetch leaderboard';
      });
      this.setError(this.state.error);
    }
  }

  clearErrors() {
    runInAction(() => {
      this.state.error = null;
    });
    this.setError(null);
  }
}
