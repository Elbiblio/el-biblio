import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Platform,
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
import { useAuth } from '@/stores/auth';

const SCREEN_WIDTH = SCREEN_DIMENSIONS.width;

type IntroScreenProps = NativeStackScreenProps<RootStackParamList, 'IntroScreen'>;

const IntroScreen: React.FC<IntroScreenProps> = ({
  navigation,
  route,
}) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  const [currentStep, setCurrentStep] = useState(0);
  const [showGuestChoice, setShowGuestChoice] = useState(false);
  const scrollRef = useRef<ScrollView>(null);
  const scrollX = useSharedValue(0);

  const { completeWelcome, hasCompletedWelcome } = useWelcomeState();
  const { createGuestAccount } = useAuth();

  const onClose = async () => {
    if (!hasCompletedWelcome) {
      await completeWelcome();
    } else if (navigation.canGoBack()) {
      navigation.goBack();
    } else {
      navigation.replace('Home');
    }
  };

  const handleNext = () => {
    if (currentStep === (STEPS.length - 1)) {
        setShowGuestChoice(true);
        return;
    }
    
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const nextStep = currentStep + 1;
    setCurrentStep(nextStep);
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
    setShowGuestChoice(false);
    navigation.navigate('RegistrationScreen');
  };

  const handleContinueAsGuest = async () => {
    setShowGuestChoice(false);
    try {
      const success = await createGuestAccount();
      if (success) {
        onClose();
      }
    } catch (error) {
      console.error('Failed to create guest account:', error);
    }
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
            <Text style={styles.description}>{step.description}</Text>
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
      {/* Close Button */}
      <TouchableOpacity 
        style={styles.closeButton}
        onPress={onClose}
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
});

export default IntroScreen;