import axios, { AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { toast } from 'sonner-native';
import { appState } from '@/utils/appInitialization';

export interface APIResponse<T> {
  success: boolean;
  data: T;
  message: string;
  errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    current_page: number;
    from: number;
    last_page: number;
    per_page: number;
    to: number;
    total: number;
  };
}

export interface QueryParams {
  include?: string[];
  sort?: string;
  per_page?: number;
  page?: number;
  filter_strict?: boolean;
  negatives?: string[];
  nulls?: string[];
  [key: string]: any;
}

const api = axios.create({
  baseURL: 'https://api.elbiblio.com/api',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

const transformResponse = <T>(response: AxiosResponse): AxiosResponse<APIResponse<T>> => {
  const responseData = response.data;
  
  if (responseData && typeof responseData === 'object' && 'success' in responseData) {
    return {
      ...response,
      data: responseData as APIResponse<T>
    };
  }

  return {
    ...response,
    data: {
      success: response.status >= 200 && response.status < 300,
      data: responseData as T,
      message: response.statusText || 'Success'
    }
  };
};

const buildQueryString = (params: QueryParams): string => {
  const queryParams = new URLSearchParams();
  
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null) {
      if (Array.isArray(value)) {
        queryParams.append(key, value.join(','));
      } else {
        queryParams.append(key, String(value));
      }
    }
  });
  
  return queryParams.toString();
};

api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Add request ID for tracking
    config.headers['X-Request-ID'] = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    return config;
  },
  (error: AxiosError) => {
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response) => {
    return transformResponse(response);
  },
  async (error: unknown) => {
    if (axios.isCancel(error)) {
      return Promise.reject(error);
    }

    const errorResponse: APIResponse<null> = {
      success: false,
      data: null,
      message: 'An error occurred',
      errors: {}
    };

    if (axios.isAxiosError(error)) {
      const { response, request } = error;
      const status = response?.status;

      if (status === 401) {
        await AsyncStorage.removeItem('auth_token');
        errorResponse.message = 'Session expired. Please login again.';
        
        if (appState.isInitialized) {
          toast.error(errorResponse.message);
        }
        
        return Promise.reject(errorResponse);
      }

      if (status && status === 403) {
        errorResponse.message = 'Access denied. You don\'t have permission to perform this action.';
        return Promise.reject(errorResponse);
      }

      if (status && status === 404) {
        errorResponse.message = 'Resource not found.';
        return Promise.reject(errorResponse);
      }

      if (status === 422 && response?.data) {
        errorResponse.errors = response.data.errors || {};
        errorResponse.message = response.data.message || 'Validation failed';
        
        if (appState.isInitialized && errorResponse.errors) {
          Object.values(errorResponse.errors).forEach(messages => {
            if (Array.isArray(messages)) {
              messages.forEach(message => toast.error(message));
            }
          });
        }
        
        return Promise.reject(errorResponse);
      }

      if (status && status === 429) {
        errorResponse.message = 'Too many requests. Please try again later.';
        return Promise.reject(errorResponse);
      }

      if (status && status >= 500) {
        errorResponse.message = 'Server error. Please try again later.';
        return Promise.reject(errorResponse);
      }

      errorResponse.message = response?.data?.message || 'An error occurred';
      errorResponse.data = response?.data?.data || null;
    } else if (axios.isAxiosError(error) && error.request) {
      errorResponse.message = 'Network error. Please check your connection.';
    } else {
      errorResponse.message = (error as Error).message || 'An error occurred';
    }

    if (appState.isInitialized) {
      toast.error(errorResponse.message);
    }
    
    return Promise.reject(errorResponse);
  }
);

