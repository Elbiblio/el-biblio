import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { Verse, Reflection, UserInteraction, Bookmark } from '@/types';
import { engagementTracker } from '@/utils/engagementTracker';

interface VerseStoreState {
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
}

export class VerseStore {
  state: VerseStoreState = {
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

    isConnected: false,
    lastUpdate: null,
  };

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'verse_store';

  constructor() {
    this.storageKey = 'verse_store';
    makeAutoObservable(this, {}, { autoBind: true });
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (!stored) return;
      const parsed = JSON.parse(stored);

      // Revive Maps from persisted arrays/objects and merge safely
      const revivedUserInteractions = (() => {
        const raw = (parsed && parsed.userInteractions) as any;
        if (!raw) return new Map<string, UserInteraction>();
        if (Array.isArray(raw)) return new Map<string, UserInteraction>(raw);
        if (typeof raw === 'object') return new Map<string, UserInteraction>(Object.entries(raw));
        return new Map<string, UserInteraction>();
      })();

      const revivedBookmarks = (() => {
        const raw = (parsed && parsed.bookmarks) as any;
        if (!raw) return new Map<string, Bookmark>();
        if (Array.isArray(raw)) return new Map<string, Bookmark>(raw);
        if (typeof raw === 'object') return new Map<string, Bookmark>(Object.entries(raw));
        return new Map<string, Bookmark>();
      })();

      runInAction(() => {
        this.state = {
          ...this.state,
          ...parsed,
          userInteractions: revivedUserInteractions,
          bookmarks: revivedBookmarks,
        };
      });
    }).catch(error => {
      console.error('Error loading verse store from storage:', error);
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
      // Serialize Maps into arrays of entries to avoid losing data
      const payload = {
        ...this.state,
        userInteractions: Array.from(this.state.userInteractions.entries()),
        bookmarks: Array.from(this.state.bookmarks.entries()),
      };
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(payload));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }

  // --- Getters ---
  get currentVerse(): Verse | null {
    return this.state.currentVerse;
  }

  get isVerseLoading(): boolean {
    return this.state.isVerseLoading;
  }

  get isReflectionsLoading(): boolean {
    return this.state.isReflectionsLoading;
  }

  async fetchDailyVerses() {
    try {
      runInAction(() => {
        this.state.isDailyVersesLoading = true;
        this.state.dailyVersesError = null;
      });

      const response = await apiClient.get<Verse[]>(
        endpoints.verses.daily,
        {
          include: ['theme', 'reflections.user', 'reflections.comments.user'],
          sort: '-created_at',
          per_page: 10
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch daily verses');

      runInAction(() => {
        this.state.dailyVerses = response.data;
        this.state.isDailyVersesLoading = false;
      });
      
      await this.saveToStorage();
    } catch (error: any) {
      console.error('Error fetching daily verses:', error);
      runInAction(() => {
        this.state.isDailyVersesLoading = false;
        this.state.dailyVersesError = error instanceof Error ? error.message : 'Failed to fetch daily verses';
      });
      this.setError(this.state.dailyVersesError);
    }
  }

  async fetchVerseById(id: string, includeReflections = false) {
    const response = await this.fetchVerseOnly(id, includeReflections);
    if (response) {
      runInAction(() => {
        this.state.isVerseLoading = false;
        this.state.isReflectionsLoading = false;
        this.state.verseError = null;
      });
      return response;
    } else {
      runInAction(() => {
        this.state.isVerseLoading = false;
        this.state.isReflectionsLoading = false;
        this.state.verseError = 'Failed to fetch verse';
      });
      this.setError(this.state.verseError);
      return null;
    }
  }

  async fetchVerseOnly(id: string, includeReflections = false) {
    try {
      runInAction(() => {
        this.state.isVerseLoading = true;
        this.state.verseError = null;
      });

      const includes = ['theme'];
      if (includeReflections) {
        includes.push('reflections.user', 'reflections.comments.user');
      }

      const response = await apiClient.get<Verse>(
        endpoints.verses.show(id),
        { include: includes }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch verse');

      runInAction(() => {
        this.state.currentVerse = response.data;
        this.state.isVerseLoading = false;
      });
      
      await this.saveToStorage();

      return response.data;
    } catch (error: any) {
      console.error('Error fetching verse:', error);
      runInAction(() => {
        this.state.isVerseLoading = false;
        this.state.verseError = error instanceof Error ? error.message : 'Failed to fetch verse';
      });
      this.setError(this.state.verseError);
      return null;
    }
  }

  async fetchTrendingVerses(limit = 10) {
    try {
      runInAction(() => {
        this.state.isTrendingLoading = true;
      });

      const response = await apiClient.get<Verse[]>(
        endpoints.verses.trending,
        {
          include: ['theme'],
          per_page: limit,
          sort: '-votes'
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch trending verses');

      runInAction(() => {
        this.state.trendingVerses = response.data;
        this.state.isTrendingLoading = false;
      });
      
      await this.saveToStorage();
    } catch (error: any) {
      console.error('Error fetching trending verses:', error);
      runInAction(() => {
        this.state.isTrendingLoading = false;
      });
      this.setError('Failed to fetch trending verses');
    }
  }

  async fetchFeaturedVerses(limit = 10) {
    try {
      runInAction(() => {
        this.state.isFeaturedLoading = true;
      });

      const response = await apiClient.get<Verse[]>(
        endpoints.verses.featured,
        {
          include: ['theme'],
          per_page: limit,
          sort: '-created_at'
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch featured verses');

      runInAction(() => {
        this.state.featuredVerses = response.data;
        this.state.isFeaturedLoading = false;
      });
      
      await this.saveToStorage();
    } catch (error: any) {
      console.error('Error fetching featured verses:', error);
      runInAction(() => {
        this.state.isFeaturedLoading = false;
      });
      this.setError('Failed to fetch featured verses');
    }
  }

  async fetchVersesByTheme(themeId: string, limit = 20) {
    try {
      const response = await apiClient.get<Verse[]>(
        endpoints.verses.byTheme(themeId),
        {
          include: ['theme'],
          per_page: limit,
          sort: '-created_at'
        }
      );

      if (!response.success) throw new Error(response.message || 'Failed to fetch verses by theme');

      return response.data;
    } catch (error) {
      console.error('Error fetching verses by theme:', error);
      return [];
    }
  }

  async searchVerses(query: string, limit = 20) {
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

      if (!response.success) throw new Error(response.message || 'Failed to search verses');

      return response.data;
    } catch (error) {
      console.error('Error searching verses:', error);
      return [];
    }
  }

  async createInteraction(data: {
    interactable_id: string;
    interactable_type: string;
    type: number;
    user_id: string;
  }) {
    try {
      const response = await apiClient.post<UserInteraction>(endpoints.interactions.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create interaction');

      // Update local state
      const interaction = response.data;
      runInAction(() => {
        this.state.userInteractions.set(
          `${interaction.interactable_type}_${interaction.interactable_id}`,
          interaction
        );
      });
      
      await this.saveToStorage();

      return true;
    } catch (error) {
      console.error('Error creating interaction:', error);
      return false;
    }
  }

  async createBookmark(data: {
    bookmarkable_id: string;
    bookmarkable_type: string;
    user_id: string;
    clip_text?: string;
  }) {
    try {
      const response = await apiClient.post<Bookmark>(endpoints.bookmarks.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create bookmark');

      // Update local state
      const bookmark = response.data;
      runInAction(() => {
        this.state.bookmarks.set(
          `${bookmark.bookmarkable_type}_${bookmark.bookmarkable_id}`,
          bookmark
        );
        if (
          this.state.currentVerse &&
          bookmark.bookmarkable_type === 'App\\Models\\Verse' &&
          String(this.state.currentVerse.id) === String(bookmark.bookmarkable_id)
        ) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            isBookmarked: true,
          } as any;
        }
      });
      
      await this.saveToStorage();

      return true;
    } catch (error) {
      console.error('Error creating bookmark:', error);
      return false;
    }
  }

  async removeBookmark(bookmarkableId: string, bookmarkableType: string) {
    try {
      const bookmarkKey = `${bookmarkableType}_${bookmarkableId}`;
      const bookmark = this.state.bookmarks.get(bookmarkKey);

      if (!bookmark) return false;

      const response = await apiClient.delete(endpoints.bookmarks.delete(bookmark.id.toString()));

      if (!response.success) throw new Error(response.message || 'Failed to remove bookmark');

      // Update local state
      runInAction(() => {
        this.state.bookmarks.delete(bookmarkKey);
        if (
          this.state.currentVerse &&
          bookmark.bookmarkable_type === 'App\\Models\\Verse' &&
          String(this.state.currentVerse.id) === String(bookmark.bookmarkable_id)
        ) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            isBookmarked: false,
          } as any;
        }
      });
      
      await this.saveToStorage();

      return true;
    } catch (error) {
      console.error('Error removing bookmark:', error);
      return false;
    }
  }

  async voteVerse(verseId: string) {
    try {
      const response = await apiClient.post(endpoints.verses.vote(verseId));

      if (!response.success) throw new Error(response.message || 'Failed to vote for verse');

      // Update local verse state
      runInAction(() => {
        if (this.state.currentVerse?.id === verseId) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            votes: this.state.currentVerse.votes + 1,
            isVoted: true
          };
        }
      });
      
      await this.saveToStorage();

      return true;
    } catch (error) {
      console.error('Error voting for verse:', error);
      return false;
    }
  }

  async likeVerse(verseId: string) {
    try {
      const response = await apiClient.post(endpoints.verses.like(verseId));

      if (!response.success) throw new Error(response.message || 'Failed to like verse');

      // Update local verse state
      runInAction(() => {
        const updater = (v: Verse) => v.id === verseId ? { ...v, likes: v.likes + 1, isLiked: true } : v;
        this.state.dailyVerses = this.state.dailyVerses.map(updater);
        this.state.trendingVerses = this.state.trendingVerses.map(updater);
        this.state.featuredVerses = this.state.featuredVerses.map(updater);
        if (this.state.currentVerse?.id === verseId) {
          this.state.currentVerse = updater(this.state.currentVerse);
        }
        this.state.lastUpdate = new Date();
      });
      
      await this.saveToStorage();

      return true;
    } catch (error) {
      console.error('Error liking verse:', error);
      return false;
    }
  }

  async shareVerse(verseId: string) {
    try {
      const response = await apiClient.post(endpoints.verses.share(verseId));

      if (!response.success) throw new Error(response.message || 'Failed to share verse');

      // Update local verse state
      runInAction(() => {
        if (this.state.currentVerse?.id === verseId) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            shares: this.state.currentVerse.shares + 1
          };
        }
      });
      
      await this.saveToStorage();

      return true;
    } catch (error) {
      console.error('Error sharing verse:', error);
      return false;
    }
  }

  async createReflection(data: {
    title?: string | null;
    content: string;
    type: number;
    user_id: string;
    verse_id: string;
    icon?: string;
    media_url?: string | null;
    media_provider?: string | null;
    duration_seconds?: number | null;
    thumbnail_url?: string | null;
    transcript?: string | null;
    language?: string | null;
    is_published?: boolean | null;
    tags?: string[] | null;
  }) {
    try {
      const response = await apiClient.post<Reflection>(endpoints.reflections.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create reflection');

      let reflection = response.data;

      // Try to enrich the reflection with required relations (user, comments)
      try {
        if (reflection?.id) {
          const enriched = await apiClient.get<Reflection>(
            endpoints.reflections.show(reflection.id.toString()),
            { include: ['user', 'comments.user', 'verse'] }
          );
          if (enriched?.success && enriched.data) {
            reflection = enriched.data;
          }
        }
      } catch {}

      // Normalize minimal safe shape in case backend didn't include relations
      const base = { ...(reflection as any) } as Reflection & { [k: string]: any };
      const safeReflection: Reflection = {
        ...base,
        comments: Array.isArray(base.comments) ? base.comments : [],
        likes: typeof base.likes === 'number' ? base.likes : 0,
        shares: typeof base.shares === 'number' ? base.shares : 0,
        isLiked: Boolean(base.isLiked),
      } as Reflection;

      // Update local verse state with new reflection
      runInAction(() => {
        if (this.state.currentVerse) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            reflections: [safeReflection, ...(this.state.currentVerse.reflections || [])]
          };
        }
      });
      
      await this.saveToStorage();

      // Mark reflection engagement for "What you missed" flow
      void engagementTracker.record('reflection');

      return safeReflection;
    } catch (error) {
      console.error('Error creating reflection:', error);
      return null;
    }
  }

  clearCurrentVerse() {
    runInAction(() => {
      this.state.currentVerse = null;
      this.state.isVerseLoading = false;
      this.state.isReflectionsLoading = false;
      this.state.verseError = null;
    });
    
    this.saveToStorage();
  }

  clearErrors() {
    runInAction(() => {
      this.state.dailyVersesError = null;
      this.state.verseError = null;
    });
    
    this.saveToStorage();
    this.setError(null);
  }

  // Real-time updates
  updateVerseVotes(verseId: string, votes: number, isVoted: boolean) {
    runInAction(() => {
      const updateVerse = (verse: Verse) => {
        if (verse.id === verseId) {
          return { ...verse, votes, isVoted };
        }
        return verse;
      };

      this.state.dailyVerses = this.state.dailyVerses.map(updateVerse);
      this.state.trendingVerses = this.state.trendingVerses.map(updateVerse);
      this.state.featuredVerses = this.state.featuredVerses.map(updateVerse);
      this.state.currentVerse = this.state.currentVerse ? updateVerse(this.state.currentVerse) : null;
      this.state.lastUpdate = new Date();
    });
    
    this.saveToStorage();
  }

  updateVerseLikes(verseId: string, likes: number, isLiked: boolean) {
    runInAction(() => {
      const updateVerse = (verse: Verse) => {
        if (verse.id === verseId) {
          return { ...verse, likes, isLiked };
        }
        return verse;
      };

      this.state.dailyVerses = this.state.dailyVerses.map(updateVerse);
      this.state.trendingVerses = this.state.trendingVerses.map(updateVerse);
      this.state.featuredVerses = this.state.featuredVerses.map(updateVerse);
      this.state.currentVerse = this.state.currentVerse ? updateVerse(this.state.currentVerse) : null;
      this.state.lastUpdate = new Date();
    });
    
    this.saveToStorage();
  }

  updateVerseShares(verseId: string, shares: number) {
    runInAction(() => {
      const updateVerse = (verse: Verse) => {
        if (verse.id === verseId) {
          return { ...verse, shares };
        }
        return verse;
      };

      this.state.dailyVerses = this.state.dailyVerses.map(updateVerse);
      this.state.trendingVerses = this.state.trendingVerses.map(updateVerse);
      this.state.featuredVerses = this.state.featuredVerses.map(updateVerse);
      this.state.currentVerse = this.state.currentVerse ? updateVerse(this.state.currentVerse) : null;
      this.state.lastUpdate = new Date();
    });
    
    this.saveToStorage();
  }

  addNewVerse(verse: Verse) {
    runInAction(() => {
      this.state.dailyVerses = [verse, ...this.state.dailyVerses];
      this.state.lastUpdate = new Date();
    });
    
    this.saveToStorage();
  }

  updateVerse(verse: Verse) {
    runInAction(() => {
      const updateVerseInList = (verses: Verse[]) => {
        return verses.map(v => v.id === verse.id ? verse : v);
      };

      this.state.dailyVerses = updateVerseInList(this.state.dailyVerses);
      this.state.trendingVerses = updateVerseInList(this.state.trendingVerses);
      this.state.featuredVerses = updateVerseInList(this.state.featuredVerses);
      this.state.currentVerse = this.state.currentVerse?.id === verse.id ? verse : this.state.currentVerse;
      this.state.lastUpdate = new Date();
    });
    
    this.saveToStorage();
  }

  setConnectionStatus(isConnected: boolean) {
    runInAction(() => {
      this.state.isConnected = isConnected;
    });
    
    this.saveToStorage();
  }
}

// Create a singleton instance for non-React consumers (e.g., services)
// and a convenience hook-like accessor for parity with ChallengeStore
export const verseStore = new VerseStore();
export const useVerseStore = () => verseStore;
export default verseStore;
