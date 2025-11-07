import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Platform,
  Dimensions,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  withDelay,
  interpolate,
  Easing,
  FadeIn,
  FadeOut,
  SlideInDown,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { Trophy, Lightning, Check, Star } from '@/components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Confetti } from 'react-native-fast-confetti';
import * as Haptics from 'expo-haptics';

interface PointsEarnedModalProps {
  visible: boolean;
  onClose: () => void;
  pointsEarned: number;
  challengeTitle?: string;
  title?: string;
  autoCloseMs?: number;
}

const { height } = Dimensions.get('window');

const PointsEarnedModal: React.FC<PointsEarnedModalProps> = ({
  visible,
  onClose,
  pointsEarned,
  challengeTitle,
  title,
  autoCloseMs = 2500,
}) => {
  const theme = useTheme();
  const confettiRef = useRef<any>(null);
  const pointsScale = useSharedValue(0.3);
  const pulseValue = useSharedValue(1);
  const raysOpacity = useSharedValue(0);
  const challengeOpacity = useSharedValue(0);
  const confettiCount = React.useMemo(() => {
    if (pointsEarned < 5) return 0;
    const base = Platform.OS === 'android' ? 60 : 100;
    const scale = Math.min(1, Math.max(0.5, pointsEarned / 20));
    return Math.round(base * scale);
  }, [pointsEarned]);

  useEffect(() => {
    if (visible) {
      // Reset animations
      pointsScale.value = 0.3;
      pulseValue.value = 1;
      raysOpacity.value = 0;
      challengeOpacity.value = 0;

      // Play haptic feedback
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

      // Start animations
      setTimeout(() => {
        if (confettiRef.current && confettiCount > 0) {
          confettiRef.current.restart({
            cannonsPositions: [{ x: -10, y: 0 }],
          });
        }

        // Animate points counter
        pointsScale.value = withSequence(
          withTiming(1.2, { duration: 600, easing: Easing.out(Easing.back(2)) }),
          withTiming(1, { duration: 200 })
        );

        // Pulsing effect
        pulseValue.value = withDelay(800, withSequence(
          withTiming(1.1, { duration: 400 }),
          withTiming(1, { duration: 400 }),
          withTiming(1.05, { duration: 400 }),
          withTiming(1, { duration: 400 })
        ));

        // Show rays
        raysOpacity.value = withDelay(400, withTiming(1, { duration: 400 }));

        // Show challenge
        challengeOpacity.value = withDelay(800, withTiming(1, { duration: 400 }));
      }, 300);

      // Auto close after a brief display, to allow queued awards to show
      const t = setTimeout(() => {
        onClose();
      }, autoCloseMs);
      return () => clearTimeout(t);
    }
  }, [visible, pointsScale, pulseValue, raysOpacity, challengeOpacity]);

  const pointsAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      { scale: pointsScale.value },
      { scale: pulseValue.value }
    ],
  }));

  const raysAnimatedStyle = useAnimatedStyle(() => ({
    opacity: raysOpacity.value,
    transform: [
      { rotate: `${interpolate(raysOpacity.value, [0, 1], [0, 15])}deg` }
    ]
  }));

  const challengeAnimatedStyle = useAnimatedStyle(() => ({
    opacity: challengeOpacity.value,
    transform: [
      { translateY: interpolate(challengeOpacity.value, [0, 1], [20, 0]) }
    ]
  }));

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.container}>
        <BlurView
          intensity={Platform.OS === 'ios' ? 60 : 80}
          tint={theme?.colors.isDark ? 'dark' : 'light'}
          style={StyleSheet.absoluteFillObject}
        />

        <Animated.View
          entering={SlideInDown.springify().damping(15)}
          style={styles.modalContent}
        >
          {visible && confettiCount > 0 && (
            <Confetti
              ref={confettiRef}
              count={confettiCount}
              autoplay={false}
              fadeOutOnEnd
              colors={['#FFD700', '#FF6347', '#4169E1', '#32CD32', '#FF69B4', '#BA55D3']}
              containerStyle={styles.confetti}
            />
          )}

          {/* Title */}
          <Animated.Text
            entering={FadeIn.delay(300)}
            style={[styles.title, { color: theme?.colors.text.primary }]}
          >
            {title || 'Points Earned!'}
          </Animated.Text>
          
          {/* Points container with animated background rays */}
          <View style={styles.pointsOuterContainer}>
            <Animated.View style={[styles.rays, raysAnimatedStyle]}>
              {Array.from({ length: 12 }).map((_, i) => (
                <View 
                  key={i} 
                  style={[
                    styles.ray, 
                    { 
                      transform: [{ rotate: `${i * 30}deg` }],
                      backgroundColor: theme?.colors.primary 
                    }
                  ]} 
                />
              ))}
            </Animated.View>
            
            <Animated.View 
              style={[
                styles.pointsContainer, 
                { 
                  backgroundColor: theme?.colors.primary,
                  shadowColor: theme?.colors.primary,
                },
                pointsAnimatedStyle
              ]}
            >
              <Star size={24} color="#FFFFFF" style={styles.pointsIcon} />
              <Text style={styles.pointsText}>+{pointsEarned}</Text>
              <Text style={styles.pointsLabel}>POINTS</Text>
            </Animated.View>
          </View>
          
          {/* Challenge info */}
          {challengeTitle && (
            <Animated.View style={[styles.challengeContainer, challengeAnimatedStyle]}>
              <Text style={[styles.challengeLabel, { color: theme?.colors.text.secondary }]}>
                DAILY CHALLENGE ACTIVATED
              </Text>
              <View style={[styles.challengeCard, { borderColor: theme?.colors.border, backgroundColor: theme?.colors.surface }]}>
                <View style={styles.challengeContent}>
                  <Lightning 
                    size={20} 
                    color={theme?.colors.secondary} 
                    style={styles.challengeIcon} 
                  />
                  <Text style={[styles.challengeTitle, { color: theme?.colors.text.primary }]}>
                    {challengeTitle}
                  </Text>
                </View>
                <View style={[styles.badgeContainer, { backgroundColor: `${theme?.colors.secondary}15` }]}>
                  <Text style={[styles.badgeText, { color: theme?.colors.secondary }]}>Active</Text>
                </View>
              </View>
            </Animated.View>
          )}
          
          {/* Close button */}
          <TouchableOpacity
            style={[styles.button, { backgroundColor: theme?.colors.surface }]}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              onClose();
            }}
          >
            <Check size={20} color={theme?.colors.primary} style={styles.buttonIcon} />
            <Text style={[styles.buttonText, { color: theme?.colors.text.primary }]}>
              Continue
            </Text>
          </TouchableOpacity>
        </Animated.View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  modalContent: {
    width: '90%',
    maxWidth: 360,
    borderRadius: 24,
    overflow: 'hidden',
    paddingVertical: 28,
    paddingHorizontal: 22,
    alignItems: 'center',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 18, shadowOffset: { width: 0, height: 10 } },
      android: { elevation: 10 }
    }),
    backgroundColor: 'rgba(255,255,255,0.7)'
  },
  confetti: {
    position: 'absolute',
    width: '120%',
    height: height,
    top: -height * 0.3,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 24,
    textAlign: 'center',
  },
  pointsOuterContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 26,
  },
  rays: {
    position: 'absolute',
    width: 176,
    height: 176,
    alignItems: 'center',
    justifyContent: 'center',
  },
  ray: {
    position: 'absolute',
    width: 3,
    height: 86,
    borderRadius: 3,
    top: 0,
    left: '50%',
    marginLeft: -1.5,
    opacity: 0.7,
    transform: [{ translateY: -40 }],
  },
  pointsContainer: {
    width: 128,
    height: 128,
    borderRadius: 64,
    alignItems: 'center',
    justifyContent: 'center',
    ...Platform.select({
      ios: {
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.3,
        shadowRadius: 12,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  pointsIcon: {
    marginBottom: 4,
  },
  pointsText: {
    color: 'white',
    fontSize: 34,
    fontWeight: '800',
    marginVertical: 2,
  },
  pointsLabel: {
    color: 'white',
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 1,
    opacity: 0.9,
  },
  challengeContainer: {
    width: '100%',
    marginBottom: 24,
  },
  challengeLabel: {
    fontSize: 12,
    fontWeight: '600',
    letterSpacing: 0.5,
    marginBottom: 8,
    textAlign: 'center',
  },
  challengeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderRadius: 14,
    borderWidth: 1,
  },
  challengeContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  challengeIcon: {
    marginRight: 12,
  },
  challengeTitle: {
    fontSize: 14,
    fontWeight: '600',
    flex: 1,
  },
  badgeContainer: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 10,
    marginLeft: 8,
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    paddingHorizontal: 22,
    borderRadius: 14,
    width: '100%',
  },
  buttonIcon: {
    marginRight: 8,
  },
  buttonText: {
    fontSize: 15,
    fontWeight: '600',
  },
});

export default PointsEarnedModal;