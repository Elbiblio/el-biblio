import { create } from 'zustand';
import api from '@/api/client'
import { Bookmark, PaginatedResponse } from '@/types';

interface BookmarkStore {
  bookmarks: Bookmark[];
  isLoading: boolean;
  error: string | null;
  
  // Actions
  fetchBookmarks: (params?: {
    include?: string[];
    sort?: string;
    per_page?: number;
    page?: number;
  }) => Promise<void>;
  createBookmark: (data: {
    bookmarkable_id: number;
    bookmarkable_type: string;
    user_id: number;
  }) => Promise<Bookmark | null>;
  deleteBookmark: (id: number) => Promise<boolean>;
  togglePin: (id: number) => Promise<boolean>;
}

export const useBookmarkStore = create<BookmarkStore>((set, get) => ({
  bookmarks: [],
  isLoading: false,
  error: null,

  fetchBookmarks: async (params) => {
    try {
      set({ isLoading: true, error: null });
      
      const queryParams = new URLSearchParams();
      if (params?.include) {
        queryParams.append('include', params.include.join(','));
      }
      if (params?.sort) {
        queryParams.append('sort', params.sort);
      }
      if (params?.per_page) {
        queryParams.append('per_page', params.per_page.toString());
      }
      if (params?.page) {
        queryParams.append('page', params.page.toString());
      }

      const response = await api.get<PaginatedResponse<Bookmark>>(`/bookmarks?${queryParams}`);
      set({ bookmarks: response.data.data });
    } catch (error: any) {
      set({ error: error.message });
      console.error('Error fetching bookmarks:', error);
    } finally {
      set({ isLoading: false });
    }
  },

  createBookmark: async (data) => {
    try {
      const response = await api.post<{ data: Bookmark }>('/bookmarks', data);
      const newBookmark = response.data.data;
      set(state => ({
        bookmarks: [...state.bookmarks, newBookmark]
      }));
      return newBookmark;
    } catch (error: any) {
      console.error('Error creating bookmark:', error);
      return null;
    }
  },

  deleteBookmark: async (id) => {
    try {
      await api.delete(`/bookmarks/${id}`);
      set(state => ({
        bookmarks: state.bookmarks.filter(bookmark => bookmark.id !== id)
      }));
      return true;
    } catch (error) {
      console.error('Error deleting bookmark:', error);
      return false;
    }
  },

  togglePin: async (id) => {
    try {
      const bookmark = get().bookmarks.find(b => b.id === id);
      if (!bookmark) return false;

      const response = await api.put(`/bookmarks/${id}`, {
        ...bookmark,
        is_pinned: !bookmark.is_pinned
      });

      set(state => ({
        bookmarks: state.bookmarks.map(b =>
          b.id === id ? response.data.data : b
        )
      }));
      return true;
    } catch (error) {
      console.error('Error toggling pin:', error);
      return false;
    }
  }
})); 