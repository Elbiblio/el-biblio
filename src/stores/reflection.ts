import { create } from 'zustand';
import { apiClient, endpoints } from '@/api/client';
import { Reflection, Comment, PaginatedResponse } from '@/types';

interface ReflectionState {
  // Reflections list
  reflections: Reflection[];
  isReflectionsLoading: boolean;
  reflectionsError: string | null;
  
  // Single reflection
  currentReflection: Reflection | null;
  isReflectionLoading: boolean;
  reflectionError: string | null;
  
  // Comments
  comments: Comment[];
  isCommentsLoading: boolean;
  commentsError: string | null;
  
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
    verseId?: string;
    userId?: string;
    type?: number;
    sortBy?: 'created_at' | 'likes' | 'comments';
    sortOrder?: 'asc' | 'desc';
  };
  
  // Actions
  fetchReflections: (page?: number, filters?: Partial<ReflectionState['filters']>) => Promise<void>;
  fetchReflectionById: (id: string) => Promise<Reflection | null>;
  fetchReflectionsByVerse: (verseId: string, page?: number) => Promise<void>;
  fetchReflectionsByUser: (userId: string, page?: number) => Promise<void>;
  fetchFeaturedReflections: (page?: number) => Promise<void>;
  
  // CRUD operations
  createReflection: (data: {
    content: string;
    type: number;
    user_id: string;
    verse_id: string;
    icon?: string;
  }) => Promise<Reflection | null>;
  updateReflection: (id: string, data: Partial<Reflection>) => Promise<boolean>;
  deleteReflection: (id: string) => Promise<boolean>;
  
  // Interactions
  likeReflection: (reflectionId: string) => Promise<boolean>;
  shareReflection: (reflectionId: string) => Promise<boolean>;
  
  // Comments
  fetchComments: (reflectionId: string, page?: number) => Promise<void>;
  createComment: (data: {
    content: string;
    user_id: string;
    reflection_id: string;
    parent_id?: string;
  }) => Promise<Comment | null>;
  updateComment: (id: string, data: Partial<Comment>) => Promise<boolean>;
  deleteComment: (id: string) => Promise<boolean>;
  likeComment: (commentId: string) => Promise<boolean>;
  
  // State management
  clearCurrentReflection: () => void;
  clearErrors: () => void;
  setFilters: (filters: Partial<ReflectionState['filters']>) => void;
  resetFilters: () => void;
}

