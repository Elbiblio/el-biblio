import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Platform,
  BackHandler,
  Modal,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinearGradient } from 'expo-linear-gradient';
import { observer } from 'mobx-react-lite';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import { MeditationSession, RootStackParamList, Virtue } from '@/types';
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
import { useAuthStore, useVirtueStore, useMeditationStore, useChallengeStore, useLeaderboardStore } from '@/stores/StoreProvider';
import * as Haptics from 'expo-haptics';
import { setAudioModeAsync } from 'expo-audio';
import { playMusic, stopMusic, playCue, playLoopByKey, stopByKey, SoundKey, playOneShotByKey } from '@/services/audio';
import BibleDBService from '@/utils/database';
import { bibleBooks } from '@/constants/bibleBooks';
import { DailyChallenge } from '@/types';
import { Challenge as ChallengeRecommendation } from '@/types/challenges';
import AnimatedCircularProgress from '@/components/AnimatedCircularProgress';
import AnimatedParticles from '@/components/AnimatedParticles';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { toast } from 'sonner-native';
import SmartPickCard from '@/components/SmartPickCard';
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
import { buildMeditationPlan, MeditationLevel, MeditationPlan, contemplativePractices } from '@/data/meditationPlans';
import MeditationSetupModal from '@/components/MeditationSetupModal';

const TIME_OPTIONS: number[] = [5, 10, 15, 20];
const ADVANCED_TIME_OPTIONS: number[] = [30, 45, 60];
const BREATH_PACE_OPTIONS = [
  { id: 'slow' as const, label: 'Slow', description: 'Steady and calming' },
  { id: 'medium' as const, label: 'Medium', description: 'Balanced rhythm' },
  { id: 'fast' as const, label: 'Fast', description: 'Energising cadence' },
];

const BREATH_CONFIG = {
  slow: { in: 5200, hold: 3000, out: 6000 },
  medium: { in: 4000, hold: 2000, out: 4800 },
  fast: { in: 2800, hold: 1500, out: 3200 },
};

const BREATH_LOOP_OPTIONS = [
  { id: 'loop-1', label: '1 loop', value: 1 },
  { id: 'loop-3', label: '3 loops', value: 3 },
  { id: 'loop-5', label: '5 loops', value: 5 },
  { id: 'loop-inf', label: 'Continuous', value: 'continuous' as const },
];

const CHANT_INSTRUMENTAL_MAP: Record<string, SoundKey | undefined> = {
  '10000-reasons': 'db/10000_reasons_instrumental.mp3',
  '10000-reasons-african': 'db/10000_reasons_instrumental.mp3',
  'be-still-my-soul': 'db/be_still_my_soul_instrumental.mp3',
  'soul-of-jesus-sanctify-me': 'db/anima_christi_instrumental.mp3',
  'oceans': 'db/oceans_instrumental.mp3',
};

const CHANT_LABEL_MAP: Record<string, string> = {
  '10000-reasons': '10,000 Reasons',
  '10000-reasons-african': '10,000 Reasons (African)',
  'be-still-my-soul': 'Be Still My Soul',
  'soul-of-jesus-sanctify-me': 'Soul of Jesus, Sanctify Me',
  'oceans': 'Oceans (Spirit Lead Me)',
};

const CHANT_VOICE_MAP: Record<string, SoundKey | undefined> = {
  '10000-reasons': 'db/10000_reasons.mp3',
  '10000-reasons-african': 'db/10000_reasons_african.mp3',
  'be-still-my-soul': 'db/be_still_my_soul.mp3',
  'soul-of-jesus-sanctify-me': 'db/anima_christi.mp3',
  'oceans': 'db/oceans_voice.mp3',
};

type MeditationGuide = {
  title: string;
  imagery: string;
  scripture: string;
  prompts: string[];
  declaration: string;
  leadIn: string;
  focus: string;
  breathInvitation: string;
  closingReminder: string;
  openReflection?: string;
  guidanceTips?: string[];
  stageNote?: string;
};

const determineMeditationLevel = (
  sessionCount: number,
  selectedMinutes: number | null
): MeditationLevel => {
  if (!selectedMinutes || sessionCount <= 2) {
    return 'foundation';
  }
  if (selectedMinutes >= 25 || sessionCount >= 8) {
    return 'deep';
  }
  return 'growth';
};

const composeMeditationGuide = (
  plan: MeditationPlan,
  virtueName?: string | null
): MeditationGuide => {
  const virtueLine = virtueName
    ? `Notice how this connects with ${virtueName.toLowerCase()} in your life today.`
    : 'Notice how this story meets your life today.';
  const prompts = [
    plan.reflectionPrompts[0],
    virtueLine,
    plan.reflectionPrompts[1],
    plan.reflectionPrompts[2],
    plan.reflectionPrompts[3],
  ].filter(Boolean) as string[];

  return {
    title: plan.title,
    imagery: plan.overview,
    scripture: plan.scripture,
    prompts: prompts.slice(0, 4),
    declaration: plan.closingReminder,
    leadIn: `Spend a moment with the ${plan.parable}. ${plan.overview}`,
    focus: plan.breathInvitation,
    breathInvitation: plan.breathInvitation,
    closingReminder: plan.closingReminder,
    openReflection: plan.openReflection,
    guidanceTips: plan.guidanceTips,
    stageNote: plan.stageNote,
  };
};

enum MeditationState {
  SETUP = 'setup',
  COUNTDOWN = 'countdown',
  ACTIVE = 'active',
  COMPLETE = 'complete',
}

