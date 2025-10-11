import { makeAutoObservable, runInAction } from 'mobx';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiClient, endpoints } from '@/api/client';
import { Challenge, ChallengeType, DailyChallenge, BackendChallenge, BackendChallengeParticipantsResponse } from '@/types/challenges';
import { mapChallenge } from '@/utils/mapChallenge';
import { PaginatedResponse } from '@/types';
import { toast } from 'sonner-native';

export type ChallengeCategory = 'personal' | 'community' | 'suggested';

export interface ChallengeState {
  // Challenge lists
  personalChallenges: Challenge[];
  communityChallenges: Challenge[];
  suggestedChallenges: Challenge[];
  
  // UI state
  activeCategory: ChallengeCategory;
  showNewChallengeForm: boolean;
  refreshing: boolean;
  
  // Pagination
  pagination: {
    currentPage: number;
    lastPage: number;
    perPage: number;
    total: number;
    hasMore: boolean;
  };
}

const initialState: ChallengeState = {
  personalChallenges: [],
  communityChallenges: [],
  suggestedChallenges: [],
  activeCategory: 'personal',
  showNewChallengeForm: false,
  refreshing: false,
  pagination: {
    currentPage: 1,
    lastPage: 1,
    perPage: 10,
    total: 0,
    hasMore: false,
  },
};

export class ChallengeStore {
  state: ChallengeState = initialState;

  // Common store props
  isLoading = false; // legacy/global
  error: string | null = null; // legacy/global
  // Per-category loading/error flags
  isPersonalLoading = false;
  isCommunityLoading = false;
  isSuggestedLoading = false;
  personalError: string | null = null;
  communityError: string | null = null;
  suggestedError: string | null = null;
  private storageKey = 'challenge_store';

  constructor() {
    this.state = initialState;
    this.storageKey = 'challenge_store';
    
    // Ensure methods are auto-bound so calling them after destructuring keeps the correct `this`
    makeAutoObservable(this, {}, { autoBind: true });
    
    // Load from storage asynchronously
    AsyncStorage.getItem(this.storageKey).then(stored => {
      if (stored) {
        runInAction(() => {
          this.state = { ...this.state, ...JSON.parse(stored) };
        });
      }
    }).catch(error => {
      console.error('Error loading challenge store from storage:', error);
    });
  }

  private setLoading = (value: boolean) => {
    this.isLoading = value;
  };

  private setCategoryLoading(category: ChallengeCategory, value: boolean) {
    if (category === 'personal') this.isPersonalLoading = value;
    if (category === 'community') this.isCommunityLoading = value;
    if (category === 'suggested') this.isSuggestedLoading = value;
  }

  private setError = (message: string | null) => {
    this.error = message;
  };

  private async saveToStorage() {
    try {
      await AsyncStorage.setItem(this.storageKey, JSON.stringify(this.state));
    } catch (error) {
      console.error(`Error saving ${this.storageKey} to storage:`, error);
      this.error = 'Failed to save data';
    }
  }
  get challenges() {
    return {
      personal: this.state.personalChallenges,
      community: this.state.communityChallenges,
      suggested: this.state.suggestedChallenges,
    };
  }

  // Computed getters for direct access
  get personalChallenges() {
    return this.state.personalChallenges;
  }

  get communityChallenges() {
    return this.state.communityChallenges;
  }

  get suggestedChallenges() {
    return this.state.suggestedChallenges;
  }

  get activeCategory() {
    return this.state.activeCategory;
  }

  get showNewChallengeForm() {
    return this.state.showNewChallengeForm;
  }

  get refreshing() {
    return this.state.refreshing;
  }

  // Legacy Zustand compatibility getters (now mapped to per-category flags)
  get isCreatingLoading() { return this.isLoading; }
  get isJoiningLoading() { return this.isLoading; }
  get isUpvotingLoading() { return this.isLoading; }
  get createError() { return this.error; }

  // Initialization
  private async initialize() {
    try {
      this.setLoading(true);
      const results = await Promise.allSettled([
        this.fetchPersonalChallenges(),
        this.fetchCommunityChallenges(),
        this.fetchSuggestedChallenges(),
      ]);
      if (results.every(r => r.status === 'rejected')) {
        this.setError('Failed to initialize challenge data');
      }
    } catch (error) {
      console.error('Error initializing challenge store:', error);
      this.setError('Failed to initialize challenge data');
    } finally {
      this.setLoading(false);
    }
  }