export const useReflectionStore = create<ReflectionState>((set, get) => ({
  // Initial State
  reflections: [],
  isReflectionsLoading: false,
  reflectionsError: null,
  
  currentReflection: null,
  isReflectionLoading: false,
  reflectionError: null,
  
  comments: [],
  isCommentsLoading: false,
  commentsError: null,
  
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
  fetchReflections: async (page = 1, filters = {}) => {
    try {
      set({ isReflectionsLoading: true, reflectionsError: null });
      
      const currentFilters = { ...get().filters, ...filters };
      const sortParam = `${currentFilters.sortOrder === 'desc' ? '-' : ''}${currentFilters.sortBy}`;
      
      const params: any = {
        include: ['user', 'verse', 'comments.user'],
        sort: sortParam,
        per_page: get().pagination.perPage,
        page,
      };
      
      // Add filters
      if (currentFilters.verseId) {
        params.verse_id = currentFilters.verseId;
      }
      if (currentFilters.userId) {
        params.user_id = currentFilters.userId;
      }
      if (currentFilters.type) {
        params.type = currentFilters.type;
      }
      
      const response = await apiClient.get<PaginatedResponse<Reflection>>(
        endpoints.reflections.list,
        params
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch reflections');
      }
      
      const { data, meta } = response.data;
      
      set({
        reflections: page === 1 ? data : [...get().reflections, ...data],
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
        isReflectionsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching reflections:', error);
      set({
        isReflectionsLoading: false,
        reflectionsError: error instanceof Error ? error.message : 'Failed to fetch reflections',
      });
    }
  },

  fetchReflectionById: async (id: string) => {
    try {
      set({ isReflectionLoading: true, reflectionError: null });
      
      const response = await apiClient.get<Reflection>(
        endpoints.reflections.show(id),
        {
          include: ['user', 'verse', 'comments.user', 'comments.replies.user'],
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch reflection');
      }
      
      set({
        currentReflection: response.data,
        isReflectionLoading: false,
      });
      
      return response.data;
    } catch (error) {
      console.error('Error fetching reflection:', error);
      set({
        isReflectionLoading: false,
        reflectionError: error instanceof Error ? error.message : 'Failed to fetch reflection',
      });
      return null;
    }
  },

  fetchReflectionsByVerse: async (verseId: string, page = 1) => {
    try {
      set({ isReflectionsLoading: true, reflectionsError: null });
      
      const response = await apiClient.get<PaginatedResponse<Reflection>>(
        endpoints.reflections.byVerse(verseId),
        {
          include: ['user', 'comments.user'],
          per_page: get().pagination.perPage,
          page,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch verse reflections');
      }
      
      const { data, meta } = response.data;
      
      set({
        reflections: page === 1 ? data : [...get().reflections, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        filters: { ...get().filters, verseId },
        isReflectionsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching verse reflections:', error);
      set({
        isReflectionsLoading: false,
        reflectionsError: error instanceof Error ? error.message : 'Failed to fetch verse reflections',
      });
    }
  },

  fetchReflectionsByUser: async (userId: string, page = 1) => {
    try {
      set({ isReflectionsLoading: true, reflectionsError: null });
      
      const response = await apiClient.get<PaginatedResponse<Reflection>>(
        endpoints.reflections.byUser(userId),
        {
          include: ['user', 'verse', 'comments.user'],
          per_page: get().pagination.perPage,
          page,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch user reflections');
      }
      
      const { data, meta } = response.data;
      
      set({
        reflections: page === 1 ? data : [...get().reflections, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        filters: { ...get().filters, userId },
        isReflectionsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching user reflections:', error);
      set({
        isReflectionsLoading: false,
        reflectionsError: error instanceof Error ? error.message : 'Failed to fetch user reflections',
      });
    }
  },

  fetchFeaturedReflections: async (page = 1) => {
    try {
      set({ isReflectionsLoading: true, reflectionsError: null });
      
      const response = await apiClient.get<PaginatedResponse<Reflection>>(
        endpoints.reflections.featured,
        {
          include: ['user', 'verse', 'comments.user'],
          per_page: get().pagination.perPage,
          page,
          sort: '-likes',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch featured reflections');
      }
      
      const { data, meta } = response.data;
      
      set({
        reflections: page === 1 ? data : [...get().reflections, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isReflectionsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching featured reflections:', error);
      set({
        isReflectionsLoading: false,
        reflectionsError: error instanceof Error ? error.message : 'Failed to fetch featured reflections',
      });
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

      const newReflection = response.data;
      
      // Add to reflections list
      set(state => ({
        reflections: [newReflection, ...state.reflections],
        currentReflection: newReflection,
      }));

      return newReflection;
    } catch (error) {
      console.error('Error creating reflection:', error);
      return null;
    }
  },

  updateReflection: async (id: string, data: Partial<Reflection>) => {
    try {
      const response = await apiClient.put<Reflection>(
        endpoints.reflections.update(id),
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update reflection');
      }

      const updatedReflection = response.data;
      
      // Update in reflections list and current reflection
      set(state => ({
        reflections: state.reflections.map(reflection => 
          reflection.id === id ? updatedReflection : reflection
        ),
        currentReflection: state.currentReflection?.id === id ? updatedReflection : state.currentReflection,
      }));

      return true;
    } catch (error) {
      console.error('Error updating reflection:', error);
      return false;
    }
  },

  deleteReflection: async (id: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.reflections.delete(id)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete reflection');
      }

      // Remove from reflections list and clear current reflection if it's the deleted one
      set(state => ({
        reflections: state.reflections.filter(reflection => reflection.id !== id),
        currentReflection: state.currentReflection?.id === id ? null : state.currentReflection,
      }));

      return true;
    } catch (error) {
      console.error('Error deleting reflection:', error);
      return false;
    }
  },

  likeReflection: async (reflectionId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.reflections.like(reflectionId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to like reflection');
      }

      // Update local state
      set(state => {
        const updateReflection = (reflection: Reflection) => {
          if (reflection.id === reflectionId) {
            return {
              ...reflection,
              likes: reflection.likes + 1,
              isLiked: true,
            };
          }
          return reflection;
        };

        return {
          reflections: state.reflections.map(updateReflection),
          currentReflection: state.currentReflection ? updateReflection(state.currentReflection) : null,
        };
      });

      return true;
    } catch (error) {
      console.error('Error liking reflection:', error);
      return false;
    }
  },

  shareReflection: async (reflectionId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.reflections.share(reflectionId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to share reflection');
      }

      // Update local state
      set(state => {
        const updateReflection = (reflection: Reflection) => {
          if (reflection.id === reflectionId) {
            return {
              ...reflection,
              shares: (reflection.shares || 0) + 1,
            };
          }
          return reflection;
        };

        return {
          reflections: state.reflections.map(updateReflection),
          currentReflection: state.currentReflection ? updateReflection(state.currentReflection) : null,
        };
      });

      return true;
    } catch (error) {
      console.error('Error sharing reflection:', error);
      return false;
    }
  },

  fetchComments: async (reflectionId: string, page = 1) => {
    try {
      set({ isCommentsLoading: true, commentsError: null });
      
      const response = await apiClient.get<PaginatedResponse<Comment>>(
        endpoints.comments.byReflection(reflectionId),
        {
          include: ['user', 'replies.user'],
          per_page: 20,
          page,
          sort: '-created_at',
        }
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to fetch comments');
      }
      
      const { data, meta } = response.data;
      
      set({
        comments: page === 1 ? data : [...get().comments, ...data],
        pagination: {
          currentPage: (meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.currentPage ?? 1),
          lastPage: (meta && typeof meta.last_page === 'number') ? meta.last_page : ((meta && typeof meta.current_page === 'number') ? meta.current_page : (page ?? get().pagination.lastPage ?? 1)),
          perPage: (meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20),
          total: (meta && typeof meta.total === 'number') ? meta.total : (get().pagination.total ?? (Array.isArray(data) ? data.length : 0)),
          hasMore: (meta && typeof meta.current_page === 'number' && typeof meta.last_page === 'number')
            ? meta.current_page < meta.last_page
            : (Array.isArray(data) ? data.length >= ((meta && typeof meta.per_page === 'number') ? meta.per_page : (get().pagination.perPage ?? 20)) : false),
        },
        isCommentsLoading: false,
      });

    } catch (error) {
      console.error('Error fetching comments:', error);
      set({
        isCommentsLoading: false,
        commentsError: error instanceof Error ? error.message : 'Failed to fetch comments',
      });
    }
  },

  createComment: async (data) => {
    try {
      const response = await apiClient.post<Comment>(
        endpoints.comments.create,
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to create comment');
      }

      const newComment = response.data;
      
      // Add to comments list
      set(state => ({
        comments: [newComment, ...state.comments],
      }));

      return newComment;
    } catch (error) {
      console.error('Error creating comment:', error);
      return null;
    }
  },

  updateComment: async (id: string, data: Partial<Comment>) => {
    try {
      const response = await apiClient.put<Comment>(
        endpoints.comments.update(id),
        data
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to update comment');
      }

      const updatedComment = response.data;
      
      // Update in comments list
      set(state => ({
        comments: state.comments.map(comment => 
          comment.id === id ? updatedComment : comment
        ),
      }));

      return true;
    } catch (error) {
      console.error('Error updating comment:', error);
      return false;
    }
  },

  deleteComment: async (id: string) => {
    try {
      const response = await apiClient.delete(
        endpoints.comments.delete(id)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to delete comment');
      }

      // Remove from comments list
      set(state => ({
        comments: state.comments.filter(comment => comment.id !== id),
      }));

      return true;
    } catch (error) {
      console.error('Error deleting comment:', error);
      return false;
    }
  },

  likeComment: async (commentId: string) => {
    try {
      const response = await apiClient.post(
        endpoints.comments.like(commentId)
      );

      if (!response.success) {
        throw new Error(response.message || 'Failed to like comment');
      }

      // Update local state
      set(state => {
        const updateComment = (comment: Comment) => {
          if (comment.id === commentId) {
            return {
              ...comment,
              likes: comment.likes + 1,
              isLiked: true,
            };
          }
          return comment;
        };

        return {
          comments: state.comments.map(updateComment),
        };
      });

      return true;
    } catch (error) {
      console.error('Error liking comment:', error);
      return false;
    }
  },

  clearCurrentReflection: () => {
    set({
      currentReflection: null,
      isReflectionLoading: false,
      reflectionError: null,
    });
  },

  clearErrors: () => {
    set({
      reflectionsError: null,
      reflectionError: null,
      commentsError: null,
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