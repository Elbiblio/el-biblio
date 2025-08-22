import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { Match, User, MatchStatus, MatchType } from '@/types';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

interface MatchState {
  // Current match
  currentMatch: Match | null;
  isMatchLoading: boolean;
  matchError: string | null;
  
  // Match history
  matchHistory: Match[];
  isHistoryLoading: boolean;
  historyError: string | null;
  
  // Active matches
  activeMatches: Match[];
  isActiveMatchesLoading: boolean;
  activeMatchesError: string | null;
  
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
  
  // Actions
  createMatch: (data: {
    match_type: MatchType;
    wait_time_minutes: number;
  }) => Promise<Match | null>;
  
  acceptMatch: (matchId: string) => Promise<boolean>;
  rejectMatch: (matchId: string) => Promise<boolean>;
  cancelMatch: (matchId: string) => Promise<boolean>;
  
  fetchActiveMatches: (page?: number) => Promise<void>;
  fetchMatchHistory: (page?: number) => Promise<void>;
  fetchMatchById: (id: string) => Promise<Match | null>;
  
  // Search management
  startSearch: (matchType: MatchType, waitTimeMinutes: number) => Promise<boolean>;
  stopSearch: () => Promise<boolean>;
  checkMatchStatus: () => Promise<void>;
  
  // Real-time updates
  setConnectionStatus: (isConnected: boolean) => void;
  updateMatchInRealTime: (matchId: string, updates: Partial<Match>) => void;
  receiveMatch: (match: Match, matchedUser: User) => void;
  
  // State management
  clearCurrentMatch: () => void;
  clearErrors: () => void;
  resetSearchState: () => void;
}