const MeditationScreen = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const auth = useAuthStore();
  const { user } = auth;

  // Virtue store (MobX)
  const virtueStore = useVirtueStore();
  const { virtues } = virtueStore;
  // Meditation store (MobX)
  const meditationStore = useMeditationStore();
  const challengeStore = useChallengeStore();
  const leaderboardStore = useLeaderboardStore();
  const {
    selectedVirtue,
    selectedTime,
    selectedChallenge,
    meditationState,
    countdown,
    meditationTimer,
    selectedBackgroundSound,
    selectedStyle,
    centeringWord,
    chosenChantId,
    jesusPrayerPace,
  } = meditationStore.state;
  const {
    parableReadMode,
    centeringReadMode,
    centeringRepeatIntervalSec,
    chantReflectionPauseSec,
  } = meditationStore.state as any;
  const {
    setSelectedVirtue: setStoreSelectedVirtue,
    setSelectedTime: setStoreSelectedTime,
    setSelectedChallenge: setStoreSelectedChallenge,
    setSelectedBackgroundSound: setStoreSelectedBackgroundSound,
    setSelectedStyle: setStoreSelectedStyle,
    setCenteringWord: setStoreCenteringWord,
    setChosenChantId: setStoreChosenChantId,
    setJesusPrayerPace: setStoreJesusPrayerPace,
    setParableReadMode: setStoreParableReadMode,
    setCenteringReadMode: setStoreCenteringReadMode,
    setCenteringRepeatIntervalSec: setStoreCenteringRepeatIntervalSec,
    setChantReflectionPauseSec: setStoreChantReflectionPauseSec,
    startMeditation: startMeditationStore,
    decrementCountdown,
    incrementMeditationTimer,
    endMeditationSession,
  } = meditationStore;
  const [currentPromptIndex, setCurrentPromptIndex] = useState(0);
  const [showPrompt, setShowPrompt] = useState(false);
  const [breathePhase, setBreathePhase] = useState<'in' | 'hold' | 'out'>('in');
  const [challengeExpanded, setChallengeExpanded] = useState(false);
  const [showFirstTipModal, setShowFirstTipModal] = useState(false);
  const [showCustomTimeModal, setShowCustomTimeModal] = useState(false);
  const [selectedPace, setSelectedPace] = useState<'slow' | 'medium' | 'fast'>('medium');
  const [selectedBreathLoops, setSelectedBreathLoops] = useState<number | 'continuous'>('continuous');
  const [smartPickDismissed, setSmartPickDismissed] = useState(false);
  const pendingStartRef = useRef(false);

  // Animation values
  const fadeAnim = useSharedValue(1);
  const breatheTextOpacity = useSharedValue(0);
  const numberScale = useSharedValue(1);
  const numberOpacity = useSharedValue(1);
  const pulseAnim = useSharedValue(0);
  const progressAnim = useSharedValue(0);
  const promptOpacity = useSharedValue(0);
  const bellScale = useSharedValue(1);

  // Centralized audio service
  const isSpeaking = useRef(false);
  const preSessionPointsRef = useRef<number | null>(null);
  const congratulatedRef = useRef(false);

  // Refs for flow control
  const isEndingPhase = useRef(false);
  const hasReadChallenge = useRef(false);
  const hasStartedFinalCountdown = useRef(false);
  const firstTwoMinutesCompleted = useRef(false);

  // Load virtues on mount
  useEffect(() => {
    virtueStore.fetchVirtues();
  }, [virtueStore]);

  const goalVirtueId = selectedVirtue;
  const [showSetupModal, setShowSetupModal] = useState(false);
  const currentVirtue = React.useMemo(
    () => virtues?.find((v: Virtue) => v.id === selectedVirtue),
    [selectedVirtue, virtues]
  );
  const totalMeditationSeconds = React.useMemo(
    () => (selectedTime || 0) * 60,
    [selectedTime]
  );
  const promptInterval = totalMeditationSeconds > 0 ? Math.floor(totalMeditationSeconds / 4) : 0;
  const sessions = meditationStore.state.sessions;
  const completedSessions = React.useMemo(() => {
    if (!selectedVirtue) return sessions.length;
    return sessions.filter(session => session.virtue_id === selectedVirtue).length;
  }, [sessions, selectedVirtue]);
  const meditationGuide = React.useMemo(() => {
    const level = determineMeditationLevel(completedSessions, selectedTime);
    const challengeText = selectedChallenge?.title || selectedChallenge?.description || null;

    if (selectedStyle === 'centering') {
      const practice = contemplativePractices.find(p => p.id === 'centering-prayer');
      const word = centeringWord?.trim() || 'Jesus';
      const prompts = (practice?.focus ?? []).slice(0, 3);
      return {
        title: practice?.name || 'Centering Prayer',
        imagery: practice?.description || 'Choose a sacred word and rest quietly before God.',
        scripture: '',
        prompts,
        declaration: 'Return gently to your word whenever you are distracted.',
        leadIn: 'Settle your body. Allow your breath to find a natural rhythm.',
        focus: `Sacred word: ${word}`,
        breathInvitation: 'Breathe slowly and let your word bring you back to God\'s presence.',
        closingReminder: 'Close with gratitude for any subtle movements of the heart.',
        openReflection: practice?.guidance?.[0],
        guidanceTips: practice?.guidance,
        stageNote: undefined,
      } as MeditationGuide;
    }

    if (selectedStyle === 'jesus_prayer') {
      const practice = contemplativePractices.find(p => p.id === 'jesus-prayer');
      const prompts = (practice?.focus ?? []).slice(0, 3);
      return {
        title: practice?.name || 'Jesus Prayer',
        imagery: practice?.description || 'Pray the ancient phrase in rhythm with your breath.',
        scripture: '',
        prompts,
        declaration: 'Have mercy on me, a sinner.',
        leadIn: 'Match the prayer with your inhale and exhale gently.',
        focus: '“Lord Jesus Christ, Son of God, have mercy on me.”',
        breathInvitation: 'Inhale the first half, exhale the second half of the prayer.',
        closingReminder: 'Carry mercy with you into your next steps.',
        openReflection: practice?.guidance?.[0],
        guidanceTips: practice?.guidance,
        stageNote: undefined,
      } as MeditationGuide;
    }

    if (selectedStyle === 'chant') {
      const practice = contemplativePractices.find(p => p.id === 'taize-chant');
      const chantLabel = (() => {
        if (!chosenChantId) return 'your chosen chant';
        if (chosenChantId === '10000-reasons') return '10,000 Reasons';
        if (chosenChantId === 'be-still-my-soul') return 'Be Still My Soul';
        if (chosenChantId === 'soul-of-jesus-sanctify-me') return 'Soul of Jesus, Sanctify Me';
        return 'your chosen chant';
      })();
      const prompts = [
        'Repeat the refrain slowly and allow it to settle in your heart.',
        'Let the melody shape your breath and soften your thoughts.',
        'Rest in silence for a moment between repetitions.',
      ];
      return {
        title: practice?.name || 'Chant',
        imagery: practice?.description || 'Repeat short chants or scriptures set to simple melodies.',
        scripture: '',
        prompts,
        declaration: 'Let the refrain linger as you return to your day.',
        leadIn: 'Choose a comfortable posture and begin softly.',
        focus: `Chant: ${chantLabel}`,
        breathInvitation: 'Breathe with the flow of the chant.',
        closingReminder: 'Carry the refrain as a quiet prayer.',
        openReflection: practice?.guidance?.[0],
        guidanceTips: practice?.guidance,
        stageNote: undefined,
      } as MeditationGuide;
    }

    const plan = buildMeditationPlan({
      level,
      dateSeed: Date.now(),
      challengeText,
      sessionCount: completedSessions,
    });
    const virtueName = selectedStyle === 'virtue' ? currentVirtue?.name : undefined;
    const base = composeMeditationGuide(plan, virtueName);
    if (selectedStyle === 'virtue') {
      const v = currentVirtue?.name || 'this virtue';
      base.prompts = [
        `Where in my life am I lacking the most in ${v}?`,
        `What can I do today to grow and improve in ${v}?`,
        `Thank you Jesus for helping me acknowledge my deficiencies in ${v}, may the grace and strength of your Spirit renew me today to imitate you in ${v}. Amen.`,
      ];
    }
    return base;
  }, [
    completedSessions,
    selectedTime,
    selectedChallenge?.title,
    selectedChallenge?.description,
    currentVirtue?.name,
    selectedStyle,
    centeringWord,
    chosenChantId,
  ]);
  const currentPrompt = meditationGuide.prompts[currentPromptIndex] || meditationGuide.prompts[0];
  const isReadyToBegin = React.useMemo(() => {
    if (!selectedTime) return false;
    if (selectedStyle === 'virtue') return Boolean(selectedVirtue);
    return true;
  }, [selectedTime, selectedStyle, selectedVirtue]);

  const smartPickChallenge = React.useMemo(() => {
    if (smartPickDismissed) return null;
    if (meditationState !== MeditationState.COMPLETE) return null;
    if (selectedStyle !== 'virtue') return null;
    const exclude = [selectedChallenge?.id].filter(Boolean) as string[];
    return challengeStore.getRecommendedChallenge({
      preferredTheme: currentVirtue?.name,
      excludeIds: exclude,
      allowJoined: false,
    });
  }, [challengeStore, currentVirtue?.name, selectedChallenge?.id, smartPickDismissed, meditationState]);

  const handleSmartPickJoin = React.useCallback((challenge: ChallengeRecommendation) => {
    void (async () => {
      const success = await challengeStore.joinChallenge(challenge.id);
      if (success) {
        toast.success('Challenge added to your day');
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        setSmartPickDismissed(true);
        navigation.navigate('DailyChallengeScreen');
      }
    })();
  }, [challengeStore, navigation]);

  React.useEffect(() => {
    if (meditationState === MeditationState.SETUP) {
      setSmartPickDismissed(false);
    }
  }, [meditationState]);

  useEffect(() => {
    if (selectedTime == null) {
      setStoreSelectedTime(10);
    }
  }, []);

  const nudgeShownRef = useRef(false);
  useEffect(() => {
    if (
      meditationState === MeditationState.SETUP &&
      selectedStyle === 'virtue' &&
      !selectedVirtue &&
      !nudgeShownRef.current
    ) {
      nudgeShownRef.current = true;
      setShowSetupModal(true);
    }
  }, [meditationState, selectedStyle, selectedVirtue]);

  const styles = React.useMemo(
    () => createStyles(theme, currentVirtue),
    [theme, currentVirtue]
  );

  const [introCompleted, setIntroCompleted] = useState(false);

  // Configure audio mode (allow playback in silent mode)
  useEffect(() => {
    setAudioModeAsync({ playsInSilentMode: true }).catch(() => {});
    return () => {
      stopMusic('meditation');
      stopMusic('heartbeat');
      try {
        Object.values(CHANT_INSTRUMENTAL_MAP).forEach((key) => {
          if (key) stopByKey(key as any);
        });
      } catch {}
    };
  }, []);

  // Background sound preview and playback controller via audio service
  useEffect(() => {
    stopMusic('meditation');
    stopMusic('heartbeat');
    if (meditationState === MeditationState.SETUP || meditationState === MeditationState.ACTIVE) {
      if (!(selectedStyle === 'chant' && meditationState === MeditationState.ACTIVE)) {
        if (selectedBackgroundSound === 'ambient') playMusic('meditation', 0.6);
        if (selectedBackgroundSound === 'heartbeat') playMusic('heartbeat', 0.6);
      }
    }
    if (meditationState === MeditationState.COUNTDOWN || meditationState === MeditationState.COMPLETE) {
      stopMusic('meditation');
      stopMusic('heartbeat');
    }
  }, [selectedBackgroundSound, meditationState, selectedStyle]);

  // Play tick sound
  const playTickSound = () => { playCue('tickTock'); };

  // Speak prompt helper (moved above first use)
  const showAndSpeakPrompt = (index: number) => {
    setCurrentPromptIndex(index);
    setShowPrompt(true);
    promptOpacity.value = withTiming(1, { duration: 1000 });
    const introWord = index === 0 ? 'Begin' : 'Now';
    const prompt = meditationGuide.prompts[index] || meditationGuide.prompts[0];
    const declaration = meditationGuide.declaration;
    isSpeaking.current = true;
    Speech.speak(`${introWord}...`, {
      rate: 0.85,
      onDone: () => {
        setTimeout(() => {
          Speech.speak(prompt, {
            rate: 0.85,
            onDone: () => {
              isSpeaking.current = false;
              if (index === meditationGuide.prompts.length - 1 && !isEndingPhase.current) {
                setTimeout(() => {
                  Speech.speak(declaration, { rate: 0.85 });
                }, 1200);
              }
            },
          });
        }, 1000);
      },
    });
  };

  // Countdown speech helper (moved above first use)
  const speakCountdownNumber = (number: number) => {
    Speech.stop();
    if (number <= 3 && number > 0) {
      setTimeout(() => Speech.speak(`${number}`, { rate: 0.8 }), 100);
    } else if (number === 0) {
      setTimeout(() => Speech.speak('Close your eyes if you are able to do so...', {
        rate: 0.8,
        onDone: () => {
          setTimeout(() => {
            Speech.speak(meditationGuide.leadIn, {
              rate: 0.8,
              onDone: () => {
                setTimeout(() => {
                  Speech.speak(meditationGuide.focus, {
                    rate: 0.8,
                    onDone: () => {
                      const continueAfterParable = () => {
                        setTimeout(() => {
                          const breathIntro = meditationGuide.breathInvitation || 'Breathe in...';
                          const stageNote = meditationGuide.stageNote?.trim();
                          const openReflection = meditationGuide.openReflection?.trim();
                          // play bell
                          playCue('meditationBell');
                          setTimeout(() => {
                            Speech.speak(breathIntro, {
                              rate: 0.8,
                              onDone: () => {
                                const speakHoldPhase = () => {
                                  setTimeout(() => {
                                    Speech.speak('Keep still...', {
                                      rate: 0.8,
                                      onDone: () => {
                                        setTimeout(() => {
                                          Speech.speak('Breathe out...', {
                                            rate: 0.8,
                                            onDone: () => {
                                              setIntroCompleted(true);
                                              setBreathePhase('in');
                                            },
                                          });
                                        }, 4000);
                                      },
                                    });
                                  }, 4000);
                                };

                                if (stageNote || openReflection) {
                                  const insights = [stageNote, openReflection].filter((text): text is string => Boolean(text));
                                  const speakInsight = (i: number) => {
                                    if (i >= insights.length) {
                                      speakHoldPhase();
                                      return;
                                    }
                                    const delay = i === 0 ? 400 : 600;
                                    setTimeout(() => {
                                      Speech.speak(insights[i]!, {
                                        rate: 0.8,
                                        onDone: () => {
                                          speakInsight(i + 1);
                                        },
                                      });
                                    }, delay);
                                  };
                                  speakInsight(0);
                                } else {
                                  speakHoldPhase();
                                }
                              },
                            });
                          }, 500);
                        }, 1000);
                      };

                      if (selectedStyle === 'parable' && parableReadMode === 'aloud') {
                        readScriptureSlowly(meditationGuide.scripture).then(() => continueAfterParable());
                      } else {
                        continueAfterParable();
                      }
                    },
                  });
                }, 1000);
              },
            });
          }, 1000);
        },
      }), 2000);
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

  const animateBreathText = React.useCallback((phaseDuration: number) => {
    const fadeIn = Math.min(500, Math.max(250, phaseDuration * 0.25));
    const delay = Math.max(0, phaseDuration - fadeIn - 400);
    breatheTextOpacity.value = withSequence(
      withTiming(1, { duration: fadeIn, easing: Easing.out(Easing.quad) }),
      withDelay(delay, withTiming(0, { duration: 400, easing: Easing.inOut(Easing.quad) }))
    );
  }, [breatheTextOpacity]);

  const breathTimeoutsRef = useRef<Array<ReturnType<typeof setTimeout>>>([]);
  const virtueStagesRef = useRef<{ s1: boolean; s2: boolean }>({ s1: false, s2: false });
  const centeringIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const chantFlowStartedRef = useRef(false);
  const chantLoopTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (selectedStyle === 'jesus_prayer' && jesusPrayerPace) {
      setSelectedPace(jesusPrayerPace);
    }
  }, [selectedStyle, jesusPrayerPace]);

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      if (!(selectedStyle === 'chant' && meditationState === MeditationState.ACTIVE)) {
        const key = CHANT_INSTRUMENTAL_MAP[chosenChantId || ''];
        if (key) {
          try { await stopByKey(key); } catch {}
        }
      }
    };
    run();
    return () => { cancelled = true; };
  }, [selectedStyle, chosenChantId, meditationState]);

  useEffect(() => {
    breathTimeoutsRef.current.forEach(clearTimeout);
    breathTimeoutsRef.current = [];

    if (meditationState === MeditationState.ACTIVE && introCompleted) {
      const pace = BREATH_CONFIG[selectedPace];
      const loopsTarget = selectedBreathLoops === 'continuous' ? Infinity : Math.max(1, selectedBreathLoops);
      const phases: Array<'in' | 'hold' | 'out'> = ['in', 'hold', 'out'];
      let loopsCompleted = 0;
      let running = true;

      const schedulePhase = (phaseIndex: number) => {
        if (!running) return;
        const phase = phases[phaseIndex];
        setBreathePhase(phase);
        const phaseDuration = phase === 'in' ? pace.in : phase === 'hold' ? pace.hold : pace.out;
        animateBreathText(phaseDuration);

        if (phase === 'out' && !firstTwoMinutesCompleted.current) {
          playBellSound();
        }

        const timeout = setTimeout(() => {
          if (!running) return;
          const nextIndex = (phaseIndex + 1) % phases.length;
          if (nextIndex === 0) {
            loopsCompleted += 1;
            if (loopsTarget !== Infinity && loopsCompleted >= loopsTarget) {
              running = false;
              return;
            }
          }
          schedulePhase(nextIndex);
        }, phaseDuration);

        breathTimeoutsRef.current.push(timeout);
      };

      schedulePhase(0);

      const repeatCount = loopsTarget === Infinity ? -1 : loopsTarget;
      pulseAnim.value = withRepeat(
        withSequence(
          withTiming(1, { duration: pace.in, easing: Easing.inOut(Easing.quad) }),
          withTiming(1, { duration: pace.hold, easing: Easing.linear }),
          withTiming(0, { duration: pace.out, easing: Easing.inOut(Easing.quad) })
        ),
        repeatCount,
        false
      );

      return () => {
        running = false;
        breathTimeoutsRef.current.forEach(clearTimeout);
        breathTimeoutsRef.current = [];
      };
    }
  }, [meditationState, introCompleted, selectedPace, selectedBreathLoops, animateBreathText, pulseAnim, firstTwoMinutesCompleted]);

  // Enhanced breathing circle style with better animation match
  const breathingCircleStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pulseAnim.value, [0, 1], [0.7, 1.6]) }],
    opacity: interpolate(pulseAnim.value, [0, 1], [0.5, 0.9]),
  }));

  // Countdown logic (uses store state)
  useEffect(() => {
    let interval: number;
    if (meditationState === MeditationState.COUNTDOWN && countdown > 0) {
      // initial tick feedback
      playTickSound();
      animateCountdownNumber();
      speakCountdownNumber(countdown);
      interval = setInterval(() => {
        const next = Math.max(0, countdown - 1);
        // side effects tied to the number we announce
        if (next >= 0) {
          playTickSound();
          animateCountdownNumber();
          speakCountdownNumber(next);
        }
        // store will flip to ACTIVE when reaches 0
        decrementCountdown();
        if (next === 0) {
          progressAnim.value = 0;
        }
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [meditationState, countdown]);

  // Meditation timer and progress with end-session enhancements (rely on store timer)
  useEffect(() => {
    let interval: number;
    if (meditationState === MeditationState.ACTIVE && selectedTime) {
      showAndSpeakPrompt(0);
      firstTwoMinutesCompleted.current = false;
      hasReadChallenge.current = false;
      hasStartedFinalCountdown.current = false;
      isEndingPhase.current = false;
      virtueStagesRef.current = { s1: false, s2: false };
      
      interval = setInterval(() => {
        const newValue = meditationStore.state.meditationTimer;
        progressAnim.value = newValue / totalMeditationSeconds;
        
        if (newValue >= 120 && !firstTwoMinutesCompleted.current) {
          firstTwoMinutesCompleted.current = true;
        }
        
        if (selectedStyle === 'virtue') {
          const s1 = Math.floor(totalMeditationSeconds * 2 / 5);
          const s2 = Math.floor(totalMeditationSeconds * 4 / 5);
          if (!virtueStagesRef.current.s1 && newValue >= s1) {
            virtueStagesRef.current.s1 = true;
            showAndSpeakPrompt(1);
          }
          if (!virtueStagesRef.current.s2 && newValue >= s2) {
            virtueStagesRef.current.s2 = true;
            showAndSpeakPrompt(2);
          }
        } else {
          if (promptInterval > 0 && newValue % promptInterval === 0 && newValue < totalMeditationSeconds - 30) {
            const nextPromptIndex = Math.floor(newValue / promptInterval);
            if (nextPromptIndex < 4) showAndSpeakPrompt(nextPromptIndex);
          }
        }
        
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
                      Speech.speak(selectedChallenge.description, { rate: 0.85 });
                    }
                  });
                }
              }
            });
          }, 500);
        }
        
        if (totalMeditationSeconds - newValue <= 10 && !hasStartedFinalCountdown.current) {
          hasStartedFinalCountdown.current = true;
          if (isSpeaking.current) Speech.stop();
          
          const closingLine = meditationGuide.closingReminder || 'You resolve to do better today.';
          Speech.speak(closingLine, {
            rate: 0.85, onDone: () => {
              let countdownNumber = 10;
              playMeditationBellSound();
              const countdownInterval = setInterval(() => {
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
      }, 500);
    }
    return () => clearInterval(interval);
  }, [meditationState, selectedTime, promptInterval, totalMeditationSeconds, selectedChallenge, meditationGuide]);

  useEffect(() => {
    if (centeringIntervalRef.current) {
      clearInterval(centeringIntervalRef.current as any);
      centeringIntervalRef.current = null;
    }
    if (meditationState === MeditationState.ACTIVE && selectedStyle === 'centering' && introCompleted) {
      const intervalMs = Math.max(10, Math.min(30, centeringRepeatIntervalSec)) * 1000;
      centeringIntervalRef.current = setInterval(() => {
        const word = (centeringWord || 'Jesus').trim();
        if (centeringReadMode === 'aloud') {
          Speech.speak(word, {
            rate: 0.85,
            onDone: () => {
              playCue('meditationBell');
            },
          });
        } else {
          playCue('meditationBell');
        }
      }, intervalMs) as any;
    }
    return () => {
      if (centeringIntervalRef.current) {
        clearInterval(centeringIntervalRef.current as any);
        centeringIntervalRef.current = null;
      }
    };
  }, [meditationState, selectedStyle, introCompleted, centeringReadMode, centeringRepeatIntervalSec, centeringWord]);

  useEffect(() => {
    if (!(meditationState === MeditationState.ACTIVE && selectedStyle === 'chant' && introCompleted)) return;
    if (chantFlowStartedRef.current) return;
    chantFlowStartedRef.current = true;
    const voice = CHANT_VOICE_MAP[chosenChantId || ''];
    const instrumental = CHANT_INSTRUMENTAL_MAP[chosenChantId || ''];
    const startInstrumentalOrLoop = async () => {
      if (instrumental) {
        await playLoopByKey(instrumental, 0.6);
      } else if (voice) {
        const loop = async () => {
          await playOneShotByKey(voice);
          chantLoopTimeoutRef.current = setTimeout(() => {
            if (meditationState === MeditationState.ACTIVE && selectedStyle === 'chant') loop();
          }, Math.max(15, Math.min(60, chantReflectionPauseSec)) * 1000) as any;
        };
        loop();
      }
    };
    Speech.speak('Take a moment to reflect on how this hymn connects to your life.', {
      rate: 0.85,
      onDone: () => {
        if (voice) {
          playOneShotByKey(voice).then(() => startInstrumentalOrLoop());
        } else {
          startInstrumentalOrLoop();
        }
      },
    });
    return () => {
      chantFlowStartedRef.current = false;
      if (chantLoopTimeoutRef.current) {
        clearTimeout(chantLoopTimeoutRef.current);
        chantLoopTimeoutRef.current = null;
      }
    };
  }, [meditationState, selectedStyle, introCompleted, chosenChantId, chantReflectionPauseSec]);

  // Refresh points and bell animation on complete
  useEffect(() => {
    if (meditationState === MeditationState.COMPLETE) {
      playCue('successBell');
      bellScale.value = withRepeat(
        withSequence(
          withTiming(1.05, { duration: 1000 }),
          withTiming(1, { duration: 1000 })
        ),
        -1
      );
      if (!congratulatedRef.current && user?.id) {
        congratulatedRef.current = true;
        (async () => {
          const before = preSessionPointsRef.current;
          const stats = await leaderboardStore.fetchUserStats(user.id);
          const after = stats?.totalPoints ?? null;
          if (before != null && after != null && after > before) {
            const delta = after - before;
            toast.success(`Great job! +${delta} points earned today`);
          } else {
            toast.success('Meditation complete. Points updated.');
          }
        })();
      }
    } else if (meditationState === MeditationState.SETUP) {
      // reset congratulation guard when returning to setup
      congratulatedRef.current = false;
    }
  }, [meditationState]);

  // Handlers
  const readScriptureSlowly = React.useCallback(async (reference?: string) => {
    if (!reference) return;
    const m = reference.trim().match(/^([0-9I]{0,3}\s*[A-Za-z\. ]+?)\s+(\d+):(\d+)(?:-(\d+))?/);
    if (!m) return;
    const bookName = m[1].replace(/\.$/, '').trim();
    const chapter = parseInt(m[2], 10);
    const vStart = parseInt(m[3], 10);
    const vEnd = m[4] ? parseInt(m[4], 10) : vStart;
    const meta = bibleBooks.find(b => b.name.toLowerCase() === bookName.toLowerCase());
    if (!meta) return;
    try {
      const rows = await BibleDBService.getChapter('eng_rv_vpl', meta.abbreviation, chapter);
      const verses = rows.filter(r => r.verse >= vStart && r.verse <= vEnd).map(r => r.text).join(' ');
      const sentences = verses.split(/(?<=[\.!?])\s+/).filter(Boolean);
      for (const s of sentences) {
        await new Promise<void>((resolve) => {
          Speech.speak(s.trim(), { rate: 0.75, onDone: () => resolve() });
        });
        await new Promise(r => setTimeout(r, 1200));
      }
    } catch {}
  }, []);

  const startMeditation = async () => {
    const missingVirtue = selectedStyle === 'virtue' && !selectedVirtue;
    if (missingVirtue || !selectedTime) {
      fadeAnim.value = withSequence(withTiming(0.3, { duration: 200 }), withTiming(1, { duration: 200 }));
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    try {
      const seen = await AsyncStorage.getItem('med_first_tip_shown');
      if (!seen) {
        // show tips modal before starting
        pendingStartRef.current = true;
        setShowFirstTipModal(true);
        return;
      }
    } catch {}
    // capture points snapshot before session begins
    preSessionPointsRef.current = leaderboardStore.userStats?.totalPoints ?? null;
    progressAnim.value = 0;
    startMeditationStore();
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  // Store initializes itself; avoid re-initializing to prevent repeated API calls

  const endMeditation = () => {
    endMeditationSession();
    if (isSpeaking.current) Speech.stop();
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const createChallenge = async () => {
    if (!selectedChallenge) {
      navigation.navigate('DailyChallengeScreen');
      return;
    }
    const endTime = new Date();
    // Keep server as source of truth for points; only compute local end_time for UI
    endTime.setHours(endTime.getHours() + (selectedTime === 40 ? 24 : selectedTime === 15 ? 6 : 3));
    const challenge = { ...selectedChallenge, end_time: endTime.toISOString() };

    if (user) {
      // Do not calculate or set points on the client. Let the backend handle it.
      await meditationStore.joinChallenge(selectedChallenge.id);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      // Optionally, refresh user data here if auth store exposes a fetch method
      // await auth.refreshUser();
    }
    navigation.navigate('Home', { meditationComplete: true, challenge });
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
  const playBellSound = () => { playCue('bell'); };
  
  // Play meditation bell sound
  const playMeditationBellSound = () => { playCue('meditationBell'); };

  // Render functions
  const handleSelectTime = React.useCallback((minutes: number) => {
    setStoreSelectedTime(minutes);
    Haptics.selectionAsync();
    setShowCustomTimeModal(false);
  }, [setStoreSelectedTime]);

  const renderSetupScreen = () => (
    <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
      <Animated.View style={[styles.setupContainer, fadeAnimStyle]}>
        <View style={styles.guideCard}>
          <Text style={styles.guideTitle}>{meditationGuide.title}</Text>
          <Text style={styles.guideImagery}>{meditationGuide.imagery}</Text>
          {!!meditationGuide.scripture && <Text style={styles.guideScripture}>{meditationGuide.scripture}</Text>}
          <Text style={styles.guideFocus}>{meditationGuide.focus}</Text>
          {meditationGuide.stageNote && (
            <Text style={styles.guideStageNote}>{meditationGuide.stageNote}</Text>
          )}
          {meditationGuide.openReflection && (
            <Text style={styles.guideReflection}>{meditationGuide.openReflection}</Text>
          )}
        </View>

        <Text style={styles.sectionTitle}>YOUR MEDITATION</Text>
        <View style={styles.selectedVirtueCollapsed}>
          <View style={styles.selectedVirtueContent}>
            <Text style={[styles.virtueText, { color: currentVirtue?.color_code || theme?.colors.primary }]}>
              {selectedStyle === 'virtue' ? (currentVirtue?.name || 'Choose a virtue') :
                selectedStyle === 'centering' ? `Centering: ${centeringWord || 'Jesus'}` :
                selectedStyle === 'jesus_prayer' ? 'Jesus Prayer' :
                selectedStyle === 'chant' ? 'Chant' : 'Parable Meditation'}
            </Text>
          </View>
          <TouchableOpacity
            style={styles.changeVirtueButton}
            onPress={() => {
              setShowSetupModal(true);
              Haptics.selectionAsync();
            }}
          >
            <Text style={styles.changeVirtueText}>Customize</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>SESSION LENGTH</Text>
        <View style={styles.timeContainer}>
          {TIME_OPTIONS.map((option) => (
            <TouchableOpacity
              key={option}
              style={[
                styles.timeButton,
                selectedTime === option && styles.selectedTimeButton,
                selectedTime === option && {
                  borderColor: currentVirtue?.color_code || theme?.colors.primary,
                },
              ]}
              onPress={() => handleSelectTime(option)}
            >
              <View style={styles.timeButtonContent}>
                <Clock
                  size={16}
                  color={
                    selectedTime === option
                      ? currentVirtue?.color_code || theme?.colors.primary
                      : theme?.colors.text.secondary
                  }
                />
                <Text
                  style={[
                    styles.timeText,
                    selectedTime === option && {
                      color: currentVirtue?.color_code || theme?.colors.primary,
                    },
                  ]}
                >
                  {option} min
                </Text>
              </View>
            </TouchableOpacity>
          ))}
          <TouchableOpacity
            style={styles.customTimeButton}
            onPress={() => {
              Haptics.selectionAsync();
              setShowCustomTimeModal(true);
            }}
          >
            <Text style={styles.customTimeText}>Custom…</Text>
          </TouchableOpacity>
        </View>

        {selectedStyle === 'virtue' && (
          <>
            <Text style={styles.sectionTitle}>DAILY CHALLENGE</Text>
            <View style={styles.challengeContainer}>
              {selectedVirtue ? (
                selectedChallenge ? (
                  <View style={[
                    styles.selectedChallengeCollapsed,
                    { borderColor: currentVirtue?.color_code || theme?.colors.border }
                  ]}>
                    <View style={styles.selectedChallengeContent}>
                      <Text style={[
                        styles.challengeTitle,
                        { color: currentVirtue?.color_code || theme?.colors.primary }
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
                        setStoreSelectedChallenge(null);
                        Haptics.selectionAsync();
                      }}
                    >
                      <Text style={styles.changeChallengeText}>Change</Text>
                    </TouchableOpacity>
                  </View>
                ) : (
                  <Text style={styles.placeholderText}>
                    Optional: Select a challenge
                  </Text>
                )
              ) : (
                <Text style={styles.placeholderText}>
                  Choose a virtue to see challenge options
                </Text>
              )}
            </View>
          </>
        )}

        {!isReadyToBegin && (
          <Text style={styles.startHelper}>
            {selectedStyle === 'virtue' ? 'Select a virtue and session length to begin.' : 'Select a session length to begin.'}
          </Text>
        )}
        <TouchableOpacity
          style={[
            styles.startButton,
            {
              backgroundColor: currentVirtue?.color_code || theme?.colors.primary,
              opacity: isReadyToBegin ? 1 : 0.6,
            },
          ]}
          onPress={startMeditation}
          disabled={!isReadyToBegin}
          activeOpacity={isReadyToBegin ? 0.85 : 1}
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
          { borderColor: currentVirtue?.color_code || theme?.colors.primary },
          countdownNumberStyle,
        ]}
      >
        <Text
          style={[
            styles.countdownText,
            { color: currentVirtue?.color_code || theme?.colors.primary },
          ]}
        >
          {countdown}
        </Text>
      </Animated.View>
      <Text style={styles.countdownSubtext}>Preparing your meditation...</Text>
      <Text style={styles.breatheText}>Take a deep breath</Text>
    </View>
  );

  const formatTime = React.useCallback((seconds: number) => {
    const clamped = Math.max(0, seconds);
    const mins = Math.floor(clamped / 60);
    const secs = clamped % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }, []);

  const renderActiveScreen = () => {
    const totalSeconds = selectedTime ? selectedTime * 60 : null;
    const elapsedLabel = formatTime(meditationTimer);
    const totalLabel = totalSeconds ? formatTime(totalSeconds) : null;
    const isChant = selectedStyle === 'chant';
    const isCentering = selectedStyle === 'centering';
    const isJP = selectedStyle === 'jesus_prayer';
    const chantNow = chosenChantId ? (CHANT_LABEL_MAP[chosenChantId] || 'Chant') : 'Chant';

    return (
      <View style={styles.activeContainer}>
        <AnimatedParticles
          count={25}
          color={currentVirtue?.color_code || theme?.colors.primary}
          speed={0.6}
          radius={2.5}
          anim={pulseAnim}
        />

        <AnimatedCircularProgress
          size={250}
          width={4}
          fill={progressAnim}
          tintColor={currentVirtue?.color_code || theme?.colors.primary}
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
                  `${currentVirtue?.color_code || theme?.colors.primary}90`,
                  `${currentVirtue?.color_code || theme?.colors.primary}30`
                ]}
                style={StyleSheet.absoluteFill}
              />
            </Animated.View>

            <View pointerEvents="none" style={styles.timerLabelContainer}>
              <Text style={styles.timerElapsed}>{elapsedLabel}</Text>
              {totalLabel ? (
                <Text style={styles.timerTotal}>/ {totalLabel}</Text>
              ) : null}
            </View>
          </View>
        </AnimatedCircularProgress>
        {!isChant && (
          <Animated.View style={[styles.breatheInstructionContainer, breatheTextStyle]}>
            <View style={styles.breatheInstructionBackground}>
              <Text style={styles.breatheInstruction}>
                {isCentering
                  ? `Return to: ${centeringWord || 'Jesus'}`
                  : breathePhase === 'in' ? 'Breathe In' : breathePhase === 'hold' ? 'Keep still' : 'Breathe Out'}
              </Text>
            </View>
          </Animated.View>
        )}

        {!isChant && (
          <Animated.View style={[styles.promptContainer, promptAnimStyle]}>
            <Text style={styles.promptText}>{currentPrompt}</Text>
            <View style={styles.promptProgress}>
              {[1, 2, 3, 4].map((_, i) => (
                <View
                  key={i}
                  style={[
                    styles.progressDot,
                    i === currentPromptIndex && styles.activeProgressDot,
                    i === currentPromptIndex && { backgroundColor: currentVirtue?.color_code || theme?.colors.primary },
                  ]}
                />
              ))}
            </View>
          </Animated.View>
        )}

        {isJP && (
          <View style={styles.jpGuideContainer}>
            <Text style={[styles.jpPhrase, breathePhase === 'in' && styles.jpPhraseActive]}>Lord Jesus Christ</Text>
            <Text style={[styles.jpPhrase, breathePhase === 'hold' && styles.jpPhraseActive]}>Son of God</Text>
            <Text style={[styles.jpPhrase, breathePhase === 'out' && styles.jpPhraseActive]}>have mercy on me</Text>
          </View>
        )}

        <View style={styles.declarationContainer}>
          <Text style={styles.declarationLabel}>Declaration</Text>
          <Text style={styles.declarationText}>{meditationGuide.declaration}</Text>
        </View>

        {isChant && (
          <View style={styles.nowPlayingCard}>
            <Text style={styles.nowPlayingTitle}>Now Playing</Text>
            <Text style={styles.nowPlayingText}>{chantNow}</Text>
          </View>
        )}
      </View>
    );
  };

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

      {selectedStyle === 'virtue' && !smartPickDismissed && smartPickChallenge && (
        <View style={styles.smartPickWrapper}>
          <SmartPickCard
            challenge={smartPickChallenge}
            onPressJoin={handleSmartPickJoin}
            onPressDismiss={() => setSmartPickDismissed(true)}
            ctaLabel={smartPickChallenge.hasJoined ? 'View challenge' : 'Join challenge'}
          />
        </View>
      )}

      {selectedStyle === 'virtue' && (
        <TouchableOpacity style={styles.bellButton} onPress={createChallenge}>
          <Animated.View style={[styles.bellIconContainer, bellButtonStyle]}>
            <Bell size={40} color={currentVirtue?.color_code || theme.colors.primary} />
          </Animated.View>
          <Text style={styles.bellText}>Activate Daily Challenge</Text>
        </TouchableOpacity>
      )}

      {selectedStyle === 'virtue' && selectedChallenge && <TouchableOpacity
        style={styles.challengeSummaryContainer}
        onPress={() => setChallengeExpanded(!challengeExpanded)}
        activeOpacity={0.85}
      >
        <View style={styles.challengeSummaryHeader}>
          <Text style={styles.challengeSummaryTitle}>Your Selected Challenge</Text>
          <Text style={styles.challengeToggleLabel}>{challengeExpanded ? 'Hide details ▴' : 'Tap for details ▾'}</Text>
        </View>
        <View style={styles.challengeSummaryCard}>
          <LinearGradient
            colors={[`${currentVirtue?.color_code}15`, `${currentVirtue?.color_code}05`]}
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
                  <View style={[styles.virtueTag, { backgroundColor: `${currentVirtue?.color_code}20` }]}>
                    <Text style={[styles.virtueTagText, { color: currentVirtue?.color_code }] }>
                      {currentVirtue?.name}
                    </Text>
                  </View>
                </View>
              )}
            </View>
          )}
        </View>
      </TouchableOpacity>
      }
    </View>
  );

  return (
    <View style={styles.container}>
      <MeditationSetupModal
        visible={showSetupModal}
        onClose={() => setShowSetupModal(false)}
        virtues={virtues}
        initialValues={{
          style: selectedStyle,
          sound: selectedBackgroundSound,
          virtueId: selectedVirtue,
          centeringWord: centeringWord ?? undefined,
          jesusPrayerPace: jesusPrayerPace,
          chantId: chosenChantId ?? undefined,
          parableReadMode: (meditationStore.state as any).parableReadMode,
          centeringReadMode: (meditationStore.state as any).centeringReadMode,
          centeringRepeatIntervalSec: (meditationStore.state as any).centeringRepeatIntervalSec,
          chantReflectionPauseSec: (meditationStore.state as any).chantReflectionPauseSec,
        }}
        onStart={(values) => {
          setStoreSelectedStyle(values.style);
          setStoreSelectedBackgroundSound(values.sound ?? null);
          setStoreSelectedVirtue(values.virtueId ?? null);
          setStoreCenteringWord(values.centeringWord ?? null);
          setStoreJesusPrayerPace(values.jesusPrayerPace ?? 'medium');
          setStoreChosenChantId(values.chantId ?? null);
          setStoreParableReadMode(values.parableReadMode ?? 'silent');
          setStoreCenteringReadMode(values.centeringReadMode ?? 'silent');
          setStoreCenteringRepeatIntervalSec(values.centeringRepeatIntervalSec ?? 15);
          setStoreChantReflectionPauseSec(values.chantReflectionPauseSec ?? 20);
          Haptics.selectionAsync();
        }}
      />
      {/* First-time meditation tips modal */}
      <Modal visible={showFirstTipModal} animationType="fade" transparent onRequestClose={() => setShowFirstTipModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Quick Tips</Text>
            <Text style={styles.modalText}>• Switch on Do Not Disturb to avoid distractions
            {'\n'}• If it’s safe, gently close your eyes
            {'\n'}• Listen to the voice guide and breathe calmly</Text>
            <View style={styles.modalActions}>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: theme.colors.surface, borderWidth: 1, borderColor: theme.colors.border }]}
                onPress={() => {
                  setShowFirstTipModal(false);
                  pendingStartRef.current = false;
                }}
              >
                <Text style={[styles.modalBtnText, { color: theme.colors.text.primary }]}>Maybe Later</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: theme.colors.primary }]}
                onPress={async () => {
                  try { await AsyncStorage.setItem('med_first_tip_shown', '1'); } catch {}
                  setShowFirstTipModal(false);
                  if (pendingStartRef.current) {
                    pendingStartRef.current = false;
                    progressAnim.value = 0;
                    startMeditationStore();
                    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                  }
                }}
              >
                <Text style={[styles.modalBtnText, { color: '#FFF' }]}>Got it, Begin</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
      <Modal visible={showCustomTimeModal} animationType="fade" transparent onRequestClose={() => setShowCustomTimeModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.customModalCard}>
            <Text style={styles.modalTitle}>Choose session length</Text>
            <View style={styles.customOptionsWrap}>
              {ADVANCED_TIME_OPTIONS.map((option) => (
                <TouchableOpacity
                  key={option}
                  style={styles.customOptionButton}
                  onPress={() => handleSelectTime(option)}
                >
                  <Text style={styles.customOptionText}>{option} min</Text>
                </TouchableOpacity>
              ))}
            </View>
            <TouchableOpacity
              style={[styles.modalBtn, styles.customModalClose]}
              onPress={() => setShowCustomTimeModal(false)}
            >
              <Text style={[styles.modalBtnText, { color: theme.colors.text.primary }]}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
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

