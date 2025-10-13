import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { PrayerCategory, PrayerRequest } from '@/types';
import { toast } from 'sonner-native';

interface PrayerRequestsStoreState {
  requests: PrayerRequest[];
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
}

const initialState: PrayerRequestsStoreState = {
  requests: [],
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 15,
    total: 0,
    hasMore: false,
  },
};

export class PrayerRequestsStore {
  state: PrayerRequestsStoreState = initialState;

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'prayer_requests_store';

  constructor() {
    this.state = initialState;
    this.storageKey = 'prayer_requests_store';
    
    makeAutoObservable(this, {}, { autoBind: true });
    
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
    return this.state.requests || [];
  }

  get pagination() {
    return this.state.pagination;
  }

  clearErrors() {
    this.setError(null);
  }

  fetchRequests = async (page = 1, params: { category?: string | 'all' } = {}) => {
    try {
      this.setLoading(true);
      this.setError(null);
      
      const response = await apiClient.get<any>(
        endpoints.prayerRequests.list,
        {
          include: ['user'],
          per_page: this.pagination.perPage,
          page,
          _sort_by: '-created_at',
          ...(params.category && params.category !== 'all' ? { category: params.category } : {}),
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch prayer requests');
      }
      
      runInAction(() => {
        // Backend returns { success: true, data: PrayerRequest[], message: string }
        // with Laravel pagination meta in data.meta if paginated
        const payload = response.data as any;
        const list = (payload.data ?? payload) as PrayerRequest[];
        const meta = payload.meta ?? null;
        
        this.state.requests = page === 1 ? list : [...this.state.requests, ...list];
        this.updatePagination(meta, page);
      });
      
      await this.saveToStorage();
      return this.state.requests;
    } catch (error) {
      console.error('Error fetching prayer requests:', error);
      this.setError('Failed to fetch prayer requests');
      return [];
    } finally {
      this.setLoading(false);
    }
  };

  createRequest = async (data: { content: string; category?: PrayerCategory; visibility?: 'anonymous' | 'first_name' | 'full_name' }) => {
    try {
      this.setLoading(true);
      this.setError(null);
      
      const payload = {
        detail: data.content.trim(),
        category: data.category ?? 'healing',
        visibility: data.visibility ?? 'anonymous',
      };
      
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.create, payload);
      
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to create prayer request');
      }
      
      const created = response.data as PrayerRequest;
      
      runInAction(() => {
        this.state.requests = [created, ...this.state.requests];
        this.state.pagination.total += 1;
      });
      
      await this.saveToStorage();
      toast.success('Prayer request shared');
      return created;
    } catch (error) {
      console.error('Error creating prayer request:', error);
      this.setError('Failed to create prayer request');
      return null;
    } finally {
      this.setLoading(false);
    }
  };

  prayForRequest = async (id: string) => {
    try {
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.pray(id));
      
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to mark as prayed');
      }

      runInAction(() => {
        const updated = response.data as PrayerRequest;
        const index = this.state.requests.findIndex(r => r.id === id);
        if (index !== -1) {
          this.state.requests[index] = updated;
        }
      });
      
      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error('Error marking prayer as prayed:', error);
      this.setError('Failed to mark as prayed');
      return false;
    }
  };

  deleteRequest = async (id: string) => {
    try {
      this.setLoading(true);
      this.setError(null);
      
      const response = await apiClient.delete(endpoints.prayerRequests.delete(id));
      
      if (!response.success) {
        throw new Error(response.message || 'Failed to delete request');
      }
      
      runInAction(() => {
        this.state.requests = this.state.requests.filter(r => r.id !== id);
        this.state.pagination.total = Math.max(0, this.state.pagination.total - 1);
      });
      
      await this.saveToStorage();
      toast.success('Prayer request deleted');
      return true;
    } catch (error) {
      console.error('Error deleting prayer request:', error);
      this.setError('Failed to delete request');
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  reset = async () => {
    runInAction(() => {
      this.state = initialState;
      this.setError(null);
    });
    
    await this.saveToStorage();
  };

  private updatePagination(meta: any, currentPage: number) {
    if (meta && typeof meta === 'object' &&
        (typeof meta.last_page !== 'undefined' || typeof meta.current_page !== 'undefined')) {
      const lastPage = Number(meta.last_page ?? currentPage) || currentPage;
      const perPage = Number(meta.per_page ?? this.state.pagination.perPage) || this.state.pagination.perPage;
      const total = Number(meta.total ?? this.state.pagination.total) || this.state.pagination.total;
      const current = Number(meta.current_page ?? currentPage) || currentPage;
      this.state.pagination = {
        currentPage: current,
        lastPage,
        perPage,
        total,
        hasMore: current < lastPage,
      };
      return;
    }

    // No meta provided: set hasMore to false
    this.state.pagination = {
      currentPage,
      lastPage: currentPage,
      perPage: this.state.pagination.perPage,
      total: this.state.pagination.total,
      hasMore: false,
    };
  }

  cleanup() {
    // Clean up any resources if needed
  }
}

// Create a singleton instance
export const prayerRequestsStore = new PrayerRequestsStore();

// For backward compatibility
export const usePrayerRequestsStore = () => prayerRequestsStore;

export default prayerRequestsStore;
