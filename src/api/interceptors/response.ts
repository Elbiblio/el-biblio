import { AxiosResponse, AxiosError, AxiosInstance } from 'axios';
import { APIResponse, RequestConfig, AuthNotReadyError } from '../types';
import { authManager } from '../auth/manager';
import { getRequestPath, isAuthReauthExemptPath } from '../auth/guards';
import { errorHandler } from '../errors/handler';
import { pointsTracker } from '@/utils/pointsTracker';

function transformResponse<T>(response: AxiosResponse): AxiosResponse<APIResponse<T>> {
  const responseData = response.data;

  if (responseData && typeof responseData === 'object' && 'success' in responseData) {
    return {
      ...response,
      data: responseData as APIResponse<T>,
    };
  }

  return {
    ...response,
    data: {
      success: response.status >= 200 && response.status < 300,
      data: responseData as T,
      message: response.statusText || 'Success',
    },
  };
}

function extractPoints(response: AxiosResponse<APIResponse<any>>): { points: number; title?: string } | null {
  try {
    const url = String(response?.config?.url || '');
    const headerPoints = Number(
      response.headers?.['x-points-earned'] || response.headers?.['X-Points-Earned']
    );
    const body: any = response.data;
    const directPoints = Number((body?.data as any)?.points_earned ?? body?.points_earned);
    const metaPoints = Number((body?.data as any)?.meta?.points_earned);
    const points = [headerPoints, directPoints, metaPoints].find(
      (v) => typeof v === 'number' && !isNaN(v) && v > 0
    );

    if (typeof points === 'number' && points > 0) {
      const title = url.includes('/game/')
        ? 'Game Score'
        : (body?.data as any)?.challenge?.title || (body?.data as any)?.title;
      return { points, title };
    }
  } catch {
    // Ignore errors in points extraction
  }
  return null;
}

function getRequestIdentifier(config: any): string {
  const method = config?.method?.toUpperCase() || 'GET';
  const url = config?.url || '';
  const requestId = config?.headers?.['X-Request-ID'] || '';
  return `${method}:${url}:${requestId}`;
}

export function responseInterceptor<T>(response: AxiosResponse): AxiosResponse<APIResponse<T>> {
  const transformed = transformResponse<T>(response);

  // Extract and emit points if present
  const pointsData = extractPoints(transformed);
  if (pointsData) {
    pointsTracker.emit(pointsData.points, pointsData.title);
  }

  return transformed;
}