export const useMatchStore = create<MatchState>((set, get) => ({
  // Initial State
  currentMatch: null,
  isMatchLoading: false,
  matchError: null,
  
  matchHistory: [],
  isHistoryLoading: false,
  historyError: null,
  
  activeMatches: [],
  isActiveMatchesLoading: false,
  activeMatchesError: null,
  
  isSearching: false,
  searchStartTime: null,
  searchDuration: 0,
  matchedUser: null,
  
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },
  
  isConnected: false,
  lastUpdate: null,
  
  // Actions
  createMatch: async (data) => {
    try {
      set({ isMatchLoading: true, matchError: null });
      
      const response = await apiClient.post<Match>(
        endpoints.matches.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create match');
      }
      
      const newMatch = response.data;
      
      set({
        currentMatch: newMatch,
        isSearching: true,
        searchStartTime: new Date(),
        searchDuration: data.wait_time_minutes * 60,
        isMatchLoading: false,
        lastUpdate: new Date(),
      });
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Searching for your match...');
      
      return newMatch;
    } catch (error) {
      console.error('Error creating match:', error);
      const message = error instanceof Error ? error.message : 'Failed to create match';
      set({ 
        isMatchLoading: false,
        matchError: message
      });
      toast.error(message);
      return null;
    }
  },

  acceptMatch: async (matchId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.matches.accept(matchId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to accept match');
      }
      
      // Update local state
      set(state => ({
        activeMatches: state.activeMatches.map(match => 
          match.id === matchId ? { ...match, status: MatchStatus.Matched } : match
        ),
        currentMatch: state.currentMatch?.id === matchId 
          ? { ...state.currentMatch, status: MatchStatus.Matched }
          : state.currentMatch
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Match accepted! Starting conversation...');
      
      return true;
    } catch (error) {
      console.error('Error accepting match:', error);
      const message = error instanceof Error ? error.message : 'Failed to accept match';
      toast.error(message);
      return false;
    }
  },

  rejectMatch: async (matchId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.matches.reject(matchId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to reject match');
      }
      
      // Update local state
      set(state => ({
        activeMatches: state.activeMatches.map(match => 
          match.id === matchId ? { ...match, status: MatchStatus.Expired } : match
        ),
        currentMatch: state.currentMatch?.id === matchId 
          ? { ...state.currentMatch, status: MatchStatus.Expired }
          : state.currentMatch
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      toast.success('Match rejected');
      
      return true;
    } catch (error) {
      console.error('Error rejecting match:', error);
      const message = error instanceof Error ? error.message : 'Failed to reject match';
      toast.error(message);
      return false;
    }
  },

  cancelMatch: async (matchId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.matches.cancel(matchId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to cancel match');
      }
      
      // Reset search state
      set({
        currentMatch: null,
        isSearching: false,
        searchStartTime: null,
        searchDuration: 0,
        matchedUser: null,
      });
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Search cancelled');
      
      return true;
    } catch (error) {
      console.error('Error cancelling match:', error);
      const message = error instanceof Error ? error.message : 'Failed to cancel match';
      toast.error(message);
      return false;
    }
  },

  fetchActiveMatches: async (page = 1) => {
    try {
      set({ isActiveMatchesLoading: true, activeMatchesError: null });
      
      const response = await apiClient.get<Match[]>(
        endpoints.matches.active,
        {
          params: {
            include: ['matched_user'],
            sort: '-created_at',
            per_page: get().pagination.perPage,
            page
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch active matches');
      }
      
      set({
        activeMatches: page === 1 ? response.data : [...get().activeMatches, ...response.data],
        isActiveMatchesLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching active matches:', error);
      set({ 
        isActiveMatchesLoading: false,
        activeMatchesError: error instanceof Error ? error.message : 'Failed to fetch active matches'
      });
    }
  },

  fetchMatchHistory: async (page = 1) => {
    try {
      set({ isHistoryLoading: true, historyError: null });
      
      const response = await apiClient.get<Match[]>(
        endpoints.matches.history,
        {
          params: {
            include: ['matched_user'],
            sort: '-created_at',
            per_page: get().pagination.perPage,
            page
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch match history');
      }
      
      set({
        matchHistory: page === 1 ? response.data : [...get().matchHistory, ...response.data],
        isHistoryLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching match history:', error);
      set({ 
        isHistoryLoading: false,
        historyError: error instanceof Error ? error.message : 'Failed to fetch match history'
      });
    }
  },

  fetchMatchById: async (id: string) => {
    try {
      set({ isMatchLoading: true, matchError: null });
      
      const response = await apiClient.get<Match>(
        endpoints.matches.show(id),
        {
          params: {
            include: ['matched_user']
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch match');
      }
      
      set({ 
        currentMatch: response.data,
        isMatchLoading: false 
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching match:', error);
      set({ 
        isMatchLoading: false,
        matchError: error instanceof Error ? error.message : 'Failed to fetch match'
      });
      return null;
    }
  },

  startSearch: async (matchType: MatchType, waitTimeMinutes: number) => {
    try {
      const result = await get().createMatch({
        match_type: matchType,
        wait_time_minutes: waitTimeMinutes
      });
      
      if (result) {
        // Start polling for match status
        get().checkMatchStatus();
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Error starting search:', error);
      return false;
    }
  },

  stopSearch: async () => {
    try {
      const { currentMatch } = get();
      
      if (currentMatch) {
        const success = await get().cancelMatch(currentMatch.id);
        if (success) {
          set({
            isSearching: false,
            searchStartTime: null,
            searchDuration: 0,
            matchedUser: null,
          });
          return true;
        }
      } else {
        // If no current match, just reset state
        set({
          isSearching: false,
          searchStartTime: null,
          searchDuration: 0,
          matchedUser: null,
        });
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Error stopping search:', error);
      return false;
    }
  },

  checkMatchStatus: async () => {
    try {
      const { currentMatch, isSearching } = get();
      
      if (!isSearching || !currentMatch) return;
      
      const response = await apiClient.get<Match>(
        endpoints.matches.show(currentMatch.id)
      );

      if (response.success && response.data) {
        const match = response.data;
        
        // Check if match status has changed
        if (match.status !== currentMatch.status) {
                   if (match.status === MatchStatus.Matched && match.matched_user_id) {
           // Match found! We'll need to fetch the matched user separately
           set({
             currentMatch: match,
             isSearching: false,
           });
           
           // Fetch matched user details if we have the ID
           if (match.matched_user_id) {
             try {
               const userResponse = await apiClient.get<User>(
                 `/users/${match.matched_user_id}`
               );
               
               if (userResponse.success && userResponse.data) {
                 set({
                   matchedUser: userResponse.data
                 });
               } else {
                 // Fallback to basic user info if API call fails
                 set({
                   matchedUser: {
                     id: match.matched_user_id,
                     first_name: 'Matched',
                     last_name: 'User',
                     avatar: '',
                     points: 0,
                     role: 2, // User role
                     is_active: true,
                     primary_language: 'en',
                     created_at: new Date().toISOString(),
                     updated_at: new Date().toISOString(),
                   }
                 });
               }
             } catch (error) {
               console.error('Error fetching matched user:', error);
               // Fallback to basic user info
               set({
                 matchedUser: {
                   id: match.matched_user_id,
                   first_name: 'Matched',
                   last_name: 'User',
                   avatar: '',
                   points: 0,
                   role: 2, // User role
                   is_active: true,
                   primary_language: 'en',
                   created_at: new Date().toISOString(),
                   updated_at: new Date().toISOString(),
                 }
               });
             }
           }
            
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            toast.success('Match found!');
          } else if (match.status === MatchStatus.Expired) {
            // Match expired
            set({
              currentMatch: match,
              isSearching: false,
            });
            
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
            toast.error('No match found within the time limit');
          }
        }
      }
    } catch (error) {
      console.error('Error checking match status:', error);
    }
  },

  // Real-time updates
  setConnectionStatus: (isConnected: boolean) => {
    set({ isConnected });
  },

  updateMatchInRealTime: (matchId: string, updates: Partial<Match>) => {
    set(state => ({
      activeMatches: state.activeMatches.map(match => 
        match.id === matchId ? { ...match, ...updates } : match
      ),
      currentMatch: state.currentMatch?.id === matchId 
        ? { ...state.currentMatch, ...updates }
        : state.currentMatch
    }));
  },

  receiveMatch: (match: Match, matchedUser: User) => {
    set({
      currentMatch: match,
      matchedUser,
      isSearching: false,
    });
    
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    toast.success('Match found!');
  },

  // State management
  clearCurrentMatch: () => {
    set({ 
      currentMatch: null,
      matchedUser: null,
      isSearching: false,
      searchStartTime: null,
      searchDuration: 0,
    });
  },

  clearErrors: () => {
    set({ 
      matchError: null, 
      historyError: null, 
      activeMatchesError: null 
    });
  },

  resetSearchState: () => {
    set({
      isSearching: false,
      searchStartTime: null,
      searchDuration: 0,
      matchedUser: null,
      currentMatch: null,
    });
  },
})); 