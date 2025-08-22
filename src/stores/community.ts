import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { Reflection } from '@/types';

interface CommunityState {
  lastOpenedAt: number | null;
  unreadCount: number;

  // Actions
  markOpened: () => void;
  computeUnreadFromReflections: (reflections: Reflection[]) => void;
  resetUnread: () => void;
}

export const useCommunityStore = create<CommunityState>()(
  persist(
    (set, get) => ({
      lastOpenedAt: null,
      unreadCount: 0,

      markOpened: () => set({ lastOpenedAt: Date.now(), unreadCount: 0 }),

      resetUnread: () => set({ unreadCount: 0 }),

      computeUnreadFromReflections: (reflections: Reflection[]) => {
        const lastOpened = get().lastOpenedAt;
        if (lastOpened == null) {
          // First run: don't show unread badge
          set({ unreadCount: 0 });
          return;
        }
        if (!Array.isArray(reflections) || reflections.length === 0) {
          set({ unreadCount: 0 });
          return;
        }

        const getTs = (obj: any): number => {
          const createdAt = obj?.created_at || obj?.createdAt;
          return createdAt ? new Date(createdAt).getTime() : 0;
        };

        const count = reflections.reduce((acc, r: any) => {
          let total = acc;
          // Reflection
          if (getTs(r) > lastOpened) total += 1;

          // Comments (if included)
          const comments: any[] = Array.isArray(r?.comments) ? r.comments : [];
          for (const c of comments) {
            if (getTs(c) > lastOpened) total += 1;
            // Replies (if included)
            const replies: any[] = Array.isArray(c?.replies) ? c.replies : [];
            for (const rep of replies) {
              if (getTs(rep) > lastOpened) total += 1;
            }
          }
          return total;
        }, 0);
        set({ unreadCount: count });
      },
    }),
    {
      name: 'community-store',
      partialize: (state) => ({ lastOpenedAt: state.lastOpenedAt, unreadCount: state.unreadCount }),
    }
  )
);
