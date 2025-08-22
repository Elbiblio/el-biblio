import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { WordHub, WordHubMessage, User, PaginatedResponse } from '@/types';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

interface WordHubsState {
  // Word Hubs list
  wordHubs: WordHub[];
  isWordHubsLoading: boolean;
  wordHubsError: string | null;
  
  // Single hub
  currentHub: WordHub | null;
  isHubLoading: boolean;
  hubError: string | null;
  
  // Hub messages
  hubMessages: WordHubMessage[];
  isMessagesLoading: boolean;
  messagesError: string | null;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Filters
  filters: {
    searchQuery?: string;
    isPrivate?: boolean;
    hasMinPoints?: boolean;
    sortBy?: 'created_at' | 'updated_at' | 'title' | 'member_count' | 'message_count';
    sortOrder?: 'asc' | 'desc';
  };
  
  // Real-time updates
  isConnected: boolean;
  lastUpdate: Date | null;
  
  // Actions
  fetchWordHubs: (page?: number, filters?: Partial<WordHubsState['filters']>) => Promise<void>;
  fetchHubById: (id: string) => Promise<WordHub | null>;
  createHub: (data: {
    title: string;
    description: string;
    is_private?: boolean;
    access_code?: string;
    min_points?: number;
  }) => Promise<WordHub | null>;
  updateHub: (id: string, data: Partial<WordHub>) => Promise<boolean>;
  deleteHub: (id: string) => Promise<boolean>;
  
  // Hub membership
  joinHub: (hubId: string, accessCode?: string) => Promise<boolean>;
  leaveHub: (hubId: string) => Promise<boolean>;
  
  // Hub messages
  fetchHubMessages: (hubId: string, page?: number) => Promise<void>;
  sendMessage: (hubId: string, message: string) => Promise<WordHubMessage | null>;
  deleteMessage: (hubId: string, messageId: string) => Promise<boolean>;
  
  // Hub interactions
  bookmarkHub: (hubId: string) => Promise<boolean>;
  shareHub: (hubId: string) => Promise<boolean>;
  
  // Search and filtering
  searchHubs: (query: string, limit?: number) => Promise<WordHub[]>;
  fetchUserHubs: (userId: string, page?: number) => Promise<void>;
  fetchJoinedHubs: (page?: number) => Promise<void>;
  
  // Real-time updates
  setConnectionStatus: (isConnected: boolean) => void;
  updateHubInRealTime: (hubId: string, updates: Partial<WordHub>) => void;
  addMessageInRealTime: (hubId: string, message: WordHubMessage) => void;
  
  // State management
  clearCurrentHub: () => void;
  clearErrors: () => void;
  setFilters: (filters: Partial<WordHubsState['filters']>) => void;
  resetFilters: () => void;
}

