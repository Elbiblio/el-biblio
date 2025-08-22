import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { Note, User, PaginatedResponse } from '@/types';

interface NotesState {
  // Notes list
  notes: Note[];
  isNotesLoading: boolean;
  notesError: string | null;
  
  // Single note
  currentNote: Note | null;
  isNoteLoading: boolean;
  noteError: string | null;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Filters
  filters: {
    theme?: string;
    isPublic?: boolean;
    isFeatured?: boolean;
    searchQuery?: string;
    sortBy?: 'created_at' | 'updated_at' | 'title' | 'likes';
    sortOrder?: 'asc' | 'desc';
  };
  
  // Actions
  fetchNotes: (page?: number, filters?: Partial<NotesState['filters']>) => Promise<void>;
  fetchNoteById: (id: string) => Promise<Note | null>;
  createNote: (data: {
    title?: string;
    text?: string;
    theme_id?: string;
    is_public?: boolean;
    virtues?: string[];
  }) => Promise<Note | null>;
  updateNote: (id: string, data: Partial<Note>) => Promise<boolean>;
  deleteNote: (id: string) => Promise<boolean>;
  searchNotes: (query: string, limit?: number) => Promise<Note[]>;
  fetchPublicNotes: (page?: number) => Promise<void>;
  fetchFeaturedNotes: (page?: number) => Promise<void>;
  fetchNotesByUser: (userId: string, page?: number) => Promise<void>;
  fetchNotesByTheme: (themeId: string, page?: number) => Promise<void>;
  
  // Note interactions
  likeNote: (noteId: string) => Promise<boolean>;
  shareNote: (noteId: string) => Promise<boolean>;
  pinNote: (noteId: string) => Promise<boolean>;
  bookmarkNote: (noteId: string) => Promise<boolean>;
  
  // State management
  clearCurrentNote: () => void;
  clearErrors: () => void;
  setFilters: (filters: Partial<NotesState['filters']>) => void;
  resetFilters: () => void;
}

