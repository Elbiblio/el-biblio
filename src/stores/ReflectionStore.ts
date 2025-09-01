import { makeObservable, action, runInAction, computed } from 'mobx';
import { apiClient, endpoints } from '@/api/client';
import { BaseStore } from './BaseStore';
import { Reflection, Comment, PaginatedResponse } from '@/types';

export interface ReflectionFilters {
  verseId?: string;
  userId?: string;
  type?: number;
  sortBy?: 'created_at' | 'likes' | 'comments';
  sortOrder?: 'asc' | 'desc';
}

export interface ReflectionPaginationState {
  currentPage: number;
  lastPage: number;
  perPage: number;
  total: number;
  hasMore: boolean;
}

export interface ReflectionState {
  reflections: Reflection[];
  isReflectionsLoading: boolean;
  reflectionsError: string | null;

  currentReflection: Reflection | null;
  isReflectionLoading: boolean;
  reflectionError: string | null;

  comments: Comment[];
  isCommentsLoading: boolean;
  commentsError: string | null;

  pagination: ReflectionPaginationState;
  filters: ReflectionFilters;
}

const initialState: ReflectionState = {
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
};

export class ReflectionStore extends BaseStore<ReflectionState> {
  constructor() {
    super(initialState, 'reflection_store');
    makeObservable(this, {
      fetchReflections: action,
      fetchReflectionById: action,
      fetchReflectionsByVerse: action,
      fetchReflectionsByUser: action,
      fetchFeaturedReflections: action,

      createReflection: action,
      updateReflection: action,
      deleteReflection: action,

      likeReflection: action,
      shareReflection: action,

      fetchComments: action,
      createComment: action,
      updateComment: action,
      deleteComment: action,
      likeComment: action,

      clearCurrentReflection: action,
      clearErrors: action,
      setFilters: action,
      resetFilters: action,
      comments: computed,
      isCommentsLoading: computed,
      commentsError: computed,
    });
  }

  private updatePagination(meta: any, page: number, currentCount: number) {
    return {
      currentPage: typeof meta?.current_page === 'number' ? meta.current_page : page,
      lastPage:
        typeof meta?.last_page === 'number'
          ? meta.last_page
          : typeof meta?.current_page === 'number'
          ? meta.current_page
          : page,
      perPage: typeof meta?.per_page === 'number' ? meta.per_page : this.state.pagination.perPage,
      total: typeof meta?.total === 'number' ? meta.total : this.state.pagination.total ?? currentCount,
      hasMore:
        typeof meta?.current_page === 'number' && typeof meta?.last_page === 'number'
          ? meta.current_page < meta.last_page
          : currentCount >= (typeof meta?.per_page === 'number' ? meta.per_page : this.state.pagination.perPage),
    } as ReflectionPaginationState;
  }

  async fetchReflections(page = 1, filters: Partial<ReflectionFilters> = {}) {
    try {
      runInAction(() => {
        this.state.isReflectionsLoading = true;
        this.state.reflectionsError = null;
      });

      const currentFilters = { ...this.state.filters, ...filters };
      const sortParam = `${currentFilters.sortOrder === 'desc' ? '-' : ''}${currentFilters.sortBy}`;

      const params: any = {
        include: ['user', 'verse', 'comments.user'],
        sort: sortParam,
        per_page: this.state.pagination.perPage,
        page,
      };

      if (currentFilters.verseId) params.verse_id = currentFilters.verseId;
      if (currentFilters.userId) params.user_id = currentFilters.userId;
      if (currentFilters.type) params.type = currentFilters.type;

      const response = await apiClient.get<PaginatedResponse<Reflection>>(endpoints.reflections.list, params);

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.reflections = page === 1 ? data : [...this.state.reflections, ...data];
        this.state.pagination = this.updatePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters = currentFilters;
        this.state.isReflectionsLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching reflections:', error);
      runInAction(() => {
        this.state.isReflectionsLoading = false;
        this.state.reflectionsError = error?.message || 'Failed to fetch reflections';
      });
    }
  }

