import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import { Note, PaginatedResponse } from '@/types';
import { apiClient, endpoints } from '@/api/client';
import { toast } from 'sonner-native';
import { appState } from '@/utils/appInitialization';

type SyncAction = 'add' | 'update' | 'delete';

interface SyncQueue {
  action: SyncAction;
  note: Note;
  timestamp: string;
}

interface NoteState {
  notes: Note[];
  isLoading: boolean;
  error: string | null;
  lastSynced: string | null;
  syncQueue: SyncQueue[];
  initialize: () => Promise<void>;
  syncNotes: () => Promise<void>;
  addNote: (data: Partial<Note>) => Promise<Note | null>;
  updateNote: (data: Partial<Note>) => Promise<Note | null>;
  deleteNote: (id: string) => Promise<boolean>;
  fetchNote: (id: string) => Promise<Note | null>;

  fetchNotes: (params?: {
    include?: string[];
    sort?: string;
    per_page?: number;
    page?: number;
  }) => Promise<void>;
  togglePin: (id: string) => Promise<boolean>;
}


const formatDate = (date: number): string => {
  return new Date(date).toISOString();
};

const localIdPrefix = 'local_';

// const isDuplicateUnsyncedNote = (notes: Note[], newNoteContent: string): boolean => {
//   return notes.some(n => n.id.startsWith(localIdPrefix) && n.text?.slice?.(0, 100) === newNoteContent.slice?.(0, 100));
// };

const STORAGE_KEY = '@notes';
const LAST_SYNCED_KEY = '@notes_last_synced';

export const useNoteStore = create<NoteState>((set, get) => ({
  notes: [],
  isLoading: false,
  error: null,
  lastSynced: null,
  syncQueue: [],

  initialize: async () => {
    try {
      set({ isLoading: true });
      // Load cached notes
      const storedNotes = await AsyncStorage.getItem(STORAGE_KEY);
      const lastSynced = await AsyncStorage.getItem(LAST_SYNCED_KEY);
      
      if (storedNotes) {
        set({ 
          notes: JSON.parse(storedNotes),
          lastSynced: lastSynced
        });
      }
    } catch (error) {
      console.error('Error initializing notes:', error);
    } finally {
      set({ isLoading: false });
    }
  },

  fetchNote: async (id) => {
    try {
      set({ isLoading: true, error: null });
      const response = await apiClient.get<{ data: Note }>(`${endpoints.notes.list}/${id}?include=virtues`);
      const note = response.data.data;
      
      // Update local state if note exists
      set(state => ({
        notes: state.notes.map(n => n.id === id ? note : n)
      }));
      
      return note;
    } catch (error: any) {
      set({ error: error.message });
      return null;
    } finally {
      set({ isLoading: false });
    }
  },

  fetchNotes: async (params) => {
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

      const response = await apiClient.get<PaginatedResponse<Note>>(`${endpoints.notes.list}?${queryParams}`);
      const notes = response.data.data;
      
      set({ notes });
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(notes));
      
    } catch (error: any) {
      set({ error: error.message });
      if (appState.isInitialized) {
        toast.error('Failed to fetch notes');
      }
    } finally {
      set({ isLoading: false });
    }
  },

  addNote: async (data) => {
    try {
      const response = await apiClient.post<{ data: Note }>(endpoints.notes.create, data);
      const newNote = response.data.data;
      
      set(state => {
        const updatedNotes = [newNote, ...state.notes];
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedNotes));
        return { notes: updatedNotes };
      });
      
      return newNote;
    } catch (error: any) {
      set({ error: error.message });
      if (appState.isInitialized) {
        toast.error('Failed to create note');
      }
      return null;
    }
  },

  updateNote: async (data) => {
    if (!data.id) return null;
    
    try {
      const response = await apiClient.put<{ data: Note }>(endpoints.notes.update(data.id), data);
      const updatedNote = response.data.data;
      
      set(state => {
        const updatedNotes = state.notes.map(note =>
          note.id === data.id ? updatedNote : note
        );
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedNotes));
        return { notes: updatedNotes };
      });
      
      return updatedNote;
    } catch (error: any) {
      set({ error: error.message });
      if (appState.isInitialized) {
        toast.error('Failed to update note');
      }
      return null;
    }
  },

  deleteNote: async (id) => {
    try {
      await apiClient.delete(endpoints.notes.delete(id));
      
      set(state => {
        const updatedNotes = state.notes.filter(note => note.id !== id);
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updatedNotes));
        return { notes: updatedNotes };
      });
      
      return true;
    } catch (error) {
      if (appState.isInitialized) {
        toast.error('Failed to delete note');
      }
      return false;
    }
  },

  syncNotes: async () => {
    // Don't attempt to sync if app isn't fully initialized
    if (!appState.isInitialized) return;
    
    try {
      set({ isLoading: true });
      
      // Get last sync timestamp
      const lastSynced = await AsyncStorage.getItem(LAST_SYNCED_KEY);
      
      // Fetch only notes updated since last sync
      const response = await apiClient.get<PaginatedResponse<Note>>(endpoints.notes.list, {
        params: {
          updated_after: lastSynced || undefined,
          include: ['virtues'],
          per_page: 100
        }
      });

      set(state => {
        // Merge new notes with existing ones, preferring server versions
        const existingNoteIds = new Set(state.notes.map(n => n.id));
        const newNotes = response.data.data;
        
        const mergedNotes = [
          ...newNotes,
          ...state.notes.filter(note => !existingNoteIds.has(note.id))
        ];

        // Update storage
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(mergedNotes));
        AsyncStorage.setItem(LAST_SYNCED_KEY, new Date().toISOString());
        
        return {
          notes: mergedNotes,
          lastSynced: new Date().toISOString()
        };
      });
    } catch (error) {
      console.error('Sync error:', error);
      if (appState.isInitialized) {
        toast.error('Failed to sync notes');
      }
    } finally {
      set({ isLoading: false });
    }
  },

  togglePin: async (id) => {
    try {
      const note = get().notes.find(n => n.id === id);
      if (!note) return false;

      const updatedNote = await get().updateNote({
        ...note,
        isPinned: !note.isPinned
      });

      return !!updatedNote;
    } catch (error) {
      if (appState.isInitialized) {
        toast.error('Failed to update pin status');
      }
      return false;
    }
  },
}));

function mergeNotes(localNotes: Note[], serverNotes: Note[]): Note[] {
  const notesMap = new Map<string, Note>();
  
  [...localNotes, ...serverNotes].forEach(note => {
    const existing = notesMap.get(note.id);
    if (!existing || new Date(existing.updated_at || Date.now()) < new Date(note.updated_at || 0)) {
      notesMap.set(note.id, note);
    }
  });
  
  return Array.from(notesMap.values());
}

// Set up network listener with initialization check
NetInfo.addEventListener(state => {
  if (state.isConnected && appState.isInitialized) {
    useNoteStore.getState().syncNotes();
  }
});