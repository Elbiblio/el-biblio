import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Platform,
  BackHandler,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import { CHALLENGE_TEMPLATES, MeditationSession, RootStackParamList, TIME_OPTIONS, VIRTUES } from '@/types';
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
} from '@/components/Icons';
import { Theme } from '@/theme';
import { useAuth } from '@/stores/auth';
import * as Haptics from 'expo-haptics';
import { Audio } from 'expo-av';
import { DailyChallenge } from '@/types';
import AnimatedCircularProgress from '@/components/AnimatedCircularProgress';
import AnimatedParticles from '@/components/AnimatedParticles';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  withRepeat,
  withDelay,
  Easing,
  interpolate,
} from 'react-native-reanimated';
import { useMeditationStore } from '@/stores/meditation';

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

  // State management
  const [selectedVirtue, setSelectedVirtue] = useState<string | null>(null);
  const [selectedTime, setSelectedTime] = useState<number | null>(null);
  const [selectedChallenge, setSelectedChallenge] = useState<DailyChallenge | null>(null);
  const [meditationState, setMeditationState] = useState<MeditationState>(MeditationState.SETUP);
  const [countdown, setCountdown] = useState(10);
  const [meditationTimer, setMeditationTimer] = useState(0);
  const [currentPromptIndex, setCurrentPromptIndex] = useState(0);
  const [showPrompt, setShowPrompt] = useState(false);
  const [selectedBackgroundSound, setSelectedBackgroundSound] = useState<string | null>(null);
  const [breathePhase, setBreathePhase] = useState<'in' | 'hold' | 'out'>('in');
  const [challengeExpanded, setChallengeExpanded] = useState(false);