  async fetchChallengeParticipants(challengeId: string, page = 1) {
    try {
      this.setLoading(true);
      const response = await apiClient.get<BackendChallengeParticipantsResponse>(
        endpoints.challenges.participants(challengeId),
        { page }
      );

      runInAction(() => {
        // Optionally refresh the challenge data from response
        if (response.data?.challenge) {
          const mappedChallenge = mapChallenge(response.data.challenge as BackendChallenge);
          this.replaceChallengeInLists(challengeId, mappedChallenge);
        }

        // Map participants to lightweight avatar objects expected by Challenge.participantAvatars
        const avatars = (response.data?.participants || []).map(p => ({
          id: String(p.id),
          avatar: p.avatar ? String(p.avatar) : '',
          first_name: p.first_name,
          last_name: p.last_name,
        }));
        const total = response.data?.pagination?.total ?? avatars.length;

        this.updateChallengeInLists(challengeId, {
          participantAvatars: avatars.slice(0, 5),
          participants: total,
        });
      });

      return response.data;
    } catch (error) {
      console.error(`Error fetching participants for challenge ${challengeId}:`, error);
      this.setError('Failed to fetch challenge participants');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  clearErrors() {
    this.setError(null);
    this.personalError = null;
    this.communityError = null;
    this.suggestedError = null;
  }

  // Fetching methods
  async fetchPersonalChallenges(page = 1) {
    try {
      this.setLoading(true);
      this.setCategoryLoading('personal', true);
      const response = await apiClient.get<PaginatedResponse<BackendChallenge>>(
        endpoints.challenges.personal,
        { page }
      );
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch personal challenges');
      }
      
      runInAction(() => {
        const payload = response.data as any;
        const list = (payload.data ?? payload) as BackendChallenge[];
        const meta = payload.meta ?? payload?.data?.meta;
        const mapped = list.map(mapChallenge);
        this.state.personalChallenges = page === 1 
          ? mapped 
          : [...this.state.personalChallenges, ...mapped];
          
        this.updatePagination(meta, page);
      });
      
      await this.saveToStorage();
      return this.state.personalChallenges;
    } catch (error) {
      console.error('Error fetching personal challenges:', error);
      this.setError('Failed to fetch personal challenges');
      this.personalError = 'Failed to fetch personal challenges';
      return [];
    } finally {
      this.setCategoryLoading('personal', false);
      this.setLoading(false);
    }
  }

  async fetchCommunityChallenges(page = 1) {
    try {
      this.setLoading(true);
      this.setCategoryLoading('community', true);
      const response = await apiClient.get<PaginatedResponse<BackendChallenge>>(
        endpoints.challenges.community,
        { page }
      );
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch community challenges');
      }
      
      runInAction(() => {
        const payload = response.data as any;
        const list = (payload.data ?? payload) as BackendChallenge[];
        const meta = payload.meta ?? payload?.data?.meta;
        const mapped = list.map(mapChallenge);
        this.state.communityChallenges = page === 1 
          ? mapped 
          : [...this.state.communityChallenges, ...mapped];
          
        this.updatePagination(meta, page);
      });
      
      await this.saveToStorage();
      return this.state.communityChallenges;
    } catch (error) {
      console.error('Error fetching community challenges:', error);
      this.setError('Failed to fetch community challenges');
      this.communityError = 'Failed to fetch community challenges';
      return [];
    } finally {
      this.setCategoryLoading('community', false);
      this.setLoading(false);
    }
  }

