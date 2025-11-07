import { makeAutoObservable, runInAction, reaction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient } from '@/api/client';
import { AuthStore } from './AuthStore';
import { MeditationSession, Challenge, DailyChallenge, PaginatedResponse } from '@/types';

export type MeditationPhase = 'setup' | 'countdown' | 'active' | 'paused' | 'complete' | 'idle';
export type MeditationStyle = 'parable' | 'virtue' | 'centering' | 'jesus_prayer' | 'chant';

export interface MeditationState {
  sessions: MeditationSession[];
  unsyncedSessions: MeditationSession[];
  challenges: Challenge[];
  joinedChallenges: string[];

  // UI/session state
  selectedVirtue: string | null;
  selectedTime: number | null;
  selectedChallenge: DailyChallenge | null;
  selectedBackgroundSound: string | null;
  selectedStyle: MeditationStyle;
  centeringWord: string | null;
  chosenChantId: string | null;
  jesusPrayerPace: 'slow' | 'medium' | 'fast';
  parableReadMode: 'silent' | 'aloud';
  centeringReadMode: 'silent' | 'aloud';
  centeringRepeatIntervalSec: number;
  chantReflectionPauseSec: number;
  meditationState: MeditationPhase;
  countdown: number;
  meditationTimer: number;
  isPreviewingSound: boolean;
  lastNonChantSound: string | null;
  pausedFrom?: 'countdown' | 'active' | null;

  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
}

const initialState: MeditationState = {
  sessions: [],
  unsyncedSessions: [],
  challenges: [],
  joinedChallenges: [],
  selectedVirtue: null,
  selectedTime: null,
  selectedChallenge: null,
  selectedBackgroundSound: 'ambient',
  selectedStyle: 'virtue',
  centeringWord: null,
  chosenChantId: null,
  jesusPrayerPace: 'medium',
  parableReadMode: 'silent',
  centeringReadMode: 'silent',
  centeringRepeatIntervalSec: 15,
  chantReflectionPauseSec: 20,
  meditationState: 'setup',
  countdown: 5, // 5-second countdown by default
  meditationTimer: 0,
  isPreviewingSound: false,
  lastNonChantSound: null,
  pausedFrom: null,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 10,
    total: 0,
    hasMore: false,
  },
};

export class MeditationStore {
  state: MeditationState = initialState;

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'meditation_store';
  private hasInitialized = false;
  private disposeAuthReaction?: () => void;
  private authStore: AuthStore;

  private setLoading = (value: boolean) => {
    this.isLoading = value;
  };

  private setError = (message: string | null) => {
    this.error = message;
  };

  private async saveToStorage() {
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }
  private countdownInterval: number | null = null;
  private meditationInterval: number | null = null;
  
  constructor(authStore: AuthStore) {
    // Auto-bind ensures methods keep the correct `this` when passed around/destructured
    makeAutoObservable(this, {}, { autoBind: true });
    this.authStore = authStore;

    // Wait for auth to be ready before initializing network calls
    this.disposeAuthReaction = reaction(
      () => ({ initialized: this.authStore.isInitialized, token: this.authStore.token }),
      ({ initialized, token }) => {
        if (initialized && token) {
          this.initialize();
        }
      },
      {
        fireImmediately: true,
        equals: (a, b) => a.initialized === b.initialized && a.token === b.token,
      }
    );
  }

  // Getters for computed values
  get totalMeditationTime() {
    return (virtueId: string) => {
      return this.state.sessions
        .filter(session => session.virtue_id === virtueId)
        .reduce((total, session) => total + (session.duration_minutes || 0), 0);
    };
  }

  get meditationCount() {
    return (virtueId: string) => {
      return this.state.sessions.filter(session => session.virtue_id === virtueId).length;
    };
  }

