import { apiClient, endpoints } from '@/api/client';
import AsyncStorage from '@react-native-async-storage/async-storage';

const SYNC_STORAGE_PREFIX = 'reminder_preferences_synced';

export type ReminderType =
  | 'daily_reminder'
  | 'reading_reminder'
  | 'challenge_reminder'
  | 'revive_reminder'
  | 'habit_conquest_reminder';

export type ReminderTime = {
  hour: number;
  minute: number;
};

export interface ReminderPreference {
  reminder_type: ReminderType;
  enabled: boolean;
  reminder_times: ReminderTime[];
  timezone?: string;
}

export interface ReminderPreferenceResponse {
  preferences: ReminderPreference[];
}

export class ReminderSyncService {
  static async syncToBackend(
    userId: string,
    reminderType: ReminderType,
    enabled: boolean,
    times: ReminderTime[]
  ): Promise<boolean> {
    try {
      if (!userId) {
        if (__DEV__) {
          console.warn('[ReminderSync] Cannot sync reminders: user not authenticated');
        }
        return false;
      }

      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

      const payload = {
        reminder_type: reminderType,
        enabled,
        reminder_times: times,
        timezone,
      };

      await apiClient.put(
        endpoints.users.reminderPreferences(userId),
        payload
      );

      await AsyncStorage.setItem(
        `${SYNC_STORAGE_PREFIX}_${reminderType}`,
        JSON.stringify({
          enabled,
          times,
          syncedAt: Date.now(),
        })
      );

      if (__DEV__) {
        console.log(`[ReminderSync] Reminder preferences synced for ${reminderType}`);
      }
      return true;
    } catch (error) {
      console.error('[ReminderSync] Failed to sync reminder preferences:', error);
      return false;
    }
  }

  static async loadFromBackend(userId: string): Promise<ReminderPreference[]> {
    try {
      if (!userId) {
        return [];
      }

      const response = await apiClient.get<{ preferences: ReminderPreference[] }>(
        endpoints.users.reminderPreferences(userId)
      );

      return response.data?.preferences || [];
    } catch (error) {
      console.error('[ReminderSync] Failed to load reminder preferences:', error);
      return [];
    }
  }

  static async syncAllLocalReminders(userId: string): Promise<void> {
    if (!userId) {
      if (__DEV__) {
        console.warn('[ReminderSync] Cannot sync: user not authenticated');
      }
      return;
    }

    const reminderTypes: ReminderType[] = [
      'daily_reminder',
      'reading_reminder',
      'challenge_reminder',
      'revive_reminder',
      'habit_conquest_reminder',
    ];

    for (const type of reminderTypes) {
      try {
        const local = await this.getLocalReminder(type);
        if (local) {
          await this.syncToBackend(userId, type, local.enabled, local.times);
        }
      } catch (error) {
        console.error(`[ReminderSync] Failed to sync ${type}:`, error);
      }
    }
  }

  private static async getLocalReminder(
    type: ReminderType
  ): Promise<{ enabled: boolean; times: ReminderTime[] } | null> {
    try {
      const storageKey = `${SYNC_STORAGE_PREFIX}_${type}`;
      const stored = await AsyncStorage.getItem(storageKey);

      if (!stored) {
        return null;
      }

      const parsed = JSON.parse(stored);
      return {
        enabled: parsed.enabled ?? true,
        times: parsed.times || [],
      };
    } catch (error) {
      console.error(`[ReminderSync] Error reading local reminder for ${type}:`, error);
      return null;
    }
  }

  static async getLocalReminderState(
    type: ReminderType
  ): Promise<{ enabled: boolean; times: ReminderTime[] } | null> {
    return this.getLocalReminder(type);
  }

  static async clearLocalReminder(type: ReminderType): Promise<void> {
    try {
      const storageKey = `${SYNC_STORAGE_PREFIX}_${type}`;
      await AsyncStorage.removeItem(storageKey);
    } catch (error) {
      console.error(`[ReminderSync] Error clearing local reminder for ${type}:`, error);
    }
  }

  static async clearAllLocalReminders(): Promise<void> {
    const reminderTypes: ReminderType[] = [
      'daily_reminder',
      'reading_reminder',
      'challenge_reminder',
      'revive_reminder',
      'habit_conquest_reminder',
    ];

    for (const type of reminderTypes) {
      await this.clearLocalReminder(type);
    }
  }

  static convertTimeStringToReminderTime(timeString: string | null): ReminderTime | null {
    if (!timeString) return null;

    const match = timeString.match(/^(\d{1,2}):(\d{2})$/);
    if (!match) return null;

    const hour = parseInt(match[1], 10);
    const minute = parseInt(match[2], 10);

    if (isNaN(hour) || isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return { hour, minute };
  }

  static convertReminderTimeToTimeString(time: ReminderTime): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${pad(time.hour)}:${pad(time.minute)}`;
  }

  static convertTimeStringsToReminderTimes(timeStrings: (string | null)[]): ReminderTime[] {
    return timeStrings
      .map((ts) => this.convertTimeStringToReminderTime(ts))
      .filter((t): t is ReminderTime => t !== null);
  }
}