export const useNotesStore = create<NotesState>((set, get) => ({
  // Initial State
  notes: [],
  isNotesLoading: false,
  notesError: null,
  
  currentNote: null,
  isNoteLoading: false,
  noteError: null,
  
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },
  
  filters: {
    sortBy: 'created_at',
    sortOrder: 'desc',
  },
  
  // Actions
  fetchNotes: async (page = 1, filters = {}) => {
    try {
      set({ isNotesLoading: true, notesError: null });
      
      const currentFilters = { ...get().filters, ...filters };
      const sortParam = `${currentFilters.sortOrder === 'desc' ? '-' : ''}${currentFilters.sortBy}`;
      
      const params: any = {
        include: ['user', 'theme', 'comments.user'],
        sort: sortParam,
        per_page: get().pagination.perPage,
        page,
      };
      
      // Add filters
      if (currentFilters.theme) {
        params.theme_id = currentFilters.theme;
      }
      if (currentFilters.isPublic !== undefined) {
        params.is_public = currentFilters.isPublic;
      }
      if (currentFilters.isFeatured !== undefined) {
        params.is_featured = currentFilters.isFeatured;
      }
      if (currentFilters.searchQuery) {
        params.q = currentFilters.searchQuery;
      }
      
      const response = await apiClient.get<PaginatedResponse<Note>>(
        endpoints.notes.list,
        params
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch notes');
      }
      
      const { data, meta } = response.data;
      
      set({
        notes: page === 1 ? data : [...get().notes, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        filters: currentFilters,
        isNotesLoading: false,
      });

    } catch (error) {
      console.error('Error fetching notes:', error);
      set({
        isNotesLoading: false,
        notesError: error instanceof Error ? error.message : 'Failed to fetch notes',
      });
    }
  },

  fetchNoteById: async (id: string) => {
    try {
      set({ isNoteLoading: true, noteError: null });
      
      const response = await apiClient.get<Note>(
        endpoints.notes.show(id),
        {
          include: ['user', 'theme', 'comments.user', 'comments.replies.user'],
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch note');
      }
      
      set({
        currentNote: response.data,
        isNoteLoading: false,
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching note:', error);
      set({
        isNoteLoading: false,
        noteError: error instanceof Error ? error.message : 'Failed to fetch note',
      });
      return null;
    }
  },

  createNote: async (data) => {
    try {
      const response = await apiClient.post<Note>(
        endpoints.notes.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create note');
      }

      const newNote = response.data;
      
      // Add to notes list
      set(state => ({
        notes: [newNote, ...state.notes],
        currentNote: newNote,
      }));

      return newNote;
    } catch (error) {
      console.error('Error creating note:', error);
      return null;
    }
  },

  updateNote: async (id: string, data: Partial<Note>) => {
    try {
      const response = await apiClient.put<Note>(
        endpoints.notes.update(id),
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update note');
      }

      const updatedNote = response.data;
      
      // Update in notes list and current note
      set(state => ({
        notes: state.notes.map(note => 
          note.id === id ? updatedNote : note
        ),
        currentNote: state.currentNote?.id === id ? updatedNote : state.currentNote,
      }));

      return true;
    } catch (error) {
      console.error('Error updating note:', error);
      return false;
    }
  },

  deleteNote: async (id: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.notes.delete(id)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete note');
      }

      // Remove from notes list and clear current note if it's the deleted one
      set(state => ({
        notes: state.notes.filter(note => note.id !== id),
        currentNote: state.currentNote?.id === id ? null : state.currentNote,
      }));

      return true;
    } catch (error) {
      console.error('Error deleting note:', error);
      return false;
    }
  },

  searchNotes: async (query: string, limit = 20) => {
    try {
      const response = await apiClient.get<Note[]>(
        endpoints.notes.search,
        {
          q: query,
          include: ['user', 'theme'],
          per_page: limit,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to search notes');
      }
      
      return response.data;
    } catch (error) {
      console.error('Error searching notes:', error);
      return [];
    }
  },

  fetchPublicNotes: async (page = 1) => {
    try {
      set({ isNotesLoading: true, notesError: null });
      
      const response = await apiClient.get<PaginatedResponse<Note>>(
        endpoints.notes.public,
        {
          include: ['user', 'theme'],
          per_page: get().pagination.perPage,
          page,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch public notes');
      }
      
      const { data, meta } = response.data;
      
      set({
        notes: page === 1 ? data : [...get().notes, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isNotesLoading: false,
      });

    } catch (error) {
      console.error('Error fetching public notes:', error);
      set({
        isNotesLoading: false,
        notesError: error instanceof Error ? error.message : 'Failed to fetch public notes',
      });
    }
  },

  fetchFeaturedNotes: async (page = 1) => {
    try {
      set({ isNotesLoading: true, notesError: null });
      
      const response = await apiClient.get<PaginatedResponse<Note>>(
        endpoints.notes.featured,
        {
          include: ['user', 'theme'],
          per_page: get().pagination.perPage,
          page,
          sort: '-likes',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch featured notes');
      }
      
      const { data, meta } = response.data;
      
      set({
        notes: page === 1 ? data : [...get().notes, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isNotesLoading: false,
      });

    } catch (error) {
      console.error('Error fetching featured notes:', error);
      set({
        isNotesLoading: false,
        notesError: error instanceof Error ? error.message : 'Failed to fetch featured notes',
      });
    }
  },

  fetchNotesByUser: async (userId: string, page = 1) => {
    try {
      set({ isNotesLoading: true, notesError: null });
      
      const response = await apiClient.get<PaginatedResponse<Note>>(
        endpoints.notes.byUser(userId),
        {
          include: ['user', 'theme'],
          per_page: get().pagination.perPage,
          page,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch user notes');
      }
      
      const { data, meta } = response.data;
      
      set({
        notes: page === 1 ? data : [...get().notes, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isNotesLoading: false,
      });

    } catch (error) {
      console.error('Error fetching user notes:', error);
      set({
        isNotesLoading: false,
        notesError: error instanceof Error ? error.message : 'Failed to fetch user notes',
      });
    }
  },

  fetchNotesByTheme: async (themeId: string, page = 1) => {
    try {
      set({ isNotesLoading: true, notesError: null });
      
      const response = await apiClient.get<PaginatedResponse<Note>>(
        endpoints.notes.list,
        {
          include: ['user', 'theme'],
          theme_id: themeId,
          per_page: get().pagination.perPage,
          page,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch theme notes');
      }
      
      const { data, meta } = response.data;
      
      set({
        notes: page === 1 ? data : [...get().notes, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isNotesLoading: false,
      });

    } catch (error) {
      console.error('Error fetching theme notes:', error);
      set({
        isNotesLoading: false,
        notesError: error instanceof Error ? error.message : 'Failed to fetch theme notes',
      });
    }
  },

  likeNote: async (noteId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.notes.like(noteId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to like note');
      }

      // Update local state
      set(state => {
        const updateNote = (note: Note) => {
          if (note.id === noteId) {
            return {
              ...note,
              likes: (note.likes || 0) + 1,
            };
          }
          return note;
        };

        return {
          notes: state.notes.map(updateNote),
          currentNote: state.currentNote ? updateNote(state.currentNote) : null,
        };
      });

      return true;
    } catch (error) {
      console.error('Error liking note:', error);
      return false;
    }
  },

  shareNote: async (noteId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.notes.share(noteId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to share note');
      }

      // Update local state
      set(state => {
        const updateNote = (note: Note) => {
          if (note.id === noteId) {
            return {
              ...note,
              shares: (note.shares || 0) + 1,
            };
          }
          return note;
        };

        return {
          notes: state.notes.map(updateNote),
          currentNote: state.currentNote ? updateNote(state.currentNote) : null,
        };
      });

      return true;
    } catch (error) {
      console.error('Error sharing note:', error);
      return false;
    }
  },

  pinNote: async (noteId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.notes.pin(noteId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to pin note');
      }

      // Update local state
      set(state => {
        const updateNote = (note: Note) => {
          if (note.id === noteId) {
            return {
              ...note,
              isPinned: !note.isPinned,
            };
          }
          return note;
        };

        return {
          notes: state.notes.map(updateNote),
          currentNote: state.currentNote ? updateNote(state.currentNote) : null,
        };
      });

      return true;
    } catch (error) {
      console.error('Error pinning note:', error);
      return false;
    }
  },

  bookmarkNote: async (noteId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.bookmarks.create,
        {
          bookmarkable_id: noteId,
          bookmarkable_type: 'App\\Models\\Note',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to bookmark note');
      }

      return true;
    } catch (error) {
      console.error('Error bookmarking note:', error);
      return false;
    }
  },

  clearCurrentNote: () => {
    set({
      currentNote: null,
      isNoteLoading: false,
      noteError: null,
    });
  },

  clearErrors: () => {
    set({
      notesError: null,
      noteError: null,
    });
  },

  setFilters: (filters) => {
    set(state => ({
      filters: { ...state.filters, ...filters },
    }));
  },

  resetFilters: () => {
    set({
      filters: {
        sortBy: 'created_at',
        sortOrder: 'desc',
      },
    });
  },
}));