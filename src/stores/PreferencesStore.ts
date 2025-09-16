import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { ThemeVariant } from '@/theme';

export const STORAGE_KEYS = {
  THEME: '@app_theme',
  COLOR_MODE: 'user_color_mode',
} as const;

export type ColorMode = 'light' | 'dark';

interface PreferencesState {
  preferredTheme: ThemeVariant;
  colorMode: ColorMode;
  isInitialized: boolean;
}

class PreferencesStore {
  // Store state
  state: PreferencesState = {
    preferredTheme: 'sage',
    colorMode: 'light',
    isInitialized: false,
  };
  
  // Common store properties
  isLoading = false;
  error: string | null = null;
  private storageKey = 'user_preferences';

  constructor() {
    makeAutoObservable(this);
    this.initialize();
  }

  private setLoading(loading: boolean) {
    runInAction(() => {
      this.isLoading = loading;
    });
  }

  private setError(error: string | null) {
    runInAction(() => {
      this.error = error;
    });
  }

  private async saveToStorage() {
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.setError('Failed to save data');
    }
  }

  async initialize() {
    if (this.state.isInitialized) return;
    
    try {
      this.setLoading(true);
      
      const [savedTheme, savedColorMode] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEYS.THEME),
        AsyncStorage.getItem(STORAGE_KEYS.COLOR_MODE),
      ]);

      runInAction(() => {
        if (savedTheme) {
          this.state.preferredTheme = savedTheme as ThemeVariant;
        }
        if (savedColorMode) {
          this.state.colorMode = savedColorMode as ColorMode;
        }
        this.state.isInitialized = true;
      });
      
      await this.saveToStorage();
    } catch (error) {
      console.error('Failed to initialize preferences:', error);
      this.setError('Failed to load preferences');
    } finally {
      this.setLoading(false);
    }
  }

  setPreferredTheme = async (theme: ThemeVariant) => {
    try {
      this.setLoading(true);
      await AsyncStorage.setItem(STORAGE_KEYS.THEME, theme);
      
      runInAction(() => {
        this.state.preferredTheme = theme;
      });
      
      await this.saveToStorage();
    } catch (error) {
      console.error('Failed to save theme preference:', error);
      this.setError('Failed to save theme preference');
      throw error;
    } finally {
      this.setLoading(false);
    }
  };

  setColorMode = async (mode: ColorMode) => {
    try {
      this.setLoading(true);
      await AsyncStorage.setItem(STORAGE_KEYS.COLOR_MODE, mode);
      
      runInAction(() => {
        this.state.colorMode = mode;
      });
      
      await this.saveToStorage();
    } catch (error) {
      console.error('Failed to save color mode preference:', error);
      this.setError('Failed to save color mode preference');
      throw error;
    } finally {
      this.setLoading(false);
    }
  };

  // Getters for computed values
  get preferredTheme(): ThemeVariant {
    return this.state.preferredTheme;
  }

  get colorMode(): ColorMode {
    return this.state.colorMode;
  }

  get isInitialized(): boolean {
    return this.state.isInitialized;
  }
}

// Create a singleton instance
export const preferencesStore = new PreferencesStore();

// For backward compatibility
export const usePreferences = () => preferencesStore;
export default preferencesStore;
