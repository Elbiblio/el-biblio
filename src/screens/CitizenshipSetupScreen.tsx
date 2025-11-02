import React, { useMemo, useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Modal } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { HABIT_CONQUEST_SCOPE_PARAMS } from '@/stores/DailyPathStore';
import type { DailyFocusKey } from '@/stores/DailyPathStore';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import { ArrowLeft, BookOpen, NotePencil, Shield, Flame, Heart, Trophy, Check } from '@/components/Icons';
import { toast } from 'sonner-native';
import { scheduleReviveReminders } from '@/tasks/reviveReminderScheduler';

const focusOptions: {
  key: DailyFocusKey;
  title: string;
  short: string;
  description: string;
  icon: React.ComponentType<{ size?: number; color?: string }>;
  accent: (theme: Theme) => string;
}[] = [
  {
    key: 'revive',
    title: 'Revive My Spiritual Life',
    short: 'Develop a working personal relationship with God',
    description: 'Receive gentle guidance to rekindle devotion, prayer, and personal time with God.',
    icon: Flame,
    accent: theme => theme.colors.primary,
  },
  {
    key: 'meditation',
    title: 'Relax & Meditate with God',
    short: 'Tame the mind and refresh the spirit: Psalm 46:10',
    description: 'Use breathing, reflection, and scripture meditation to slow down with the Spirit.',
    icon: Heart,
    accent: theme => theme.colors.warning,
  },
  {
    key: 'knowledge',
    title: 'Deepen My Faith Knowledge',
    short: 'I want to study scripture',
    description: 'Explore curated Bible readings and insights to strengthen your understanding.',
    icon: BookOpen,
    accent: theme => theme.colors.info,
  },
  {
    key: 'habits',
    title: 'Discipleship',
    short: 'Daily challenges',
    description: 'Set daily challenges to help others, grow your faith and gain spiritual wealth.',
    icon: NotePencil,
    accent: theme => theme.colors.secondary,
  },
  {
    key: 'habit_conquest',
    title: 'Conquer Harmful Habits',
    short: 'Break the patterns stealing your devotion',
    description:
      'Engage daily precepts that expose the world’s distortions, rebuild holy discipline, and align with God’s design.',
    icon: Shield,
    accent: theme => theme.colors.success,
  },
];

type Navigation = NativeStackNavigationProp<RootStackParamList>;

