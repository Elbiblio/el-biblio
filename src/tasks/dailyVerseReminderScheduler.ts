import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import * as Notifications from 'expo-notifications';

const STORAGE_KEY = 'daily_verse_reminder_schedules_v1';
const CHANNEL_ID = 'daily-verse-reminders';

export type DailyVerseReminderTime = { hour: number; minute: number };
export type DailyVerseReminderSchedule = DailyVerseReminderTime & { notificationId: string };

const parseSchedules = (value: string | null): DailyVerseReminderSchedule[] => {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((entry) => ({
        hour: Number(entry.hour ?? 0),
        minute: Number(entry.minute ?? 0),
        notificationId: String(entry.notificationId ?? ''),
      }))
      .filter((entry) => entry.notificationId);
  } catch {
    return [];
  }
};

const storeSchedules = async (schedules: DailyVerseReminderSchedule[]) => {
  if (!schedules.length) {
    await AsyncStorage.removeItem(STORAGE_KEY);
    return;
  }
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(schedules));
};

const ensurePermissionsAsync = async () => {
  const { status } = await Notifications.getPermissionsAsync();
  if (status === 'granted') return true;
  const request = await Notifications.requestPermissionsAsync();
  return request.status === 'granted';
};

const ensureChannelAsync = async () => {
  if (Platform.OS !== 'android') return;
  await Notifications.setNotificationChannelAsync(CHANNEL_ID, {
    name: 'Daily verse reminders',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
    enableVibrate: true,
  });
};

export const getStoredDailyVerseReminderSchedules = async (): Promise<DailyVerseReminderSchedule[]> => {
  const stored = await AsyncStorage.getItem(STORAGE_KEY);
  return parseSchedules(stored);
};

export const cancelDailyVerseReminders = async () => {
  const existing = await getStoredDailyVerseReminderSchedules();
  if (existing.length) {
    await Promise.all(
      existing.map(async (schedule) => {
        try {
          await Notifications.cancelScheduledNotificationAsync(schedule.notificationId);
        } catch {
          // ignore
        }
      })
    );
  }
  await AsyncStorage.removeItem(STORAGE_KEY);
};

const normalizeTimes = (times: DailyVerseReminderTime[]) => {
  const normalized = (times || [])
    .map((t) => ({
      hour: Math.min(23, Math.max(0, Number(t.hour ?? 0))),
      minute: Math.min(59, Math.max(0, Number(t.minute ?? 0))),
    }))
    .filter((t) => Number.isFinite(t.hour) && Number.isFinite(t.minute));

  const seen = new Set<string>();
  const unique: DailyVerseReminderTime[] = [];
  for (const t of normalized) {
    const key = `${t.hour}:${t.minute}`;
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(t);
  }

  unique.sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
  return unique;
};

export const scheduleDailyVerseReminders = async (
  times: DailyVerseReminderTime[]
): Promise<DailyVerseReminderSchedule[]> => {
  const normalizedTimes = normalizeTimes(times);
  if (!normalizedTimes.length) {
    await cancelDailyVerseReminders();
    return [];
  }

  const hasPermission = await ensurePermissionsAsync();
  if (!hasPermission) {
    return [];
  }

  await ensureChannelAsync();

  const existing = await getStoredDailyVerseReminderSchedules();
  const sameTimes =
    existing.length === normalizedTimes.length &&
    existing.every((e, idx) => e.hour === normalizedTimes[idx].hour && e.minute === normalizedTimes[idx].minute);

  if (sameTimes) {
    const scheduled = await Notifications.getAllScheduledNotificationsAsync();
    const missing = existing.filter((e) => !scheduled.some((n) => n.identifier === e.notificationId));
    if (!missing.length) {
      return existing;
    }
  }

  await cancelDailyVerseReminders();

  const schedules: DailyVerseReminderSchedule[] = [];
  for (const { hour, minute } of normalizedTimes) {
    const notificationId = await Notifications.scheduleNotificationAsync({
      content: {
        title: 'Daily Verse',
        body: 'Open El-Biblio for today\'s verse.',
        sound: 'default',
        priority: Notifications.AndroidNotificationPriority.HIGH,
        data: {
          type: 'daily_verse',
        },
      },
      trigger: {
        hour,
        minute,
        repeats: true,
        channelId: CHANNEL_ID,
      },
    });

    schedules.push({ hour, minute, notificationId });
  }

  await storeSchedules(schedules);
  return schedules;
};
