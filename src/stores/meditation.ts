import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { MeditationSession, Challenge, DailyChallenge, PaginatedResponse } from '@/types';

// UI session flow state centralization for Meditation
type MeditationPhase = 'setup' | 'countdown' | 'active' | 'complete';

interface MeditationState {
  sessions: MeditationSession[];
  unsyncedSessions: MeditationSession[];
  challenges: Challenge[];
  joinedChallenges: string[];
  isLoading: boolean;
  isSyncing: boolean;
  error: string | null;
  
  // Centralized UI/session state
  selectedVirtue: string | null;
  selectedTime: number | null;
  selectedChallenge: DailyChallenge | null;
  selectedBackgroundSound: string | null; // 'ambient' | 'heartbeat' | null
  meditationState: MeditationPhase;
  countdown: number; // seconds until start
  meditationTimer: number; // seconds elapsed during ACTIVE
  
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
  recordSession: (session: MeditationSession) => Promise<boolean>;
  joinChallenge: (challengeId: string) => Promise<boolean>;
  completeChallenge: (challengeId: string) => Promise<boolean>;
  getTotalMeditationTime: (virtueId: string) => number;
  getMeditationCount: (virtueId: string) => number;
  fetchSessions: (page?: number) => Promise<void>;
  fetchChallenges: (page?: number) => Promise<void>;
  clearErrors: () => void;

  // UI/session actions
  setSelectedVirtue: (id: string | null) => void;
  setSelectedTime: (minutes: number | null) => void;
  setSelectedChallenge: (challenge: DailyChallenge | null) => void;
  setSelectedBackgroundSound: (id: string | null) => void;
  startMeditation: () => void; // move to COUNTDOWN
  decrementCountdown: () => void; // tick countdown, auto-enter ACTIVE at 0
  incrementMeditationTimer: () => void; // +1 sec
  endMeditationSession: () => void; // move to COMPLETE
  resetMeditationSession: () => void; // reset to SETUP
}

