import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';

export class BaseStore<T> {
  protected storageKey: string | null = null;
  protected state: T;
  isLoading = false;
  error: string | null = null;

  constructor(initialState: T, storageKey?: string) {
    this.state = initialState;
    this.storageKey = storageKey || null;
    makeAutoObservable(this);
    
    if (this.storageKey) {
      this.loadFromStorage();
    }
  }

  protected async loadFromStorage() {
    if (!this.storageKey) return;
    
    try {
      this.setLoading(true);
      const stored = await AsyncStorage.getItem(this.storageKey);
      if (stored) {
        runInAction(() => {
          this.state = JSON.parse(stored);
        });
      }
    } catch (error) {
      console.error(`Error loading ${this.storageKey} from storage:`, error);
      this.setError('Failed to load data');
    } finally {
      this.setLoading(false);
    }
  }

  protected async saveToStorage() {
    if (!this.storageKey) return;
    
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.setError('Failed to save data');
    }
  }

  protected setLoading(loading: boolean) {
    runInAction(() => {
      this.isLoading = loading;
    });
  }

  protected setError(error: string | null) {
    runInAction(() => {
      this.error = error;
    });
  }

  // Clear the store's state
  clear() {
    runInAction(() => {
      this.state = {} as T;
      this.error = null;
    });
    
    if (this.storageKey) {
      AsyncStorage.removeItem(this.storageKey).catch(console.error);
    }
  }

  // Get the current state
  get currentState(): T {
    return this.state;
  }
}
