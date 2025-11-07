import { apiClient, endpoints } from '@/api/client';
import { authStore } from '@/stores/AuthStore';
import { preferencesStore } from '@/stores/PreferencesStore';
import {
  buildNuggetContext,
  cancelDailyNuggetSchedule,
  getNuggetContextHash,
  scheduleDailyNugget,
  NuggetContextInput,
} from '@/tasks/dailyNuggetScheduler';
import {
  Activity,
  MeditationSession,
  Note,
  PaginatedResponse,
  Reflection,
} from '@/types';

export interface DailyNuggetSyncOptions {
  force?: boolean;
  triggerInSeconds?: number;
}

export interface DailyNuggetSyncResult {
  scheduled: boolean;
  reason?: string;
}

const SAFE_PER_PAGE = 15;

type InjectedAuth = { user: any };
type InjectedPrefs = { state: { showDailyNuggets: boolean } };

let injectedAuth: InjectedAuth | null = null;
let injectedPrefs: InjectedPrefs | null = null;

export const setDailyNuggetStores = (deps: { authStore: InjectedAuth; preferencesStore: InjectedPrefs }) => {
  injectedAuth = deps.authStore;
  injectedPrefs = deps.preferencesStore;
};

const extractItems = <T>(payload: any): T[] => {
  if (!payload) return [];
  if (Array.isArray(payload)) return payload as T[];
  if (Array.isArray(payload?.data)) return payload.data as T[];
  if (Array.isArray(payload?.items)) return payload.items as T[];
  return [];
};

const fetchUserNotes = async (userId: string): Promise<Note[]> => {
  try {
    const response = await apiClient.get<PaginatedResponse<Note>>(
      endpoints.notes.byUser(userId),
      { per_page: SAFE_PER_PAGE, sort: '-created_at' },
    );
    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch notes');
    }
    return extractItems<Note>(response.data);
  } catch (error) {
    console.warn('[DailyNuggetOrchestrator] Failed to load notes', error);
    return [];
  }
};

const fetchUserReflections = async (userId: string): Promise<Reflection[]> => {
  try {
    const response = await apiClient.get<PaginatedResponse<Reflection>>(
      endpoints.reflections.byUser(userId),
      { per_page: SAFE_PER_PAGE, sort: '-created_at' },
    );
    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch reflections');
    }
    return extractItems<Reflection>(response.data);
  } catch (error) {
    console.warn('[DailyNuggetOrchestrator] Failed to load reflections', error);
    return [];
  }
};

const fetchUserMeditationSessions = async (): Promise<MeditationSession[]> => {
  try {
    const response = await apiClient.get<PaginatedResponse<MeditationSession>>(
      '/meditation_sessions',
      { per_page: SAFE_PER_PAGE, sort: '-started_at' },
    );
    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch meditation sessions');
    }
    return extractItems<MeditationSession>(response.data);
  } catch (error) {
    console.warn('[DailyNuggetOrchestrator] Failed to load meditation sessions', error);
    return [];
  }
};

const fetchUserActivities = async (userId: string): Promise<Activity[]> => {
  try {
    const response = await apiClient.get<PaginatedResponse<Activity>>(
      endpoints.activities.byUser(userId),
      { per_page: SAFE_PER_PAGE, sort: '-created_at' },
    );
    if (!response.success) {
      throw new Error(response.message || 'Failed to fetch activities');
    }
    return extractItems<Activity>(response.data);
  } catch (error) {
    console.warn('[DailyNuggetOrchestrator] Failed to load activities', error);
    return [];
  }
};

export const syncDailyNuggets = async (
  options: DailyNuggetSyncOptions = {},
): Promise<DailyNuggetSyncResult> => {
  try {
    const { user } = (injectedAuth || authStore);
    if (!user?.id) {
      await cancelDailyNuggetSchedule();
      return { scheduled: false, reason: 'no_user' };
    }

    const prefs = (injectedPrefs || preferencesStore);
    if (!prefs.state.showDailyNuggets) {
      await cancelDailyNuggetSchedule();
      return { scheduled: false, reason: 'disabled' };
    }

    const [notes, reflections, meditationSessions, activities] = await Promise.all([
      fetchUserNotes(String(user.id)),
      fetchUserReflections(String(user.id)),
      fetchUserMeditationSessions(),
      fetchUserActivities(String(user.id)),
    ]);

    const contextInput: NuggetContextInput = {
      notes,
      reflections,
      meditationSessions,
      activities,
    };

    const context = buildNuggetContext(contextInput);
    const contextHash = getNuggetContextHash(context);

    const result = await scheduleDailyNugget(context, {
      ...options,
      contextHash,
    });

    return {
      scheduled: result.scheduled,
      reason: result.reason,
    };
  } catch (error) {
    console.error('[DailyNuggetOrchestrator] sync failed', error);
    return { scheduled: false, reason: 'unknown' };
  }
};

export const disableDailyNuggets = async () => {
  await cancelDailyNuggetSchedule();
};
