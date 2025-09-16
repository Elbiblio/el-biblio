import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { PaginatedResponse, PrayerRequest } from '@/types';
import { buildPagination, initialPagination } from '@/utils/pagination';

interface PrayerRequestsStoreState {
  requests: PrayerRequest[];
  pagination: typeof initialPagination;
}

export class PrayerRequestsStore {
  state: PrayerRequestsStoreState = {
    requests: [],
    pagination: initialPagination,
  };

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'prayer_requests_store';

  constructor() {
    this.state = {
      requests: [],
      pagination: initialPagination,
    };
    this.storageKey = 'prayer_requests_store';
    
    makeAutoObservable(this);
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading prayer requests store from storage:', error);
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
      
      await this.saveToStorage();
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
      
      await this.saveToStorage();
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
      
      await this.saveToStorage();
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
      
      await this.saveToStorage();
      return true;
    } catch (err) {
      this.setError(err instanceof Error ? err.message : 'An unknown error occurred');
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  reset = async () => {
    runInAction(() => {
        this.state.requests = [];
        this.state.pagination = initialPagination;
        this.setError(null);
    });
    
    await this.saveToStorage();
  };
}
