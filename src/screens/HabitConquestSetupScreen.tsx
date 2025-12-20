import React, { useMemo, useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { ChevronLeft, Check } from '@/components/Icons';
import { scheduleHabitConquestReminders, cancelHabitConquestReminders } from '@/tasks/habitConquestReminderScheduler';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { saveHabitConquestConfig } from '@/api/habitConquest';
import { Alert } from 'react-native';

const VICES = [
  'Laziness & neglect',
  'Recklessness & impulsiveness',
  'Ingratitude & entitlement',
  'Fear & cowardice',
  'Vanity & elitism',
  'Addiction to novelty',
  'Legalism & isolation',
  'Manipulation & ego-driven ambition',
];

const CADENCE_OPTIONS: Array<{ id: string; label: string; description: string; minutes: number; split: 'once' | 'twice' | 'thrice' }> = [
  {
    id: 'gentle',
    label: 'Gentle reset',
    description: '10 minutes • once per day',
    minutes: 10,
    split: 'once',
  },
  {
    id: 'steady',
    label: 'Steady practice',
    description: '20 minutes • twice per day',
    minutes: 20,
    split: 'twice',
  },
  {
    id: 'immersive',
    label: 'Immersive rebuild',
    description: '30 minutes • three touch points',
    minutes: 30,
    split: 'thrice',
  },
];

const STEP_ORDER = ['vice', 'cadence', 'reminders'] as const;
type StepKey = typeof STEP_ORDER[number];

const STEP_META: Record<StepKey, { title: string; subtitle: string }> = {
  vice: {
    title: 'Choose one focus to heal first',
    subtitle: 'You can always expand later—picking one keeps the journey doable.',
  },
  cadence: {
    title: 'Pick a cadence that fits your day',
    subtitle: 'We scale the guided phases automatically so you can stay present.',
  },
  reminders: {
    title: 'Do you want gentle reminders?',
    subtitle: 'We can nudge you each day or stay silent until you ask.',
  },
};

const REMINDER_CHOICES = [
  {
    id: 'enabled',
    title: 'Yes, keep me accountable',
    description: 'Receive friendly notifications aligned with your cadence.',
    enable: true,
  },
  {
    id: 'disabled',
    title: 'I’ll return on my own',
    description: 'You can enable reminders later from Daily Path settings.',
    enable: false,
  },
];

const DEFAULT_PHASES = [
  { id: 'affirmation', label: 'Affirmation', minutes: 2 },
  { id: 'meditation', label: 'Meditation', minutes: 3 },
  { id: 'mercy', label: 'Prayer for Mercy', minutes: 2 },
  { id: 'forgiveness', label: 'Prayer for Forgiveness', minutes: 2 },
  { id: 'thanksgiving', label: 'Prayer for Thanksgiving', minutes: 1 },
] as const;

const VICE_INTENTIONS: Record<string, string> = {
  'Laziness & neglect': 'Restore holy discipline and joyful energy.',
  'Recklessness & impulsiveness': 'Move from reaction to Spirit-led action.',
  'Ingratitude & entitlement': 'Rebuild daily gratitude and awe.',
  'Fear & cowardice': 'Choose bold trust over shrinking back.',
  'Vanity & elitism': 'Practice humility that centers Christ.',
  'Addiction to novelty': 'Stay rooted instead of chasing distraction.',
  'Legalism & isolation': 'Let love soften rigid edges.',
  'Manipulation & ego-driven ambition': 'Lead with service, not control.',
};

const getIntention = (vice: string) => VICE_INTENTIONS[vice] ?? `Invite grace to conquer ${vice.toLowerCase()}.`;

const HabitConquestSetupScreen: React.FC = () => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const dailyPathStore = useDailyPathStore();

  const initial = dailyPathStore.state.habitConquest;
  const initialCadence = useMemo(() => {
    const currentMinutes = initial?.dailyMinutes;
    const currentSplit = initial?.split;
    const matched = CADENCE_OPTIONS.find((option) => option.minutes === currentMinutes && option.split === currentSplit);
    return matched ?? CADENCE_OPTIONS[0];
  }, [initial?.dailyMinutes, initial?.split]);

  const [stepIndex, setStepIndex] = useState(0);
  const [vice, setVice] = useState<string>(initial?.vice ?? VICES[0]);
  const [minutes, setMinutes] = useState<number>(initialCadence.minutes);
  const [split, setSplit] = useState<'once' | 'twice' | 'thrice'>(initialCadence.split);
  const [selectedCadenceId, setSelectedCadenceId] = useState<string>(initialCadence.id);
  const [isSaving, setIsSaving] = useState(false);

  const basePhases = useMemo(() => initial?.phases ?? DEFAULT_PHASES, [initial?.phases]);

  const goBack = useCallback(() => {
    setStepIndex((prev) => Math.max(0, prev - 1));
  }, []);

  const goNext = useCallback(() => {
    setStepIndex((prev) => Math.min(prev + 1, STEP_ORDER.length - 1));
  }, []);

  const autoAdvance = useCallback(() => {
    setTimeout(() => goNext(), 160);
  }, [goNext]);

  const handleSelectVice = useCallback(
    (value: string) => {
      setVice(value);
      autoAdvance();
    },
    [autoAdvance],
  );

  const handleSelectCadence = useCallback(
    (option: typeof CADENCE_OPTIONS[number]) => {
      setSelectedCadenceId(option.id);
      setMinutes(option.minutes);
      setSplit(option.split);
      autoAdvance();
    },
    [autoAdvance],
  );

  const completeSetup = useCallback(
    async (enableReminders: boolean) => {
      if (isSaving) return;
      setIsSaving(true);
      try {
        dailyPathStore.setHabitConquestVice(vice);
        dailyPathStore.setHabitConquestMinutes(minutes);
        dailyPathStore.setHabitConquestSplit(split);
        const update: Record<string, number> = {};
        for (const phase of basePhases) {
          update[phase.id] = phase.minutes;
        }
        dailyPathStore.setHabitConquestPhaseMinutes(update);
        dailyPathStore.setHabitConquestDoor(initial?.doorOfSin ?? null);
        dailyPathStore.setHabitConquestPledge(initial?.pledgeGood ?? null);

        try {
          const today = new Date().toISOString().slice(0, 10);
          await AsyncStorage.removeItem(`hc_session_state_${today}`);
          await AsyncStorage.removeItem(`hc_sessions_${today}`);
        } catch (e) {
          console.warn('[HabitConquestSetup] Failed to reset session state:', e);
        }

        try {
          if (enableReminders) {
            await scheduleHabitConquestReminders(split, vice, minutes, 30);
          } else {
            await cancelHabitConquestReminders();
          }
        } catch (e) {
          console.warn('[HabitConquestSetup] reminder scheduling error', e);
        }

        try {
          await saveHabitConquestConfig({
            vice,
            doorOfSin: initial?.doorOfSin ?? null,
            pledgeGood: initial?.pledgeGood ?? null,
            dailyMinutes: minutes,
            split,
            phases: basePhases.map(p => ({ id: p.id, label: p.label, minutes: p.minutes })),
            reminders: enableReminders ? {
              enabled: true,
              times: [],
              timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            } : undefined,
          });
        } catch (error) {
          console.warn('[HabitConquestSetup] Failed to sync to backend:', error);
          Alert.alert(
            'Setup Saved Locally',
            'Your habit conquest setup was saved on this device, but we couldn\'t sync it to the cloud. Your progress will sync when connection is restored.',
            [{ text: 'OK' }]
          );
        }

        navigation.navigate('HabitConquestSessionScreen' as any);
      } finally {
        setIsSaving(false);
      }
    },
    [basePhases, dailyPathStore, vice, minutes, split, initial?.doorOfSin, initial?.pledgeGood, navigation, isSaving],
  );

  const activeStep = STEP_ORDER[stepIndex];
  const stepMeta = STEP_META[activeStep];

  const renderViceStep = () => (
    <View style={styles.cardStack}>
      {VICES.map((item) => {
        const active = vice === item;
        return (
          <TouchableOpacity
            key={item}
            style={[styles.choiceCard, active && styles.choiceCardActive]}
            onPress={() => handleSelectVice(item)}
            activeOpacity={0.85}
          >
            <Text style={[styles.choiceLabel, active && styles.choiceLabelActive]}>{item}</Text>
            <Text style={[styles.choiceDescription, active && styles.choiceDescriptionActive]}>{getIntention(item)}</Text>
            {active ? (
              <View style={styles.checkBadge}>
                <Check size={14} color={theme.colors.text.inverse} />
              </View>
            ) : null}
          </TouchableOpacity>
        );
      })}
    </View>
  );

  const renderCadenceStep = () => (
    <View style={styles.cardStack}>
      {CADENCE_OPTIONS.map((option) => {
        const active = selectedCadenceId === option.id;
        return (
          <TouchableOpacity
            key={option.id}
            style={[styles.choiceCard, active && styles.choiceCardActive]}
            onPress={() => handleSelectCadence(option)}
            activeOpacity={0.85}
          >
            <Text style={[styles.choiceLabel, active && styles.choiceLabelActive]}>{option.label}</Text>
            <Text style={[styles.choiceDescription, active && styles.choiceDescriptionActive]}>{option.description}</Text>
            <Text style={styles.choiceHelper}>
              {option.split === 'once'
                ? 'One immersive session'
                : option.split === 'twice'
                  ? 'Morning & evening grounding'
                  : 'Three brief resets spread across your day'}
            </Text>
            {active ? (
              <View style={styles.checkBadge}>
                <Check size={14} color={theme.colors.text.inverse} />
              </View>
            ) : null}
          </TouchableOpacity>
        );
      })}
    </View>
  );

  const renderReminderStep = () => (
    <View style={styles.cardStack}>
      {REMINDER_CHOICES.map((choice) => (
        <TouchableOpacity
          key={choice.id}
          style={[styles.choiceCard, styles.reminderCard]}
          onPress={() => completeSetup(choice.enable)}
          activeOpacity={0.85}
          disabled={isSaving}
        >
          <Text style={styles.choiceLabel}>{choice.title}</Text>
          <Text style={styles.choiceDescription}>{choice.description}</Text>
          {isSaving ? <Text style={styles.savingText}>Saving...</Text> : null}
        </TouchableOpacity>
      ))}
    </View>
  );

  const renderActiveStep = () => {
    switch (activeStep) {
      case 'vice':
        return renderViceStep();
      case 'cadence':
        return renderCadenceStep();
      case 'reminders':
      default:
        return renderReminderStep();
    }
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top, paddingBottom: insets.bottom }]}>
      <View style={styles.navRow}>
        {stepIndex > 0 ? (
          <TouchableOpacity style={styles.backBtn} onPress={goBack} accessibilityRole="button">
            <ChevronLeft size={18} color={theme.colors.text.primary} />
            <Text style={styles.backText}>Back</Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.backPlaceholder} />
        )}
        <Text style={styles.stepIndicator}>
          Step {stepIndex + 1} of {STEP_ORDER.length}
        </Text>
        <View style={styles.backPlaceholder} />
      </View>

      <View style={styles.header}>
        <Text style={styles.title}>Conquer Harmful Habits</Text>
        <Text style={styles.subtitle}>{stepMeta.subtitle}</Text>
      </View>

      <View style={styles.stageLabel}>
        <Text style={styles.stageTitle}>{stepMeta.title}</Text>
      </View>

      <ScrollView
        contentContainerStyle={styles.stepContent}
        bounces={false}
        showsVerticalScrollIndicator={false}
      >
        {renderActiveStep()}
      </ScrollView>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background, paddingHorizontal: 20 },
  navRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 },
  backBtn: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingVertical: 6, paddingHorizontal: 10, borderRadius: 999, backgroundColor: theme.colors.surface },
  backText: { color: theme.colors.text.primary, fontWeight: '600', fontSize: 13 },
  backPlaceholder: { width: 64 },
  stepIndicator: { color: theme.colors.text.secondary, fontWeight: '600', fontSize: 13 },
  header: { marginBottom: 12 },
  title: { fontSize: 22, fontWeight: '700', color: theme.colors.text.primary },
  subtitle: { fontSize: 14, color: theme.colors.text.secondary, marginTop: 4 },
  stageLabel: { marginBottom: 8 },
  stageTitle: { fontSize: 16, fontWeight: '700', color: theme.colors.text.primary },
  stepContent: { paddingBottom: 32, gap: 12 },
  cardStack: { gap: 12 },
  choiceCard: {
    borderRadius: 20,
    padding: 16,
    backgroundColor: theme.colors.surface,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: `${theme.colors.border}55`,
  },
  choiceCardActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}12`,
  },
  reminderCard: {
    minHeight: 110,
  },
  choiceLabel: { fontSize: 16, fontWeight: '700', color: theme.colors.text.primary },
  choiceLabelActive: { color: theme.colors.primary },
  choiceDescription: { marginTop: 6, color: theme.colors.text.secondary, fontSize: 13, lineHeight: 18 },
  choiceDescriptionActive: { color: theme.colors.text.primary },
  choiceHelper: { marginTop: 6, fontSize: 12, color: theme.colors.text.tertiary },
  checkBadge: {
    position: 'absolute',
    top: 16,
    right: 16,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepContentWrapper: { flex: 1 },
  savingText: { marginTop: 12, color: theme.colors.text.secondary, fontSize: 12 },
});

export default HabitConquestSetupScreen;
