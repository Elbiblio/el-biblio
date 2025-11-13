import { runInAction, makeAutoObservable } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { WordHub, WordHubMessage, PaginatedResponse, WordHubMember, LiveKitCredentials } from '@/types';
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

interface WordHubJoinResponse {
  member: WordHubMember;
  livekit?: LiveKitCredentials | null;
}

interface CachedLiveKitSession {
  credentials: LiveKitCredentials;
  member: WordHubMember | null;
  accessCode?: string;
}

interface MessageAuthor {
  id?: string;
  name?: string;
  avatar?: string;
}

export interface LiveKitSessionState {
  hubId: string;
  member: WordHubMember | null;
  credentials: LiveKitCredentials;
  accessCode?: string;
  isConnecting: boolean;
  isConnected: boolean;
  error: string | null;
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

  // LiveKit audio session
  activeLiveKitSession: LiveKitSessionState | null;
  liveKitSessionCache: Record<string, CachedLiveKitSession>;
  lastSocketDisconnectReason?: string;
}

const extractWordHubs = (payload: any) => {
  if (Array.isArray(payload)) {
    return { items: payload as WordHub[], meta: undefined };
  }

  if (payload && Array.isArray(payload.data)) {
    return { items: payload.data as WordHub[], meta: payload.meta };
  }

  if (payload?.data && Array.isArray(payload.data.data)) {
    return { items: payload.data.data as WordHub[], meta: payload.data.meta ?? payload.meta };
  }

  return { items: [] as WordHub[], meta: payload?.meta };
};

export class WordHubsStore {
  state: WordHubsStoreState;
  error: string | null = null;

  constructor() {
    this.state = {
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

      activeLiveKitSession: null,
      liveKitSessionCache: {},
      lastSocketDisconnectReason: undefined,
    };

    makeAutoObservable(this, {}, { autoBind: true });
  }

  activateCachedLiveKitSession(hubId: string) {
    const cached = this.state.liveKitSessionCache[hubId];
    if (!cached) {
      return null;
    }

    const session: LiveKitSessionState = {
      hubId,
      member: cached.member,
      credentials: cached.credentials,
      accessCode: cached.accessCode,
      isConnecting: false,
      isConnected: false,
      error: null,
    };

    this.setLiveKitSession(session);
    return session;
  }

  async refreshLiveKitSession(hubId: string, userId?: string) {
    const activeSession = this.state.activeLiveKitSession;
    if (activeSession?.hubId === hubId) {
      return activeSession;
    }

    const cachedSession = this.activateCachedLiveKitSession(hubId);
    if (cachedSession) {
      return cachedSession;
    }

    const accessCode = this.state.liveKitSessionCache[hubId]?.accessCode;
    return this.joinHub(hubId, accessCode, { silent: true });
  }

  private cacheLiveKitSession(session: LiveKitSessionState) {
    runInAction(() => {
      this.state.liveKitSessionCache[session.hubId] = {
        credentials: session.credentials,
        member: session.member,
        accessCode: session.accessCode,
      };
    });
  }

  private removeCachedLiveKitSession(hubId: string) {
    runInAction(() => {
      delete this.state.liveKitSessionCache[hubId];
    });
  }

  private setError(message: string | null) {
    this.error = message;
  }

  // Convenience getters for UI components
  get wordHubs() {
    return this.state.wordHubs;
  }

  get isWordHubsLoading() {
    return this.state.isWordHubsLoading;
  }

  get wordHubsError() {
    return this.state.wordHubsError;
  }

  get currentHub() {
    return this.state.currentHub;
  }

  get isHubLoading() {
    return this.state.isHubLoading;
  }

  get hubError() {
    return this.state.hubError;
  }

  get hubMessages() {
    return this.state.hubMessages;
  }

  get isMessagesLoading() {
    return this.state.isMessagesLoading;
  }

  get messagesError() {
    return this.state.messagesError;
  }

  get isConnected() {
    return this.state.isConnected;
  }

  get lastUpdate() {
    return this.state.lastUpdate;
  }

  get activeLiveKitSession() {
    return this.state.activeLiveKitSession;
  }

  get lastSocketDisconnectReason() {
    return this.state.lastSocketDisconnectReason;
  }

  private getMemberByUserId(userId?: string | null) {
    if (!userId) return undefined;
    return this.state.currentHub?.members?.find((member) => member.user?.id === userId);
  }

