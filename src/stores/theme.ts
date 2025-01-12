import { Theme, defaultTheme } from './../theme';
import { create } from 'zustand';

interface ThemeStore {
  current: Theme;
  setTheme: (theme: Theme) => void;
}

export const useThemeStore = create<ThemeStore>((set) => ({
  current: defaultTheme,
  setTheme: (theme: Theme) => set({ current: theme })
}));

// Sync helper for non-React code
export const getThemeStore = () => useThemeStore.getState();

// Direct theme getter for static styles
export const getCurrentTheme = (): Theme => getThemeStore().current;