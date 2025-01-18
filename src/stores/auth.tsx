import { create } from 'zustand';
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createContext, useContext, useEffect, ReactNode } from 'react';
import { apiClient, endpoints } from '@/api/client';
import { User } from '@/types';

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => Promise<void>;
  initialize: () => Promise<void>;
  signUp: (data: SignUpData) => Promise<boolean>;
  updateUserTime: (totalActiveTime: number) => Promise<void>;
  updateAvatar: (avatarUrl: string) => Promise<boolean>;
}

interface SignUpData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  avatar: string;
}

interface LoginResponse {
  token: string;
  user: User;
  expires_in: number;
}

// Create store
const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,
  isLoading: false,
  isInitialized: false,
  error: null,

  initialize: async () => {
    try {
      set({ isLoading: true });
      const token = await AsyncStorage.getItem('auth_token');
      
      if (token) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        
        const response = await apiClient.get<User>(endpoints.auth.user);
        console.log('Initialize response:', response);

        if (response.success && response.data) {
          set({
            token,
            user: response.data,
            isInitialized: true
          });
          console.log('Successfully initialized with user:', response.data);
        } else {
          console.log('Invalid response during initialization:', response);
          await AsyncStorage.removeItem('auth_token');
          delete axios.defaults.headers.common['Authorization'];
        }
      }
    } catch (error) {
      console.error('Auth initialization error:', error);
      await AsyncStorage.removeItem('auth_token');
      delete axios.defaults.headers.common['Authorization'];
    } finally {
      set({ isLoading: false, isInitialized: true });
    }
  },

  login: async (email: string, password: string) => {
    try {
      set({ isLoading: true, error: null });
      console.log('Attempting login for:', email);

      const response = await apiClient.post<LoginResponse>(
        endpoints.auth.login,
        { email, password }
      );

      console.log('Login response:', response);

      if (!response.success || !response.data) {
        console.error('Login failed:', response.message);
        throw new Error(response.message || 'Login failed');
      }

      const { token, user } = response.data;
      console.log('Login successful for user:', user);
      
      await AsyncStorage.setItem('auth_token', token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;

      set({
        user,
        token,
        isLoading: false,
        error: null
      });
      return true;
    } catch (error) {
      console.error('Login error:', error);
      const message = error instanceof Error ? error.message : 'Login failed';
      set({
        error: message,
        isLoading: false
      });
      return false;
    }
  },

  signUp: async (data: SignUpData) => {
    try {
      set({ isLoading: true, error: null });
      console.log('Attempting signup with data:', { ...data, password: '[REDACTED]' });

      const signupResponse = await apiClient.post<User>(
        endpoints.auth.signup,
        data
      );

      console.log('Signup response:', signupResponse);

      if (!signupResponse.success || !signupResponse.data) {
        console.error('Signup failed:', signupResponse.message);
        return false;
      }

      console.log('Signup successful, attempting login');
      await get().login(data.email, data.password);
      return true;
    } catch (error) {
      console.error('Signup error:', error);
      const message = error instanceof Error ? error.message : 'Registration failed';
      set({
        error: message,
        isLoading: false
      });
      return false;
    }
  },

  updateAvatar: async (avatarUrl: string) => {
    try {
      set({ isLoading: true, error: null });
      console.log('Attempting to update avatar:', avatarUrl);
      
      const state = get();
      if (!state.user?.id) {
        throw new Error('User not found');
      }

      const response = await apiClient.put<User>(
        endpoints.users.avatar(state.user.id),
        { avatar: avatarUrl }
      );

      console.log('Update avatar response:', response);

      if (!response.success || !response.data) {
        console.error('Avatar update failed:', response.message);
        return false;
      }

      console.log('Avatar update successful');
      set(state => ({
        user: { ...state.user!, avatar: avatarUrl },
        isLoading: false,
        error: null
      }));

      return true;
    } catch (error) {
      console.error('Avatar update error:', error);
      const message = error instanceof Error ? error.message : 'Failed to update avatar';
      set({
        error: message,
        isLoading: false
      });
      return false;
    }
  },
  updateUserTime: async (totalActiveTime: number) => {
    try {
      const state = get();
      if (!state.user?.id) {
        throw new Error('User not found');
      }

      const response = await apiClient.put<User>(
        endpoints.users.update(state.user.id),
        {
          last_seen: new Date().toISOString(),
          total_active_time: totalActiveTime
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to update user time');
      }

      set(state => ({
        user: {
          ...state.user!,
          last_seen: response.data.last_seen,
          total_active_time: response.data.total_active_time
        }
      }));

    } catch (error) {
      console.error('Time update error:', error);
      // Don't throw error to prevent app disruption
    }
  },
  logout: async () => {
    try {
      set({ isLoading: true });
      console.log('Attempting logout');
      
      try {
        const response = await apiClient.post<void>(endpoints.auth.logout);
        console.log('Logout response:', response);
      } catch (error) {
        console.error('Logout API error:', error);
      }

      await AsyncStorage.removeItem('auth_token');
      delete axios.defaults.headers.common['Authorization'];

      console.log('Logout successful');
      set({
        user: null,
        token: null,
        isLoading: false,
        error: null
      });
    } catch (error) {
      console.error('Logout error:', error);
      set({ isLoading: false });
      // Still clear local state even if server logout fails
      await AsyncStorage.removeItem('auth_token');
      delete axios.defaults.headers.common['Authorization'];
    }
  },
}));

// Create context
const AuthContext = createContext<AuthState | undefined>(undefined);

// Provider component
export function AuthProvider({ children }: { children: ReactNode }) {
  const auth = useAuthStore();

  useEffect(() => {
    auth.initialize();
  }, []);

  return (
    <AuthContext.Provider value={auth}>
      {children}
    </AuthContext.Provider>
  );
}

// Hook for using auth context
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export default useAuthStore;