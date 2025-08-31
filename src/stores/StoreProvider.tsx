import React, { createContext, useContext } from 'react';
import { authStore } from './AuthStore';
import { meditationStore } from './MeditationStore';
import { matchStore } from './MatchStore';
import { preferencesStore } from './PreferencesStore';
import { ReflectionStore } from './ReflectionStore';
import { LeaderboardStore } from './LeaderboardStore';
import { VirtueStore } from './VirtueStore';
import { VerseStore } from './VerseStore';
import { PrayerRequestsStore } from './PrayerRequestsStore';
import { WordHubsStore } from './WordHubsStore';
import { GameStore } from './GameStore';

class RootStore {
  authStore = authStore;
  meditationStore = meditationStore;
  matchStore = matchStore;
  preferencesStore = preferencesStore;
  reflectionStore: ReflectionStore;
  leaderboardStore: LeaderboardStore;
  virtueStore: VirtueStore;
  verseStore: VerseStore;
  prayerRequestsStore: PrayerRequestsStore;
  wordHubsStore: WordHubsStore;
  gameStore: GameStore;

  constructor() {
    this.reflectionStore = new ReflectionStore();
    this.leaderboardStore = new LeaderboardStore();
    this.virtueStore = new VirtueStore();
    this.verseStore = new VerseStore();
    this.prayerRequestsStore = new PrayerRequestsStore();
    this.wordHubsStore = new WordHubsStore();
    this.gameStore = new GameStore();
  }
}

const StoreContext = createContext<RootStore | null>(null);

export const StoreProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const rootStore = React.useMemo(() => new RootStore(), []);

  return (
    <StoreContext.Provider value={rootStore}>
      {children}
    </StoreContext.Provider>
  );
};

export const useStores = (): RootStore => {
  const context = useContext(StoreContext);
  if (!context) {
    throw new Error('useStores must be used within a StoreProvider');
  }
  return context;
};

// Individual store hooks for convenience
export const useAuthStore = () => useStores().authStore;
export const useMeditationStore = () => useStores().meditationStore;
export const useMatchStore = () => useStores().matchStore;
export const usePreferencesStore = () => useStores().preferencesStore;
export const useReflectionStore = () => useStores().reflectionStore;
export const useLeaderboardStore = () => useStores().leaderboardStore;
export const useVirtueStore = () => useStores().virtueStore;
export const useVerseStore = () => useStores().verseStore;
export const usePrayerRequestsStore = () => useStores().prayerRequestsStore;
export const useWordHubsStore = () => useStores().wordHubsStore;
export const useGameStore = () => useStores().gameStore;
