import React, { createContext, useContext } from 'react';
import { Theme, ThemeVariant, defaultTheme, getTheme } from '../theme';
import { useThemeStore } from '../theme/store';

interface ThemeContextType {
  theme: Theme;
  setThemeVariant: (variant: ThemeVariant) => void;
}

const ThemeContext = createContext<ThemeContextType>({
  theme: defaultTheme,
  setThemeVariant: () => null,
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

  // Sync initial theme with store
  React.useEffect(() => {
    setStoreTheme(initialTheme);
  }, [initialTheme]);

  const setThemeVariant = React.useCallback((variant: ThemeVariant) => {
    const newTheme = getTheme(variant);
    setStoreTheme(newTheme); // Sync with store
    onThemeChange?.(variant);
  }, [onThemeChange, setStoreTheme]);

  const value = React.useMemo(() => ({
    theme: currentTheme,
    setThemeVariant,
  }), [currentTheme, setThemeVariant]);

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
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