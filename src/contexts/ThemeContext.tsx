import React, { createContext, useContext } from 'react';
import { Theme, ThemeVariant, defaultTheme, getTheme } from '../theme';
import { useThemeStore } from '../theme/store';
import { useAppStore } from '@/stores/appStore';

interface ThemeContextType {
  theme: Theme;
  setThemeVariant: (variant: ThemeVariant) => void;
  hasCompletedWelcome: boolean;
  completeWelcome: () => Promise<void>;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: defaultTheme,
  setThemeVariant: () => null,
  hasCompletedWelcome: false,
  completeWelcome: async () => {},
});

interface ThemeProviderProps {
  children: React.ReactNode;
  initialTheme?: Theme;
  onThemeChange?: (variant: ThemeVariant) => void;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({
  children,
  initialTheme = defaultTheme,
  onThemeChange,
}) => {
  const setStoreTheme = useThemeStore(state => state.setTheme);
  const currentTheme = useThemeStore(state => state.current);
  const hasCompletedWelcome = useAppStore(state => state.hasCompletedWelcome);
  const setHasCompletedWelcome = useAppStore(state => state.setHasCompletedWelcome);
  const initializeWelcomeState = useAppStore(state => state.initializeWelcomeState);

  // Sync initial theme with store
  React.useEffect(() => {
    setStoreTheme(initialTheme);
    initializeWelcomeState();
  }, [initialTheme]);

  const setThemeVariant = React.useCallback((variant: ThemeVariant) => {
    const newTheme = getTheme(variant);
    setStoreTheme(newTheme);
    onThemeChange?.(variant);
  }, [onThemeChange, setStoreTheme]);

  const completeWelcome = React.useCallback(async () => {
    await setHasCompletedWelcome(true);
  }, [setHasCompletedWelcome]);

  const value = React.useMemo(() => ({
    theme: currentTheme,
    setThemeVariant,
    hasCompletedWelcome,
    completeWelcome,
  }), [currentTheme, setThemeVariant, hasCompletedWelcome, completeWelcome]);

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useWelcomeState = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useWelcomeState must be used within a ThemeProvider');
  }
  return {
    hasCompletedWelcome: context.hasCompletedWelcome,
    completeWelcome: context.completeWelcome,
  };
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context.theme;
};

export const useThemeVariant = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useThemeVariant must be used within a ThemeProvider');
  }
  return context.setThemeVariant;
};