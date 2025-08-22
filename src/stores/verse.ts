//stores/verse.ts

import { create } from 'zustand';
import { apiClient, endpoints, PaginatedResponse } from '@/api/client';
import { Verse, Reflection, UserInteraction, Bookmark, PaginatedResponse as AppPaginatedResponse } from '@/types';

interface VerseState {
  // Daily verses
  dailyVerses: Verse[];
  isDailyVersesLoading: boolean;
  dailyVersesError: string | null;
  
  // Single verse
  currentVerse: Verse | null;
  isVerseLoading: boolean;
  isReflectionsLoading: boolean;
  verseError: string | null;
  
  // Trending and featured verses
  trendingVerses: Verse[];
  featuredVerses: Verse[];
  isTrendingLoading: boolean;
  isFeaturedLoading: boolean;
  
  // User interactions
  userInteractions: Map<string, UserInteraction>;
  bookmarks: Map<string, Bookmark>;
  
  // Real-time updates
  isConnected: boolean;
  lastUpdate: Date | null;
  
  // Actions
  fetchDailyVerses: () => Promise<void>;
  fetchVerseById: (id: string, includeReflections?: boolean) => Promise<Verse | null>;
  fetchVerseOnly: (id: string, includeReflections?: boolean) => Promise<Verse | null>;
  fetchTrendingVerses: (limit?: number) => Promise<void>;
  fetchFeaturedVerses: (limit?: number) => Promise<void>;
  fetchVersesByTheme: (themeId: string, limit?: number) => Promise<Verse[]>;
  searchVerses: (query: string, limit?: number) => Promise<Verse[]>;
  
  // User interactions
  createInteraction: (data: {
    interactable_id: string;
    interactable_type: string;
    type: number;
    user_id: string;
  }) => Promise<boolean>;
  createBookmark: (data: {
    bookmarkable_id: string;
    bookmarkable_type: string;
    user_id: string;
    clip_text?: string;
  }) => Promise<boolean>;
  removeBookmark: (bookmarkableId: string, bookmarkableType: string) => Promise<boolean>;
  voteVerse: (verseId: string) => Promise<boolean>;
  likeVerse: (verseId: string) => Promise<boolean>;
  shareVerse: (verseId: string) => Promise<boolean>;
  
  // Reflections
  createReflection: (data: {
    content: string;
    type: number;
    user_id: string;
    verse_id: string;
    icon?: string;
  }) => Promise<Reflection | null>;
  
  // Real-time updates
  updateVerseVotes: (verseId: string, votes: number, isVoted: boolean) => void;
  updateVerseLikes: (verseId: string, likes: number, isLiked: boolean) => void;
  updateVerseShares: (verseId: string, shares: number) => void;
  addNewVerse: (verse: Verse) => void;
  updateVerse: (verse: Verse) => void;
  
  // State management
  clearCurrentVerse: () => void;
  clearErrors: () => void;
  setConnectionStatus: (isConnected: boolean) => void;
}

