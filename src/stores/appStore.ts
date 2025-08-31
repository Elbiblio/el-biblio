import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';

class AppStore {
  hasCompletedWelcome = false;

  constructor() {
    makeAutoObservable(this);
    this.initializeWelcomeState();
  }

  setHasCompletedWelcome = async (completed: boolean) => {
    try {
      await AsyncStorage.setItem('welcomeScreen', completed ? 'completed' : '');
      runInAction(() => {
        this.hasCompletedWelcome = completed;
      });
    } catch (error) {
      console.error('Error setting welcome state:', error);
    }
  };

  initializeWelcomeState = async () => {
    try {
      const welcomeScreen = await AsyncStorage.getItem('welcomeScreen');
      const hasCompleted = welcomeScreen === 'completed';
      runInAction(() => {
        this.hasCompletedWelcome = hasCompleted;
      });
    } catch (error) {
      console.error('Error initializing welcome state:', error);
      runInAction(() => {
        this.hasCompletedWelcome = false;
      });
    }
  };
}

export const appStore = new AppStore();