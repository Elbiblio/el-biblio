import { apiClient, endpoints, type APIResponse } from '@/api/client';
import type {
  HabitConquestSummary,
  HabitConquestJournalEntry,
  HabitConquestConfig,
  HabitConquestPhaseConfig,
} from '@/types/habitConquest';
import type { ReminderTime } from '@/services/reminderSync';

type RawReminder = { hour: number; minute: number };

type RawPhase = {
  id: string;
  label: string;
  minutes: number;
};

type RawHabitConquest = {
  id?: number | string;
  vice?: string | null;
  door_of_sin?: string | null;
  pledge_good?: string | null;
  daily_minutes?: number;
  split?: 'once' | 'twice' | 'thrice';
  phases?: RawPhase[];
  reminders_enabled?: boolean;
  reminder_times?: RawReminder[];
  timezone?: string | null;
  streak_current?: number;
  streak_longest?: number;
  clean_days?: number;
  last_checkin_date?: string | null;
  reminders?: {
    enabled?: boolean;
    times?: RawReminder[];
    timezone?: string | null;
  };
  streak?: {
    current?: number;
    longest?: number;
    clean_days?: number;
  };
};

type RawHabitConquestEntry = {
  id?: number | string;
  date: string;
  clean: boolean;
  pledged: boolean;
  mood?: string | null;
  note?: string | null;
  prayer_intent?: string | null;
  completed_at?: string | null;
};

type RawHabitConquestSummary = {
  habit_conquest: RawHabitConquest | null;
  today_entry: RawHabitConquestEntry | null;
  recent_entries: RawHabitConquestEntry[];
  missing_dates: string[];
  defaults?: {
    daily_minutes?: number;
    split?: 'once' | 'twice' | 'thrice';
    phases?: RawPhase[];
  };
};

type RawHabitConquestCheckinResponse = {
  entry: RawHabitConquestEntry;
  summary: RawHabitConquestSummary;
};

const toReminderTimes = (times?: RawReminder[] | ReminderTime[]): ReminderTime[] => {
  if (!Array.isArray(times)) return [];
  return times
    .map((slot) => ({
      hour: Number(slot.hour ?? 0),
      minute: Number(slot.minute ?? 0),
    }))
    .filter((slot) => slot.hour >= 0 && slot.hour < 24 && slot.minute >= 0 && slot.minute < 60);
};

const mapPhase = (raw: RawPhase): HabitConquestPhaseConfig => ({
  id: raw?.id ?? '',
  label: raw?.label ?? '',
  minutes: Math.max(0, Number(raw?.minutes ?? 0)),
});

const mapEntry = (raw: RawHabitConquestEntry): HabitConquestJournalEntry => ({
  id: raw.id ? String(raw.id) : undefined,
  date: raw.date,
  clean: !!raw.clean,
  pledged: !!raw.pledged,
  mood: (raw.mood as HabitConquestJournalEntry['mood']) ?? 'steady',
  note: raw.note ?? null,
  prayerIntent: raw.prayer_intent ?? null,
  completedAt: raw.completed_at ?? null,
});

const mapConfig = (raw: RawHabitConquest | null): HabitConquestConfig | null => {
  if (!raw) return null;
  const phases = Array.isArray(raw.phases) && raw.phases.length ? raw.phases.map(mapPhase) : [];
  const reminders = raw.reminders ?? {};
  const streak = raw.streak ?? {};
  return {
    id: raw.id ? String(raw.id) : undefined,
    vice: raw.vice ?? null,
    doorOfSin: raw.door_of_sin ?? null,
    pledgeGood: raw.pledge_good ?? null,
    dailyMinutes: Number(raw.daily_minutes ?? 10),
    split: (raw.split as HabitConquestConfig['split']) ?? 'once',
    phases,
    remindersEnabled: Boolean(
      reminders.enabled ??
        raw.reminders_enabled ??
        (Array.isArray(reminders.times ?? raw.reminder_times) && (reminders.times ?? raw.reminder_times)?.length),
    ),
    reminderTimes: toReminderTimes(reminders.times ?? raw.reminder_times),
    reminderTimezone: reminders.timezone ?? raw.timezone ?? null,
    streak: {
      current: Number(streak.current ?? raw.streak_current ?? 0),
      longest: Number(streak.longest ?? raw.streak_longest ?? 0),
      cleanDays: Number(streak.clean_days ?? raw.clean_days ?? 0),
    },
    lastCheckinDate: raw.last_checkin_date ?? null,
  };
};

