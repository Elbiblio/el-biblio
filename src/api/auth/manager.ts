import AsyncStorage from '@react-native-async-storage/async-storage';

export interface AuthState {
  initialized: boolean;
  user: any | null;
  token: string | null;
}

class AuthManager {
  private cachedToken: string | null = null;
  private tokenCacheInitialized = false;
  private authInitialized = false;
  private authUser: any = null;
  private unauthorizedHandler: (() => Promise<void> | void) | null = null;
  private reauthPromise: Promise<boolean> | null = null;

  setUnauthorizedHandler(handler: (() => Promise<void> | void) | null): void {
    this.unauthorizedHandler = handler;
  }

  setToken(token: string | null): void {
    this.cachedToken = token;
    this.tokenCacheInitialized = true;
  }

  setAuthState(initialized: boolean, user: any): void {
    this.authInitialized = initialized;
    this.authUser = user;
    if (__DEV__) {
      console.log('[AuthManager] Auth state updated', { initialized, hasUser: !!user });
    }
  }

  isAuthReady(): boolean {
    return this.authInitialized;
  }

  async getToken(): Promise<string | null> {
    if (this.cachedToken != null) {
      return this.cachedToken;
    }
    if (this.tokenCacheInitialized) {
      return null;
    }
    const token = await AsyncStorage.getItem('auth_token');
    this.cachedToken = token;
    this.tokenCacheInitialized = true;
    return token;
  }

  async reauthenticate(): Promise<boolean> {
    if (this.reauthPromise) {
      return this.reauthPromise;
    }

    this.reauthPromise = (async () => {
      try {
        if (__DEV__) {
          console.log('[AuthManager] Starting reauthentication');
        }

        if (this.unauthorizedHandler) {
          await this.unauthorizedHandler();
          const token = await this.getToken();
          return !!token;
        }
        return false;
      } catch (e) {
        if (__DEV__) {
          console.error('[AuthManager] Reauthentication error:', e);
        }
        return false;
      } finally {
        this.reauthPromise = null;
      }
    })();

    return this.reauthPromise;
  }

  getState(): AuthState {
    return {
      initialized: this.authInitialized,
      user: this.authUser,
      token: this.cachedToken,
    };
  }
}

export const authManager = new AuthManager();
