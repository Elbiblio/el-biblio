import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import * as BackgroundTask from 'expo-background-task';
import * as TaskManager from 'expo-task-manager';
import { Platform } from 'react-native';

export const TASK_NAME = 'challenge-reminder-task';
export const CHALLENGE_REMINDER_PREFIX = 'challenge_reminder_';
export const CHALLENGE_REMINDER_INDEX_KEY = 'challenge_reminder_index';
export const CHALLENGE_REMINDER_CHANNEL_ID = 'challenge-reminders';

type StoredReminder = {
  challengeId: string;
  challengeTitle?: string;
  reminderHours: number;
  scheduledFor?: string;
  nextReminderDue: string;
  notificationIds?: string[];
  lastReminderSentAt?: string;
};

export const ensureChallengeReminderChannel = async () => {
  if (Platform.OS !== 'android') {
    return;
  }
  try {
    await Notifications.setNotificationChannelAsync(CHALLENGE_REMINDER_CHANNEL_ID, {
      name: 'Challenge reminders',
      importance: Notifications.AndroidImportance.HIGH,
      sound: 'default',
      enableVibrate: true,
    });
  } catch (error) {
    console.warn('[ChallengeReminderTask] Failed to configure challenge reminder channel', error);
  }
};

export const getReminderStorageKey = (challengeId: string) => `${CHALLENGE_REMINDER_PREFIX}${challengeId}`;

export const getReminderIndex = async (): Promise<string[]> => {
  try {
    const stored = await AsyncStorage.getItem(CHALLENGE_REMINDER_INDEX_KEY);
    if (!stored) {
      return [];
    }
    const parsed = JSON.parse(stored);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to read reminder index', error);
    return [];
  }
};

export const addReminderKeyToIndex = async (reminderKey: string) => {
  try {
    const current = await getReminderIndex();
    if (!current.includes(reminderKey)) {
      current.push(reminderKey);
      await AsyncStorage.setItem(CHALLENGE_REMINDER_INDEX_KEY, JSON.stringify(current));
    }
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to add reminder to index', error);
  }
};

export const removeReminderKeyFromIndex = async (reminderKey: string) => {
  try {
    const current = await getReminderIndex();
    const filtered = current.filter(key => key !== reminderKey);
    if (filtered.length !== current.length) {
      if (filtered.length === 0) {
        await AsyncStorage.removeItem(CHALLENGE_REMINDER_INDEX_KEY);
      } else {
        await AsyncStorage.setItem(CHALLENGE_REMINDER_INDEX_KEY, JSON.stringify(filtered));
      }
    }
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to remove reminder from index', error);
  }
};

export const loadStoredReminder = async (challengeId: string): Promise<StoredReminder | null> => {
  try {
    const reminderKey = getReminderStorageKey(challengeId);
    const stored = await AsyncStorage.getItem(reminderKey);
    return stored ? (JSON.parse(stored) as StoredReminder) : null;
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to load reminder', error);
    return null;
  }
};

const storeReminderPayload = async (reminderKey: string, reminder: StoredReminder) => {
  await AsyncStorage.setItem(reminderKey, JSON.stringify(reminder));
  await addReminderKeyToIndex(reminderKey);
};

export const upsertStoredReminder = async (
  params: Pick<StoredReminder, 'challengeId' | 'reminderHours'> &
    Partial<Omit<StoredReminder, 'challengeId' | 'reminderHours'>>
) => {
  const now = new Date();
  const reminderKey = getReminderStorageKey(params.challengeId);
  const base = await loadStoredReminder(params.challengeId);

  const nextDue = params.nextReminderDue
    ? new Date(params.nextReminderDue)
    : new Date(now.getTime() + (params.reminderHours || base?.reminderHours || 1) * 60 * 60 * 1000);

  const payload: StoredReminder = {
    challengeId: params.challengeId,
    reminderHours: params.reminderHours,
    challengeTitle: params.challengeTitle ?? base?.challengeTitle,
    scheduledFor: params.scheduledFor ?? base?.scheduledFor ?? now.toISOString(),
    notificationIds: params.notificationIds ?? base?.notificationIds,
    lastReminderSentAt: params.lastReminderSentAt ?? base?.lastReminderSentAt,
    nextReminderDue: nextDue.toISOString(),
  };

  await storeReminderPayload(reminderKey, payload);
  return payload;
};

export const updateReminderNextDue = async (challengeId: string, nextReminderDue: Date) => {
  const reminderKey = getReminderStorageKey(challengeId);
  const existing = await loadStoredReminder(challengeId);
  if (!existing) {
    return;
  }

  const payload: StoredReminder = {
    ...existing,
    nextReminderDue: nextReminderDue.toISOString(),
  };

  await storeReminderPayload(reminderKey, payload);
};

export const storeReminderNotificationIds = async (challengeId: string, notificationIds: string[]) => {
  const reminderKey = getReminderStorageKey(challengeId);
  const existing = await loadStoredReminder(challengeId);
  if (!existing) {
    return;
  }

  const payload: StoredReminder = {
    ...existing,
    notificationIds,
  };

  await storeReminderPayload(reminderKey, payload);
};

export const removeStoredReminder = async (challengeId: string) => {
  try {
    const reminderKey = getReminderStorageKey(challengeId);
    await AsyncStorage.removeItem(reminderKey);
    await removeReminderKeyFromIndex(reminderKey);
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to remove stored reminder', error);
  }
};

export const cancelChallengeReminder = async (challengeId: string) => {
  try {
    const reminderData = await loadStoredReminder(challengeId);

    if (reminderData?.notificationIds?.length) {
      for (const notificationId of reminderData.notificationIds) {
        try {
          await Notifications.cancelScheduledNotificationAsync(notificationId);
        } catch (error) {
          console.error('[ChallengeReminderTask] Failed to cancel scheduled notification', error);
        }
      }
    }

    await removeStoredReminder(challengeId);
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to cancel reminder', error);
  }
};

export const registerChallengeReminderTask = async () => {
  try {
    const isRegistered = await TaskManager.isTaskRegisteredAsync(TASK_NAME);
    if (isRegistered) {
      await BackgroundTask.unregisterTaskAsync(TASK_NAME);
    }
    return true;
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to register task', error);
    return false;
  }
};

export const unregisterChallengeReminderTask = async () => {
  try {
    const isRegistered = await TaskManager.isTaskRegisteredAsync(TASK_NAME);
    if (isRegistered) {
      await BackgroundTask.unregisterTaskAsync(TASK_NAME);
    }
  } catch (error) {
    console.error('[ChallengeReminderTask] Failed to unregister task', error);
  }
};

export type { StoredReminder };