  async fetchSuggestedChallenges(page = 1) {
    try {
      this.setLoading(true);
      this.setCategoryLoading('suggested', true);
      const response = await apiClient.get<PaginatedResponse<BackendChallenge>>(
        endpoints.challenges.suggested,
        { page }
      );
      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to fetch suggested challenges');
      }
      
      runInAction(() => {
        const payload = response.data as any;
        const list = (payload.data ?? payload) as BackendChallenge[];
        const meta = payload.meta ?? payload?.data?.meta;
        const mapped = list.map(mapChallenge);
        this.state.suggestedChallenges = page === 1 
          ? mapped 
          : [...this.state.suggestedChallenges, ...mapped];
          
        this.updatePagination(meta, page);
      });
      
      await this.saveToStorage();
      return this.state.suggestedChallenges;
    } catch (error) {
      console.error('Error fetching suggested challenges:', error);
      this.setError('Failed to fetch suggested challenges');
      this.suggestedError = 'Failed to fetch suggested challenges';
      return [];
    } finally {
      this.setCategoryLoading('suggested', false);
      this.setLoading(false);
    }
  }

  async fetchDailyChallenges() {
    try {
      this.setLoading(true);
      const response = await apiClient.get<{ data: DailyChallenge[] }>(endpoints.challenges.daily);
      
      // Update the relevant challenges in the store
      runInAction(() => {
        // This is a simplified example - you might want to handle this differently
        // based on how daily challenges are structured in your app
        response.data.data.forEach(dailyChallenge => {
          const challengeIndex = this.state.personalChallenges.findIndex(
            c => c.id === dailyChallenge.id
          );
          
          if (challengeIndex !== -1) {
            this.state.personalChallenges[challengeIndex] = {
              ...this.state.personalChallenges[challengeIndex],
              ...dailyChallenge,
            };
          }
        });
      });
      
      return response.data.data;
    } catch (error) {
      console.error('Error fetching daily challenges:', error);
      this.setError('Failed to fetch daily challenges');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  // Challenge management
  async createChallenge(data: {
    title: string;
    description?: string;
    type: ChallengeType;
    category: 'personal' | 'community' | 'suggested';
    endTime: string; // UI field, map to end_time
    isPublic?: boolean;
  }) {
    try {
      this.setLoading(true);
      // Map UI payload to backend expected keys
      const payload: Record<string, any> = {
        title: data.title,
        description: data.description,
        type: data.type,
        category: data.category,
        end_time: data.endTime,
        is_public: data.isPublic ?? (data.category !== 'personal'),
      };
      const response = await apiClient.post<BackendChallenge>(endpoints.challenges.create, payload);
      
      runInAction(() => {
        const created = mapChallenge(response.data as unknown as BackendChallenge);
        // Add the new challenge to the appropriate list using category
        if (created.category === 'personal') {
          this.state.personalChallenges = [created, ...this.state.personalChallenges];
        } else if (created.category === 'community') {
          this.state.communityChallenges = [created, ...this.state.communityChallenges];
        } else {
          this.state.suggestedChallenges = [created, ...this.state.suggestedChallenges];
        }
        
        // Update pagination total
        this.state.pagination.total += 1;
      });
      
      await this.saveToStorage();
      toast.success('Challenge created successfully');
      return this.getChallengeById(String((response.data as any).id));
    } catch (error) {
      console.error('Error creating challenge:', error);
      this.setError('Failed to create challenge');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async updateChallenge(id: string, updates: Partial<Challenge>) {
    try {
      this.setLoading(true);
      const response = await apiClient.put<BackendChallenge>(endpoints.challenges.update(id), updates);
      
      runInAction(() => {
        const mapped = mapChallenge(response.data as unknown as BackendChallenge);
        // Update the challenge in all relevant lists
        this.replaceChallengeInLists(id, mapped);
      });
      
      await this.saveToStorage();
      toast.success('Challenge updated successfully');
      return this.getChallengeById(id);
    } catch (error) {
      console.error(`Error updating challenge ${id}:`, error);
      this.setError('Failed to update challenge');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async deleteChallenge(id: string) {
    try {
      this.setLoading(true);
      await apiClient.delete(endpoints.challenges.delete(id));
      
      runInAction(() => {
        // Remove the challenge from all lists
        this.state.personalChallenges = this.state.personalChallenges.filter(c => c.id !== id);
        this.state.communityChallenges = this.state.communityChallenges.filter(c => c.id !== id);
        this.state.suggestedChallenges = this.state.suggestedChallenges.filter(c => c.id !== id);
        
        // Update pagination total
        this.state.pagination.total = Math.max(0, this.state.pagination.total - 1);
      });
      
      await this.saveToStorage();
      toast.success('Challenge deleted successfully');
      return true;
    } catch (error) {
      console.error(`Error deleting challenge ${id}:`, error);
      this.setError('Failed to delete challenge');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async joinChallenge(challengeId: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<BackendChallenge>(endpoints.challenges.join(challengeId));

      runInAction(() => {
        const mapped = mapChallenge(response.data as BackendChallenge);
        const existing = this.getChallengeById(challengeId);
        const participants =
          typeof mapped.participants === 'number'
            ? mapped.participants
            : existing?.participants ?? 0;

        const merged = {
          ...(existing ?? {}),
          ...mapped,
          hasJoined: true,
          participants,
        } as Challenge;

        if (existing) {
          this.replaceChallengeInLists(challengeId, merged);
        } else {
          this.updateChallengeInLists(challengeId, {
            hasJoined: true,
            participants,
          });
        }

        const existsInPersonal = this.state.personalChallenges.some(c => c.id === merged.id);
        if (existsInPersonal) {
          this.state.personalChallenges = this.state.personalChallenges.map(c =>
            c.id === merged.id ? { ...merged } : c
          );
        } else {
          this.state.personalChallenges = [merged, ...this.state.personalChallenges];
        }
      });

      await this.saveToStorage();
      toast.success('Successfully joined the challenge');
      return this.getChallengeById(challengeId);
    } catch (error) {
      console.error(`Error joining challenge ${challengeId}:`, error);
      this.setError('Failed to join challenge');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async leaveChallenge(challengeId: string) {
    try {
      this.setLoading(true);
      await apiClient.post(endpoints.challenges.leave(challengeId));
      
      runInAction(() => {
        const current = this.getChallengeById(challengeId);
        const participants = Math.max(0, (current?.participants || 1) - 1);
        this.updateChallengeInLists(challengeId, {
          hasJoined: false,
          participants,
        });

        this.state.personalChallenges = this.state.personalChallenges.filter(c => c.id !== challengeId);
      });
      
      await this.saveToStorage();
      toast.success('Successfully left the challenge');
      return this.getChallengeById(challengeId);
    } catch (error) {
      console.error(`Error leaving challenge ${challengeId}:`, error);
      this.setError('Failed to leave challenge');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async upvoteChallenge(challengeId: string) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<BackendChallenge>(endpoints.challenges.upvote(challengeId));
      const mapped = mapChallenge(response.data as BackendChallenge);
      
      runInAction(() => {
        // Update counts and toggle locally based on new counts
        this.updateChallengeInLists(challengeId, {
          upvotes: mapped.upvotes,
          hasUpvoted: mapped.hasUpvoted,
        });
      });
      
      await this.saveToStorage();
      toast.success('Challenge upvoted successfully');
      return { hasUpvoted: mapped.hasUpvoted, upvotes: mapped.upvotes };
    } catch (error) {
      console.error(`Error upvoting challenge ${challengeId}:`, error);
      this.setError('Failed to upvote challenge');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async voteChallenge(challengeId: string, payload: { spiritual: number; effort: number }) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<{ challenge: BackendChallenge; vote: any }>(
        endpoints.challenges.vote(challengeId),
        {
          spiritual: Math.max(1, Math.min(5, Math.round(payload.spiritual))),
          effort: Math.max(1, Math.min(5, Math.round(payload.effort))),
        }
      );

      if (!response.success || !response.data) {
        throw new Error(response.message || 'Failed to record vote');
      }

      const backendChallenge = (response.data as any).challenge as BackendChallenge;
      const mapped = mapChallenge(backendChallenge);

      runInAction(() => {
        this.replaceChallengeInLists(challengeId, mapped);
      });

      await this.saveToStorage();
      toast.success('Vote recorded');
      return mapped;
    } catch (error) {
      console.error(`Error voting on challenge ${challengeId}:`, error);
      this.setError('Failed to record your vote');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async completeChallenge(challengeId: string, isCompleted: boolean) {
    try {
      this.setLoading(true);
      const response = await apiClient.post<BackendChallenge>(
        endpoints.challenges.complete(challengeId)
      );
      
      runInAction(() => {
        const mapped = mapChallenge(response.data as BackendChallenge);
        // Update the challenge in all lists
        this.updateChallengeInLists(challengeId, {
          isCompleted: mapped.isCompleted,
        });
      });
      
      await this.saveToStorage();
      toast.success(`Challenge marked as ${isCompleted ? 'completed' : 'incomplete'}`);
      return this.getChallengeById(challengeId);
    } catch (error) {
      console.error(`Error updating challenge ${challengeId} completion status:`, error);
      this.setError(`Failed to mark challenge as ${isCompleted ? 'completed' : 'incomplete'}`);
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  async addSuggestedToPersonal(challengeId: string) {
    try {
      this.setLoading(true);
      const challenge = this.state.suggestedChallenges.find(c => c.id === challengeId);
      
      if (!challenge) {
        throw new Error('Challenge not found');
      }
      
      // Create a personal copy of the challenge
      const personalChallenge = await this.createChallenge({
        title: challenge.title,
        description: challenge.description,
        type: challenge.type,
        category: 'personal',
        endTime: challenge.endTime,
        isPublic: false,
      });
      
      // Remove from suggested challenges
      runInAction(() => {
        this.state.suggestedChallenges = this.state.suggestedChallenges.filter(c => c.id !== challengeId);
      });
      
      await this.saveToStorage();
      return personalChallenge;
    } catch (error) {
      console.error(`Error adding suggested challenge ${challengeId} to personal:`, error);
      this.setError('Failed to add challenge to personal');
      throw error;
    } finally {
      this.setLoading(false);
    }
  }

  // UI state management
  setActiveCategory(category: ChallengeCategory) {
    this.state.activeCategory = category;
  }

  setShowNewChallengeForm(show: boolean) {
    this.state.showNewChallengeForm = show;
  }

  setRefreshing(refreshing: boolean) {
    this.state.refreshing = refreshing;
  }

  // Refresh methods
  async refreshAll() {
    try {
      this.setRefreshing(true);
      await Promise.all([
        this.fetchPersonalChallenges(1),
        this.fetchCommunityChallenges(1),
        this.fetchSuggestedChallenges(1),
      ]);
    } finally {
      this.setRefreshing(false);
    }
  }

  async refreshChallenges() {
    switch (this.state.activeCategory) {
      case 'personal':
        return this.fetchPersonalChallenges(1);
      case 'community':
        return this.fetchCommunityChallenges(1);
      case 'suggested':
        return this.fetchSuggestedChallenges(1);
      default:
        return Promise.resolve();
    }
  }

  // Helper methods
  private updatePagination(meta: any, currentPage: number) {
    // Some endpoints return an array (no pagination meta). In that case, avoid errors and set safe defaults.
    if (meta && typeof meta === 'object' &&
        (typeof meta.last_page !== 'undefined' || typeof meta.current_page !== 'undefined')) {
      const lastPage = Number(meta.last_page ?? currentPage) || currentPage;
      const perPage = Number(meta.per_page ?? this.state.pagination.perPage) || this.state.pagination.perPage;
      const total = Number(meta.total ?? this.state.pagination.total) || this.state.pagination.total;
      const current = Number(meta.current_page ?? currentPage) || currentPage;
      this.state.pagination = {
        currentPage: current,
        lastPage,
        perPage,
        total,
        hasMore: current < lastPage,
      };
      return;
    }

    // No meta provided: set hasMore to false and preserve prior totals/perPage
    this.state.pagination = {
      currentPage,
      lastPage: currentPage,
      perPage: this.state.pagination.perPage,
      total: this.state.pagination.total,
      hasMore: false,
    };
  }

  private getChallengeById(challengeId: string): Challenge | undefined {
    return [
      ...this.state.personalChallenges,
      ...this.state.communityChallenges,
      ...this.state.suggestedChallenges,
    ].find(challenge => challenge.id === challengeId);
  }

  private updateChallengeInLists(challengeId: string, updates: Partial<Challenge>) {
    const updateFn = (challenge: Challenge) => 
      challenge.id === challengeId ? { ...challenge, ...updates } : challenge;
    
    this.state.personalChallenges = this.state.personalChallenges.map(updateFn);
    this.state.communityChallenges = this.state.communityChallenges.map(updateFn);
    this.state.suggestedChallenges = this.state.suggestedChallenges.map(updateFn);
    
    // Also update current challenge if it's the one being updated
    if (updates.id === challengeId || 
        (this.state.personalChallenges.some(c => c.id === challengeId) ||
         this.state.communityChallenges.some(c => c.id === challengeId) ||
         this.state.suggestedChallenges.some(c => c.id === challengeId))) {
      // The challenge exists in one of the lists
      const updatedChallenge = this.getChallengeById(challengeId);
      if (updatedChallenge) {
        // The challenge was found and updated
        return { ...updatedChallenge, ...updates };
      }
    }
    
    return null;
  }

  private replaceChallengeInLists(challengeId: string, replacement: Challenge) {
    const replaceFn = (challenge: Challenge) => 
      challenge.id === challengeId ? replacement : challenge;
    this.state.personalChallenges = this.state.personalChallenges.map(replaceFn);
    this.state.communityChallenges = this.state.communityChallenges.map(replaceFn);
    this.state.suggestedChallenges = this.state.suggestedChallenges.map(replaceFn);
  }
  
  // Cleanup on store destruction
  cleanup() {
    // Clean up any resources if needed
  }
}

// Create a singleton instance
export const challengeStore = new ChallengeStore();

// For backward compatibility
export const useChallengeStore = () => challengeStore;

export default challengeStore;
