import { makeObservable, observable, action, runInAction, computed } from 'mobx';
import type { GuideDefinition, GuideSummary } from '@/services/GuideService';
import { getGuides, getGuideById } from '@/services/GuideService';

export class GuideStore {
  summaries: GuideSummary[] = [];
  definitions: Record<string, GuideDefinition> = {};
  isLoading = false;
  error: string | null = null;

  constructor() {
    makeObservable(this, {
      summaries: observable,
      definitions: observable,
      isLoading: observable,
      error: observable,
      hasGuides: computed,
      fetchSummaries: action,
      fetchGuide: action,
      setGuide: action,
    }, { autoBind: true });
  }

  get hasGuides(): boolean {
    return this.summaries.length > 0;
  }

  async fetchSummaries() {
    this.isLoading = true;
    this.error = null;
    try {
      const list = await getGuides();
      runInAction(() => {
        this.summaries = Array.isArray(list) ? list : [];
        this.isLoading = false;
      });
    } catch (e: any) {
      runInAction(() => {
        this.error = 'Failed to load guides';
        this.isLoading = false;
      });
    }
  }

  async fetchGuide(id: string): Promise<GuideDefinition | null> {
    try {
      const cached = this.definitions[id] || null;
      if (cached) return cached;
      const def = await getGuideById(id);
      if (def) {
        runInAction(() => {
          this.definitions[id] = def;
        });
      }
      return def;
    } catch {
      return null;
    }
  }

  setGuide(def: GuideDefinition) {
    this.definitions[def.id] = def;
  }
}

export default GuideStore;
