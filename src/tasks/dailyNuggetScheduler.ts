import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import * as Notifications from 'expo-notifications';
import { differenceInHours } from 'date-fns';

import {
  KINGDOM_NUGGETS,
  NUGGET_COOLDOWN_HOURS,
  KingdomNugget,
  NuggetTag,
} from '@/data/kingdomNuggets';
import {
  Activity,
  ActivityType,
  MeditationSession,
  Note,
  Reflection,
} from '@/types';

const STORAGE_KEY = 'daily_nugget_schedule_state_v1';
const CHANNEL_ID = 'daily-nuggets';
const DEFAULT_TRIGGER_SECONDS = 60 * 45; // 45 minutes

interface ScheduleState {
  lastScheduledAt?: string;
  lastNuggetId?: string;
  notificationId?: string;
  contextHash?: string;
}

export interface NuggetContext {
  tagSignals: NuggetTag[];
  momentSignals: string[];
  scoreHints?: Partial<Record<NuggetTag, number>>;
  now?: Date;
}

export interface NuggetContextInput {
  notes?: Note[];
  reflections?: Reflection[];
  meditationSessions?: MeditationSession[];
  activities?: Activity[];
}

export interface NuggetSyncOptions {
  force?: boolean;
  triggerInSeconds?: number;
  contextHash?: string;
}

export interface NuggetSyncResult {
  scheduled: boolean;
  nugget?: KingdomNugget;
  notificationId?: string;
  reason?:
    | 'disabled'
    | 'cooldown'
    | 'no_nuggets'
    | 'no_context_change'
    | 'permission_denied'
    | 'unknown';
}

const ensurePermissionsAsync = async () => {
  const { status } = await Notifications.getPermissionsAsync();
  if (status === 'granted') {
    return true;
  }
  const request = await Notifications.requestPermissionsAsync();
  return request.status === 'granted';
};

const ensureChannelAsync = async () => {
  if (Platform.OS !== 'android') {
    return;
  }
  await Notifications.setNotificationChannelAsync(CHANNEL_ID, {
    name: 'Daily Nuggets',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
    enableVibrate: true,
  });
};

const loadState = async (): Promise<ScheduleState> => {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as ScheduleState) : {};
  } catch (error) {
    console.warn('[DailyNuggetScheduler] Failed to load schedule state', error);
    return {};
  }
};