// API Configuration
export const useVerseStore = create<VerseState>((set, get) => ({
  // Initial State
  dailyVerses: [],
  isDailyVersesLoading: false,
  dailyVersesError: null,
  
  currentVerse: null,
  isVerseLoading: false,
  isReflectionsLoading: false,
  verseError: null,
  
  trendingVerses: [],
  featuredVerses: [],
  isTrendingLoading: false,
  isFeaturedLoading: false,
  
  userInteractions: new Map(),
  bookmarks: new Map(),
  
  // Real-time updates
  isConnected: false,
  lastUpdate: null,
  
  // Actions
  fetchDailyVerses: async () => {
    try {
      set({ isDailyVersesLoading: true, dailyVersesError: null });
      
      const response = await apiClient.get<Verse[]>(
        endpoints.verses.daily,
        {
          include: ['theme', 'reflections.user', 'reflections.comments.user'],
          sort: '-created_at',
          per_page: 10
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch daily verses');
      }
      
      set({ 
        dailyVerses: response.data,
        isDailyVersesLoading: false 
      });

    } catch (error) {
      console.error('Error fetching daily verses:', error);
      set({ 
        isDailyVersesLoading: false,
        dailyVersesError: error instanceof Error ? error.message : 'Failed to fetch daily verses'
      });
    }
  },

  fetchVerseById: async (id: string, includeReflections = false) => {   
    let response = await get().fetchVerseOnly(id, includeReflections);
    if (response) {
      set({ 
        isVerseLoading: false,
        isReflectionsLoading: false,
        verseError: null
      });
      return response;
    } else {
      set({ 
        isVerseLoading: false,
        isReflectionsLoading: false,
        verseError: 'Failed to fetch verse'
      });
      return null;
    }
  },

  fetchVerseOnly: async (id: string, includeReflections = false) => {
    try {
      set({ isVerseLoading: true, verseError: null });
      
      const includes = ['theme'];
      if (includeReflections) {
        includes.push('reflections.user', 'reflections.comments.user');
      }
      
      const response = await apiClient.get<Verse>(
        endpoints.verses.show(id),
        {
          include: includes
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch verse');
      }
      
      set({ 
        currentVerse: response.data,
        isVerseLoading: false 
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching verse:', error);
      set({ 
        isVerseLoading: false,
        verseError: error instanceof Error ? error.message : 'Failed to fetch verse'
      });
      return null;
    }
  },

  fetchTrendingVerses: async (limit = 10) => {
    try {
      set({ isTrendingLoading: true });
      
      const response = await apiClient.get<Verse[]>(
        endpoints.verses.trending,
        {
          include: ['theme'],
          per_page: limit,
          sort: '-votes'
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch trending verses');
      }
      
      set({ 
        trendingVerses: response.data,
        isTrendingLoading: false 
      });

    } catch (error) {
      console.error('Error fetching trending verses:', error);
      set({ isTrendingLoading: false });
    }
  },

  fetchFeaturedVerses: async (limit = 10) => {
    try {
      set({ isFeaturedLoading: true });
      
      const response = await apiClient.get<Verse[]>(
        endpoints.verses.featured,
        {
          include: ['theme'],
          per_page: limit,
          sort: '-created_at'
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch featured verses');
      }
      
      set({ 
        featuredVerses: response.data,
        isFeaturedLoading: false 
      });

    } catch (error) {
      console.error('Error fetching featured verses:', error);
      set({ isFeaturedLoading: false });
    }
  },

  fetchVersesByTheme: async (themeId: string, limit = 20) => {
    try {
      const response = await apiClient.get<Verse[]>(
        endpoints.verses.byTheme(themeId),
        {
          include: ['theme'],
          per_page: limit,
          sort: '-created_at'
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch verses by theme');
      }
      
      return response.data;
    } catch (error) {
      console.error('Error fetching verses by theme:', error);
      return [];
    }
  },

  searchVerses: async (query: string, limit = 20) => {
    try {
      const response = await apiClient.get<Verse[]>(
        endpoints.verses.search,
        {
          q: query,
          include: ['theme'],
          per_page: limit,
          sort: '-created_at'
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to search verses');
      }
      
      return response.data;
    } catch (error) {
      console.error('Error searching verses:', error);
      return [];
    }
  },

  createInteraction: async (data) => {
    try {
      const response = await apiClient.post<UserInteraction>(
        endpoints.interactions.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create interaction');
      }

      // Update local state
      const interaction = response.data;
      set(state => ({
        userInteractions: new Map(state.userInteractions).set(
          `${interaction.interactable_type}_${interaction.interactable_id}`,
          interaction
        )
      }));

      return true;
    } catch (error) {
      console.error('Error creating interaction:', error);
      return false;
    }
  },

  createBookmark: async (data) => {
    try {
      const response = await apiClient.post<Bookmark>(
        endpoints.bookmarks.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create bookmark');
      }

      // Update local state
      const bookmark = response.data;
      set(state => ({
        bookmarks: new Map(state.bookmarks).set(
          `${bookmark.bookmarkable_type}_${bookmark.bookmarkable_id}`,
          bookmark
        )
      }));

      return true;
    } catch (error) {
      console.error('Error creating bookmark:', error);
      return false;
    }
  },

  removeBookmark: async (bookmarkableId: string, bookmarkableType: string) => {
    try {
      const state = get();
      const bookmarkKey = `${bookmarkableType}_${bookmarkableId}`;
      const bookmark = state.bookmarks.get(bookmarkKey);
      
      if (!bookmark) {
        return false;
      }

      const response = await apiClient.delete(
        endpoints.bookmarks.delete(bookmark.id.toString())
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to remove bookmark');
      }

      // Update local state
      set(state => {
        const newBookmarks = new Map(state.bookmarks);
        newBookmarks.delete(bookmarkKey);
        return { bookmarks: newBookmarks };
      });

      return true;
    } catch (error) {
      console.error('Error removing bookmark:', error);
      return false;
    }
  },

  voteVerse: async (verseId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.verses.vote(verseId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to vote for verse');
      }

      // Update local verse state
      set(state => {
        if (state.currentVerse?.id === verseId) {
          return {
            currentVerse: {
              ...state.currentVerse,
              votes: state.currentVerse.votes + 1,
              isVoted: true
            }
          };
        }
        return state;
      });

      return true;
    } catch (error) {
      console.error('Error voting for verse:', error);
      return false;
    }
  },

  likeVerse: async (verseId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.verses.like(verseId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to like verse');
      }

      // Update local verse state
      set(state => {
        if (state.currentVerse?.id === verseId) {
          return {
            currentVerse: {
              ...state.currentVerse,
              likes: state.currentVerse.likes + 1,
              isLiked: true
            }
          };
        }
        return state;
      });

      return true;
    } catch (error) {
      console.error('Error liking verse:', error);
      return false;
    }
  },

  shareVerse: async (verseId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.verses.share(verseId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to share verse');
      }

      // Update local verse state
      set(state => {
        if (state.currentVerse?.id === verseId) {
          return {
            currentVerse: {
              ...state.currentVerse,
              shares: state.currentVerse.shares + 1
            }
          };
        }
        return state;
      });

      return true;
    } catch (error) {
      console.error('Error sharing verse:', error);
      return false;
    }
  },

  createReflection: async (data) => {
    try {
      const response = await apiClient.post<Reflection>(
        endpoints.reflections.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create reflection');
      }

      const reflection = response.data;

      // Update local verse state with new reflection
      set(state => {
        if (state.currentVerse) {
          return {
            currentVerse: {
              ...state.currentVerse,
              reflections: [reflection, ...(state.currentVerse.reflections || [])]
            }
          };
        }
        return state;
      });

      return reflection;
    } catch (error) {
      console.error('Error creating reflection:', error);
      return null;
    }
  },

  clearCurrentVerse: () => {
    set({
      currentVerse: null,
      isVerseLoading: false,
      isReflectionsLoading: false,
      verseError: null
    });
  },

  clearErrors: () => {
    set({
      dailyVersesError: null,
      verseError: null
    });
  },

  // Real-time updates
  updateVerseVotes: (verseId: string, votes: number, isVoted: boolean) => {
    set(state => {
      const updateVerse = (verse: Verse) => {
        if (verse.id === verseId) {
          return { ...verse, votes, isVoted };
        }
        return verse;
      };

      return {
        dailyVerses: state.dailyVerses.map(updateVerse),
        trendingVerses: state.trendingVerses.map(updateVerse),
        featuredVerses: state.featuredVerses.map(updateVerse),
        currentVerse: state.currentVerse ? updateVerse(state.currentVerse) : null,
        lastUpdate: new Date(),
      };
    });
  },

  updateVerseLikes: (verseId: string, likes: number, isLiked: boolean) => {
    set(state => {
      const updateVerse = (verse: Verse) => {
        if (verse.id === verseId) {
          return { ...verse, likes, isLiked };
        }
        return verse;
      };

      return {
        dailyVerses: state.dailyVerses.map(updateVerse),
        trendingVerses: state.trendingVerses.map(updateVerse),
        featuredVerses: state.featuredVerses.map(updateVerse),
        currentVerse: state.currentVerse ? updateVerse(state.currentVerse) : null,
        lastUpdate: new Date(),
      };
    });
  },

  updateVerseShares: (verseId: string, shares: number) => {
    set(state => {
      const updateVerse = (verse: Verse) => {
        if (verse.id === verseId) {
          return { ...verse, shares };
        }
        return verse;
      };

      return {
        dailyVerses: state.dailyVerses.map(updateVerse),
        trendingVerses: state.trendingVerses.map(updateVerse),
        featuredVerses: state.featuredVerses.map(updateVerse),
        currentVerse: state.currentVerse ? updateVerse(state.currentVerse) : null,
        lastUpdate: new Date(),
      };
    });
  },

  addNewVerse: (verse: Verse) => {
    set(state => ({
      dailyVerses: [verse, ...state.dailyVerses],
      lastUpdate: new Date(),
    }));
  },

  updateVerse: (verse: Verse) => {
    set(state => {
      const updateVerseInList = (verses: Verse[]) => {
        return verses.map(v => v.id === verse.id ? verse : v);
      };

      return {
        dailyVerses: updateVerseInList(state.dailyVerses),
        trendingVerses: updateVerseInList(state.trendingVerses),
        featuredVerses: updateVerseInList(state.featuredVerses),
        currentVerse: state.currentVerse?.id === verse.id ? verse : state.currentVerse,
        lastUpdate: new Date(),
      };
    });
  },

  setConnectionStatus: (isConnected: boolean) => {
    set({ isConnected });
  },
}));