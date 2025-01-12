import { create } from 'zustand';
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createContext, useContext, useEffect, ReactNode } from 'react';

// Types
interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  avatar: string;
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

      const response = await axios.post('https://api.elbiblio.com/api/auth/login', {
        email,
        password
      });

      const { token, expires_in } = response.data;

      // Save token
      await AsyncStorage.setItem('auth_token', token);
      
      // Set default auth header
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;

      // In production, you'd fetch user data here
      // For now use dummy data
      set({
        token,
        user: {
          id: '1',
          email: 'user@elbiblio.com',
          first_name: 'Test',
          last_name: 'User',
          avatar: 'https://via.placeholder.com/150'
        },
        isLoading: false
      });

    } catch (error) {
      console.error('Login error:', error);
      set({ 
        error: 'Login failed. Please check your credentials.',
        isLoading: false 
      });
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
  }
}));

// Create context
const AuthContext = createContext<AuthState | undefined>(undefined);

// Provider component
export function AuthProvider({ children }: { children: ReactNode }) {
  const auth = useAuthStore();

  useEffect(() => {
    // Auto-login with default user in development
    if (!auth.isInitialized) {
      auth.login('user@elbiblio.com', 'password');
    } else {
      auth.initialize();
    }
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