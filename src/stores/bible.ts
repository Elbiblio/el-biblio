import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { BibleVerse, Book, BibleVersion, VerseActivityMap, PaginatedResponse } from '@/types';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Clipboard } from 'react-native';
import { toast } from 'sonner-native';
import BibleDBService, { generateVPLId, parseVPLId } from '@/utils/database';
import { bibleBooks } from '@/constants/bibleBooks';

interface BibleState {
  // Current state
  currentBook: Book | null;
  currentChapter: number;
  currentVersion: BibleVersion | null;
  verses: BibleVerse[];
  searchResults: BibleVerse[];
  
  // Loading states
  isVersesLoading: boolean;
  isSearchLoading: boolean;
  isInstallingVersion: boolean;
  
  // Error states
  versesError: string | null;
  searchError: string | null;
  installError: string | null;
  
  // User interactions (stored locally)
  highlightedVerses: Set<string>;
  bookmarkedVerses: Set<string>;
  likedVerses: Set<string>;
  verseActivity: VerseActivityMap;
  
  // UI state
  fontSize: number;
  searchQuery: string;
  showSearch: boolean;
  showActivityPanel: boolean;
  selectedVerseId: string | null;
  
  // Bible versions
  installedVersions: string[];
  availableVersions: BibleVersion[];
  isVersionsLoading: boolean;
  versionsError: string | null;
  
  // Local storage keys
  localVerses: Map<string, BibleVerse[]>;
  isOffline: boolean;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
  
  // Actions
  fetchVerses: (book: Book, chapter: number, version: BibleVersion, page?: number) => Promise<void>;
  searchVerses: (query: string, version?: BibleVersion) => Promise<void>;
  fetchBibleVersions: () => Promise<void>;
  installVersion: (version: BibleVersion) => Promise<boolean>;
  
  // Verse interactions (offline-first)
  toggleHighlight: (verseId: string) => Promise<boolean>;
  toggleBookmark: (verseId: string) => Promise<boolean>;
  likeVerse: (verseId: string) => Promise<boolean>;
  shareVerse: (verseId: string) => Promise<boolean>;
  createReflection: (verseId: string, content: string, type: number) => Promise<boolean>;
  
  // Local storage
  loadUserPreferences: () => Promise<void>;
  saveUserPreferences: () => Promise<void>;
  loadLocalVerses: (version: string, book: string, chapter: number) => Promise<BibleVerse[] | null>;
  saveLocalVerses: (version: string, book: string, chapter: number, verses: BibleVerse[]) => Promise<void>;
  addToPendingSync: (action: string, data: any) => Promise<void>;
  syncUserInteractions: () => Promise<void>;
  
  // State management
  setCurrentBook: (book: Book) => void;
  setCurrentChapter: (chapter: number) => void;
  setCurrentVersion: (version: BibleVersion) => void;
  setFontSize: (size: number) => void;
  setSearchQuery: (query: string) => void;
  setShowSearch: (show: boolean) => void;
  setShowActivityPanel: (show: boolean) => void;
  setSelectedVerseId: (id: string | null) => void;
  setIsOffline: (offline: boolean) => void;
  
  // Clear state
  clearErrors: () => void;
  clearSearch: () => void;
}

// Storage keys
const STORAGE_KEYS = {
  HIGHLIGHTED_VERSES: 'bible_highlighted_verses',
  BOOKMARKED_VERSES: 'bible_bookmarked_verses',
  LIKED_VERSES: 'bible_liked_verses',
  FONT_SIZE: 'bible_font_size',
  INSTALLED_VERSIONS: 'bible_installed_versions',
  LAST_POSITION: 'bible_last_position',
  USER_PREFERENCES: 'bible_user_preferences',
  LOCAL_VERSES: 'bible_local_verses_',
  PENDING_SYNC: 'bible_pending_sync',
};