const mapSummary = (raw: RawHabitConquestSummary): HabitConquestSummary => ({
  config: mapConfig(raw.habit_conquest),
  todayEntry: raw.today_entry ? mapEntry(raw.today_entry) : null,
  recentEntries: Array.isArray(raw.recent_entries) ? raw.recent_entries.map(mapEntry) : [],
  missingDates: raw.missing_dates ?? [],
  defaults: raw.defaults
    ? {
        daily_minutes: raw.defaults.daily_minutes,
        split: raw.defaults.split,
        phases: raw.defaults.phases?.map(mapPhase),
      }
    : undefined,
});

export interface HabitConquestSetupPayload {
  vice: string;
  doorOfSin?: string | null;
  pledgeGood?: string | null;
  dailyMinutes: number;
  split: 'once' | 'twice' | 'thrice';
  phases: HabitConquestPhaseConfig[];
  reminders?: {
    enabled: boolean;
    times?: ReminderTime[];
    timezone?: string | null;
  };
}

export interface HabitConquestEntryInput {
  date?: string;
  clean: boolean;
  pledged: boolean;
  mood: string;
  note?: string | null;
  prayerIntent?: string | null;
}

export const fetchHabitConquestSummary = async (): Promise<HabitConquestSummary> => {
  const response = await apiClient.get<RawHabitConquestSummary>(endpoints.habitConquest.base);
  if (!response.success) {
    throw new Error(response.message || 'Failed to load Habit Conquest');
  }
  return mapSummary(response.data);
};

export const saveHabitConquestConfig = async (
  payload: HabitConquestSetupPayload,
): Promise<HabitConquestSummary> => {
  const response = await apiClient.post<RawHabitConquestSummary>(endpoints.habitConquest.base, {
    vice: payload.vice,
    door_of_sin: payload.doorOfSin,
    pledge_good: payload.pledgeGood,
    daily_minutes: payload.dailyMinutes,
    split: payload.split,
    phases: payload.phases?.map((phase) => ({
      id: phase.id,
      label: phase.label,
      minutes: phase.minutes,
    })),
    reminders: payload.reminders
      ? {
          enabled: payload.reminders.enabled,
          times: payload.reminders.times,
          timezone: payload.reminders.timezone,
        }
      : undefined,
  });
  if (!response.success) {
    throw new Error(response.message || 'Failed to save Habit Conquest');
  }
  return mapSummary(response.data);
};

export const recordHabitConquestCheckin = async (args: {
  date?: string;
  clean: boolean;
  pledged: boolean;
}): Promise<{ entry: HabitConquestJournalEntry; summary: HabitConquestSummary }> => {
  const response = await apiClient.post<RawHabitConquestCheckinResponse>(endpoints.habitConquest.checkins, {
    date: args.date,
    clean: args.clean,
    pledged: args.pledged,
  });
  if (!response.success) {
    throw new Error(response.message || 'Failed to record check-in');
  }
  return {
    entry: mapEntry(response.data.entry),
    summary: mapSummary(response.data.summary),
  };
};

export const recordHabitConquestEntry = async (
  args: HabitConquestEntryInput,
): Promise<{ entry: HabitConquestJournalEntry; summary: HabitConquestSummary }> => {
  const response = await apiClient.post<RawHabitConquestCheckinResponse>(endpoints.habitConquest.entries, {
    date: args.date,
    clean: args.clean,
    pledged: args.pledged,
    mood: args.mood,
    note: args.note,
    prayer_intent: args.prayerIntent,
  });
  if (!response.success) {
    throw new Error(response.message || 'Failed to save reflection');
  }
  return {
    entry: mapEntry(response.data.entry),
    summary: mapSummary(response.data.summary),
  };
};

export const fetchHabitConquestHistory = async (perPage = 60): Promise<HabitConquestJournalEntry[]> => {
  const response = await apiClient.get<{ data: RawHabitConquestEntry[] }>(endpoints.habitConquest.history, {
    per_page: perPage,
  });
  if (!response.success) {
    throw new Error(response.message || 'Failed to load history');
  }
  const entries = Array.isArray(response.data.data) ? response.data.data : [];
  return entries.map(mapEntry);
};

type RawHabitConquestReminderResponse = {
  reminders?: {
    reminder_type?: string;
    enabled?: boolean;
    reminder_times?: RawReminder[];
    timezone?: string | null;
  };
  summary: RawHabitConquestSummary;
};

export const syncHabitConquestReminders = async (payload: {
  enabled: boolean;
  times?: ReminderTime[];
  timezone?: string | null;
}): Promise<HabitConquestSummary> => {
  const response = await apiClient.post<RawHabitConquestReminderResponse>(endpoints.habitConquest.reminders, {
    enabled: payload.enabled,
    times: payload.times ?? [],
    timezone: payload.timezone ?? null,
  });
  if (!response.success) {
    throw new Error(response.message || 'Failed to sync reminders');
  }
  return mapSummary(response.data.summary);
};
