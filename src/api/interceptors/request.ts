import type { InternalAxiosRequestConfig } from 'axios';
import { authManager } from '../auth/manager';
import { shouldRequireAuth, isAuthHeaderExemptPath } from '../auth/guards';
import { RequestConfig, AuthNotReadyError } from '../types';

function getRequestIdentifier(config: InternalAxiosRequestConfig): string {
  const method = config?.method?.toUpperCase() || 'GET';
  const url = config?.url || '';
  const requestId = config?.headers?.['X-Request-ID'] || '';
  return `${method}:${url}:${requestId}`;
}

export async function requestInterceptor(
  config: InternalAxiosRequestConfig
): Promise<InternalAxiosRequestConfig> {
  const requiresAuth = shouldRequireAuth(config);
  const requestId = getRequestIdentifier(config);

  // Block authenticated requests if auth is not ready
  if (requiresAuth && !authManager.isAuthReady()) {
    const errorMessage = 'Authentication not initialized. Request queued or rejected.';
    if (__DEV__) {
      console.warn(`[RequestInterceptor] Blocking authenticated request before auth ready [${requestId}]:`, {
        method: config.method,
        url: config.url,
      });
    }

    const error: AuthNotReadyError = {
      message: errorMessage,
      code: 'AUTH_NOT_READY',
      config: config as RequestConfig,
    };
    return Promise.reject(error);
  }

  const isAnonymous = config?.headers && (config.headers as any)['X-Anonymous'] === 'true';
  const isAuthHeaderExempt = isAuthHeaderExemptPath(String(config.url || ''));

  // Add authorization header for authenticated requests
  if (!isAnonymous && !isAuthHeaderExempt) {
    const token = await authManager.getToken();
    if (token) {
      config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    } else if (requiresAuth) {
      if (__DEV__) {
        console.warn(`[RequestInterceptor] No token available for authenticated request [${requestId}]:`, {
          method: config.method,
          url: config.url,
        });
      }
    }
  } else {
    // Remove authorization header for anonymous/exempt requests
    if (config.headers && 'Authorization' in config.headers) {
      delete (config.headers as any).Authorization;
    }

    if (__DEV__) {
      console.log('[RequestInterceptor] Anonymous request', {
        method: config.method,
        url: config.url,
      });
    }
  }

  // Add request ID for tracking
  config.headers = config.headers || {};
  config.headers['X-Request-ID'] = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

  if (__DEV__) {
    console.log(`[RequestInterceptor] Request: ${requestId}`, {
      method: config.method,
      url: config.url,
      hasToken: !!config.headers.Authorization,
      authReady: authManager.isAuthReady(),
    });
  }

  return config;
}

export function requestErrorInterceptor(error: any): Promise<never> {
  if (__DEV__) {
    console.error('[RequestInterceptor] Request error:', error);
  }
  return Promise.reject(error);
}