  // Actions
  async initialize() {
    // Prevent duplicate initialization and repeated API calls
    if (this.hasInitialized) return;
    try {
      this.setLoading(true);
      
      // Load stored state
      const stored = await AsyncStorage.getItem(this.storageKey);
      if (stored) {
        runInAction(() => {
          const parsed = JSON.parse(stored);
          // Drop legacy rosary state if present
          const { rosaryState: _legacyRosary, ...rest } = parsed ?? {};
          this.state = { ...this.state, ...rest };
          // Ensure a sensible default for background sound
          if (!this.state.selectedBackgroundSound) {
            this.state.selectedBackgroundSound = 'ambient';
          }
        });
      }
      
      // Load any locally stored unsynced sessions
      const storedSessions = await AsyncStorage.getItem('unsyncedMeditationSessions');
      if (storedSessions) {
        runInAction(() => {
          this.state.unsyncedSessions = JSON.parse(storedSessions);
        });
      }
      
      // Initial data fetch: don't blow up UI if one fails
      const results = await Promise.allSettled([
        this.fetchSessions(),
        this.fetchChallenges(),
      ]);

      // If both failed, surface a friendly error
      const allRejected = results.every(r => r.status === 'rejected');
      if (allRejected) {
        this.setError('Failed to load meditation data');
      }
      
    } catch (error) {
      console.error('Error initializing meditation store:', error);
      this.setError('Failed to initialize meditation data');
    } finally {
      this.setLoading(false);
      this.hasInitialized = true;
      if (this.disposeAuthReaction) {
        this.disposeAuthReaction();
        this.disposeAuthReaction = undefined;
      }
    }
  }

  async sync() {
    if (this.state.unsyncedSessions.length === 0) return;
    
    try {
      this.setLoading(true);
      
      // Try to sync each unsynced session
      const successfulSyncs: number[] = [];
      
      for (let i = 0; i < this.state.unsyncedSessions.length; i++) {
        const session = this.state.unsyncedSessions[i];
        try {
          await this.recordSession(session, true);
          successfulSyncs.push(i);
        } catch (error) {
          console.error(`Failed to sync session ${i}:`, error);
        }
      }
      
      // Remove successfully synced sessions
      if (successfulSyncs.length > 0) {
        runInAction(() => {
          this.state.unsyncedSessions = this.state.unsyncedSessions.filter(
            (_, index) => !successfulSyncs.includes(index)
          );
          this.saveUnsyncedSessions();
        });
      }
      
    } catch (error) {
      console.error('Error syncing meditation sessions:', error);
      this.setError('Failed to sync meditation sessions');
    } finally {
      this.setLoading(false);
    }
  }

