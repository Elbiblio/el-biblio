import { makeAutoObservable, runInAction } from 'mobx';
import { BaseStore } from './BaseStore';

export type RankTimeframe = 'all' | 'day' | 'week' | 'month';

interface GameBadgeState {
  lastKnownRank: Partial<Record<RankTimeframe, number>>;
  shouldShowBadge: boolean;
}

class GameBadgeStore extends BaseStore<GameBadgeState> {
  constructor() {
    super({
      lastKnownRank: {},
      shouldShowBadge: false,
    }, 'game_badge_store');
    
    makeAutoObservable(this);
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