const createStyles = (theme: Theme, currentVirtue: Virtue | undefined) =>
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
    guideCard: {
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.lg,
      backgroundColor: theme?.colors.surface,
      borderWidth: 1,
      borderColor: theme?.colors.border,
      marginBottom: theme?.spacing.lg,
      gap: theme?.spacing.sm,
    },
    guideTitle: {
      ...theme?.typography.heading.small,
      color: theme?.colors.text.primary,
      fontWeight: '700',
    },
    guideImagery: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      lineHeight: 22,
    },
    guideScripture: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.primary,
      fontStyle: 'italic',
    },
    guideFocus: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.primary,
      fontWeight: '600',
    },
    guideStageNote: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      fontStyle: 'italic',
    },
    guideReflection: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.primary,
      marginTop: theme?.spacing.xs,
    },
    guideTipsContainer: {
      marginTop: theme?.spacing.sm,
      gap: theme?.spacing.xs,
    },
    guideTipText: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
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
    timeContainer: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      justifyContent: 'flex-start',
      marginRight: -theme?.spacing.sm,
    },
    timeButton: {
      width: '31%', // 3 per row
      paddingVertical: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
      alignItems: 'center',
      backgroundColor: theme?.colors.surface,
      marginRight: theme?.spacing.sm,
      marginBottom: theme?.spacing.sm,
    },
    selectedTimeButton: { borderWidth: 2, backgroundColor: theme?.colors.background },
    timeButtonContent: { flexDirection: 'row', alignItems: 'center' },
    timeText: { ...theme?.typography.body.sans, fontWeight: '600', color: theme?.colors.text.primary, marginLeft: 6 },
    customTimeButton: {
      paddingVertical: theme?.spacing.md,
      paddingHorizontal: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
      backgroundColor: theme?.colors.surface,
      justifyContent: 'center',
      alignItems: 'center',
      marginBottom: theme?.spacing.sm,
    },
    customTimeText: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      fontWeight: '600',
    },
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
    soundButtonContent: { flexDirection: 'row', alignItems: 'center', gap: theme?.spacing.sm },
    soundTextGroup: { flex: 1 },
    soundText: { ...theme?.typography.body.sans, fontWeight: '600', color: theme?.colors.text.primary },
    soundDescription: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginTop: 2,
    },
    paceContainer: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      gap: theme?.spacing.sm,
      marginTop: theme?.spacing.sm,
      marginBottom: theme?.spacing.sm,
    },
    paceButton: {
      flex: 1,
      paddingVertical: theme?.spacing.md,
      paddingHorizontal: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
      alignItems: 'center',
      backgroundColor: theme?.colors.surface,
    },
    paceButtonActive: { borderWidth: 2 },
    paceButtonText: {
      ...theme?.typography.body.sans,
      fontWeight: '600',
      color: theme?.colors.text.primary,
    },
    paceDescription: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginTop: 4,
      textAlign: 'center',
    },
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
    startHelper: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginBottom: theme?.spacing.sm,
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
      width: 210,
      height: 210,
      borderRadius: 105,
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
    },
    baseCircle: {
      width: '100%',
      height: '100%',
      borderRadius: 105,
    },
    timerLabelContainer: {
      position: 'absolute',
      alignItems: 'center',
      justifyContent: 'center',
    },
    timerElapsed: {
      ...theme?.typography.heading.small,
      color: theme?.colors.text.primary,
      fontWeight: '700',
    },
    dismissText: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginTop: 2,
    },
    smartPickWrapper: {
      width: '100%',
      marginBottom: theme?.spacing.lg,
    },
    timerTotal: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginTop: 2,
    },
    breathGradient: {
      width: '100%',
      height: '100%',
      borderRadius: 1000,
      overflow: 'hidden',
      position: 'absolute',
      borderWidth: 1,
      borderColor: `${currentVirtue?.color_code || theme?.colors.primary}40`,
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
      borderColor: `${currentVirtue?.color_code || theme?.colors.primary}40`,
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
      color: currentVirtue?.color_code || theme?.colors.primary,
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
    declarationContainer: {
      width: '100%',
      marginTop: theme?.spacing.lg,
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      backgroundColor: `${theme?.colors.surface}E6`,
      borderWidth: 1,
      borderColor: `${theme?.colors.border}80`,
      gap: theme?.spacing.sm,
    },
    declarationLabel: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      textTransform: 'uppercase',
      letterSpacing: 1,
      fontWeight: '600',
    },
    declarationText: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.primary,
      lineHeight: 22,
    },
    jpGuideContainer: {
      alignItems: 'center',
      gap: theme?.spacing.xs,
      marginTop: theme?.spacing.sm,
    },
    jpPhrase: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
    },
    jpPhraseActive: {
      color: currentVirtue?.color_code || theme?.colors.primary,
      fontWeight: '700',
    },
    nowPlayingCard: {
      marginTop: theme?.spacing.md,
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1,
      borderColor: theme?.colors.border,
      backgroundColor: theme?.colors.surface,
      alignItems: 'center',
    },
    nowPlayingTitle: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginBottom: 4,
    },
    nowPlayingText: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.primary,
      fontWeight: '700',
    },
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
    challengeSummaryContainer: {
      width: '100%',
      marginBottom: theme.spacing.xl,
    },
    challengeSummaryHeader: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      paddingHorizontal: theme.spacing.sm,
      marginBottom: theme.spacing.xs,
    },
    challengeSummaryTitle: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    challengeToggleLabel: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
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
      backgroundColor: `${currentVirtue?.color_code || theme?.colors.primary}08`,
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
    retryButton: {
      backgroundColor: theme.colors.primary,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.lg,
      borderRadius: theme.borderRadius.full,
      marginTop: theme.spacing.md,
    },
    retryButtonText: {
      color: '#FFF',
    },
    modalOverlay: {
      flex: 1,
      backgroundColor: 'rgba(0,0,0,0.45)',
      alignItems: 'center',
      justifyContent: 'center',
      padding: theme.spacing.lg,
    },
    modalCard: {
      width: '100%',
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.xl,
      padding: theme.spacing.lg,
      borderWidth: 1,
      borderColor: theme.colors.border,
      ...Platform.select({ ios: { shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 16, shadowOffset: { width: 0, height: 8 } }, android: { elevation: 8 } }),
    },
    modalTitle: {
      ...theme.typography.heading.medium,
      color: theme.colors.text.primary,
      textAlign: 'center',
      marginBottom: theme.spacing.sm,
    },
    modalText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
      textAlign: 'center',
      lineHeight: 22,
      marginBottom: theme.spacing.md,
    },
    modalActions: {
      flexDirection: 'row',
      justifyContent: 'space-between',
    },
    customModalCard: {
      width: '100%',
      backgroundColor: theme.colors.surface,
      borderRadius: theme.borderRadius.xl,
      padding: theme.spacing.lg,
      borderWidth: 1,
      borderColor: theme.colors.border,
      gap: theme.spacing.md,
    },
    customOptionsWrap: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      gap: theme.spacing.sm,
    },
    customOptionButton: {
      flex: 1,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.md,
      backgroundColor: `${theme.colors.primary}12`,
      alignItems: 'center',
      borderWidth: 1,
      borderColor: `${theme.colors.primary}30`,
    },
    customOptionText: {
      ...theme.typography.body.sans,
      color: theme.colors.primary,
      fontWeight: '600',
    },
    customModalClose: {
      backgroundColor: `${theme.colors.primary}12`,
      borderWidth: 1,
      borderColor: theme.colors.border,
    },
    modalBtn: {
      flex: 1,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      alignItems: 'center',
    },
    modalBtnText: {
      ...theme.typography.body.sans,
      fontWeight: '700',
    },
    selectedChallengeCollapsed: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: theme?.spacing.md,
      borderRadius: theme?.borderRadius.md,
      borderWidth: 1.5,
      backgroundColor: `${currentVirtue?.color_code || theme?.colors.primary}08`,
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

export default observer(MeditationScreen);