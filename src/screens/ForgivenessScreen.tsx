import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft } from '@/components/Icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getGuideById, MeditationGuideConfig } from '@/services/GuideService';
import Animated, { FadeInDown } from 'react-native-reanimated';

export type ForgivenessScreenProps = NativeStackScreenProps<RootStackParamList, 'ForgivenessScreen'>;

type ForgivenessMode = 'short' | 'long';
type ForgivenessStepId = 'reflection' | 'prayer' | 'penitence';

type BiblePassageConfig = {
  id: string;
  label: string;
  book: string;
  chapter: number;
  verse?: number;
};

const FORGIVENESS_STEPS: { id: ForgivenessStepId; title: string }[] = [
  {
    id: 'reflection',
    title: 'Reflection',
  },
  {
    id: 'prayer',
    title: 'Prayer for forgiveness',
  },
  {
    id: 'penitence',
    title: 'Penitence & thanksgiving',
  },
];

const FORGIVENESS_STEP_ORDER: ForgivenessStepId[] = ['reflection', 'prayer', 'penitence'];

const FORGIVENESS_MINUTES: Record<ForgivenessMode, Record<ForgivenessStepId, string>> = {
  short: {
    reflection: '3–4 min',
    prayer: '3–4 min',
    penitence: '2–3 min',
  },
  long: {
    reflection: '7–10 min',
    prayer: '4–5 min',
    penitence: '3–5 min',
  },
};

const FORGIVENESS_PASSAGES: BiblePassageConfig[] = [
  {
    id: 'ps51',
    label: 'Psalm 51 – A prayer of repentance',
    book: 'Psalms',
    chapter: 51,
  },
  {
    id: 'ps32',
    label: 'Psalm 32 – Joy of forgiveness',
    book: 'Psalms',
    chapter: 32,
  },
  {
    id: 'eph4',
    label: 'Ephesians 4:31–32 – Forgive as Christ forgave you',
    book: 'Ephesians',
    chapter: 4,
    verse: 31,
  },
];

const FORGIVENESS_SESSION_COUNT_KEY = 'FORGIVENESS_SESSION_COUNT';

