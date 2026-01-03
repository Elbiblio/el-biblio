import React, { useRef, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Platform } from 'react-native';
import Animated, { useSharedValue, useAnimatedStyle, withTiming, withSequence, withRepeat } from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import { PIConfetti } from 'react-native-fast-confetti';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { ArrowLeft, Trophy, Star } from '@/components/Icons';

export type VirtueTriviaCompleteProps = {
  virtueName: string;
  score: number;
  highScore: number;
  correctAnswers: number;
  totalQuestions: number;
  userLevelLabel: string;
  remainingToLevelUp: number;
  onPlayAgain: () => void;
  onGoBack?: () => void;
};

const VirtueTriviaComplete: React.FC<VirtueTriviaCompleteProps> = ({
  virtueName,
  score,
  highScore,
  correctAnswers,
  totalQuestions,
  userLevelLabel,
  remainingToLevelUp,
  onPlayAgain,
  onGoBack,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  const percent = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;
  const passed = percent >= 70;

  const bannerPulse = useSharedValue(0.95);
  const badgeFloat = useSharedValue(0);

  const bannerStyle = useAnimatedStyle(() => ({
    transform: [{ scale: bannerPulse.value }],
  }));
  const badgeStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: badgeFloat.value }],
  }));

  useEffect(() => {
    bannerPulse.value = withRepeat(withSequence(withTiming(1, { duration: 700 }), withTiming(0.97, { duration: 700 })), -1, true);
    badgeFloat.value = withRepeat(withSequence(withTiming(-6, { duration: 900 }), withTiming(0, { duration: 900 })), -1, true);
  }, []);

  const confettiRef = useRef<any>(null);
  useEffect(() => {
    // burst once on mount
    confettiRef.current?.restart?.();
  }, []);

  return (
    <View style={styles.container}>
      {onGoBack && (
        <TouchableOpacity style={styles.backButton} onPress={onGoBack}>
          <ArrowLeft size={18} color={theme.colors.text.primary} />
          <Text style={styles.backButtonText}>Back</Text>
        </TouchableOpacity>
      )}
      <PIConfetti ref={confettiRef} count={passed ? 220 : 140} fadeOutOnEnd colors={['#FFD700','#FF8C00','#00BCD4','#8BC34A','#FF69B4','#BA55D3']} />

      <Animated.View style={[styles.banner, bannerStyle]}>
        <LinearGradient
          colors={passed ? ['#22c55e33', '#22c55e11'] : ['#f59e0b33', '#f59e0b11']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        <Animated.View style={[styles.badge, badgeStyle]}>
          {passed ? <Trophy size={28} color="#FFD700" /> : <Star size={28} color={theme.colors.warning} />}
        </Animated.View>
        <Text style={styles.title}>{passed ? 'Quiz Complete!' : 'Quiz Complete'}</Text>
        <Text style={styles.subtitle}>{passed ? 'Virtue mastered — amazing!' : 'Keep going — you got this!'}</Text>
      </Animated.View>

      <View style={styles.card}>
        <LinearGradient colors={[`${theme.colors.surface}FF`, `${theme.colors.surface}E6`]} style={StyleSheet.absoluteFill} />
        <Text style={styles.statLabel}>Virtue</Text>
        <Text style={styles.virtueName}>{virtueName}</Text>

        <Text style={styles.finalScore}>Final Score: <Text style={styles.finalScoreValue}>{score}</Text></Text>

        <View style={styles.progressBlock}>
          <Text style={styles.progressText}>{correctAnswers} of {totalQuestions} correct ({percent}%)</Text>
          <View style={styles.progressTrack}>
            <View style={[styles.progressFill, { width: `${percent}%`, backgroundColor: passed ? theme.colors.success : theme.colors.warning }]} />
          </View>
          <View style={[styles.tip, { backgroundColor: passed ? `${theme.colors.success}20` : `${theme.colors.warning}20` }] }>
            <Text style={[styles.tipText, { color: passed ? theme.colors.success : theme.colors.warning }]}>
              {passed ? 'Mastered — great job!' : `Need ${Math.max(0, 7 - correctAnswers)} more correct to master`}
            </Text>
          </View>
        </View>

        <View style={styles.statsRow}>
          <View style={styles.statPill}><Text style={styles.statPillText}>High Score: {highScore}</Text></View>
          <View style={styles.statPill}><Text style={styles.statPillText}>Level: {userLevelLabel}</Text></View>
        </View>

        <View style={styles.levelUpBlock}>
          <Text style={styles.levelUpText}>
            {remainingToLevelUp > 0 ? `Complete ${remainingToLevelUp} more ${remainingToLevelUp === 1 ? 'virtue' : 'virtues'} to level up` : 'Ready to level up!'}
          </Text>
        </View>

        <TouchableOpacity style={[styles.playAgainBtn, { backgroundColor: theme.colors.primary }]} onPress={onPlayAgain}>
          <Text style={styles.playAgainText}>Play Again</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default VirtueTriviaComplete;

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.lg,
  },
  backButton: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    backgroundColor: `${theme.colors.text.primary}10`,
    borderRadius: theme.borderRadius.full,
    marginBottom: theme.spacing.sm,
  },
  backButtonText: {
    marginLeft: theme.spacing.xs,
    color: theme.colors.text.primary,
    fontWeight: '600',
    fontSize: 14,
  },
  banner: {
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.lg,
    marginBottom: theme.spacing.md,
    borderRadius: theme.borderRadius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: `${theme.colors.text.secondary}22`,
  },
  badge: {
    position: 'absolute',
    top: 8,
    right: 16,
    backgroundColor: `${theme.colors.background}AA`,
    borderRadius: 22,
    padding: 6,
    ...Platform.select({ ios: { shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 6, shadowOffset: { width: 0, height: 2 } }, android: { elevation: 3 } }),
  },
  title: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
  },
  subtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: 4,
  },
  card: {
    width: '100%',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.text.secondary}22`,
    ...Platform.select({ ios: { shadowColor: '#000', shadowOpacity: 0.08, shadowRadius: 10, shadowOffset: { width: 0, height: 4 } }, android: { elevation: 4 } }),
  },
  statLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  virtueName: {
    ...theme.typography.heading.small,
    textAlign: 'center',
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  finalScore: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.xs,
  },
  finalScoreValue: {
    color: theme.colors.primary,
    fontWeight: '900',
  },
  progressBlock: {
    marginTop: theme.spacing.sm,
    marginBottom: theme.spacing.md,
  },
  progressText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.xs,
  },
  progressTrack: {
    height: 8,
    borderRadius: 4,
    backgroundColor: `${theme.colors.text.secondary}18`,
    overflow: 'hidden',
    marginBottom: theme.spacing.xs,
  },
  progressFill: {
    height: '100%',
    borderRadius: 4,
  },
  tip: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: theme.borderRadius.md,
    alignSelf: 'center',
  },
  tipText: {
    ...theme.typography.caption.primary,
    fontWeight: '700',
  },
  statsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: theme.spacing.md,
  },
  statPill: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: `${theme.colors.text.secondary}12`,
    borderRadius: theme.borderRadius.full,
  },
  statPillText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  levelUpBlock: {
    marginTop: theme.spacing.md,
    alignItems: 'center',
    padding: theme.spacing.md,
    backgroundColor: `${theme.colors.text.secondary}10`,
    borderRadius: theme.borderRadius.lg,
  },
  levelUpText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  playAgainBtn: {
    marginTop: theme.spacing.lg,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
  },
  playAgainText: {
    ...theme.typography.body.sans,
    color: '#FFF',
    fontWeight: '800',
  },
});
