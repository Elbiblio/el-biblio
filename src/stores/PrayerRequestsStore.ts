import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { PrayerCategory, PrayerRequest, PrayerRequestComment } from '@/types';
import { toast } from 'sonner-native';

interface PrayerRequestsStoreState {
  requests: PrayerRequest[];
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
}

const initialState: PrayerRequestsStoreState = {
  requests: [],
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 15,
    total: 0,
    hasMore: false,
  },
};

export class PrayerRequestsStore {
  state: PrayerRequestsStoreState = initialState;

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'prayer_requests_store';

  constructor() {
    this.state = initialState;
    this.storageKey = 'prayer_requests_store';
    
    makeAutoObservable(this, {}, { autoBind: true });
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading prayer requests store from storage:', error);
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
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }

  get requests(): PrayerRequest[] {
    return this.state.requests || [];
  }

  get pagination() {
    return this.state.pagination;
  }

  clearErrors() {
    this.setError(null);
  }

  fetchRequests = async (
    page = 1,
    params: { category?: string | 'all'; type?: 'prayer' | 'testimony' | 'all' } = {}
  ) => {
    try {
      this.setLoading(true);
      this.setError(null);
      
      const response = await apiClient.get<any>(
        endpoints.prayerRequests.list,
        {
          include: [
            'user',
            'rootComments.user',
            'rootComments.children.user',
            'rootComments.children.children.user',
            'rootComments.children.children.children.user',
          ],
          per_page: this.pagination.perPage,
          page,
          _sort_by: '-created_at',
          ...(params.category && params.category !== 'all' ? { category: params.category } : {}),
          ...(params.type && params.type !== 'all' ? { type: params.type } : {}),
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch prayer requests');
      }
      
      runInAction(() => {
        // Backend returns { success: true, data: PrayerRequest[], message: string }
        // with Laravel pagination meta in data.meta if paginated
        const payload = response.data as any;
        const list = ((payload.data ?? payload) as PrayerRequest[]).map(this.normalizeRequest);
        const meta = payload.meta ?? null;
        
        this.state.requests = page === 1 ? list : [...this.state.requests, ...list];
        this.updatePagination(meta, page);
      });
      
      await this.saveToStorage();
      return this.state.requests;
    } catch (error) {
      console.error('Error fetching prayer requests:', error);
      this.setError('Failed to fetch prayer requests');
      return [];
    } finally {
      this.setLoading(false);
    }
  };

  createRequest = async (data: {
    content: string;
    category?: PrayerCategory;
    visibility?: 'anonymous' | 'first_name' | 'full_name';
    title?: string | null;
    type?: 'prayer' | 'testimony';
  }) => {
    try {
      this.setLoading(true);
      this.setError(null);
      
      const payload = {
        title: data.title?.trim() || undefined,
        detail: data.content.trim(),
        category: data.category ?? 'healing',
        visibility: data.visibility ?? 'anonymous',
        type: data.type ?? 'prayer',
      };
      
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.create, payload);
      
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to create prayer request');
      }
      
      const created = this.normalizeRequest(response.data as PrayerRequest);
      
      runInAction(() => {
        this.state.requests = [created, ...this.state.requests];
        this.state.pagination.total += 1;
      });
      
      await this.saveToStorage();
      toast.success('Prayer request shared');
      return created;
    } catch (error) {
      console.error('Error creating prayer request:', error);
      this.setError('Failed to create prayer request');
      return null;
    } finally {
      this.setLoading(false);
    }
  };

  prayForRequest = async (id: string) => {
    try {
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.pray(id));
      
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to mark as prayed');
      }

      runInAction(() => {
        const updated = this.normalizeRequest(response.data as PrayerRequest);
        this.replaceRequest(updated);
      });
      
      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error('Error marking prayer as prayed:', error);
      this.setError('Failed to mark as prayed');
      return false;
    }
  };

  toggleAmen = async (id: string) => {
    try {
      const response = await apiClient.post<PrayerRequest>(endpoints.prayerRequests.amen(id));

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to toggle amen');
      }

      runInAction(() => {
        const updated = this.normalizeRequest(response.data as PrayerRequest);
        this.replaceRequest(updated);
      });

      await this.saveToStorage();
      return true;
    } catch (error) {
      console.error('Error toggling amen:', error);
      this.setError('Failed to update amen');
      return false;
    }
  };

  addComment = async (
    prayerRequestId: string,
    content: string,
    parentId?: string | null
  ) => {
    try {
      const response = await apiClient.post<PrayerRequestComment>(
        endpoints.prayerRequestComments.create,
        {
          content,
          prayer_request_id: prayerRequestId,
          ...(parentId ? { parent_id: parentId } : {}),
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to add comment');
      }

      runInAction(() => {
        const request = this.state.requests.find(r => r.id === prayerRequestId);
        if (!request) return;

        const newComment = response.data as PrayerRequestComment;

        if (!parentId) {
          request.comments = [newComment, ...(request.comments ?? [])];
        } else if (request.comments?.length) {
          request.comments = request.comments.map(comment => this.appendReply(comment, newComment));
        }

        request.comments_count = (request.comments_count ?? 0) + 1;
        this.replaceRequest(this.normalizeRequest(request));
      });

      await this.saveToStorage();
      return response.data;
    } catch (error) {
      console.error('Error adding comment:', error);
      this.setError('Failed to add comment');
      return null;
    }
  };

  toggleCommentAmen = async (commentId: string) => {
    try {
      const response = await apiClient.post<PrayerRequestComment>(
        endpoints.prayerRequestComments.amen(commentId)
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to toggle comment amen');
      }

      const normalizedComment = this.normalizeComment(response.data);

      runInAction(() => {
        // Update the comment in all prayer requests
        this.state.requests.forEach(request => {
          if (request.comments?.length) {
            this.updateCommentInTree(request.comments, normalizedComment);
          }
        });
      });

      await this.saveToStorage();
      return normalizedComment;
    } catch (error) {
      console.error('Error toggling comment amen:', error);
      this.setError('Failed to update comment amen');
      return null;
    }
  };

  private updateCommentInTree(comments: PrayerRequestComment[], updatedComment: PrayerRequestComment): boolean {
    for (let i = 0; i < comments.length; i++) {
      if (comments[i].id === updatedComment.id) {
        comments[i] = updatedComment;
        return true;
      }
      if (comments[i].replies?.length && this.updateCommentInTree(comments[i].replies!, updatedComment)) {
        return true;
      }
    }
    return false;
  }

  fetchComments = async (prayerRequestId: string, options: { rootsOnly?: boolean; withChildren?: boolean } = {}) => {
    try {
      const params: any = {
        prayer_request_id: prayerRequestId,
        include: 'user,parent.user,children.user',
        per_page: 50,
      };

      if (options.rootsOnly) {
        params.roots_only = '1';
      }

      if (options.withChildren) {
        params.with_children = '1';
      }

      const response = await apiClient.get<any>(
        endpoints.prayerRequestComments.list,
        params
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch comments');
      }

      return response.data;
    } catch (error) {
      console.error('Error fetching comments:', error);
      this.setError('Failed to fetch comments');
      return [];
    }
  };

  deleteRequest = async (id: string) => {
    try {
      this.setLoading(true);
      this.setError(null);
      
      const response = await apiClient.delete(endpoints.prayerRequests.delete(id));
      
      if (!response.success) {
        throw new Error(response.message || 'Failed to delete request');
      }
      
      runInAction(() => {
        this.state.requests = this.state.requests.filter(r => r.id !== id);
        this.state.pagination.total = Math.max(0, this.state.pagination.total - 1);
      });
      
      await this.saveToStorage();
      toast.success('Prayer request deleted');
      return true;
    } catch (error) {
      console.error('Error deleting prayer request:', error);
      this.setError('Failed to delete request');
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  reset = async () => {
    runInAction(() => {
      this.state = initialState;
      this.setError(null);
    });
    
    await this.saveToStorage();
  };

  private replaceRequest(updated: PrayerRequest) {
    const index = this.state.requests.findIndex(r => r.id === updated.id);
    if (index !== -1) {
      this.state.requests[index] = updated;
    }
  }

  private appendReply(
    comment: PrayerRequestComment,
    incoming: PrayerRequestComment
  ): PrayerRequestComment {
    if (comment.id === incoming.parent_id) {
      return {
        ...comment,
        replies: [this.normalizeComment(incoming), ...(comment.replies ?? [])],
      };
    }

    return {
      ...comment,
      replies: comment.replies?.map(reply => this.appendReply(reply, incoming)) ?? comment.replies,
    };
  }

  private normalizeRequest = (request: PrayerRequest): PrayerRequest => {
    return {
      ...request,
      comments: request.comments ?? [],
      comments_count: request.comments_count ?? request.comments?.length ?? 0,
      prayed_count: request.prayed_count ?? (Array.isArray(request.prayed_users) ? request.prayed_users.length : 0),
      amen_count: request.amen_count ?? (Array.isArray(request.amen_users) ? request.amen_users.length : 0),
    };
  };

  private normalizeComment = (comment: PrayerRequestComment): PrayerRequestComment => {
    return {
      ...comment,
      amen_count: comment.amen_count ?? (Array.isArray(comment.amen_users) ? comment.amen_users.length : 0),
    };
  };

  async reportRequest(requestId: string): Promise<void> {
    this.setLoading(true);
    this.error = null;
    try {
      await apiClient.post(`${endpoints.prayerRequests}/${requestId}/report`);
      toast.success('Content reported successfully');
    } catch (error: any) {
      this.error = error?.message || 'Failed to report content';
      toast.error(this.error || 'Failed to report content');
      throw error;
    } finally {
      this.setLoading(false);
    }
  };

  private updatePagination(meta: any, currentPage: number) {
    if (meta && typeof meta === 'object' &&
        (typeof meta.last_page !== 'undefined' || typeof meta.current_page !== 'undefined')) {
      const lastPage = Number(meta.last_page ?? currentPage) || currentPage;
      const perPage = Number(meta.per_page ?? this.state.pagination.perPage) || this.state.pagination.perPage;
      const total = Number(meta.total ?? this.state.pagination.total) || this.state.pagination.total;
      const current = Number(meta.current_page ?? currentPage) || currentPage;
      this.state.pagination = {
        currentPage: current,
        lastPage,
        perPage,
        total,
        hasMore: current < lastPage,
      };
      return;
    }

    // No meta provided: set hasMore to false
    this.state.pagination = {
      currentPage,
      lastPage: currentPage,
      perPage: this.state.pagination.perPage,
      total: this.state.pagination.total,
      hasMore: false,
    };
  }

  cleanup() {
    // Clean up any resources if needed
  }
}

// Create a singleton instance
export const prayerRequestsStore = new PrayerRequestsStore();

// For backward compatibility
export const usePrayerRequestsStore = () => prayerRequestsStore;

export default prayerRequestsStore;