export const useBibleStore = create<BibleState>((set, get) => ({
  // Initial State
  currentBook: null,
  currentChapter: 1,
  currentVersion: null,
  verses: [],
  searchResults: [],
  isVersesLoading: false,
  isSearchLoading: false,
  isInstallingVersion: false,
  versesError: null,
  searchError: null,
  installError: null,
  highlightedVerses: new Set(),
  bookmarkedVerses: new Set(),
  likedVerses: new Set(),
  verseActivity: {},
  fontSize: 16,
  searchQuery: '',
  showSearch: false,
  showActivityPanel: false,
  selectedVerseId: null,
  installedVersions: [],
  availableVersions: [],
  isVersionsLoading: false,
  versionsError: null,
  localVerses: new Map(),
  isOffline: false,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 20,
    total: 0,
    hasMore: false,
  },

  fetchVerses: async (book: Book, chapter: number, version: BibleVersion, page = 1) => {
    try {
      set({ isVersesLoading: true, versesError: null });

      // Use BibleDBService for offline-first verse retrieval
      const versesData = await BibleDBService.getChapter(
        version.tableName,
        book.abbreviation,
        chapter
      );
      
      const versesArray = versesData.map(v => ({
        id: generateVPLId(book.abbreviation, chapter, v.verse),
        text: v.text,
        reference: `${book.name} ${chapter}:${v.verse}`
      }));

      set((state) => ({
        verses: page === 1 ? versesArray : [...state.verses, ...versesArray],
        pagination: {
          currentPage: 1,
          lastPage: 1,
          perPage: versesArray.length,
          total: versesArray.length,
          hasMore: false,
        },
      }));

      // Save current position to local storage
      await AsyncStorage.setItem(STORAGE_KEYS.LAST_POSITION, JSON.stringify({
        book: book.abbreviation,
        chapter,
        version: version.tableName,
      }));

      // Try to sync with server in background (if online)
      if (!get().isOffline) {
        try {
          await apiClient.post('/bible/position', {
            book: book.abbreviation,
            chapter,
            version: version.tableName,
          });
        } catch (error) {
          console.error('Error saving position to API:', error);
        }
      }
    } catch (error) {
      console.error('Error fetching verses:', error);
      set({ versesError: 'Failed to fetch verses' });
    } finally {
      set({ isVersesLoading: false });
    }
  },

  searchVerses: async (query: string, version?: BibleVersion) => {
    try {
      set({ isSearchLoading: true, searchError: null });

      if (!version) {
        set({ searchError: 'No version selected' });
        return;
      }

      // Use BibleDBService for offline search
      const results = await BibleDBService.searchVerses(version.tableName, query);
      
      const searchResultsArray = results.map(v => {
        const { bookAbbr, chapter, verse } = parseVPLId(v.verseID);
        const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
        return {
          id: v.verseID,
          text: v.verseText,
          reference: `${book?.name} ${chapter}:${verse}`
        };
      });

      set({ searchResults: searchResultsArray });
    } catch (error) {
      console.error('Error searching verses:', error);
      set({ searchError: 'Failed to search verses' });
    } finally {
      set({ isSearchLoading: false });
    }
  },

  fetchBibleVersions: async () => {
    try {
      set({ isVersionsLoading: true, versionsError: null });

      // Initialize BibleDBService if not already done
      await BibleDBService.initialize();

      // Get installed versions from local database
      const installed = await BibleDBService.getInstalledVersions();
      
      // Load available versions from local storage or API
      let versions: BibleVersion[];
      try {
        const versionsData = await AsyncStorage.getItem('bibleVersions');
        if (versionsData) {
          versions = JSON.parse(versionsData);
        } else {
          // Fallback to default version
          versions = [{
            englishName: "Revised Version",
            tableName: "eng_rv_vpl",
            shortName: "RV",
            downloadUrl: "https://api.elbiblio.com/dbs/rv.db",
            preinstalled: true,
            dbFilename: "rv.db"
          }];
        }
      } catch (error) {
        console.error('Error loading versions:', error);
        versions = [{
          englishName: "Revised Version",
          tableName: "eng_rv_vpl",
          shortName: "RV",
          downloadUrl: "https://api.elbiblio.com/dbs/rv.db",
          preinstalled: true,
          dbFilename: "rv.db"
        }];
      }

      set({ 
        availableVersions: versions,
        installedVersions: installed
      });
    } catch (error) {
      console.error('Error fetching Bible versions:', error);
      set({ versionsError: 'Failed to fetch Bible versions' });
    } finally {
      set({ isVersionsLoading: false });
    }
  },

  installVersion: async (version: BibleVersion) => {
    try {
      set({ isInstallingVersion: true, installError: null });

      // Use BibleDBService for installation
      await BibleDBService.installVersion(version);

      // Update installed versions list
      const installed = await BibleDBService.getInstalledVersions();
      set({ installedVersions: installed });
      
      return true;
    } catch (error) {
      console.error('Error installing version:', error);
      set({ installError: 'Failed to install version' });
      return false;
    } finally {
      set({ isInstallingVersion: false });
    }
  },

  toggleHighlight: async (verseId: string) => {
    try {
      const { highlightedVerses } = get();
      const isHighlighted = highlightedVerses.has(verseId);

      // Update local state immediately
      set((state) => {
        const newHighlighted = new Set(state.highlightedVerses);
        if (isHighlighted) {
          newHighlighted.delete(verseId);
        } else {
          newHighlighted.add(verseId);
        }
        return { highlightedVerses: newHighlighted };
      });

      // Save to local storage
      await AsyncStorage.setItem(
        STORAGE_KEYS.HIGHLIGHTED_VERSES,
        JSON.stringify(Array.from(get().highlightedVerses))
      );

      // Try to sync with server (if online)
      if (!get().isOffline) {
        try {
          const response = await apiClient.post(`/bible/verses/${verseId}/highlight`, {
            highlighted: !isHighlighted,
          });
          return response.success;
        } catch (error) {
          console.error('Error syncing highlight:', error);
          // Add to pending sync queue
          await get().addToPendingSync('highlight', { verseId, highlighted: !isHighlighted });
        }
      } else {
        // Add to pending sync queue for when back online
        await get().addToPendingSync('highlight', { verseId, highlighted: !isHighlighted });
      }
      
      return true;
    } catch (error) {
      console.error('Error toggling highlight:', error);
      return false;
    }
  },

  toggleBookmark: async (verseId: string) => {
    try {
      const { bookmarkedVerses } = get();
      const isBookmarked = bookmarkedVerses.has(verseId);

      // Update local state immediately
      set((state) => {
        const newBookmarked = new Set(state.bookmarkedVerses);
        if (isBookmarked) {
          newBookmarked.delete(verseId);
        } else {
          newBookmarked.add(verseId);
        }
        return { bookmarkedVerses: newBookmarked };
      });

      // Save to local storage
      await AsyncStorage.setItem(
        STORAGE_KEYS.BOOKMARKED_VERSES,
        JSON.stringify(Array.from(get().bookmarkedVerses))
      );

      // Try to sync with server (if online)
      if (!get().isOffline) {
        try {
          const response = await apiClient.post(`/bible/verses/${verseId}/bookmark`, {
            bookmarked: !isBookmarked,
          });
          return response.success;
        } catch (error) {
          console.error('Error syncing bookmark:', error);
          await get().addToPendingSync('bookmark', { verseId, bookmarked: !isBookmarked });
        }
      } else {
        await get().addToPendingSync('bookmark', { verseId, bookmarked: !isBookmarked });
      }
      
      return true;
    } catch (error) {
      console.error('Error toggling bookmark:', error);
      return false;
    }
  },

  likeVerse: async (verseId: string) => {
    try {
      const { likedVerses } = get();
      const isLiked = likedVerses.has(verseId);

      // Update local state immediately
      set((state) => {
        const newLiked = new Set(state.likedVerses);
        if (isLiked) {
          newLiked.delete(verseId);
        } else {
          newLiked.add(verseId);
        }
        return { likedVerses: newLiked };
      });

      // Save to local storage
      await AsyncStorage.setItem(
        STORAGE_KEYS.LIKED_VERSES,
        JSON.stringify(Array.from(get().likedVerses))
      );

      // Try to sync with server (if online)
      if (!get().isOffline) {
        try {
          const response = await apiClient.post(`/bible/verses/${verseId}/like`);
          return response.success;
        } catch (error) {
          console.error('Error syncing like:', error);
          await get().addToPendingSync('like', { verseId });
        }
      } else {
        await get().addToPendingSync('like', { verseId });
      }
      
      return true;
    } catch (error) {
      console.error('Error liking verse:', error);
      return false;
    }
  },

  shareVerse: async (verseId: string) => {
    try {
      // Find the verse in current verses or search results
      const { verses, searchResults } = get();
      const verse = [...verses, ...searchResults].find(v => v.id === verseId);
      
      if (!verse) {
        toast.error('Verse not found');
        return false;
      }

      // Format verse for sharing
      const shareText = formatVerseForSharing(verse);
      
      // Copy to clipboard
      Clipboard.setString(shareText);
      toast.success('Verse copied to clipboard!');
      
      // Track share count (if online)
      if (!get().isOffline) {
        try {
          await apiClient.post(`/bible/verses/${verseId}/share`);
        } catch (error) {
          console.error('Error tracking share:', error);
          await get().addToPendingSync('share', { verseId });
        }
      } else {
        await get().addToPendingSync('share', { verseId });
      }
      
      return true;
    } catch (error) {
      console.error('Error sharing verse:', error);
      toast.error('Failed to share verse');
      return false;
    }
  },

  createReflection: async (verseId: string, content: string, type: number) => {
    try {
      const response = await apiClient.post('/reflections', {
        verse_id: verseId,
        content,
        type,
      });
      return response.success;
    } catch (error) {
      console.error('Error creating reflection:', error);
      return false;
    }
  },

  loadLocalVerses: async (version: string, book: string, chapter: number): Promise<BibleVerse[] | null> => {
    try {
      const key = `${STORAGE_KEYS.LOCAL_VERSES}${version}_${book}_${chapter}`;
      const data = await AsyncStorage.getItem(key);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.error('Error loading local verses:', error);
      return null;
    }
  },

  saveLocalVerses: async (version: string, book: string, chapter: number, verses: BibleVerse[]) => {
    try {
      const key = `${STORAGE_KEYS.LOCAL_VERSES}${version}_${book}_${chapter}`;
      await AsyncStorage.setItem(key, JSON.stringify(verses));
    } catch (error) {
      console.error('Error saving local verses:', error);
    }
  },

  addToPendingSync: async (action: string, data: any) => {
    try {
      const pending = await AsyncStorage.getItem(STORAGE_KEYS.PENDING_SYNC);
      const pendingSync = pending ? JSON.parse(pending) : [];
      pendingSync.push({ action, data, timestamp: Date.now() });
      await AsyncStorage.setItem(STORAGE_KEYS.PENDING_SYNC, JSON.stringify(pendingSync));
    } catch (error) {
      console.error('Error adding to pending sync:', error);
    }
  },

  syncUserInteractions: async () => {
    try {
      const pending = await AsyncStorage.getItem(STORAGE_KEYS.PENDING_SYNC);
      if (!pending) return;

      const pendingSync = JSON.parse(pending) as Array<{action: string, data: any, timestamp: number}>;
      const successful: any[] = [];

      for (const item of pendingSync) {
        try {
          switch (item.action) {
            case 'highlight':
              await apiClient.post(`/bible/verses/${item.data.verseId}/highlight`, {
                highlighted: item.data.highlighted,
              });
              break;
            case 'bookmark':
              await apiClient.post(`/bible/verses/${item.data.verseId}/bookmark`, {
                bookmarked: item.data.bookmarked,
              });
              break;
            case 'like':
              await apiClient.post(`/bible/verses/${item.data.verseId}/like`);
              break;
            case 'share':
              await apiClient.post(`/bible/verses/${item.data.verseId}/share`);
              break;
          }
          successful.push(item);
        } catch (error) {
          console.error(`Error syncing ${item.action}:`, error);
        }
      }

      // Remove successful syncs
      const remaining = pendingSync.filter(item => !successful.includes(item));
      await AsyncStorage.setItem(STORAGE_KEYS.PENDING_SYNC, JSON.stringify(remaining));
    } catch (error) {
      console.error('Error syncing user interactions:', error);
    }
  },

  loadUserPreferences: async () => {
    try {
      // Load from local storage first
      const [highlightedData, bookmarkedData, likedData, fontSizeData, installedData, positionData] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEYS.HIGHLIGHTED_VERSES),
        AsyncStorage.getItem(STORAGE_KEYS.BOOKMARKED_VERSES),
        AsyncStorage.getItem(STORAGE_KEYS.LIKED_VERSES),
        AsyncStorage.getItem(STORAGE_KEYS.FONT_SIZE),
        AsyncStorage.getItem(STORAGE_KEYS.INSTALLED_VERSIONS),
        AsyncStorage.getItem(STORAGE_KEYS.LAST_POSITION),
      ]);

      set({
        highlightedVerses: new Set(highlightedData ? JSON.parse(highlightedData) : []),
        bookmarkedVerses: new Set(bookmarkedData ? JSON.parse(bookmarkedData) : []),
        likedVerses: new Set(likedData ? JSON.parse(likedData) : []),
        fontSize: fontSizeData ? JSON.parse(fontSizeData) : 16,
        installedVersions: installedData ? JSON.parse(installedData) : [],
      });

      // Restore last position if available
      if (positionData) {
        const { book, chapter, version } = JSON.parse(positionData);
        const foundBook = bibleBooks.find(b => b.abbreviation === book);
        if (foundBook) {
          set({ currentBook: foundBook, currentChapter: chapter });
        }
      }

      // Try to load from API if online
      if (!get().isOffline) {
        try {
          const response = await apiClient.get<{
            highlighted_verses: string[];
            bookmarked_verses: string[];
            font_size: number;
            installed_versions: string[];
            last_position?: {
              book: string;
              chapter: number;
              version: string;
            };
          }>('/bible/preferences');

          if (response.success && response.data) {
            const { data } = response;
            set({
              highlightedVerses: new Set(data.highlighted_verses || []),
              bookmarkedVerses: new Set(data.bookmarked_verses || []),
              fontSize: data.font_size || 16,
              installedVersions: data.installed_versions || [],
            });

            // Save updated preferences to local storage
            await get().saveUserPreferences();
          }
        } catch (error) {
          console.error('Error loading preferences from API:', error);
        }
      }
    } catch (error) {
      console.error('Error loading user preferences:', error);
    }
  },

  saveUserPreferences: async () => {
    try {
      const { highlightedVerses, bookmarkedVerses, likedVerses, fontSize, installedVersions } = get();
      
      // Save to local storage
      await Promise.all([
        AsyncStorage.setItem(STORAGE_KEYS.HIGHLIGHTED_VERSES, JSON.stringify(Array.from(highlightedVerses))),
        AsyncStorage.setItem(STORAGE_KEYS.BOOKMARKED_VERSES, JSON.stringify(Array.from(bookmarkedVerses))),
        AsyncStorage.setItem(STORAGE_KEYS.LIKED_VERSES, JSON.stringify(Array.from(likedVerses))),
        AsyncStorage.setItem(STORAGE_KEYS.FONT_SIZE, JSON.stringify(fontSize)),
        AsyncStorage.setItem(STORAGE_KEYS.INSTALLED_VERSIONS, JSON.stringify(installedVersions)),
      ]);

      // Try to save to API if online
      if (!get().isOffline) {
        try {
          await apiClient.post('/bible/preferences', {
            highlighted_verses: Array.from(highlightedVerses),
            bookmarked_verses: Array.from(bookmarkedVerses),
            font_size: fontSize,
            installed_versions: installedVersions,
          });
        } catch (error) {
          console.error('Error saving preferences to API:', error);
        }
      }
    } catch (error) {
      console.error('Error saving user preferences:', error);
    }
  },

  // State management
  setCurrentBook: (book: Book) => set({ currentBook: book }),
  setCurrentChapter: (chapter: number) => set({ currentChapter: chapter }),
  setCurrentVersion: (version: BibleVersion) => set({ currentVersion: version }),
  setFontSize: (size: number) => set({ fontSize: size }),
  setSearchQuery: (query: string) => set({ searchQuery: query }),
  setShowSearch: (show: boolean) => set({ showSearch: show }),
  setShowActivityPanel: (show: boolean) => set({ showActivityPanel: show }),
  setSelectedVerseId: (id: string | null) => set({ selectedVerseId: id }),
  setIsOffline: (offline: boolean) => set({ isOffline: offline }),

  // Clear state
  clearErrors: () => set({ versesError: null, searchError: null, installError: null }),
  clearSearch: () => set({ searchResults: [], searchQuery: '' }),
}));

// Helper function to format verse for sharing
const formatVerseForSharing = (verse: BibleVerse): string => {
  const { text, reference } = verse;
  
  return `${text}\n\n— ${reference}\n\nShared via ElBiblio SoulForge`;
}; 