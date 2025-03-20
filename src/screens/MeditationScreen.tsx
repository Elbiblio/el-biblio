import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Animated,
  Platform,
  BackHandler,
  DimensionValue,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import { CHALLENGE_TEMPLATES, RootStackParamList, TIME_OPTIONS, VIRTUES } from '@/types';
import {
  ArrowLeft,
  Heart,
  Shield,
  Leaf,
  Scales,
  Flame,
  Lightning,
  Clock,
  Bell,
  Check,
  Timer as TimerIcon,
} from '@/components/Icons';
import { Theme } from '@/theme';
import { useAuth } from '@/stores/auth';
import * as Haptics from 'expo-haptics';
import { Audio } from 'expo-av';
import { DailyChallenge } from '@/types';
import Svg, { Path, Circle } from 'react-native-svg';
import AnimatedCircularProgress from '@/components/AnimatedCircularProgress';
import AnimatedParticles from '@/components/AnimatedParticles';
import { useSharedValue, useAnimatedProps, withTiming, withSequence, withRepeat, withDelay, Easing } from 'react-native-reanimated';
import { ReanimatedPath, ReanimatedCircle } from '@/components/ReanimatedSvg';
import { useAnimatedStyle, interpolate } from 'react-native-reanimated';

enum MeditationState {
  SETUP = 'setup',
  COUNTDOWN = 'countdown',
  ACTIVE = 'active',
  COMPLETE = 'complete',
}

const MeditationScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const { user, updateUserPoints } = useAuth();

  const [selectedVirtue, setSelectedVirtue] = useState<string | null>(null);
  const currentVirtue = VIRTUES.find(v => v.id === selectedVirtue);


  const styles = React.useMemo(() => createStyles(theme, currentVirtue), [theme, currentVirtue]);

  // State management
  const [selectedTime, setSelectedTime] = useState<number | null>(null);
  const [selectedChallenge, setSelectedChallenge] = useState<DailyChallenge | null>(null);
  const [meditationState, setMeditationState] = useState<MeditationState>(MeditationState.SETUP);
  const [countdown, setCountdown] = useState(10);
  const [meditationTimer, setMeditationTimer] = useState(0);
  const [currentPromptIndex, setCurrentPromptIndex] = useState(0);
  const [showPrompt, setShowPrompt] = useState(false);

  // Animation values
  const breatheAnim = useSharedValue(0);
  const bellAnim = useSharedValue(0);
  const fadeAnim = useSharedValue(1);
  const promptOpacity = useSharedValue(0);

  // Audio/vibration feedback refs
  const isSpeaking = useRef(false);

  // Add sound effect references
  const [tickSound, setTickSound] = useState<Audio.Sound | null>(null);
  const [backgroundSound, setBackgroundSound] = useState<Audio.Sound | null>(null);
  const [selectedBackgroundSound, setSelectedBackgroundSound] = useState<string | null>(null);
  const [breathePhase, setBreathePhase] = useState<'in' | 'hold' | 'out'>('in');
  const breatheTextOpacity = useSharedValue(1);
  const numberScale = useSharedValue(1);
  const numberOpacity = useSharedValue(1);

  // Get current prompt
  const currentPrompt = currentVirtue?.prompts[currentPromptIndex];

  // Calculate meditation parameters
  const totalMeditationSeconds = (selectedTime || 0) * 60;
  const promptInterval = totalMeditationSeconds > 0 ? Math.floor(totalMeditationSeconds / 4) : 0;

  const AnimatedPath = Animated.createAnimatedComponent(Path);
  const AnimatedCircle = Animated.createAnimatedComponent(Circle);

  const AnimatedCheckmark = () => {
    const checkProgress = useSharedValue(0);
    const circleProgress = useSharedValue(0);
    const pulseScale = useSharedValue(1);

    useEffect(() => {
      // Checkmark drawing animation
      checkProgress.value = 0;
      circleProgress.value = 0;
      
      // Sequence the animations
      setTimeout(() => {
        circleProgress.value = withTiming(1, { duration: 800, easing: Easing.out(Easing.quad) });
        
        setTimeout(() => {
          checkProgress.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.quad) });
        }, 800);
      }, 0);

      // Loop pulse animation
      const loop = () => {
        pulseScale.value = withTiming(1.2, { duration: 1000, easing: Easing.inOut(Easing.ease) });
        
        setTimeout(() => {
          pulseScale.value = withTiming(1, { duration: 1000, easing: Easing.inOut(Easing.ease) });
          
          setTimeout(loop, 0);
        }, 1000);
      };
      
      loop();

      return () => {
        // Cleanup if needed
      };
    }, []);

    const checkPath = `
      M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z
    `;

    const circleAnimatedProps = useAnimatedProps(() => {
      return {
        strokeOpacity: 0.1 * circleProgress.value,
        transform: [{
          scale: 0.8 + 0.2 * circleProgress.value,
        }],
      };
    });

    const pulseAnimatedProps = useAnimatedProps(() => {
      return {
        strokeOpacity: 0.3 * (1 - ((pulseScale.value - 1) / 0.2)),
        transform: [{ scale: pulseScale.value }],
      };
    });

    const pathAnimatedProps = useAnimatedProps(() => {
      return {
        strokeDashoffset: 100 - (checkProgress.value * 100),
      };
    });

    return (
      <Svg width={150} height={150} viewBox="0 0 24 24">
        {/* Background circle */}
        <ReanimatedCircle
          cx="12"
          cy="12"
          r="10"
          fill="none"
          stroke={currentVirtue?.color || theme.colors.primary}
          strokeWidth="2"
          animatedProps={circleAnimatedProps}
        />

        {/* Outer pulse circle */}
        <ReanimatedCircle
          cx="12"
          cy="12"
          r="10"
          fill="none"
          stroke={currentVirtue?.color || theme.colors.primary}
          strokeWidth="2"
          animatedProps={pulseAnimatedProps}
        />

        {/* Animated checkmark */}
        <ReanimatedPath
          d={checkPath}
          fill="none"
          stroke={currentVirtue?.color || theme.colors.primary}
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeDasharray="100"
          animatedProps={pathAnimatedProps}
        />
      </Svg>
    );
  };

  const renderCompleteScreen = () => (
    <View style={styles.completeContainer}>
      <View style={styles.completeBanner}>
        <AnimatedCheckmark />
        <Text style={styles.completeTitle}>Meditation Complete</Text>
        <Text style={styles.completeSubtitle}>
          Take a moment to reflect on your experience
        </Text>
      </View>

      <View style={styles.bellContainer}>
        <TouchableOpacity
          style={styles.bellButton}
          onPress={createChallenge}
        >
          <LinearGradient
            colors={[
              `${currentVirtue?.color}15`,
              `${currentVirtue?.color}05`
            ]}
            style={styles.bellIconContainer}
          >
            <Bell size={40} color={currentVirtue?.color || theme.colors.primary} />
          </LinearGradient>
          <Text style={styles.bellText}>Activate Daily Challenge</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.challengeSummaryContainer}>
        <Text style={styles.challengeSummaryTitle}>Your Selected Challenge:</Text>
        <View style={styles.challengeSummaryCard}>
          <LinearGradient
            colors={[
              `${currentVirtue?.color}15`,
              `${currentVirtue?.color}05`
            ]}
            style={StyleSheet.absoluteFill}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          />
          <Text style={styles.challengeSummaryText}>{selectedChallenge?.title}</Text>
          <Text style={styles.challengeDuration}>
            For the next {selectedTime} {selectedTime === 1 ? 'hour' : 'hours'}
          </Text>
        </View>
      </View>
    </View>
  );


  // Load sound effects
  useEffect(() => {
    async function loadSounds() {
      try {
        const { sound: tick } = await Audio.Sound.createAsync(
          require('../../assets/sounds/tick-tock.wav')
        );
        setTickSound(tick);
      } catch (error) {
        console.error("Failed to load sounds", error);
      }
    }

    loadSounds();

    return () => {
      if (tickSound) {
        tickSound.unloadAsync();
      }
      if (backgroundSound) {
        backgroundSound.unloadAsync();
      }
    };
  }, []);

  // Load and play background sound when selected
  useEffect(() => {
    const loadBackgroundSound = async () => {
      // Unload any previous background sound
      if (backgroundSound) {
        await backgroundSound.unloadAsync();
      }

      if (!selectedBackgroundSound) return;

      try {
        const soundAsset = selectedBackgroundSound === 'ambient' 
          ? require('../../assets/sounds/meditation-ambient.mp3')
          : require('../../assets/sounds/heartbeat.mp3');
          
        const { sound } = await Audio.Sound.createAsync(
          soundAsset,
          { isLooping: true, volume: 0.4 } // Lower volume to not overpower voice
        );
        
        setBackgroundSound(sound);
        
        // Only play if in active meditation
        if (meditationState === MeditationState.ACTIVE) {
          await sound.playAsync();
        }
      } catch (error) {
        console.error("Failed to load background sound", error);
      }
    };

    loadBackgroundSound();
  }, [selectedBackgroundSound]);

  // Start/stop background sound based on meditation state
  useEffect(() => {
    const handleBackgroundSound = async () => {
      if (!backgroundSound) return;

      if (meditationState === MeditationState.ACTIVE) {
        await backgroundSound.playAsync();
      } else if (meditationState === MeditationState.COMPLETE) {
        await backgroundSound.stopAsync();
      }
    };

    handleBackgroundSound();
  }, [meditationState, backgroundSound]);

  // Play tick sound during countdown
  const playTickSound = async () => {
    try {
      if (tickSound) {
        await tickSound.setPositionAsync(0);
        await tickSound.playAsync();
      }
    } catch (error) {
      console.error("Failed to play tick sound", error);
    }
  };

  // Animate countdown numbers
  const animateCountdownNumber = () => {
    numberScale.value = 1;
    numberOpacity.value = 1;
    
    // Sequence: grow then shrink
    numberScale.value = withSequence(
      withTiming(1.2, { duration: 300, easing: Easing.out(Easing.quad) }),
      withTiming(0.8, { duration: 700, easing: Easing.inOut(Easing.quad) })
    );
    
    // Fade in then slightly fade out
    numberOpacity.value = withSequence(
      withTiming(1, { duration: 100, easing: Easing.out(Easing.quad) }),
      withTiming(0.5, { duration: 700, easing: Easing.inOut(Easing.quad) })
    );
  };

  // Handle breathing animation with text cues
  useEffect(() => {
    if (meditationState === MeditationState.ACTIVE) {
      const breathingCycle = () => {
        // Breathe in phase - 4 seconds
        setBreathePhase('in');
        animateBreathText();

        setTimeout(() => {
          // Hold phase - 4 seconds
          setBreathePhase('hold');
          animateBreathText();

          setTimeout(() => {
            // Breathe out phase - 4 seconds
            setBreathePhase('out');
            animateBreathText();
          }, 4000);
        }, 4000);
      };

      // Start breathing cycle
      breathingCycle();
      // Repeat cycle every 12 seconds (4s in + 4s hold + 4s out)
      const interval = setInterval(breathingCycle, 12000);

      return () => clearInterval(interval);
    }
  }, [meditationState]);

  // Animate breath text opacity
  const animateBreathText = () => {
    // Fade out current text
    breatheTextOpacity.value = withTiming(0, { duration: 200 });
    
    // Then fade in new text
    setTimeout(() => {
      breatheTextOpacity.value = withTiming(1, { duration: 400 });
    }, 200);
  };

  // Synchronize speech with countdown numbers
  const speakCountdownNumber = (number: number) => {
    // Clear any previous speech to ensure synchronization
    Speech.stop();
    
    if (number <= 3 && number > 0) {
      // Small delay to synchronize with visual
      setTimeout(() => {
        Speech.speak(`${number}`, { rate: 0.8 });
      }, 100);
    } else if (number === 0) {
      setTimeout(() => {
        Speech.speak("Close your eyes, if you are able to do so. Visualize yourself calm, peaceful, empty and ready to grow spiritually.", { rate: 0.8 });
      }, 100);
    }
  };

  // Handle countdown timer logic with animation and sound
  useEffect(() => {
    let interval: number;

    if (meditationState === MeditationState.COUNTDOWN && countdown > 0) {
      // Play initial tick
      playTickSound();
      animateCountdownNumber();
      // Speak the initial number if <= 3
      speakCountdownNumber(countdown);

      interval = setInterval(() => {
        setCountdown(prev => {
          const newValue = prev - 1;

          // Play tick sound and animate for each countdown number
          if (newValue >= 0) {
            playTickSound();
            animateCountdownNumber();
            speakCountdownNumber(newValue);
          }

          if (newValue === 0) {
            // Start meditation session
            setMeditationState(MeditationState.ACTIVE);
          }

          return newValue;
        });
      }, 1000);
    }

    return () => clearInterval(interval);
  }, [meditationState, countdown]);

  // Handle meditation timer and prompts
  useEffect(() => {
    let interval: number;

    if (meditationState === MeditationState.ACTIVE && selectedTime) {
      // Start session with first prompt
      showAndSpeakPrompt(0);

      interval = setInterval(() => {
        setMeditationTimer(prev => {
          const newValue = prev + 1;

          // Show a new prompt at calculated intervals
          if (newValue % promptInterval === 0 && newValue < totalMeditationSeconds) {
            const nextPromptIndex = Math.floor(newValue / promptInterval);
            if (nextPromptIndex < 4) {
              showAndSpeakPrompt(nextPromptIndex);
            }
          }

          // End meditation when time is up
          if (newValue >= totalMeditationSeconds) {
            endMeditation();
            clearInterval(interval);
          }

          return newValue;
        });
      }, 1000);
    }

    return () => clearInterval(interval);
  }, [meditationState, selectedTime]);

  const showAndSpeakPrompt = (index: number) => {
    setCurrentPromptIndex(index);
    setShowPrompt(false);

    // Fade out any current prompt
    promptOpacity.value = withTiming(0, { duration: 500 });
    
    // Then fade in the new prompt
    setTimeout(() => {
      setShowPrompt(true);
      promptOpacity.value = withTiming(1, { duration: 1000 });

      // Speak the prompt
      if (currentVirtue?.prompts[index]) {
        isSpeaking.current = true;
        Speech.speak(currentVirtue.prompts[index], {
          rate: 0.85,
          onDone: () => {
            isSpeaking.current = false;
          }
        });
      }
    }, 500);
  };

  const startMeditation = () => {
    if (!selectedVirtue || !selectedTime || !selectedChallenge) {
      // Animate to highlight missing selections
      fadeAnim.value = withSequence(
        withTiming(0.3, { duration: 200 }),
        withTiming(1, { duration: 200 })
      );

      // Provide haptic feedback for error
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    // Begin countdown
    setMeditationState(MeditationState.COUNTDOWN);
    // Provide haptic feedback for success
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const endMeditation = () => {
    setMeditationState(MeditationState.COMPLETE);

    // Stop any ongoing speech
    if (isSpeaking.current) {
      Speech.stop();
      isSpeaking.current = false;
    }

    // Trigger bell animation with Reanimated
    bellAnim.value = withTiming(1, { duration: 1000 });

    // Play bell sound (if we had a sound library)
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const pulseAnim = useSharedValue(0);
  const progressAnim = useSharedValue(0);

  useEffect(() => {
    // Start continuous loop for the breathing animation
    const startPulseAnimation = () => {
      pulseAnim.value = 0;
      pulseAnim.value = withRepeat(
        withSequence(
          withTiming(1, { duration: 4000, easing: Easing.inOut(Easing.ease) }),
          withTiming(0, { duration: 8000, easing: Easing.inOut(Easing.ease) })
        ),
        -1, // infinite repeat
        false // don't reverse
      );
    };
    
    startPulseAnimation();
  }, []);

  const handlePauseOrStop = () => {
    // This would handle pausing or stopping meditation
    // For simplicity, we're just ending the session
    navigation.goBack();
  };

  // Calculate end time for the challenge when creating it
  const calculateEndTime = (): Date => {
    const endTime = new Date();
    if (selectedTime) {
      // If time is in minutes, convert to hours for the challenge duration
      endTime.setHours(endTime.getHours() + (selectedTime === 40 ? 24 : selectedTime === 15 ? 6 : 3));
    }
    return endTime;
  };

  // Updated with DailyChallenge type
  const createChallenge = async () => {
    // Create challenge with calculated end time
    if (!selectedChallenge) return;

    // Award points based on time spent
    const pointsEarned = selectedTime === 7 ? 15 : selectedTime === 15 ? 25 : 50;

    // Update the end_time for the selected challenge
    const challenge = {
      ...selectedChallenge,
      end_time: calculateEndTime()
    };

    if (user) {
      try {
        await updateUserPoints(user.points || 0 + pointsEarned);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } catch (error) {
        console.error("Failed to update points", error);
      }
    }

    // Navigate back to home with success message
    navigation.navigate('Home', {
      meditationComplete: true,
      challenge: challenge,
      pointsEarned
    });
  };

  // Create animated styles for components that use the animated values
  const countdownNumberStyle = useAnimatedStyle(() => {
    return {
      transform: [{ scale: numberScale.value }],
      opacity: numberOpacity.value
    };
  });

  // Create animated style for fade animations
  const fadeAnimStyle = useAnimatedStyle(() => {
    return {
      opacity: fadeAnim.value
    };
  });

  // Create animated style for prompts
  const promptAnimStyle = useAnimatedStyle(() => {
    return {
      opacity: promptOpacity.value,
      transform: [{
        translateY: interpolate(
          promptOpacity.value,
          [0, 1],
          [20, 0]
        )
      }]
    };
  });

  // Create animated style for breathing text
  const breatheTextStyle = useAnimatedStyle(() => {
    return {
      opacity: breatheTextOpacity.value
    };
  });

  // Create animated style for breathing circle
  const breathingCircleStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { scale: interpolate(pulseAnim.value, [0, 1], [1, 1.3]) }
      ],
      opacity: interpolate(pulseAnim.value, [0, 1], [0.3, 0.6])
    };
  });

  // Render different screen states
  const renderSetupScreen = () => (
    <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
      <Animated.View style={[styles.setupContainer, fadeAnimStyle]}>
        <Text style={styles.sectionTitle}>CHOOSE A VIRTUE</Text>
        
        {selectedVirtue ? (
          // Collapsed view when virtue is selected
          <View style={styles.selectedVirtueCollapsed}>
            <View style={styles.selectedVirtueContent}>
              {currentVirtue && (
                <>
                  <View style={[
                    styles.virtueIconContainer,
                    { backgroundColor: `${currentVirtue.color}15` }
                  ]}>
                    <currentVirtue.icon size={24} color={currentVirtue.color} />
                  </View>
                  <Text style={[styles.virtueText, { color: currentVirtue.color }]}>
                    {currentVirtue.name}
                  </Text>
                </>
              )}
            </View>
            <TouchableOpacity 
              style={styles.changeVirtueButton}
              onPress={() => {
                setSelectedVirtue(null);
                Haptics.selectionAsync();
              }}
            >
              <Text style={styles.changeVirtueText}>Change</Text>
            </TouchableOpacity>
          </View>
        ) : (
          // Expanded virtues container when no virtue is selected
          <View style={styles.virtuesContainer}>
            {VIRTUES.map(virtue => (
              <TouchableOpacity
                key={virtue.id}
                style={[
                  styles.virtueButton,
                  selectedVirtue === virtue.id && styles.selectedVirtueButton,
                  selectedVirtue === virtue.id && { borderColor: virtue.color }
                ]}
                onPress={() => {
                  setSelectedVirtue(virtue.id);
                  Haptics.selectionAsync();
                }}
              >
                <View
                  style={[
                    styles.virtueIconContainer,
                    { backgroundColor: `${virtue.color}15` }
                  ]}
                >
                  <virtue.icon size={24} color={virtue.color} />
                </View>
                <Text style={[
                  styles.virtueText,
                  selectedVirtue === virtue.id && { color: virtue.color }
                ]}>
                  {virtue.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}

        <Text style={styles.sectionTitle}>SESSION LENGTH</Text>
        <View style={styles.timeContainer}>
          {TIME_OPTIONS.map((option: { value: number, label: string }) => (
            <TouchableOpacity
              key={option.value}
              style={[
                styles.timeButton,
                selectedTime === option.value && styles.selectedTimeButton,
                selectedTime === option.value && {
                  borderColor: currentVirtue?.color || theme?.colors.primary
                }
              ]}
              onPress={() => {
                setSelectedTime(option.value);
                Haptics.selectionAsync();
              }}
            >
              <View style={styles.timeButtonContent}>
                <Clock
                  size={16}
                  color={selectedTime === option.value
                    ? (currentVirtue?.color || theme?.colors.primary)
                    : theme?.colors.text.secondary
                  }
                />
                <Text style={[
                  styles.timeText,
                  selectedTime === option.value && {
                    color: currentVirtue?.color || theme?.colors.primary
                  }
                ]}>
                  {option.label}
                </Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.sectionTitle}>BACKGROUND SOUND</Text>
        <View style={styles.soundContainer}>
          <TouchableOpacity
            style={[
              styles.soundButton,
              selectedBackgroundSound === 'ambient' && styles.selectedSoundButton,
              selectedBackgroundSound === 'ambient' && {
                borderColor: currentVirtue?.color || theme?.colors.primary
              }
            ]}
            onPress={() => {
              setSelectedBackgroundSound('ambient');
              Haptics.selectionAsync();
            }}
          >
            <View style={styles.soundButtonContent}>
              <Bell
                size={16}
                color={selectedBackgroundSound === 'ambient'
                  ? (currentVirtue?.color || theme?.colors.primary)
                  : theme?.colors.text.secondary
                }
              />
              <Text style={[
                styles.soundText,
                selectedBackgroundSound === 'ambient' && {
                  color: currentVirtue?.color || theme?.colors.primary
                }
              ]}>
                Ambient
              </Text>
            </View>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[
              styles.soundButton,
              selectedBackgroundSound === 'heartbeat' && styles.selectedSoundButton,
              selectedBackgroundSound === 'heartbeat' && {
                borderColor: currentVirtue?.color || theme?.colors.primary
              }
            ]}
            onPress={() => {
              setSelectedBackgroundSound('heartbeat');
              Haptics.selectionAsync();
            }}
          >
            <View style={styles.soundButtonContent}>
              <Heart
                size={16}
                color={selectedBackgroundSound === 'heartbeat'
                  ? (currentVirtue?.color || theme?.colors.primary)
                  : theme?.colors.text.secondary
                }
              />
              <Text style={[
                styles.soundText,
                selectedBackgroundSound === 'heartbeat' && {
                  color: currentVirtue?.color || theme?.colors.primary
                }
              ]}>
                Heartbeat
              </Text>
            </View>
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[
              styles.soundButton,
              selectedBackgroundSound === null && styles.selectedSoundButton,
              selectedBackgroundSound === null && {
                borderColor: currentVirtue?.color || theme?.colors.primary
              }
            ]}
            onPress={() => {
              setSelectedBackgroundSound(null);
              Haptics.selectionAsync();
            }}
          >
            <View style={styles.soundButtonContent}>
              <Flame
                size={16}
                color={selectedBackgroundSound === null
                  ? (currentVirtue?.color || theme?.colors.primary)
                  : theme?.colors.text.secondary
                }
              />
              <Text style={[
                styles.soundText,
                selectedBackgroundSound === null && {
                  color: currentVirtue?.color || theme?.colors.primary
                }
              ]}>
                Silent
              </Text>
            </View>
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>DAILY CHALLENGE</Text>
        <View style={styles.challengeContainer}>
          {renderChallengeButtons()}
        </View>

        <TouchableOpacity
          style={[
            styles.startButton,
            {
              backgroundColor: currentVirtue
                ? currentVirtue.color
                : theme?.colors.primary
            }
          ]}
          onPress={startMeditation}
        >
          <Text style={styles.startButtonText}>Begin Meditation</Text>
        </TouchableOpacity>
      </Animated.View>
    </ScrollView>
  );

  const renderCountdownScreen = () => (
    <View style={styles.countdownContainer}>
      <Animated.View
        style={[
          styles.countdownCircle,
          {
            borderColor: currentVirtue?.color || theme?.colors.primary,
          },
          countdownNumberStyle
        ]}
      >
        <Animated.Text style={[
          styles.countdownText,
          { color: currentVirtue?.color || theme?.colors.primary },
          { textShadowColor: 'rgba(0,0,0,0.2)', textShadowOffset: { width: 0, height: 1 }, textShadowRadius: 2 }
        ]}>
          {countdown}
        </Animated.Text>
      </Animated.View>
      <Text style={styles.countdownSubtext}>
        Preparing your meditation...
      </Text>
      <Text style={styles.breatheText}>
        Take a deep breath
      </Text>
    </View>
  );

  const renderActiveScreen = () => {
    return (
      <View style={styles.activeContainer}>
        <AnimatedCircularProgress
          size={250}
          width={4}
          fill={progressAnim}
          tintColor={currentVirtue?.color || theme?.colors.primary}
          backgroundColor={theme.colors.border}
          rotation={0}
          lineCap="round"
        >
          {(
            <View style={styles.breathCircleContainer}>
              <Animated.View style={[styles.breathGradient, breathingCircleStyle]}>
                <LinearGradient
                  colors={[`${currentVirtue?.color}33`, `${currentVirtue?.color}00`]}
                  style={StyleSheet.absoluteFill}
                />
              </Animated.View>
              <AnimatedParticles
                count={20}
                color={currentVirtue?.color || theme?.colors.primary}
                speed={0.5}
                radius={2}
                anim={pulseAnim}
              />
            </View>
          )}
        </AnimatedCircularProgress>

        {/* Enhanced prompt animation */}
        <Animated.View style={[styles.promptContainer, promptAnimStyle]}>
          <Text style={styles.promptText}>{currentPrompt}</Text>
          {/* Add progress dots */}
          <View style={styles.promptProgress}>
            {currentVirtue?.prompts.map((_, i) => (
              <View key={i} style={[
                styles.progressDot,
                i === currentPromptIndex && styles.activeProgressDot,
                i === currentPromptIndex && { backgroundColor: currentVirtue.color }
              ]} />
            ))}
          </View>
        </Animated.View>
      </View>
    );
  };
  // Render challenge buttons with DailyChallenge structure
  const renderChallengeButtons = () => {
    if (!selectedVirtue) {
      return (
        <Text style={styles.placeholderText}>
          Select a virtue to see challenge options
        </Text>
      );
    }

    return CHALLENGE_TEMPLATES[selectedVirtue]?.map((challenge, index) => (
      <TouchableOpacity
        key={challenge.id}
        style={[
          styles.challengeButton,
          selectedChallenge?.id === challenge.id && styles.selectedChallengeButton,
          selectedChallenge?.id === challenge.id && {
            borderColor: currentVirtue?.color || theme?.colors.primary
          }
        ]}
        onPress={() => {
          setSelectedChallenge(challenge);
          Haptics.selectionAsync();
        }}
      >
        <LinearGradient
          colors={[
            `${currentVirtue?.color || theme?.colors.primary}10`,
            `${currentVirtue?.color || theme?.colors.primary}03`
          ]}
          style={[
            StyleSheet.absoluteFill,
            styles.challengeGradient,
            selectedChallenge?.id === challenge.id && { opacity: 0.5 }
          ]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        />
        <View style={styles.challengeContentContainer}>
          <Text style={[
            styles.challengeTitle,
            selectedChallenge?.id === challenge.id && {
              color: currentVirtue?.color || theme?.colors.primary
            }
          ]}>
            {challenge.title}
          </Text>
          <Text style={styles.challengeDescription}>
            {challenge.description}
          </Text>
          <View style={styles.challengeMetaContainer}>
            <View style={[
              styles.challengeTypeBadge,
              {
                backgroundColor: challenge.mode === 'attitude' ?
                  `${theme?.colors.secondary}20` :
                  `${theme?.colors.primary}20`
              }
            ]}>
              <Text style={[
                styles.challengeTypeBadgeText,
                {
                  color: challenge.mode === 'attitude' ?
                    theme?.colors.secondary :
                    theme?.colors.primary
                }
              ]}>
                {challenge.mode === 'attitude' ? 'Mindset' : 'Action'}
              </Text>
            </View>
          </View>
        </View>

        {selectedChallenge?.id === challenge.id && (
          <View style={[
            styles.checkmarkIcon,
            { backgroundColor: currentVirtue?.color || theme?.colors.primary }
          ]}>
            <Check size={12} color="#FFFFFF" />
          </View>
        )}
      </TouchableOpacity>
    ));
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      {meditationState === MeditationState.SETUP && (
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => navigation.goBack()}
          >
            <ArrowLeft size={24} color={theme?.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Daily Meditation</Text>
          <View style={{ width: 24 }} />
        </View>
      )}

      {/* Content based on state */}
      {meditationState === MeditationState.SETUP && renderSetupScreen()}
      {meditationState === MeditationState.COUNTDOWN && renderCountdownScreen()}
      {meditationState === MeditationState.ACTIVE && renderActiveScreen()}
      {meditationState === MeditationState.COMPLETE && renderCompleteScreen()}
    </View>
  );
};

const createStyles = (theme: Theme, currentVirtue: any) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
  },
  headerTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  scrollContainer: {
    flex: 1,
  },
  setupContainer: {
    padding: theme?.spacing.md,
  },
  sectionTitle: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.lg,
    marginBottom: theme?.spacing.sm,
    fontWeight: '600',
  },
  virtuesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: theme?.spacing.sm,
  },
  virtueButton: {
    width: '48%',
    paddingVertical: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1.5,
    borderColor: theme?.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme?.colors.surface,
    marginBottom: theme?.spacing.sm,
  },
  selectedVirtueButton: {
    borderWidth: 2,
    backgroundColor: theme?.colors.background,
  },
  virtueIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.sm,
  },
  virtueText: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    color: theme?.colors.text.primary,
  },
  timeContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  timeButton: {
    flex: 1,
    paddingVertical: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1.5,
    borderColor: theme?.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme?.colors.surface,
    marginHorizontal: theme?.spacing.xs,
  },
  selectedTimeButton: {
    borderWidth: 2,
    backgroundColor: theme?.colors.background,
  },
  timeButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  timeText: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    color: theme?.colors.text.primary,
  },

  completeContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme.spacing.lg,
  },
  completeBanner: {
    width: '100%',
    alignItems: 'center',
    marginTop: theme.spacing.xl,
  },
  completeTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginVertical: theme.spacing.md,
  },
  completeSubtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginBottom: theme.spacing.xl,
  },
  bellContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bellButton: {
    alignItems: 'center',
  },
  bellIconContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme.spacing.md,
  },
  bellText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  challengeSummaryContainer: {
    width: '100%',
    marginBottom: theme.spacing.xl,
  },
  challengeSummaryTitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  challengeSummaryCard: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
    overflow: 'hidden',
  },
  challengeSummaryText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.sm,
  },
  challengeDuration: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },

  challengeContainer: {
    gap: theme?.spacing.sm,
  },
  challengeButton: {
    padding: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1.5,
    borderColor: theme?.colors.border,
    backgroundColor: theme?.colors.surface,
    overflow: 'hidden',
    marginBottom: theme?.spacing.sm,
  },
  selectedChallengeButton: {
    borderWidth: 2,
    backgroundColor: `${theme?.colors.surface}80`,
  },
  challengeGradient: {
    borderRadius: theme?.borderRadius.md - 1,
  },
  challengeContentContainer: {
    flex: 1,
  },
  challengeTitle: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    color: theme?.colors.text.primary,
    marginBottom: 4,
  },
  challengeDescription: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginBottom: 8,
  },
  challengeMetaContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  challengeTypeBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 12,
    marginRight: 8,
  },
  challengeTypeBadgeText: {
    ...theme?.typography.caption.secondary,
    fontSize: 10,
    fontWeight: '600',
  },
  breathGradient: {
    width: 200,
    height: 200,
    borderRadius: 100,
    overflow: 'hidden',
  },
  promptProgress: {
    flexDirection: 'row',
    marginTop: theme.spacing.md,
    gap: theme.spacing.xs,
  },
  progressDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: theme.colors.border,
  },
  activeProgressDot: {
    width: 16,
  },
  challengeButtonGradient: {
    padding: theme.spacing.xl,
    alignItems: 'center',
    paddingHorizontal: theme.spacing.xxl,
  },
  challengeButtonText: {
    ...theme.typography.heading.small,
    color: '#FFF',
    marginVertical: theme.spacing.md,
  },
  challengeDurationText: {
    ...theme.typography.caption.secondary,
    color: '#FFFFFFAA',
    textAlign: 'center',
  },
  motivationText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
    marginTop: theme.spacing.xl,
  },
  successAnimation: {
    width: 150,
    height: 150,
  },
  breatheInstruction: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    position: 'absolute',
    bottom: -30,
    fontWeight: '600',
  },
  promptContainer: {
    padding: theme?.spacing.lg,
    marginVertical: theme?.spacing.xl,
    borderRadius: theme?.borderRadius.lg,
    backgroundColor: theme?.colors.surface,
    width: '100%',
    alignItems: 'center',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  promptText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    textAlign: 'center',
    lineHeight: 24,
    fontWeight: '600',
    fontSize: 18,
  },
  progressBarContainer: {
    width: '100%',
    marginBottom: theme?.spacing.lg,
  },
  progressBar: {
    height: 6,
    backgroundColor: theme?.colors.border,
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
  },

  // Countdown screen styles
  countdownContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.lg,
  },
  countdownCircle: {
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 4,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.xl,
  },
  countdownText: {
    ...theme?.typography.heading.large,
    fontSize: 64,
    fontWeight: '700',
    letterSpacing: -1,
  },
  countdownSubtext: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontSize: 18,
    marginBottom: theme?.spacing.md,
  },
  breatheText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },

  // Active meditation styles
  activeContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme?.spacing.lg,
  },
  meditationHeader: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'center',
    marginBottom: theme?.spacing.xl,
  },
  timerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    backgroundColor: theme?.colors.surface,
    gap: theme?.spacing.xs,
  },
  timerText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  breathCircleContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    flex: 1,
  },
  breatheCircle: {
    width: 200,
    height: 200,
    borderRadius: 100,
  },
  virtueIconWrapper: {
    position: 'absolute',
    alignItems: 'center',
    justifyContent: 'center',
  },
  startButton: {
    marginTop: theme?.spacing.xl,
    marginBottom: theme?.spacing.xl,
    paddingVertical: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.xl,
    borderRadius: theme?.borderRadius.lg,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: currentVirtue?.color || theme?.colors.primary,
    ...Platform.select({
      ios: {
        shadowColor: theme?.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
      },
      android: {
        elevation: 6,
      },
    }),
  },
  startButtonText: {
    ...theme?.typography.body.sans,
    fontWeight: '700',
    color: '#FFFFFF',
    fontSize: 16,
  },
  placeholderText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    textAlign: 'center',
    paddingVertical: theme?.spacing.xl,
  },
  checkmarkIcon: {
    position: 'absolute',
    top: theme?.spacing.sm,
    right: theme?.spacing.sm,
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  selectedVirtueCollapsed: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1.5,
    borderColor: currentVirtue?.color || theme?.colors.border,
    backgroundColor: `${currentVirtue?.color || theme?.colors.primary}08`,
    marginBottom: theme?.spacing.md,
  },
  selectedVirtueContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.md,
  },
  changeVirtueButton: {
    paddingVertical: theme?.spacing.xs,
    paddingHorizontal: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.sm,
    backgroundColor: theme?.colors.surface,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  changeVirtueText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    fontWeight: '500',
  },

  // Add sound selection styles
  soundContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.md,
  },
  soundButton: {
    flex: 1,
    paddingVertical: theme?.spacing.md,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1.5,
    borderColor: theme?.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme?.colors.surface,
    marginHorizontal: theme?.spacing.xs,
  },
  selectedSoundButton: {
    borderWidth: 2,
    backgroundColor: theme?.colors.background,
  },
  soundButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  soundText: {
    ...theme?.typography.body.sans,
    fontWeight: '600',
    color: theme?.colors.text.primary,
  },
});

export default MeditationScreen; 