export function createResponseErrorInterceptor(axiosInstance: AxiosInstance) {
  async function handle401Error(
    error: AxiosError,
    errorResponse: APIResponse<null>,
    requestId: string
  ): Promise<never> {
    const originalRequest = error.config as RequestConfig;
    const requestPath = getRequestPath(String(originalRequest?.url || ''));
    const isAnonymousRequest =
      originalRequest?.headers && (originalRequest.headers as any)['X-Anonymous'] === 'true';
    const isReauthExempt = isAnonymousRequest || isAuthReauthExemptPath(requestPath);

    // Don't attempt reauth for exempt paths
    if (isReauthExempt) {
      errorResponse.message = (error.response?.data as any)?.message || 'Unauthorized';
      errorResponse.errors = (error.response?.data as any)?.errors || {};
      if (__DEV__) {
        console.log(`[ResponseInterceptor] 401 exempt [${requestId}]:`, { requestPath, isAnonymousRequest });
      }
      return Promise.reject(errorResponse);
    }

    // Don't retry if already retried
    if (originalRequest && originalRequest._retry) {
      errorResponse.message = 'Unauthorized';
      if (__DEV__) {
        console.log(`[ResponseInterceptor] 401 retry failed [${requestId}]`);
      }
      return Promise.reject(errorResponse);
    }

    // Attempt reauthentication
    if (__DEV__) {
      console.log(`[ResponseInterceptor] 401 detected [${requestId}], attempting reauth`, {
        requestPath,
      });
    }

    try {
      const success = await authManager.reauthenticate();

      if (success) {
        if (__DEV__) {
          console.log(`[ResponseInterceptor] Reauth successful, retrying [${requestId}]`);
        }
        originalRequest._retry = true;
        // Retry the original request using the axios instance
        return axiosInstance(originalRequest);
      }
    } catch (e) {
      if (__DEV__) {
        console.error(`[ResponseInterceptor] Reauth failed [${requestId}]:`, e);
      }
    }

    // Reauthentication failed - show error
    errorResponse.message = 'Session expired. Please login again.';
    errorHandler.handleSessionExpired();
    return Promise.reject(errorResponse);
  }

  return async function responseErrorInterceptor(error: unknown): Promise<never> {
    // Handle AUTH_NOT_READY errors from request interceptor
    if (error && typeof error === 'object' && 'code' in error && error.code === 'AUTH_NOT_READY') {
      const authError = error as AuthNotReadyError;
      const errorResponse: APIResponse<null> = {
        success: false,
        data: null,
        message: authError.message,
        errors: {},
        status: 401,
      };
      if (__DEV__) {
        console.log('[ResponseInterceptor] Request rejected - auth not ready:', error);
      }
      return Promise.reject(errorResponse);
    }

    const errorResponse: APIResponse<null> = {
      success: false,
      data: null,
      message: 'An error occurred',
      errors: {},
    };

    if (error && typeof error === 'object' && 'isAxiosError' in error && (error as any).isAxiosError) {
      const axiosError = error as AxiosError;
      const { response, request, config, message: axiosMessage } = axiosError;
      const status = response?.status;
      errorResponse.status = status;
      const requestId = getRequestIdentifier(config || {});

      if (__DEV__) {
        console.log(`[ResponseInterceptor] Response error [${requestId}]:`, {
          status,
          url: config?.url,
          method: config?.method,
          message: axiosMessage,
          responseData: response?.data,
        });
      }

      // Handle 401 Unauthorized
      if (status === 401) {
        return handle401Error(axiosError, errorResponse, requestId);
      }

      // Handle 403 Forbidden
      if (status === 403) {
        errorResponse.message = "Access denied. You don't have permission to perform this action.";
        return Promise.reject(errorResponse);
      }

      // Handle 404 Not Found
      if (status === 404) {
        errorResponse.message = 'Resource not found.';
        return Promise.reject(errorResponse);
      }

      // Handle 422 Validation Error
      if (status === 422 && response?.data) {
        errorResponse.errors = (response.data as any).errors || {};
        errorResponse.message = (response.data as any).message || 'Validation failed';
        errorHandler.handleValidationError(errorResponse.errors);
        return Promise.reject(errorResponse);
      }

      // Handle 429 Rate Limit
      if (status === 429) {
        errorResponse.message = 'Too many requests. Please try again later.';
        return Promise.reject(errorResponse);
      }

      // Handle 5xx Server Errors
      if (status && status >= 500) {
        if (__DEV__) {
          console.error(`[ResponseInterceptor] Server error [${requestId}]:`, response?.data);
        }
        errorResponse.message = 'Server error. Please try again later.';
        return Promise.reject(errorResponse);
      }

      // Handle other status codes
      if (status) {
        errorResponse.message = (response?.data as any)?.message || 'An error occurred';
        errorResponse.data = (response?.data as any)?.data || null;
      } else if (request) {
        if (__DEV__) {
          console.warn(`[ResponseInterceptor] Network error (no response received) [${requestId}]:`, {
            url: config?.url,
            method: config?.method,
          });
        }
        errorResponse.message = 'Network error. Please check your connection.';
      } else {
        errorResponse.message = axiosMessage || 'An error occurred';
      }
    } else {
      errorResponse.message = (error as Error).message || 'An error occurred';
    }

    errorHandler.handleGenericError(errorResponse.message);
    return Promise.reject(errorResponse);
  };
}
