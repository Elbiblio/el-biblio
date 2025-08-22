import { create } from 'zustand';
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createContext, useContext, useEffect, ReactNode } from 'react';
import { apiClient, endpoints } from '@/api/client';
import { User, UserRole } from '@/types';

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
  isGuest: boolean;
  isEmailVerified: boolean;
  userRole: UserRole;
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
  refreshToken: () => Promise<boolean>;
  verifyEmail: (token: string) => Promise<boolean>;
  resendVerificationEmail: () => Promise<boolean>;
  forgotPassword: (email: string) => Promise<boolean>;
  resetPassword: (token: string, password: string) => Promise<boolean>;
  updateUserProfile: (data: Partial<User>) => Promise<boolean>;
  checkGuestStatus: (email: string) => boolean;
}

interface SignUpData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  avatar?: string;
  primary_language?: string;
  english_fluency?: number;
  date_of_birth?: string;
  denomination?: string;
}

interface LoginResponse {
  token: string;
  user: User;
}

// Create store
const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: null,
  isLoading: false,
  isInitialized: false,
  error: null,
  isGuest: false,
  isEmailVerified: false,
  userRole: UserRole.User,

  checkGuestStatus: (email: string) => {
    return email.endsWith('@elbiblio.com');
  },

  initialize: async () => {
    try {
      set({ isLoading: true });
      const token = await AsyncStorage.getItem('auth_token');
      const deviceToken = await AsyncStorage.getItem('device_token');
      
      if (token) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        
        const response = await apiClient.get<User>(endpoints.auth.user, {
          include: ['userVirtues', 'activeChallenges']
        });
        console.log('Initialize response:', response);

        if (response.success && response.data) {
          const user = response.data;
          const isGuest = get().checkGuestStatus(user.email || '');
          
          set({
            token,
            user,
            isGuest,
            isEmailVerified: !!user.email_verified_at,
            userRole: user.role,
            isInitialized: true
          });
          console.log('Successfully initialized with user:', user);
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
        endpoints.auth.login,
        { email, password },
        {
          params: {
            include: 'userVirtues,activeChallenges'
          }
        }
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

      const isGuest = get().checkGuestStatus(user.email || '');

      set({
        user,
        token,
        isGuest,
        isEmailVerified: !!user.email_verified_at,
        userRole: user.role,
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
      console.log('Attempting signup for:', data.email);

      const response = await apiClient.post<User>(
        endpoints.auth.signup,
        data
      );

      console.log('Signup response:', response);

      if (!response.success || !response.data) {
        console.error('Signup failed:', response.message);
        throw new Error(response.message || 'Signup failed');
      }

      const user = response.data;
      console.log('Signup successful for user:', user);

      // Auto-login after successful signup
      const loginSuccess = await get().login(data.email, data.password);
      
      if (loginSuccess) {
        console.log('Auto-login after signup successful');
        return true;
      } else {
        console.error('Auto-login after signup failed');
        return false;
      }
    } catch (error) {
      console.error('Signup error:', error);
      const message = error instanceof Error ? error.message : 'Signup failed';
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
          email,
          password,
          first_name: 'Guest',
          last_name: 'User',
          avatar: 'https://elbiblio.com/avatars/user.png', // Default avatar
          primary_language: 'en',
          is_guest: true
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
      const state = get();
      
      if (!state.user?.id) {
        throw new Error('User not found');
      }

      console.log('Updating guest to user:', data.email);

      const response = await apiClient.put<User>(
        endpoints.users.update(state.user.id),
        {
          ...data,
          is_guest: false
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to update guest to user');
      }

      const updatedUser = response.data;
      const isGuest = get().checkGuestStatus(updatedUser.email || '');

      set({
        user: updatedUser,
        isGuest,
        isEmailVerified: !!updatedUser.email_verified_at,
        userRole: updatedUser.role,
        isLoading: false,
        error: null
      });

      console.log('Successfully updated guest to user');
      return true;
    } catch (error) {
      console.error('Update guest to user error:', error);
      const message = error instanceof Error ? error.message : 'Failed to update account';
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
        {
          points: (parseInt(state.user.points) + points).toString()
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to update user points');
      }

      set(state => ({
        user: {
          ...state.user!,
          points: response.data.points
        }
      }));

    } catch (error) {
      console.error('Points update error:', error);
      // Don't throw error to prevent app disruption
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

  updateAvatar: async (avatarUrl: string) => {
    try {
      const state = get();
      if (!state.user?.id) {
        throw new Error('User not found');
      }

      const response = await apiClient.put<User>(
        endpoints.users.avatar(state.user.id),
        { avatar: avatarUrl }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to update avatar');
      }

      set(state => ({
        user: {
          ...state.user!,
          avatar: response.data.avatar
        }
      }));

      return true;
    } catch (error) {
      console.error('Avatar update error:', error);
      return false;
    }
  },

  refreshToken: async () => {
    try {
      const response = await apiClient.post<{ token: string }>(
        endpoints.auth.refresh
      );

      if (response.success && response.data.token) {
        const newToken = response.data.token;
        await AsyncStorage.setItem('auth_token', newToken);
        axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`;
        
        set({ token: newToken });
        return true;
      }
      return false;
    } catch (error) {
      console.error('Token refresh error:', error);
      return false;
    }
  },

  verifyEmail: async (token: string) => {
    try {
      const response = await apiClient.post<{ success: boolean }>(
        endpoints.auth.verifyEmail,
        { token }
      );

      if (response.success) {
        set(state => ({
          user: state.user ? {
            ...state.user,
            email_verified_at: new Date().toISOString()
          } : null,
          isEmailVerified: true
        }));
        return true;
      }
      return false;
    } catch (error) {
      console.error('Email verification error:', error);
      return false;
    }
  },

  resendVerificationEmail: async () => {
    try {
      const state = get();
      if (!state.user?.email) {
        throw new Error('User email not found');
      }

      const response = await apiClient.post<{ success: boolean }>(
        endpoints.auth.verifyEmail,
        { email: state.user.email }
      );

      return response.success;
    } catch (error) {
      console.error('Resend verification email error:', error);
      return false;
    }
  },

  forgotPassword: async (email: string) => {
    try {
      const response = await apiClient.post<{ success: boolean }>(
        endpoints.auth.forgotPassword,
        { email }
      );

      return response.success;
    } catch (error) {
      console.error('Forgot password error:', error);
      return false;
    }
  },

  resetPassword: async (token: string, password: string) => {
    try {
      const response = await apiClient.post<{ success: boolean }>(
        endpoints.auth.resetPassword,
        { token, password }
      );

      return response.success;
    } catch (error) {
      console.error('Reset password error:', error);
      return false;
    }
  },

  updateUserProfile: async (data: Partial<User>) => {
    try {
      const state = get();
      if (!state.user?.id) {
        throw new Error('User not found');
      }

      const response = await apiClient.put<User>(
        endpoints.users.update(state.user.id),
        data
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to update profile');
      }

      const updatedUser = response.data;
      const isGuest = get().checkGuestStatus(updatedUser.email || '');

      set({
        user: updatedUser,
        isGuest,
        isEmailVerified: !!updatedUser.email_verified_at,
        userRole: updatedUser.role
      });

      return true;
    } catch (error) {
      console.error('Profile update error:', error);
      return false;
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
        isEmailVerified: false,
        userRole: UserRole.User,
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
export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const auth = useAuthStore();

  useEffect(() => {
    auth.initialize();
  }, []);

  return (
    <AuthContext.Provider value={auth}>
      {children}
    </AuthContext.Provider>
  );
};

// Hook to use auth context
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default useAuthStore;