export const endpoints = {
  // Authentication
  auth: {
    login: '/auth/login',
    logout: '/auth/logout',
    user: '/auth/me',
    signup: '/users',
    refresh: '/auth/refresh',
    forgotPassword: '/auth/forgot-password',
    resetPassword: '/auth/reset-password',
    verifyEmail: '/auth/verify-email',
  },

  // Users
  users: {
    list: '/users',
    show: (id: string) => `/users/${id}`,
    update: (id: string) => `/users/${id}`,
    delete: (id: string) => `/users/${id}`,
    avatar: (id: string) => `/users/${id}/avatar`,
    profile: (id: string) => `/users/${id}/profile`,
    preferences: (id: string) => `/users/${id}/preferences`,
    activity: (id: string) => `/users/${id}/activity`,
    stats: (id: string) => `/users/${id}/stats`,
  },

  // Verses
  verses: {
    list: '/verses',
    daily: '/verses/daily',
    show: (id: string) => `/verses/${id}`,
    update: (id: string) => `/verses/${id}`,
    delete: (id: string) => `/verses/${id}`,
    vote: (id: string) => `/verses/${id}/vote`,
    like: (id: string) => `/verses/${id}/like`,
    share: (id: string) => `/verses/${id}/share`,
    trending: '/verses/trending',
    featured: '/verses/featured',
    search: '/verses/search',
    byTheme: (themeId: string) => `/verses/theme/${themeId}`,
  },

  // Notes
  notes: {
    list: '/notes',
    show: (id: string) => `/notes/${id}`,
    create: '/notes',
    update: (id: string) => `/notes/${id}`,
    delete: (id: string) => `/notes/${id}`,
    like: (id: string) => `/notes/${id}/like`,
    share: (id: string) => `/notes/${id}/share`,
    pin: (id: string) => `/notes/${id}/pin`,
    public: '/notes/public',
    featured: '/notes/featured',
    search: '/notes/search',
    byUser: (userId: string) => `/users/${userId}/notes`,
  },

  // Reflections
  reflections: {
    list: '/reflections',
    show: (id: string) => `/reflections/${id}`,
    create: '/reflections',
    update: (id: string) => `/reflections/${id}`,
    delete: (id: string) => `/reflections/${id}`,
    like: (id: string) => `/reflections/${id}/like`,
    share: (id: string) => `/reflections/${id}/share`,
    byVerse: (verseId: string) => `/verses/${verseId}/reflections`,
    byUser: (userId: string) => `/users/${userId}/reflections`,
    featured: '/reflections/featured',
  },

  // Comments
  comments: {
    list: '/comments',
    show: (id: string) => `/comments/${id}`,
    create: '/comments',
    update: (id: string) => `/comments/${id}`,
    delete: (id: string) => `/comments/${id}`,
    like: (id: string) => `/comments/${id}/like`,
    byReflection: (reflectionId: string) => `/reflections/${reflectionId}/comments`,
    replies: (id: string) => `/comments/${id}/replies`,
  },

  // Bookmarks
  bookmarks: {
    list: '/bookmarks',
    show: (id: string) => `/bookmarks/${id}`,
    create: '/bookmarks',
    update: (id: string) => `/bookmarks/${id}`,
    delete: (id: string) => `/bookmarks/${id}`,
    byUser: (userId: string) => `/users/${userId}/bookmarks`,
    byType: (type: string) => `/bookmarks/type/${type}`,
  },

  // User Interactions
  interactions: {
    list: '/user-interactions',
    create: '/user-interactions',
    update: (id: string) => `/user-interactions/${id}`,
    delete: (id: string) => `/user-interactions/${id}`,
    byUser: (userId: string) => `/users/${userId}/interactions`,
    byType: (type: string) => `/user-interactions/type/${type}`,
  },

  // Activities
  activities: {
    list: '/activities',
    show: (id: string) => `/activities/${id}`,
    create: '/activities',
    update: (id: string) => `/activities/${id}`,
    delete: (id: string) => `/activities/${id}`,
    byUser: (userId: string) => `/users/${userId}/activities`,
    feed: '/activities/feed',
    recent: '/activities/recent',
  },

  // Notifications
  notifications: {
    list: '/notifications',
    show: (id: string) => `/notifications/${id}`,
    markAsRead: (id: string) => `/notifications/${id}/read`,
    markAllAsRead: '/notifications/mark-all-read',
    delete: (id: string) => `/notifications/${id}`,
    settings: '/notifications/settings',
    unreadCount: '/notifications/unread-count',
  },

  // Themes
  themes: {
    list: '/themes',
    show: (id: string) => `/themes/${id}`,
    create: '/themes',
    update: (id: string) => `/themes/${id}`,
    delete: (id: string) => `/themes/${id}`,
    foundational: '/themes/foundational',
    byUser: (userId: string) => `/users/${userId}/themes`,
  },

  // Word Hubs
  wordHubs: {
    list: '/word-hubs',
    show: (id: string) => `/word-hubs/${id}`,
    create: '/word-hubs',
    update: (id: string) => `/word-hubs/${id}`,
    delete: (id: string) => `/word-hubs/${id}`,
    join: (id: string) => `/word-hubs/${id}/join`,
    leave: (id: string) => `/word-hubs/${id}/leave`,
    members: (id: string) => `/word-hubs/${id}/members`,
    messages: (id: string) => `/word-hubs/${id}/messages`,
    sendMessage: (id: string) => `/word-hubs/${id}/messages`,
    byUser: (userId: string) => `/users/${userId}/word-hubs`,
  },

  // Matches
  matches: {
    list: '/matches',
    show: (id: string) => `/matches/${id}`,
    create: '/matches',
    update: (id: string) => `/matches/${id}`,
    delete: (id: string) => `/matches/${id}`,
    cancel: (id: string) => `/matches/${id}/cancel`,
    accept: (id: string) => `/matches/${id}/accept`,
    reject: (id: string) => `/matches/${id}/reject`,
    active: '/matches/active',
    history: '/matches/history',
  },

  // Languages
  languages: {
    list: '/languages',
    show: (id: string) => `/languages/${id}`,
    active: '/languages/active',
  },

  // Cache
  cache: {
    get: (key: string) => `/cache/${key}`,
    set: '/cache',
    delete: (key: string) => `/cache/${key}`,
    clear: '/cache/clear',
  },

  // Jobs
  jobs: {
    list: '/jobs',
    show: (id: string) => `/jobs/${id}`,
    create: '/jobs',
    retry: (id: string) => `/jobs/${id}/retry`,
    cancel: (id: string) => `/jobs/${id}/cancel`,
  },

  // Leaderboards
  leaderboards: {
    global: '/leaderboards/global',
    byTheme: (themeId: string) => `/leaderboards/theme/${themeId}`,
    byTimeframe: (timeframe: string) => `/leaderboards/timeframe/${timeframe}`,
    userRank: (userId: string) => `/leaderboards/user/${userId}/rank`,
  },

  // Statistics
  stats: {
    user: (userId: string) => `/stats/user/${userId}`,
    global: '/stats/global',
    theme: (themeId: string) => `/stats/theme/${themeId}`,
  },

  // Search
  search: {
    global: '/search',
    verses: '/search/verses',
    notes: '/search/notes',
    reflections: '/search/reflections',
    users: '/search/users',
  },

  // Bible
  bible: {
    versions: '/bible/versions',
    verses: '/bible/verses',
    search: '/bible/search',
    installVersion: (version: string) => `/bible/versions/${version}/install`,
    toggleHighlight: (verseId: string) => `/bible/verses/${verseId}/highlight`,
    toggleBookmark: (verseId: string) => `/bible/verses/${verseId}/bookmark`,
    like: (verseId: string) => `/bible/verses/${verseId}/like`,
    share: (verseId: string) => `/bible/verses/${verseId}/share`,
  },

  // Challenges
  challenges: {
    personal: '/challenges/personal',
    community: '/challenges/community',
    suggested: '/challenges/suggested',
    daily: '/challenges/daily',
    create: '/challenges',
    update: (id: string) => `/challenges/${id}`,
    delete: (id: string) => `/challenges/${id}`,
    join: (id: string) => `/challenges/${id}/join`,
    leave: (id: string) => `/challenges/${id}/leave`,
    upvote: (id: string) => `/challenges/${id}/upvote`,
    complete: (id: string) => `/challenges/${id}/complete`,
    addToPersonal: (id: string) => `/challenges/${id}/add-to-personal`,
    participants: (id: string) => `/challenges/${id}/participants`,
  },

  // Prayer Requests
  prayerRequests: {
    list: '/prayer-requests',
    show: (id: string) => `/prayer-requests/${id}`,
    create: '/prayer-requests',
    update: (id: string) => `/prayer-requests/${id}`,
    delete: (id: string) => `/prayer-requests/${id}`,
    pray: (id: string) => `/prayer-requests/${id}/pray`,
    byUser: (userId: string) => `/users/${userId}/prayer-requests`,
  },
};

