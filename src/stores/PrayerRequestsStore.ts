import { makeObservable, action, runInAction } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient, endpoints } from '@/api/client';
import { PaginatedResponse, PrayerRequest } from '@/types';

interface PaginationState {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
}

interface PrayerRequestsStoreState {
  // List
  requests: PrayerRequest[];
  isLoading: boolean;
  error: string | null;

  // Pagination
  pagination: PaginationState;
}

export class PrayerRequestsStore extends BaseStore<PrayerRequestsStoreState> {
  constructor() {
    super({
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
    });

    makeObservable(this, {
      fetchRequests: action.bound,
      createRequest: action.bound,
      prayForRequest: action.bound,
      deleteRequest: action.bound,
      reset: action.bound,
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

  async fetchRequests(page = 1, params: { sort?: string; category?: string | 'all' } = {}) {
    try {
      runInAction(() => {
        this.state.isLoading = true;
        this.state.error = null;
      });

      const queryParams: any = {
        include: ['user', 'prayed_users'],
        per_page: this.state.pagination.perPage,
        page,
        sort: params.sort ?? '-created_at',
      };

      if (params.category && params.category !== 'all') {
        queryParams.category = params.category;
      }

      const response = await apiClient.get<PaginatedResponse<PrayerRequest>>(
        endpoints.prayerRequests.list,
        queryParams
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch prayer requests');

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.requests = page === 1 ? data : [...this.state.requests, ...data];
        this.state.pagination = this.computePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.isLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching prayer requests:', error);
      runInAction(() => {
        this.state.isLoading = false;
        this.state.error = error instanceof Error ? error.message : 'Failed to fetch prayer requests';
      });
      this.setError(this.state.error);
    }
  }

  async createRequest(data: { content: string; category?: string; visibility?: 'public' | 'community' | 'private' }) {
    try {
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create prayer request');

      const request = response.data;

      runInAction(() => {
        this.state.requests = [request, ...this.state.requests];
      });

      return request;
    } catch (error) {
      console.error('Error creating prayer request:', error);
      return null;
    }
  }

  async prayForRequest(id: string) {
    try {
      const response = await apiClient.post<{ prayed: boolean }>(endpoints.prayerRequests.pray(id));

      if (!response.success) throw new Error(response.message || 'Failed to mark as prayed');

      runInAction(() => {
        this.state.requests = this.state.requests.map(r => r.id === id
          ? {
              ...r,
              prayed_count: (r.prayed_count ?? 0) + 1,
            }
          : r
        );
      });

      return true;
    } catch (error) {
      console.error('Error praying for request:', error);
      return false;
    }
  }

  async deleteRequest(id: string) {
    try {
      const response = await apiClient.delete(endpoints.prayerRequests.delete(id));

      if (!response.success) throw new Error(response.message || 'Failed to delete request');

      runInAction(() => {
        this.state.requests = this.state.requests.filter(r => r.id !== id);
      });

      return true;
    } catch (error) {
      console.error('Error deleting prayer request:', error);
      return false;
    }
  }

  reset() {
    runInAction(() => {
      this.state.requests = [];
      this.state.isLoading = false;
      this.state.error = null;
      this.state.pagination = {
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
        hasMore: false,
      };
    });
    this.setError(null);
  }
}
