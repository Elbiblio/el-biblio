import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo from '@react-native-community/netinfo';
import { Note } from '@/types';
import { apiClient, endpoints } from '@/api/client';

type SyncAction = 'add' | 'update' | 'delete';

interface SyncQueue {
  action: SyncAction;
  note: Note;
  timestamp: string;
}

interface NoteState {
  notes: Note[];
  isLoading: boolean;
  lastSync: string;
  syncQueue: SyncQueue[];
  initialize: () => Promise<boolean>;
  syncNotes: () => Promise<boolean>;
  addNote: (note: Omit<Note, 'id' | 'updatedAt' | 'createdAt'>) => Promise<Note|null>;
  updateNote: (note: Note) => Promise<Note|null>;
  deleteNote: (noteId: string) => Promise<boolean>;
}

const formatDate = (date: number): string => {
  return new Date(date).toISOString();
};

export const useNoteStore = create<NoteState>((set, get) => ({
  notes: [],
  isLoading: false,
  lastSync: formatDate(0),
  syncQueue: [],

  initialize: async () => {
    try {
      set({ isLoading: true });
      console.log('Initializing note store...');
      
      // Load local data
      const localData = await AsyncStorage.multiGet([
        'notes',
        'lastSync',
        'syncQueue'
      ]);
      
      const [notesData, lastSyncData, queueData] = localData;
      const notes = notesData[1] ? JSON.parse(notesData[1]) : [];
      const lastSync = lastSyncData[1] ? lastSyncData[1] : formatDate(0);
      const syncQueue = queueData[1] ? JSON.parse(queueData[1]) : [];

      set({ notes, lastSync, syncQueue });

      return true;
    } catch (error) {
      console.error('Note store initialization error:', error);
      return false;
    } finally {
      set({ isLoading: false });
    }
  },

  syncNotes: async () => {
    const { notes, lastSync, syncQueue } = get();
    console.log('Syncing notes...');
    
    try {
      // Get updates from server
      const response = await apiClient.get<Note[]>(`${endpoints.notes.list}?since=${lastSync}`);
      
      if (!response.success) {
        console.error(response.message);
      }

      const serverNotes = response.data;
      console.log('Fetched server notes:', serverNotes.length);

      // Process sync queue
      for (const queueItem of syncQueue) {
        try {
          console.log('Processing queue item:', queueItem.action);
          
          switch (queueItem.action) {
            case 'add':
              await apiClient.post(endpoints.notes.create, queueItem.note);
              break;
            case 'update':
              await apiClient.put(endpoints.notes.update(queueItem.note.id), queueItem.note);
              break;
            case 'delete':
              await apiClient.delete(endpoints.notes.delete(queueItem.note.id));
              break;
          }
        } catch (error) {
          console.error('Queue item sync failed:', error);
          continue;
        }
      }

      // Merge and update local state
      const mergedNotes = mergeNotes(notes, serverNotes);
      const now = formatDate(Date.now());
      
      await AsyncStorage.multiSet([
        ['notes', JSON.stringify(mergedNotes)],
        ['lastSync', now],
        ['syncQueue', '[]']
      ]);

      set({
        notes: mergedNotes,
        lastSync: now,
        syncQueue: []
      });

      console.log('Sync completed successfully');
      return true;

    } catch (error) {
      console.error('Note sync error:', error);
      return false;
    }
  },

  addNote: async (noteData) => {
    try {
      const { notes, syncQueue } = get();
      const netInfo = await NetInfo.fetch();
      const now = formatDate(Date.now());

      const note: Note = {
        ...noteData,
        id: `local_${Date.now()}`,
        updatedAt: now,
        createdAt: now,
        isPinned: false
      };

      if (netInfo.isConnected) {
        const response = await apiClient.post<Note>(endpoints.notes.create, note);
        
        if (!response.success) {
          console.error(response.message);
          return null;
        }

        const serverNote = response.data;
        const updatedNotes = [...notes, serverNote];
        
        await AsyncStorage.setItem('notes', JSON.stringify(updatedNotes));
        set({ notes: updatedNotes });
        
        return serverNote;
      } else {
        // Queue for later sync
        const updatedQueue: SyncQueue[] = [...syncQueue, {
          action: 'add',
          note,
          timestamp: now
        }];
        
        const updatedNotes = [...notes, note];
        
        await AsyncStorage.multiSet([
          ['notes', JSON.stringify(updatedNotes)],
          ['syncQueue', JSON.stringify(updatedQueue)]
        ]);
        
        set({
          notes: updatedNotes,
          syncQueue: updatedQueue
        });
        
        return note;
      }
    } catch (error) {
      console.error('Add note error:', error);
      return null;
    }
  },

  updateNote: async (note) => {
    try {
      const { notes, syncQueue } = get();
      const netInfo = await NetInfo.fetch();
      const now = formatDate(Date.now());
      
      const updatedNote: Note = {
        ...note,
        updatedAt: now
      };

      if (netInfo.isConnected) {
        const response = await apiClient.put<Note>(
          endpoints.notes.update(note.id),
          updatedNote
        );
        
        if (!response.success) {
          console.error(response.message);
          return null;
        }

        const serverNote = response.data;
        const updatedNotes = notes.map(n => n.id === serverNote.id ? serverNote : n);
        
        await AsyncStorage.setItem('notes', JSON.stringify(updatedNotes));
        set({ notes: updatedNotes });
        
        return serverNote;
      } else {
        // Queue for later sync
        const updatedQueue: SyncQueue[] = [...syncQueue, {
          action: 'update',
          note: updatedNote,
          timestamp: now
        }];
        
        const updatedNotes = notes.map(n => n.id === note.id ? updatedNote : n);
        
        await AsyncStorage.multiSet([
          ['notes', JSON.stringify(updatedNotes)],
          ['syncQueue', JSON.stringify(updatedQueue)]
        ]);
        
        set({
          notes: updatedNotes,
          syncQueue: updatedQueue
        });
        
        return updatedNote;
      }
    } catch (error) {
      console.error('Update note error:', error);
      return null;
    }
  },

  deleteNote: async (noteId) : Promise<boolean> => {
    try {
      const { notes, syncQueue } = get();
      const netInfo = await NetInfo.fetch();
      const noteToDelete = notes.find(n => n.id === noteId);

      if (!noteToDelete) return false;

      if (netInfo.isConnected) {
        const response = await apiClient.delete(endpoints.notes.delete(noteId));
        
        if (!response.success) {
          console.error(response.message);
          return false;
        }

        const updatedNotes = notes.filter(n => n.id !== noteId);
        await AsyncStorage.setItem('notes', JSON.stringify(updatedNotes));
        set({ notes: updatedNotes });
        
        return true;
      } else {
        const updatedQueue: SyncQueue[] = [...syncQueue, {
          action: 'delete',
          note: noteToDelete,
          timestamp: formatDate(Date.now())
        }];
        
        const updatedNotes = notes.filter(n => n.id !== noteId);
        
        await AsyncStorage.multiSet([
          ['notes', JSON.stringify(updatedNotes)],
          ['syncQueue', JSON.stringify(updatedQueue)]
        ]);
        
        set({
          notes: updatedNotes,
          syncQueue: updatedQueue
        });
        
        return true;
      }
    } catch (error) {
      console.error('Delete note error:', error);
      return false;
    }
  }
}));

function mergeNotes(localNotes: Note[], serverNotes: Note[]): Note[] {
  const notesMap = new Map<string, Note>();
  
  [...localNotes, ...serverNotes].forEach(note => {
    const existing = notesMap.get(note.id);
    if (!existing || new Date(existing.updatedAt || Date.now()) < new Date(note.updatedAt || 0)) {
      notesMap.set(note.id, note);
    }
  });
  
  return Array.from(notesMap.values());
}

// Set up network listener
NetInfo.addEventListener(state => {
  if (state.isConnected) {
    useNoteStore.getState().syncNotes();
  }
});