  async fetchReflectionById(id: string) {
    try {
      runInAction(() => {
        this.state.isReflectionLoading = true;
        this.state.reflectionError = null;
      });

      const response = await apiClient.get<Reflection>(endpoints.reflections.show(id), {
        include: ['user', 'verse', 'comments.user', 'comments.replies.user'],
      });

      runInAction(() => {
        this.state.currentReflection = response.data;
        this.state.isReflectionLoading = false;
      });

      return response.data;
    } catch (error: any) {
      console.error('Error fetching reflection:', error);
      runInAction(() => {
        this.state.isReflectionLoading = false;
        this.state.reflectionError = error?.message || 'Failed to fetch reflection';
      });
      return null;
    }
  }

  async fetchReflectionsByVerse(verseId: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isReflectionsLoading = true;
        this.state.reflectionsError = null;
      });

      const response = await apiClient.get<PaginatedResponse<Reflection>>(endpoints.reflections.byVerse(verseId), {
        include: ['user', 'comments.user'],
        per_page: this.state.pagination.perPage,
        page,
        sort: '-created_at',
      });

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.reflections = page === 1 ? data : [...this.state.reflections, ...data];
        this.state.pagination = this.updatePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters = { ...this.state.filters, verseId };
        this.state.isReflectionsLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching verse reflections:', error);
      runInAction(() => {
        this.state.isReflectionsLoading = false;
        this.state.reflectionsError = error?.message || 'Failed to fetch verse reflections';
      });
    }
  }

  async fetchReflectionsByUser(userId: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isReflectionsLoading = true;
        this.state.reflectionsError = null;
      });

      const response = await apiClient.get<PaginatedResponse<Reflection>>(endpoints.reflections.byUser(userId), {
        include: ['user', 'verse', 'comments.user'],
        per_page: this.state.pagination.perPage,
        page,
        sort: '-created_at',
      });

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.reflections = page === 1 ? data : [...this.state.reflections, ...data];
        this.state.pagination = this.updatePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.filters = { ...this.state.filters, userId };
        this.state.isReflectionsLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching user reflections:', error);
      runInAction(() => {
        this.state.isReflectionsLoading = false;
        this.state.reflectionsError = error?.message || 'Failed to fetch user reflections';
      });
    }
  }

  async fetchFeaturedReflections(page = 1) {
    try {
      runInAction(() => {
        this.state.isReflectionsLoading = true;
        this.state.reflectionsError = null;
      });

      const response = await apiClient.get<PaginatedResponse<Reflection>>(endpoints.reflections.featured, {
        include: ['user', 'verse', 'comments.user'],
        per_page: this.state.pagination.perPage,
        page,
        sort: '-likes',
      });

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.reflections = page === 1 ? data : [...this.state.reflections, ...data];
        this.state.pagination = this.updatePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.isReflectionsLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching featured reflections:', error);
      runInAction(() => {
        this.state.isReflectionsLoading = false;
        this.state.reflectionsError = error?.message || 'Failed to fetch featured reflections';
      });
    }
  }

  async createReflection(data: { content: string; type: number; user_id: string; verse_id: string; icon?: string; }) {
    try {
      const response = await apiClient.post<Reflection>(endpoints.reflections.create, data);
      const newReflection = response.data;
      runInAction(() => {
        this.state.reflections = [newReflection, ...this.state.reflections];
        this.state.currentReflection = newReflection;
      });
      return newReflection;
    } catch (error) {
      console.error('Error creating reflection:', error);
      return null;
    }
  }

  async updateReflection(id: string, data: Partial<Reflection>) {
    try {
      const response = await apiClient.put<Reflection>(endpoints.reflections.update(id), data);
      const updated = response.data;
      runInAction(() => {
        this.state.reflections = this.state.reflections.map(r => (r.id === id ? updated : r));
        if (this.state.currentReflection?.id === id) this.state.currentReflection = updated;
      });
      return true;
    } catch (error) {
      console.error('Error updating reflection:', error);
      return false;
    }
  }

  async deleteReflection(id: string) {
    try {
      await apiClient.delete(endpoints.reflections.delete(id));
      runInAction(() => {
        this.state.reflections = this.state.reflections.filter(r => r.id !== id);
        if (this.state.currentReflection?.id === id) this.state.currentReflection = null;
      });
      return true;
    } catch (error) {
      console.error('Error deleting reflection:', error);
      return false;
    }
  }

  async likeReflection(reflectionId: string) {
    try {
      await apiClient.post(endpoints.reflections.like(reflectionId));
      runInAction(() => {
        const update = (r: Reflection) =>
          r.id === reflectionId ? { ...r, likes: r.likes + 1, isLiked: true } : r;
        this.state.reflections = this.state.reflections.map(update);
        if (this.state.currentReflection) this.state.currentReflection = update(this.state.currentReflection);
      });
      return true;
    } catch (error) {
      console.error('Error liking reflection:', error);
      return false;
    }
  }

  async shareReflection(reflectionId: string) {
    try {
      await apiClient.post(endpoints.reflections.share(reflectionId));
      runInAction(() => {
        const update = (r: Reflection) => (r.id === reflectionId ? { ...r, shares: (r.shares || 0) + 1 } : r);
        this.state.reflections = this.state.reflections.map(update);
        if (this.state.currentReflection) this.state.currentReflection = update(this.state.currentReflection);
      });
      return true;
    } catch (error) {
      console.error('Error sharing reflection:', error);
      return false;
    }
  }

  async fetchComments(reflectionId: string, page = 1) {
    try {
      runInAction(() => {
        this.state.isCommentsLoading = true;
        this.state.commentsError = null;
      });

      const response = await apiClient.get<PaginatedResponse<Comment>>(endpoints.comments.byReflection(reflectionId), {
        include: ['user', 'replies.user'],
        per_page: 20,
        page,
        sort: '-created_at',
      });

      const { data, meta } = response.data;

      runInAction(() => {
        this.state.comments = page === 1 ? data : [...this.state.comments, ...data];
        this.state.pagination = this.updatePagination(meta, page, Array.isArray(data) ? data.length : 0);
        this.state.isCommentsLoading = false;
      });
    } catch (error: any) {
      console.error('Error fetching comments:', error);
      runInAction(() => {
        this.state.isCommentsLoading = false;
        this.state.commentsError = error?.message || 'Failed to fetch comments';
      });
    }
  }

  async createComment(data: { content: string; user_id: string; reflection_id: string; parent_id?: string }) {
    try {
      const response = await apiClient.post<Comment>(endpoints.comments.create, data);
      const newComment = response.data;
      runInAction(() => {
        this.state.comments = [newComment, ...this.state.comments];
      });
      return newComment;
    } catch (error) {
      console.error('Error creating comment:', error);
      return null;
    }
  }

  async updateComment(id: string, data: Partial<Comment>) {
    try {
      const response = await apiClient.put<Comment>(endpoints.comments.update(id), data);
      const updated = response.data;
      runInAction(() => {
        this.state.comments = this.state.comments.map(c => (c.id === id ? updated : c));
      });
      return true;
    } catch (error) {
      console.error('Error updating comment:', error);
      return false;
    }
  }

  async deleteComment(id: string) {
    try {
      await apiClient.delete(endpoints.comments.delete(id));
      runInAction(() => {
        this.state.comments = this.state.comments.filter(c => c.id !== id);
      });
      return true;
    } catch (error) {
      console.error('Error deleting comment:', error);
      return false;
    }
  }

  async likeComment(commentId: string) {
    try {
      await apiClient.post(endpoints.comments.like(commentId));
      runInAction(() => {
        const update = (c: Comment) => (c.id === commentId ? { ...c, likes: c.likes + 1, isLiked: true } : c);
        this.state.comments = this.state.comments.map(update);
      });
      return true;
    } catch (error) {
      console.error('Error liking comment:', error);
      return false;
    }
  }

  clearCurrentReflection() {
    runInAction(() => {
      this.state.currentReflection = null;
      this.state.isReflectionLoading = false;
      this.state.reflectionError = null;
    });
  }

  clearErrors() {
    runInAction(() => {
      this.state.reflectionsError = null;
      this.state.reflectionError = null;
      this.state.commentsError = null;
    });
  }

  setFilters(filters: Partial<ReflectionFilters>) {
    runInAction(() => {
      this.state.filters = { ...this.state.filters, ...filters };
    });
  }

  resetFilters() {
    runInAction(() => {
      this.state.filters = { sortBy: 'created_at', sortOrder: 'desc' };
    });
  }

  get comments(): Comment[] {
    return this.state.comments;
  }

  get isCommentsLoading(): boolean {
    return this.state.isCommentsLoading;
  }

  get commentsError(): string | null {
    return this.state.commentsError;
  }
}

export const reflectionStore = new ReflectionStore();
export default reflectionStore;
