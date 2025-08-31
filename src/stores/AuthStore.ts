import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import axios from 'axios';
import { apiClient, endpoints } from '@/api/client';
import { User, UserRole, SignUpData } from '@/types';

class AuthStore {
  user: User | null = null;
  token: string | null = null;
  isLoading = false;
  isInitialized = false;
  error: string | null = null;
  isGuest = false;
  isEmailVerified = false;
  userRole: UserRole = UserRole.User;
  private readonly TOKEN_KEY = 'auth_token';
  private readonly USER_KEY = 'user_data';

  constructor() {
    makeAutoObservable(this);
    this.initialize();
  }

  private setLoading = (loading: boolean) => {
    this.isLoading = loading;
  };

  private setError = (error: string | null) => {
    this.error = error;
  };

  private setUser = (user: User | null) => {
    this.user = user;
    // Our User type doesn't include guest/email verification flags; default safely
    this.isGuest = false;
    this.isEmailVerified = !!user?.email;
    this.userRole = user?.role ?? UserRole.User;
    if (user) {
      AsyncStorage.setItem(this.USER_KEY, JSON.stringify(user));
    } else {
      AsyncStorage.removeItem(this.USER_KEY);
    }
  };

  private setToken = (token: string | null) => {
    this.token = token;
    if (token) {
      AsyncStorage.setItem(this.TOKEN_KEY, token);
    } else {
      AsyncStorage.removeItem(this.TOKEN_KEY);
    }
  };

  initialize = async () => {
    if (this.isInitialized) return;

    try {
      this.setLoading(true);
      const [token, userData] = await Promise.all([
        AsyncStorage.getItem(this.TOKEN_KEY),
        AsyncStorage.getItem(this.USER_KEY),
      ]);

      if (token && userData) {
        const user = JSON.parse(userData);
        runInAction(() => {
          this.setToken(token);
          this.setUser(user);
          this.isInitialized = true;
        });
      }
    } catch (error) {
      console.error('Error initializing auth:', error);
      this.setError('Failed to initialize authentication');
    } finally {
      runInAction(() => {
        this.isLoading = false;
        this.isInitialized = true;
      });
    }
  };

  login = async (email: string, password: string): Promise<boolean> => {
    try {
      this.setLoading(true);
      this.setError(null);

      const response = await apiClient.post<{
        token: string;
        user: User;
      }>(endpoints.auth.login, { email, password });

      runInAction(() => {
        this.setToken(response.data.token);
        this.setUser(response.data.user);
      });

      return true;
    } catch (error) {
      this.handleAuthError(error);
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  logout = async (): Promise<void> => {
    try {
      this.setLoading(true);
      // Optional: Call logout endpoint if needed
      // await apiClient.post(endpoints.auth.logout);
    } catch (error) {
      console.error('Error during logout:', error);
    } finally {
      runInAction(() => {
        this.setToken(null);
        this.setUser(null);
        this.setLoading(false);
      });
    }
  };

  signUp = async (data: SignUpData): Promise<boolean> => {
    try {
      this.setLoading(true);
      this.setError(null);

      const response = await apiClient.post<{
        token: string;
        user: User;
      }>(endpoints.auth.signup, data);

      runInAction(() => {
        this.setToken(response.data.token);
        this.setUser(response.data.user);
      });

      return true;
    } catch (error) {
      this.handleAuthError(error);
      return false;
    } finally {
      this.setLoading(false);
    }
  };

  createGuestAccount = async (): Promise<boolean> => {
    // Guest account endpoint is not available; provide controlled failure
    this.setError('Guest accounts are not supported.');
    return false;
  };

  // Add other methods like updateUser, refreshToken, etc.

  private handleAuthError = (error: any) => {
    console.error('Auth error:', error);
    let errorMessage = 'An error occurred during authentication';

    if (axios.isAxiosError(error)) {
      errorMessage = error.response?.data?.message || error.message;
    } else if (error instanceof Error) {
      errorMessage = error.message;
    }

    this.setError(errorMessage);
  };
}

// Create a singleton instance
export const authStore = new AuthStore();

// For backward compatibility
export const useAuthStore = () => authStore;
