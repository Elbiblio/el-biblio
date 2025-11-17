import { makeAutoObservable, runInAction } from 'mobx';
import { apiClient, endpoints, APIResponse } from '@/api/client';
import { useAuthStore } from './StoreProvider';

export type FeatureSuggestionStatus = 'proposed' | 'planned' | 'accepted' | 'in_progress' | 'shipped' | 'rejected';

export interface FeatureSuggestion {
  id: string;
  title: string;
  description: string;
  tags: string[];
  createdBy: { id: string; name?: string | null };
  createdAt: string;
  votesCount: number;
  status: FeatureSuggestionStatus;
  plannedAt?: string | null;
  acceptedAt?: string | null;
  eta?: string | null;
  adminNotes?: string | null;
  updatedAt?: string | null;
}

const FEATURE_SUGGESTIONS_ENABLED = true;
const USE_FEATURE_SUGGESTIONS_MOCK = true;

const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));

const mockData: FeatureSuggestion[] = [
  {
    id: 'fs-1',
    title: 'Daily streak heatmap',
    description: 'Visualize consistency with a calendar heatmap. Tap days to view activity.',
    tags: ['engagement', 'visualization'],
    createdBy: { id: 'u1', name: 'System' },
    createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
    votesCount: 67,
    status: 'proposed',
  },
  {
    id: 'fs-2',
    title: 'Offline reading packs',
    description: 'Download a pack for offline reading with notes sync later.',
    tags: ['offline', 'bible'],
    createdBy: { id: 'u2', name: 'System' },
    createdAt: new Date(Date.now() - 6 * 86400000).toISOString(),
    votesCount: 102,
    status: 'planned',
    plannedAt: new Date(Date.now() - 86400000).toISOString(),
  },
];

export class FeatureSuggestionsStore {
  enabled = FEATURE_SUGGESTIONS_ENABLED;
  isLoading = false;
  error: string | null = null;

  items: FeatureSuggestion[] = [];
  myVotes = new Set<string>();

  constructor() {
    makeAutoObservable(this, {}, { autoBind: true });
  }

  canUseFeature(user: any): boolean {
    if (!this.enabled) return false;
    if (!user) return false;
    if ((user as any)?.is_guest) return false;
    return true;
  }

  canSubmit(user: any): boolean {
    return this.canUseFeature(user) && Number(user?.total_points || 0) >= 1000;
  }

  canVote(user: any): boolean {
    return this.canUseFeature(user) && Number(user?.total_points || 0) >= 100;
  }

  async fetchSuggestions(): Promise<void> {
    if (!this.enabled) return;
    this.isLoading = true;
    this.error = null;
    try {
      if (USE_FEATURE_SUGGESTIONS_MOCK) {
        await delay(250);
        runInAction(() => {
          this.items = [...mockData];
        });
      } else {
        const res: APIResponse<{ items: FeatureSuggestion[] }> = await apiClient.get((endpoints as any).featureSuggestions.list);
        if (res.success) {
          runInAction(() => {
            this.items = (res.data as any)?.items ?? [];
          });
        } else {
          throw new Error(res.message || 'Failed to fetch');
        }
      }
    } catch (e: any) {
      this.error = e?.message || 'Failed to load feature suggestions';
    } finally {
      this.isLoading = false;
    }
  }

  async createSuggestion(user: any, payload: { title: string; description: string; tags?: string[] }) {
    if (!this.canSubmit(user)) throw new Error('You need at least 1000 points to suggest a feature.');
    if (!payload?.title?.trim() || !payload?.description?.trim()) throw new Error('Title and description are required.');
    const now = new Date().toISOString();
    const newItem: FeatureSuggestion = {
      id: `fs-${Date.now()}`,
      title: payload.title.trim().slice(0, 120),
      description: payload.description.trim().slice(0, 10000),
      tags: (payload.tags || []).slice(0, 5),
      createdBy: { id: String(user?.id || 'me'), name: (user?.name || user?.email || null) },
      createdAt: now,
      votesCount: 0,
      status: 'proposed',
    };

    if (USE_FEATURE_SUGGESTIONS_MOCK) {
      await delay(200);
      runInAction(() => {
        this.items = [newItem, ...this.items];
      });
      return newItem;
    }

    const res = await apiClient.post<FeatureSuggestion>((endpoints as any).featureSuggestions.create, payload);
    if (!res.success) throw new Error(res.message || 'Failed to create');
    await this.fetchSuggestions();
    return res.data;
  }

  async vote(user: any, id: string) {
    if (!this.canVote(user)) throw new Error('You need at least 100 points to vote.');
    if (this.myVotes.has(id)) return; // already voted

    if (USE_FEATURE_SUGGESTIONS_MOCK) {
      await delay(150);
      runInAction(() => {
        this.myVotes.add(id);
        this.items = this.items.map((it) =>
          it.id === id
            ? { ...it, votesCount: it.votesCount + 1, status: it.votesCount + 1 >= 100 && it.status === 'proposed' ? 'planned' : it.status, plannedAt: it.votesCount + 1 >= 100 ? new Date().toISOString() : it.plannedAt }
            : it,
        );
      });
      return;
    }

    const res = await apiClient.post<{ votesCount: number; status: FeatureSuggestionStatus }>((endpoints as any).featureSuggestions.vote(id));
    if (!res.success) throw new Error(res.message || 'Failed to vote');
    runInAction(() => {
      this.myVotes.add(id);
      this.items = this.items.map((it) => (it.id === id ? { ...it, votesCount: res.data.votesCount, status: res.data.status } : it));
    });
  }

  async unvote(user: any, id: string) {
    if (!this.canVote(user)) throw new Error('You need at least 100 points to vote.');
    if (!this.myVotes.has(id)) return;

    if (USE_FEATURE_SUGGESTIONS_MOCK) {
      await delay(150);
      runInAction(() => {
        this.myVotes.delete(id);
        this.items = this.items.map((it) => (it.id === id ? { ...it, votesCount: Math.max(0, it.votesCount - 1) } : it));
      });
      return;
    }

    const res = await apiClient.delete<{ votesCount: number }>((endpoints as any).featureSuggestions.unvote(id));
    if (!res.success) throw new Error(res.message || 'Failed to unvote');
    runInAction(() => {
      this.myVotes.delete(id);
      this.items = this.items.map((it) => (it.id === id ? { ...it, votesCount: res.data.votesCount } : it));
    });
  }
}

export const featureSuggestionsStore = new FeatureSuggestionsStore();
export const useFeatureSuggestionsStore = () => featureSuggestionsStore;
