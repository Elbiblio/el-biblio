import { create } from 'zustand';
import { createContext, useContext, ReactNode, useEffect, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ThemeVariant } from '@/theme';

// Use consistent storage keys that match App.tsx
export const STORAGE_KEYS = {
  THEME: '@app_theme',
  COLOR_MODE: 'user_color_mode',
};

// Define the state interface
interface PreferencesState {
  preferredTheme: ThemeVariant;
  colorMode: 'light' | 'dark';
  isInitialized: boolean;
}

// Define the context interface with methods
interface PreferencesContextType extends PreferencesState {
  setPreferredTheme: (theme: ThemeVariant) => Promise<void>;
  setColorMode: (mode: 'light' | 'dark') => Promise<void>;
}

// Create the internal Zustand store
const usePreferencesStore = create<
  PreferencesState & {
    setPreferredTheme: (theme: ThemeVariant) => Promise<void>;
    setColorMode: (mode: 'light' | 'dark') => Promise<void>;
  }
>((set) => ({
  preferredTheme: 'sage',
  colorMode: 'light',
  isInitialized: false,

  setPreferredTheme: async (theme: ThemeVariant) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.THEME, theme);
      set({ preferredTheme: theme });
    } catch (error) {
      console.error('Failed to save theme preference:', error);
    }
  },

  setColorMode: async (mode: 'light' | 'dark') => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.COLOR_MODE, mode);
      set({ colorMode: mode });
    } catch (error) {
      console.error('Failed to save color mode preference:', error);
    }
  },
}));

// Create the React context
const PreferencesContext = createContext<PreferencesContextType | undefined>(undefined);

// Create the provider component
export const PreferencesProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isReady, setIsReady] = useState(false);
  const store = usePreferencesStore();
  
  // Initialize preferences from storage on mount
  useEffect(() => {
    const initializePreferences = async () => {
      try {
        const [storedTheme, storedColorMode] = await Promise.all([
          AsyncStorage.getItem(STORAGE_KEYS.THEME),
          AsyncStorage.getItem(STORAGE_KEYS.COLOR_MODE),
        ]);

        const updates: Partial<PreferencesState> = { isInitialized: true };

        if (storedTheme) {
          updates.preferredTheme = storedTheme as ThemeVariant;
        }

        if (storedColorMode && (storedColorMode === 'light' || storedColorMode === 'dark')) {
          updates.colorMode = storedColorMode;
        }

        usePreferencesStore.setState(updates);
      } catch (error) {
        console.error('Failed to load preferences:', error);
        usePreferencesStore.setState({ isInitialized: true });
      } finally {
        setIsReady(true);
      }
    };
    
    initializePreferences();
  }, []);

  // Return loading state or context provider
  if (!isReady) {
    return null; // Or a loading indicator
  }

  return (
    <PreferencesContext.Provider value={store}>
      {children}
    </PreferencesContext.Provider>
  );
};

// Create a hook to use the preferences context
export const usePreferences = (): PreferencesContextType => {
  const context = useContext(PreferencesContext);
  
  if (context === undefined) {
    throw new Error('usePreferences must be used within a PreferencesProvider');
  }
  
  return context;
};

// We can still export the store for direct use if needed
export default usePreferencesStore; 