import axios, { AxiosRequestConfig } from 'axios';
import { APIResponse, QueryParams } from './types';
import { authManager } from './auth/manager';
import { requestInterceptor, requestErrorInterceptor } from './interceptors/request';
import { responseInterceptor, createResponseErrorInterceptor } from './interceptors/response';
import { buildQueryString, isAPIResponse } from './utils';
import { endpoints } from './endpoints';

// Create axios instance
const api = axios.create({
  baseURL: 'https://api.elbiblio.com/api',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

// Register interceptors
api.interceptors.request.use(requestInterceptor, requestErrorInterceptor);
api.interceptors.response.use(responseInterceptor, createResponseErrorInterceptor(api));

// Export auth manager functions for backward compatibility
export const setUnauthorizedHandler = (handler: (() => Promise<void> | void) | null) => {
  authManager.setUnauthorizedHandler(handler);
};

export const setTokenCache = (token: string | null) => {
  authManager.setToken(token);
};

export const setAuthState = (initialized: boolean, user: any) => {
  authManager.setAuthState(initialized, user);
};

// Export types
export type { APIResponse, PaginatedResponse, QueryParams } from './types';

// Export endpoints
export { endpoints };

// API Client wrapper
export const apiClient = {
  async get<T>(url: string, params?: QueryParams, config?: AxiosRequestConfig): Promise<APIResponse<T>> {
    try {
      const queryString = params ? buildQueryString(params) : '';
      const fullUrl = queryString ? `${url}?${queryString}` : url;
      const response = await api.get<APIResponse<T>>(fullUrl, config);
      return response.data;
    } catch (error) {
      if (isAPIResponse(error)) {
        return error as APIResponse<T>;
      }
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
      if (isAPIResponse(error)) {
        return error as APIResponse<T>;
      }
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
      if (isAPIResponse(error)) {
        return error as APIResponse<T>;
      }
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
      if (isAPIResponse(error)) {
        return error as APIResponse<T>;
      }
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
      if (isAPIResponse(error)) {
        return error as APIResponse<T>;
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },

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
      if (isAPIResponse(error)) {
        return error as APIResponse<T>;
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error occurred');
    }
  },
};

// Export cancel token utility
export const createCancelToken = () => {
  return axios.CancelToken.source();
};

// Export default axios instance for advanced usage
export default api;
