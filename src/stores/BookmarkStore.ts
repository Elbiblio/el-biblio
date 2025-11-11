import { makeAutoObservable, runInAction } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { Bookmark, PaginatedResponse } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface BookmarkStoreState {
  bookmarks: Bookmark[];
}

export class BookmarkStore {
  state: BookmarkStoreState = {
    bookmarks: [],
  };

  isLoading = false;
  error: string | null = null;
  private storageKey = 'bookmarks_store';

  constructor() {
    makeAutoObservable(this);
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

  get bookmarks() {
    return this.state.bookmarks;
  }

  fetchBookmarks = async (params?: {
    include?: string[];
    sort?: string;
    per_page?: number;
    page?: number;
  }) => {
    try {
      this.setLoading(true);
      this.setError(null);
      // Ensure we request necessary relations for reflections to display properly
      const mergedParams = {
        include: Array.from(new Set([...(params?.include || []), 'bookmarkable', 'bookmarkable.user', 'bookmarkable.author'])),
        sort: params?.sort,
        per_page: params?.per_page,
        page: params?.page,
      };
      const response = await apiClient.get<PaginatedResponse<Bookmark>>(endpoints.bookmarks.list, mergedParams as any);
      if (!response || !response.success || !response.data) {
        const errMsg = response?.message || 'Failed to fetch bookmarks';
        const err: any = new Error(errMsg);
        err.status = (response as any)?.status;
        err.response = response as any;
        throw err;
      }
      
      runInAction(() => {
        const rows = Array.isArray(response.data.data) ? response.data.data : [];
        // Normalize shape for UI assumptions
        const normalized = rows.map((b: any) => {
          const bb = { ...b } as Bookmark & { [k: string]: any };
          const bm = bb.bookmarkable as any;
          if (bm && !bm.author && bm.user) {
            bm.author = bm.user;
          }
          if (bm && typeof bm.type === 'string') {
            const t = bm.type;
            if (t.includes('Reflection')) bm.type = 'reflection';
            else if (t.includes('Verse')) bm.type = 'verse';
            else if (t.includes('Note')) bm.type = 'note';
            else if (t.includes('Clip')) bm.type = 'clip';
          }
          bb.bookmarkable = bm;
          return bb as Bookmark;
        });
        this.state.bookmarks = normalized;
      });
      
      await this.saveToStorage();
    } catch (error: any) {
      const status = error?.status || error?.response?.status;
      const message = error?.message;
      const details = error?.response?.data || null;
      console.error('Failed to fetch bookmarks:', { status, message, details });
      this.setError(message || 'Failed to fetch bookmarks');
      throw error;
    } finally {
      this.setLoading(false);
    }
  };

  createBookmark = async (data: {
    bookmarkable_id: number;
    bookmarkable_type: string;
    user_id: number;
  }) => {
    try {
      this.setLoading(true);
      const response = await apiClient.post<{ data: Bookmark }>(endpoints.bookmarks.create, data);
      if (!response || !response.success || !response.data) {
        const err: any = new Error(response?.message || 'Failed to create bookmark');
        err.status = (response as any)?.status; err.response = response as any; throw err;
      }
      
      runInAction(() => {
        const created = (response as any).data?.data || (response as any).data;
        this.state.bookmarks = created ? [created, ...this.state.bookmarks] : this.state.bookmarks;
      });
      
      await this.saveToStorage();
      return response.data.data;
    } catch (error: any) {
      const status = error?.status || error?.response?.status;
      const message = error?.message;
      const details = error?.response?.data || null;
      console.error('Failed to create bookmark:', { status, message, details });
      this.setError(message || 'Failed to create bookmark');
      throw error;
    } finally {
      this.setLoading(false);
    }
  };

  deleteBookmark = async (id: number) => {
    try {
      this.setLoading(true);
      await apiClient.delete(endpoints.bookmarks.delete(id.toString()));
      
      runInAction(() => {
        this.state.bookmarks = this.state.bookmarks.filter(bookmark => bookmark.id !== id);
      });
      
      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error('Failed to delete bookmark:', error);
      this.setError('Failed to delete bookmark');
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  togglePin = async (id: number) => {
    try {
      this.setLoading(true);
      const bookmark = this.state.bookmarks.find(b => b.id === id);
      if (!bookmark) {
        throw new Error('Bookmark not found');
      }
      const response = await apiClient.patch<{ data: Bookmark }>(`${endpoints.bookmarks.update(id.toString())}/toggle-pin`);
      if (!response || !response.success || !response.data) {
        const err: any = new Error(response?.message || 'Failed to toggle pin status');
        err.status = (response as any)?.status; err.response = response as any; throw err;
      }
      
      runInAction(() => {
        const index = this.state.bookmarks.findIndex(b => b.id === id);
        if (index !== -1) {
          const updated = (response as any).data?.data || (response as any).data;
          if (updated) this.state.bookmarks[index] = updated;
        }
      });
      
      await this.saveToStorage();
      return true;
    } catch (error: any) {
      const status = error?.status || error?.response?.status;
      const message = error?.message;
      const details = error?.response?.data || null;
      console.error('Failed to toggle pin:', { status, message, details });
      this.setError(message || 'Failed to toggle pin status');
      return false;
    } finally {
      this.setLoading(false);
    }
  };
}
