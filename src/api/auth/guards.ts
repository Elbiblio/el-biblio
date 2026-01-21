import { RequestConfig } from '../types';

const AUTH_HEADER_EXEMPT_PATHS = new Set([
  '/auth/login',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/auth/verify-email',
  '/users',
]);

const AUTH_REAUTH_EXEMPT_PATHS = new Set([
  ...AUTH_HEADER_EXEMPT_PATHS,
  '/auth/refresh',
  '/auth/logout',
]);

export function getRequestPath(url?: string): string {
  if (!url) return '';
  const raw = url.split('?')[0];
  let path = raw;
  try {
    path = new URL(raw, 'http://localhost').pathname;
  } catch {
    path = raw;
  }
  if (path.startsWith('/api/')) {
    return path.slice(4);
  }
  if (path === '/api') {
    return '/';
  }
  return path;
}

export function isAuthHeaderExemptPath(url?: string): boolean {
  return AUTH_HEADER_EXEMPT_PATHS.has(getRequestPath(url));
}

export function isAuthReauthExemptPath(url?: string): boolean {
  return AUTH_REAUTH_EXEMPT_PATHS.has(getRequestPath(url));
}

export function shouldRequireAuth(config: RequestConfig): boolean {
  const isAnonymous = config?.headers && (config.headers as any)['X-Anonymous'] === 'true';
  const isAuthHeaderExempt = isAuthHeaderExemptPath(String(config.url || ''));
  return !isAnonymous && !isAuthHeaderExempt;
}
