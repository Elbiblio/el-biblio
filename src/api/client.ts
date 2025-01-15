// api/client.ts
import axios, { AxiosError, AxiosRequestConfig } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { toast } from 'sonner-native';
import { useAuth } from '@/stores/auth';
import { APIResponse } from '@/types/api';

const api = axios.create({
  baseURL: 'https://api.elbiblio.com/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

// Add support for cancellation
export const createCancelToken = () => {
  const source = axios.CancelToken.source();
  return source;
};

// Request interceptor with auth token
api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error: AxiosError) => Promise.reject(error)
);

// Response interceptor with error handling
api.interceptors.response.use(
  (response) => response,
  async (error: any) => {
    // Don't handle cancelled requests
    if (axios.isCancel(error)) {
      return Promise.reject(error);
    }

    // Handle 401 Unauthorized
    if (error.response?.status === 401) {
      await AsyncStorage.removeItem('auth_token');
      const { logout } = useAuth();
      logout();
      toast.error('Session expired. Please login again.');
      return Promise.reject(error);
    }

    // Handle validation errors (422)
    if (error.response?.status === 422) {
      const validationErrors = (error.response.data as any)?.errors;
      if (validationErrors) {
        Object.values(validationErrors).forEach((messages: any) => {
          messages.forEach((message: string) => toast.error(message));
        });
      }
      return Promise.reject(error);
    }

    // Network errors
    if (!error.response) {
      toast.error('Network error. Please check your connection.');
      return Promise.reject(error);
    }

    // General error fallback
    const errorMessage = (error.response?.data as any)?.message || 'Something went wrong';
    toast.error(errorMessage);
    return Promise.reject(error);
  }
);

// API endpoints
export const endpoints = {
  auth: {
    login: '/auth/login',
    signup: '/auth/register',
    logout: '/auth/logout',
    user: '/auth/me',
  },
  verses: {
    daily: '/verses/daily',
    show: (id: string) => `/verses/${id}`,
    vote: (id: string) => `/verses/${id}/vote`,
  },
  users: {
    update: (id: string) => `/users/${id}`,
    avatar: (id: string) => `/users/${id}/avatar`,
  },
  interactions: {
    create: '/user-interactions',
  },
  bookmarks: {
    create: '/bookmarks',
  },
  reflections: {
    create: '/reflections',
    show: (id: string) => `/reflections/${id}`,
  },
  comments: {
    create: '/comments',
  },
};

// API methods with type safety
export const apiClient = {
  get: async <T>(url: string, config?: AxiosRequestConfig) => {
    const response = await api.get<APIResponse<T>>(url, config);
    return response.data;
  },
  
  post: async <T>(url: string, data?: any, config?: AxiosRequestConfig) => {
    const response = await api.post<APIResponse<T>>(url, data, config);
    return response.data;
  },
  
  put: async <T>(url: string, data?: any, config?: AxiosRequestConfig) => {
    const response = await api.put<APIResponse<T>>(url, data, config);
    return response.data;
  },
  
  delete: async <T>(url: string, config?: AxiosRequestConfig) => {
    const response = await api.delete<APIResponse<T>>(url, config);
    return response.data;
  },
};

export default api;