const saveState = async (state: ScheduleState) => {
  try {
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (error) {
    console.warn('[DailyNuggetScheduler] Failed to persist schedule state', error);
  }
};

const clearState = async () => {
  try {
    await AsyncStorage.removeItem(STORAGE_KEY);
  } catch (error) {
    console.warn('[DailyNuggetScheduler] Failed to clear schedule state', error);
  }
};

const makeSet = <T extends string>(items: T[] | undefined) => new Set(items ?? []);

export const getNuggetContextHash = (context: NuggetContext) => {
  const tags = [...new Set(context.tagSignals)].sort().join('|');
  const moments = [...new Set(context.momentSignals)].sort().join('|');
  return `${tags}__${moments}`;
};

interface ScoredNugget {
  nugget: KingdomNugget;
  score: number;
  matchedTags: NuggetTag[];
  matchedMoments: string[];
}

const scoreNuggets = (
  context: NuggetContext,
  state: ScheduleState,
): ScoredNugget[] => {
  const tagSet = makeSet(context.tagSignals);
  const momentSet = makeSet(context.momentSignals);
  const tagHints = context.scoreHints ?? {};

  return KINGDOM_NUGGETS.map((nugget) => {
    const matchedTags = nugget.tags.filter((tag) => tagSet.has(tag));
    const matchedMoments = nugget.deliveryHints.moments.filter((moment) => momentSet.has(moment));

    let score = 0;
    matchedTags.forEach((tag) => {
      const base = 6; // base weight per tag
      const hintWeight = tagHints[tag] ? Math.min(tagHints[tag] ?? 0, 5) * 2 : 0;
      score += base + hintWeight;
    });
    matchedMoments.forEach(() => {
      score += 8; // heavier weight for explicit moment matches
    });

    if (nugget.tone === 'encourage') score += 2;
    if (nugget.tone === 'remind') score += 1;

    // Mild penalty if this nugget was last sent
    if (state.lastNuggetId === nugget.id) {
      score -= 5;
    }

    return {
      nugget,
      score,
      matchedTags,
      matchedMoments,
    };
  }).filter((entry) => entry.score > 0);
};

const selectBestNugget = (
  context: NuggetContext,
  state: ScheduleState,
): KingdomNugget | null => {
  const now = context.now ?? new Date();
  if (state.lastScheduledAt && state.lastNuggetId) {
    const hoursSince = differenceInHours(now, new Date(state.lastScheduledAt));
    if (hoursSince < NUGGET_COOLDOWN_HOURS) {
      return null;
    }
  }

  const scored = scoreNuggets(context, state);
  if (!scored.length) {
    // Fallback: choose an encourage nugget with minimal overlap
    const fallback = KINGDOM_NUGGETS.find((n) => n.tone === 'encourage');
    return fallback ?? KINGDOM_NUGGETS[0] ?? null;
  }

  scored.sort((a, b) => b.score - a.score);
  return scored[0]?.nugget ?? null;
};

export const scheduleDailyNugget = async (
  context: NuggetContext,
  options: NuggetSyncOptions = {},
): Promise<NuggetSyncResult> => {
  const state = options.force ? {} : await loadState();
  const contextHash = options.contextHash ?? getNuggetContextHash(context);
  const now = context.now ?? new Date();

  if (!options.force && state.contextHash === contextHash) {
    return { scheduled: false, reason: 'no_context_change' };
  }

  if (!options.force && state.lastScheduledAt && state.lastNuggetId) {
    const hoursSince = differenceInHours(now, new Date(state.lastScheduledAt));
    if (hoursSince < NUGGET_COOLDOWN_HOURS) {
      return { scheduled: false, reason: 'cooldown' };
    }
  }

  const hasPermission = await ensurePermissionsAsync();
  if (!hasPermission) {
    return { scheduled: false, reason: 'permission_denied' };
  }
  await ensureChannelAsync();

  const nugget = selectBestNugget(context, state);
  if (!nugget) {
    return { scheduled: false, reason: 'no_nuggets' };
  }

  if (state.notificationId) {
    try {
      await Notifications.cancelScheduledNotificationAsync(state.notificationId);
    } catch (error) {
      console.warn('[DailyNuggetScheduler] Failed to cancel previous notification', error);
    }
  }

  try {
    const triggerInSeconds = Math.max(options.triggerInSeconds ?? DEFAULT_TRIGGER_SECONDS, 60);
    const notificationId = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Kingdom Nugget',
        body: nugget.text,
        sound: 'default',
        data: {
          nuggetId: nugget.id,
          tone: nugget.tone,
        },
      },
      trigger: {
        seconds: triggerInSeconds,
        channelId: CHANNEL_ID,
      },
    });

    const nextState: ScheduleState = {
      lastScheduledAt: now.toISOString(),
      lastNuggetId: nugget.id,
      notificationId,
      contextHash,
    };
    await saveState(nextState);

    return {
      scheduled: true,
      nugget,
      notificationId,
    };
  } catch (error) {
    console.error('[DailyNuggetScheduler] Failed to schedule notification', error);
    return { scheduled: false, reason: 'unknown' };
  }
};

export const cancelDailyNuggetSchedule = async () => {
  const state = await loadState();
  if (state.notificationId) {
    try {
      await Notifications.cancelScheduledNotificationAsync(state.notificationId);
    } catch (error) {
      console.warn('[DailyNuggetScheduler] Failed to cancel notification', error);
    }
  }
  await clearState();
};

const addTag = (collection: Map<NuggetTag, number>, tag: NuggetTag, weight = 1) => {
  collection.set(tag, (collection.get(tag) ?? 0) + weight);
};

const virtueToTags: Record<string, NuggetTag[]> = {
  love: ['relationships', 'service', 'joy'],
  humility: ['humility', 'service', 'self_control'],
  faith: ['trust', 'purpose'],
  knowledge: ['wisdom', 'discernment'],
  'self-control': ['self_control', 'purity'],
  obedience: ['obedience', 'service'],
  patience: ['self_control', 'humility'],
  gentleness: ['relationships', 'humility'],
  generosity: ['generosity', 'service'],
  kindness: ['relationships', 'joy'],
  goodness: ['service', 'joy'],
  compassion: ['relationships', 'service'],
  courage: ['courage', 'purpose'],
  perseverance: ['purpose', 'self_control'],
  hope: ['joy', 'trust'],
  joy: ['joy', 'gratitude'],
  peace: ['contentment', 'trust'],
  gratitude: ['gratitude', 'joy'],
  righteousness: ['obedience', 'wisdom'],
  justice: ['stewardship', 'service'],
  respect: ['relationships', 'humility'],
  honesty: ['identity', 'trust'],
  prudence: ['wisdom', 'discernment'],
  fortitude: ['courage', 'purpose'],
};

