import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Theme, defaultTheme } from '../theme';

class ThemeStore {
  state: { current: Theme } = { current: defaultTheme };

  // Common store props
  isLoading = false;
  error: string | null = null;
  private storageKey = 'theme_preferences';

  constructor() {
    this.state = { current: defaultTheme };
    this.storageKey = 'theme_preferences';
    
    makeAutoObservable(this);
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading theme store from storage:', error);
    });
  }

  private setLoading = (value: boolean) => {
    this.isLoading = value;
  };

  private setError = (message: string | null) => {
    this.error = message;
  };

  private async saveToStorage() {
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }

  async setTheme(theme: Theme) {
    runInAction(() => {
      this.state.current = theme;
    });
    await this.saveToStorage();
  }

  // Get the current theme
  get current(): Theme {
    return this.state.current;
  }
}

// Create a singleton instance
export const themeStore = new ThemeStore();

// For backward compatibility
export const useThemeStore = () => themeStore;
export const getThemeStore = () => themeStore;
