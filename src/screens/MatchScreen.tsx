import React, { useState, useCallback, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Platform,
  Image,
  DimensionValue,
  BackHandler,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withSequence,
  withRepeat,
  withTiming,
  interpolate,
  cancelAnimation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import {
  ArrowLeft,
  Sparkle,
  ChevronRight,
  ChevronLeft,
  BookReader,
  BulbTwo,
  BulbDiverse,
  BulbGroup,
  ArrowRightPlay,
  Check,
  Clock,
  IconProps,
} from '../components/Icons';
import AvatarStack from '@/components/AvatarStack';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import { SCREEN_DIMENSIONS } from '@/constants';

const BUTTON_WIDTH = SCREEN_DIMENSIONS.width - 48;
const SLIDER_KNOB_SIZE = 64;

interface MatchModeOption {
  mode: 'unity' | 'diversity' | 'any';
  icon: React.FC<IconProps>;
  title: string;
  color: string;
}

interface CollapsedOption {
  icon: React.FC<IconProps>;
  label: string;
  value: string | number;
  color: string;
}

const MatchScreen: React.FC<NativeStackScreenProps<RootStackParamList, 'MatchScreen'>> = ({
  navigation
}) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // States
  const [selectedMode, setSelectedMode] = useState<string | null>(null);
  const [selectedTime, setSelectedTime] = useState<number | null>(null);
  const [matchStatus, setMatchStatus] = useState<'idle' | 'searching' | 'found' | 'not_found'>('idle');
  const [isMatchModeCollapsed, setIsMatchModeCollapsed] = useState(false);
  const [isWaitTimeCollapsed, setIsWaitTimeCollapsed] = useState(false);
  const [searchTimeElapsed, setSearchTimeElapsed] = useState(0);

  // Animated values
  const searchRotation = useSharedValue(0);
  const searchScale = useSharedValue(1);
  const sliderPosition = useSharedValue(BUTTON_WIDTH / 2 - SLIDER_KNOB_SIZE / 2);
  const matchModeHeight = useSharedValue<DimensionValue>('auto');
  const waitTimeHeight = useSharedValue<DimensionValue>('auto');
  const progressWidth = useSharedValue(0);

  // Timer effect for search progress
  useEffect(() => {
    if (matchStatus === 'searching' && selectedTime) {
      const interval = setInterval(() => {
        setSearchTimeElapsed(prev => {
          const next = prev + 1;
          if (next >= selectedTime * 60) {
            clearInterval(interval);
            setMatchStatus('not_found');
            return 0;
          }
          return next;
        });
      }, 1000);

      return () => clearInterval(interval);
    }
  }, [matchStatus, selectedTime]);

  // Progress animation
  useEffect(() => {
    if (matchStatus === 'searching' && selectedTime) {
      progressWidth.value = withTiming(1, {
        duration: selectedTime * 60 * 1000
      });
    } else {
      progressWidth.value = 0;
    }
  }, [matchStatus, selectedTime]);

  const progressStyle = useAnimatedStyle(() => ({
    width: `${progressWidth.value * 100}%`,
  }));

  // Search animation
  const searchAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      { rotate: `${searchRotation.value * 360}deg` },
      { scale: searchScale.value }
    ],
  }));
  const pulseScale = useSharedValue(1);
  const pulseOpacity = useSharedValue(1);
  const glowOpacity = useSharedValue(0);

  // Enhanced search animation with pulsing
  const startSearchAnimation = useCallback(() => {
    // Rotate animation
    searchRotation.value = withRepeat(
      withTiming(1, { duration: 3000 }),
      -1,
      false
    );

    // Main icon scale
    searchScale.value = withRepeat(
      withSequence(
        withTiming(1.1, { duration: 1500 }),
        withTiming(1, { duration: 1500 })
      ),
      -1,
      true
    );

    // Pulse animation
    pulseScale.value = withRepeat(
      withSequence(
        withTiming(1.8, { duration: 1000 }),
        withTiming(1, { duration: 1000 })
      ),
      -1,
      true
    );

    // Pulse opacity
    pulseOpacity.value = withRepeat(
      withSequence(
        withTiming(0.6, { duration: 1000 }),
        withTiming(0, { duration: 1000 })
      ),
      -1,
      true
    );

    // Glow effect
    glowOpacity.value = withRepeat(
      withSequence(
        withTiming(0.5, { duration: 1500 }),
        withTiming(0.2, { duration: 1500 })
      ),
      -1,
      true
    );
  }, []);


  const toggleMatchMode = useCallback(() => {
    if (matchStatus === 'searching') return;

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setIsMatchModeCollapsed(!isMatchModeCollapsed);
    matchModeHeight.value = withSpring(isMatchModeCollapsed ? 'auto' : 48, {
      damping: 15,
      stiffness: 150
    });
  }, [isMatchModeCollapsed, matchStatus]);

  const toggleWaitTime = useCallback(() => {
    if (matchStatus === 'searching') return;

    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setIsWaitTimeCollapsed(!isWaitTimeCollapsed);
    waitTimeHeight.value = withSpring(isWaitTimeCollapsed ? 'auto' : 48, {
      damping: 15,
      stiffness: 150
    });
  }, [isWaitTimeCollapsed, matchStatus]);

  // Add this for slider interaction - after other handlers
  const handleSliderMove = useCallback((event: { nativeEvent: { locationX: number } }) => {
    const { locationX } = event.nativeEvent;
    const newPosition = Math.max(0, Math.min(locationX - SLIDER_KNOB_SIZE / 2, BUTTON_WIDTH - SLIDER_KNOB_SIZE));

    sliderPosition.value = withSpring(newPosition, {
      damping: 15,
      stiffness: 150
    });

    // Determine if it's an accept or reject based on position
    if (newPosition > (BUTTON_WIDTH - SLIDER_KNOB_SIZE) * 0.75) {
      // Accept
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      // Handle accept logic
    } else if (newPosition < (BUTTON_WIDTH - SLIDER_KNOB_SIZE) * 0.25) {
      // Reject
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      // Handle reject logic
    }
  }, []);

  // Animation styles
  const pulseStyle = useAnimatedStyle(() => ({
    transform: [{ scale: pulseScale.value }],
    opacity: pulseOpacity.value,
  }));

  const glowStyle = useAnimatedStyle(() => ({
    opacity: glowOpacity.value,
  }));

  const searchContainerStyle = useAnimatedStyle(() => ({
    transform: [
      { rotate: `${searchRotation.value * 360}deg` },
      { scale: searchScale.value }
    ],
  }));

  const matchModeStyle = useAnimatedStyle(() => ({
    height: matchModeHeight.value,
    opacity: matchModeHeight.value === 'auto' ? 1 : 0.5,
  }));

  const waitTimeStyle = useAnimatedStyle(() => ({
    height: waitTimeHeight.value,
    opacity: waitTimeHeight.value === 'auto' ? 1 : 0.5,
  }));

  const sliderAnimatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ translateX: sliderPosition.value }],
    };
  });

  const searchAnimationRefs = useRef<{
    rotation?: number;
    scale?: number;
    pulse?: number;
    glow?: number;
  }>({});

  // Add new useEffect for handling back button
  useEffect(() => {
    const backHandler = BackHandler.addEventListener('hardwareBackPress', () => {
      if (matchStatus === 'searching') {
        handleStopSearch();
        return true;
      }
      return false;
    });

    return () => backHandler.remove();
  }, [matchStatus]);

  const handleStopSearch = useCallback(() => {
    // Cancel all animations
    if (searchAnimationRefs.current.rotation) {
      cancelAnimation(searchRotation);
    }
    if (searchAnimationRefs.current.scale) {
      cancelAnimation(searchScale);
    }
    if (searchAnimationRefs.current.pulse) {
      cancelAnimation(pulseScale);
    }
    if (searchAnimationRefs.current.glow) {
      cancelAnimation(glowOpacity);
    }

    // Reset animation values
    searchRotation.value = 0;
    searchScale.value = 1;
    pulseScale.value = 1;
    pulseOpacity.value = 0;
    glowOpacity.value = 0;

    // Reset match status
    setMatchStatus('idle');
    setSearchTimeElapsed(0);

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }, []);

  const handleModeSelect = useCallback((mode: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setSelectedMode(mode);
    setIsMatchModeCollapsed(true);
  }, []);

  const handleTimeSelect = useCallback((time: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setSelectedTime(time);
    setIsWaitTimeCollapsed(true);
  }, []);

  // Update startSearching function
  const startSearching = useCallback(() => {
    setMatchStatus('searching');
    setSearchTimeElapsed(0);
    startSearchAnimation();

    // Simulate finding a match
    const matchTimeout = setTimeout(() => {
      if (matchStatus === 'searching') {
        handleStopSearch();
        setMatchStatus('found');
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    }, Math.random() * 3000 + 2000);

    // Store timeout reference
    return () => clearTimeout(matchTimeout);
  }, [matchStatus]);

  // Update navigation header
  const renderHeader = () => (
    <View style={styles.header}>
      <TouchableOpacity 
        onPress={() => {
          if (matchStatus === 'searching') {
            handleStopSearch();
          } else {
            navigation.goBack();
          }
        }}
      >
        <ArrowLeft size={24} color={theme.colors.text.primary} />
      </TouchableOpacity>
      <Text style={styles.title}>One-on-One</Text>
      <View style={{ width: 24 }} />
    </View>
  );

  // Updated search status component
  const SearchStatus = () => (
    <View style={styles.searchStatus}>
      <SearchProgress />
      <View style={styles.searchingContainer}>
        <View style={styles.searchIconWrapper}>
          {/* Background Glow */}
          <Animated.View style={[styles.glow, glowStyle]}>
            <LinearGradient
              colors={[
                `${theme.colors.primary}00`,
                `${theme.colors.primary}40`,
                `${theme.colors.primary}00`
              ]}
              style={styles.glowGradient}
            />
          </Animated.View>

          {/* Pulse Circles */}
          <Animated.View style={[styles.pulseCircle, pulseStyle]} />
          <Animated.View
            style={[
              styles.pulseCircle,
              pulseStyle,
              { transform: [{ scale: interpolate(pulseScale.value, [1, 1.8], [1, 1.4]) }] }
            ]}
          />

          {/* Main Search Icon */}
          <Animated.View style={[styles.searchIcon, searchContainerStyle]}>
            <Sparkle size={48} color={theme.colors.primary} />
          </Animated.View>
        </View>
        <Text style={styles.searchingText}>Finding your match...</Text>
      </View>
    </View>
  );

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Render helpers
  const CollapsedSelection = ({
    title,
    option,
    onPress
  }: {
    title: string;
    option: CollapsedOption;
    onPress: () => void;
  }) => (
    <TouchableOpacity
      style={styles.collapsedContainer}
      onPress={onPress}
    >
      <BlurView intensity={10} style={StyleSheet.absoluteFill} />
      <View style={styles.collapsedContent}>
        <View style={styles.collapsedLeft}>
          <Text style={styles.collapsedTitle}>{title}</Text>
          <View style={styles.collapsedOption}>
            <option.icon size={16} color={option.color} />
            <Text style={[styles.collapsedValue, { color: option.color }]}>
              {option.label}
            </Text>
          </View>
        </View>
        <View style={[styles.checkmark, { backgroundColor: `${option.color}15` }]}>
          <Check size={16} color={option.color} />
        </View>
      </View>
    </TouchableOpacity>
  );

  const SearchProgress = () => (
    <View style={styles.searchProgress}>
      <View style={styles.progressTop}>
        <Text style={styles.progressText}>
          {formatTime(searchTimeElapsed)}
        </Text>
        <Text style={styles.progressText}>
          {formatTime(selectedTime! * 60)}
        </Text>
      </View>
      <View style={styles.progressTrack}>
        <Animated.View
          style={[
            styles.progressBar,
            progressStyle,
            { backgroundColor: theme.colors.primary }
          ]}
        />
      </View>
    </View>
  );

  const matchModes: MatchModeOption[] = [
    {
      mode: 'unity',
      icon: BulbTwo,
      title: 'Unity Match',
      color: theme.colors.primary,
    },
    {
      mode: 'diversity',
      icon: BulbDiverse,
      title: 'Diversity Match',
      color: theme.colors.primaryDark,
    },
    {
      mode: 'any',
      icon: BulbGroup,
      title: 'Any Match',
      color: theme.colors.secondary,
    },
  ];

  const waitTimes = [5, 15, 30, 60];
  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>One-on-One</Text>
        <View style={{ width: 24 }} />
      </View>

      <View style={styles.content}>
        {/* Intro Card - Only show when not searching */}
        {matchStatus === 'idle' && (
          <BlurView intensity={10} style={styles.introCard}>
            <View style={styles.iconContainer}>
              <LinearGradient
                colors={[`${theme.colors.primary}20`, `${theme.colors.primary}05`]}
                style={styles.iconGradient}
              >
                <BookReader size={32} color={theme.colors.primary} />
              </LinearGradient>
            </View>
            <Text style={styles.introTitle}>Connect and Share</Text>
            <Text style={styles.introDescription}>
              Share a meaningful 15-minute conversation based on common or diverging views. Choose your
              preference below.
            </Text>
          </BlurView>
        )}

        {/* Match Mode Section */}
        {matchStatus === 'idle' && (
          <>
            {selectedMode && isMatchModeCollapsed ? (
              <CollapsedSelection
                title="Match Mode"
                option={{
                  icon: matchModes.find(m => m.mode === selectedMode)?.icon!,
                  label: matchModes.find(m => m.mode === selectedMode)?.title!,
                  value: selectedMode,
                  color: matchModes.find(m => m.mode === selectedMode)?.color!
                }}
                onPress={toggleMatchMode}
              />
            ) : (
              <Animated.View style={matchModeStyle}>
                <View style={styles.modeTitleContainer}>
                  <ArrowRightPlay size={24} color={theme.colors.primary} />
                  <Text style={[styles.modeTitle, { color: theme.colors.primary }]}>
                    Match Mode
                  </Text>
                </View>
                <View style={styles.matchModes}>
                  {matchModes.map((option) => (
                    <TouchableOpacity
                      key={option.mode}
                      style={[
                        styles.modeButton,
                        selectedMode === option.mode && {
                          backgroundColor: `${option.color}15`,
                          borderColor: option.color,
                        }
                      ]}
                      onPress={() => handleModeSelect(option.mode)}
                    >
                      <option.icon
                        size={24}
                        color={selectedMode === option.mode ? option.color : theme.colors.text.secondary}
                      />
                      <Text style={[
                        styles.modeText,
                        selectedMode === option.mode && { color: option.color }
                      ]}>
                        {option.title}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </Animated.View>
            )}
          </>
        )}

        {/* Wait Time Section */}
        {matchStatus === 'idle' && selectedMode && (
          <>
            {selectedTime && isWaitTimeCollapsed ? (
              <CollapsedSelection
                title="Wait Time"
                option={{
                  icon: Clock,
                  label: `${selectedTime} minutes`,
                  value: selectedTime,
                  color: theme.colors.primary
                }}
                onPress={toggleWaitTime}
              />
            ) : (
              <Animated.View style={waitTimeStyle}>
                <Text style={styles.sectionTitle}>Wait Time</Text>
                <View style={styles.timeGrid}>
                  {waitTimes.map((time) => (
                    <TouchableOpacity
                      key={time}
                      style={[
                        styles.timeButton,
                        selectedTime === time && styles.selectedTimeButton
                      ]}
                      onPress={() => handleTimeSelect(time)}
                    >
                      <Text style={[
                        styles.timeText,
                        selectedTime === time && styles.selectedTimeText
                      ]}>
                        {time}min
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </Animated.View>
            )}
          </>
        )}

        {/* Search Status and Progress */}
        {matchStatus === 'searching' && (
          <View style={styles.searchStatus}>
            <SearchProgress />
            <View style={styles.searchingContainer}>
              <View style={styles.searchIconWrapper}>
                {/* Background Glow */}
                <Animated.View style={[styles.glow, glowStyle]}>
                  <LinearGradient
                    colors={[
                      `${theme.colors.primary}00`,
                      `${theme.colors.primary}40`,
                      `${theme.colors.primary}00`
                    ]}
                    style={styles.glowGradient}
                  />
                </Animated.View>

                {/* Pulse Circles */}
                <Animated.View style={[styles.pulseCircle, pulseStyle]} />
                <Animated.View
                  style={[
                    styles.pulseCircle,
                    pulseStyle,
                    { transform: [{ scale: interpolate(pulseScale.value, [1, 1.8], [1, 1.4]) }] }
                  ]}
                />

                {/* Main Search Icon */}
                <Animated.View style={[styles.searchIcon, searchContainerStyle]}>
                  <Sparkle size={48} color={theme.colors.primary} />
                </Animated.View>
              </View>
              <Text style={styles.searchingText}>Finding your match...</Text>
            </View>
          </View>
        )}

        {/* Match Found */}
        {matchStatus === 'found' && (
          <View style={styles.matchFoundContainer}>
            <BlurView intensity={10} style={StyleSheet.absoluteFill} />

            {/* Profile Preview */}
            <View style={styles.profilePreview}>
              <Image
                src="/api/placeholder/80/80"
                style={styles.profileImage}
              />
              <View style={styles.profileInfo}>
                <Text style={styles.profileName}>Sarah Mitchell</Text>
                <Text style={styles.profileBio}>Passionate about scripture study</Text>
                <AvatarStack
                  users={[]}
                  maxAvatars={3}
                  size={24}
                />
              </View>
            </View>

            {/* Accept/Reject Slider */}
            <View style={styles.sliderContainer}>
              <LinearGradient
                colors={[theme.colors.error, 'transparent', theme.colors.success]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                style={styles.sliderTrack}
              />
              <Animated.View
                style={[styles.sliderKnob, sliderAnimatedStyle]}
                onTouchMove={handleSliderMove}
              >
                <BlurView intensity={20} style={StyleSheet.absoluteFill} />
                <View style={styles.knobContent}>
                  <ChevronLeft size={20} color={theme.colors.text.primary} />
                  <ChevronRight size={20} color={theme.colors.text.primary} />
                </View>
              </Animated.View>
            </View>

            <Text style={styles.sliderHint}>
              Slide to accept or decline
            </Text>
          </View>
        )}

        {/* Start Button - Only show when mode and time selected & not searching */}
        {selectedMode && selectedTime && matchStatus === 'idle' && (
          <TouchableOpacity
            style={styles.startButton}
            onPress={startSearching}
          >
            <Text style={styles.startButtonText}>Find Match</Text>
          </TouchableOpacity>
        )}

        {/* Not Found Message */}
        {matchStatus === 'not_found' && (
          <View style={styles.notFoundContainer}>
            <BlurView intensity={10} style={StyleSheet.absoluteFill} />
            <Text style={styles.notFoundTitle}>No Match Found</Text>
            <Text style={styles.notFoundText}>
              We couldn't find a match within your waiting time.
              Would you like to try again?
            </Text>
            <View style={styles.retryActions}>
            <TouchableOpacity
              style={styles.retryButton}
              onPress={() => {
                startSearching()
              }}
            >
              <Text style={styles.retryText}>Try Again</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.cancelButton}
              onPress={() => {
                setMatchStatus('idle');
                setIsWaitTimeCollapsed(false);
              }}
            >
              <Text style={styles.cancelText}>Cancel</Text>
            </TouchableOpacity>
            </View>
          </View>
        )}
        
        {matchStatus === 'searching' && (
        <TouchableOpacity
          style={styles.stopSearchButton}
          onPress={handleStopSearch}
        >
          <Text style={styles.stopSearchText}>Stop Search</Text>
        </TouchableOpacity>
      )}
      </View>
    </View>
  );
}

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  content: {
    flex: 1,
    padding: theme.spacing.md,
  },
  introCard: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    marginBottom: theme.spacing.xl,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    overflow: 'hidden',
  },
  iconContainer: {
    marginBottom: theme.spacing.md,
  },
  iconGradient: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  introTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  introDescription: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
  },
  modeTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
    gap: theme.spacing.xs,
  },
  modeTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.primary,
  },
  matchModes: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.lg,
  },
  modeButton: {
    flex: 1,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.xs,
  },
  modeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  timeSelection: {
    marginBottom: theme.spacing.lg,
  },
  sectionTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  timeGrid: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  timeButton: {
    flex: 1,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  selectedTimeButton: {
    backgroundColor: `${theme.colors.primary}15`,
    borderColor: theme.colors.primary,
  },
  timeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  selectedTimeText: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  searchStatus: {
    marginBottom: theme.spacing.xl,
  },
  searchProgress: {
    padding: theme.spacing.md,
  },
  progressTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.xs,
  },
  progressText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  progressTrack: {
    height: 3,
    backgroundColor: `${theme.colors.primary}15`,
    borderRadius: 1.5,
    overflow: 'hidden',
  },
  progressBar: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
    borderRadius: 1.5,
  },
  searchIconWrapper: {
    width: 120,
    height: 120,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  searchIcon: {
    width: 64,
    height: 64,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 32,
    backgroundColor: `${theme.colors.primary}15`,
  },
  pulseCircle: {
    position: 'absolute',
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: `${theme.colors.primary}20`,
  },
  glow: {
    position: 'absolute',
    width: 120,
    height: 120,
    borderRadius: 60,
    overflow: 'hidden',
  },
  glowGradient: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  searchingContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.xl,
  },
  searchingText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.md,
  },
  collapsedContainer: {
    marginBottom: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
  },
  collapsedContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme.spacing.md,
  },
  collapsedLeft: {
    flex: 1,
  },
  collapsedTitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
  },
  collapsedOption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  collapsedValue: {
    ...theme.typography.caption.primary,
    fontWeight: '600',
  },
  checkmark: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  matchFoundContainer: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.xl,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    overflow: 'hidden',
  },
  profilePreview: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  profileImage: {
    width: 80,
    height: 80,
    borderRadius: 40,
    marginRight: theme.spacing.md,
    borderWidth: 2,
    borderColor: theme.colors.background,
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
  profileInfo: {
    flex: 1,
  },
  profileName: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  profileBio: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  sliderContainer: {
    height: SLIDER_KNOB_SIZE,
    marginVertical: theme.spacing.md,
    position: 'relative',
  },
  sliderTrack: {
    height: 3,
    borderRadius: 1.5,
    position: 'absolute',
    left: 0,
    right: 0,
    top: '50%',
    marginTop: -1.5,
  },
  sliderKnob: {
    width: SLIDER_KNOB_SIZE,
    height: SLIDER_KNOB_SIZE,
    borderRadius: SLIDER_KNOB_SIZE / 2,
    position: 'absolute',
    top: 0,
    borderWidth: 1,
    borderColor: theme.colors.border,
    overflow: 'hidden',
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
  knobContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
  },
  sliderHint: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.sm,
  },
  startButton: {
    backgroundColor: theme.colors.primary,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
    marginTop: 'auto',
    marginBottom: theme.spacing.xl,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  startButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  notFoundContainer: {
    padding: theme.spacing.xl,
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  notFoundTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  notFoundText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.lg,
  },
  retryActions: {
    flexDirection: "row",
    alignSelf: "center",
    alignContent: "center",
    gap: theme.spacing.lg,
    alignItems: "center"
  },
  retryButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    backgroundColor: `${theme.colors.primary}`,
    borderRadius: theme.borderRadius.full,
  },
  cancelButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    backgroundColor: `${theme.colors.secondary}15`,
    borderRadius: theme.borderRadius.full,
  },
  retryText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  cancelText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  stopSearchButton: {
    position: 'absolute',
    bottom: theme.spacing.xl,
    left: theme.spacing.md,
    right: theme.spacing.md,
    backgroundColor: theme.colors.error,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
  },
  stopSearchText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
});

export default MatchScreen;