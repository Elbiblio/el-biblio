import { makeObservable, action, runInAction } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient, endpoints } from '@/api/client';
import { WordHub, WordHubMessage, PaginatedResponse } from '@/types';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

interface PaginationState {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
}

interface FiltersState {
  searchQuery?: string;
  isPrivate?: boolean;
  hasMinPoints?: boolean;
  sortBy?: 'created_at' | 'updated_at' | 'title' | 'member_count' | 'message_count';
  sortOrder?: 'asc' | 'desc';
}

interface WordHubsStoreState {
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
  pagination: PaginationState;

  // Filters
  filters: FiltersState;

  // Real-time updates
  isConnected: boolean;
  lastUpdate: Date | null;
}

export class WordHubsStore extends BaseStore<WordHubsStoreState> {
  constructor() {
    super({
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
        sortBy: 'updated_at',
        sortOrder: 'desc',
      },

      isConnected: false,
      lastUpdate: null,
    });

    makeObservable(this, {
      fetchWordHubs: action.bound,
      fetchHubById: action.bound,
      createHub: action.bound,
      updateHub: action.bound,
      deleteHub: action.bound,
      joinHub: action.bound,
      leaveHub: action.bound,
      fetchHubMessages: action.bound,
      sendMessage: action.bound,
      deleteMessage: action.bound,
      bookmarkHub: action.bound,
      shareHub: action.bound,
      searchHubs: action.bound,
      fetchUserHubs: action.bound,
      fetchJoinedHubs: action.bound,
      setConnectionStatus: action.bound,
      updateHubInRealTime: action.bound,
      addMessageInRealTime: action.bound,
      clearCurrentHub: action.bound,
      clearErrors: action.bound,
      setFilters: action.bound,
      resetFilters: action.bound,
    });
  }

  private computePagination(meta: any, fallbackPage: number, currentTotal: number): PaginationState {
    const current_page = (meta && typeof meta.current_page === 'number') ? meta.current_page : fallbackPage;
    const last_page = (meta && typeof meta.last_page === 'number') ? meta.last_page : current_page;
    const per_page = (meta && typeof meta.per_page === 'number') ? meta.per_page : this.state.pagination.perPage;
    const total = (meta && typeof meta.total === 'number') ? meta.total : (currentTotal ?? 0);
    const hasMore = (typeof current_page === 'number' && typeof last_page === 'number')
      ? current_page < last_page
      : currentTotal >= per_page;

    return {
      currentPage: current_page,
      lastPage: last_page,
      perPage: per_page,
      total,
      hasMore,
    };
  }

  async fetchWordHubs(page = 1, filters: Partial<FiltersState> = {}) {
    try {
      runInAction(() => {
        this.state.isWordHubsLoading = true;
        this.state.wordHubsError = null;
      });

      const currentFilters = { ...this.state.filters, ...filters };
      const sortParam = `${currentFilters.sortOrder === 'desc' ? '-' : ''}${currentFilters.sortBy}`;

      const params: any = {
        include: ['members', 'creator'],
        sort: sortParam,
        per_page: this.state.pagination.perPage,
        page,
      };

      if (currentFilters.searchQuery) {
        params.q = currentFilters.searchQuery;
      }
      if (currentFilters.isPrivate !== undefined) {
        params.is_private = currentFilters.isPrivate;
      }
      if (currentFilters.hasMinPoints) {
        params.has_min_points = true;
      }

      const response = await apiClient.get<PaginatedResponse<WordHub>>(
        endpoints.wordHubs.list,
        params
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch word hubs');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.wordHubs = page === 1 ? data : [...this.state.wordHubs, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters = currentFilters;
        this.state.isWordHubsLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching word hubs:', error);
      runInAction(() => {
        this.state.isWordHubsLoading = false;
        this.state.wordHubsError = error instanceof Error ? error.message : 'Failed to fetch word hubs';
      });
      this.setError(this.state.wordHubsError);
    }
  }

  async fetchHubById(id: string) {
    try {
      runInAction(() => {
        this.state.isHubLoading = true;
        this.state.hubError = null;
      });

      const response = await apiClient.get<WordHub>(
        endpoints.wordHubs.show(id),
        { include: ['members', 'creator', 'recent_messages'] }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch word hub');

      runInAction(() => {
        this.state.currentHub = response.data;
        this.state.isHubLoading = false;
        this.state.lastUpdate = new Date();
      });

      return response.data;
    } catch (error: any) {
      console.error('Error fetching word hub:', error);
      runInAction(() => {
        this.state.isHubLoading = false;
        this.state.hubError = error instanceof Error ? error.message : 'Failed to fetch word hub';
      });
      this.setError(this.state.hubError);
      return null;
    }
  }

  async createHub(data: {
    title: string;
    description: string;
    is_private?: boolean;
    access_code?: string;
    min_points?: number;
  }) {
    try {
      const response = await apiClient.post<WordHub>(endpoints.wordHubs.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create word hub');

      const hub = response.data;

      runInAction(() => {
        this.state.wordHubs = [hub, ...this.state.wordHubs];
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Word hub created successfully!');

      return hub;
    } catch (error: any) {
      console.error('Error creating word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to create word hub';
      toast.error(message);
      return null;
    }
  }

  async updateHub(id: string, data: Partial<WordHub>) {
    try {
      const response = await apiClient.put(endpoints.wordHubs.update(id), data);

      if (!response.success) throw new Error(response.message || 'Failed to update word hub');

      runInAction(() => {
        this.state.wordHubs = this.state.wordHubs.map(hub => 
          hub.id === id ? { ...hub, ...data } : hub
        );
        if (this.state.currentHub?.id === id) {
          this.state.currentHub = { ...this.state.currentHub, ...data };
        }
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Word hub updated successfully!');

      return true;
    } catch (error: any) {
      console.error('Error updating word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to update word hub';
      toast.error(message);
      return false;
    }
  }

  async deleteHub(id: string) {
    try {
      const response = await apiClient.delete(endpoints.wordHubs.delete(id));

      if (!response.success) throw new Error(response.message || 'Failed to delete word hub');

      runInAction(() => {
        this.state.wordHubs = this.state.wordHubs.filter(hub => hub.id !== id);
        if (this.state.currentHub?.id === id) {
          this.state.currentHub = null;
        }
      });

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Word hub deleted successfully!');

      return true;
    } catch (error: any) {
      console.error('Error deleting word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to delete word hub';
      toast.error(message);
      return false;
    }
  }

  async joinHub(hubId: string, accessCode?: string) {
    try {
      const response = await apiClient.post(
        endpoints.wordHubs.join(hubId),
        accessCode ? { access_code: accessCode } : {}
      );

      if (!response.success) throw new Error(response.message || 'Failed to join word hub');

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Successfully joined word hub!');

      return true;
    } catch (error: any) {
      console.error('Error joining word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to join word hub';
      toast.error(message);
      return false;
    }
  }

  async leaveHub(hubId: string) {
    try {
      const response = await apiClient.post(endpoints.wordHubs.leave(hubId));

      if (!response.success) throw new Error(response.message || 'Failed to leave word hub');

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Successfully left word hub!');

      return true;
    } catch (error: any) {
      console.error('Error leaving word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to leave word hub';
      toast.error(message);
      return false;
    }
  }

  async fetchHubMessages(hubId: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isMessagesLoading = true;
        this.state.messagesError = null;
      });

      const response = await apiClient.get<PaginatedResponse<WordHubMessage>>(
        endpoints.wordHubs.messages(hubId),
        {
          include: ['user'],
          sort: '-created_at',
          per_page: 50,
          page,
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch hub messages');

      const { data } = response.data;

      runInAction(() => {
        this.state.hubMessages = page === 1 ? data : [...this.state.hubMessages, ...data];
        this.state.isMessagesLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching hub messages:', error);
      runInAction(() => {
        this.state.isMessagesLoading = false;
        this.state.messagesError = error instanceof Error ? error.message : 'Failed to fetch hub messages';
      });
      this.setError(this.state.messagesError);
    }
  }

  async sendMessage(hubId: string, message: string) {
    try {
      const response = await apiClient.post<WordHubMessage>(
        endpoints.wordHubs.sendMessage(hubId),
        { message }
      );

      if (!response.success) throw new Error(response.message || 'Failed to send message');

      const newMessage = response.data;

      runInAction(() => {
        this.state.hubMessages = [newMessage, ...this.state.hubMessages];
      });

      return newMessage;
    } catch (error: any) {
      console.error('Error sending message:', error);
      const message = error instanceof Error ? error.message : 'Failed to send message';
      toast.error(message);
      return null;
    }
  }

  async deleteMessage(hubId: string, messageId: string) {
    try {
      const response = await apiClient.delete(`/word-hubs/${hubId}/messages/${messageId}`);

      if (!response.success) throw new Error(response.message || 'Failed to delete message');

      runInAction(() => {
        this.state.hubMessages = this.state.hubMessages.filter(msg => msg.id !== messageId);
      });

      return true;
    } catch (error: any) {
      console.error('Error deleting message:', error);
      return false;
    }
  }

  async bookmarkHub(hubId: string) {
    try {
      const response = await apiClient.post(
        endpoints.bookmarks.create,
        {
          bookmarkable_type: 'WordHub',
          bookmarkable_id: hubId
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to bookmark word hub');

      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Word hub bookmarked!');

      return true;
    } catch (error: any) {
      console.error('Error bookmarking word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to bookmark word hub';
      toast.error(message);
      return false;
    }
  }

  async shareHub(hubId: string) {
    try {
      const response = await apiClient.post(`/word-hubs/${hubId}/share`);

      if (!response.success) throw new Error(response.message || 'Failed to share word hub');

      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      toast.success('Word hub shared!');

      return true;
    } catch (error: any) {
      console.error('Error sharing word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to share word hub';
      toast.error(message);
      return false;
    }
  }

  async searchHubs(query: string, limit = 20) {
    try {
      const response = await apiClient.get<WordHub[]>(
        endpoints.wordHubs.list,
        {
          q: query,
          include: ['members', 'creator'],
          per_page: limit,
          sort: '-updated_at'
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to search word hubs');

      return response.data;
    } catch (error) {
      console.error('Error searching word hubs:', error);
      return [];
    }
  }

  async fetchUserHubs(userId: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isWordHubsLoading = true;
        this.state.wordHubsError = null;
      });

      const response = await apiClient.get<PaginatedResponse<WordHub>>(
        endpoints.wordHubs.byUser(userId),
        {
          include: ['members', 'creator'],
          per_page: this.state.pagination.perPage,
          page,
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch user hubs');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.wordHubs = page === 1 ? data : [...this.state.wordHubs, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.isWordHubsLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching user hubs:', error);
      runInAction(() => {
        this.state.isWordHubsLoading = false;
        this.state.wordHubsError = error instanceof Error ? error.message : 'Failed to fetch user hubs';
      });
      this.setError(this.state.wordHubsError);
    }
  }

  async fetchJoinedHubs(page = 1) {
    try {
      runInAction(() => {
        this.state.isWordHubsLoading = true;
        this.state.wordHubsError = null;
      });

      const response = await apiClient.get<PaginatedResponse<WordHub>>(
        '/word-hubs/joined',
        {
          include: ['members', 'creator'],
          per_page: this.state.pagination.perPage,
          page,
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch joined hubs');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.wordHubs = page === 1 ? data : [...this.state.wordHubs, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.isWordHubsLoading = false;
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching joined hubs:', error);
      runInAction(() => {
        this.state.isWordHubsLoading = false;
        this.state.wordHubsError = error instanceof Error ? error.message : 'Failed to fetch joined hubs';
      });
      this.setError(this.state.wordHubsError);
    }
  }

  // Real-time updates
  setConnectionStatus(isConnected: boolean) {
    runInAction(() => {
      this.state.isConnected = isConnected;
    });
  }

  updateHubInRealTime(hubId: string, updates: Partial<WordHub>) {
    runInAction(() => {
      this.state.wordHubs = this.state.wordHubs.map(hub => 
        hub.id === hubId ? { ...hub, ...updates } : hub
      );
      if (this.state.currentHub?.id === hubId) {
        this.state.currentHub = { ...this.state.currentHub, ...updates };
      }
    });
  }

  addMessageInRealTime(hubId: string, message: WordHubMessage) {
    runInAction(() => {
      if (this.state.currentHub?.id === hubId) {
        this.state.hubMessages = [message, ...this.state.hubMessages];
      }
    });
  }

  // State management
  clearCurrentHub() {
    runInAction(() => {
      this.state.currentHub = null;
      this.state.hubMessages = [];
      this.state.isHubLoading = false;
      this.state.isMessagesLoading = false;
      this.state.hubError = null;
      this.state.messagesError = null;
    });
  }

  clearErrors() {
    runInAction(() => {
      this.state.wordHubsError = null;
      this.state.hubError = null;
      this.state.messagesError = null;
    });
    this.setError(null);
  }

  setFilters(filters: Partial<FiltersState>) {
    runInAction(() => {
      this.state.filters = { ...this.state.filters, ...filters };
    });
  }

  resetFilters() {
    runInAction(() => {
      this.state.filters = {
        sortBy: 'updated_at',
        sortOrder: 'desc',
      };
    });
  }
}
