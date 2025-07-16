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
  isGuest: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  loginWithDeviceToken: (deviceToken: string) => Promise<boolean>;
  logout: () => Promise<void>;
  initialize: () => Promise<void>;
  signUp: (data: SignUpData) => Promise<boolean>;
  createGuestAccount: () => Promise<boolean>;
  updateGuestToUser: (data: SignUpData) => Promise<boolean>;
  updateUserPoints: (points: number) => Promise<void>;
  updateUserTime: (totalActiveTime: number) => Promise<void>;
  updateAvatar: (avatarUrl: string) => Promise<boolean>;
}

interface SignUpData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  avatar: string;
  device_token?: string;
  is_guest?: boolean;
}

interface LoginResponse {
  token?: string;
  access_token?: string;
  user: User;
  expires_in?: number;
}

// Create store
const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,
  isLoading: false,
  isInitialized: false,
  error: null,
  isGuest: false,

  initialize: async () => {
    try {
      set({ isLoading: true });
      const token = await AsyncStorage.getItem('auth_token');
      const deviceToken = await AsyncStorage.getItem('device_token');
      
      if (token) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        
        const response = await apiClient.get<User>(endpoints.auth.user);
        console.log('Initialize response:', response);

        if (response.success && response.data) {
          set({
            token,
            user: response.data,
            isGuest: response.data.is_guest || false,
            isInitialized: true
          });
          console.log('Successfully initialized with user:', response.data);
        } else {
          console.log('Invalid response during initialization:', response);
          await AsyncStorage.removeItem('auth_token');
          await AsyncStorage.removeItem('device_token');
          delete axios.defaults.headers.common['Authorization'];
        }
      } else if (deviceToken) {
        // Try to login with device token for returning guests
        console.log('Attempting device token login for returning guest');
        const success = await get().loginWithDeviceToken(deviceToken);
        if (!success) {
          await AsyncStorage.removeItem('device_token');
        }
      }
    } catch (error) {
      console.error('Auth initialization error:', error);
      await AsyncStorage.removeItem('auth_token');
      await AsyncStorage.removeItem('device_token');
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
        endpoints.auth.login + '?include=user.active_challenges,user.user_virtues',
        { email, password }
      );

      console.log('Login response:', response);

      if (!response.success || !response.data) {
        console.error('Login failed:', response.message);
        throw new Error(response.message || 'Login failed');
      }

      const { token, user } = response.data;
      console.log('Login successful for user:', user);
      
      if (!token) {
        console.error('No token received from login');
        throw new Error('No authentication token received');
      }
      
      await AsyncStorage.setItem('auth_token', token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;

      set({
        user,
        token,
        isGuest: user.is_guest || false,
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

  loginWithDeviceToken: async (deviceToken: string) => {
    try {
      set({ isLoading: true, error: null });
      console.log('Attempting login with device token');
      // Split deviceToken into username and password
      const [username, password] = deviceToken.split(':');
      const email = `${username}@elbiblio.com`;
      return await get().login(email, password);
    } catch (error) {
      console.error('Device token login error:', error);
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

  createGuestAccount: async () => {
    try {
      set({ isLoading: true, error: null });
      console.log('Creating guest account');

      // Generate unique username and password
      const username = `guest_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const password = Math.random().toString(36).substr(2, 15);
      
      // Create device token as username:password
      const deviceToken = `${username}:${password}`;
      const email = `${username}@elbiblio.com`;

      const guestResponse = await apiClient.post<User>(
        endpoints.auth.signup,
        {
          device_token: deviceToken,
          is_guest: true,
          first_name: 'Guest',
          last_name: 'User',
          email,
          password,
          avatar: 'https://elbiblio.com/avatars/user.png' // Default avatar
        }
      );

      console.log('Guest account response:', guestResponse);

      if (!guestResponse.success || !guestResponse.data) {
        console.error('Guest account creation failed:', guestResponse.message);
        return false;
      }

      // Store device token for future login
      await AsyncStorage.setItem('device_token', deviceToken);
      
      // Now login with the username and password to get the JWT
      const loginSuccess = await get().login(email, password);
      
      if (loginSuccess) {
        console.log('Guest account created and logged in successfully');
        return true;
      } else {
        console.error('Failed to login after guest account creation');
        return false;
      }
    } catch (error) {
      console.error('Guest account creation error:', error);
      const message = error instanceof Error ? error.message : 'Failed to create guest account';
      set({
        error: message,
        isLoading: false
      });
      return false;
    }
  },

  updateGuestToUser: async (data: SignUpData) => {
    try {
      set({ isLoading: true, error: null });
      console.log('Updating guest account to user account');

      const state = get();
      if (!state.user?.id) {
        throw new Error('No user found');
      }

      const updateResponse = await apiClient.put<User>(
        endpoints.users.update(state.user.id),
        {
          email: data.email,
          password: data.password,
          first_name: data.first_name,
          last_name: data.last_name,
          avatar: data.avatar,
          is_guest: false
        }
      );

      console.log('Guest to user update response:', updateResponse);

      if (!updateResponse.success || !updateResponse.data) {
        console.error('Guest to user update failed:', updateResponse.message);
        return false;
      }

      set({
        user: updateResponse.data,
        isGuest: false,
        isLoading: false,
        error: null
      });

      console.log('Guest account successfully updated to user account');
      return true;
    } catch (error) {
      console.error('Guest to user update error:', error);
      const message = error instanceof Error ? error.message : 'Failed to update account';
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
  updateUserPoints: async (points: number) => {
    try {
      const state = get();
      if (!state.user?.id) {
        throw new Error('User not found');
      }

      const response = await apiClient.put<User>(
        endpoints.users.update(state.user.id),
        { points }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to update user points');
      }

      set(state => ({
        user: { ...state.user!, points: response.data.points }
      }));
    } catch (error) {
      console.error('Points update error:', error);
      const message = error instanceof Error ? error.message : 'Failed to update points';
      set({
        error: message,
        isLoading: false
      });
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
      await AsyncStorage.removeItem('device_token');
      delete axios.defaults.headers.common['Authorization'];

      console.log('Logout successful');
      set({
        user: null,
        token: null,
        isGuest: false,
        isLoading: false,
        error: null
      });
    } catch (error) {
      console.error('Logout error:', error);
      set({ isLoading: false });
      // Still clear local state even if server logout fails
      await AsyncStorage.removeItem('auth_token');
      await AsyncStorage.removeItem('device_token');
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