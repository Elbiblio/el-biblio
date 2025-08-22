import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type RankTimeframe = 'all' | 'day' | 'week' | 'month';

interface GameBadgeState {
  lastKnownRank: Partial<Record<RankTimeframe, number>>;
  shouldShowBadge: boolean;
  updateRank: (timeframe: RankTimeframe, newRank: number | null | undefined) => void;
  clearBadge: () => void;
}

export const useGameBadgeStore = create<GameBadgeState>()(
  persist(
    (set, get) => ({
      lastKnownRank: {},
      shouldShowBadge: false,
      updateRank: (timeframe, newRank) => {
        if (!newRank || newRank <= 0) return; // ignore invalid ranks
        const prev = get().lastKnownRank[timeframe];
        if (typeof prev === 'number' && prev !== newRank) {
          set({ shouldShowBadge: true });
        }
        set(state => ({
          lastKnownRank: { ...state.lastKnownRank, [timeframe]: newRank },
        }));
      },
      clearBadge: () => set({ shouldShowBadge: false }),
    }),
    {
      name: 'game-badge-store',
      partialize: (state) => ({ lastKnownRank: state.lastKnownRank, shouldShowBadge: state.shouldShowBadge }),
    }
  )
);
