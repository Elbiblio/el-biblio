import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { GameId, GameScore, LeaderboardEntry, PaginatedResponse } from '@/types';

interface GameState {
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
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Actions
  initialize: () => Promise<void>;
  sync: () => Promise<void>;
  submitScore: (gameId: GameId, score: number) => Promise<boolean>;
  getPersonalBest: (gameId: GameId) => number;
  getLeaderboard: (gameId: GameId) => LeaderboardEntry[];
  fetchLeaderboard: (gameId: GameId, page?: number) => Promise<void>;
  clearErrors: () => void;
}

export const useGameStore = create<GameState>((set, get) => ({
  // Initial State
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

  initialize: async () => {
    try {
      set({ isLoading: true, error: null });
      
      // Fetch user's game data from API
      const [personalBestsResponse, leaderboardsResponse] = await Promise.all([
        apiClient.get<{ scores: Record<GameId, number> }>('/game/personal-bests'),
        apiClient.get<{ leaderboards: Record<GameId, LeaderboardEntry[]> }>('/game/leaderboards'),
      ]);

      if (personalBestsResponse.success) {
        set({ personalBests: personalBestsResponse.data?.scores || {} });
      }

      if (leaderboardsResponse.success) {
        set({ leaderboards: leaderboardsResponse.data?.leaderboards || {} });
      }

      set({ lastSynced: new Date() });
    } catch (error) {
      console.error('Error initializing game data:', error);
      set({ error: 'Failed to initialize game data' });
    } finally {
      set({ isLoading: false });
    }
  },

  sync: async () => {
    const { unsyncedScores } = get();
    if (unsyncedScores.length === 0) return;

    try {
      set({ isSyncing: true, error: null });

      // Submit all unsynced scores
      for (const score of unsyncedScores) {
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

      const newPersonalBests = personalBestsResponse.success ? personalBestsResponse.data?.scores || {} : {};
      const newLeaderboards = leaderboardsResponse.success ? leaderboardsResponse.data?.leaderboards || {} : {};

      set({
        personalBests: newPersonalBests,
        leaderboards: newLeaderboards,
        unsyncedScores: [],
        lastSynced: new Date(),
      });
    } catch (error) {
      console.error('Sync error:', error);
      set({ error: 'Failed to sync game data' });
    } finally {
      set({ isSyncing: false });
    }
  },

  submitScore: async (gameId: GameId, score: number) => {
    const timestamp = new Date().toISOString();
    const currentBest = get().personalBests[gameId] || 0;

    // Update local state immediately
    set((state) => {
      const newUnsyncedScores: GameScore[] = [
        ...state.unsyncedScores,
        { gameId, score, timestamp },
      ];

      let newState: Partial<GameState> = { unsyncedScores: newUnsyncedScores };
      if (score > currentBest) {
        const newPersonalBests = { ...state.personalBests, [gameId]: score };
        newState = { ...newState, personalBests: newPersonalBests };
      }

      return newState;
    });

    // Attempt to sync immediately
    await get().sync();
    return true;
  },

  getPersonalBest: (gameId: GameId) => get().personalBests[gameId] || 0,

  getLeaderboard: (gameId: GameId) => get().leaderboards[gameId] || [],

  fetchLeaderboard: async (gameId: GameId, page = 1) => {
    try {
      set({ isLoading: true, error: null });

      const response = await apiClient.get<PaginatedResponse<LeaderboardEntry>>(
        `/game/leaderboards/${gameId}`,
        { params: { page, per_page: 20 } }
      );

      if (response.success && response.data) {
        const { data, meta } = response.data;
        set((state) => ({
          leaderboards: {
            ...state.leaderboards,
            [gameId]: page === 1 ? data : [...(state.leaderboards[gameId] || []), ...data],
          },
          pagination: {
            currentPage: meta.current_page,
            lastPage: meta.last_page,
            perPage: meta.per_page,
            total: meta.total,
            hasMore: meta.current_page < meta.last_page,
          },
        }));
      }
    } catch (error) {
      console.error('Error fetching leaderboard:', error);
      set({ error: 'Failed to fetch leaderboard' });
    } finally {
      set({ isLoading: false });
    }
  },

  clearErrors: () => set({ error: null }),
}));