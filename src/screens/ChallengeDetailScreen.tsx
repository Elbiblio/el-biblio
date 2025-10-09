import React, { useEffect, useMemo, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, ActivityIndicator, Alert, Platform, Modal } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList, User } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useChallengeStore } from '@/stores/ChallengeStore';
import { ArrowLeft, ArrowUp, Users, Clock, Star, X, Calendar, Trophy } from '@/components/Icons';
import { LinearGradient } from 'expo-linear-gradient';
import * as Notifications from 'expo-notifications';
import AsyncStorage from '@react-native-async-storage/async-storage';


type Props = NativeStackScreenProps<RootStackParamList, 'ChallengeDetail'>;

const ChallengeDetailScreen = ({ route, navigation }: Props) => {
  const { id } = route.params;
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const store = useChallengeStore();

  // Gather challenge from any list in the store
  const challenge = useMemo(() => {
    return (
      store.state.personalChallenges.find(c => c.id === id) ||
      store.state.communityChallenges.find(c => c.id === id) ||
      store.state.suggestedChallenges.find(c => c.id === id)
    );
  }, [store.state.personalChallenges, store.state.communityChallenges, store.state.suggestedChallenges, id]);

  const [loadingParticipants, setLoadingParticipants] = useState(false);
  const [showReminderModal, setShowReminderModal] = useState(false);
  const [selectedReminderHours, setSelectedReminderHours] = useState<number>(6);
  const [forceUpdate, setForceUpdate] = useState(0);
  const [showReminderAlert, setShowReminderAlert] = useState(false);
  const [reminderDismissedUntil, setReminderDismissedUntil] = useState<Date | null>(null);

  useEffect(() => {
    navigation.setOptions?.({ headerShown: false });
  }, [navigation]);

  useEffect(() => {
    // If challenge not found in store, try to fetch it via participants endpoint
    if (!challenge) {
      store.fetchChallengeParticipants(id).catch(() => {
        // Silently fail, loading state will be handled by store
      });
    }
  }, [challenge, id, store]);

  // Check for reminder alerts
  useEffect(() => {
    if (!challenge?.hasJoined || challenge?.isCompleted) {
      return;
    }

    const checkReminderDue = async () => {
      try {
        const reminderKey = `challenge_reminder_${challenge.id}`;
        const storedReminder = await AsyncStorage.getItem(reminderKey);

        if (storedReminder) {
          const reminderData = JSON.parse(storedReminder);
          const nextReminderDue = new Date(reminderData.nextReminderDue);
          const now = new Date();

          // Check if reminder is due and not dismissed
          if (now >= nextReminderDue &&
              (!reminderDismissedUntil || now >= reminderDismissedUntil)) {
            setShowReminderAlert(true);
          }
        }
      } catch (error) {
        console.error('Error checking reminder due:', error);
      }
    };

    // Check immediately and then every minute
    checkReminderDue();
    const interval = setInterval(checkReminderDue, 60000); // Check every minute

    return () => clearInterval(interval);
  }, [challenge?.id, challenge?.hasJoined, challenge?.isCompleted, reminderDismissedUntil]);

  const handleJoinLeave = async () => {
    if (!challenge) return;
    try {
      if (challenge.hasJoined) {
        // Leave challenge - cancel any pending notifications
        await cancelChallengeReminder(challenge.id);
        await store.leaveChallenge(challenge.id);
        navigation.goBack();
      } else {
        // Join challenge - show reminder selection modal
        setShowReminderModal(true);
      }
    } catch (e) {
      Alert.alert('Error', 'Unable to update challenge membership.');
    }
  };

  const handleConfirmJoin = async () => {
    if (!challenge) return;
    try {
      await store.joinChallenge(challenge.id);
      
      // Schedule reminder notification
      await scheduleChallengeReminder(challenge, selectedReminderHours);
      
      setShowReminderModal(false);
      navigation.goBack();
    } catch (e) {
      Alert.alert('Error', 'Unable to join challenge.');
    }
  };

  const scheduleChallengeReminder = async (challenge: any, hours: number) => {
    try {
      // Request permissions if needed
      const { status } = await Notifications.getPermissionsAsync();
      if (status !== 'granted') {
        const { status: newStatus } = await Notifications.requestPermissionsAsync();
        if (newStatus !== 'granted') {
          console.log('Notification permissions not granted');
          return;
        }
      }

      // Schedule periodic notifications every X hours until challenge is completed
      const now = new Date();
      const challengeEndTime = challenge.endTime ? new Date(challenge.endTime) : null;

      // Schedule notifications every 'hours' interval, up to the challenge end time or max 24 hours
      const maxNotifications = challengeEndTime
        ? Math.min(24, Math.floor((challengeEndTime.getTime() - now.getTime()) / (hours * 60 * 60 * 1000)))
        : 24; // Max 24 notifications if no end time

      const notificationIds: string[] = [];

      for (let i = 1; i <= maxNotifications; i++) {
        const trigger = new Date(now.getTime() + (i * hours * 60 * 60 * 1000));

        // Don't schedule past the challenge end time
        if (challengeEndTime && trigger > challengeEndTime) break;

        const notificationId = await Notifications.scheduleNotificationAsync({
          content: {
            title: 'Daily Challenge Reminder',
            body: `Don't forget to complete your "${challenge.title}" challenge! Every ${hours} hour${hours > 1 ? 's' : ''} reminder.`,
            sound: true,
            priority: Notifications.AndroidNotificationPriority.HIGH,
          },
          trigger: {
            type: Notifications.SchedulableTriggerInputTypes.DATE,
            date: trigger,
          },
        });

        notificationIds.push(notificationId);
      }

      // Store reminder info locally
      const reminderKey = `challenge_reminder_${challenge.id}`;
      await AsyncStorage.setItem(reminderKey, JSON.stringify({
        challengeId: challenge.id,
        reminderHours: hours,
        scheduledFor: now.toISOString(),
        notificationIds,
        nextReminderDue: new Date(now.getTime() + (hours * 60 * 60 * 1000)).toISOString(),
      }));

    } catch (error) {
      console.error('Error scheduling periodic reminders:', error);
    }
  };

  const cancelChallengeReminder = async (challengeId: string) => {
    try {
      // Get stored reminder info to cancel specific notifications
      const reminderKey = `challenge_reminder_${challengeId}`;
      const storedReminder = await AsyncStorage.getItem(reminderKey);

      if (storedReminder) {
        const reminderData = JSON.parse(storedReminder);
        if (reminderData.notificationIds && Array.isArray(reminderData.notificationIds)) {
          // Cancel all scheduled notifications
          for (const notificationId of reminderData.notificationIds) {
            await Notifications.cancelScheduledNotificationAsync(notificationId);
          }
        }
      }

      // Remove stored reminder info
      await AsyncStorage.removeItem(reminderKey);
    } catch (error) {
      console.error('Error canceling reminder:', error);
    }
  };

  const handleUpvote = async () => {
    if (!challenge) return;
    try {
      await store.upvoteChallenge(challenge.id);
      // Force re-render to ensure UI updates
      setForceUpdate(prev => prev + 1);
    } catch (e) {
      Alert.alert('Error', 'Unable to upvote challenge.');
    }
  };

  const handleDismissReminder = async () => {
    if (!challenge) return;

    try {
      const reminderKey = `challenge_reminder_${challenge.id}`;
      const storedReminder = await AsyncStorage.getItem(reminderKey);

      if (storedReminder) {
        const reminderData = JSON.parse(storedReminder);
        const reminderHours = reminderData.reminderHours || 1;

        // Set dismissed until next reminder interval
        const dismissedUntil = new Date(Date.now() + (reminderHours * 60 * 60 * 1000));
        setReminderDismissedUntil(dismissedUntil);

        // Update stored reminder data with new next reminder time
        const updatedReminderData = {
          ...reminderData,
          nextReminderDue: dismissedUntil.toISOString(),
        };
        await AsyncStorage.setItem(reminderKey, JSON.stringify(updatedReminderData));
      }

      setShowReminderAlert(false);
    } catch (error) {
      console.error('Error dismissing reminder:', error);
    }
  };

  const handleCompleteFromReminder = async () => {
    if (!challenge) return;

    try {
      await store.completeChallenge(challenge.id, true);
      setShowReminderAlert(false);

      // Cancel future reminders since challenge is completed
      await cancelChallengeReminder(challenge.id);
    } catch (error) {
      console.error('Error completing challenge from reminder:', error);
      Alert.alert('Error', 'Unable to complete challenge.');
    }
  };

  const refreshParticipants = async () => {
    if (!challenge) return;
    try {
      setLoadingParticipants(true);
      await store.fetchChallengeParticipants(challenge.id);
    } catch (e) {
      // already handled in store
    } finally {
      setLoadingParticipants(false);
    }
  };

  if (!challenge) {
    return (
      <View style={[styles.container, { paddingTop: 48 }] }>
        <View style={styles.header}>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme?.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Challenge</Text>
          <View style={{ width: 40 }} />
        </View>
        <View style={styles.centerArea}>
          <ActivityIndicator color={theme?.colors.primary} />
          <Text style={styles.muted}>Loading challenge...</Text>
        </View>
      </View>
    );
  }

  const isVirtue = challenge.type === 'virtue';
  const color = isVirtue ? theme?.colors.success : theme?.colors.error;

  // Helper functions
  const getFrequencyLabel = (freq?: string) => {
    switch (freq) {
      case 'd': return 'Daily';
      case 'w': return 'Weekly';
      case 'm': return 'Monthly';
      default: return 'Daily';
    }
  };

  const getDifficultyLabel = (level?: string) => {
    switch (level) {
      case '1': return 'Beginner';
      case '2': return 'Intermediate';
      case '3': return 'Advanced';
      default: return 'Beginner';
    }
  };

  const formatDate = (dateStr?: string) => {
    if (!dateStr) return 'Ongoing';
    try {
      return new Date(dateStr).toLocaleDateString();
    } catch {
      return 'Ongoing';
    }
  };

  return (
    <>
    <View style={[styles.container, { paddingTop: 48 }] }>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme?.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Challenge</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.card}>
          <LinearGradient 
            colors={[`${color}15`, `${color}08`, `${color}03`]} 
            start={{ x: 0, y: 0 }} 
            end={{ x: 1, y: 1 }} 
            style={styles.cardGradient} 
          />

          {/* Status badges */}
          <View style={styles.statusContainer}>
            {challenge.hasJoined && (
              <View style={[styles.statusBadge, { backgroundColor: `${theme?.colors.success}20` }]}>
                <Star size={14} color={theme?.colors.success} />
                <Text style={[styles.statusText, { color: theme?.colors.success }]}>Joined</Text>
              </View>
            )}
            <View style={[styles.typeTag, { backgroundColor: `${color}15` }]}>
              {isVirtue ? <Star size={14} color={color} /> : <X size={14} color={color} />}
              <Text style={[styles.typeText, { color }]}>{challenge.theme_name || challenge.category.charAt(0).toUpperCase() + challenge.category.slice(1)}</Text>
            </View>
          </View>

          <Text style={styles.title}>{challenge.title}</Text>
          {!!challenge.description && (
            <Text style={styles.description}>{challenge.description}</Text>
          )}

          {/* Challenge details */}
          <View style={styles.detailsContainer}>
            <View style={styles.detailRow}>
              <View style={styles.detailIcon}>
                <Calendar size={16} color={theme?.colors.text.secondary} />
              </View>
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Start Date</Text>
                <Text style={styles.detailValue}>{formatDate(challenge.startDate)}</Text>
              </View>
            </View>

            <View style={styles.detailRow}>
              <View style={styles.detailIcon}>
                <Clock size={16} color={theme?.colors.text.secondary} />
              </View>
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Frequency</Text>
                <Text style={styles.detailValue}>{getFrequencyLabel(challenge.frequency)}</Text>
              </View>
            </View>

            <View style={styles.detailRow}>
              <View style={styles.detailIcon}>
                <Trophy size={16} color={theme?.colors.text.secondary} />
              </View>
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Difficulty</Text>
                <Text style={styles.detailValue}>{getDifficultyLabel(challenge.level)}</Text>
              </View>
            </View>

            {challenge.points && (
              <View style={styles.detailRow}>
                <View style={styles.detailIcon}>
                  <Star size={16} color={theme?.colors.primary} />
                </View>
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Points per Completion</Text>
                  <Text style={[styles.detailValue, { color: theme?.colors.primary, fontWeight: '700' }]}>
                    {challenge.points} pts
                  </Text>
                </View>
              </View>
            )}
          </View>

          {challenge.category === 'community' && (
            <View style={[styles.rowBetween, { marginTop: theme?.spacing.md }]}>
              <View style={styles.rowCenter}>
                <Users size={16} color={theme?.colors.text.secondary} />
                <Text style={styles.muted}>{challenge.participants || 0} joined</Text>
              </View>
              <TouchableOpacity style={[styles.pill, { backgroundColor: `${theme?.colors.text.secondary}10` }]} onPress={refreshParticipants}>
                {loadingParticipants ? (
                  <ActivityIndicator size="small" color={theme?.colors.text.secondary} />
                ) : (
                  <Text style={styles.pillText}>Refresh</Text>
                )}
              </TouchableOpacity>
            </View>
          )}
        </View>

        <View style={styles.actions}>
          {!challenge.hasUpvoted && (
            <TouchableOpacity style={[styles.actionBtn, { backgroundColor: `${theme?.colors.primary}15` }]} onPress={handleUpvote}>
              <ArrowUp size={18} color={theme?.colors.primary} />
              <Text style={[styles.actionText, { color: theme?.colors.primary }]}>Upvote</Text>
            </TouchableOpacity>
          )}

          <TouchableOpacity 
            style={[
              styles.joinBtn, 
              { 
                backgroundColor: challenge.hasJoined 
                  ? theme?.colors.success 
                  : theme?.colors.primary 
              }
            ]} 
            onPress={handleJoinLeave}
          >
            <Text style={styles.joinBtnText}>
              {challenge.hasJoined ? '✓ Joined' : 'Join Challenge'}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
      </View>

      {/* Reminder Selection Modal */}
      <Modal visible={showReminderModal} animationType="fade" transparent onRequestClose={() => setShowReminderModal(false)}>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Set Challenge Reminder</Text>
            <Text style={[styles.muted, { marginBottom: theme?.spacing.md }]}>
              Choose how often you'd like to be reminded to complete this challenge:
            </Text>

            <View style={{ gap: theme?.spacing.sm }}>
              {[1, 4, 6].map((hours) => (
                <TouchableOpacity
                  key={hours}
                  style={[
                    styles.reminderOption,
                    selectedReminderHours === hours && styles.reminderOptionSelected,
                  ]}
                  onPress={() => setSelectedReminderHours(hours)}
                >
                  <Clock size={20} color={selectedReminderHours === hours ? theme?.colors.primary : theme?.colors.text.secondary} />
                  <Text style={[
                    styles.reminderOptionText,
                    selectedReminderHours === hours && styles.reminderOptionTextSelected,
                  ]}>
                    Every {hours === 1 ? '1 hour' : `${hours} hours`}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <View style={[styles.formActions, { marginTop: theme?.spacing.lg }]}>
              <TouchableOpacity style={[styles.formButton, styles.cancelButton]} onPress={() => setShowReminderModal(false)}>
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.formButton, styles.createButton]} onPress={handleConfirmJoin}>
                <Text style={styles.createButtonText}>Join Challenge</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Reminder Alert Modal */}
      <Modal visible={showReminderAlert} animationType="fade" transparent>
        <View style={styles.modalBackdrop}>
          <View style={styles.alertModalCard}>
            <View style={styles.alertIconContainer}>
              <Clock size={32} color={theme?.colors.primary} />
            </View>
            <Text style={styles.alertTitle}>Time to Complete Your Challenge!</Text>
            <Text style={styles.alertMessage}>
              Don't forget to work on your "{challenge?.title}" challenge.
            </Text>

            <View style={[styles.formActions, { marginTop: theme?.spacing.lg }]}>
              <TouchableOpacity
                style={[styles.formButton, styles.cancelButton]}
                onPress={handleDismissReminder}
              >
                <Text style={styles.cancelButtonText}>Remind Me Later</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.formButton, styles.createButton]}
                onPress={handleCompleteFromReminder}
              >
                <Text style={styles.createButtonText}>Complete Now</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
      </>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme?.spacing.md,
    paddingBottom: theme?.spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  backButton: {
    padding: theme?.spacing.sm,
  },
  headerTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  content: {
    padding: theme?.spacing.md,
  },
  card: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  cardGradient: {
    ...StyleSheet.absoluteFillObject,
    borderTopLeftRadius: theme?.borderRadius.lg,
    borderTopRightRadius: theme?.borderRadius.lg,
  },
  statusContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.sm,
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
    gap: theme?.spacing.xs,
  },
  statusText: {
    ...theme?.typography.caption.secondary,
    fontWeight: '600',
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  rowCenter: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  typeTag: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
  },
  typeText: {
    ...theme?.typography.caption.primary,
    marginLeft: theme?.spacing.xs,
    fontWeight: '600',
  },
  timeText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.xs,
  },
  title: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.sm,
  },
  description: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.md,
  },
  detailsContainer: {
    gap: theme?.spacing.md,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
  },
  detailIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme?.colors.surface,
  },
  detailContent: {
    flex: 1,
  },
  detailLabel: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontWeight: '500',
  },
  detailValue: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '600',
    marginTop: 2,
  },
  muted: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.sm,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: theme?.spacing.sm,
    marginTop: theme?.spacing.lg,
  },
  pill: {
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.xs,
    borderRadius: theme?.borderRadius.full,
  },
  pillText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    color: theme?.colors.text.secondary,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    gap: theme?.spacing.xs,
  },
  actionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
  },
  joinBtn: {
    flex: 1,
    paddingVertical: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.2, shadowRadius: 8 },
      android: { elevation: 6 },
    }),
  },
  joinBtnText: {
    ...theme?.typography.body.sans,
    fontWeight: '700',
    color: '#FFFFFF',
    fontSize: 16,
  },
  centerArea: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
  },
  modalCard: {
    width: '100%',
    maxWidth: 520,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  reminderOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  reminderOptionSelected: {
    backgroundColor: `${theme?.colors.primary}10`,
    borderColor: theme?.colors.primary,
  },
  reminderOptionText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.sm,
  },
  reminderOptionTextSelected: {
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  modalTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme?.spacing.sm,
  },
  formActions: {
    flexDirection: 'row',
    gap: theme?.spacing.sm,
  },
  formButton: {
    flex: 1,
    paddingVertical: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cancelButton: {
    backgroundColor: `${theme?.colors.text.secondary}10`,
  },
  cancelButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  createButton: {
    backgroundColor: theme?.colors.primary,
  },
  createButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFFFFF',
    fontWeight: '600',
  },
  alertModalCard: {
    width: '100%',
    maxWidth: 400,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.xl,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    alignItems: 'center',
  },
  alertIconContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: `${theme?.colors.primary}15`,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.md,
  },
  alertTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme?.spacing.sm,
  },
  alertMessage: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme?.spacing.md,
  },
});

export default ChallengeDetailScreen;
