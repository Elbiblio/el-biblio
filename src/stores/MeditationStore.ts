import { makeObservable, action, runInAction, computed } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient } from '@/api/client';
import { MeditationSession, Challenge, DailyChallenge, PaginatedResponse } from '@/types';
import { BaseStore } from './BaseStore';

export type MeditationPhase = 'setup' | 'countdown' | 'active' | 'complete';

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
  meditationState: MeditationPhase;
  countdown: number;
  meditationTimer: number;
  
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
  selectedBackgroundSound: null,
  meditationState: 'setup',
  countdown: 5, // 5-second countdown by default
  meditationTimer: 0,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 10,
    total: 0,
    hasMore: false,
  },
};

export class MeditationStore extends BaseStore<MeditationState> {
  private countdownInterval: number | null = null;
  private meditationInterval: number | null = null;
  
  constructor() {
    super(initialState, 'meditation_store');
    makeObservable(this, {
      // Actions
      initialize: action,
      sync: action,
      recordSession: action,
      joinChallenge: action,
      completeChallenge: action,
      fetchSessions: action,
      fetchChallenges: action,
      setSelectedVirtue: action,
      setSelectedTime: action,
      setSelectedChallenge: action,
      setSelectedBackgroundSound: action,
      startMeditation: action,
      decrementCountdown: action,
      incrementMeditationTimer: action,
      endMeditationSession: action,
      resetMeditationSession: action,
      clearErrors: action,
    });
    
    // Initialize the store
    this.initialize();
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
    try {
      this.setLoading(true);
      
      // Load any locally stored unsynced sessions
      const storedSessions = await AsyncStorage.getItem('unsyncedMeditationSessions');
      if (storedSessions) {
        runInAction(() => {
          this.state.unsyncedSessions = JSON.parse(storedSessions);
        });
      }
      
      // Initial data fetch
      await Promise.all([
        this.fetchSessions(),
        this.fetchChallenges(),
      ]);
      
    } catch (error) {
      console.error('Error initializing meditation store:', error);
      this.setError('Failed to initialize meditation data');
    } finally {
      this.setLoading(false);
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
      const response = await apiClient.post<{ data: MeditationSession }>('/meditation/sessions', session);
      
      runInAction(() => {
        this.state.sessions = [response.data.data, ...this.state.sessions];
        
        // Update pagination total
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
      throw new Error('Failed to record meditation session');
    }
  }

  async joinChallenge(challengeId: string) {
    try {
      await apiClient.post(`/challenges/${challengeId}/join`);
      
      runInAction(() => {
        if (!this.state.joinedChallenges.includes(challengeId)) {
          this.state.joinedChallenges = [...this.state.joinedChallenges, challengeId];
        }
      });
      
      return true;
    } catch (error) {
      console.error(`Error joining challenge ${challengeId}:`, error);
      this.setError('Failed to join challenge');
      throw error;
    }
  }

  async completeChallenge(challengeId: string) {
    try {
      await apiClient.post(`/challenges/${challengeId}/complete`);
      
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
      throw error;
    }
  }

  async fetchSessions(page = 1) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<PaginatedResponse<MeditationSession>>(
        '/meditation/sessions',
        { page }
      );
      
      runInAction(() => {
        this.state.sessions = page === 1 
          ? response.data.data 
          : [...this.state.sessions, ...response.data.data];
          
        this.state.pagination = {
          currentPage: page,
          lastPage: response.data.meta.last_page,
          perPage: response.data.meta.per_page,
          total: response.data.meta.total,
          hasMore: response.data.meta.current_page < response.data.meta.last_page,
        };
      });
      
      return response.data.data;
    } catch (error) {
      console.error('Error fetching meditation sessions:', error);
      this.setError('Failed to fetch meditation sessions');
      throw error;
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
      
      runInAction(() => {
        this.state.challenges = page === 1 
          ? response.data.data 
          : [...this.state.challenges, ...response.data.data];
          
        // Note: API does not expose is_joined on Challenge type; keep joinedChallenges as-is
        
        this.state.pagination = {
          currentPage: page,
          lastPage: response.data.meta.last_page,
          perPage: response.data.meta.per_page,
          total: response.data.meta.total,
          hasMore: response.data.meta.current_page < response.data.meta.last_page,
        };
      });
      
      return response.data.data;
    } catch (error) {
      console.error('Error fetching challenges:', error);
      this.setError('Failed to fetch challenges');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  // UI/session actions
  setSelectedVirtue(id: string | null) {
    this.state.selectedVirtue = id;
  }

  setSelectedTime(minutes: number | null) {
    this.state.selectedTime = minutes;
  }

  setSelectedChallenge(challenge: DailyChallenge | null) {
    this.state.selectedChallenge = challenge;
  }

  setSelectedBackgroundSound(id: string | null) {
    this.state.selectedBackgroundSound = id;
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
      this.endMeditationSession();
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
  }

  clearErrors() {
    this.setError(null);
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
}

// Create a singleton instance
export const meditationStore = new MeditationStore();

// For backward compatibility
export const useMeditationStore = () => meditationStore;

export default meditationStore;
