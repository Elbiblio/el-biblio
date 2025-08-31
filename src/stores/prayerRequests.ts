import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import type { PaginatedResponse, PrayerRequest, User } from '@/types';
import { buildPagination } from '@/utils/pagination';

interface PrayerRequestsState {
  // List
  requests: PrayerRequest[];
  isLoading: boolean;
  error: string | null;

  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };

  // Actions
  fetchRequests: (page?: number, params?: { sort?: string; category?: string | 'all' }) => Promise<void>;
  createRequest: (data: { content: string; category?: string; visibility?: 'public'|'community'|'private' }) => Promise<PrayerRequest | null>;
  prayForRequest: (id: string) => Promise<boolean>;
  deleteRequest: (id: string) => Promise<boolean>;
  reset: () => void;
}

export const usePrayerRequestsStore = create<PrayerRequestsState>((set, get) => ({
  requests: [],
  isLoading: false,
  error: null,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },

  fetchRequests: async (page = 1, params = {}) => {
    try {
      set({ isLoading: true, error: null });

      const response = await apiClient.get<PaginatedResponse<PrayerRequest>>(
        endpoints.prayerRequests.list,
        {
          include: ['user', 'prayed_users'],
          per_page: get().pagination.perPage,
          page,
          sort: params.sort ?? '-created_at',
          ...(params.category && params.category !== 'all' ? { category: params.category } : {}),
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch prayer requests');

      const { data, meta } = response.data;

      set({
        requests: page === 1 ? data : [...get().requests, ...data],
        pagination: buildPagination(meta as any, get().pagination, page, Array.isArray(data) ? data.length : 0),
        isLoading: false,
      });
    } catch (err) {
      set({ isLoading: false, error: err instanceof Error ? err.message : 'Failed to fetch prayer requests' });
    }
  },

  createRequest: async (data) => {
    try {
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.create, data);
      if (!response.success) throw new Error(response.message || 'Failed to create prayer request');
      const req = response.data;
      set(state => ({ requests: [req, ...state.requests] }));
      return req;
    } catch (err) {
      return null;
    }
  },

  prayForRequest: async (id: string) => {
    try {
      const response = await apiClient.post<{ prayed: boolean }>(endpoints.prayerRequests.pray(id));
      if (!response.success) throw new Error(response.message || 'Failed to mark as prayed');

      set(state => ({
        requests: state.requests.map(r => r.id === id
          ? {
              ...r,
              prayed_count: (r.prayed_count ?? 0) + 1,
            }
          : r
        )
      }));
      return true;
    } catch (err) {
      return false;
    }
  },

  deleteRequest: async (id: string) => {
    try {
      const response = await apiClient.delete(endpoints.prayerRequests.delete(id));
      if (!response.success) throw new Error(response.message || 'Failed to delete request');
      set(state => ({ requests: state.requests.filter(r => r.id !== id) }));
      return true;
    } catch (err) {
      return false;
    }
  },

  reset: () => set({
    requests: [],
    isLoading: false,
    error: null,
    pagination: { currentPage: 1, lastPage: 1, perPage: 20, total: 0, hasMore: false },
  }),
}));
