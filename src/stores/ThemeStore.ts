import { makeAutoObservable, runInAction } from 'mobx';
import { Theme, defaultTheme } from '../theme';
import { BaseStore } from './BaseStore';

class ThemeStore extends BaseStore<{ current: Theme }> {
  constructor() {
    super({ current: defaultTheme }, 'theme_preferences');
    makeAutoObservable(this);
  }

  setTheme(theme: Theme) {
    runInAction(() => {
      this.state.current = theme;
    });
    this.saveToStorage();
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
