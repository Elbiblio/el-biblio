import { makeObservable, action, runInAction } from 'mobx';
import { BaseStore } from '@/stores/BaseStore';
import { apiClient, endpoints } from '@/api/client';
import { Verse, Reflection, UserInteraction, Bookmark } from '@/types';

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

export class VerseStore extends BaseStore<VerseStoreState> {
  constructor() {
    super({
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
    });

    makeObservable(this, {
      fetchDailyVerses: action.bound,
      fetchVerseById: action.bound,
      fetchVerseOnly: action.bound,
      fetchTrendingVerses: action.bound,
      fetchFeaturedVerses: action.bound,
      fetchVersesByTheme: action.bound,
      searchVerses: action.bound,
      createInteraction: action.bound,
      createBookmark: action.bound,
      removeBookmark: action.bound,
      voteVerse: action.bound,
      likeVerse: action.bound,
      shareVerse: action.bound,
      createReflection: action.bound,
      updateVerseVotes: action.bound,
      updateVerseLikes: action.bound,
      updateVerseShares: action.bound,
      addNewVerse: action.bound,
      updateVerse: action.bound,
      clearCurrentVerse: action.bound,
      clearErrors: action.bound,
      setConnectionStatus: action.bound,
    });
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
      });

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
      });

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
        if (this.state.currentVerse?.id === verseId) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            likes: this.state.currentVerse.likes + 1,
            isLiked: true
          };
        }
      });

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

      return true;
    } catch (error) {
      console.error('Error sharing verse:', error);
      return false;
    }
  }

  async createReflection(data: {
    content: string;
    type: number;
    user_id: string;
    verse_id: string;
    icon?: string;
  }) {
    try {
      const response = await apiClient.post<Reflection>(endpoints.reflections.create, data);

      if (!response.success) throw new Error(response.message || 'Failed to create reflection');

      const reflection = response.data;

      // Update local verse state with new reflection
      runInAction(() => {
        if (this.state.currentVerse) {
          this.state.currentVerse = {
            ...this.state.currentVerse,
            reflections: [reflection, ...(this.state.currentVerse.reflections || [])]
          };
        }
      });

      return reflection;
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
  }

  clearErrors() {
    runInAction(() => {
      this.state.dailyVersesError = null;
      this.state.verseError = null;
    });
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
  }

  addNewVerse(verse: Verse) {
    runInAction(() => {
      this.state.dailyVerses = [verse, ...this.state.dailyVerses];
      this.state.lastUpdate = new Date();
    });
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
  }

  setConnectionStatus(isConnected: boolean) {
    runInAction(() => {
      this.state.isConnected = isConnected;
    });
  }
}

// Create a singleton instance for non-React consumers (e.g., services)
// and a convenience hook-like accessor for parity with ChallengeStore
export const verseStore = new VerseStore();
export const useVerseStore = () => verseStore;
export default verseStore;
