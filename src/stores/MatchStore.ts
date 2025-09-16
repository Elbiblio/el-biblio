import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { Match, User, MatchStatus, MatchType } from '@/types';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

export interface MatchState {
  // Current match
  currentMatch: Match | null;
  
  // Match history
  matchHistory: Match[];
  
  // Active matches
  activeMatches: Match[];
  
  // Match status
  isSearching: boolean;
  searchStartTime: Date | null;
  searchDuration: number;
  matchedUser: User | null;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Real-time updates
  isConnected: boolean;
  lastUpdate: Date | null;
}

const initialState: MatchState = {
  currentMatch: null,
  matchHistory: [],
  activeMatches: [],
  isSearching: false,
  searchStartTime: null,
  searchDuration: 0,
  matchedUser: null,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 10,
    total: 0,
    hasMore: false,
  },
  isConnected: false,
  lastUpdate: null,
};

export class MatchStore {
  state: MatchState = initialState;
  
  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'match_store';
  private searchInterval: number | null = null;
  
  constructor() {
    this.state = initialState;
    this.storageKey = 'match_store';
    
    makeAutoObservable(this);
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading match store from storage:', error);
    });
  }

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

  // Computed getters
  get currentMatch() {
    return this.state.currentMatch;
  }

  get matchHistory() {
    return this.state.matchHistory;
  }

  get activeMatches() {
    return this.state.activeMatches;
  }

  get isSearching() {
    return this.state.isSearching;
  }

  get matchedUser() {
    return this.state.matchedUser;
  }

  get searchDuration() {
    if (!this.state.searchStartTime) return 0;
    return Math.floor((new Date().getTime() - this.state.searchStartTime.getTime()) / 1000);
  }

  // Bridge getters to match screen expectations
  get isMatchLoading() {
    return this.isLoading;
  }

  get matchError() {
    return this.error;
  }

  get searchStartTime() {
    return this.state.searchStartTime;
  }

  get isConnected() {
    return this.state.isConnected;
  }

  get lastUpdate() {
    return this.state.lastUpdate;
  }

  // Actions
  async createMatch(data: { match_type: MatchType; wait_time_minutes: number }) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<{ data: Match }>(endpoints.matches.create, data);
      
      runInAction(() => {
        this.state.currentMatch = response.data.data;
        this.state.activeMatches = [response.data.data, ...this.state.activeMatches];
      });
      
      await this.saveToStorage();
      return response.data.data;
    } catch (error) {
      console.error('Error creating match:', error);
      this.setError('Failed to create match');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async acceptMatch(matchId: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<{ data: Match }>(endpoints.matches.accept(matchId));
      
      runInAction(() => {
        if (this.state.currentMatch?.id === matchId) {
          this.state.currentMatch = response.data.data;
        }
        
        this.state.activeMatches = this.state.activeMatches.map(match => 
          match.id === matchId ? response.data.data : match
        );
      });
      
      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error(`Error accepting match ${matchId}:`, error);
      this.setError('Failed to accept match');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async rejectMatch(matchId: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<{ data: Match }>(endpoints.matches.reject(matchId));
      
      runInAction(() => {
        if (this.state.currentMatch?.id === matchId) {
          this.state.currentMatch = response.data.data;
        }
        
        this.state.activeMatches = this.state.activeMatches.map(match => 
          match.id === matchId ? response.data.data : match
        );
      });
      
      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error(`Error rejecting match ${matchId}:`, error);
      this.setError('Failed to reject match');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async cancelMatch(matchId: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<{ data: Match }>(endpoints.matches.cancel(matchId));
      
      runInAction(() => {
        if (this.state.currentMatch?.id === matchId) {
          this.state.currentMatch = response.data.data;
        }
        
        this.state.activeMatches = this.state.activeMatches.filter(match => match.id !== matchId);
      });
      
      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error(`Error cancelling match ${matchId}:`, error);
      this.setError('Failed to cancel match');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async fetchActiveMatches(page = 1) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<{ data: Match[]; meta: any }>(endpoints.matches.active, {
        page
      });
      
      runInAction(() => {
        this.state.activeMatches = page === 1 
          ? response.data.data 
          : [...this.state.activeMatches, ...response.data.data];
          
        this.state.pagination = {
          currentPage: page,
          lastPage: response.data.meta.last_page,
          perPage: response.data.meta.per_page,
          total: response.data.meta.total,
          hasMore: response.data.meta.current_page < response.data.meta.last_page,
        };
      });
      
      await this.saveToStorage();
      return response.data.data;
    } catch (error) {
      console.error('Error fetching active matches:', error);
      this.setError('Failed to fetch active matches');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async fetchMatchHistory(page = 1) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<{ data: Match[]; meta: any }>(endpoints.matches.history, {
        page
      });
      
      runInAction(() => {
        this.state.matchHistory = page === 1 
          ? response.data.data 
          : [...this.state.matchHistory, ...response.data.data];
          
        this.state.pagination = {
          currentPage: page,
          lastPage: response.data.meta.last_page,
          perPage: response.data.meta.per_page,
          total: response.data.meta.total,
          hasMore: response.data.meta.current_page < response.data.meta.last_page,
        };
      });
      
      await this.saveToStorage();
      return response.data.data;
    } catch (error) {
      console.error('Error fetching match history:', error);
      this.setError('Failed to fetch match history');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async fetchMatchById(id: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<{ data: Match }>(endpoints.matches.show(id));
      
      runInAction(() => {
        this.state.currentMatch = response.data.data;
      });
      
      await this.saveToStorage();
      return response.data.data;
    } catch (error) {
      console.error(`Error fetching match ${id}:`, error);
      this.setError('Failed to fetch match');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  startSearch(matchType: MatchType, waitTimeMinutes: number) {
    runInAction(() => {
      this.state.isSearching = true;
      this.state.searchStartTime = new Date();
      this.state.searchDuration = 0;
      this.state.matchedUser = null;
    });
    
    // Start polling for match status
    this.searchInterval = setInterval(() => this.checkMatchStatus(), 3000);
    
    // Set timeout to automatically stop searching
    setTimeout(() => {
      if (this.state.isSearching) {
        this.stopSearch();
        toast('Search timed out. No matches found.');
      }
    }, waitTimeMinutes * 60 * 1000);
  }

  stopSearch() {
    if (this.searchInterval) {
      clearInterval(this.searchInterval);
      this.searchInterval = null;
    }
    
    runInAction(() => {
      this.state.isSearching = false;
      this.state.searchStartTime = null;
      this.state.searchDuration = 0;
    });
  }

  async checkMatchStatus() {
    if (!this.state.isSearching) return;
    
    try {
      const response = await apiClient.get<{ data: { has_match: boolean; match_id?: string } }>('/matches/status');
      
      if (response.data.data.has_match && response.data.data.match_id) {
        const match = await this.fetchMatchById(response.data.data.match_id);
        
        runInAction(() => {
          this.state.matchedUser = match.matchedUser || null;
          this.state.currentMatch = match;
          this.state.activeMatches = [match, ...this.state.activeMatches];
          this.state.isSearching = false;
        });
        
        if (this.searchInterval) {
          clearInterval(this.searchInterval);
          this.searchInterval = null;
        }
        
        // Haptic feedback for match found
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        toast('Match found!');
      }
    } catch (error) {
      console.error('Error checking match status:', error);
    }
  }

  setConnectionStatus(isConnected: boolean) {
    this.state.isConnected = isConnected;
    this.state.lastUpdate = new Date();
    
    if (isConnected && this.state.isSearching) {
      // Reconnect and resume search
      this.checkMatchStatus();
    }
  }

  updateMatchInRealTime(matchId: string, updates: Partial<Match>) {
    runInAction(() => {
      if (this.state.currentMatch?.id === matchId) {
        this.state.currentMatch = { ...this.state.currentMatch, ...updates };
      }
      
      this.state.activeMatches = this.state.activeMatches.map(match => 
        match.id === matchId ? { ...match, ...updates } : match
      );
      
      this.state.matchHistory = this.state.matchHistory.map(match => 
        match.id === matchId ? { ...match, ...updates } : match
      );
    });
  }

  receiveMatch(match: Match, matchedUser: User) {
    runInAction(() => {
      this.state.currentMatch = match;
      this.state.matchedUser = matchedUser;
      this.state.activeMatches = [match, ...this.state.activeMatches];
      this.state.isSearching = false;
    });
    
    if (this.searchInterval) {
      clearInterval(this.searchInterval);
      this.searchInterval = null;
    }
    
    // Haptic feedback for match found
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    toast('Match found!');
  }

  clearCurrentMatch() {
    this.state.currentMatch = null;
    this.state.matchedUser = null;
  }

  clearErrors() {
    this.setError(null);
  }

  resetSearchState() {
    if (this.searchInterval) {
      clearInterval(this.searchInterval);
      this.searchInterval = null;
    }
    
    runInAction(() => {
      this.state.isSearching = false;
      this.state.searchStartTime = null;
      this.state.searchDuration = 0;
      this.state.matchedUser = null;
    });
  }
  
  // Cleanup on store destruction
  cleanup() {
    if (this.searchInterval) {
      clearInterval(this.searchInterval);
    }
  }
}

// Create a singleton instance
export const matchStore = new MatchStore();

// For backward compatibility
export const useMatchStore = () => matchStore;

export default matchStore;