export const apiClient = {
  async get<T>(url: string, params?: QueryParams, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const queryString = params ? buildQueryString(params) : '';
      const fullUrl = queryString ? `${url}?${queryString}` : url;
      const response = await api.get<APIResponse<T>>(fullUrl, config);
      return response.data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },
  
  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const response = await api.post<APIResponse<T>>(url, data, config);
      return response.data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },
  
  async put<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const response = await api.put<APIResponse<T>>(url, data, config);
      return response.data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },
  
  async patch<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const response = await api.patch<APIResponse<T>>(url, data, config);
      return response.data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },
  
  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const response = await api.delete<APIResponse<T>>(url, config);
      return response.data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },

  // Helper methods for common operations
  async uploadFile<T>(url: string, file: any, onProgress?: (progress: number) => void): Promise<APIResponse<T>> {
    try {
      const formData = new FormData();
      formData.append('file', file);
      
      const response = await api.post<APIResponse<T>>(url, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        onUploadProgress: (progressEvent) => {
          if (onProgress && progressEvent.total) {
            const progress = (progressEvent.loaded / progressEvent.total) * 100;
            onProgress(progress);
          }
        },
      });
      return response.data;
    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },
};

export const createCancelToken = () => {
  return axios.CancelToken.source();
};

export default api;