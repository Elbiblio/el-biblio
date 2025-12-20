import type { ReminderTime } from '@/services/reminderSync';

export const HABIT_CONQUEST_MOODS = [
  'renewed',
  'steady',
  'tired',
  'hopeful',
  'resilient',
  'convicted',
] as const;

export type HabitConquestMood = (typeof HABIT_CONQUEST_MOODS)[number];

export interface HabitConquestPhaseConfig {
  id: string;
  label: string;
  minutes: number;
}

export interface HabitConquestJournalEntry {
  id?: string;
  date: string;
  mood: HabitConquestMood;
  note?: string | null;
  clean: boolean;
  pledged: boolean;
  prayerIntent?: string | null;
  completedAt?: string | null;
}

export interface HabitConquestReflectionDraft {
  date: string;
  clean: boolean;
  pledged: boolean;
  mood: HabitConquestMood;
  note?: string | null;
}

export interface HabitConquestPrayerPayload extends HabitConquestReflectionDraft {
  prayerIntent?: string | null;
}

export interface HabitConquestEntryResponse {
  success: boolean;
  data?: {
    points_earned?: number;
    streak?: {
      current: number;
      longest: number;
      clean_days: number;
    };
  };
  message?: string;
}

export interface HabitConquestReflectionScreenParams {
  pendingDates?: string[];
}

export interface HabitConquestPrayerScreenParams {
  draft: HabitConquestPrayerPayload;
  remainingDates?: string[];
}

export interface HabitConquestStreak {
  current: number;
  longest: number;
  cleanDays: number;
}

export interface HabitConquestConfig {
  id?: string;
  vice: string | null;
  doorOfSin: string | null;
  pledgeGood: string | null;
  dailyMinutes: number;
  split: 'once' | 'twice' | 'thrice';
  phases: HabitConquestPhaseConfig[];
  remindersEnabled: boolean;
  reminderTimes: ReminderTime[];
  reminderTimezone?: string | null;
  streak: HabitConquestStreak;
  lastCheckinDate?: string | null;
}

export interface HabitConquestSummary {
  config: HabitConquestConfig | null;
  todayEntry: HabitConquestJournalEntry | null;
  recentEntries: HabitConquestJournalEntry[];
  missingDates: string[];
  defaults?: {
    daily_minutes?: number;
    split?: 'once' | 'twice' | 'thrice';
    phases?: HabitConquestPhaseConfig[];
  };
}

export interface HabitConquestHistoryResponse {
  data: HabitConquestJournalEntry[];
  meta?: {
    current_page?: number;
    last_page?: number;
    per_page?: number;
    total?: number;
  };
}
