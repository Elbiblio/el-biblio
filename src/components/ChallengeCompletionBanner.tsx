import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Animated, Platform } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { useChallengeStore } from '@/stores/ChallengeStore';
import { Challenge } from '@/types/challenges';
import { RootStackParamList } from '@/types';
import { Trophy, X, Check, Flame, Star, Sparkle } from '@/components/Icons';
import * as Haptics from 'expo-haptics';
import { LinearGradient } from 'expo-linear-gradient';

interface ChallengeCompletionBannerProps {
  onDismiss: () => void;
}

const ChallengeCompletionBanner: React.FC<ChallengeCompletionBannerProps> = ({ onDismiss }) => {
  const theme = useTheme();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const store = useChallengeStore();
  const styles = useMemo(() => createStyles(theme), [theme]);

  // Get uncompleted personal challenges - memoized for performance
  const uncompletedChallenges = useMemo(
    () => store.personalChallenges.filter(challenge => challenge?.id && challenge.title && !challenge.isCompleted && challenge.hasJoined),
    [store.personalChallenges]
  );

  const [selectedChallenge, setSelectedChallenge] = useState<Challenge | null>(() => 
    uncompletedChallenges.length > 0 ? uncompletedChallenges[0] : null
  );
  const [countdown, setCountdown] = useState(15);
  const [canDismiss, setCanDismiss] = useState(false);
  const [isCompleting, setIsCompleting] = useState(false);

  // Sync selected challenge when store updates
  useEffect(() => {
    if (!selectedChallenge && uncompletedChallenges.length > 0) {
      setSelectedChallenge(uncompletedChallenges[0]);
    } else if (selectedChallenge && !uncompletedChallenges.find(ch => ch.id === selectedChallenge.id)) {
      // Current challenge was removed, select next one
      setSelectedChallenge(uncompletedChallenges[0] ?? null);
    }
  }, [uncompletedChallenges, selectedChallenge]);

  // Animation refs - created once
  const countdownInterval = useRef<ReturnType<typeof setInterval> | null>(null);
  const slideAnim = useRef(new Animated.Value(-300)).current;
  const scaleAnim = useRef(new Animated.Value(0.8)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const sparkleAnim = useRef(new Animated.Value(0)).current;

  // Mount animations and countdown - runs once
  useEffect(() => {
    // Animate banner in
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

    // Start pulsing animation
    const pulseAnimation = Animated.loop(
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
    );
    
    const pulseTimeout = setTimeout(() => pulseAnimation.start(), 500);

    // Start countdown
    countdownInterval.current = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) {
          setCanDismiss(true);
          Animated.spring(sparkleAnim, {
            toValue: 1,
            useNativeDriver: true,
            tension: 200,
            friction: 5,
          }).start();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (countdownInterval.current) {
        clearInterval(countdownInterval.current);
      }
      clearTimeout(pulseTimeout);
      pulseAnimation.stop();
    };
  }, [slideAnim, scaleAnim, pulseAnim, sparkleAnim]);

  const handleComplete = useCallback(async () => {
    if (!selectedChallenge || isCompleting) return;

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
        handleDismiss();
      }
    } catch (error) {
      console.error('Error completing challenge:', error);
      setIsCompleting(false);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    }
  }, [selectedChallenge, isCompleting, store, uncompletedChallenges]);

  const handleDismiss = useCallback(() => {
    if (countdownInterval.current) {
      clearInterval(countdownInterval.current);
    }
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
  }, [slideAnim, scaleAnim, onDismiss]);

  const handleViewChallenge = useCallback(() => {
    if (selectedChallenge) {
      navigation.navigate('ChallengeDetail', { id: selectedChallenge.id });
      handleDismiss();
    }
  }, [selectedChallenge, navigation, handleDismiss]);

  if (!selectedChallenge) {
    return null;
  }

  const overlayColors = useMemo(() => ['rgba(0,0,0,0.7)', 'rgba(0,0,0,0.7)'] as const, []);
  const surfaceColors = useMemo(() => [theme?.colors.surface ?? '#F5F7F3', theme?.colors.surface ?? '#F5F7F3'] as const, [theme?.colors.surface]);

  return (
    <Animated.View style={styles.overlay}>
      <LinearGradient
        colors={overlayColors}
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
            colors={surfaceColors}
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
                <Text style={styles.mainTitle} numberOfLines={1} ellipsizeMode="tail">Challenge Time! 👋</Text>
                <Text style={styles.subtitle}>You asked for a reminder, Let's crush this challenge now shall we? 💪</Text>
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
                colors={surfaceColors}
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
                </View>

                {!!selectedChallenge.description && (
                  <Text
                    style={styles.previewText}
                    numberOfLines={2}
                  >
                    {selectedChallenge.description.slice(0, 100)}{selectedChallenge.description.length > 100 ? '…' : ''}
                  </Text>
                )}
              </LinearGradient>
            </Animated.View>

            {/* Progress indicator */}
            <View style={styles.progressSection}>
              {!canDismiss ? (
                <View style={styles.countdownContainer}>
                  <Text style={styles.countdownLabel}>⏰ Just {countdown} more seconds...</Text>
                  <View style={styles.countdownDisplay}>
                    <Text allowFontScaling={false} style={styles.countdownNumber}>{countdown}</Text>
                    <Text allowFontScaling={false} style={styles.countdownUnit}>sec</Text>
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
    padding: theme?.spacing.xs,
  },
  banner: {
    width: '100%',
    maxWidth: 360,
    borderRadius: theme?.borderRadius.xl,
    overflow: 'hidden',
    backgroundColor: theme?.colors.surface,
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
    padding: theme?.spacing.lg,
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
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
    minWidth: 0,
  },
  mainTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    fontSize: 24,
    fontWeight: '800',
    marginBottom: 4,
    flexShrink: 1,
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
    marginBottom: theme?.spacing.md,
  },
  challengeGradient: {
    padding: theme?.spacing.md,
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
  previewText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.sm,
  },
  progressSection: {
    flex: 1,
    marginBottom: theme?.spacing.md,
    alignItems: 'center',
  },
  countdownContainer: {
    alignItems: 'center',
    gap: theme?.spacing.xs,
    paddingVertical: theme?.spacing.sm,
    overflow: 'visible',
    position: 'relative',
    zIndex: 1,
  },
  countdownLabel: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontSize: 14,
    marginBottom: theme?.spacing.sm,
  },
  countdownDisplay: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: theme?.spacing.xs,
    minHeight: 56,
    overflow: 'visible',
  },
  countdownNumber: {
    ...theme?.typography.heading.large,
    color: theme?.colors.primary,
    fontSize: 40,
    lineHeight: 56,
    fontWeight: '800',
    includeFontPadding: false,
    paddingTop: 2,
  },
  countdownUnit: {
    ...theme?.typography.body.sans,
    color: theme?.colors.primary,
    fontSize: 16,
    fontWeight: '600',
    marginLeft: theme?.spacing.xs,
    marginBottom: theme?.spacing.xxs,
    alignSelf: 'flex-end',
    includeFontPadding: false,
    textAlignVertical: 'bottom',
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
    marginBottom: theme?.spacing.md,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme?.spacing.md,
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
