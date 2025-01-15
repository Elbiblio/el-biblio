import { create } from 'zustand';
import axios from 'axios';
import { Verse, Reflection, Comment, User } from '@/types';
import { APIResponse, DailyVersesResponse } from '@/types/api';

// Types for API payloads
type InteractionType = 1 | 2 | 3; // 1: like, 2: bookmark, 3: vote
type ReflectionType = 1 | 2; // 1: story, 2: insight
type InteractableType = 'App\\Models\\Reflection' | 'App\\Models\\Verse' | 'App\\Models\\Comment';

interface UserInteraction {
  interactable_id: string | number;
  interactable_type: InteractableType;
  type: InteractionType;
  user_id?: string;
}

interface ReflectionPayload {
  content: string;
  icon?: string;
  type: ReflectionType;
  user_id: string;
  verse_id: string;
}

interface CommentPayload {
  content: string;
  parent_id?: string;
  reflection_id: string;
  user_id: string;
}

interface BookmarkPayload {
  user_id: string;
  bookmarkable_type: InteractableType;
  bookmarkable_id: string;
  clip_text?: string;
}

interface VerseState {
  // Daily Verses State
  dailyVerses: Verse[];
  isDailyVersesLoading: boolean;
  dailyVersesError: string | null;
  
  // Individual Verse State
  currentVerse: Verse | null;
  isVerseLoading: boolean;
  isReflectionsLoading: boolean;
  verseError: string | null;
  
  // Actions
  fetchDailyVerses: () => Promise<void>;
  fetchVerseById: (id: string, includeReflections?: boolean) => Promise<void>;
  createInteraction: (payload: UserInteraction) => Promise<void>;
  createReflection: (payload: ReflectionPayload) => Promise<void>;
  createComment: (payload: CommentPayload) => Promise<void>;
  createBookmark: (payload: BookmarkPayload) => Promise<void>;
}

// API Configuration
const API_BASE_URL = 'https://api.elbiblio.com/api';
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

export const useVerseStore = create<VerseState>((set, get) => ({
  // Initial State
  dailyVerses: [],
  isDailyVersesLoading: false,
  dailyVersesError: null,
  
  currentVerse: null,
  isVerseLoading: false,
  isReflectionsLoading: false,
  verseError: null,
  
  // Actions
  fetchDailyVerses: async () => {
    try {
      set({ isDailyVersesLoading: true, dailyVersesError: null });
      
      // Using exact parameters as expected by VerseAPIController@daily
      const response = await api.get<DailyVersesResponse>('/verses/daily', {
        params: {
          include: 'theme,reflections.user,reflections.comments.author',
          sort: '-created_at'
        }
      });

      if (!response.data.success) {
        throw new Error(response.data.message || 'Failed to fetch daily verses');
      }
      
      set({ 
        dailyVerses: response.data.data,
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
    try {
      if (!get().currentVerse || get().currentVerse?.id !== id) {
        set({ isVerseLoading: true });
      }
      if (includeReflections) {
        set({ isReflectionsLoading: true });
      }
      set({ verseError: null });

      // Using exact parameters as expected by VerseAPIController@show
      const response = await api.get<APIResponse<Verse>>(`/verses/${id}`, {
        params: {
          include: includeReflections ? 
            'theme,reflections.user,reflections.comments.author' : 'theme'
        }
      });

      if (!response.data.success) {
        throw new Error(response.data.message || 'Failed to fetch verse');
      }
      
      set({ 
        currentVerse: response.data.data,
        isVerseLoading: false,
        isReflectionsLoading: false
      });

    } catch (error) {
      console.error('Error fetching verse:', error);
      set({ 
        isVerseLoading: false,
        isReflectionsLoading: false,
        verseError: error instanceof Error ? error.message : 'Failed to fetch verse'
      });
    }
  },

  createInteraction: async (payload: UserInteraction) => {
    try {
      const response = await api.post<APIResponse<UserInteraction>>('/user_interactions', payload);

      if (!response.data.success) {
        throw new Error(response.data.message || 'Failed to create interaction');
      }

      // Optimistic update based on interaction type
      set(state => {
        const updateVerse = (verse: Verse) => {
          if (verse.id === payload.interactable_id.toString()) {
            switch (payload.type) {
              case 1: // Like
                return {
                  ...verse,
                  isLiked: !verse.isLiked,
                  likes: verse.likes + (verse.isLiked ? -1 : 1)
                };
              case 2: // Bookmark
                return {
                  ...verse,
                  isBookmarked: !verse.isBookmarked
                };
              case 3: // Vote
                return {
                  ...verse,
                  votes: verse.votes + 1
                };
              default:
                return verse;
            }
          }
          return verse;
        };

        if (payload.interactable_type === 'App\\Models\\Verse') {
          return {
            ...state,
            dailyVerses: state.dailyVerses.map(updateVerse),
            currentVerse: state.currentVerse?.id === payload.interactable_id.toString() ? 
              updateVerse(state.currentVerse) : state.currentVerse
          };
        }

        return state;
      });

    } catch (error) {
      console.error('Error creating interaction:', error);
      // Revert optimistic update on error
      await get().fetchDailyVerses();
      const currentVerse = get().currentVerse;
      if (currentVerse) {
        await get().fetchVerseById(currentVerse.id);
      }
      throw error;
    }
  },

  createReflection: async (payload: ReflectionPayload) => {
    try {
      const response = await api.post('/reflections', payload);
      
      // Refresh verse with new reflection
      await get().fetchVerseById(payload.verse_id, true);
    } catch (error) {
      console.error('Error creating reflection:', error);
    }
  },

  createComment: async (payload: CommentPayload) => {
    try {
      const response = await api.post('/comments', payload);
      
      // Update local state with new comment
      set(state => {
        if (!state.currentVerse?.reflections) return state;
        
        return {
          currentVerse: {
            ...state.currentVerse,
            reflections: state.currentVerse.reflections.map(reflection => {
              if (reflection.id === payload.reflection_id) {
                return {
                  ...reflection,
                  comments: [
                    response.data.data,
                    ...(reflection.comments || [])
                  ]
                };
              }
              return reflection;
            })
          }
        };
      });
    } catch (error) {
      console.error('Error creating comment:', error);
    }
  },

  createBookmark: async (payload: BookmarkPayload) => {
    try {
      await api.post('/bookmarks', payload);
      
      // Create corresponding user interaction
      await get().createInteraction({
        interactable_id: payload.bookmarkable_id,
        interactable_type: payload.bookmarkable_type,
        type: 2, // Bookmark
        user_id: payload.user_id
      });
    } catch (error) {
      console.error('Error creating bookmark:', error);
    }
  },
}));