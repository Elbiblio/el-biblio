import { makeAutoObservable, runInAction } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { Note, PaginatedResponse } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';

export interface NotesState {
  notes: Note[];
  currentNote: Note | null;
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  filters: {
    theme?: string;
    isPublic?: boolean;
    isFeatured?: boolean;
    searchQuery?: string;
    sortBy?: 'created_at' | 'updated_at' | 'title' | 'likes';
    sortOrder?: 'asc' | 'desc';
  };
}

const initialState: NotesState = {
  notes: [],
  currentNote: null,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },
  filters: {
    theme: undefined,
    isPublic: undefined,
    isFeatured: undefined,
    searchQuery: '',
    sortBy: 'created_at',
    sortOrder: 'desc',
  },
};

export class NotesStore {
  state: NotesState = initialState;

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'notes_store';

  constructor() {
    this.state = initialState;
    this.storageKey = 'notes_store';
    
    makeAutoObservable(this, {}, { autoBind: true });
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading notes store from storage:', error);
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

  get notes() {
    return this.state.notes;
  }

  get currentNote() {
    return this.state.currentNote;
  }

  get pagination() {
    return this.state.pagination;
  }

  get filters() {
    return this.state.filters;
  }

  private buildQueryParams(page: number, filters: Partial<NotesState['filters']> = {}) {
    const { sortBy, sortOrder, ...restFilters } = filters;
    return {
      page,
      sort_by: sortBy,
      sort_order: sortOrder,
      ...restFilters,
    };
  }

  async fetchNotes(page = 1, filters: Partial<NotesState['filters']> = {}) {
    try {
      this.setLoading(true);
      const params = this.buildQueryParams(page, { ...this.state.filters, ...filters });
      const response = await apiClient.get<PaginatedResponse<Note>>(endpoints.notes.list, params);
      
      runInAction(() => {
        this.state.notes = page === 1 ? response.data.data : [...this.state.notes, ...response.data.data];
        this.state.pagination = {
          currentPage: page,
          lastPage: response.data.meta.last_page,
          perPage: response.data.meta.per_page,
          total: response.data.meta.total,
          hasMore: response.data.meta.current_page < response.data.meta.last_page,
        };
        this.state.filters = { ...this.state.filters, ...filters };
      });
      
      await this.saveToStorage();
    } catch (error) {
      console.error('Error fetching notes:', error);
      this.setError('Failed to fetch notes');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async fetchNoteById(id: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<Note>(endpoints.notes.show(id));
      
      runInAction(() => {
        this.state.currentNote = response.data;
        // Update in notes list if exists
        const noteIndex = this.state.notes.findIndex(n => n.id === id);
        if (noteIndex !== -1) {
          this.state.notes[noteIndex] = response.data;
        }
      });
      
      await this.saveToStorage();
      
      return response.data;
    } catch (error) {
      console.error(`Error fetching note ${id}:`, error);
      this.setError('Failed to fetch note');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async createNote(data: Omit<Note, 'id' | 'created_at' | 'updated_at'>) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<Note>(endpoints.notes.create, data);
      
      runInAction(() => {
        this.state.notes = [response.data, ...this.state.notes];
        this.state.currentNote = response.data;
      });
      
      await this.saveToStorage();
      
      return response.data;
    } catch (error) {
      console.error('Error creating note:', error);
      this.setError('Failed to create note');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async updateNote(id: string, data: Partial<Note>) {
    try {
      this.setLoading(true);
      const response = await apiClient.put<Note>(endpoints.notes.update(id), data);
      
      runInAction(() => {
        // Update in notes list
        const noteIndex = this.state.notes.findIndex(n => n.id === id);
        if (noteIndex !== -1) {
          this.state.notes[noteIndex] = { ...this.state.notes[noteIndex], ...data };
        }
        // Update current note if it's the one being updated
        if (this.state.currentNote?.id === id) {
          this.state.currentNote = { ...this.state.currentNote, ...data };
        }
      });
      
      await this.saveToStorage();
      
      return true;
    } catch (error) {
      console.error(`Error updating note ${id}:`, error);
      this.setError('Failed to update note');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async deleteNote(id: string) {
    try {
      this.setLoading(true);
      await apiClient.delete<void>(endpoints.notes.delete(id));
      
      runInAction(() => {
        this.state.notes = this.state.notes.filter(note => note.id !== id);
        if (this.state.currentNote?.id === id) {
          this.state.currentNote = null;
        }
      });
      
      await this.saveToStorage();
      
      return true;
    } catch (error) {
      console.error(`Error deleting note ${id}:`, error);
      this.setError('Failed to delete note');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async likeNote(noteId: string) {
    try {
      const response = await apiClient.post<Note>(endpoints.notes.like(noteId));
      
      runInAction(() => {
        // Update in notes list
        const noteIndex = this.state.notes.findIndex(n => n.id === noteId);
        if (noteIndex !== -1) {
          this.state.notes[noteIndex] = response.data;
        }
        // Update current note if it's the one being liked
        if (this.state.currentNote?.id === noteId) {
          this.state.currentNote = response.data;
        }
      });
      
      await this.saveToStorage();
      
      return response.data;
    } catch (error) {
      console.error(`Error liking note ${noteId}:`, error);
      throw error;
    }
  }

  async shareNote(noteId: string) {
    try {
      const response = await apiClient.post<{ share_url: string }>(endpoints.notes.share(noteId));
      return response.data.share_url;
    } catch (error) {
      console.error(`Error sharing note ${noteId}:`, error);
      throw error;
    }
  }

  

  async pinNote(noteId: string) {
    try {
      const response = await apiClient.post<Note>(endpoints.notes.pin(noteId));
      
      runInAction(() => {
        // Update in notes list
        const noteIndex = this.state.notes.findIndex(n => n.id === noteId);
        if (noteIndex !== -1) {
          this.state.notes[noteIndex] = response.data;
        }
        // Update current note if it's the one being pinned
        if (this.state.currentNote?.id === noteId) {
          this.state.currentNote = response.data;
        }
      });
      
      await this.saveToStorage();
      
      return response.data;
    } catch (error) {
      console.error(`Error pinning note ${noteId}:`, error);
      throw error;
    }
  }

  async bookmarkNote(noteId: string) {
    try {
      const response = await apiClient.post<{ is_bookmarked: boolean }>(`/notes/${noteId}/bookmark`);
      return response.data.is_bookmarked;
    } catch (error) {
      console.error(`Error bookmarking note ${noteId}:`, error);
      throw error;
    }
  }

  clearCurrentNote() {
    this.state.currentNote = null;
    this.saveToStorage();
  }

  setFilters(filters: Partial<NotesState['filters']>) {
    this.state.filters = { ...this.state.filters, ...filters };
    this.saveToStorage();
  }

  resetFilters() {
    this.state.filters = initialState.filters;
    this.saveToStorage();
  }

  // Additional methods that were in the original store
  async fetchPublicNotes(page = 1) {
    return this.fetchNotes(page, { isPublic: true });
  }

  async fetchFeaturedNotes(page = 1) {
    return this.fetchNotes(page, { isFeatured: true });
  }

  async fetchNotesByUser(userId: string, page = 1) {
    try {
      this.setLoading(true);
      const params = this.buildQueryParams(page, this.state.filters);
      const response = await apiClient.get<PaginatedResponse<Note>>(endpoints.notes.byUser(userId), params);
      runInAction(() => {
        this.state.notes = page === 1 ? response.data.data : [...this.state.notes, ...response.data.data];
        this.state.pagination = {
          currentPage: page,
          lastPage: response.data.meta.last_page,
          perPage: response.data.meta.per_page,
          total: response.data.meta.total,
          hasMore: response.data.meta.current_page < response.data.meta.last_page,
        };
      });
      
      await this.saveToStorage();
    } catch (error) {
      console.error('Error fetching notes by user:', error);
      this.setError('Failed to fetch user notes');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async searchNotes(query: string, limit = 20) {
    if (!query?.trim()) return [] as Note[];
    try {
      this.setLoading(true);
      const response = await apiClient.get<Note[]>(endpoints.notes.search, {
        q: query,
        include: ['user', 'theme'],
        per_page: limit,
        sort: '-created_at',
      });
      return response.data;
    } catch (error) {
      console.error('Error searching notes:', error);
      this.setError('Failed to search notes');
      return [] as Note[];
    } finally {
      this.setLoading(false);
    }
  }

  async fetchNotesByTheme(themeId: string, page = 1) {
    return this.fetchNotes(page, { theme: themeId });
  }
}

// Create a singleton instance
export const notesStore = new NotesStore();

// For backward compatibility
export const useNotesStore = () => notesStore;

export default notesStore;
