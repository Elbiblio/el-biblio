import React, { useMemo, useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Modal } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useDailyPathStore, useJourneyStore } from '@/stores/StoreProvider';
import { HABIT_CONQUEST_SCOPE_PARAMS } from '@/stores/DailyPathStore';
import ReadingPlanSetupModal from '@/components/ReadingPlanSetupModal';
import { useBibleStore } from '@/stores/BibleStore';
import { ReadingPlanMode, ReadingPlanPhase } from '@/constants/readingPlanModes';
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
  const bibleStore = useBibleStore();
  const journeyStore = useJourneyStore();
  const [showReviveChecklist, setShowReviveChecklist] = useState(false);
  const [reviveSelections, setReviveSelections] = useState<string[]>([]);
  const [selectedFocuses, setSelectedFocuses] = useState<DailyFocusKey[]>(
    dailyPathStore.primaryFocus ? [dailyPathStore.primaryFocus, ...dailyPathStore.secondaryFocus.filter(item => item !== dailyPathStore.primaryFocus)] : dailyPathStore.secondaryFocus
  );
  const [enableChallenges, setEnableChallenges] = useState<boolean>(dailyPathStore.isChallengesEnabled);
  const [isSaving, setIsSaving] = useState(false);
  const [isPlanSetupVisible, setIsPlanSetupVisible] = useState(false);
  const [isSchedulingRevive, setIsSchedulingRevive] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);
  const [showCareerSection, setShowCareerSection] = useState(false);
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

      if (includesKnowledge) {
        setIsPlanSetupVisible(true);
      } else {
        navigation.navigate('MyJourneyScreen');
      }
    } finally {
      setIsSaving(false);
    }
  }, [dailyPathStore, enableChallenges, isSaving, navigation, selectedFocuses]);

  const handleCreatePlan = useCallback(async ({ books, timePerDay, readingMode, phases, reminderTime, presetIds, minChaptersPerDay, maxChaptersPerDay, readingPaceWpm }: { books: string[]; timePerDay: number; readingMode: ReadingPlanMode; phases: ReadingPlanPhase[]; reminderTime?: string; presetIds?: string[]; minChaptersPerDay?: number; maxChaptersPerDay?: number; readingPaceWpm?: number }) => {
    try {
      await bibleStore.createReadingPlan({
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
        presetIds,
        minChaptersPerDay,
        maxChaptersPerDay,
        readingPaceWpm,
      });
      journeyStore.setBiblePlan({
        id: bibleStore.readingPlan?.id ?? '',
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
        presetIds: presetIds ?? [],
        focusVirtue: bibleStore.readingPlan?.focusVirtue ?? null,
      } as any);
    } finally {
      setIsPlanSetupVisible(false);
      navigation.navigate('MyJourneyScreen');
    }
  }, [bibleStore, journeyStore, navigation]);

  return (
    <View style={[styles.container, { paddingTop: insets.top + theme.spacing.md }]}> 
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <ArrowLeft size={22} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <View style={styles.headerTextGroup}>
          <Text style={styles.heading}>Kingdom Citizenship</Text>
          {
            currentStep === 0 ?
          <Text style={styles.subheading}>
            Seek ye first the Kingdom of God and his righteousness and everything will be added unto you.
          </Text>:
          currentStep === 1 ?
          <Text style={styles.subheading}>
            Understanding your spiritual inheritance and responsibility
          </Text>:
          currentStep === 2 ?
          <Text style={styles.subheading}>
            Aligning your work with God's purpose
          </Text>:
          <Text style={styles.subheading}>
            {selectedFocuses.length == 0 ? 'Choose your first focus area' :
             selectedFocuses.length == 1 ? 'Great, select one more' :
             (selectedFocuses.length == 2 ? "Perfect let's get started" :
             (selectedFocuses.length == 3 ? "Getting excited are you?..." : 
             "Is your earthly role sanctified?..."))
            }.
          </Text>
          }
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Step 0: Spiritual Foundation */}
        {currentStep === 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Your Spiritual Foundation</Text>
            <Text style={styles.sectionDescription}>
              We perish because of lack of knowledge. Once we truly know God a little, all our anxiety and worries will take a back seat.
            </Text>
            <View style={styles.guidanceCard}>
              <Text style={styles.guidanceText}>
                The only anxiety that remains is the anxiety of a lucky child that has a rich and kind generous dad—they don't know the type of discipline or kindness they would be shown next but they know it would be a good one and from the best of the best.
              </Text>
            </View>
            <TouchableOpacity style={styles.nextButton} onPress={() => setCurrentStep(1)}>
              <Text style={styles.nextButtonText}>Continue</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Step 1: Kingdom Citizenship */}
        {currentStep === 1 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Your Kingdom Inheritance</Text>
            <Text style={styles.sectionDescription}>
              By becoming a true citizen of God's kingdom, we inherit spiritual rights and authority to proclaim words over our own life in union with God and extend prayers to others.
            </Text>
            <View style={styles.warningCard}>
              <Text style={styles.warningTitle}>A Sacred Responsibility</Text>
              <Text style={styles.warningText}>
                This citizenship must be sought with discipline and firmness of mind. It's a position that is also dangerous because you don't throw pearls to swines.
              </Text>
            </View>
            <View style={styles.benefitsCard}>
              <Text style={styles.benefitsTitle}>Your Spiritual Rights</Text>
              <Text style={styles.benefitsText}>
                • Authority to proclaim words over your life in union with God{'\n'}
                • Ability to extend prayers to others effectively{'\n'}
                • Physical well-being: health, mental state, confidence{'\n'}
                • Inner peace and joy that transcends circumstances
              </Text>
            </View>
            <View style={styles.stepActions}>
              <TouchableOpacity style={styles.stepBackButton} onPress={() => setCurrentStep(0)}>
                <Text style={styles.backButtonText}>Back</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.nextButton} onPress={() => setCurrentStep(2)}>
                <Text style={styles.nextButtonText}>Continue</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* Step 2: Career Sanctification */}
        {currentStep === 2 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Sanctify Your Work</Text>
            <Text style={styles.sectionDescription}>
              Career wise, you should make adjustments to put your God-given gifts and talents first, essentially ensuring your work is sanctified within God's plan.
            </Text>
            <View style={styles.careerCard}>
              <Text style={styles.careerTitle}>Work as Worship</Text>
              <Text style={styles.careerText}>
                Your career is not separate from your spiritual journey. When you align your work with God's purpose, it becomes an act of worship and a channel for His blessings to flow through you.
              </Text>
            </View>
            <TouchableOpacity style={styles.nextButton} onPress={() => setCurrentStep(3)}>
              <Text style={styles.nextButtonText}>Choose Your Path</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Step 3: Choose Focus Areas */}
        {currentStep === 3 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Choose Your Growth Areas</Text>
            <Text style={styles.sectionDescription}>
              Select the areas where you want to focus your spiritual development. Each area will help you submit and unite your will with God for your purpose to fully blossom.
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
          <View style={styles.stepActions}>
            <TouchableOpacity style={styles.stepBackButton} onPress={() => setCurrentStep(2)}>
              <Text style={styles.backButtonText}>Back</Text>
            </TouchableOpacity>
          </View>
        </View>
        )}

      </ScrollView>

      {/* Only show footer on step 3 */}
      {currentStep === 3 && (
      <View style={[styles.footer, { paddingBottom: theme.spacing.xl + theme.spacing.sm + (insets.bottom || 0) }]}>
        <TouchableOpacity
          style={[styles.saveButton, (selectedFocuses.length === 0 || isSaving) && styles.saveButtonDisabled]}
          activeOpacity={0.85}
          onPress={handleSave}
          disabled={selectedFocuses.length === 0 || isSaving}
        >
          <Text style={styles.saveButtonText}>{selectedFocuses.length === 0 ? 'Select an area' : isSaving ? 'Saving...' : 'Get Started'}</Text>
        </TouchableOpacity>
      </View>
      )}

      {/* Revive checklist modal */}
      {showReviveChecklist && (
        <Modal visible={showReviveChecklist} transparent animationType="slide" onRequestClose={() => setShowReviveChecklist(false)}>
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
      <ReadingPlanSetupModal
        visible={isPlanSetupVisible}
        onClose={() => { setIsPlanSetupVisible(false); navigation.navigate('MyJourneyScreen'); }}
        onCreatePlan={handleCreatePlan}
      />
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
  guidanceCard: {
    backgroundColor: `${theme.colors.primary}08`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: theme.colors.primary,
    marginTop: theme.spacing.sm,
  },
  guidanceText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    lineHeight: 22,
    fontStyle: 'italic',
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
  // Step navigation styles
  nextButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.xl,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
    marginTop: theme.spacing.md,
  },
  nextButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  },
  stepActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.lg,
  },
  stepBackButton: {
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
  },
  backButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.primary,
  },
  // Warning and benefits cards
  warningCard: {
    backgroundColor: `${theme.colors.warning}10`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: theme.colors.warning,
    marginTop: theme.spacing.sm,
  },
  warningTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.warning,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  warningText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    lineHeight: 18,
  },
  benefitsCard: {
    backgroundColor: `${theme.colors.success}10`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: theme.colors.success,
    marginTop: theme.spacing.sm,
  },
  benefitsTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.success,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  benefitsText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    lineHeight: 18,
  },
  // Career card
  careerCard: {
    backgroundColor: `${theme.colors.info}10`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    borderLeftWidth: 4,
    borderLeftColor: theme.colors.info,
    marginTop: theme.spacing.sm,
  },
  careerTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.info,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  careerText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    lineHeight: 18,
  },
});

export default CitizenshipSetupScreen;
