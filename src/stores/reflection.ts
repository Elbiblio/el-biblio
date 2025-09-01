import { makeAutoObservable, runInAction } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { Reflection, Comment, PaginatedResponse } from '@/types';
import { BaseStore } from './BaseStore';
import { buildPagination, initialPagination } from '@/utils/pagination';

interface ReflectionFilters {
  verseId?: string;
  userId?: string;
  type?: number;
  sortBy?: 'created_at' | 'likes' | 'comments';
  sortOrder?: 'asc' | 'desc';
}

interface ReflectionState {
  reflections: Reflection[];
  currentReflection: Reflection | null;
  comments: Comment[];
  pagination: typeof initialPagination;
  filters: ReflectionFilters;
}

class ReflectionStore extends BaseStore<ReflectionState> {
  // Additional loading/error states for specific actions
  isCommentsLoading = false;
  commentsError: string | null = null;

  constructor() {
    super({
      reflections: [],
      currentReflection: null,
      comments: [],
      pagination: initialPagination,
      filters: {
        sortBy: 'created_at',
        sortOrder: 'desc',
      },
    });
    makeAutoObservable(this);
  }

  // --- ACTIONS ---

  fetchReflections = async (page = 1, filters: Partial<ReflectionFilters> = {}) => {
    this.setLoading(true);
    const currentFilters = { ...this.state.filters, ...filters };

    try {
      const sortParam = `${currentFilters.sortOrder === 'desc' ? '-' : ''}${currentFilters.sortBy}`;
      const params = {
        include: ['user', 'verse', 'comments.user'],
        sort: sortParam,
        per_page: this.state.pagination.perPage,
        page,
        ...currentFilters,
      };

      const response = await apiClient.get<PaginatedResponse<Reflection>>(endpoints.reflections.list, params);
      if (!response.success || !response.data) throw new Error(response.message || 'Failed to fetch reflections');

      const { data, meta } = response.data;
      runInAction(() => {
        this.state.reflections = page === 1 ? data : [...this.state.reflections, ...data];
        this.state.pagination = buildPagination(meta, this.state.pagination, page, data.length);
        this.state.filters = currentFilters;
      });
    } catch (error: any) {
      this.setError(error.message);
    } finally {
      this.setLoading(false);
    }
  };

  fetchReflectionById = async (id: string) => {
    this.setLoading(true);
    try {
      const response = await apiClient.get<Reflection>(endpoints.reflections.show(id), {
        include: ['user', 'verse', 'comments.user', 'comments.replies.user'],
      });
      if (!response.success || !response.data) throw new Error(response.message || 'Failed to fetch reflection');

      runInAction(() => {
        this.state.currentReflection = response.data;
      });
      return response.data;
    } catch (error: any) {
      this.setError(error.message);
      return null;
    } finally {
      this.setLoading(false);
    }
  };

  createReflection = async (data: { content: string; type: number; user_id: string; verse_id: string; icon?: string }) => {
    this.setLoading(true);
    try {
      const response = await apiClient.post<Reflection>(endpoints.reflections.create, data);
      if (!response.success || !response.data) throw new Error(response.message || 'Failed to create reflection');

      const newReflection = response.data;
      runInAction(() => {
        this.state.reflections.unshift(newReflection);
        this.state.currentReflection = newReflection;
      });
      return newReflection;
    } catch (error: any) {
      this.setError(error.message);
      return null;
    } finally {
      this.setLoading(false);
    }
  };

  likeReflection = async (reflectionId: string) => {
    try {
      const response = await apiClient.post(endpoints.reflections.like(reflectionId));
      if (!response.success) throw new Error(response.message || 'Failed to like reflection');

      runInAction(() => {
        const update = (r: Reflection) => r.id === reflectionId ? { ...r, likes: r.likes + 1, isLiked: true } : r;
        this.state.reflections = this.state.reflections.map(update);
        if (this.state.currentReflection?.id === reflectionId) {
          this.state.currentReflection = update(this.state.currentReflection);
        }
      });
      return true;
    } catch (error: any) {
      this.setError(error.message);
      return false;
    }
  };

  // --- COMMENTS ---

  fetchComments = async (reflectionId: string, page = 1) => {
    runInAction(() => {
      this.isCommentsLoading = true;
      this.commentsError = null;
    });
    try {
      const response = await apiClient.get<PaginatedResponse<Comment>>(endpoints.comments.byReflection(reflectionId), {
        include: ['user', 'replies.user'],
        per_page: 20,
        page,
        sort: '-created_at',
      });
      if (!response.success || !response.data) throw new Error(response.message || 'Failed to fetch comments');

      const { data, meta } = response.data;
      runInAction(() => {
        this.state.comments = page === 1 ? data : [...this.state.comments, ...data];
        // Note: This pagination is for comments, separate from reflections pagination
      });
    } catch (error: any) {
      runInAction(() => {
        this.commentsError = error.message;
      });
    } finally {
      runInAction(() => {
        this.isCommentsLoading = false;
      });
    }
  };

  createComment = async (data: { content: string; user_id: string; reflection_id: string; parent_id?: string }) => {
    try {
      const response = await apiClient.post<Comment>(endpoints.comments.create, data);
      if (!response.success || !response.data) throw new Error(response.message || 'Failed to create comment');

      const newComment = response.data;
      runInAction(() => {
        this.state.comments.unshift(newComment);
      });
      return newComment;
    } catch (error: any) {
      runInAction(() => {
        this.commentsError = error.message;
      });
      return null;
    }
  };

  likeComment = async (commentId: string) => {
    try {
      const response = await apiClient.post(endpoints.comments.like(commentId));
      if (!response.success) throw new Error(response.message || 'Failed to like comment');

      runInAction(() => {
        const update = (c: Comment): Comment => {
          if (c.id === commentId) return { ...c, likes: c.likes + 1, isLiked: true };
          if (c.replies) return { ...c, replies: c.replies.map(update) };
          return c;
        };
        this.state.comments = this.state.comments.map(update);
      });
      return true;
    } catch (error: any) {
      runInAction(() => {
        this.commentsError = error.message;
      });
      return false;
    }
  };

  // --- STATE MANAGEMENT ---

  clearCurrentReflection = () => {
    runInAction(() => {
      this.state.currentReflection = null;
      this.error = null;
    });
  };

  clearErrors = () => {
    this.setError(null);
    runInAction(() => {
      this.commentsError = null;
    });
  };

  setFilters = (filters: Partial<ReflectionFilters>) => {
    runInAction(() => {
      this.state.filters = { ...this.state.filters, ...filters };
    });
  };

  resetFilters = () => {
    runInAction(() => {
      this.state.filters = {
        sortBy: 'created_at',
        sortOrder: 'desc',
      };
    });
  };
}

export const reflectionStore = new ReflectionStore();
export const useReflectionStore = () => reflectionStore;
export default reflectionStore;
 