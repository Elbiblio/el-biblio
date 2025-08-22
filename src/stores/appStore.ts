import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface AppState {
  hasCompletedWelcome: boolean;
  setHasCompletedWelcome: (completed: boolean) => Promise<void>;
  initializeWelcomeState: () => Promise<void>;
}

export const useAppStore = create<AppState>((set) => ({
  hasCompletedWelcome: false,
  setHasCompletedWelcome: async (completed) => {
    await AsyncStorage.setItem('welcomeScreen', completed ? 'completed' : '');
    set({ hasCompletedWelcome: completed });
  },
  initializeWelcomeState: async () => {
    try {
      const welcomeScreen = await AsyncStorage.getItem('welcomeScreen');
      const hasCompleted = welcomeScreen === 'completed';
      set({ hasCompletedWelcome: hasCompleted });
    } catch (error) {
      console.error('Error initializing welcome state:', error);
      set({ hasCompletedWelcome: false });
    }
  },
}));