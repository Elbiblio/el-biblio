import React, { useState, useEffect, useRef } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Animated, Platform, Dimensions } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useChallengeStore } from '@/stores/ChallengeStore';
import { Challenge } from '@/types/challenges';
import { Trophy, X, Check, Flame, Star, Sparkle } from '@/components/Icons';
import * as Haptics from 'expo-haptics';
import { LinearGradient } from 'expo-linear-gradient';

interface ChallengeCompletionBannerProps {
  onDismiss: () => void;
}

const ChallengeCompletionBanner: React.FC<ChallengeCompletionBannerProps> = ({ onDismiss }) => {
  const theme = useTheme();
  const navigation = useNavigation();
  const store = useChallengeStore();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // Get uncompleted personal challenges
  const uncompletedChallenges = store.personalChallenges.filter(
    challenge => !challenge.isCompleted && challenge.hasJoined
  );

  const [selectedChallenge, setSelectedChallenge] = useState<Challenge | null>(
    uncompletedChallenges.length > 0 ? uncompletedChallenges[0] : null
  );
  const [countdown, setCountdown] = useState(15);
  const [canDismiss, setCanDismiss] = useState(false);
  const [isCompleting, setIsCompleting] = useState(false);

  // Animation refs
  const countdownInterval = useRef<number | null>(null);
  const slideAnim = useRef(new Animated.Value(-300)).current;
  const scaleAnim = useRef(new Animated.Value(0.8)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const sparkleAnim = useRef(new Animated.Value(0)).current;

  const { width: screenWidth } = Dimensions.get('window');

  useEffect(() => {
    // Animate banner in with bounce effect
    Animated.parallel([
      Animated.spring(slideAnim, {
        toValue: 0,
        useNativeDriver: true,
        tension: 50,
        friction: 7,
      }),
      Animated.spring(scaleAnim, {
        toValue: 1,
        useNativeDriver: true,
        tension: 100,
        friction: 8,
      }),
    ]).start();

    // Start pulsing animation for encouragement
    const startPulseAnimation = () => {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.05,
            duration: 1000,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 1000,
            useNativeDriver: true,
          }),
        ])
      ).start();
    };

    // Start countdown with sparkle effect
    countdownInterval.current = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) {
          setCanDismiss(true);
          // Trigger sparkle animation when countdown completes
          Animated.spring(sparkleAnim, {
            toValue: 1,
            useNativeDriver: true,
            tension: 200,
            friction: 5,
          }).start(() => {
            // Fade out sparkle after a moment
            setTimeout(() => {
              Animated.timing(sparkleAnim, {
                toValue: 0,
                duration: 500,
                useNativeDriver: true,
              }).start();
            }, 1000);
          });
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    // Start animations after a brief delay
    setTimeout(startPulseAnimation, 500);

    return () => {
      if (countdownInterval.current) {
        clearInterval(countdownInterval.current);
      }
    };
  }, []);

  const handleComplete = async () => {
    if (!selectedChallenge) return;

    setIsCompleting(true);
    try {
      await store.completeChallenge(selectedChallenge.id, true);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

      // Check if there are more uncompleted challenges
      const remaining = uncompletedChallenges.filter(c => c.id !== selectedChallenge.id);
      if (remaining.length > 0) {
        setSelectedChallenge(remaining[0]);
        setCountdown(15);
        setCanDismiss(false);
        setIsCompleting(false);
      } else {
        // No more challenges, dismiss banner
        handleDismiss();
      }
    } catch (error) {
      console.error('Error completing challenge:', error);
      setIsCompleting(false);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    }
  };

  const handleViewChallenge = () => {
    if (selectedChallenge) {
      (navigation as any).navigate('ChallengeDetail', { id: selectedChallenge.id });
      handleDismiss();
    }
  };

  const handleDismiss = () => {
    Animated.parallel([
      Animated.spring(slideAnim, {
        toValue: -300,
        useNativeDriver: true,
        tension: 50,
        friction: 7,
      }),
      Animated.timing(scaleAnim, {
        toValue: 0.8,
        duration: 200,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onDismiss();
    });
  };

  if (!selectedChallenge) {
    return null;
  }

  return (
    <Animated.View style={[styles.overlay]}>
      <LinearGradient
        colors={['rgba(0,0,0,0)', 'rgba(0,0,0,0.3)', 'rgba(0,0,0,0.5)']}
        style={styles.overlayGradient}
      >
        <Animated.View
          style={[
            styles.banner,
            {
              transform: [
                { translateY: slideAnim },
                { scale: scaleAnim }
              ]
            }
          ]}
        >
          <LinearGradient
            colors={[`${theme?.colors.primary}20`, `${theme?.colors.primary}10`, 'transparent']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.bannerGradient}
          >
            {/* Header with trophy and motivational title */}
            <View style={styles.header}>
              <View style={styles.trophyContainer}>
                <Animated.View style={{ transform: [{ scale: pulseAnim }] }}>
                  <Trophy size={28} color={theme?.colors.primary} />
                </Animated.View>
              </View>
              <View style={styles.titleContainer}>
                <Text style={styles.mainTitle}>Challenge Time! 👋</Text>
                <Text style={styles.subtitle}>You asked for a reminder, so here it is! Let's crush this challenge now shall we? 💪</Text>
              </View>
              {canDismiss && (
                <TouchableOpacity style={styles.closeButton} onPress={handleDismiss}>
                  <X size={20} color={theme?.colors.text.secondary} />
                </TouchableOpacity>
              )}
            </View>

            {/* Challenge card */}
            <Animated.View style={[styles.challengeCard, { transform: [{ scale: pulseAnim }] }]}>
              <LinearGradient
                colors={[theme?.colors.surface, `${theme?.colors.primary}05`]}
                style={styles.challengeGradient}
              >
                <View style={styles.challengeHeader}>
                  <View style={styles.challengeIcon}>
                    <Flame size={20} color={theme?.colors.primary} />
                  </View>
                  <Text style={styles.challengeTitle}>{selectedChallenge.title}</Text>
                </View>

                <View style={styles.challengeStats}>
                  <View style={styles.statItem}>
                    <Star size={16} color={theme?.colors.primary} />
                    <Text style={styles.statText}>
                      {selectedChallenge.points ? `${selectedChallenge.points} pts` : 'Complete now'}
                    </Text>
                  </View>
                  <View style={styles.statItem}>
                    <Star size={16} color={theme?.colors.success} />
                    <Text style={styles.statText}>Ready to conquer!</Text>
                  </View>
                </View>
              </LinearGradient>
            </Animated.View>

            {/* Progress indicator */}
            <View style={styles.progressSection}>
              {!canDismiss ? (
                <View style={styles.countdownContainer}>
                  <Text style={styles.countdownLabel}>⏰ Just {countdown} more seconds...</Text>
                  <View style={styles.countdownDisplay}>
                    <Text style={styles.countdownNumber}>{countdown}</Text>
                    <Text style={styles.countdownUnit}>sec</Text>
                  </View>
                  <Animated.View
                    style={[
                      styles.sparkleEffect,
                      { opacity: sparkleAnim }
                    ]}
                  >
                    <Sparkle size={24} color={theme?.colors.primary} />
                  </Animated.View>
                </View>
              ) : (
                <View style={styles.readyContainer}>
                  <Text style={styles.readyText}>✨ Alright, your choice now! Let's do this!</Text>
                </View>
              )}
            </View>

            {/* Action buttons */}
            <View style={styles.actionsContainer}>
              <TouchableOpacity
                style={[styles.actionButton, styles.viewButton]}
                onPress={handleViewChallenge}
              >
                <Flame size={18} color={theme?.colors.text.secondary} />
                <Text style={styles.viewButtonText}>Check Details</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.actionButton,
                  styles.completeButton,
                  isCompleting && styles.completeButtonDisabled
                ]}
                onPress={handleComplete}
                disabled={isCompleting}
              >
                {isCompleting ? (
                  <View style={styles.completingContainer}>
                    <Text style={styles.completingText}>🎉 Completing...</Text>
                  </View>
                ) : (
                  <>
                    <Check size={18} color="#FFFFFF" />
                    <Text style={styles.completeButtonText}>I Did It! 🎉</Text>
                    <Sparkle size={16} color="#FFFFFF" />
                  </>
                )}
              </TouchableOpacity>
            </View>

            {/* Encouraging footer */}
            {uncompletedChallenges.length > 1 && (
              <View style={styles.footer}>
                <Text style={styles.footerText}>
                  🚀 Plus {uncompletedChallenges.length - 1} more challenge{uncompletedChallenges.length - 1 !== 1 ? 's' : ''} waiting!
                </Text>
                <Text style={styles.footerSubtext}>
                  As you sow, you grow! 🔥
                </Text>
              </View>
            )}
          </LinearGradient>
        </Animated.View>
      </LinearGradient>
    </Animated.View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1000,
  },
  overlayGradient: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme?.spacing.md,
  },
  banner: {
    width: '100%',
    maxWidth: 400,
    borderRadius: theme?.borderRadius.xl,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.3,
        shadowRadius: 20,
      },
      android: {
        elevation: 20,
      },
    }),
  },
  bannerGradient: {
    padding: theme?.spacing.xl,
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.lg,
    width: '100%',
  },
  trophyContainer: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: `${theme?.colors.primary}20`,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme?.spacing.md,
  },
  titleContainer: {
    flex: 1,
  },
  mainTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    fontSize: 24,
    fontWeight: '800',
    marginBottom: 4,
  },
  subtitle: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontSize: 14,
    fontWeight: '600',
  },
  closeButton: {
    padding: theme?.spacing.sm,
  },
  challengeCard: {
    width: '100%',
    marginBottom: theme?.spacing.lg,
  },
  challengeGradient: {
    padding: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  challengeHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  challengeIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: `${theme?.colors.primary}15`,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme?.spacing.md,
  },
  challengeTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    flex: 1,
    fontSize: 18,
  },
  challengeStats: {
    gap: theme?.spacing.sm,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontSize: 14,
    marginLeft: theme?.spacing.sm,
  },
  progressSection: {
    marginBottom: theme?.spacing.lg,
    alignItems: 'center',
  },
  countdownContainer: {
    alignItems: 'center',
  },
  countdownLabel: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontSize: 14,
    marginBottom: theme?.spacing.sm,
  },
  countdownDisplay: {
    flexDirection: 'row',
    alignItems: 'baseline',
    marginBottom: theme?.spacing.sm,
  },
  countdownNumber: {
    ...theme?.typography.heading.large,
    color: theme?.colors.primary,
    fontSize: 48,
    fontWeight: '900',
  },
  countdownUnit: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontSize: 16,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
  },
  sparkleEffect: {
    position: 'absolute',
    top: -10,
    right: -10,
  },
  readyContainer: {
    alignItems: 'center',
  },
  readyText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.success,
    fontSize: 16,
    fontWeight: '600',
  },
  actionsContainer: {
    flexDirection: 'row',
    gap: theme?.spacing.md,
    width: '100%',
    marginBottom: theme?.spacing.lg,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme?.spacing.lg,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    gap: theme?.spacing.sm,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  viewButton: {
    backgroundColor: theme?.colors.surface,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  viewButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
    fontSize: 16,
  },
  completeButton: {
    backgroundColor: theme?.colors.success,
    flexDirection: 'row',
    gap: theme?.spacing.sm,
  },
  completeButtonDisabled: {
    backgroundColor: `${theme?.colors.success}50`,
  },
  completeButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 16,
  },
  completingContainer: {
    alignItems: 'center',
  },
  completingText: {
    ...theme?.typography.body.sans,
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 16,
  },
  footer: {
    alignItems: 'center',
  },
  footerText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontSize: 14,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 4,
  },
  footerSubtext: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontSize: 12,
  },
});

export default ChallengeCompletionBanner;