const mapVirtuesToTags = (virtues?: string[] | null): NuggetTag[] => {
  if (!virtues?.length) return [];
  const tags = virtues.flatMap((virtue) => virtueToTags[virtue.toLowerCase()] ?? []);
  return [...new Set(tags)];
};

const getRecentItems = <T extends { created_at?: string; updated_at?: string; ended_at?: string; started_at?: string }>(
  items: T[] | undefined,
  hours = 48,
): T[] => {
  if (!items?.length) return [];
  const now = new Date();
  return items.filter((item) => {
    const candidates = [item.updated_at, item.created_at, (item as any).ended_at, (item as any).started_at]
      .filter(Boolean)
      .map((value) => new Date(value as string));
    return candidates.some((date) => !Number.isNaN(date.getTime()) && differenceInHours(now, date) <= hours);
  });
};

const ACTIVITY_SUBJECT_TAGS: Record<string, NuggetTag[]> = {
  Reflection: ['wisdom', 'service'],
  Note: ['wisdom', 'focus'],
  PrayerRequest: ['service', 'relationships'],
  Verse: ['wisdom', 'focus'],
  Challenge: ['purpose', 'courage'],
};

const ACTIVITY_SUBJECT_MOMENTS: Record<string, string[]> = {
  Reflection: ['reflection_published', 'comment_submitted'],
  Note: ['journaling_session', 'note_tagged_purpose'],
  PrayerRequest: ['prayer_request_created', 'community_support_action'],
  Challenge: ['challenge_completed', 'challenge_joined'],
};

const mapActivitiesToSignals = (
  activities: Activity[] | undefined,
  tagCounts: Map<NuggetTag, number>,
  momentSignals: Set<string>,
) => {
  if (!activities?.length) return;
  activities.forEach((activity) => {
    const subject = activity.subject_type?.replace(/^.*\\/, '') ?? '';
    const subjectTags = ACTIVITY_SUBJECT_TAGS[subject];
    const subjectMoments = ACTIVITY_SUBJECT_MOMENTS[subject];
    if (subjectTags) {
      subjectTags.forEach((tag) => addTag(tagCounts, tag, 1));
    }
    if (subjectMoments) {
      subjectMoments.forEach((moment) => momentSignals.add(moment));
    }
    const activityType =
      typeof activity.type === 'number'
        ? activity.type
        : activity.type?.value;
    if (activityType === ActivityType.Like) {
      momentSignals.add('community_like_integrity');
    }
    if (activityType === ActivityType.Comment) {
      momentSignals.add('comment_submitted');
    }
  });
};

export const buildNuggetContext = (input: NuggetContextInput): NuggetContext => {
  const tagCounts = new Map<NuggetTag, number>();
  const momentSignals = new Set<string>();

  const recentNotes = getRecentItems(input.notes, 48);
  recentNotes.forEach((note) => {
    const tags = mapVirtuesToTags((note as any).virtues ?? (note.theme ? [note.theme] : []));
    tags.forEach((tag) => addTag(tagCounts, tag, 1));
    if (tags.includes('gratitude')) {
      momentSignals.add('gratitude_note_created');
    }
    if (tags.includes('self_control') || tags.includes('purity')) {
      momentSignals.add('note_about_temptation');
    }
    if (tags.includes('purpose')) {
      momentSignals.add('note_tagged_purpose');
    }
    momentSignals.add('journaling_session');
  });

  const recentReflections = getRecentItems(input.reflections, 72);
  recentReflections.forEach(() => {
    addTag(tagCounts, 'service', 1);
    addTag(tagCounts, 'wisdom', 1);
    momentSignals.add('reflection_published');
  });

  const recentSessions = getRecentItems(input.meditationSessions, 48);
  if (recentSessions.length) {
    addTag(tagCounts, 'self_control', recentSessions.length);
    addTag(tagCounts, 'focus', recentSessions.length);
    addTag(tagCounts, 'joy', Math.max(1, Math.floor(recentSessions.length / 2)));
    momentSignals.add('meditation_completed');
    if (recentSessions.length >= 5) {
      momentSignals.add('meditation_streak_5');
    }
  }

  mapActivitiesToSignals(input.activities, tagCounts, momentSignals);

  if (!recentNotes.length && !recentReflections.length && !recentSessions.length) {
    momentSignals.add('no_activity_half_day');
    addTag(tagCounts, 'discernment', 1);
  }

  const tagSignals = Array.from(tagCounts.keys());
  const scoreHints: Partial<Record<NuggetTag, number>> = {};
  tagCounts.forEach((value, key) => {
    scoreHints[key] = value;
  });

  return {
    tagSignals,
    momentSignals: Array.from(momentSignals),
    scoreHints,
  };
};
