import React, { memo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Theme } from '@/theme';

export interface ChallengeOnboardingOverlayProps {
  visible: boolean;
  theme: Theme;
  hasJoinedChallenge: boolean;
  onBrowse: () => void;
  onSkip: () => void;
}

const ChallengeOnboardingOverlay = memo(({
  visible,
  theme,
  hasJoinedChallenge,
  onBrowse,
  onSkip,
}: ChallengeOnboardingOverlayProps) => {
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  if (!visible) {
    return null;
  }

  return (
    <View style={styles.onboardingOverlay} pointerEvents="auto">
      <View style={styles.onboardingCard}>
        <Text style={styles.onboardingTitle}>Join a Daily Challenge</Text>
        <Text style={styles.onboardingBody}>
          Pick a challenge to stay consistent. We'll guide you with reminders and track your progress.
        </Text>
        <TouchableOpacity
          style={styles.onboardingPrimary}
          onPress={onBrowse}
        >
          <Text style={styles.onboardingPrimaryText}>
            {hasJoinedChallenge ? 'Go to my challenge' : 'Browse challenges'}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.onboardingSecondary}
          onPress={onSkip}
        >
          <Text style={styles.onboardingSecondaryText}>Skip for now</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  onboardingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.lg,
  },
  onboardingCard: {
    width: '100%',
    borderRadius: theme?.borderRadius.xl,
    backgroundColor: theme?.colors.surface,
    padding: theme?.spacing.lg,
    gap: theme?.spacing.md,
    borderWidth: 1,
    borderColor: `${theme?.colors.border}80`,
  },
  onboardingTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  onboardingBody: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
  },
  onboardingPrimary: {
    borderRadius: theme?.borderRadius.lg,
    paddingVertical: theme?.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme?.colors.primary,
  },
  onboardingPrimaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.inverse,
  },
  onboardingSecondary: {
    borderRadius: theme?.borderRadius.lg,
    paddingVertical: theme?.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    backgroundColor: theme?.colors.surface,
  },
  onboardingSecondaryText: {
    ...theme?.typography.button,
    color: theme?.colors.text.primary,
  },
});

ChallengeOnboardingOverlay.displayName = 'ChallengeOnboardingOverlay';

export default ChallengeOnboardingOverlay;
