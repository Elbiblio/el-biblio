import { makeAutoObservable, runInAction } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient, endpoints } from '@/api/client';
import { PaginatedResponse, PrayerRequest } from '@/types';
import { buildPagination, initialPagination } from '@/utils/pagination';

interface PrayerRequestsStoreState {
  requests: PrayerRequest[];
  pagination: typeof initialPagination;
}

export class PrayerRequestsStore extends BaseStore<PrayerRequestsStoreState> {
  constructor() {
    super(
      {
        requests: [],
        pagination: initialPagination,
      },
      'prayer_requests_store'
    );
    makeAutoObservable(this);
  }

  get requests(): PrayerRequest[] {
    return this.state.requests;
  }

  get pagination() {
    return this.state.pagination;
  }

  fetchRequests = async (page = 1, params: { category?: string | 'all' } = {}) => {
    this.setLoading(true);
    try {
      const response = await apiClient.get<PaginatedResponse<PrayerRequest>>(
        endpoints.prayerRequests.list,
        {
          params: {
            include: ['user'],
            per_page: this.pagination.perPage,
            page,
            sort: '-created_at',
            ...(params.category && params.category !== 'all' ? { 'filter[category]': params.category } : {}),
          }
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch prayer requests');
      }

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.requests = page === 1 ? data : [...this.state.requests, ...data];
        this.state.pagination = buildPagination(meta as any, this.pagination, page, data.length);
      });
    } catch (err) {
      this.setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      this.setLoading(false);
    }
  };

  createRequest = async (data: { content: string; category?: string; visibility?: 'public' | 'community' | 'private' }) => {
    this.setLoading(true);
    try {
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.create, data);
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to create prayer request');
      }
      const req = response.data;
      runInAction(() => {
        this.state.requests.unshift(req);
      });
      return req;
    } catch (err) {
      this.setError(err instanceof Error ? err.message : 'An unknown error occurred');
      return null;
    } finally {
      this.setLoading(false);
    }
  };

  prayForRequest = async (id: string) => {
    try {
      const response = await apiClient.post<{ prayed: boolean }>(endpoints.prayerRequests.pray(id));
      if (!response.success) {
        throw new Error(response.message || 'Failed to mark as prayed');
      }

      runInAction(() => {
        const request = this.state.requests.find(r => r.id === id);
        if (request) {
          request.prayed_count = (request.prayed_count ?? 0) + 1;
        }
      });
      return true;
    } catch (err) {
      this.setError(err instanceof Error ? err.message : 'An unknown error occurred');
      return false;
    }
  };

  deleteRequest = async (id: string) => {
    this.setLoading(true);
    try {
      const response = await apiClient.delete(endpoints.prayerRequests.delete(id));
      if (!response.success) {
        throw new Error(response.message || 'Failed to delete request');
      }
      runInAction(() => {
        this.state.requests = this.state.requests.filter(r => r.id !== id);
      });
      return true;
    } catch (err) {
      this.setError(err instanceof Error ? err.message : 'An unknown error occurred');
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  reset = () => {
    runInAction(() => {
        this.state.requests = [];
        this.state.pagination = initialPagination;
        this.setError(null);
    });
  };
}
