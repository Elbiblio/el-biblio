import { create } from 'zustand';
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createContext, useContext, useEffect, ReactNode } from 'react';
import * as ImagePicker from 'expo-image-picker';
import { toast } from 'sonner-native';
import { apiClient, endpoints } from '@/api/client';

// Types
interface User {
  id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  display_name?: string | null;
  avatar: string | null;
  points?: number;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  initialize: () => Promise<void>;
  signUp: (data: SignUpData) => Promise<void>;
  updateAvatar: (avatarUrl: string) => Promise<void>;
}

interface SignUpData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  avatar_url: string;
}

interface ApiResponse {
  success: boolean;
  data: User;
  message: string;
}

// Create store
const useAuthStore = create<AuthState>((set) => ({
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
        // Set default auth header
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;

        // Here you would typically validate token and get user info
        // For now we'll use dummy user data
        set({
          token,
          user: {
            id: '1',
            email: 'user@elbiblio.com',
            first_name: 'Test',
            last_name: 'User',
            points: 0,
            avatar: 'https://via.placeholder.com/150'
          },
          isInitialized: true
        });
      }
    } catch (error) {
      console.error('Auth initialization error:', error);
    } finally {
      set({ isLoading: false, isInitialized: true });
    }
  },

  login: async (email: string, password: string) => {
    try {
      set({ isLoading: true, error: null });

      const response = await apiClient.post<{ token: string; user: User }>(
        endpoints.auth.login,
        { email, password }
      );

      if (!response.success) {
        throw new Error(response.message);
      }

      const { token, user } = response.data;
      await AsyncStorage.setItem('auth_token', token);

      set({
        user,
        token,
        isLoading: false,
        error: null
      });

      toast.success('Welcome back!');

    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Login failed',
        isLoading: false
      });
      throw error;
    }
  },

  signUp: async (data: SignUpData) => {
    try {
      set({ isLoading: true, error: null });

      const response = await apiClient.post<User>(
        endpoints.auth.signup,
        data
      );

      if (!response.success) {
        throw new Error(response.message);
      }

      // Auto login after signup
      await useAuth().login(data.email, data.password);

    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Registration failed',
        isLoading: false
      });
      throw error;
    }
  },

  updateAvatar: async (avatarUrl: string) => {
    try {
      set({ isLoading: true, error: null });

      const { user } = useAuth();
      if (!user?.id) throw new Error('User not found');

      const response = await apiClient.put<User>(
        endpoints.users.avatar(user.id),
        { avatar_url: avatarUrl }
      );

      if (!response.success) {
        throw new Error(response.message);
      }

      set({
        user: response.data,
        isLoading: false,
        error: null
      });

      toast.success('Avatar updated successfully');

    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to update avatar',
        isLoading: false
      });
      throw error;
    }
  },

  logout: async () => {
    try {
      set({ isLoading: true });

      // Clear token
      await AsyncStorage.removeItem('auth_token');
      delete axios.defaults.headers.common['Authorization'];

      set({
        user: null,
        token: null,
        isLoading: false
      });
    } catch (error) {
      console.error('Logout error:', error);
      set({ isLoading: false });
    }
  },
}));

// Create context
const AuthContext = createContext<AuthState | undefined>(undefined);

// Provider component
export function AuthProvider({ children }: { children: ReactNode }) {
  const auth = useAuthStore();

  // useEffect(() => {
  //   // Auto-login with default user in development
  //   if (!auth.isInitialized) {
  //     auth.login('user@elbiblio.com', 'password');
  //   } else {
  //     auth.initialize();
  //   }
  // }, []);

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