//  const [completionSound, setCompletionSound] = useState<Audio.Sound | null>(null);

  // Animation values
  const fadeAnim = useSharedValue(1);
  const breatheTextOpacity = useSharedValue(0);
  const numberScale = useSharedValue(1);
  const numberOpacity = useSharedValue(1);
  const pulseAnim = useSharedValue(0);
  const progressAnim = useSharedValue(0);
  const promptOpacity = useSharedValue(0);
  const bellScale = useSharedValue(1);

  // Audio refs
  const [tickSound, setTickSound] = useState<Audio.Sound | null>(null);
  const [backgroundSound, setBackgroundSound] = useState<Audio.Sound | null>(null);
  const isSpeaking = useRef(false);

  // Add these new state variables and refs
  const [bellSound, setBellSound] = useState<Audio.Sound | null>(null);
  const [meditationBellSound, setMeditationBellSound] = useState<Audio.Sound | null>(null);
  const isEndingPhase = useRef(false);
  const hasReadChallenge = useRef(false);
  const hasStartedFinalCountdown = useRef(false);
  const firstTwoMinutesCompleted = useRef(false);

  // Derived values
  const currentVirtue = React.useMemo(
    () => VIRTUES.find((v) => v.id === selectedVirtue),
    [selectedVirtue]
  );
  const totalMeditationSeconds = React.useMemo(
    () => (selectedTime || 0) * 60,
    [selectedTime]
  );
  const promptInterval = totalMeditationSeconds > 0 ? Math.floor(totalMeditationSeconds / 4) : 0;
  const currentPrompt = currentVirtue?.prompts[currentPromptIndex];
  const styles = React.useMemo(
    () => createStyles(theme, currentVirtue),
    [theme, currentVirtue]
  );

  const [introCompleted, setIntroCompleted] = useState(false);

  // Load sounds
  useEffect(() => {
    async function loadSounds() {
      try {
        const { sound: tick } = await Audio.Sound.createAsync(
          require('../../assets/sounds/tick-tock.wav')
        );
        setTickSound(tick);

        // const { sound: completion } = await Audio.Sound.createAsync(
        //   require('../../assets/sounds/correct.mp3')
        // );
        // setCompletionSound(completion);
        
        // Load bell sounds
        const { sound: bell } = await Audio.Sound.createAsync(
          require('../../assets/sounds/bell.wav')
        );
        setBellSound(bell);
        
        const { sound: meditationBell } = await Audio.Sound.createAsync(
          require('../../assets/sounds/bell-meditation.mp3')
        );
        setMeditationBellSound(meditationBell);
      } catch (error) {
        console.error('Failed to load sounds', error);
      }
    }
    loadSounds();

    return () => {
      if (tickSound) tickSound.unloadAsync();
      if (backgroundSound) backgroundSound.unloadAsync();
      // if (completionSound) completionSound.unloadAsync();
      if (bellSound) bellSound.unloadAsync();
      if (meditationBellSound) meditationBellSound.unloadAsync();
    };
  }, []);

  useEffect(() => {
    const loadBackgroundSound = async () => {
      // Stop and unload previous sound if it exists
      if (backgroundSound) {
        await backgroundSound.stopAsync();
        await backgroundSound.unloadAsync();
      }

      if (!selectedBackgroundSound) return;

      try {
        const soundAsset =
          selectedBackgroundSound === 'ambient'
            ? require('../../assets/sounds/meditation-ambient.mp3')
            : require('../../assets/sounds/heartbeat.mp3');
        const { sound } = await Audio.Sound.createAsync(soundAsset, {
          isLooping: true,
          volume: 0.6,
        });
        setBackgroundSound(sound);

        // Play preview if we're in setup mode
        if (meditationState === MeditationState.SETUP) {
          await sound.playAsync();
        } else if (meditationState === MeditationState.ACTIVE) {
          await sound.playAsync();
        }
      } catch (error) {
        console.error('Failed to load background sound', error);
      }
    };
    loadBackgroundSound();
  }, [selectedBackgroundSound]);

  // Stop preview when meditation state changes or when component unmounts
  useEffect(() => {
    const handleBackgroundSound = async () => {
      if (!backgroundSound) return;

      if (meditationState === MeditationState.ACTIVE) {
        await backgroundSound.playAsync();
      } else if (meditationState === MeditationState.COUNTDOWN) {
        // Stop preview when countdown starts
        await backgroundSound.stopAsync();
      } else if (meditationState === MeditationState.COMPLETE) {
        await backgroundSound.stopAsync();
      }
    };
    handleBackgroundSound();

    // Clean up sound on unmount
    return () => {
      if (backgroundSound) {
        backgroundSound.stopAsync();
      }
    };
  }, [meditationState, backgroundSound]);

  // Play tick sound
  const playTickSound = async () => {
    try {
      if (tickSound) {
        await tickSound.setPositionAsync(0);
        await tickSound.playAsync();
      }
    } catch (error) {
      console.error('Failed to play tick sound', error);
    }
  };

  // Countdown animation
  const animateCountdownNumber = () => {
    numberScale.value = withSequence(
      withTiming(1.2, { duration: 300, easing: Easing.out(Easing.quad) }),
      withTiming(0.8, { duration: 700, easing: Easing.inOut(Easing.quad) })
    );
    numberOpacity.value = withSequence(
      withTiming(1, { duration: 100, easing: Easing.out(Easing.quad) }),
      withTiming(0.5, { duration: 700, easing: Easing.inOut(Easing.quad) })
    );
  };

  const animateBreathText = () => {
    breatheTextOpacity.value = withSequence(
      withTiming(1, { duration: 500 }), // Fade in (500ms)
      withDelay(3000, withTiming(0, { duration: 500 })) // Stay visible (3000ms), fade out (500ms)
    );
  };

  useEffect(() => {
    if (meditationState === MeditationState.ACTIVE && introCompleted) {
      // Start breathing cycle logic
      let currentPhase: 'in' | 'hold' | 'out' = 'in';
      setBreathePhase(currentPhase);
      animateBreathText();
      
      const phaseInterval = setInterval(() => {
        currentPhase = currentPhase === 'in' ? 'hold' : currentPhase === 'hold' ? 'out' : 'in';
        setBreathePhase(currentPhase);
        if (currentPhase === 'out' && !firstTwoMinutesCompleted.current) {  
          playBellSound();
        }
        animateBreathText();
      }, 4000);

      pulseAnim.value = 0;

      // Create precise breathing animation sequence - exactly 4 seconds for each phase
      pulseAnim.value = withRepeat(
        withSequence(
          // Breathe in - expand precisely over 4 seconds
          withTiming(1, {
            duration: 4000,
            easing: Easing.inOut(Easing.quad)
          }),
          // Hold - maintain expanded state for exactly 4 seconds
          withTiming(1, {
            duration: 1000,
            easing: Easing.inOut(Easing.quad)
          }),
          // Breathe out - contract precisely over 4 seconds
          withTiming(0, {
            duration: 7000,
            easing: Easing.inOut(Easing.quad)
          })
        ),
        -1, // Infinite repeat
        false
      );
  
      return () => clearInterval(phaseInterval);
    }
  }, [meditationState, introCompleted]);

  // Enhanced breathing circle style with better animation match
  const breathingCircleStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pulseAnim.value, [0, 1], [0.7, 1.6]) }],
    opacity: interpolate(pulseAnim.value, [0, 1], [0.5, 0.9]),
  }));

  // Countdown logic
  useEffect(() => {
    let interval: number;
    if (meditationState === MeditationState.COUNTDOWN && countdown > 0) {
      playTickSound();
      animateCountdownNumber();
      speakCountdownNumber(countdown);
      interval = setInterval(() => {
        setCountdown((prev) => {
          const newValue = prev - 1;
          if (newValue >= 0) {
            playTickSound();
            animateCountdownNumber();
            speakCountdownNumber(newValue);
          }
          if (newValue === 0) {
            setMeditationState(MeditationState.ACTIVE);
            progressAnim.value = 0;
            setMeditationTimer(0);
          }
          return newValue;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [meditationState, countdown]);

  // Meditation timer and progress with end-session enhancements
  useEffect(() => {
    let interval: number;
    if (meditationState === MeditationState.ACTIVE && selectedTime) {
      showAndSpeakPrompt(0);
      firstTwoMinutesCompleted.current = false;
      hasReadChallenge.current = false;
      hasStartedFinalCountdown.current = false;
      isEndingPhase.current = false;
      
      interval = setInterval(() => {
        setMeditationTimer((prev) => {
          const newValue = prev + 1;
          progressAnim.value = newValue / totalMeditationSeconds;
          
          // Mark first 2 minutes as complete
          if (newValue >= 120 && !firstTwoMinutesCompleted.current) {
            firstTwoMinutesCompleted.current = true;
          }
          
          // Regular prompts during the session
          if (newValue % promptInterval === 0 && newValue < totalMeditationSeconds - 30) {
            const nextPromptIndex = Math.floor(newValue / promptInterval);
            if (nextPromptIndex < 4) showAndSpeakPrompt(nextPromptIndex);
          }
          
          // Read challenge 30 seconds before the end
          if (totalMeditationSeconds - newValue <= 30 && !hasReadChallenge.current) {
            hasReadChallenge.current = true;
            isEndingPhase.current = true;
            
            if (isSpeaking.current) Speech.stop();
            setTimeout(() => {
              Speech.speak("Your challenge is:", {
                rate: 0.85, onDone: () => {
                  if (selectedChallenge) {
                    Speech.speak(selectedChallenge.title, {
                      rate: 0.85, onDone: () => {
                        Speech.speak(selectedChallenge.description, {
                          rate: 0.85
                        });
                      }
                    });
                  }
                }
              });
            }, 500);
          }
          
          // Start final countdown 10 seconds before the end
          if (totalMeditationSeconds - newValue <= 10 && !hasStartedFinalCountdown.current) {
            hasStartedFinalCountdown.current = true;
            if (isSpeaking.current) Speech.stop();
            
            Speech.speak("You resolve to do better today.", {
              rate: 0.85, onDone: () => {
                // Start the bell-based countdown
                let countdownNumber = 10;
                playMeditationBellSound();
                const countdownInterval = setInterval(() => {
                  // Play bell sound instead of tick                  
                  countdownNumber--;
                  if (countdownNumber <= 3 && countdownNumber > 0) {
                    setTimeout(() => Speech.speak(`${countdownNumber}`, { rate: 0.8 }), 500);
                  } else if (countdownNumber === 0) {
                    setTimeout(() => Speech.speak("Open your eyes", { rate: 0.8 }), 500);
                    clearInterval(countdownInterval);
                  }
                }, 1000);
              }
            });
          }
          
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

  // Bell animation on complete
  useEffect(() => {
    if (meditationState === MeditationState.COMPLETE) {
      bellScale.value = withRepeat(
        withSequence(
          withTiming(1.05, { duration: 1000 }),
          withTiming(1, { duration: 1000 })
        ),
        -1
      );
    }
  }, [meditationState]);

  // Handlers
  const speakCountdownNumber = (number: number) => {
    Speech.stop();
    if (number <= 3 && number > 0) {
      setTimeout(() => Speech.speak(`${number}`, { rate: 0.8 }), 100);
    } else if (number === 0) {
      setTimeout(() => Speech.speak('Close your eyes if you are able to do so...', {
        rate: 0.8, onDone: () => {
          setTimeout(() => {
            Speech.speak('Visualize yourself calm. Peaceful. Empty; and ready to grow spiritually...', {
              rate: 0.8, onDone: () => {
                setTimeout(() => {
                  playMeditationBellSound();
                  setTimeout(() => {
                    Speech.speak('Breathe in...', {
                      rate: 0.8, onDone: () => {
                        setTimeout(() => {
                          Speech.speak('Keep still...', {
                            rate: 0.8, onDone: () => {
                              setTimeout(() => {
                                Speech.speak('Breathe out...', {
                                  rate: 0.8, onDone: () => {
                                    setIntroCompleted(true);
                                    setBreathePhase('in');
                                  }
                                });
                              }, 4000);
                            }
                          });
                        }, 4000);
                      }
                    });
                  }, 500);
                }, 1000);
              }
            });
          }, 1000);
        }
      }), 2000);
    }
  };

  const showAndSpeakPrompt = (index: number) => {
    setCurrentPromptIndex(index);
    setShowPrompt(false);
    const introWord = index === 0 ? "Begin" : "Now";

    promptOpacity.value = withTiming(0, { duration: 500 });
    setTimeout(() => {
      setShowPrompt(true);
      promptOpacity.value = withTiming(1, { duration: 1000 });
      if (currentVirtue?.prompts[index]) {
        isSpeaking.current = true;
        Speech.speak(`${introWord}...`, {
          rate: 0.85, onDone: () => {
            setTimeout(() => {
              Speech.speak(currentVirtue.prompts[index], {
                rate: 0.85,
                onDone: () => { isSpeaking.current = false },
              });
            }, 1000);
          }
        })
      }
    }, 500);
  };

  const startMeditation = () => {
    if (!selectedVirtue || !selectedTime || !selectedChallenge) {
      fadeAnim.value = withSequence(withTiming(0.3, { duration: 200 }), withTiming(1, { duration: 200 }));
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    progressAnim.value = 0;
    setMeditationState(MeditationState.COUNTDOWN);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  useEffect(() => {
    useMeditationStore.getState().initialize();
  }, []);

  const endMeditation = () => {
    setMeditationState(MeditationState.COMPLETE);
    if (isSpeaking.current) Speech.stop();
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  
    const session: MeditationSession = {
      virtue_id: selectedVirtue!,
      duration_minutes: selectedTime!,
      started_at: new Date(Date.now() - selectedTime! * 60 * 1000).toISOString(),
      ended_at: new Date().toISOString(),
    };
    useMeditationStore.getState().recordSession(session);
  };

  const createChallenge = async () => {
    if (!selectedChallenge) return;
    const pointsEarned = selectedTime === 7 ? 15 : selectedTime === 15 ? 25 : 50;
    const endTime = new Date();
    endTime.setHours(endTime.getHours() + (selectedTime === 40 ? 24 : selectedTime === 15 ? 6 : 3));
    const challenge = { ...selectedChallenge, end_time: endTime };
  
    if (user) {
      await updateUserPoints((user.points || 0) + pointsEarned);
      await useMeditationStore.getState().joinChallenge(selectedChallenge.id);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
    navigation.navigate('Home', { meditationComplete: true, challenge, pointsEarned });
  };

  // Animated styles
  const fadeAnimStyle = useAnimatedStyle(() => ({ opacity: fadeAnim.value }));
  const countdownNumberStyle = useAnimatedStyle(() => ({
    transform: [{ scale: numberScale.value }],
    opacity: numberOpacity.value,
  }));
  const breatheTextStyle = useAnimatedStyle(() => ({ opacity: breatheTextOpacity.value }));
  const promptAnimStyle = useAnimatedStyle(() => ({
    opacity: promptOpacity.value,
    transform: [{ translateY: interpolate(promptOpacity.value, [0, 1], [20, 0]) }],
  }));
  const bellButtonStyle = useAnimatedStyle(() => ({ transform: [{ scale: bellScale.value }] }));

  // Play bell sound
  const playBellSound = async () => {
    try {
      if (bellSound) {
        await bellSound.setPositionAsync(0);
        await bellSound.playAsync();
      }
    } catch (error) {
      console.error('Failed to play bell sound', error);
    }
  };
  
  // Play meditation bell sound
  const playMeditationBellSound = async () => {
    try {
      if (meditationBellSound) {
        await meditationBellSound.setPositionAsync(0);
        await meditationBellSound.playAsync();
      }
    } catch (error) {
      console.error('Failed to play meditation bell sound', error);
    }
  };

  // Render functions
  const renderSetupScreen = () => (
    <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
      <Animated.View style={[styles.setupContainer, fadeAnimStyle]}>
        <Text style={styles.sectionTitle}>CHOOSE A VIRTUE</Text>
        {selectedVirtue ? (
          <View style={styles.selectedVirtueCollapsed}>
            <View style={styles.selectedVirtueContent}>
              {currentVirtue && (
                <>
                  <View
                    style={[
                      styles.virtueIconContainer,
                      { backgroundColor: `${currentVirtue.color}15` },
                    ]}
                  >
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
          <View style={styles.virtuesContainer}>
            {VIRTUES.map((virtue) => (
              <TouchableOpacity
                key={virtue.id}
                style={[
                  styles.virtueButton,
                  selectedVirtue === virtue.id && styles.selectedVirtueButton,
                  selectedVirtue === virtue.id && { borderColor: virtue.color },
                ]}
                onPress={() => {
                  setSelectedVirtue(virtue.id);
                  Haptics.selectionAsync();
                }}
              >
                <View style={[styles.virtueIconContainer, { backgroundColor: `${virtue.color}15` }]}>
                  <virtue.icon size={24} color={virtue.color} />
                </View>
                <Text
                  style={[
                    styles.virtueText,
                    selectedVirtue === virtue.id && { color: virtue.color },
                  ]}
                >
                  {virtue.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        )}

        <Text style={styles.sectionTitle}>SESSION LENGTH</Text>
        <View style={styles.timeContainer}>
          {TIME_OPTIONS.map((option) => (
            <TouchableOpacity
              key={option.value}
              style={[
                styles.timeButton,
                selectedTime === option.value && styles.selectedTimeButton,
                selectedTime === option.value && {
                  borderColor: currentVirtue?.color || theme?.colors.primary,
                },
              ]}
              onPress={() => {
                setSelectedTime(option.value);
                Haptics.selectionAsync();
              }}
            >
              <View style={styles.timeButtonContent}>
                <Clock
                  size={16}
                  color={
                    selectedTime === option.value
                      ? currentVirtue?.color || theme?.colors.primary
                      : theme?.colors.text.secondary
                  }
                />
                <Text
                  style={[
                    styles.timeText,
                    selectedTime === option.value && {
                      color: currentVirtue?.color || theme?.colors.primary,
                    },
                  ]}
                >
                  {option.label}
                </Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.sectionTitle}>BACKGROUND SOUND</Text>
        <View style={styles.soundContainer}>
          {[
            { id: 'ambient', label: 'Ambient', icon: Bell },
            { id: 'heartbeat', label: 'Heartbeat', icon: Heart },
            { id: null, label: 'Silent', icon: Flame },
          ].map(({ id, label, icon: Icon }) => (
            <TouchableOpacity
              key={label}
              style={[
                styles.soundButton,
                selectedBackgroundSound === id && styles.selectedSoundButton,
                selectedBackgroundSound === id && {
                  borderColor: currentVirtue?.color || theme?.colors.primary,
                },
              ]}
              onPress={() => {
                setSelectedBackgroundSound(id);
                Haptics.selectionAsync();
              }}
            >
              <View style={styles.soundButtonContent}>
                <Icon
                  size={16}
                  color={
                    selectedBackgroundSound === id
                      ? currentVirtue?.color || theme?.colors.primary
                      : theme?.colors.text.secondary
                  }
                />
                <Text
                  style={[
                    styles.soundText,
                    selectedBackgroundSound === id && {
                      color: currentVirtue?.color || theme?.colors.primary,
                    },
                  ]}
                >
                  {label}
                </Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={styles.sectionTitle}>DAILY CHALLENGE</Text>
        <View style={styles.challengeContainer}>
          {selectedVirtue ? (
            selectedChallenge ? (
              <View style={[
                styles.selectedChallengeCollapsed,
                { borderColor: currentVirtue?.color || theme?.colors.border }
              ]}>
                <View style={styles.selectedChallengeContent}>
                  <Text style={[
                    styles.challengeTitle,
                    { color: currentVirtue?.color || theme?.colors.primary }
                  ]}>
                    {selectedChallenge.title}
                  </Text>
                  <Text style={styles.challengeDescriptionCollapsed}>
                    {selectedChallenge.description.length > 80
                      ? selectedChallenge.description.substring(0, 80) + '...'
                      : selectedChallenge.description}
                  </Text>
                </View>
                <TouchableOpacity
                  style={styles.changeChallengeButton}
                  onPress={() => {
                    setSelectedChallenge(null);
                    Haptics.selectionAsync();
                  }}
                >
                  <Text style={styles.changeChallengeText}>Change</Text>
                </TouchableOpacity>
              </View>
            ) : (
              CHALLENGE_TEMPLATES[selectedVirtue]?.map((challenge: DailyChallenge) => (
                <TouchableOpacity
                  key={challenge.id}
                  style={[
                    styles.challengeButton,
                    selectedChallenge && (selectedChallenge as DailyChallenge).id ? {
                      ...styles.selectedChallengeButton,
                      borderColor: currentVirtue?.color || theme?.colors.primary,
                    } : undefined,
                  ]}
                  onPress={() => {
                    setSelectedChallenge(challenge);
                    Haptics.selectionAsync();
                  }}
                >
                  <LinearGradient
                    colors={[`${currentVirtue?.color}15`, `${currentVirtue?.color}05`]}
                    style={StyleSheet.absoluteFill}
                  />
                  <Text style={[
                    styles.challengeTitle,
                    selectedChallenge && (selectedChallenge as DailyChallenge).id ? {
                      color: currentVirtue?.color || theme?.colors.primary,
                    } : undefined,
                  ]}>
                    {challenge.title}
                  </Text>
                  <Text style={styles.challengeDescription}>{challenge.description}</Text>                  
                  {selectedChallenge && (selectedChallenge as DailyChallenge).id === challenge.id && (
                    <View
                      style={[
                        styles.checkmarkIcon,
                        { backgroundColor: currentVirtue?.color || theme?.colors.primary },
                      ]}
                    >
                      <Check size={12} color="#FFFFFF" />
                    </View>
                  )}
                </TouchableOpacity>
              ))
            )
          ) : (
            <Text style={styles.placeholderText}>
              Select a virtue to see challenge options
            </Text>
          )}
        </View>

        <TouchableOpacity
          style={[
            styles.startButton,
            { backgroundColor: currentVirtue?.color || theme?.colors.primary },
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
          { borderColor: currentVirtue?.color || theme?.colors.primary },
          countdownNumberStyle,
        ]}
      >
        <Text
          style={[
            styles.countdownText,
            { color: currentVirtue?.color || theme?.colors.primary },
          ]}
        >
          {countdown}
        </Text>
      </Animated.View>
      <Text style={styles.countdownSubtext}>Preparing your meditation...</Text>
      <Text style={styles.breatheText}>Take a deep breath</Text>
    </View>
  );

  const renderActiveScreen = () => (
    <View style={styles.activeContainer}>
      <AnimatedParticles
        count={25}
        color={currentVirtue?.color || theme?.colors.primary}
        speed={0.6}
        radius={2.5}
        anim={pulseAnim}
      />

      <AnimatedCircularProgress
        size={250}
        width={4}
        fill={progressAnim}
        tintColor={currentVirtue?.color || theme?.colors.primary}
        backgroundColor={theme.colors.border}
        innerBackgroundColor="transparent"
        rotation={0}
        lineCap="round"
      >
        <View style={styles.breathCircleContainer}>
          {/* Base circle for better contrast */}
          <View style={[styles.baseCircle, { backgroundColor: theme.colors.background }]} />

          {/* Improved breathing circle with better visibility */}
          <Animated.View style={[styles.breathGradient, breathingCircleStyle]}>
            <LinearGradient
              colors={[
                `${currentVirtue?.color || theme?.colors.primary}90`,
                `${currentVirtue?.color || theme?.colors.primary}30`
              ]}
              style={StyleSheet.absoluteFill}
            />
          </Animated.View>
        </View>
      </AnimatedCircularProgress>
      <Animated.View style={[styles.breatheInstructionContainer, breatheTextStyle]}>
        <View style={styles.breatheInstructionBackground}>
          <Text style={styles.breatheInstruction}>
            {breathePhase === 'in' ? 'Breathe In' : breathePhase === 'hold' ? 'Keep still' : 'Breathe Out'}
          </Text>
        </View>
      </Animated.View>

      <Animated.View style={[styles.promptContainer, promptAnimStyle]}>
        <Text style={styles.promptText}>{currentPrompt}</Text>
        <View style={styles.promptProgress}>
          {currentVirtue?.prompts.map((_, i) => (
            <View
              key={i}
              style={[
                styles.progressDot,
                i === currentPromptIndex && styles.activeProgressDot,
                i === currentPromptIndex && { backgroundColor: currentVirtue.color },
              ]}
            />
          ))}
        </View>
      </Animated.View>
    </View>
  );

  const renderCompleteScreen = () => (
    <View style={styles.completeContainer}>
      <View style={styles.completeBanner}>
        <Text style={styles.completeTitle}>Meditation Complete</Text>
        <View style={styles.checkmarkContainer}>
          <View style={styles.checkCircle}>
            <Check size={36} color="#FFFFFF" />
          </View>
        </View>
        <Text style={styles.completeSubtitle}>Take a moment to reflect on your experience</Text>
      </View>

      <TouchableOpacity style={styles.bellButton} onPress={createChallenge}>
        <Animated.View style={[styles.bellIconContainer, bellButtonStyle]}>
          <Bell size={40} color={currentVirtue?.color || theme.colors.primary} />
        </Animated.View>
        <Text style={styles.bellText}>Activate Daily Challenge</Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.challengeSummaryContainer}
        onPress={() => setChallengeExpanded(!challengeExpanded)}
      >
        <Text style={styles.challengeSummaryTitle}>Your Selected Challenge:</Text>
        <View style={styles.challengeSummaryCard}>
          <LinearGradient
            colors={[`${currentVirtue?.color}15`, `${currentVirtue?.color}05`]}
            style={StyleSheet.absoluteFill}
          />
          <Text style={styles.challengeSummaryText}>{selectedChallenge?.title}</Text>
          <Text style={styles.challengeDuration}>
            For the next {selectedTime} {selectedTime === 1 ? 'hour' : 'hours'}
          </Text>

          {challengeExpanded && (
            <View style={styles.expandedChallengeInfo}>
              <Text style={styles.expandedChallengeDescription}>
                {selectedChallenge?.description}
              </Text>
              {selectedVirtue && (
                <View style={styles.virtueTagContainer}>
                  <View style={[styles.virtueTag, { backgroundColor: `${currentVirtue?.color}20` }]}>
                    {currentVirtue?.icon && <currentVirtue.icon size={14} color={currentVirtue?.color} />}
                    <Text style={[styles.virtueTagText, { color: currentVirtue?.color }]}>
                      {currentVirtue?.name}
                    </Text>
                  </View>
                </View>
              )}
            </View>
          )}
        </View>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      {meditationState === MeditationState.SETUP && (
        <View style={styles.header}>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme?.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Daily Meditation</Text>
          <View style={{ width: 24 }} />
        </View>
      )}

      {meditationState === MeditationState.SETUP && renderSetupScreen()}
      {meditationState === MeditationState.COUNTDOWN && renderCountdownScreen()}
      {meditationState === MeditationState.ACTIVE && renderActiveScreen()}
      {meditationState === MeditationState.COMPLETE && renderCompleteScreen()}
    </View>
  );
};

const createStyles = (theme: Theme, currentVirtue: any) =>
  StyleSheet.create({
    container: { flex: 1, backgroundColor: theme?.colors.background },
    header: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: theme?.spacing.md,
      paddingVertical: theme?.spacing.lg,
      borderBottomWidth: 1,
      borderBottomColor: theme?.colors.border,
    },
    headerTitle: { ...theme?.typography.heading.medium, color: theme?.colors.text.primary },
    backButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      justifyContent: 'center',
      alignItems: 'center',
    },
    scrollContainer: { flex: 1 },
    setupContainer: { padding: theme?.spacing.md },
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
      backgroundColor: theme?.colors.surface,
      marginBottom: theme?.spacing.sm,
    },
    selectedVirtueButton: { borderWidth: 2, backgroundColor: theme?.colors.background },
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
    timeContainer: { flexDirection: 'row', justifyContent: 'space-between' },
    timeButton: {
      flex: 1,
      paddingVertical: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
      alignItems: 'center',
      backgroundColor: theme?.colors.surface,
      marginHorizontal: theme?.spacing.xs,
    },
    selectedTimeButton: { borderWidth: 2, backgroundColor: theme?.colors.background },
    timeButtonContent: { flexDirection: 'row', alignItems: 'center', gap: 4 },
    timeText: { ...theme?.typography.body.sans, fontWeight: '600', color: theme?.colors.text.primary },
    soundContainer: { flexDirection: 'row', justifyContent: 'space-between' },
    soundButton: {
      flex: 1,
      paddingVertical: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
      alignItems: 'center',
      backgroundColor: theme?.colors.surface,
      marginHorizontal: theme?.spacing.xs,
    },
    selectedSoundButton: { borderWidth: 2, backgroundColor: theme?.colors.background },
    soundButtonContent: { flexDirection: 'row', alignItems: 'center', gap: 4 },
    soundText: { ...theme?.typography.body.sans, fontWeight: '600', color: theme?.colors.text.primary },
    challengeContainer: { gap: theme?.spacing.sm },
    challengeButton: {
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
      backgroundColor: theme?.colors.surface,
      overflow: 'hidden',
    },
    selectedChallengeButton: { borderWidth: 2 },
    challengeGradient: { borderRadius: theme?.borderRadius.md - 1 },
    challengeTitle: {
      ...theme?.typography.body.sans,
      fontWeight: '600',
      color: theme?.colors.text.primary,
      marginBottom: 4,
    },
    challengeDescription: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
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
    startButton: {
      marginVertical: theme?.spacing.xl,
      paddingVertical: theme?.spacing.md,
      paddingHorizontal: theme?.spacing.xl,
      borderRadius: theme?.borderRadius.lg,
      alignItems: 'center',
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.2, shadowRadius: 8 },
        android: { elevation: 6 },
      }),
    },
    startButtonText: {
      ...theme?.typography.body.sans,
      fontWeight: '700',
      color: '#FFFFFF',
      fontSize: 16,
    },
    countdownContainer: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      padding: theme?.spacing.lg
    },
    countdownCircle: {
      width: 160,
      height: 160,
      borderRadius: 80,
      borderWidth: 4,
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: theme?.spacing.xl,
      backgroundColor: `${theme?.colors.background}E6`,
    },
    countdownText: {
      ...theme?.typography.heading.large,
      fontSize: 72,
      fontWeight: '700',
      textAlign: 'center',
      includeFontPadding: false,
      lineHeight: 80,
    },
    countdownSubtext: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.primary,
      fontSize: 18,
      marginBottom: theme?.spacing.md,
    },
    breatheText: { ...theme?.typography.caption.secondary, color: theme?.colors.text.secondary },
    activeContainer: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: theme?.spacing.lg,
      paddingTop: theme?.spacing.xl * 1.5
    },
    breathCircleContainer: {
      alignItems: 'center',
      justifyContent: 'center',
      width: '100%',
      height: '100%',
      position: 'relative',
    },
    baseCircle: {
      position: 'absolute',
      width: '90%',
      height: '90%',
      borderRadius: 1000,
      opacity: 0.9,
    },
    breathGradient: {
      width: '100%',
      height: '100%',
      borderRadius: 1000,
      overflow: 'hidden',
      position: 'absolute',
      borderWidth: 1,
      borderColor: `${currentVirtue?.color || theme?.colors.primary}40`,
    },
    breatheInstructionContainer: {
      width: '100%',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 10, // Ensure this is on top
    },
    breatheInstructionBackground: {
      backgroundColor: `${theme.colors.background}CC`, // More opaque background
      paddingHorizontal: 18,
      paddingVertical: 8,
      borderRadius: 18,
      borderWidth: 1,
      borderColor: `${currentVirtue?.color || theme?.colors.primary}40`,
      ...Platform.select({
        ios: {
          shadowColor: theme.colors.text.primary,
          shadowOffset: { width: 0, height: 1 },
          shadowOpacity: 0.2,
          shadowRadius: 3
        },
        android: { elevation: 2 },
      }),
    },
    breatheInstruction: {
      ...theme?.typography.body.sans,
      color: currentVirtue?.color || theme?.colors.primary,
      fontSize: 20,
      fontWeight: '700',
      minWidth: 170,
      textAlign: 'center',
      textShadowColor: 'rgba(255, 255, 255, 0.5)',
      textShadowOffset: { width: 0, height: 0 },
      textShadowRadius: 2,
    },
    promptContainer: {
      padding: theme?.spacing.lg,
      borderRadius: theme?.borderRadius.lg,
      backgroundColor: theme?.colors.surface,
      width: '100%',
      alignItems: 'center',
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1, shadowRadius: 4 },
        android: { elevation: 2 },
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
    promptProgress: { flexDirection: 'row', marginTop: theme?.spacing.md, gap: theme?.spacing.xs },
    progressDot: { width: 8, height: 8, borderRadius: 4, backgroundColor: theme?.colors.border },
    activeProgressDot: { width: 16 },
    completeContainer: { flex: 1, alignItems: 'center', justifyContent: 'space-between', padding: theme.spacing.lg },
    completeBanner: { width: '100%', alignItems: 'center', marginTop: theme.spacing.xl },
    completeTitle: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      marginVertical: theme.spacing.md,
    },
    completeSubtitle: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      textAlign: 'center',
    },
    bellButton: { alignItems: 'center' },
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
    challengeSummaryContainer: { width: '100%', marginBottom: theme.spacing.xl },
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
    challengeDuration: { ...theme.typography.caption.secondary, color: theme.colors.text.secondary },
    placeholderText: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      textAlign: 'center',
      paddingVertical: theme?.spacing.xl,
    },
    selectedVirtueCollapsed: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      backgroundColor: `${currentVirtue?.color || theme?.colors.primary}08`,
      marginBottom: theme?.spacing.md,
    },
    selectedVirtueContent: { flexDirection: 'row', alignItems: 'center', gap: theme?.spacing.md },
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
    checkmarkContainer: {
      marginVertical: theme.spacing.lg,
      alignItems: 'center',
    },
    checkCircle: {
      width: 70,
      height: 70,
      borderRadius: 35,
      backgroundColor: '#4CAF50',
      alignItems: 'center',
      justifyContent: 'center',
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.2, shadowRadius: 4 },
        android: { elevation: 4 },
      }),
    },
    expandedChallengeInfo: {
      marginTop: theme.spacing.md,
      paddingTop: theme.spacing.md,
      borderTopWidth: 1,
      borderTopColor: `${theme.colors.border}80`,
    },
    expandedChallengeDescription: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.md,
      lineHeight: 22,
    },
    virtueTagContainer: {
      flexDirection: 'row',
      flexWrap: 'wrap',
    },
    virtueTag: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingVertical: theme.spacing.xs,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.md,
      marginRight: theme.spacing.xs,
    },
    virtueTagText: {
      ...theme.typography.caption.secondary,
      fontWeight: '600',
      marginLeft: 4,
    },
    selectedChallengeCollapsed: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      backgroundColor: `${currentVirtue?.color || theme?.colors.primary}08`,
      marginBottom: theme?.spacing.md,
    },
    selectedChallengeContent: { flex: 1, marginRight: theme?.spacing.md },
    challengeDescriptionCollapsed: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginTop: theme?.spacing.xs,
    },
    changeChallengeButton: {
      paddingVertical: theme?.spacing.xs,
      paddingHorizontal: theme?.spacing.sm,
      borderRadius: theme?.borderRadius.sm,
      backgroundColor: theme?.colors.surface,
      borderWidth: 1,
      borderColor: theme?.colors.border,
    },
    changeChallengeText: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      fontWeight: '500',
    },
  });

export default MeditationScreen;