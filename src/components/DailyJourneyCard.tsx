import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { DailyStep, DailyFocusIconKey } from '@/stores/DailyPathStore';
import { BookOpen, NotePencil, Users, Flame, Heart, Trophy, Check, ChevronRight } from '@/components/Icons';

const ICON_MAP: Record<DailyFocusIconKey, React.ComponentType<{ size?: number; color?: string }>> = {
  BookOpen,
  NotePencil,
  Users,
  Flame,
  Heart,
  Trophy,
};

interface DailyJourneyCardProps {
  steps: DailyStep[];
  nextStep: DailyStep | null;
  completed: string[];
  progress: number;
  onActionPress(step: DailyStep): void;
  onToggleComplete(step: DailyStep): void;
}

const DailyJourneyCard: React.FC<DailyJourneyCardProps> = ({
  steps,
  nextStep,
  completed,
  progress,
  onActionPress,
  onToggleComplete,
}) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const progressPercent = Math.round(progress * 100);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Today&apos;s Path</Text>
        <Text style={styles.subtitle}>
          {nextStep ? nextStep.summary : 'Stay faithful to what you have learned and encourage another citizen today.'}
        </Text>
        <View style={styles.progressTrack}>
          <View style={[styles.progressFill, { width: `${progressPercent}%` }]} />
        </View>
        <Text style={styles.progressLabel}>{progressPercent}% of today&apos;s path complete</Text>
        {nextStep ? (
          <TouchableOpacity
            style={styles.primaryButton}
            activeOpacity={0.85}
            onPress={() => onActionPress(nextStep)}
          >
            <Text style={styles.primaryButtonText}>{nextStep.actionLabel}</Text>
            <ChevronRight size={18} color={theme.colors.text.inverse} />
          </TouchableOpacity>
        ) : (
          <View style={styles.successPill}>
            <Check size={18} color={theme.colors.success} />
            <Text style={styles.successText}>Path complete. Pour into someone else.</Text>
          </View>
        )}
      </View>

      <View style={styles.stepsContainer}>
        {steps.map(step => {
          const Icon = ICON_MAP[step.icon];
          const isComplete = completed.includes(step.id);

          return (
            <View key={step.id} style={styles.stepRow}>
              <View style={styles.stepIconWrapper}>
                <Icon size={20} color={theme.colors.primary} />
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepTitle}>{step.title}</Text>
                <Text style={styles.stepSummary}>{step.summary}</Text>
                <View style={styles.stepActions}>
                  <TouchableOpacity
                    style={[styles.stepActionButton, { backgroundColor: `${theme.colors.primary}12` }]}
                    onPress={() => onActionPress(step)}
                    activeOpacity={0.85}
                  >
                    <Text style={styles.stepActionText}>{step.actionLabel}</Text>
                    <ChevronRight size={14} color={theme.colors.primary} />
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.stepToggle, isComplete && styles.stepToggleComplete]}
                    onPress={() => onToggleComplete(step)}
                    activeOpacity={0.8}
                  >
                    {isComplete ? (
                      <Check size={18} color={theme.colors.text.inverse} />
                    ) : (
                      <View style={styles.stepToggleInner} />
                    )}
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          );
        })}
      </View>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: `${theme.colors.border}90`,
    gap: theme.spacing.lg,
  },
  header: {
    gap: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  subtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 20,
  },
  progressTrack: {
    height: 8,
    borderRadius: 4,
    backgroundColor: `${theme.colors.border}60`,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
  },
  progressLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  primaryButton: {
    marginTop: theme.spacing.xs,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.primary,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
  },
  primaryButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  },
  successPill: {
    marginTop: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.success}20`,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  successText: {
    ...theme.typography.caption.primary,
    color: theme.colors.success,
  },
  stepsContainer: {
    gap: theme.spacing.md,
  },
  stepRow: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  stepIconWrapper: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme.colors.primary}12`,
  },
  stepContent: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  stepTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  stepSummary: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    lineHeight: 18,
  },
  stepActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.xs,
  },
  stepActionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
  },
  stepActionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  stepToggle: {
    width: 32,
    height: 32,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.surface,
  },
  stepToggleComplete: {
    backgroundColor: theme.colors.primary,
    borderColor: theme.colors.primary,
  },
  stepToggleInner: {
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: `${theme.colors.text.secondary}60`,
  },
});

export default DailyJourneyCard;