  async recordSession(session: MeditationSession, isRetry = false) {
    try {
      const response = await apiClient.post<{ data: MeditationSession }>('/meditation_sessions', session);
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to record meditation session');
      }

      const created = (response.data as any).data ?? response.data;

      runInAction(() => {
        this.state.sessions = [created, ...this.state.sessions];
        this.state.pagination.total += 1;
      });

      return true;
    } catch (error) {
      if (!isRetry) {
        // If it's not a retry, save to unsynced sessions
        runInAction(() => {
          this.state.unsyncedSessions = [session, ...this.state.unsyncedSessions];
          this.saveUnsyncedSessions();
        });
      }
      
      console.error('Error recording meditation session:', error);
      // Don't throw to avoid crashing UI
      return false;
    }
  }

  async joinChallenge(challengeId: string) {
    try {
      const response = await apiClient.post(`/challenges/${challengeId}/join`);
      if (!response.success) {
        throw new Error(response.message || 'Failed to join challenge');
      }
      
      runInAction(() => {
        if (!this.state.joinedChallenges.includes(challengeId)) {
          this.state.joinedChallenges = [...this.state.joinedChallenges, challengeId];
        }
      });
      
      return true;
    } catch (error) {
      console.error(`Error joining challenge ${challengeId}:`, error);
      this.setError('Failed to join challenge');
      return false;
    }
  }

  async completeChallenge(challengeId: string) {
    try {
      const response = await apiClient.post(`/challenges/${challengeId}/complete`);
      if (!response.success) {
        throw new Error(response.message || 'Failed to complete challenge');
      }
      
      runInAction(() => {
        this.state.challenges = this.state.challenges.map(challenge => 
          challenge.id === challengeId 
            ? { ...challenge, is_completed: true }
            : challenge
        );
      });
      
      return true;
    } catch (error) {
      console.error(`Error completing challenge ${challengeId}:`, error);
      this.setError('Failed to complete challenge');
      return false;
    }
  }

  async fetchSessions(page = 1) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<PaginatedResponse<MeditationSession>>(
        '/meditation_sessions',
        { page }
      );
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch meditation sessions');
      }
      
      runInAction(() => {
        const payload = response.data as any;
        const list = payload.data ?? payload;
        const meta = payload.meta ?? payload?.data?.meta;

        this.state.sessions = page === 1 
          ? list 
          : [...this.state.sessions, ...list];
          
        this.state.pagination = {
          currentPage: page,
          lastPage: meta?.last_page ?? page,
          perPage: meta?.per_page ?? this.state.pagination.perPage,
          total: meta?.total ?? this.state.pagination.total,
          hasMore: (meta?.current_page ?? page) < (meta?.last_page ?? page),
        };
      });
      
      return (response.data as any).data ?? response.data;
    } catch (error) {
      console.error('Error fetching meditation sessions:', error);
      this.setError('Failed to fetch meditation sessions');
      return [];
    } finally {
      this.setLoading(false);
    }
  }

  async fetchChallenges(page = 1) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<PaginatedResponse<Challenge>>(
        '/challenges',
        { page }
      );
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch challenges');
      }
      
      runInAction(() => {
        const payload = response.data as any;
        const list = payload.data ?? payload;
        const meta = payload.meta ?? payload?.data?.meta;

        this.state.challenges = page === 1 
          ? list 
          : [...this.state.challenges, ...list];
          
        // Note: API does not expose is_joined on Challenge type; keep joinedChallenges as-is
        
        this.state.pagination = {
          currentPage: page,
          lastPage: meta?.last_page ?? page,
          perPage: meta?.per_page ?? this.state.pagination.perPage,
          total: meta?.total ?? this.state.pagination.total,
          hasMore: (meta?.current_page ?? page) < (meta?.last_page ?? page),
        };
      });
      
      return (response.data as any).data ?? response.data;
    } catch (error) {
      console.error('Error fetching challenges:', error);
      this.setError('Failed to fetch challenges');
      return [];
    } finally {
      this.setLoading(false);
    }
  }

  // UI/session actions
  setSelectedVirtue(id: string | null) {
    this.state.selectedVirtue = id;
    this.saveToStorage();
  }

  setSelectedTime(minutes: number | null) {
    this.state.selectedTime = minutes;
    this.saveToStorage();
  }

  setSelectedChallenge(challenge: DailyChallenge | null) {
    this.state.selectedChallenge = challenge;
  }

  setSelectedBackgroundSound(id: string | null) {
    this.state.selectedBackgroundSound = id;
    if (id) this.state.lastNonChantSound = id;
    // Persist immediately so user's choice sticks
    this.saveToStorage();
  }

  setLastNonChantSound(id: string | null) {
    this.state.lastNonChantSound = id;
    this.saveToStorage();
  }

  setIsPreviewingSound(value: boolean) {
    this.state.isPreviewingSound = value;
  }

  setSelectedStyle(style: MeditationStyle) {
    this.state.selectedStyle = style;
    this.saveToStorage();
  }

  setCenteringWord(word: string | null) {
    this.state.centeringWord = word;
    this.saveToStorage();
  }

  setChosenChantId(id: string | null) {
    this.state.chosenChantId = id;
    this.saveToStorage();
  }

  setJesusPrayerPace(pace: 'slow' | 'medium' | 'fast') {
    this.state.jesusPrayerPace = pace;
    this.saveToStorage();
  }

  setParableReadMode(mode: 'silent' | 'aloud') {
    this.state.parableReadMode = mode;
    this.saveToStorage();
  }

  setCenteringReadMode(mode: 'silent' | 'aloud') {
    this.state.centeringReadMode = mode;
    this.saveToStorage();
  }

  setCenteringRepeatIntervalSec(seconds: number) {
    const clamped = Math.max(10, Math.min(30, Math.floor(seconds || 10)));
    this.state.centeringRepeatIntervalSec = clamped;
    this.saveToStorage();
  }

  setChantReflectionPauseSec(seconds: number) {
    const clamped = Math.max(15, Math.min(60, Math.floor(seconds || 20)));
    this.state.chantReflectionPauseSec = clamped;
    this.saveToStorage();
  }

  startMeditation() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }
    
    this.state.meditationState = 'countdown';
    this.state.countdown = 5; // 5-second countdown
    
    this.countdownInterval = setInterval(() => {
      this.decrementCountdown();
    }, 1000);
  }

  decrementCountdown() {
    if (this.state.countdown > 1) {
      this.state.countdown -= 1;
    } else {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
      }
      this.startMeditationTimer();
    }
  }

  private startMeditationTimer() {
    this.state.meditationState = 'active';
    this.state.meditationTimer = 0;
    
    this.meditationInterval = setInterval(() => {
      this.incrementMeditationTimer();
    }, 1000);
  }

  incrementMeditationTimer() {
    this.state.meditationTimer += 1;
    
    // Auto-end session if time is up (if a time was set)
    if (this.state.selectedTime && this.state.meditationTimer >= this.state.selectedTime * 60) {
      this.state.meditationTimer = this.state.selectedTime * 60;
      if (this.meditationInterval) {
        clearInterval(this.meditationInterval);
        this.meditationInterval = null;
      }
    }
  }

  async endMeditationSession() {
    // Stop any running intervals
    if (this.meditationInterval) {
      clearInterval(this.meditationInterval);
      this.meditationInterval = null;
    }
    
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
    
    // Only record the session if it was actually started
    if (this.state.meditationState === 'active' && this.state.meditationTimer > 0) {
      const now = new Date();
      const startedAt = new Date(now.getTime() - this.state.meditationTimer * 1000).toISOString();
      const endedAt = now.toISOString();
      const session: MeditationSession = {
        id: `local-${Date.now()}`,
        virtue_id: this.state.selectedVirtue || '',
        duration_minutes: Math.max(1, Math.round(this.state.meditationTimer / 60)),
        started_at: startedAt,
        ended_at: endedAt,
      };
      
      try {
        await this.recordSession(session);
      } catch (error) {
        console.error('Error saving meditation session:', error);
        // The session is already added to unsyncedSessions in the catch block of recordSession
      }
    }
    
    this.state.meditationState = 'complete';
  }

  resetMeditationSession() {
    if (this.meditationInterval) {
      clearInterval(this.meditationInterval);
      this.meditationInterval = null;
    }
    
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
    
    this.state.meditationState = 'setup';
    this.state.countdown = 5;
    this.state.meditationTimer = 0;
    this.state.pausedFrom = null;
  }
  goIdle() {
    if (this.meditationInterval) {
      clearInterval(this.meditationInterval);
      this.meditationInterval = null;
    }
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
    this.state.meditationState = 'idle';
    this.state.pausedFrom = null;
  }
  // Helper method to save unsynced sessions to localStorage
  private async saveUnsyncedSessions() {
    try {
      await AsyncStorage.setItem('unsyncedMeditationSessions', JSON.stringify(this.state.unsyncedSessions));
    } catch (e) {
      // Non-fatal
      console.error('Failed to persist unsynced sessions', e);
    }
  }
  
  // Cleanup on store destruction
  cleanup() {
    if (this.meditationInterval) {
      clearInterval(this.meditationInterval);
    }
    
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
    }
  }

  // Pause/resume support
  pause() {
    if (this.state.meditationState === 'active' || this.state.meditationState === 'countdown') {
      if (this.meditationInterval) {
        clearInterval(this.meditationInterval);
        this.meditationInterval = null;
      }
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
      }
      this.state.pausedFrom = this.state.meditationState as any;
      this.state.meditationState = 'paused';
    }
  }

  resume() {
    if (this.state.meditationState !== 'paused') return;
    const from = this.state.pausedFrom;
    this.state.pausedFrom = null;
    if (from === 'countdown') {
      this.state.meditationState = 'countdown';
      this.countdownInterval = setInterval(() => {
        this.decrementCountdown();
      }, 1000);
    } else {
      this.state.meditationState = 'active';
      this.meditationInterval = setInterval(() => {
        this.incrementMeditationTimer();
      }, 1000);
    }
  }
}

// For backward compatibility (legacy imports may still reference default export)
export default MeditationStore;