const CitizenshipSetupScreen = observer(() => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const navigation = useNavigation<Navigation>();
  const dailyPathStore = useDailyPathStore();
  const [showReviveChecklist, setShowReviveChecklist] = useState(false);
  const [reviveSelections, setReviveSelections] = useState<string[]>([]);
  const [selectedFocuses, setSelectedFocuses] = useState<DailyFocusKey[]>(
    dailyPathStore.primaryFocus ? [dailyPathStore.primaryFocus, ...dailyPathStore.secondaryFocus.filter(item => item !== dailyPathStore.primaryFocus)] : dailyPathStore.secondaryFocus
  );
  const [enableChallenges, setEnableChallenges] = useState<boolean>(dailyPathStore.isChallengesEnabled);
  const [isSaving, setIsSaving] = useState(false);
  const [isSchedulingRevive, setIsSchedulingRevive] = useState(false);
  const primaryOption = useMemo(() => focusOptions.find(option => option.key === selectedFocuses[0]), [selectedFocuses]);

  const toggleSelection = useCallback((focus: DailyFocusKey) => {
    setSelectedFocuses(prev => {
      const exists = prev.includes(focus);
      if (exists) {
        const next = prev.filter(item => item !== focus);
        if (focus === 'habits') {
          setEnableChallenges(false);
        }
        return next;
      }
      const next = prev.length >= 4 ? [prev[1], prev[2], prev[3], focus] : [...prev, focus];
      if (focus === 'habits') {
        setEnableChallenges(true);
      }
      return next;
    });
  }, []);

  const handleSave = useCallback(async () => {
    if (isSaving) {
      return;
    }
    setIsSaving(true);
    try {
      const [firstFocus, secondFocus] = selectedFocuses;
      const remaining = selectedFocuses.slice(1);
      dailyPathStore.setFocuses(firstFocus ?? 'revive', remaining);

      const includesKnowledge = selectedFocuses.includes('knowledge');
      const includesDiscipleship = selectedFocuses.includes('habits');
      const includesHabitConquest = selectedFocuses.includes('habit_conquest');
      const includesRevive = selectedFocuses.includes('revive');

      // Unlocks and flags
      if (selectedFocuses.includes('habits')) {
        dailyPathStore.setChallengesEnabled(true);
        dailyPathStore.setViewedChallengeSelection(true);
        dailyPathStore.setChallengeOnboardingCompleted(false);
        setEnableChallenges(true);
      } else {
        dailyPathStore.setChallengesEnabled(enableChallenges);
      }

      dailyPathStore.markSetupComplete();

      // Post-setup flows: prioritize Reading Plan > Challenges > Revive checklist
      if (includesKnowledge) {
        navigation.navigate('BibleScreen', { openPlanSetup: true } as any);
      } else if (includesHabitConquest) {
        navigation.navigate('BibleScreen', HABIT_CONQUEST_SCOPE_PARAMS);
      } else if (includesDiscipleship) {
        navigation.navigate('DailyChallengeScreen', { onboarding: true });
      } else if (includesRevive) {
        setShowReviveChecklist(true);
      } else {
        navigation.navigate('Home');
      }
    } finally {
      setIsSaving(false);
    }
  }, [dailyPathStore, enableChallenges, isSaving, navigation, selectedFocuses]);

  return (
    <View style={[styles.container, { paddingTop: insets.top + theme.spacing.md }]}> 
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <ArrowLeft size={22} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <View style={styles.headerTextGroup}>
          <Text style={styles.heading}>Shape Your Daily Path</Text>
          {
            selectedFocuses.length == 0 ?
          <Text style={styles.subheading}>
            Choose where you want to grow so we can guide your kingdom citizenship journey.
          </Text>:
          <Text style={styles.subheading}>
            {selectedFocuses.length == 1 ? 'Great, select one more' :
             (selectedFocuses.length == 2 ? "Perfect let's get started" :
             (selectedFocuses.length == 3 ? "Getting excited are you?..." : 
             "Are you a spiritual entrepereneur?..."))
            }.
          </Text>
          }
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Choose what you need most</Text>
          <Text style={styles.sectionDescription}>
            Pick up to two areas. We will tailor readings, prompts, and challenges around them.
          </Text>
          <View style={styles.optionGrid}>
            {focusOptions.map(option => {
              const Icon = option.icon;
              const isSelected = selectedFocuses.includes(option.key);
              const accent = option.accent(theme);
              return (
                <TouchableOpacity
                  key={option.key}
                  style={[styles.optionCard, isSelected && [styles.optionCardSelected, { borderColor: accent }]]}
                  activeOpacity={0.85}
                  onPress={() => toggleSelection(option.key)}
                >
                  <View style={[styles.iconBadge, { backgroundColor: isSelected ? `${accent}16` : `${theme.colors.primary}10` }]}> 
                    <Icon size={20} color={accent} />
                  </View>
                  <Text style={styles.optionTitle}>{option.title}</Text>
                  <Text style={styles.optionSubtitle}>{option.short}</Text>
                  {isSelected ? (
                    <Text style={styles.optionDescription}>{option.description}</Text>
                  ) : null}
                  {isSelected && (
                    <View style={[styles.checkBadge, { backgroundColor: accent }]}>
                      <Check size={16} color={theme.colors.text.inverse} />
                    </View>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

      </ScrollView>

      <View style={styles.footer}>
        <TouchableOpacity
          style={[styles.saveButton, (selectedFocuses.length === 0 || isSaving) && styles.saveButtonDisabled]}
          activeOpacity={0.85}
          onPress={handleSave}
          disabled={selectedFocuses.length === 0 || isSaving}
        >
          <Text style={styles.saveButtonText}>{selectedFocuses.length === 0 ? 'Select an area' : isSaving ? 'Saving...' : 'Get Started'}</Text>
        </TouchableOpacity>
      </View>

      {/* Revive checklist modal */}
      {showReviveChecklist && (
        <Modal visible transparent animationType="slide" onRequestClose={() => setShowReviveChecklist(false)}>
          <View style={styles.modalOverlay}>
            <View style={styles.modalCard}>
              <Text style={styles.modalTitle}>Revive Daily Checklist</Text>
              <Text style={styles.modalSubtitle}>Pick up to three items to set reminders for.</Text>
              {['Morning prayer', 'Midday pause (5m)', 'Evening reflection', 'Gratitude note', 'Digital quiet hour'].map(item => {
                const active = reviveSelections.includes(item);
                return (
                  <TouchableOpacity
                    key={item}
                    style={[styles.modalItem, active && styles.modalItemActive]}
                    onPress={() => setReviveSelections(prev => {
                      const exists = prev.includes(item);
                      if (exists) return prev.filter(x => x !== item);
                      if (prev.length >= 3) return prev; 
                      return [...prev, item];
                    })}
                    activeOpacity={0.85}
                  >
                    <Text style={[styles.modalItemText, active && styles.modalItemTextActive]}>{item}</Text>
                  </TouchableOpacity>
                );
              })}
              <View style={styles.modalActions}>
                <TouchableOpacity style={styles.modalSecondary} onPress={() => { setShowReviveChecklist(false); navigation.navigate('Home'); }}>
                  <Text style={styles.modalSecondaryText}>Skip</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.modalPrimary, (reviveSelections.length === 0 || isSchedulingRevive) && styles.modalPrimaryDisabled]}
                  disabled={reviveSelections.length === 0 || isSchedulingRevive}
                  onPress={async () => {
                    if (isSchedulingRevive) {
                      return;
                    }
                    setIsSchedulingRevive(true);
                    try {
                      const schedules = await scheduleReviveReminders(reviveSelections);
                      dailyPathStore.setReviveReminderItems(reviveSelections);
                      dailyPathStore.setReviveReminderSchedules(schedules);
                      dailyPathStore.setReviveRemindersConfigured(true);
                      toast.success('Revive reminders scheduled');
                      setShowReviveChecklist(false);
                      navigation.navigate('Home');
                    } catch (error) {
                      toast.error('Unable to schedule reminders. Check notification permissions.');
                    } finally {
                      setIsSchedulingRevive(false);
                    }
                  }}
                >
                  <Text style={styles.modalPrimaryText}>{isSchedulingRevive ? 'Scheduling…' : 'Set Reminders'}</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      )}
    </View>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.lg,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
    marginRight: theme.spacing.md,
  },
  headerTextGroup: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  heading: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  subheading: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 20,
  },
  scrollContent: {
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.xl + theme.spacing.xl,
    gap: theme.spacing.xl,
  },
  section: {
    gap: theme.spacing.sm,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  sectionDescription: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
    marginBottom: theme.spacing.md,
    lineHeight: 18,
  },
  optionGrid: {
    flexDirection: 'column',
    gap: theme.spacing.md,
  },
  optionCard: {
    position: 'relative',
    alignSelf: 'stretch',
    borderRadius: theme.borderRadius.xl,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.lg,
    gap: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 12,
    elevation: 2,
  },
  optionCardSelected: {
    shadowOpacity: 0.15,
    elevation: 4,
  },
  optionSubtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  optionDescription: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    lineHeight: 18,
  },
  iconBadge: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  checkBadge: {
    position: 'absolute',
    top: theme.spacing.md,
    right: theme.spacing.md,
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 6,
    elevation: 3,
  },
  footer: {
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.xl + theme.spacing.sm,
    paddingTop: theme.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  saveButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
  },
  saveButtonDisabled: {
    opacity: 0.6,
  },
  saveButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  modalCard: {
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  modalTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  modalSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.md,
  },
  modalItem: {
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.sm,
  },
  modalItemActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  modalItemText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  modalItemTextActive: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  modalActions: {
    marginTop: theme.spacing.md,
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: theme.spacing.sm,
  },
  modalSecondary: {
    flex: 1,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.surface,
  },
  modalSecondaryText: {
    ...theme.typography.button,
    color: theme.colors.text.primary,
  },
  modalPrimary: {
    flex: 1,
    borderRadius: theme.borderRadius.lg,
    paddingVertical: theme.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
  },
  modalPrimaryDisabled: {
    opacity: 0.5,
  },
  modalPrimaryText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  },
});

export default CitizenshipSetupScreen;
