import * as Notifications from 'expo-notifications';
import { Challenge } from '@/types/challenges';
import {
  ensureChallengeReminderChannel,
  cancelChallengeReminder,
  upsertStoredReminder,
  CHALLENGE_REMINDER_CHANNEL_ID,
} from '@/tasks/challengeReminderTask';

export const scheduleChallengeReminder = async (
  challenge: Pick<Challenge, 'id' | 'title' | 'expiresAt'>,
  hours: number,
) => {
  try {
    const { status } = await Notifications.getPermissionsAsync();
    let permissionStatus = status;

    if (permissionStatus !== 'granted') {
      const { status: nextStatus } = await Notifications.requestPermissionsAsync();
      permissionStatus = nextStatus;

      if (permissionStatus !== 'granted') {
        return;
      }
    }

    await ensureChallengeReminderChannel();
    await cancelChallengeReminder(challenge.id);

    const now = new Date();
    let challengeEndTime: Date | null = null;
    if (challenge?.expiresAt) {
      const parsed = new Date(String(challenge.expiresAt));
      if (!Number.isNaN(parsed.getTime())) {
        challengeEndTime = parsed;
      }
    }

    const intervalMs = Math.max(1, hours) * 60 * 60 * 1000;
    const triggers: Date[] = [];
    const firstTrigger = new Date(now.getTime() + intervalMs);
    if (!challengeEndTime || firstTrigger <= challengeEndTime) {
      triggers.push(firstTrigger);
    }

    for (let i = 2; i <= 24; i += 1) {
      const triggerAt = new Date(now.getTime() + i * intervalMs);
      if (challengeEndTime && triggerAt > challengeEndTime) break;
      triggers.push(triggerAt);
    }

    if (!triggers.length) {
      await cancelChallengeReminder(challenge.id);
      return;
    }

    const notificationIds: string[] = [];
    for (const triggerAt of triggers) {
      const notificationId = await Notifications.scheduleNotificationAsync({
        content: {
          title: 'Daily Challenge Reminder',
          body: `Don't forget to complete your "${challenge.title}" challenge!`,
          sound: 'default',
          priority: Notifications.AndroidNotificationPriority.HIGH,
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: triggerAt,
          channelId: CHALLENGE_REMINDER_CHANNEL_ID,
        },
      });
      notificationIds.push(notificationId);
    }

    await upsertStoredReminder({
      challengeId: challenge.id,
      challengeTitle: challenge.title,
      reminderHours: hours,
      scheduledFor: now.toISOString(),
      nextReminderDue: triggers[0].toISOString(),
      notificationIds,
    });
  } catch (error) {
    console.error('[scheduleChallengeReminder] Failed to schedule reminder', error);
  }
};
