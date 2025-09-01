import { makeAutoObservable, runInAction } from 'mobx';
import { Reflection } from '@/types';
import { BaseStore } from './BaseStore';

interface CommunityState {
  lastOpenedAt: number | null;
  unreadCount: number;
}

export class CommunityStore extends BaseStore<CommunityState> {
  constructor() {
    super({
      lastOpenedAt: null,
      unreadCount: 0,
    }, 'community_store');
    
    makeAutoObservable(this);
  }

  markOpened = () => {
    runInAction(() => {
      this.state.lastOpenedAt = Date.now();
      this.state.unreadCount = 0;
      this.saveToStorage();
    });
  };

  resetUnread = () => {
    runInAction(() => {
      this.state.unreadCount = 0;
      this.saveToStorage();
    });
  };

  computeUnreadFromReflections = (reflections: Reflection[]) => {
    const lastOpened = this.state.lastOpenedAt;
    
    if (lastOpened == null) {
      // First run: don't show unread badge
      runInAction(() => {
        this.state.unreadCount = 0;
      });
      return;
    }
    
    if (!Array.isArray(reflections) || reflections.length === 0) {
      runInAction(() => {
        this.state.unreadCount = 0;
      });
      return;
    }

    const getTs = (obj: any): number => {
      const createdAt = obj?.created_at || obj?.createdAt;
      return createdAt ? new Date(createdAt).getTime() : 0;
    };

    let count = 0;
    
    for (const r of reflections) {
      // Check reflection
      if (getTs(r) > lastOpened) count += 1;

      // Check comments (if included)
      const comments: any[] = Array.isArray(r?.comments) ? r.comments : [];
      for (const c of comments) {
        if (getTs(c) > lastOpened) count += 1;
      }
    }

    runInAction(() => {
      this.state.unreadCount = count;
      this.saveToStorage();
    });
  };

  // Getters
  get unreadCount(): number {
    return this.state.unreadCount;
  }

  get hasUnread(): boolean {
    return this.state.unreadCount > 0;
  }
}

// Create a singleton instance
export const communityStore = new CommunityStore();

// For backward compatibility
export const useCommunityStore = () => communityStore;
export default communityStore;
