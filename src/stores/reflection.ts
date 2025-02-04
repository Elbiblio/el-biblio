import { create } from 'zustand';
import api from '@/api/client'
import { Reflection, PaginatedResponse } from '@/types';


interface ReflectionStore {
  reflections: Reflection[];
  currentReflection: Reflection | null;
  isLoading: boolean;
  error: string | null;

  // Actions
  fetchReflection: (id: string) => Promise<Reflection | null>;
  fetchReflections: (params?: {
    include?: string[];
    sort?: string;
    per_page?: number;
    page?: number;
  }) => Promise<void>;

  createReflection: (data: {
    content: string;
    type: 1 | 2; // 1: story, 2: insight
    user_id: number;
    verse_id: string;
  }) => Promise<Reflection | null>;
  updateReflection: (id: string, data: Partial<Reflection>) => Promise<Reflection | null>;
  deleteReflection: (id: string) => Promise<boolean>;
}


export const useReflectionStore = create<ReflectionStore>((set, get) => ({
  reflections: [],
  currentReflection: null,
  isLoading: false,
  error: null,

  fetchReflection: async (id) => {
    try {
      set({ isLoading: true, error: null });
      const response = await api.get<{ data: Reflection }>(`/reflections/${id}?include=author,verse,comments`);
      const reflection = response.data.data;
      set({ currentReflection: reflection });
      return reflection;
    } catch (error: any) {
      set({ error: error.message });
      return null;
    } finally {
      set({ isLoading: false });
    }
  },

  fetchReflections: async (params) => {
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

      const response = await api.get<PaginatedResponse<Reflection>>(`/reflections?${queryParams}`);
      set({ reflections: response.data.data });
    } catch (error: any) {
      set({ error: error.message });
    } finally {
      set({ isLoading: false });
    }
  },

  createReflection: async (data) => {
    try {
      const response = await api.post<{ data: Reflection }>('/reflections', data);
      const newReflection = response.data.data;
      set(state => ({
        reflections: [newReflection, ...state.reflections]
      }));
      return newReflection;
    } catch (error: any) {
      set({ error: error.message });
      return null;
    }
  },

  updateReflection: async (id, data) => {
    try {
      const response = await api.put<{ data: Reflection }>(`/reflections/${id}`, data);
      const updatedReflection = response.data.data;
      set(state => ({
        reflections: state.reflections.map(r =>
          r.id === id ? updatedReflection : r
        ),
        currentReflection: state.currentReflection?.id === id ? updatedReflection : state.currentReflection
      }));
      return updatedReflection;
    } catch (error: any) {
      set({ error: error.message });
      return null;
    }
  },

  deleteReflection: async (id) => {
    try {
      await api.delete(`/reflections/${id}`);
      set(state => ({
        reflections: state.reflections.filter(r => r.id !== id),
        currentReflection: state.currentReflection?.id === id ? null : state.currentReflection
      }));
      return true;
    } catch (error) {
      return false;
    }
  }
})); 