  private resolveDisplayName(input: any): string {
    if (!input) return 'Unknown User';
    if (typeof input.name === 'string' && input.name.trim()) {
      return input.name.trim();
    }

    const first = input.first_name ?? input.firstName ?? '';
    const last = input.last_name ?? input.lastName ?? '';
    const combined = `${first} ${last}`.trim();
    if (combined) {
      return combined;
    }

    const username = input.username ?? input.email ?? input.handle;
    if (typeof username === 'string' && username.trim()) {
      return username.trim();
    }

    return 'Unknown User';
  }

  private normalizeMessage(message: WordHubMessage, author?: MessageAuthor): WordHubMessage {
    const currentUser = message.user;
    const candidateId = (message as any).user_id ?? currentUser?.id ?? author?.id;

    if (currentUser && currentUser.name) {
      return {
        ...message,
        user: {
          id: currentUser.id,
          name: this.resolveDisplayName(currentUser),
          avatar: currentUser.avatar,
        },
      };
    }

    const member = candidateId ? this.getMemberByUserId(candidateId) : undefined;
    const memberUser = member?.user;

    const resolvedAuthor = currentUser
      ?? (memberUser ? {
        id: memberUser.id,
        name: this.resolveDisplayName(memberUser),
        avatar: memberUser.avatar,
      } : undefined)
      ?? (author?.id ? {
        id: author.id,
        name: author.name ?? 'Unknown User',
        avatar: author.avatar,
      } : undefined);

    const fallbackId = candidateId ?? author?.id ?? 'unknown';
    const fallbackName = author?.name ?? (memberUser ? this.resolveDisplayName(memberUser) : 'Unknown User');

    return {
      ...message,
      user: {
        id: resolvedAuthor?.id ?? fallbackId,
        name: resolvedAuthor?.name ?? fallbackName ?? 'Unknown User',
        avatar: resolvedAuthor?.avatar ?? memberUser?.avatar ?? author?.avatar,
      },
    };
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

      const { items, meta } = extractWordHubs(response.data);

      runInAction(() => {
        const current = page === 1 || !Array.isArray(this.state.wordHubs) ? [] : this.state.wordHubs;
        this.state.wordHubs = page === 1 ? items : [...current, ...items];
        this.state.pagination = this.computePagination(meta, page, items.length);
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
        { include: ['members', 'creator'] }
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
        const current = Array.isArray(this.state.wordHubs) ? this.state.wordHubs : [];
        this.state.wordHubs = [hub, ...current];
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
        this.state.wordHubs = this.state.wordHubs?.map(hub => 
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

  private setLiveKitSession(session: LiveKitSessionState | null) {
    runInAction(() => {
      this.state.activeLiveKitSession = session;
    });
  }

  markLiveKitConnecting(hubId: string) {
    runInAction(() => {
      if (this.state.activeLiveKitSession?.hubId === hubId) {
        this.state.activeLiveKitSession = {
          ...this.state.activeLiveKitSession,
          isConnecting: true,
          error: null,
        };
      }
    });
  }

  markLiveKitConnected(hubId: string) {
    runInAction(() => {
      if (this.state.activeLiveKitSession?.hubId === hubId) {
        this.state.activeLiveKitSession = {
          ...this.state.activeLiveKitSession,
          isConnecting: false,
          isConnected: true,
          error: null,
        };
      }
    });
  }

  markLiveKitDisconnected(hubId: string, error?: string) {
    runInAction(() => {
      if (this.state.activeLiveKitSession?.hubId === hubId) {
        this.state.activeLiveKitSession = {
          ...this.state.activeLiveKitSession,
          isConnecting: false,
          isConnected: false,
          error: error ?? null,
        };
      }
      this.state.lastSocketDisconnectReason = error;
    });
  }

  clearSocketDisconnectReason() {
    runInAction(() => {
      this.state.lastSocketDisconnectReason = undefined;
    });
  }

  clearLiveKitSession(hubId?: string) {
    runInAction(() => {
      if (!hubId || this.state.activeLiveKitSession?.hubId === hubId) {
        this.state.activeLiveKitSession = null;
      }
    });
  }

  async joinHub(hubId: string, accessCode?: string, options: { silent?: boolean } = {}) {
    try {
      const response = await apiClient.post<WordHubJoinResponse>(
        endpoints.wordHubs.join(hubId),
        accessCode ? { access_code: accessCode } : {}
      );

      if (!response.success) throw new Error(response.message || 'Failed to join word hub');

      const data = response.data;

      if (data?.livekit) {
        const session: LiveKitSessionState = {
          hubId,
          member: data.member ?? null,
          credentials: data.livekit,
          accessCode,
          isConnecting: true,
          isConnected: false,
          error: null,
        };

        this.setLiveKitSession(session);
        this.cacheLiveKitSession(session);
      } else {
        this.clearLiveKitSession(hubId);
      }

      if (!options.silent) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        toast.success('Successfully joined word hub!');
      }

      return data;
    } catch (error: any) {
      console.error('Error joining word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to join word hub';
      if (!options?.silent) {
        toast.error(message);
      }
      return null;
    }
  }

  async leaveHub(hubId: string) {
    try {
      const response = await apiClient.post(endpoints.wordHubs.leave(hubId));

      if (!response.success) throw new Error(response.message || 'Failed to leave word hub');

      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Successfully left word hub!');

      this.clearLiveKitSession(hubId);

      return true;
    } catch (error: any) {
      console.error('Error leaving word hub:', error);
      const message = error instanceof Error ? error.message : 'Failed to leave word hub';
      toast.error(message);
      return false;
    }
  }

  async fetchHubMessages(hubId: string, page = 1, options: { silent?: boolean } = {}) {
    try {
      if (!options.silent) {
        runInAction(() => {
          this.state.isMessagesLoading = true;
          this.state.messagesError = null;
        });
      }

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

      const payload = response.data;
      const list = Array.isArray((payload as any)?.data) ? (payload as any).data as WordHubMessage[] : [];
      const normalized = list?.map((msg) => this.normalizeMessage(msg));

      runInAction(() => {
        this.state.hubMessages = page === 1 ? normalized : [...this.state.hubMessages, ...normalized];
        if (!options.silent) {
          this.state.isMessagesLoading = false;
        }
        this.state.lastUpdate = new Date();
      });
    } catch (error: any) {
      console.error('Error fetching hub messages:', error);
      runInAction(() => {
        if (!options.silent) {
          this.state.isMessagesLoading = false;
        }
        this.state.messagesError = error instanceof Error ? error.message : 'Failed to fetch hub messages';
      });
      this.setError(this.state.messagesError);
    }
  }

  async sendMessage(hubId: string, message: string, author?: MessageAuthor) {
    try {
      const response = await apiClient.post<WordHubMessage>(
        endpoints.wordHubs.sendMessage(hubId),
        { message }
      );

      if (!response.success) throw new Error(response.message || 'Failed to send message');

      const payload = (response.data as any)?.message ?? response.data;
      if (!payload) {
        throw new Error('Message payload missing from server response');
      }

      const newMessage = this.normalizeMessage(payload as WordHubMessage, author);

      runInAction(() => {
        const remaining = this.state.hubMessages.filter(msg => msg.id !== newMessage.id);
        this.state.hubMessages = [newMessage, ...remaining];
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

      runInAction(() => {
        const idx = this.state.wordHubs.findIndex(h => String(h.id) === String(hubId));
        if (idx !== -1) {
          this.state.wordHubs[idx] = { ...this.state.wordHubs[idx], isBookmarked: true } as any;
        }
        if (this.state.currentHub && String(this.state.currentHub.id) === String(hubId)) {
          this.state.currentHub = { ...this.state.currentHub, isBookmarked: true } as any;
        }
      });

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

      const { items, meta } = extractWordHubs(response.data);

      runInAction(() => {
        const current = page === 1 || !Array.isArray(this.state.wordHubs) ? [] : this.state.wordHubs;
        this.state.wordHubs = page === 1 ? items : [...current, ...items];
        this.state.pagination = this.computePagination(meta, page, items.length);
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

      const { items, meta } = extractWordHubs(response.data);

      runInAction(() => {
        const current = page === 1 || !Array.isArray(this.state.wordHubs) ? [] : this.state.wordHubs;
        this.state.wordHubs = page === 1 ? items : [...current, ...items];
        this.state.pagination = this.computePagination(meta, page, items.length);
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
      this.state.wordHubs = this.state.wordHubs?.map(hub => 
        hub.id === hubId ? { ...hub, ...updates } : hub
      );
      if (this.state.currentHub?.id === hubId) {
        this.state.currentHub = { ...this.state.currentHub, ...updates };
      }
    });
  }

  addMessageInRealTime(hubId: string, message: WordHubMessage, author?: MessageAuthor) {
    runInAction(() => {
      if (this.state.currentHub?.id === hubId) {
        const normalized = this.normalizeMessage(message, author);
        const existingIndex = this.state.hubMessages.findIndex(existing => existing.id === normalized.id);
        if (existingIndex >= 0) {
          const updated = [...this.state.hubMessages];
          updated.splice(existingIndex, 1);
          this.state.hubMessages = [normalized, ...updated];
        } else {
          this.state.hubMessages = [normalized, ...this.state.hubMessages];
        }
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
