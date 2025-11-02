import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { ReadingPlanPhase } from '@/constants/readingPlanModes';
import * as Haptics from 'expo-haptics';
import { observer } from 'mobx-react-lite';
import { appTimerStore } from '@/stores/AppTimerStore';

export type PhaseProgress = {
  id: ReadingPlanPhase['id'];
  label: string;
  plannedSeconds: number;
  elapsedSeconds: number;
};

type ReadingTimerProps = {
  timerId?: string; // When provided, component becomes controlled via AppTimerStore
  phases: ReadingPlanPhase[];
  onPhaseComplete?: (phase: ReadingPlanPhase, elapsedSeconds: number) => void;
  onAllPhasesComplete?: (totalElapsedSeconds: number, summaries: PhaseProgress[]) => void;
  autoStart?: boolean;
  passive?: boolean;
  initialPhaseIndex?: number;
  initialSecondsRemaining?: number;
  initialSummaries?: PhaseProgress[];
  onStateSnapshot?: (state: {
    currentPhaseIndex: number;
    secondsRemainingInPhase: number;
    phaseSummaries: PhaseProgress[];
    completed: boolean;
  }) => void;
  controlledState?: {
    currentPhaseIndex: number;
    secondsRemainingInPhase: number;
    phaseSummaries: PhaseProgress[];
    isActive: boolean;
    completed?: boolean;
  };
  onToggleActive?: (nextActive: boolean) => void;
  onAdvancePhase?: () => void;
  passages?: string[];
};

