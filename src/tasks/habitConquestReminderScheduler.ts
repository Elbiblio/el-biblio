import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import * as Notifications from 'expo-notifications';

const STORAGE_KEY = 'habit_conquest_reminder_schedules_v1';
const CHANNEL_ID = 'habit-conquest-reminders';

type Time = { hour: number; minute: number };
export type HabitConquestSplit = 'once' | 'twice' | 'thrice';

export type HabitConquestReminder = {
  label: string; // Morning / Midday / Evening
  hour: number;
  minute: number;
  notificationId: string;
  followUpId?: string; // progressive follow-up id
};

const parseSchedules = (value: string | null): HabitConquestReminder[] => {
  if (!value) return [];
  try {
    const parsed = JSON.parse(value);
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((e) => ({
        label: String(e.label ?? ''),
        hour: Number(e.hour ?? 0),
        minute: Number(e.minute ?? 0),
        notificationId: String(e.notificationId ?? ''),
        followUpId: e.followUpId ? String(e.followUpId) : undefined,
      }))
      .filter((e) => e.label && e.notificationId);
  } catch (err) {
    console.warn('[HCReminder] parse failed', err);
    return [];
  }
};

const storeSchedules = async (schedules: HabitConquestReminder[]) => {
  if (!schedules.length) {
    await AsyncStorage.removeItem(STORAGE_KEY);
    return;
  }
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(schedules));
};

const ensurePermissionsAsync = async () => {
  const { status } = await Notifications.getPermissionsAsync();
  if (status === 'granted') return;
  const req = await Notifications.requestPermissionsAsync();
  if (req.status !== 'granted') throw new Error('Notification permissions were not granted');
};

const ensureChannelAsync = async () => {
  if (Platform.OS !== 'android') return;
  await Notifications.setNotificationChannelAsync(CHANNEL_ID, {
    name: 'Habit Conquest reminders',
    importance: Notifications.AndroidImportance.HIGH,
    sound: 'default',
    enableVibrate: true,
  });
};

const buckets: Record<HabitConquestSplit, Array<{ label: string; time: Time }>> = {
  once: [
    { label: 'Morning', time: { hour: 8, minute: 0 } },
  ],
  twice: [
    { label: 'Morning', time: { hour: 8, minute: 0 } },
    { label: 'Midday', time: { hour: 13, minute: 0 } },
  ],
  thrice: [
    { label: 'Morning', time: { hour: 8, minute: 0 } },
    { label: 'Afternoon', time: { hour: 16, minute: 0 } },
    { label: 'Evening', time: { hour: 20, minute: 0 } },
  ],
};

const addMinutes = (time: Time, delta: number): Time => {
  const total = time.hour * 60 + time.minute + delta;
  const wrapped = ((total % (24 * 60)) + (24 * 60)) % (24 * 60);
  return { hour: Math.floor(wrapped / 60), minute: wrapped % 60 };
};

export const getStoredHabitConquestSchedules = async (): Promise<HabitConquestReminder[]> => {
  const stored = await AsyncStorage.getItem(STORAGE_KEY);
  return parseSchedules(stored);
};

export const cancelHabitConquestReminders = async () => {
  const existing = await getStoredHabitConquestSchedules();
  if (existing.length) {
    await Promise.all(existing.map(async (s) => {
      try { await Notifications.cancelScheduledNotificationAsync(s.notificationId); } catch {}
      if (s.followUpId) { try { await Notifications.cancelScheduledNotificationAsync(s.followUpId); } catch {} }
    }));
  }
  await AsyncStorage.removeItem(STORAGE_KEY);
};

export const scheduleHabitConquestReminders = async (
  split: HabitConquestSplit,
  vice?: string | null,
  minutes?: number | null,
  progressiveFollowUpMinutes: number = 30,
): Promise<HabitConquestReminder[]> => {
  await ensurePermissionsAsync();
  await ensureChannelAsync();
  await cancelHabitConquestReminders();

  const slots = buckets[split] ?? buckets.once;
  const titleBase = 'Habit Conquest';
  const detail = vice ? `Focus: ${vice}.` : 'Stay faithful.';
  const minutesText = minutes ? `${minutes} min today.` : '';

  const schedules: HabitConquestReminder[] = [];
  for (const { label, time } of slots) {
    const notificationId = await Notifications.scheduleNotificationAsync({
      content: {
        title: `${titleBase} — ${label}`,
        body: `${detail} ${minutesText}`.trim(),
        sound: 'default',
        priority: Notifications.AndroidNotificationPriority.HIGH,
      },
      trigger: { hour: time.hour, minute: time.minute, repeats: true, channelId: CHANNEL_ID },
    });

    const follow = addMinutes(time, progressiveFollowUpMinutes);
    const followUpId = await Notifications.scheduleNotificationAsync({
      content: {
        title: `${titleBase} — ${label} (gentle nudge)`,
        body: `If you haven't started yet, now's a good time. ${minutesText}`.trim(),
        sound: 'default',
        priority: Notifications.AndroidNotificationPriority.DEFAULT,
      },
      trigger: { hour: follow.hour, minute: follow.minute, repeats: true, channelId: CHANNEL_ID },
    });

    schedules.push({ label, hour: time.hour, minute: time.minute, notificationId, followUpId });
  }

  await storeSchedules(schedules);
  return schedules;
};

export const ensureHabitConquestRemindersActive = async (
  split: HabitConquestSplit,
  vice?: string | null,
  minutes?: number | null,
  progressiveFollowUpMinutes: number = 30,
): Promise<HabitConquestReminder[]> => {
  const target = await getStoredHabitConquestSchedules();
  if (target.length) {
    try {
      await ensurePermissionsAsync();
      await ensureChannelAsync();
      const existing = await Notifications.getAllScheduledNotificationsAsync();
      const missing = target.filter(t => !existing.some(n => n.identifier === t.notificationId));
      if (!missing.length) return target;
    } catch (e) {
      console.warn('[HCReminder] ensure failed, rescheduling', e);
    }
  }
  return scheduleHabitConquestReminders(split, vice, minutes, progressiveFollowUpMinutes);
};
