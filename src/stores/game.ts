import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import { apiClient } from '@/api/client';
import { toast } from 'sonner-native';

// Type definitions
type GameId = 'verse_builder' | 'virtue_trivia' | string; // Extend as needed

interface ScoreEntry {
  gameId: GameId;
  score: number;
  timestamp: string;
}

interface LeaderboardEntry {
  userId: string;
  username: string;
  score: number;
}

interface GameState {
  personalBests: Record<GameId, number>;
  unsyncedScores: ScoreEntry[];
  leaderboards: Record<GameId, LeaderboardEntry[]>;
  lastSynced: string | null;
  isLoading: boolean;
  error: string | null;
  initialize: () => Promise<void>;
  sync: () => Promise<void>;
  submitScore: (gameId: GameId, score: number) => void;
  getPersonalBest: (gameId: GameId) => number | undefined;
  getLeaderboard: (gameId: GameId) => LeaderboardEntry[] | undefined;
}

const STORAGE_KEY = '@game_data';

// Create the store
export const useGameStore = create<GameState>((set, get) => ({
  personalBests: {},
  unsyncedScores: [],
  leaderboards: {},
  lastSynced: null,
  isLoading: false,
  error: null,

  // Initialize the store by loading data from AsyncStorage
  initialize: async () => {
    try {
      set({ isLoading: true });
      const storedData = await AsyncStorage.getItem(STORAGE_KEY);
      if (storedData) {
        const data = JSON.parse(storedData);
        set({
          personalBests: data.personalBests || {},
          unsyncedScores: data.unsyncedScores || [],
          leaderboards: data.leaderboards || {},
          lastSynced: data.lastSynced || null,
        });
      }
    } catch (error) {
      console.error('Error initializing game data:', error);
      set({ error: 'Failed to initialize game data' });
    } finally {
      set({ isLoading: false });
    }
  },

  // Sync scores with the server when online
  sync: async () => {
    const { unsyncedScores } = get();
    if (unsyncedScores.length === 0) return;

    const { isConnected } = await NetInfo.fetch();
    if (!isConnected) return;

    try {
      set({ isLoading: true, error: null });

      // Group scores by gameId for batch submission
      const scoresByGame: Record<GameId, ScoreEntry[]> = {};
      unsyncedScores.forEach((score) => {
        scoresByGame[score.gameId] = scoresByGame[score.gameId] || [];
        scoresByGame[score.gameId].push(score);
      });

      // Submit scores for each game
      for (const gameId in scoresByGame) {
        const scores = scoresByGame[gameId].map((s) => ({
          score: s.score,
          timestamp: s.timestamp,
        }));
        await apiClient.post(`/games/${gameId}/scores/batch`, { scores });
      }

      // Fetch updated personal bests and leaderboards
      const personalBestsResponse = await apiClient.get('/user/scores');
      const leaderboardsResponse = await apiClient.get('/leaderboards');

      const newPersonalBests = (personalBestsResponse as any).data.scores || {};
      const newLeaderboards = (leaderboardsResponse as any).data.leaderboards || {};

      // Update state and storage
      set({
        personalBests: newPersonalBests,
        unsyncedScores: [],
        leaderboards: newLeaderboards,
        lastSynced: new Date().toISOString(),
      });

      await AsyncStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          personalBests: newPersonalBests,
          unsyncedScores: [],
          leaderboards: newLeaderboards,
          lastSynced: new Date().toISOString(),
        })
      );
    } catch (error: any) {
      console.error('Sync error:', error);
      set({ error: error.message });
      toast.error('Failed to sync game data');
    } finally {
      set({ isLoading: false });
    }
  },

  // Submit a new score (called by game components)
  submitScore: (gameId: GameId, score: number) => {
    const timestamp = new Date().toISOString();
    set((state) => {
      const newUnsyncedScores = [
        ...state.unsyncedScores,
        { gameId, score, timestamp },
      ];
      const currentBest = state.personalBests[gameId] || 0;

      let newState = { unsyncedScores: newUnsyncedScores };
      if (score > currentBest) {
        const newPersonalBests = { ...state.personalBests, [gameId]: score };
        newState = { ...newState, personalBests: newPersonalBests };
      }

      // Save to storage
      AsyncStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({ ...state, ...newState })
      ).catch((error) => console.error('Storage error:', error));

      return newState;
    });
  },

  // Get the user's personal best for a game
  getPersonalBest: (gameId: GameId) => get().personalBests[gameId],

  // Get the leaderboard for a game
  getLeaderboard: (gameId: GameId) => get().leaderboards[gameId],
}));

// Automatic sync when coming online
NetInfo.addEventListener((state) => {
  if (state.isConnected) {
    useGameStore.getState().sync();
  }
});