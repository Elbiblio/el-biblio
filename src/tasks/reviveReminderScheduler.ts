import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import * as Notifications from 'expo-notifications';

import { ReviveReminderSchedule } from '@/stores/DailyPathStore';

const STORAGE_KEY = 'revive_reminder_schedules';
const CHANNEL_ID = 'revive-reminders';

export const REVIVE_REMINDER_DEFAULT_TIMES: ReadonlyArray<{ hour: number; minute: number }> = [
  { hour: 8, minute: 0 },
  { hour: 13, minute: 0 },
  { hour: 20, minute: 0 },
];

const parseSchedules = (value: string | null): ReviveReminderSchedule[] => {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed
      .map((entry) => ({
        item: String(entry.item ?? ''),
        hour: Number(entry.hour ?? 0),
        minute: Number(entry.minute ?? 0),
        notificationId: String(entry.notificationId ?? ''),
      }))
      .filter((entry) => entry.item && entry.notificationId);
  } catch (error) {
    console.warn('[ReviveReminderScheduler] Failed to parse schedules', error);
    return [];
  }
};

const storeSchedules = async (schedules: ReviveReminderSchedule[]) => {
  if (!schedules.length) {
    await AsyncStorage.removeItem(STORAGE_KEY);
    return;
  }
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(schedules));
};

const ensurePermissionsAsync = async () => {
  const { status } = await Notifications.getPermissionsAsync();
  if (status === 'granted') {
    return;
  }
  const request = await Notifications.requestPermissionsAsync();
  if (request.status !== 'granted') {
    throw new Error('Notification permissions were not granted');
  }
};

const ensureChannelAsync = async () => {
  if (Platform.OS !== 'android') {
    return;
  }
  await Notifications.setNotificationChannelAsync(CHANNEL_ID, {
    name: 'Revive reminders',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
    enableVibrate: true,
  });
};

export const getStoredReviveReminderSchedules = async (): Promise<ReviveReminderSchedule[]> => {
  const stored = await AsyncStorage.getItem(STORAGE_KEY);
  return parseSchedules(stored);
};

export const cancelReviveReminders = async () => {
  const existing = await getStoredReviveReminderSchedules();
  if (existing.length) {
    await Promise.all(
      existing.map(async (schedule) => {
        try {
          await Notifications.cancelScheduledNotificationAsync(schedule.notificationId);
        } catch (error) {
          console.warn('[ReviveReminderScheduler] Failed to cancel notification', schedule.notificationId, error);
        }
      }),
    );
  }
  await AsyncStorage.removeItem(STORAGE_KEY);
};

const resolveTimes = (items: string[], times?: { hour: number; minute: number }[]) => {
  const safeTimes = times && times.length === items.length ? times : undefined;
  return items.map((_, index) => {
    if (safeTimes) {
      return safeTimes[index];
    }
    return REVIVE_REMINDER_DEFAULT_TIMES[Math.min(index, REVIVE_REMINDER_DEFAULT_TIMES.length - 1)];
  });
};

export const scheduleReviveReminders = async (
  items: string[],
  options?: { times?: { hour: number; minute: number }[] },
): Promise<ReviveReminderSchedule[]> => {
  if (!items.length) {
    await cancelReviveReminders();
    return [];
  }

  await ensurePermissionsAsync();
  await ensureChannelAsync();
  await cancelReviveReminders();

  const trimmedItems = items.filter(Boolean).slice(0, REVIVE_REMINDER_DEFAULT_TIMES.length);
  const times = resolveTimes(trimmedItems, options?.times);

  const schedules: ReviveReminderSchedule[] = [];
  for (let index = 0; index < trimmedItems.length; index += 1) {
    const item = trimmedItems[index];
    const { hour, minute } = times[index];

    const notificationId = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Revive your spiritual life',
        body: `Take a moment today to ${item}.`,
        sound: 'default',
        priority: Notifications.AndroidNotificationPriority.HIGH,
      },
      trigger: {
        hour,
        minute,
        repeats: true,
        channelId: CHANNEL_ID,
      },
    });

    schedules.push({ item, hour, minute, notificationId });
  }

  await storeSchedules(schedules);
  return schedules;
};

export const ensureReviveRemindersActive = async (
  currentSchedules?: ReviveReminderSchedule[],
): Promise<ReviveReminderSchedule[]> => {
  const targetSchedules = (currentSchedules && currentSchedules.length
    ? currentSchedules
    : await getStoredReviveReminderSchedules()).slice(0, REVIVE_REMINDER_DEFAULT_TIMES.length);

  if (!targetSchedules.length) {
    return [];
  }

  try {
    await ensurePermissionsAsync();
    await ensureChannelAsync();
  } catch (error) {
    console.warn('[ReviveReminderScheduler] Permissions not granted, skip ensure', error);
    return targetSchedules;
  }

  const scheduledNotifications = await Notifications.getAllScheduledNotificationsAsync();
  const missing = targetSchedules.filter(
    (schedule) => !scheduledNotifications.some((notification) => notification.identifier === schedule.notificationId),
  );

  if (!missing.length) {
    return targetSchedules;
  }

  const restored = await scheduleReviveReminders(
    targetSchedules.map((schedule) => schedule.item),
    { times: targetSchedules.map(({ hour, minute }) => ({ hour, minute })) },
  );
  return restored;
};
