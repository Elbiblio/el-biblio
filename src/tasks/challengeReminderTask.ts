import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import * as BackgroundTask from 'expo-background-task';
import * as TaskManager from 'expo-task-manager';

export const TASK_NAME = 'challenge-reminder-task';
export const CHALLENGE_REMINDER_PREFIX = 'challenge_reminder_';
export const CHALLENGE_REMINDER_INDEX_KEY = 'challenge_reminder_index';

type StoredReminder = {
  challengeId: string;
  challengeTitle?: string;
  reminderHours: number;
  scheduledFor?: string;
  nextReminderDue: string;
  notificationIds?: string[];
  lastReminderSentAt?: string;
};

const defineTaskOnce = () => {
  const alreadyDefined = typeof TaskManager.isTaskDefined === 'function'
    ? TaskManager.isTaskDefined(TASK_NAME)
    : false;

  if (alreadyDefined) {
    return;
  }

  TaskManager.defineTask(TASK_NAME, async () => {
    try {
      const reminderKeys = await getReminderIndex();
      if (!reminderKeys.length) {
        return BackgroundTask.BackgroundTaskResult.Success;
      }

      const now = Date.now();
      for (const reminderKey of reminderKeys) {
        try {
          const storedReminder = await AsyncStorage.getItem(reminderKey);
          if (!storedReminder) {
            continue;
          }

          const reminder: StoredReminder = JSON.parse(storedReminder);
          if (!reminder?.nextReminderDue) {
            continue;
          }

          const nextDue = Date.parse(reminder.nextReminderDue);
          if (Number.isNaN(nextDue)) {
            continue;
          }

          if (now < nextDue) {
            continue;
          }

          const title = reminder.challengeTitle || 'Challenge check-in';
          const body = `Hey friend! "${reminder.challengeTitle || 'Your challenge'}" is waiting for you.`;

          await Notifications.scheduleNotificationAsync({
            content: {
              title,
              body,
              sound: true,
              priority: Notifications.AndroidNotificationPriority.HIGH,
            },
            trigger: null,
          });

          const hours = reminder.reminderHours || 1;
          const updatedDue = new Date(now + hours * 60 * 60 * 1000).toISOString();
          const updated: StoredReminder = {
            ...reminder,
            nextReminderDue: updatedDue,
            lastReminderSentAt: new Date(now).toISOString(),
          };

          await storeReminderPayload(reminderKey, updated);
        } catch (innerError) {
          console.error('[ChallengeReminderTask] Failed to process reminder', reminderKey, innerError);
        }
      }

      return BackgroundTask.BackgroundTaskResult.Success;
    } catch (error) {
      console.error('[ChallengeReminderTask] Background task error', error);
      return BackgroundTask.BackgroundTaskResult.Failed;
    }
  });
};

defineTaskOnce();

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

export const registerChallengeReminderTask = async () => {
  try {
    const status = await BackgroundTask.getStatusAsync();

    if (status !== BackgroundTask.BackgroundTaskStatus.Available) {
      if (status === BackgroundTask.BackgroundTaskStatus.Restricted) {
        console.warn('[ChallengeReminderTask] Background tasks restricted on this device');
      } else {
        console.warn('[ChallengeReminderTask] Background task status', status);
      }
      return false;
    }

    const isRegistered = await TaskManager.isTaskRegisteredAsync(TASK_NAME);
    if (!isRegistered) {
      await BackgroundTask.registerTaskAsync(TASK_NAME, {
        minimumInterval: 15 * 60,
      });
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