export const useMeditationStore = create<MeditationState>((set, get) => ({
  sessions: [],
  unsyncedSessions: [],
  challenges: [],
  joinedChallenges: [],
  isLoading: false,
  isSyncing: false,
  error: null,
  // Centralized UI/session state defaults
  selectedVirtue: null,
  selectedTime: null,
  selectedChallenge: null,
  selectedBackgroundSound: null,
  meditationState: 'setup',
  countdown: 10,
  meditationTimer: 0,
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
      
      // Fetch meditation data from API
      const [sessionsResponse, challengesResponse] = await Promise.all([
        apiClient.get<PaginatedResponse<MeditationSession>>('/meditation_sessions'),
        apiClient.get<PaginatedResponse<Challenge>>('/challenges'),
      ]);

      if (sessionsResponse.success && sessionsResponse.data) {
        set({ 
          sessions: sessionsResponse.data.data,
          pagination: {
            currentPage: sessionsResponse.data.meta.current_page,
            lastPage: sessionsResponse.data.meta.last_page,
            perPage: sessionsResponse.data.meta.per_page,
            total: sessionsResponse.data.meta.total,
            hasMore: sessionsResponse.data.meta.current_page < sessionsResponse.data.meta.last_page,
          }
        });
      }

      if (challengesResponse.success && challengesResponse.data) {
        set({ challenges: challengesResponse.data.data });
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
    const { unsyncedSessions } = get();
    if (unsyncedSessions.length === 0) return;

    try {
      set({ isSyncing: true, error: null });

      // Sync unsynced sessions
      for (const session of unsyncedSessions) {
        await apiClient.post('/meditation_sessions/', session);
      }

      // Fetch updated data
      const [sessionsResponse, challengesResponse] = await Promise.all([
        apiClient.get<PaginatedResponse<MeditationSession>>('/meditation_sessions'),
        apiClient.get<PaginatedResponse<Challenge>>('/challenges'),
      ]);

      if (sessionsResponse.success && sessionsResponse.data) {
        set({ 
          sessions: sessionsResponse.data.data,
          unsyncedSessions: [],
          pagination: {
            currentPage: sessionsResponse.data.meta.current_page,
            lastPage: sessionsResponse.data.meta.last_page,
            perPage: sessionsResponse.data.meta.per_page,
            total: sessionsResponse.data.meta.total,
            hasMore: sessionsResponse.data.meta.current_page < sessionsResponse.data.meta.last_page,
          }
        });
      }

      if (challengesResponse.success && challengesResponse.data) {
        set({ challenges: challengesResponse.data.data });
      }
    } catch (error) {
      console.error('Sync error:', error);
      set({ error: 'Failed to sync meditation data' });
    } finally {
      set({ isSyncing: false });
    }
  },

  // UI/session actions
  setSelectedVirtue: (id) => set({ selectedVirtue: id }),
  setSelectedTime: (minutes) => set({ selectedTime: minutes }),
  setSelectedChallenge: (challenge) => set({ selectedChallenge: challenge }),
  setSelectedBackgroundSound: (id) => set({ selectedBackgroundSound: id }),
  startMeditation: () => set({ meditationState: 'countdown', countdown: 10, meditationTimer: 0 }),
  decrementCountdown: () => {
    const { countdown } = get();
    const next = Math.max(0, countdown - 1);
    // If reaching 0, enter ACTIVE and reset timer
    if (next === 0) {
      set({ countdown: next, meditationState: 'active', meditationTimer: 0 });
    } else {
      set({ countdown: next });
    }
  },
  incrementMeditationTimer: () => set((state) => ({ meditationTimer: state.meditationTimer + 1 })),
  endMeditationSession: () => set({ meditationState: 'complete' }),
  resetMeditationSession: () => set({
    selectedVirtue: null,
    selectedTime: null,
    selectedChallenge: null,
    selectedBackgroundSound: null,
    meditationState: 'setup',
    countdown: 10,
    meditationTimer: 0,
  }),

  recordSession: async (session: MeditationSession) => {
    set((state) => {
      const newUnsyncedSessions = [...state.unsyncedSessions, session];
      return { unsyncedSessions: newUnsyncedSessions };
    });
    
    // Attempt sync immediately
    await get().sync();
    return true;
  },

  joinChallenge: async (challengeId: string) => {
    try {
      set({ isLoading: true, error: null });
      
      const response = await apiClient.post(`/challenges/${challengeId}/join`);
      
      if (response.success) {
        set((state) => ({
          joinedChallenges: [...state.joinedChallenges, challengeId],
        }));
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error joining challenge:', error);
      set({ error: 'Failed to join challenge' });
      return false;
    } finally {
      set({ isLoading: false });
    }
  },

  completeChallenge: async (challengeId: string) => {
    try {
      set({ isLoading: true, error: null });
      
      const response = await apiClient.post(`/challenges/${challengeId}/complete`);
      
      if (response.success) {
        // Refresh challenges to get updated data
        await get().fetchChallenges();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error completing challenge:', error);
      set({ error: 'Failed to complete challenge' });
      return false;
    } finally {
      set({ isLoading: false });
    }
  },

  getTotalMeditationTime: (virtueId: string) => {
    const { sessions } = get();
    return sessions
      .filter(session => session.virtue_id === virtueId)
      .reduce((total, session) => total + session.duration_minutes, 0);
  },

  getMeditationCount: (virtueId: string) => {
    const { sessions } = get();
    return sessions.filter(session => session.virtue_id === virtueId).length;
  },

  fetchSessions: async (page = 1) => {
    try {
      set({ isLoading: true, error: null });

      const response = await apiClient.get<PaginatedResponse<MeditationSession>>(
        '/meditation_sessions',
        { params: { page, per_page: 20 } }
      );

      if (response.success && response.data) {
        const { data, meta } = response.data;
        set((state) => ({
          sessions: page === 1 ? data : [...state.sessions, ...data],
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
      console.error('Error fetching sessions:', error);
      set({ error: 'Failed to fetch sessions' });
    } finally {
      set({ isLoading: false });
    }
  },

  fetchChallenges: async (page = 1) => {
    try {
      set({ isLoading: true, error: null });

      const response = await apiClient.get<PaginatedResponse<Challenge>>(
        '/challenges',
        { params: { page, per_page: 20 } }
      );

      if (response.success && response.data) {
        const { data } = response.data;
        set((state) => ({
          challenges: page === 1 ? data : [...state.challenges, ...data],
        }));
      }
    } catch (error) {
      console.error('Error fetching challenges:', error);
      set({ error: 'Failed to fetch challenges' });
    } finally {
      set({ isLoading: false });
    }
  },

  clearErrors: () => set({ error: null }),
}));