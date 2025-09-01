import React, { createContext, useContext } from 'react';
import { Theme, ThemeVariant, defaultTheme, getTheme } from '../theme';
import { appStore } from '@/stores/appStore';

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
  const [theme, setTheme] = React.useState<Theme>(initialTheme);
  const { hasCompletedWelcome, setHasCompletedWelcome, initializeWelcomeState } = appStore;

  React.useEffect(() => {
    setTheme(initialTheme);
    initializeWelcomeState();
  }, [initialTheme, initializeWelcomeState]);

  const setThemeVariant = React.useCallback((variant: ThemeVariant) => {
    const newTheme = getTheme(variant);
    setTheme(newTheme);
    if (onThemeChange) onThemeChange(variant);
  }, [onThemeChange]);

  const completeWelcome = React.useCallback(async () => {
    await setHasCompletedWelcome(true);
  }, [setHasCompletedWelcome]);

  const value = React.useMemo(() => ({
    theme,
    setThemeVariant,
    hasCompletedWelcome,
    completeWelcome,
  }), [theme, setThemeVariant, hasCompletedWelcome, completeWelcome]);

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