export const useWordHubsStore = create<WordHubsState>((set, get) => ({
  // Initial State
  wordHubs: [],
  isWordHubsLoading: false,
  wordHubsError: null,
  
  currentHub: null,
  isHubLoading: false,
  hubError: null,
  
  hubMessages: [],
  isMessagesLoading: false,
  messagesError: null,
  
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },
  
  filters: {
    sortBy: 'created_at',
    sortOrder: 'desc',
  },
  
  isConnected: false,
  lastUpdate: null,
  
  // Actions
  fetchWordHubs: async (page = 1, filters = {}) => {
    try {
      set({ isWordHubsLoading: true, wordHubsError: null });
      
      const currentFilters = { ...get().filters, ...filters };
      const sortParam = `${currentFilters.sortOrder === 'desc' ? '-' : ''}${currentFilters.sortBy}`;
      
      const params: any = {
        include: ['user', 'members.user', 'bookmarks', 'messages'],
        sort: sortParam,
        per_page: get().pagination.perPage,
        page,
      };
      
      // Add filters
      if (currentFilters.searchQuery) {
        params.search = currentFilters.searchQuery;
      }
      if (currentFilters.isPrivate !== undefined) {
        params.is_private = currentFilters.isPrivate;
      }
      if (currentFilters.hasMinPoints !== undefined) {
        params.has_min_points = currentFilters.hasMinPoints;
      }
      
      const response = await apiClient.get<PaginatedResponse<WordHub>>(
        endpoints.wordHubs.list,
        { params }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch word hubs');
      }
      
      const { data, meta } = response.data;
      
      set({
        wordHubs: page === 1 ? data : [...get().wordHubs, ...data],
        pagination: {
          currentPage: meta.current_page,
          lastPage: meta.last_page,
          perPage: meta.per_page,
          total: meta.total,
          hasMore: meta.current_page < meta.last_page,
        },
        isWordHubsLoading: false,
        lastUpdate: new Date(),
      });

    } catch (error) {
      console.error('Error fetching word hubs:', error);
      set({ 
        isWordHubsLoading: false,
        wordHubsError: error instanceof Error ? error.message : 'Failed to fetch word hubs'
      });
    }
  },

  fetchHubById: async (id: string) => {
    try {
      set({ isHubLoading: true, hubError: null });
      
      const response = await apiClient.get<WordHub>(
        endpoints.wordHubs.show(id),
        {
          params: {
            include: ['user', 'members.user', 'bookmarks', 'messages.user', 'activities']
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch hub');
      }
      
      set({ 
        currentHub: response.data,
        isHubLoading: false 
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching hub:', error);
      set({ 
        isHubLoading: false,
        hubError: error instanceof Error ? error.message : 'Failed to fetch hub'
      });
      return null;
    }
  },

  createHub: async (data) => {
    try {
      const response = await apiClient.post<WordHub>(
        endpoints.wordHubs.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create hub');
      }
      
      const newHub = response.data;
      
      // Add to local state
      set(state => ({
        wordHubs: [newHub, ...state.wordHubs],
        currentHub: newHub
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Word Hub created successfully!');
      
      return newHub;
    } catch (error) {
      console.error('Error creating hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to create hub';
      toast.error(message);
      return null;
    }
  },

  updateHub: async (id: string, data: Partial<WordHub>) => {
    try {
      const response = await apiClient.put<WordHub>(
        endpoints.wordHubs.update(id),
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update hub');
      }
      
      const updatedHub = response.data;
      
      // Update in local state
      set(state => ({
        wordHubs: state.wordHubs.map(hub => 
          hub.id === id ? updatedHub : hub
        ),
        currentHub: state.currentHub?.id === id ? updatedHub : state.currentHub
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Hub updated successfully!');
      
      return true;
    } catch (error) {
      console.error('Error updating hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to update hub';
      toast.error(message);
      return false;
    }
  },

  deleteHub: async (id: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.wordHubs.delete(id)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete hub');
      }
      
      // Remove from local state
      set(state => ({
        wordHubs: state.wordHubs.filter(hub => hub.id !== id),
        currentHub: state.currentHub?.id === id ? null : state.currentHub
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Hub deleted successfully!');
      
      return true;
    } catch (error) {
      console.error('Error deleting hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to delete hub';
      toast.error(message);
      return false;
    }
  },

  joinHub: async (hubId: string, accessCode?: string) => {
    try {
      const response = await apiClient.post<{ member: any }>(
        endpoints.wordHubs.join(hubId),
        accessCode ? { access_code: accessCode } : undefined
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to join hub');
      }
      
      // Update hub membership status in local state
      set(state => ({
        wordHubs: state.wordHubs.map(hub => 
          hub.id === hubId ? { ...hub, isMember: true, member_count: (hub.member_count || 0) + 1 } : hub
        ),
        currentHub: state.currentHub?.id === hubId 
          ? { ...state.currentHub, isMember: true, member_count: (state.currentHub.member_count || 0) + 1 }
          : state.currentHub
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Successfully joined the hub!');
      
      return true;
    } catch (error) {
      console.error('Error joining hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to join hub';
      toast.error(message);
      return false;
    }
  },

  leaveHub: async (hubId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.wordHubs.leave(hubId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to leave hub');
      }
      
      // Update hub membership status in local state
      set(state => ({
        wordHubs: state.wordHubs.map(hub => 
          hub.id === hubId ? { ...hub, isMember: false, member_count: Math.max(0, (hub.member_count || 0) - 1) } : hub
        ),
        currentHub: state.currentHub?.id === hubId 
          ? { ...state.currentHub, isMember: false, member_count: Math.max(0, (state.currentHub.member_count || 0) - 1) }
          : state.currentHub
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Successfully left the hub!');
      
      return true;
    } catch (error) {
      console.error('Error leaving hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to leave hub';
      toast.error(message);
      return false;
    }
  },

  fetchHubMessages: async (hubId: string, page = 1) => {
    try {
      set({ isMessagesLoading: true, messagesError: null });
      
      const response = await apiClient.get<PaginatedResponse<WordHubMessage>>(
        endpoints.wordHubs.messages(hubId),
        {
          params: {
            include: ['user'],
            sort: '-created_at',
            per_page: 50,
            page
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch messages');
      }
      
      const { data, meta } = response.data;
      
      set({
        hubMessages: page === 1 ? data : [...get().hubMessages, ...data],
        isMessagesLoading: false,
      });

    } catch (error) {
      console.error('Error fetching hub messages:', error);
      set({ 
        isMessagesLoading: false,
        messagesError: error instanceof Error ? error.message : 'Failed to fetch messages'
      });
    }
  },

  sendMessage: async (hubId: string, message: string) => {
    try {
      const response = await apiClient.post<{ message: WordHubMessage }>(
        endpoints.wordHubs.sendMessage(hubId),
        { message: message.trim() }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to send message');
      }
      
      const newMessage = response.data.message;
      
      // Add to local state
      set(state => ({
        hubMessages: [newMessage, ...state.hubMessages]
      }));
      
      // Update message count in hub
      set(state => ({
        wordHubs: state.wordHubs.map(hub => 
          hub.id === hubId ? { ...hub, message_count: (hub.message_count || 0) + 1 } : hub
        ),
        currentHub: state.currentHub?.id === hubId 
          ? { ...state.currentHub, message_count: (state.currentHub.message_count || 0) + 1 }
          : state.currentHub
      }));
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      
      return newMessage;
    } catch (error) {
      console.error('Error sending message:', error);
      const message = error instanceof Error ? error.message : 'Failed to send message';
      toast.error(message);
      return null;
    }
  },

  deleteMessage: async (hubId: string, messageId: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.wordHubs.messages(hubId) + `/${messageId}`
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete message');
      }
      
      // Remove from local state
      set(state => ({
        hubMessages: state.hubMessages.filter(msg => msg.id !== messageId)
      }));
      
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Message deleted successfully!');
      
      return true;
    } catch (error) {
      console.error('Error deleting message:', error);
      const message = error instanceof Error ? error.message : 'Failed to delete message';
      toast.error(message);
      return false;
    }
  },

  bookmarkHub: async (hubId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.wordHubs.show(hubId) + '/bookmark'
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to bookmark hub');
      }
      
      // Update bookmark status in local state
      set(state => ({
        wordHubs: state.wordHubs.map(hub => 
          hub.id === hubId ? { ...hub, isBookmarked: !hub.isBookmarked } : hub
        ),
        currentHub: state.currentHub?.id === hubId 
          ? { ...state.currentHub, isBookmarked: !state.currentHub.isBookmarked }
          : state.currentHub
      }));
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      
      return true;
    } catch (error) {
      console.error('Error bookmarking hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to bookmark hub';
      toast.error(message);
      return false;
    }
  },

  shareHub: async (hubId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.wordHubs.show(hubId) + '/share'
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to share hub');
      }
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Hub shared successfully!');
      
      return true;
    } catch (error) {
      console.error('Error sharing hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to share hub';
      toast.error(message);
      return false;
    }
  },

  searchHubs: async (query: string, limit = 20) => {
    try {
      const response = await apiClient.get<WordHub[]>(
        endpoints.wordHubs.list,
        {
          params: {
            search: query,
            include: ['user', 'members.user'],
            per_page: limit
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to search hubs');
      }
      
      return response.data;
    } catch (error) {
      console.error('Error searching hubs:', error);
      return [];
    }
  },

  fetchUserHubs: async (userId: string, page = 1) => {
    try {
      set({ isWordHubsLoading: true, wordHubsError: null });
      
      const response = await apiClient.get<PaginatedResponse<WordHub>>(
        endpoints.wordHubs.byUser(userId),
        {
          params: {
            include: ['user', 'members.user'],
            sort: '-created_at',
            per_page: get().pagination.perPage,
            page
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch user hubs');
      }
      
      const { data, meta } = response.data;
      
      set({
        wordHubs: page === 1 ? data : [...get().wordHubs, ...data],
        pagination: {
          currentPage: meta.current_page,
          lastPage: meta.last_page,
          perPage: meta.per_page,
          total: meta.total,
          hasMore: meta.current_page < meta.last_page,
        },
        isWordHubsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching user hubs:', error);
      set({ 
        isWordHubsLoading: false,
        wordHubsError: error instanceof Error ? error.message : 'Failed to fetch user hubs'
      });
    }
  },

  fetchJoinedHubs: async (page = 1) => {
    try {
      set({ isWordHubsLoading: true, wordHubsError: null });
      
      const response = await apiClient.get<PaginatedResponse<WordHub>>(
        endpoints.wordHubs.list,
        {
          params: {
            include: ['user', 'members.user'],
            filter: 'joined',
            sort: '-updated_at',
            per_page: get().pagination.perPage,
            page
          }
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch joined hubs');
      }
      
      const { data, meta } = response.data;
      
      set({
        wordHubs: page === 1 ? data : [...get().wordHubs, ...data],
        pagination: {
          currentPage: meta.current_page,
          lastPage: meta.last_page,
          perPage: meta.per_page,
          total: meta.total,
          hasMore: meta.current_page < meta.last_page,
        },
        isWordHubsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching joined hubs:', error);
      set({ 
        isWordHubsLoading: false,
        wordHubsError: error instanceof Error ? error.message : 'Failed to fetch joined hubs'
      });
    }
  },

  // Real-time updates
  setConnectionStatus: (isConnected: boolean) => {
    set({ isConnected });
  },

  updateHubInRealTime: (hubId: string, updates: Partial<WordHub>) => {
    set(state => ({
      wordHubs: state.wordHubs.map(hub => 
        hub.id === hubId ? { ...hub, ...updates } : hub
      ),
      currentHub: state.currentHub?.id === hubId 
        ? { ...state.currentHub, ...updates }
        : state.currentHub
    }));
  },

  addMessageInRealTime: (hubId: string, message: WordHubMessage) => {
    set(state => ({
      hubMessages: [message, ...state.hubMessages]
    }));
    
    // Update message count
    set(state => ({
      wordHubs: state.wordHubs.map(hub => 
        hub.id === hubId ? { ...hub, message_count: (hub.message_count || 0) + 1 } : hub
      ),
      currentHub: state.currentHub?.id === hubId 
        ? { ...state.currentHub, message_count: (state.currentHub.message_count || 0) + 1 }
        : state.currentHub
    }));
  },

  // State management
  clearCurrentHub: () => {
    set({ currentHub: null, hubMessages: [] });
  },

  clearErrors: () => {
    set({ 
      wordHubsError: null, 
      hubError: null, 
      messagesError: null 
    });
  },

  setFilters: (filters: Partial<WordHubsState['filters']>) => {
    set(state => ({
      filters: { ...state.filters, ...filters }
    }));
  },

  resetFilters: () => {
    set({
      filters: {
        sortBy: 'created_at',
        sortOrder: 'desc',
      }
    });
  },
})); 