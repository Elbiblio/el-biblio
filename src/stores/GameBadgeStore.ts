import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';

export type RankTimeframe = 'all' | 'day' | 'week' | 'month';

interface GameBadgeState {
  lastKnownRank: Partial<Record<RankTimeframe, number>>;
  shouldShowBadge: boolean;
}

class GameBadgeStore {
  state: GameBadgeState = {
    lastKnownRank: {},
    shouldShowBadge: false,
  };

  isLoading = false;
  error: string | null = null;
  private storageKey = 'game_badge_store';

  constructor() {
    makeAutoObservable(this);
  }

  private async saveToStorage() {
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }

  updateRank = (timeframe: RankTimeframe, newRank: number | null | undefined) => {
    if (!newRank || newRank <= 0) return; // ignore invalid ranks
    
    const prevRank = this.state.lastKnownRank[timeframe];
    
    runInAction(() => {
      // Update the last known rank
      this.state.lastKnownRank = {
        ...this.state.lastKnownRank,
        [timeframe]: newRank,
      };
      
      // Show badge if rank has improved
      if (typeof prevRank === 'number' && prevRank !== newRank) {
        this.state.shouldShowBadge = true;
      }
      
      // Save to storage
      this.saveToStorage();
    });
  };

  clearBadge = () => {
    runInAction(() => {
      this.state.shouldShowBadge = false;
      this.saveToStorage();
    });
  };

  // Getters
  get shouldShowBadge(): boolean {
    return this.state.shouldShowBadge;
  }

  getLastKnownRank(timeframe: RankTimeframe): number | undefined {
    return this.state.lastKnownRank[timeframe];
  }
}

// Create a singleton instance
export const gameBadgeStore = new GameBadgeStore();

// For backward compatibility
export const useGameBadgeStore = () => gameBadgeStore;
export default gameBadgeStore;
