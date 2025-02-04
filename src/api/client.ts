import axios, { AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { toast } from 'sonner-native';

export interface APIResponse<T> {
  success: boolean;
  data: T;
  message: string;
  errors?: Record<string, string[]>;
}

const api = axios.create({
  baseURL: 'https://api.elbiblio.com/api',
  timeout: 10000,
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

api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
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
        toast.error(errorResponse.message);
        return Promise.reject(errorResponse);
      }

      if (status === 422 && response?.data) {
        errorResponse.errors = response.data.errors || {};
        errorResponse.message = response.data.message || 'Validation failed';
        
        if (errorResponse.errors) {
          Object.values(errorResponse.errors).forEach(messages => {
            if (Array.isArray(messages)) {
              messages.forEach(message => toast.error(message));
            }
          });
        }
        return Promise.reject(errorResponse);
      }

      errorResponse.message = response?.data?.message || 'An error occurred';
      errorResponse.data = response?.data?.data || null;
    } else if (axios.isAxiosError(error) && error.request) {
      errorResponse.message = 'Network error. Please check your connection.';
    } else {
      errorResponse.message = (error as Error).message || 'An error occurred';
    }

    toast.error(errorResponse.message);
    return Promise.reject(errorResponse);
  }
);

export const endpoints = {
  auth: {
    login: '/auth/login',
    logout: '/auth/logout',
    user: '/auth/me',
    signup: '/users',
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
  notes: {
    list: '/notes',
    create: '/notes',
    update: (id: string) => `/notes/${id}`,
    delete: (id: string) => `/notes/${id}`,
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
  wordHubs: {
    list: '/word_hubs',
    create: '/word_hubs',
    join: (id: string) => `/word_hubs/${id}/join`,
    leave: (id: string) => `/word_hubs/${id}/leave`,
    messages: (id: string) => `/word_hubs/${id}/messages`,
  }
};

export const apiClient = {
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const response = await api.get<APIResponse<T>>(url, config);
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
};

export const createCancelToken = () => {
  return axios.CancelToken.source();
};

export default api;