const ReadingTimer: React.FC<ReadingTimerProps> = ({
  timerId,
  phases,
  onPhaseComplete,
  onAllPhasesComplete,
  autoStart,
  passive,
  initialPhaseIndex,
  initialSecondsRemaining,
  initialSummaries,
  onStateSnapshot,
  controlledState,
  onToggleActive,
  onAdvancePhase,
  passages,
}) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const [isActive, setIsActive] = useState(false);
  const [currentPhaseIndex, setCurrentPhaseIndex] = useState(initialPhaseIndex ?? 0);
  const [secondsRemaining, setSecondsRemaining] = useState(initialSecondsRemaining ?? phases[0].minutes * 60);
  const [phaseSummaries, setPhaseSummaries] = useState(initialSummaries ?? []);

  // Ensure timer exists and phases are synced
  useEffect(() => {
    if (timerId) {
      const phaseDefs = phases.map(p => ({
        id: p.id,
        label: p.label,
        plannedSeconds: Math.max(0, p.minutes * 60),
      }));
      appTimerStore.ensure(timerId, phaseDefs);
    }
  }, [timerId, phases]);

  // Watch for phase/completion changes
  const prevPhaseIndexRef = React.useRef<number | null>(null);
  const prevCompletedRef = React.useRef<boolean>(false);

  // Derive controlled view from AppTimerStore when timerId is provided
  const timer = timerId ? appTimerStore.get(timerId) : null;
  const derivedControlledState = useMemo(() => {
    if (!timerId || !timer) return undefined;
    const remaining = appTimerStore.remainingInPhase(timerId);
    return {
      currentPhaseIndex: timer.currentPhaseIndex,
      secondsRemainingInPhase: Math.max(0, remaining),
      phaseSummaries: timer.summaries.map(s => ({
        id: s.id as PhaseProgress['id'],
        label: s.label,
        plannedSeconds: Math.max(0, s.plannedSeconds),
        elapsedSeconds: Math.max(0, s.elapsedSeconds),
      })),
      isActive: timer.isActive,
      completed: timer.completed,
    } as const;
  }, [timerId, timer, appTimerStore.now]);

  const effectiveControlled = controlledState ?? derivedControlledState;
  const isControlled = Boolean(effectiveControlled);

  useEffect(() => {
    if (!isControlled) return;
    if (!effectiveControlled) return;
    setCurrentPhaseIndex(effectiveControlled.currentPhaseIndex);
    setSecondsRemaining(effectiveControlled.secondsRemainingInPhase);
    setPhaseSummaries(effectiveControlled.phaseSummaries);
    setIsActive(effectiveControlled.isActive);
  }, [isControlled, effectiveControlled?.currentPhaseIndex, effectiveControlled?.secondsRemainingInPhase, effectiveControlled?.phaseSummaries, effectiveControlled?.isActive]);

  useEffect(() => {
    if (!timerId) return;

    if (prevPhaseIndexRef.current !== null && currentPhaseIndex > prevPhaseIndexRef.current) {
      const prevIndex = prevPhaseIndexRef.current;
      const phase = phases[prevIndex];
      const summary = phaseSummaries[prevIndex];
      if (phase && summary) {
        onPhaseComplete?.(phase, summary.elapsedSeconds);
      }
    }

    const justCompleted = Boolean(effectiveControlled?.completed);
    if (!prevCompletedRef.current && justCompleted) {
      const totalElapsed = phaseSummaries.reduce((sum, s) => sum + s.elapsedSeconds, 0);
      const phaseSummariesCopy = phaseSummaries.map(s => ({
        id: s.id as PhaseProgress['id'],
        label: s.label,
        plannedSeconds: Math.max(0, s.plannedSeconds),
        elapsedSeconds: Math.max(0, s.elapsedSeconds),
      }));
      onAllPhasesComplete?.(totalElapsed, phaseSummariesCopy);
    }

    prevPhaseIndexRef.current = currentPhaseIndex;
    prevCompletedRef.current = justCompleted;
  }, [timerId, currentPhaseIndex, phaseSummaries, phases, onPhaseComplete, onAllPhasesComplete, effectiveControlled?.completed]);

  const formatTime = useCallback((seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.max(0, seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }, []);

  const handleToggle = useCallback(async () => {
    try {
      await Haptics.selectionAsync();
    } catch {}

    if (timerId) {
      if (isActive) {
        appTimerStore.pause(timerId);
      } else {
        appTimerStore.resume(timerId);
      }
    } else {
      setIsActive(prev => !prev);
    }
  }, [timerId, isActive]);

  const handleAdvancePhase = useCallback(async () => {
    try {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch {}

    if (timerId) {
      appTimerStore.advancePhase(timerId);
    } else {
      setCurrentPhaseIndex(prev => prev + 1);
    }
  }, [timerId]);

  const handleStart = useCallback(async () => {
    try {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch {}

    if (timerId) {
      appTimerStore.start(timerId, phases.map(p => ({
        id: p.id,
        label: p.label,
        plannedSeconds: Math.max(0, p.minutes * 60),
      })));
    } else {
      setIsActive(true);
    }
  }, [timerId, phases]);

  const totalMinutesPlanned = phases.reduce((sum, phase) => sum + phase.minutes, 0);
  const remainingSeconds = timerId ? appTimerStore.remainingInPhase(timerId) : secondsRemaining;
  const plannedSeconds = Math.max(0, phases[currentPhaseIndex].minutes * 60);
  const elapsedSeconds = plannedSeconds - Math.max(0, remainingSeconds);
  const progressPercent = plannedSeconds === 0 ? 0 : (elapsedSeconds / plannedSeconds) * 100;

  const totalElapsedSeconds = phaseSummaries.reduce((sum, s) => sum + s.elapsedSeconds, 0) + elapsedSeconds;

  const isMultiPhase = phases.length > 1;
  const hasAnyProgress = useMemo(() => {
    if (phaseSummaries.some(p => p.elapsedSeconds > 0)) return true;
    if (currentPhaseIndex > 0) return true;
    const firstPlanned = (phases[0]?.minutes ?? 0) * 60;
    return firstPlanned > 0 && remainingSeconds < firstPlanned;
  }, [phaseSummaries, currentPhaseIndex, phases, remainingSeconds]);

  const showSingleStart = !hasAnyProgress;

  if (passive) return null;

  return (
    <View style={styles.container}>
      <View style={styles.phaseInfo}>
        <View>
          <Text style={styles.phaseLabel}>{phases[currentPhaseIndex].label}</Text>
          <Text style={styles.phaseStep}>
            Step {currentPhaseIndex + 1} of {phases.length}
          </Text>
        </View>
        <Text style={styles.totalTimeText}>{totalMinutesPlanned} min plan</Text>
      </View>

      <View style={styles.timerContainer}>
        <Text style={styles.timerText}>{formatTime(Math.max(0, remainingSeconds))}</Text>
        <Text style={styles.elapsedText}>
          Spent: {formatTime(elapsedSeconds)}
          {plannedSeconds ? ` • Planned: ${formatTime(plannedSeconds)}` : ''}
        </Text>
      </View>

      <View style={styles.progressBarContainer}>
        <View style={[styles.progressBar, { width: `${progressPercent}%` }]} />
      </View>

      {phases[currentPhaseIndex].hint ? <Text style={styles.hintText}>{phases[currentPhaseIndex].hint}</Text> : null}

      {!!passages?.length && (
        <View style={styles.passagesContainer}>
          {passages.map((p, i) => (
            <Text key={`${p}-${i}`} style={styles.passageItem} numberOfLines={1}>
              {p}
            </Text>
          ))}
        </View>
      )}

      {showSingleStart ? (
        <View style={styles.controlsRow}>
          <TouchableOpacity style={styles.controlButtonPrimary} onPress={handleStart}>
            <Text style={styles.primaryButtonText}>Start</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <View style={styles.controlsRow}>
          <TouchableOpacity
            style={[styles.controlButton, !isActive && styles.controlButtonSecondary]}
            onPress={handleToggle}
          >
            <Text style={styles.controlButtonText}>{isActive ? 'Pause' : 'Resume'}</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.controlButtonPrimary} onPress={handleAdvancePhase}>
            <Text style={styles.primaryButtonText}>
              {currentPhaseIndex >= phases.length - 1 ? 'Complete' : (isMultiPhase ? 'Next Phase' : 'Complete')}
            </Text>
          </TouchableOpacity>
        </View>
      )}

      {phaseSummaries.length > 0 && (
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total focus time:</Text>
          <Text style={styles.summaryValue}>{formatTime(totalElapsedSeconds)}</Text>
        </View>
      )}
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    container: {
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.lg,
      padding: theme.spacing.lg,
      borderWidth: 2,
      borderColor: theme.colors.primary,
      gap: theme.spacing.md,
    },
    phaseInfo: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
    },
    phaseLabel: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
      fontWeight: '600',
      fontSize: 18,
    },
    phaseStep: {
      ...theme.typography.caption,
      color: theme.colors.text.secondary,
      marginTop: 4,
    },
    totalTimeText: {
      ...theme.typography.caption,
      color: theme.colors.text.secondary,
    },
    timerContainer: {
      alignItems: 'center',
      gap: theme.spacing.xs,
    },
    timerText: {
      fontSize: 48,
      fontWeight: '700',
      color: theme.colors.primary,
      fontVariant: ['tabular-nums'],
    },
    elapsedText: {
      ...theme.typography.caption,
      color: theme.colors.text.secondary,
    },
    progressBarContainer: {
      height: 8,
      backgroundColor: theme.colors.surfaceVariant,
      borderRadius: theme.borderRadius.full,
      overflow: 'hidden',
    },
    progressBar: {
      height: '100%',
      backgroundColor: theme.colors.primary,
    },
    hintText: {
      ...theme.typography.caption,
      color: theme.colors.text.secondary,
      fontStyle: 'italic',
      textAlign: 'center',
    },
    passagesContainer: {
      marginTop: theme.spacing.xs,
      gap: 4,
      alignItems: 'center',
    },
    passageItem: {
      ...theme.typography.caption,
      color: theme.colors.text.primary,
    },
    controlsRow: {
      flexDirection: 'row',
      gap: theme.spacing.sm,
    },
    controlButton: {
      flex: 1,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
      justifyContent: 'center',
      borderWidth: 1,
      borderColor: theme.colors.primary,
      backgroundColor: `${theme.colors.primary}10`,
    },
    controlButtonSecondary: {
      backgroundColor: theme.colors.surfaceVariant,
      borderColor: theme.colors.border,
    },
    controlButtonText: {
      ...theme.typography.body.sans,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    controlButtonPrimary: {
      flex: 1,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.primary,
    },
    primaryButtonText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
    summaryRow: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    summaryLabel: {
      ...theme.typography.caption,
      color: theme.colors.text.secondary,
    },
    summaryValue: {
      ...theme.typography.caption,
      color: theme.colors.text.primary,
      fontWeight: '600',
    },
  });

export default observer(ReadingTimer);
