import React, { memo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Platform } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Clock, Star, X, Check } from '@/components/Icons';
import { Theme } from '@/theme';
import { Challenge } from '@/types/challenges';
import * as Haptics from 'expo-haptics';
import { getTimeRemaining, getFrequencyLabel } from '@/utils/challengeHelpers';

export interface ChallengeCardProps {
  challenge: Challenge;
  theme: Theme;
  activeCategory: 'personal' | 'community' | 'suggested';
  isCreatingLoading: boolean;
  isJoiningLoading: boolean;
  isUpvotingLoading: boolean;
  onPress: () => void;
  onJoin: () => void;
  onLeave: () => void;
  onComplete: () => void;
  onVote: () => void;
}

const ChallengeCard = memo(({
  challenge,
  theme,
  activeCategory,
  isCreatingLoading,
  isJoiningLoading,
  isUpvotingLoading,
  onPress,
  onJoin,
  onLeave,
  onComplete,
  onVote,
}: ChallengeCardProps) => {
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  const isVirtue = challenge.type === 'virtue';
  const color = isVirtue ? theme?.colors.success : theme?.colors.error;
  const CIcon = isVirtue ? Star : X;
  const timeRemaining = getTimeRemaining(challenge.endTime);
  const isExpired = timeRemaining === 'Expired';
  const isJoined = Boolean((challenge as any)?.hasJoined);
  const isCompleted = !!challenge.isCompleted;
  const actionInProgress = activeCategory === 'suggested' ? isCreatingLoading : isJoiningLoading;

  const handlePrimaryAction = async () => {
    if (actionInProgress) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    if (activeCategory === 'suggested') {
      if (!isExpired && !isJoined) {
        onJoin();
      }
      return;
    }

    if (isJoined) {
      onLeave();
    } else {
      if (!isExpired) {
        onJoin();
      }
    }
  };

  const primaryLabel = activeCategory === 'suggested'
    ? 'Join'
    : isJoined
      ? 'Leave'
      : 'Join';

  const createdAt = new Date(challenge.createdAt);
  const now = new Date();
  const ms3days = 3 * 24 * 60 * 60 * 1000;
  const withinWindow = now.getTime() - createdAt.getTime() < ms3days;
  const belowCap = (challenge.upvotes || 0) < 100;
  const canVote = !challenge.hasUpvoted && withinWindow && belowCap;

  return (
    <TouchableOpacity style={styles.challengeCard} onPress={onPress}>
      <LinearGradient
        colors={[`${color}10`, `${color}02`]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.cardGradient}
      />

      <View style={styles.challengeHeader}>
        <View style={[styles.typeTag, { backgroundColor: `${color}15` }]}>
          <CIcon size={14} color={color} />
          <Text style={[styles.typeText, { color }]}>
            {isVirtue ? 'Virtue' : 'Vice'}
          </Text>
        </View>
        {challenge.hasJoined && (
          <View style={[styles.badge, { backgroundColor: `${theme?.colors.success}15` }]}>
            <Check size={12} color={theme?.colors.success} />
            <Text style={[styles.badgeText, { color: theme?.colors.success }]}>Joined</Text>
          </View>
        )}
        {isCompleted && (
          <View style={[styles.badge, { backgroundColor: `${theme?.colors.primary}10` }]}>
            <Check size={12} color={theme?.colors.primary} />
            <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>Completed</Text>
          </View>
        )}
        <View style={styles.timeContainer}>
          <Clock size={14} color={isExpired ? theme?.colors.error : theme?.colors.text.secondary} />
          <Text style={[
            styles.timeText, 
            isExpired && { color: theme?.colors.error }
          ]}>
            {timeRemaining}
          </Text>
        </View>
      </View>

      <Text style={styles.challengeTitle}>{challenge.title}</Text>
      {!!challenge.description && (
        <Text style={styles.challengeDescription} numberOfLines={2}>
          {challenge.description}
        </Text>
      )}

      <View style={styles.actionContainer}>
        {(!!(challenge as any)?.tier || !!(challenge as any)?.points) && activeCategory === 'community' && (
          <View style={[styles.badge, { backgroundColor: `${theme?.colors.primary}10`, marginRight: 'auto' }]}> 
            <Star size={14} color={theme?.colors.primary} />
            <Text style={[styles.badgeText, { color: theme?.colors.primary }]}>
              {(challenge as any)?.tier ? `Tier ${(challenge as any).tier}` : `${(challenge as any).points} pts`}
            </Text>
          </View>
        )}

        <TouchableOpacity
          style={[styles.primaryActionButton, { backgroundColor: `${theme?.colors.primary}12` }]}
          onPress={handlePrimaryAction}
          disabled={actionInProgress || (activeCategory === 'suggested' && (isJoined || isExpired)) || (!isJoined && isExpired)}
          activeOpacity={0.8}
        >
          <Text style={[styles.primaryActionText, actionInProgress && { opacity: 0.6 }]}>
            {actionInProgress ? 'Please wait…' : primaryLabel}
          </Text>
        </TouchableOpacity>

        {activeCategory === 'personal' && isJoined && !isCompleted && !isExpired ? (
          <TouchableOpacity
            style={[styles.actionButton, { backgroundColor: `${theme?.colors.success}15` }]}
            onPress={() => {
              if (actionInProgress) return;
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onComplete();
            }}
            disabled={actionInProgress}
          >
            <Check size={16} color={theme?.colors.success} />
            <Text style={[styles.actionText, { color: theme?.colors.success }]}>I Did It</Text>
          </TouchableOpacity>
        ) : null}

        {activeCategory === 'community' && canVote ? (
          <TouchableOpacity
            style={[styles.actionButton, { backgroundColor: `${theme?.colors.primary}15` }]}
            onPress={() => { Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); onVote(); }}
            disabled={isUpvotingLoading}
          >
            <Star size={16} color={theme?.colors.primary} />
            <Text style={[styles.actionText, { color: theme?.colors.primary }]}>Vote</Text>
          </TouchableOpacity>
        ) : null}
      </View>

      {activeCategory === 'community' && (
        <View style={styles.compactInfoRow}>
          <Text style={styles.compactInfoText}>
            {getFrequencyLabel(challenge.frequency)} {(challenge.upvotes||0)}/100 votes
          </Text>
        </View>
      )}
    </TouchableOpacity>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  challengeCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    marginBottom: theme?.spacing.md,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  cardGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  challengeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme?.spacing.md,
  },
  typeTag: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
  },
  typeText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  timeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginLeft: theme?.spacing.xs,
  },
  challengeTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.sm,
  },
  challengeDescription: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    paddingHorizontal: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  actionContainer: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    padding: theme?.spacing.md,
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  primaryActionButton: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  actionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  primaryActionText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
    color: theme?.colors.primary,
    textAlign: 'center',
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme?.borderRadius.full,
    gap: 6,
  },
  badgeText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
  },
  compactInfoRow: {
    marginTop: 4,
    paddingHorizontal: theme?.spacing.md,
    paddingBottom: theme?.spacing.sm,
  },
  compactInfoText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
});

ChallengeCard.displayName = 'ChallengeCard';

export default ChallengeCard;
