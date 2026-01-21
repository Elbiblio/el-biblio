import { QueryParams } from './types';

export function buildQueryString(params: QueryParams): string {
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
}

export function isAPIResponse(err: any): err is import('./types').APIResponse<any> {
  return !!err && typeof err === 'object' && 'success' in err && 'message' in err;
}
