import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { ReadingPlanPhase } from '@/constants/readingPlanModes';

export type PhaseProgress = {
  id: ReadingPlanPhase['id'];
  label: string;
  plannedSeconds: number;
  elapsedSeconds: number;
};

type ReadingTimerProps = {
  phases: ReadingPlanPhase[];
  onPhaseComplete?: (phase: ReadingPlanPhase, elapsedSeconds: number) => void;
  onAllPhasesComplete?: (totalElapsedSeconds: number, summaries: PhaseProgress[]) => void;
  autoStart?: boolean;
  onRemainingChange?: (totalRemainingSeconds: number) => void;
  passive?: boolean;
};

const ReadingTimer: React.FC<ReadingTimerProps> = ({ phases, onPhaseComplete, onAllPhasesComplete, autoStart = true, onRemainingChange, passive = false }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const [currentPhaseIndex, setCurrentPhaseIndex] = useState(0);
  const [secondsRemaining, setSecondsRemaining] = useState(() => (phases[0]?.minutes ?? 0) * 60);
  const [phaseSummaries, setPhaseSummaries] = useState<PhaseProgress[]>([]);
  const [isActive, setIsActive] = useState(autoStart);

  const currentPhase = phases[currentPhaseIndex];

  useEffect(() => {
    setCurrentPhaseIndex(0);
    setPhaseSummaries([]);
    setIsActive(autoStart);
    setSecondsRemaining((phases[0]?.minutes ?? 0) * 60);
  }, [phases, autoStart]);

  // Notify total remaining seconds (current remaining + full remaining of subsequent phases)
  useEffect(() => {
    if (!currentPhase) {
      onRemainingChange?.(0);
      return;
    }
    const subsequent = phases.slice(currentPhaseIndex + 1).reduce((sum, p) => sum + (p.minutes * 60), 0);
    const totalRemaining = Math.max(0, secondsRemaining) + subsequent;
    onRemainingChange?.(totalRemaining);
  }, [secondsRemaining, currentPhaseIndex, phases, currentPhase, onRemainingChange]);

  const formatTime = useCallback((seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.max(0, seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }, []);

  const totalMinutesPlanned = useMemo(() => phases.reduce((sum, phase) => sum + phase.minutes, 0), [phases]);

  const totalElapsedSeconds = useMemo(
    () => phaseSummaries.reduce((sum, item) => sum + item.elapsedSeconds, 0),
    [phaseSummaries]
  );

  const completePhase = useCallback(
    (remaining: number) => {
      if (!currentPhase) {
        return;
      }

      const plannedSeconds = Math.max(0, currentPhase.minutes * 60);
      const elapsedSeconds = plannedSeconds - Math.max(0, remaining);
      const summary: PhaseProgress = {
        id: currentPhase.id,
        label: currentPhase.label,
        plannedSeconds,
        elapsedSeconds,
      };

      const newSummaries = [...phaseSummaries, summary];
      setPhaseSummaries(newSummaries);
      setIsActive(false);

      onPhaseComplete?.(currentPhase, elapsedSeconds);

      const isLastPhase = currentPhaseIndex >= phases.length - 1;

      if (isLastPhase) {
        setSecondsRemaining(0);
        const finalTotal = newSummaries.reduce((sum, item) => sum + item.elapsedSeconds, 0);
        onAllPhasesComplete?.(finalTotal, newSummaries);
        onRemainingChange?.(0);
      } else {
        const nextIndex = currentPhaseIndex + 1;
        setCurrentPhaseIndex(nextIndex);
        setSecondsRemaining((phases[nextIndex]?.minutes ?? 0) * 60);
        setIsActive(autoStart);
      }
    },
    [currentPhase, currentPhaseIndex, autoStart, onPhaseComplete, onAllPhasesComplete, phaseSummaries, phases]
  );

  useEffect(() => {
    if (!currentPhase || !isActive) {
      return;
    }

    if (secondsRemaining <= 0) {
      completePhase(0);
      return;
    }

    const timerId = setTimeout(() => {
      setSecondsRemaining(prev => prev - 1);
    }, 1000);

    return () => clearTimeout(timerId);
  }, [currentPhase, isActive, secondsRemaining, completePhase]);

  if (!currentPhase) {
    return null;
  }

  const plannedSeconds = Math.max(0, currentPhase.minutes * 60);
  const elapsedSeconds = plannedSeconds - Math.max(0, secondsRemaining);
  const progressPercent = plannedSeconds === 0 ? 0 : (elapsedSeconds / plannedSeconds) * 100;

  const handleAdvancePhase = () => {
    completePhase(secondsRemaining);
  };

  if (passive) {
    return null;
  }

  return (
    <View style={styles.container}>
      <View style={styles.phaseInfo}>
        <View>
          <Text style={styles.phaseLabel}>{currentPhase.label}</Text>
          <Text style={styles.phaseStep}>
            Step {currentPhaseIndex + 1} of {phases.length}
          </Text>
        </View>
        <Text style={styles.totalTimeText}>{totalMinutesPlanned} min plan</Text>
      </View>

      <View style={styles.timerContainer}>
        <Text style={styles.timerText}>{formatTime(secondsRemaining)}</Text>
        <Text style={styles.elapsedText}>
          Spent: {formatTime(elapsedSeconds)}
          {plannedSeconds ? ` • Planned: ${formatTime(plannedSeconds)}` : ''}
        </Text>
      </View>

      <View style={styles.progressBarContainer}>
        <View style={[styles.progressBar, { width: `${progressPercent}%` }]} />
      </View>

      {currentPhase.hint ? <Text style={styles.hintText}>{currentPhase.hint}</Text> : null}

      <View style={styles.controlsRow}>
        <TouchableOpacity
          style={[styles.controlButton, !isActive && styles.controlButtonSecondary]}
          onPress={() => setIsActive(prev => !prev)}
        >
          <Text style={styles.controlButtonText}>{isActive ? 'Pause' : 'Resume'}</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.controlButtonPrimary} onPress={handleAdvancePhase}>
          <Text style={styles.primaryButtonText}>
            {currentPhaseIndex >= phases.length - 1 ? 'Finish Session' : 'Next Phase'}
          </Text>
        </TouchableOpacity>
      </View>

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

export const timerOverlayStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    container: {
      position: 'absolute',
      top: theme.spacing.md,
      right: theme.spacing.md,
      zIndex: 40,
      elevation: 6,
    },
  });

export default ReadingTimer;
