import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import { apiClient } from '@/api/client';
import { MeditationSession, Challenge, DailyChallenge } from '@/types';


interface MeditationState {
  sessions: MeditationSession[];
  unsyncedSessions: MeditationSession[];
  challenges: Challenge[];
  joinedChallenges: string[];
  isLoading: boolean;
  error: string | null;
  initialize: () => Promise<void>;
  sync: () => Promise<void>;
  recordSession: (session: MeditationSession) => void;
  joinChallenge: (challengeId: string) => Promise<void>;
  completeChallenge: (challengeId: string) => Promise<void>;
  getTotalMeditationTime: (virtueId: string) => number;
  getMeditationCount: (virtueId: string) => number;
}

const STORAGE_KEY = '@meditation_data';

export const useMeditationStore = create<MeditationState>((set, get) => ({
  sessions: [],
  unsyncedSessions: [],
  challenges: [],
  joinedChallenges: [],
  isLoading: false,
  error: null,

  initialize: async () => {
    try {
      set({ isLoading: true });
      const storedData = await AsyncStorage.getItem(STORAGE_KEY);
      if (storedData) {
        const data = JSON.parse(storedData);
        set({
          sessions: data.sessions || [],
          unsyncedSessions: data.unsyncedSessions || [],
          challenges: data.challenges || [],
          joinedChallenges: data.joinedChallenges || [],
        });
      }
      await get().sync();
    } catch (error) {
      console.error('Error initializing meditation data:', error);
      set({ error: 'Failed to initialize meditation data' });
    } finally {
      set({ isLoading: false });
    }
  },

  sync: async () => {
    const { unsyncedSessions, joinedChallenges } = get();
    const { isConnected } = await NetInfo.fetch();
    if (!isConnected) return;

    try {
      set({ isLoading: true, error: null });

      // Sync unsynced sessions
      for (const session of unsyncedSessions) {
        await apiClient.post('/meditation_sessions/', session);
      }

      // Fetch updated data
      const [sessionsResponse, challengesResponse] = await Promise.all([
        apiClient.get('/meditation_sessions'),
        apiClient.get('/challenges'),
      ]);

      const newSessions = (sessionsResponse as any).data.sessions || [];
      const newChallenges = (challengesResponse as any).data.challenges || [];

      set({
        sessions: newSessions,
        unsyncedSessions: [],
        challenges: newChallenges,
        joinedChallenges,
      });

      await AsyncStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          sessions: newSessions,
          unsyncedSessions: [],
          challenges: newChallenges,
          joinedChallenges,
        })
      );
    } catch (error: any) {
      console.error('Sync error:', error);
      set({ error: error.message });
    } finally {
      set({ isLoading: false });
    }
  },

  recordSession: (session: MeditationSession) => {
    set((state) => {
      const newUnsyncedSessions = [...state.unsyncedSessions, session];
      const newState = { unsyncedSessions: newUnsyncedSessions };

      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify({ ...state, ...newState })).catch((error) =>
        console.error('Storage error:', error)
      );

      return newState;
    });
    get().sync(); // Attempt sync immediately
  },

  joinChallenge: async (challengeId: string) => {
    try {
      await apiClient.post(`/challenges/${challengeId}/join`);
      set((state) => ({
        joinedChallenges: [...state.joinedChallenges, challengeId],
      }));
    } catch (error) {
      console.error('Failed to join challenge:', error);
    }
  },

  completeChallenge: async (challengeId: string, notes?: string) => {
    try {
      await apiClient.post(`/challenges/${challengeId}/complete`, { notes });
      set((state) => ({
        joinedChallenges: state.joinedChallenges.filter((id) => id !== challengeId),
      }));
    } catch (error) {
      console.error('Failed to complete challenge:', error);
    }
  },

  getTotalMeditationTime: (virtueId: string) => {
    const sessions = get().sessions.filter((s) => s.virtue_id === virtueId);
    return sessions.reduce((total, session) => total + session.duration_minutes, 0);
  },

  getMeditationCount: (virtueId: string) => {
    const sessions = get().sessions.filter((s) => s.virtue_id === virtueId);
    return sessions.length;
  },
}));

// Sync when online
NetInfo.addEventListener((state) => {
  if (state.isConnected) {
    useMeditationStore.getState().sync();
  }
});