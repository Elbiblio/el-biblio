import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import NetInfo from '@react-native-community/netinfo';
import { Note } from '@/types';

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
  initialize: () => Promise<void>;
  syncNotes: () => Promise<void>;
  addNote: (note: Omit<Note, 'id' | 'updatedAt' | 'createdAt'>) => Promise<Note>;
  updateNote: (note: Note) => Promise<Note>;
  deleteNote: (noteId: string) => Promise<void>;
}

const API_URL = 'https://api.elbiblio.com/api/notes';
const SYNC_INTERVAL = 1000 * 60 * 5; // 5 minutes

const axiosInstance = axios.create({
  baseURL: API_URL,
  timeout: 10000,
});

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

      const netInfo = await NetInfo.fetch();
      if (netInfo.isConnected) {
        await get().syncNotes();
      }

      setInterval(() => {
        NetInfo.fetch().then(state => {
          if (state.isConnected) {
            get().syncNotes();
          }
        });
      }, SYNC_INTERVAL);

    } catch (error) {
      console.error('Initialization error:', error);
    } finally {
      set({ isLoading: false });
    }
  },

  syncNotes: async () => {
    const { notes, lastSync, syncQueue } = get();
    
    try {
      const { data: serverNotes } = await axiosInstance.get(`?since=${lastSync}`);
      
      for (const queueItem of syncQueue) {
        try {
          switch (queueItem.action) {
            case 'add':
              await axiosInstance.post('', queueItem.note);
              break;
            case 'update':
              await axiosInstance.put(`/${queueItem.note.id}`, queueItem.note);
              break;
            case 'delete':
              await axiosInstance.delete(`/${queueItem.note.id}`);
              break;
          }
        } catch (error) {
          console.error('Queue item sync failed:', error);
          continue;
        }
      }

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

    } catch (error) {
      console.error('Sync error:', error);
    }
  },

  addNote: async (noteData) => {
    const now = formatDate(Date.now());
    const note: Note = {
      ...noteData,
      id: `local_${Date.now()}`,
      updatedAt: now,
      createdAt: now,
      isPinned: false
    };

    try {
      const { notes, syncQueue } = get();
      const netInfo = await NetInfo.fetch();

      if (netInfo.isConnected) {
        const { data: serverNote } = await axiosInstance.post('', note);
        const updatedNotes = [...notes, serverNote];
        
        await AsyncStorage.setItem('notes', JSON.stringify(updatedNotes));
        set({ notes: updatedNotes });
        
        return serverNote;
      } else {
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
      throw error;
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
        const { data: serverNote } = await axiosInstance.put(`/${note.id}`, updatedNote);
        const updatedNotes = notes.map(n => n.id === serverNote.id ? serverNote : n);
        
        await AsyncStorage.setItem('notes', JSON.stringify(updatedNotes));
        set({ notes: updatedNotes });
        
        return serverNote;
      } else {
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
      throw error;
    }
  },

  deleteNote: async (noteId) => {
    try {
      const { notes, syncQueue } = get();
      const netInfo = await NetInfo.fetch();
      const noteToDelete = notes.find(n => n.id === noteId);

      if (!noteToDelete) return;

      if (netInfo.isConnected) {
        await axiosInstance.delete(`/${noteId}`);
        const updatedNotes = notes.filter(n => n.id !== noteId);
        
        await AsyncStorage.setItem('notes', JSON.stringify(updatedNotes));
        set({ notes: updatedNotes });
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
      }
    } catch (error) {
      console.error('Delete note error:', error);
      throw error;
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

NetInfo.addEventListener(state => {
  if (state.isConnected) {
    useNoteStore.getState().syncNotes();
  }
});