import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { useSharedValue } from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { 
  ChevronRight,
  ChevronLeft,
  X,
  Sparkle,
} from '../components/Icons';
import GuestChoiceModal from '../components/GuestChoiceModal';
import { Theme } from '@/theme';
import { useTheme, useWelcomeState } from '@/contexts/ThemeContext';
import * as Haptics from 'expo-haptics';
import { RootStackParamList } from '@/types';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { OnboardingStep, STEPS } from '@/constants';
import { SCREEN_DIMENSIONS } from '@/constants';
import { useAuthStore } from '@/stores/StoreProvider';
import { toast } from 'sonner-native';
import { parseDescription } from '@/utils/ui';
import { playSound } from '@/services/audio';

const SCREEN_WIDTH = SCREEN_DIMENSIONS.width;

type IntroScreenProps = NativeStackScreenProps<RootStackParamList, 'IntroScreen'>;

const IntroScreen = ({
  navigation,
  route,
}: IntroScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  const [currentStep, setCurrentStep] = useState(0);
  const [showGuestChoice, setShowGuestChoice] = useState(false);
  const [showGuestFailure, setShowGuestFailure] = useState(false);
  const [guestFailureMessage, setGuestFailureMessage] = useState<string>('');
  const scrollRef = useRef<ScrollView>(null);
  const scrollX = useSharedValue(0);

  const { completeWelcome, hasCompletedWelcome } = useWelcomeState();
  const { createGuestAccount, isLoading, error } = useAuthStore();

  const onClose = async () => {
    try {
      if (!hasCompletedWelcome) {
        await completeWelcome();
        // Track onboarding completion
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        // Navigate to Home after completing welcome
        navigation.replace('Home');
      } else if (navigation.canGoBack()) {
        navigation.goBack();
      } else {
        navigation.replace('Home');
      }
    } catch (error) {
      console.error('Error completing welcome:', error);
      // Fallback navigation
      navigation.replace('Home');
    }
  };

  const handleNext = () => {
    if (currentStep === (STEPS.length - 1)) {
        setShowGuestChoice(true);
        // Track onboarding completion
        console.log('Onboarding completed, showing guest choice');
        return;
    }
    
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const nextStep = currentStep + 1;
    setCurrentStep(nextStep);
    
    // Track step progression
    console.log(`Onboarding step: ${currentStep + 1} -> ${nextStep + 1}`);
    
    scrollRef.current?.scrollTo({
      x: nextStep * SCREEN_WIDTH,
      animated: true,
    });
  };

  const handlePrevious = () => {
    if (currentStep === 0) return;
    
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const prevStep = currentStep - 1;
    setCurrentStep(prevStep);
    scrollRef.current?.scrollTo({
      x: prevStep * SCREEN_WIDTH,
      animated: true,
    });
  };

  const handleScroll = (event: any) => {
    scrollX.value = event.nativeEvent.contentOffset.x;
  };

  const handleRegister = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setShowGuestChoice(false);
    // Track registration choice
    console.log('User chose to register');
    navigation.navigate('RegistrationScreen');
  };

  const handleContinueAsGuest = async () => {
    setShowGuestChoice(false);
    try {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      const success = await createGuestAccount();
      if (success) {
        await completeWelcome();
        toast.success('Welcome to El-biblio!');
        //play level up sound
        playSound('level-up', 'mp3');
        // Navigate directly to Home after successful guest account creation
        navigation.replace('Home');
      } else {
        // Show failure modal with options to Retry or go Home unauthenticated
        setGuestFailureMessage(error || 'We created your account, but automatic sign-in failed. You can retry or continue to Home without sign-in.');
        setShowGuestFailure(true);
      }
    } catch (error) {
      console.error('Failed to create guest account:', error);
      setGuestFailureMessage((error as any)?.message || 'Failed to create guest account. Please try again.');
      setShowGuestFailure(true);
    }
  };

  const handleRetryGuest = async () => {
    try {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      const success = await createGuestAccount();
      if (success) {
        await completeWelcome();
        toast.success('Welcome to El-biblio!');
        setShowGuestFailure(false);
        navigation.replace('Home');
      } else {
        setGuestFailureMessage(error || 'Automatic sign-in still failing. You can try again or continue to Home.');
      }
    } catch (e) {
      setGuestFailureMessage((e as any)?.message || 'Retry failed. You can try again or continue to Home.');
    }
  };

  const handleGoHomeUnauthenticated = async () => {
    try {
      await completeWelcome();
    } catch {}
    setShowGuestFailure(false);
    navigation.replace('Home');
  };

  const renderStep = (step: OnboardingStep, index: number) => {
    const isFirst = index === 0;
    const isLast = index === STEPS.length - 1;

    return (
      <View 
        key={step.id}
        style={[styles.stepContainer, { width: SCREEN_WIDTH }]}
      >
        <BlurView intensity={10} style={StyleSheet.absoluteFill} />
        <View style={styles.stepContent}>
          {/* Icon */}
          <View 
            style={[
              styles.iconContainer,
              { backgroundColor: `${step.color}15` }
            ]}
          >
            <step.Icon size={48} color={step.color} />
          </View>

          {/* Title */}
          <Text style={styles.title}>{step.title}</Text>
          <Text style={styles.subtitle}>{step.subtitle}</Text>

          {/* Description */}
          <ScrollView 
            style={styles.descriptionScroll}
            contentContainerStyle={styles.descriptionContent}
            showsVerticalScrollIndicator={false}
          >
            {index == 0 ?
            <>
            <Text style={styles.introDescription}>Usage Guide</Text>
            <Text style={styles.description}>{parseDescription(step.description)}</Text>
            </>
            :
            <Text style={styles.description}>{step.description}</Text>
            }

            {step.practices.length > 0 && (
              <View style={styles.practicesContainer}>
                {index !== 0 && <Text style={styles.practicesTitle}>Guide:</Text>}
                {step.practices.map((practice, idx) => (
                  <View key={idx} style={styles.practiceItem}>
                    <Sparkle size={16} color={step.color} />
                    <Text style={styles.practiceText}>{practice}</Text>
                  </View>
                ))}
              </View>
            )}
          </ScrollView>

          {/* Navigation */}
          <View style={styles.navigation}>
            {!isFirst && (
              <TouchableOpacity
                style={styles.navButton}
                onPress={handlePrevious}
              >
                <ChevronLeft size={24} color={theme.colors.text.primary} />
                <Text style={styles.navText}>Previous</Text>
              </TouchableOpacity>
            )}

            <View style={styles.dots}>
              {STEPS.map((_, idx) => (
                <View
                  key={idx}
                  style={[
                    styles.dot,
                    currentStep === idx && styles.activeDot
                  ]}
                />
              ))}
            </View>

            <TouchableOpacity
              style={styles.navButton}
              onPress={handleNext}
            >
              <Text style={styles.navText}>
                {isLast ? 'Start Journey' : 'Next'}
              </Text>
              <ChevronRight size={24} color={theme.colors.text.primary} />
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  };

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Loading Overlay */}
      {isLoading && !showGuestFailure && (
        <View style={styles.loadingOverlay}>
          <BlurView intensity={20} style={StyleSheet.absoluteFill} />
          <View style={styles.loadingContent}>
            <Text style={styles.loadingText}>Setting up your account...</Text>
          </View>
        </View>
      )}
      
      {/* Close Button */}
      <TouchableOpacity 
        style={styles.closeButton}
        onPress={onClose}
        disabled={isLoading}
      >
        <X size={24} color={theme.colors.text.primary} />
      </TouchableOpacity>

      {/* Steps */}
      <ScrollView
        ref={scrollRef}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        scrollEventThrottle={16}
        onScroll={handleScroll}
        scrollEnabled={false}
      >
        {STEPS.map(renderStep)}
      </ScrollView>

      <GuestChoiceModal
        visible={showGuestChoice}
        onClose={() => setShowGuestChoice(false)}
        onRegister={handleRegister}
        onContinueAsGuest={handleContinueAsGuest}
      />

      {/* Guest Failure Modal */}
      {showGuestFailure && (
        <View style={styles.failureOverlay}>
          <BlurView intensity={20} style={StyleSheet.absoluteFill} />
          <View style={styles.failureCard}>
            <Text style={styles.failureTitle}>We couldn't sign you in</Text>
            {!!guestFailureMessage && (
              <Text style={styles.failureMessage}>{guestFailureMessage}</Text>
            )}
            <View style={styles.failureActions}>
              <TouchableOpacity
                style={[styles.failureButton, styles.retryButton, isLoading && styles.disabledButton]}
                onPress={handleRetryGuest}
                disabled={isLoading}
              >
                {isLoading ? (
                  <View style={styles.inlineLoading}>
                    <ActivityIndicator size="small" color="#fff" />
                    <Text style={styles.failureButtonText}>Retrying</Text>
                  </View>
                ) : (
                  <Text style={styles.failureButtonText}>Retry</Text>
                )}
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.failureButton, styles.homeButton, isLoading && styles.disabledButton]}
                onPress={handleGoHomeUnauthenticated}
                disabled={isLoading}
              >
                <Text style={styles.failureHomeText}>Go Home</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  closeButton: {
    position: 'absolute',
    top: 16 + (Platform.OS === 'ios' ? 44 : 0),
    right: 16,
    zIndex: 1,
    padding: 8,
  },
  stepContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  stepContent: {
    flex: 1,
    width: '100%',
    alignItems: 'center',
    maxWidth: 500,
  },
  iconContainer: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.lg,
  },
  title: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
  },
  descriptionScroll: {
    flex: 1,
    width: '100%',
  },
  descriptionContent: {
    paddingBottom: theme.spacing.xl,
  },
  introDescription: {
    marginVertical: theme.spacing.lg,
    fontSize: theme.typography.heading.medium.fontSize,
    fontWeight: '600',
    textAlign: 'center',
  },
  intro: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
    lineHeight: 24,
  },
  description: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
    lineHeight: 24,
  },
  practicesContainer: {
    width: '100%',
    paddingHorizontal: theme.spacing.md,
  },
  practicesTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  practiceItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
    gap: theme.spacing.sm,
  },
  practiceText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    flex: 1,
  },
  navigation: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    paddingTop: theme.spacing.lg,
  },
  navButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    padding: theme.spacing.sm,
  },
  navText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  dots: {
    flexDirection: 'row',
    gap: theme.spacing.xs,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: `${theme.colors.primary}30`,
  },
  activeDot: {
    backgroundColor: theme.colors.primary,
    width: 24,
  },
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1000,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingContent: {
    backgroundColor: theme.colors.surface,
    borderWidth: 0.3,
    borderColor: theme.colors.primary,
    padding: theme.spacing.xl,
    borderRadius: theme.borderRadius.lg,
    alignItems: 'center',
  },
  loadingText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  failureOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    zIndex: 1100,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.lg,
  },
  failureCard: {
    width: '100%',
    maxWidth: 420,
    borderWidth: 0.3,
    borderColor: theme.colors.primaryLight,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  failureTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  failureMessage: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  failureActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  failureButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  disabledButton: {
    opacity: 0.7,
  },
  retryButton: {
    backgroundColor: '#1E88E5',
  },
  homeButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#1E88E5',
  },
  failureButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  failureHomeText: {
    color: '#1E88E5',
    fontWeight: '600',
  },
  inlineLoading: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
});

export default IntroScreen;