const ForgivenessScreen = ({ navigation }: ForgivenessScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  const [mode, setMode] = React.useState<ForgivenessMode>('short');
  const [activeStep, setActiveStep] = React.useState<ForgivenessStepId>('reflection');
  const [elapsed, setElapsed] = React.useState<Record<ForgivenessStepId, number>>({
    reflection: 0,
    prayer: 0,
    penitence: 0,
  });
  const [isTimerRunning, setIsTimerRunning] = React.useState(false);
  const timerRef = React.useRef<ReturnType<typeof setInterval> | null>(null);
  const [selectedPassageId, setSelectedPassageId] = React.useState<string>(FORGIVENESS_PASSAGES[0].id);
  const [sessionCount, setSessionCount] = React.useState<number>(0);
  const [shortMinutes, setShortMinutes] = React.useState<number | null>(null);
  const [longMinutes, setLongMinutes] = React.useState<number | null>(null);
  const [hasStarted, setHasStarted] = React.useState(false);

  React.useEffect(() => {
    AsyncStorage.getItem(FORGIVENESS_SESSION_COUNT_KEY)
      .then(value => {
        const parsed = value ? Number(value) : 0;
        setSessionCount(Number.isNaN(parsed) ? 0 : parsed);
      })
      .catch(() => {
        setSessionCount(0);
      });
  }, []);

  React.useEffect(() => {
    let isActive = true;

    const loadGuide = async () => {
      try {
        const guide = await getGuideById('forgiveness');
        if (!guide) return;
        if (guide.content.mode !== 'meditation') return;
        const cfg = guide.content as MeditationGuideConfig;
        if (isActive) {
          setShortMinutes(cfg.minutesShort);
          setLongMinutes(cfg.minutesLong);
        }
      } catch {
        // ignore
      }
    };

    void loadGuide();

    return () => {
      isActive = false;
    };
  }, []);

  React.useEffect(() => {
    if (!isTimerRunning) {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
      return;
    }

    timerRef.current = setInterval(() => {
      setElapsed(prev => ({
        ...prev,
        [activeStep]: (prev[activeStep] ?? 0) + 1,
      }));
    }, 1000);

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [isTimerRunning, activeStep]);

  const current = FORGIVENESS_STEPS.find(step => step.id === activeStep) || FORGIVENESS_STEPS[0];
  const currentSeconds = elapsed[activeStep] ?? 0;
  const timerMinutes = Math.floor(currentSeconds / 60)
    .toString()
    .padStart(2, '0');
  const timerSeconds = (currentSeconds % 60).toString().padStart(2, '0');

  const totalSteps = FORGIVENESS_STEP_ORDER.length;
  const currentStepIndex = FORGIVENESS_STEP_ORDER.indexOf(activeStep);
  const safeStepIndex = currentStepIndex === -1 ? 0 : currentStepIndex;
  const isFirstStep = safeStepIndex === 0;
  const isLastStep = safeStepIndex === totalSteps - 1;

  const handleToggleTimer = () => {
    setIsTimerRunning(prev => !prev);
  };

  const handleResetTimer = () => {
    setElapsed(prev => ({
      ...prev,
      [activeStep]: 0,
    }));
    setIsTimerRunning(false);
  };

  const handleBeginSession = () => {
    setHasStarted(true);
    setActiveStep('reflection');
    setElapsed({
      reflection: 0,
      prayer: 0,
      penitence: 0,
    });
    setIsTimerRunning(true);
  };

  const handleGoToStep = (stepId: ForgivenessStepId) => {
    setActiveStep(stepId);
    setIsTimerRunning(false);
  };

  const handleNextStep = () => {
    const idx = FORGIVENESS_STEP_ORDER.indexOf(activeStep);
    if (idx === -1) return;
    const nextIndex = idx + 1;
    if (nextIndex >= FORGIVENESS_STEP_ORDER.length) return;
    setActiveStep(FORGIVENESS_STEP_ORDER[nextIndex]);
    setIsTimerRunning(false);
  };

  const handlePreviousStep = () => {
    const idx = FORGIVENESS_STEP_ORDER.indexOf(activeStep);
    if (idx <= 0) return;
    const prevIndex = idx - 1;
    setActiveStep(FORGIVENESS_STEP_ORDER[prevIndex]);
    setIsTimerRunning(false);
  };

  const handleOpenSelectedPassage = () => {
    const passage =
      FORGIVENESS_PASSAGES.find(p => p.id === selectedPassageId) ?? FORGIVENESS_PASSAGES[0];

    navigation.navigate('BibleScreen', {
      book: passage.book,
      chapter: passage.chapter,
      verse: passage.verse,
    });
  };

  const shortLabel = shortMinutes ? `About ${shortMinutes} min` : 'About 8–10 min';
  const longLabel = longMinutes ? `About ${longMinutes} min` : 'About 15–20 min';

  const handleCompleteSession = async () => {
    try {
      const next = sessionCount + 1;
      setSessionCount(next);
      await AsyncStorage.setItem(FORGIVENESS_SESSION_COUNT_KEY, String(next));

      if (next === 10) {
        navigation.navigate('JourneyQuizScreen', { phaseId: 'repentance' });
        return;
      }

      navigation.goBack();
    } catch {
      navigation.goBack();
    }
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Forgiveness</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <Text style={styles.introTitle}>Walk through forgiveness with God</Text>
        <Text style={styles.introBody}>
          Choose a short or longer path, then move gently through reflection, prayer for
          forgiveness, and penitence. Let the Spirit set the real pace.
        </Text>

        <Animated.View entering={FadeInDown.duration(350)} style={styles.card}>
          <View style={styles.modeChipsContainer}>
            <TouchableOpacity
              style={[
                styles.modeChip,
                mode === 'short' && styles.modeChipActive,
              ]}
              activeOpacity={0.9}
              onPress={() => setMode('short')}
            >
              <Text style={mode === 'short' ? styles.modeChipLabelActive : styles.modeChipLabel}>
                Short form
              </Text>
              <Text style={styles.modeDurationText}>{shortLabel}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.modeChip,
                mode === 'long' && styles.modeChipActive,
              ]}
              activeOpacity={0.9}
              onPress={() => setMode('long')}
            >
              <Text style={mode === 'long' ? styles.modeChipLabelActive : styles.modeChipLabel}>
                Long form
              </Text>
              <Text style={styles.modeDurationText}>{longLabel}</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.stepChipsContainer}>
            {FORGIVENESS_STEPS.map(step => {
              const isActive = step.id === activeStep;
              return (
                <TouchableOpacity
                  key={step.id}
                  style={[
                    styles.stepChip,
                    isActive && styles.stepChipActive,
                  ]}
                  activeOpacity={0.9}
                  onPress={() => handleGoToStep(step.id)}
                  disabled={!hasStarted}
                >
                  <Text
                    style={
                      isActive ? styles.stepChipLabelActive : styles.stepChipLabel
                    }
                  >
                    {step.title}
                  </Text>
                  <Text style={styles.stepDurationText}>
                    {FORGIVENESS_MINUTES[mode][step.id]}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {!hasStarted && (
            <Animated.View entering={FadeInDown.delay(120).duration(300)} style={styles.sessionIntroBlock}>
              <Text style={styles.cardBody}>
                When you begin, you will move step by step through reflection, prayer, and
                penitence with a simple timer to help you linger without rushing.
              </Text>
              <TouchableOpacity
                style={styles.primaryButton}
                activeOpacity={0.9}
                onPress={handleBeginSession}
              >
                <Text style={styles.primaryButtonText}>Begin forgiveness session</Text>
              </TouchableOpacity>
            </Animated.View>
          )}

          {hasStarted && (
            <>
              <Animated.View entering={FadeInDown.delay(80).duration(260)} style={styles.sessionHeaderRow}>
                <Text style={styles.sessionStepLabel}>
                  Step {safeStepIndex + 1} of {totalSteps}
                </Text>
                <Text style={styles.sessionModePill}>
                  {mode === 'short' ? 'Short form' : 'Long form'} •{' '}
                  {FORGIVENESS_MINUTES[mode][current.id]}
                </Text>
              </Animated.View>

              {current.id === 'reflection' && (
                <Animated.View entering={FadeInDown.delay(140).duration(260)}>
                  <Text style={styles.cardBody}>
                    Spend a few quiet minutes reviewing your day. Where did you love well?
                    Where did you choose yourself over God or neighbour? Let the Spirit show you
                    specific moments without shame.
                  </Text>
                  <View style={styles.bulletList}>
                    <Text style={styles.bulletItem}>• What did I do today that reflected the Kingdom?</Text>
                    <Text style={styles.bulletItem}>• Where did I dishonor or wound others or myself?</Text>
                    <Text style={styles.bulletItem}>• Where did I fail to love enough or ignore God’s nudge or gentle voice?</Text>
                  </View>
                </Animated.View>
              )}

              {current.id === 'prayer' && (
                <Animated.View entering={FadeInDown.delay(140).duration(260)}>
                  <Text style={styles.cardBody}>
                    Bring what the Spirit has revealed into the light. Name specific sins and
                    trust that Jesus is the healer of your spiritual wounds.
                  </Text>
                  <View style={styles.bulletList}>
                    <Text style={styles.bulletItem}>• Ask the Spirit to reveal what needs healing.</Text>
                    <Text style={styles.bulletItem}>• Confess clearly, without excuses.</Text>
                    <Text style={styles.bulletItem}>• Receive mercy as a gift, like a child who reports themselves to a loving guardian.</Text>
                  </View>
                  <Text style={styles.cardBody}>
                    If it helps, quietly name one area or vice you are bringing before God
                    (for example: anger, lust, envy, impatience).
                  </Text>
                  <TextInput
                    style={styles.viceInput}
                    placeholder="Type something you want to surrender"
                    placeholderTextColor={theme.colors.text.secondary}
                  />
                  <View style={styles.passageList}>
                    {FORGIVENESS_PASSAGES.map(passage => {
                      const isSelected = passage.id === selectedPassageId;
                      return (
                        <TouchableOpacity
                          key={passage.id}
                          style={[
                            styles.passageChip,
                            isSelected && styles.passageChipSelected,
                          ]}
                          activeOpacity={0.85}
                          onPress={() => setSelectedPassageId(passage.id)}
                        >
                          <Text
                            style={
                              isSelected
                                ? styles.passageChipLabelSelected
                                : styles.passageChipLabel
                            }
                          >
                            {passage.label}
                          </Text>
                        </TouchableOpacity>
                      );
                    })}
                  </View>
                  <TouchableOpacity
                    style={styles.secondaryButton}
                    activeOpacity={0.9}
                    onPress={handleOpenSelectedPassage}
                  >
                    <Text style={styles.secondaryButtonText}>
                      Open selected passage in Bible
                    </Text>
                  </TouchableOpacity>
                  <Text style={styles.cardPrayerHeading}>Suggested prayer</Text>
                  <Text style={styles.cardPrayer}>
                    Lord Jesus, I am sorry for my sins. I bring them into Your light and ask You
                    to wash me clean. Heal every wound my choices have opened, and give me a
                    new heart that loves what You love.
                  </Text>
                </Animated.View>
              )}

              {current.id === 'penitence' && (
                <Animated.View entering={FadeInDown.delay(140).duration(260)}>
                  <Text style={styles.cardBody}>
                    Penitence is thanksgiving and a concrete decision to walk differently with
                    grace. You do not pay God back; you simply respond to mercy with love.
                  </Text>
                  <View style={styles.bulletList}>
                    <Text style={styles.bulletItem}>• Thank God for forgiving and healing you.</Text>
                    <Text style={styles.bulletItem}>• Ask for strength to choose differently next time.</Text>
                    <Text style={styles.bulletItem}>• Name one small, concrete step you will take today.</Text>
                  </View>
                  <Text style={styles.cardPrayerHeading}>Suggested prayer</Text>
                  <Text style={styles.cardPrayer}>
                    Father, thank You for forgiving me and drawing close to my wounds. By Your
                    grace, help me to walk in a new way, to repair what I can, and to grow as a
                    true citizen of Your Kingdom.
                  </Text>
                </Animated.View>
              )}

              <View style={styles.timerRow}>
                <Text style={styles.timerLabel}>Time in this step</Text>
                <Text style={styles.timerValue}>
                  {timerMinutes}:{timerSeconds}
                </Text>
              </View>
              <View style={styles.timerButtonsRow}>
                <TouchableOpacity
                  style={styles.secondaryButton}
                  activeOpacity={0.9}
                  onPress={handleToggleTimer}
                >
                  <Text style={styles.secondaryButtonText}>
                    {isTimerRunning ? 'Pause' : 'Start'}
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.timerResetButton}
                  activeOpacity={0.85}
                  onPress={handleResetTimer}
                >
                  <Text style={styles.timerResetButtonText}>Reset</Text>
                </TouchableOpacity>
              </View>

              <View style={styles.stepNavRow}>
                <TouchableOpacity
                  style={[
                    styles.stepNavButton,
                    isFirstStep && styles.stepNavButtonDisabled,
                  ]}
                  activeOpacity={0.9}
                  onPress={handlePreviousStep}
                  disabled={isFirstStep}
                >
                  <Text style={styles.stepNavButtonText}>Previous step</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[
                    styles.stepNavButton,
                    isLastStep && styles.stepNavButtonDisabled,
                  ]}
                  activeOpacity={0.9}
                  onPress={handleNextStep}
                  disabled={isLastStep}
                >
                  <Text style={styles.stepNavButtonText}>
                    {isLastStep ? 'Stay here with God' : 'Next step'}
                  </Text>
                </TouchableOpacity>
              </View>
            </>
          )}
        </Animated.View>
        {hasStarted && (
          <Animated.View entering={FadeInDown.delay(220).duration(280)} style={styles.completionCard}>
            <Text style={styles.completionText}>
              When you have moved through the steps for today, you can gently mark this
              forgiveness time as complete.
            </Text>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={handleCompleteSession}
            >
              <Text style={styles.primaryButtonText}>Finish this forgiveness time</Text>
            </TouchableOpacity>
          </Animated.View>
        )}
      </ScrollView>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  content: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  introTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  introBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  modeChipsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  modeChip: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.background,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  modeChipActive: {
    backgroundColor: `${theme.colors.primary}10`,
    borderColor: theme.colors.primary,
  },
  modeChipLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  modeChipLabelActive: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  modeDurationText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  card: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  cardBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  cardPrayerHeading: {
    marginTop: theme.spacing.sm,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  cardPrayer: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  bulletList: {
    marginTop: theme.spacing.xs,
    gap: 2,
  },
  bulletItem: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  stepChipsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  stepChip: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.background,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  stepChipActive: {
    backgroundColor: `${theme.colors.primary}10`,
    borderColor: theme.colors.primary,
  },
  stepChipLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  stepChipLabelActive: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  stepDurationText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  viceInput: {
    marginTop: theme.spacing.sm,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: theme.borderRadius.md,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  passageList: {
    marginTop: theme.spacing.sm,
    gap: theme.spacing.xs,
  },
  passageChip: {
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    backgroundColor: theme.colors.background,
  },
  passageChipSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  passageChipLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  passageChipLabelSelected: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  timerRow: {
    marginTop: theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  timerLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  timerValue: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  timerButtonsRow: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  timerResetButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  timerResetButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  secondaryButton: {
    marginTop: theme.spacing.sm,
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}08`,
  },
  secondaryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  completionCard: {
    marginTop: theme.spacing.md,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  completionText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  sessionIntroBlock: {
    marginTop: theme.spacing.sm,
    paddingTop: theme.spacing.sm,
    borderTopWidth: 1,
    borderTopColor: `${theme.colors.border}80`,
    gap: theme.spacing.sm,
  },
  sessionHeaderRow: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sessionStepLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '500',
  },
  sessionModePill: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  stepNavRow: {
    marginTop: theme.spacing.md,
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  stepNavButton: {
    flex: 1,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
    alignItems: 'center',
  },
  stepNavButtonDisabled: {
    opacity: 0.5,
  },
  stepNavButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  primaryButton: {
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  primaryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
});

export default observer(ForgivenessScreen);
