import type { AxiosRequestConfig, InternalAxiosRequestConfig } from 'axios';

export interface APIResponse<T> {
  success: boolean;
  data: T;
  message: string;
  errors?: Record<string, string[]>;
  status?: number;
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

export interface RequestConfig extends InternalAxiosRequestConfig {
  _retry?: boolean;
}

export interface AuthNotReadyError {
  message: string;
  code: 'AUTH_NOT_READY';
  config: RequestConfig;
}
