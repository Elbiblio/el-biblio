import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  BackHandler,
  Alert,
  Modal,
  AppState,
  AppStateStatus,
} from 'react-native';

import { useNavigation, useFocusEffect } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import MeditationCompleteView from '@/components/MeditationCompleteView';
import { observer } from 'mobx-react-lite';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import { useDailyPathStore } from '@/stores/StoreProvider';
import { RootStackParamList, Virtue } from '@/types';

import {
  ArrowLeft,
  Clock,
} from '@/components/Icons';
import { useAuthStore, useVirtueStore, useMeditationStore, useChallengeStore, useLeaderboardStore } from '@/stores/StoreProvider';
import { useBibleStore } from '@/stores/BibleStore';
import * as Haptics from 'expo-haptics';
import { useKeepAwake } from 'expo-keep-awake';
import { playMusic, stopMusic, preloadMusicCue, setExclusiveAudioMode, setMixingAudioMode } from '@/services/audio';
import { clearSpeechQueue } from '@/services/AudioCoordinator';
import { MeditationOrchestrator } from '@/services/MeditationOrchestrator';
import type { MeditationGuide as OrchestratorMeditationGuide } from '@/services/MeditationOrchestrator';
import { getChantById } from '@/data/chantTracks';
import { Challenge as ChallengeRecommendation } from '@/types/challenges';
import AnimatedCircularProgress from '@/components/AnimatedCircularProgress';
import AnimatedParticles from '@/components/AnimatedParticles';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { toast } from 'sonner-native';
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
import MeditationSetupModal from '@/components/MeditationSetupModal';
import { MaterialIcons } from '@expo/vector-icons';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { createStyles } from './MeditationScreenStyles';

const TIME_OPTIONS: number[] = [5, 10, 15, 20];
const ADVANCED_TIME_OPTIONS: number[] = [30, 45, 60];

enum MeditationState {
  SETUP = 'setup',
  COUNTDOWN = 'countdown',
  ACTIVE = 'active',
  PAUSED = 'paused',
  COMPLETE = 'complete',
  IDLE = 'idle',
}

const MeditationScreen = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const auth = useAuthStore();
  const { user } = auth;
  const { isOffline } = useNetworkStatus();

  // Store references
  const virtueStore = useVirtueStore();
  const { virtues } = virtueStore;
  const meditationStore = useMeditationStore();
  const challengeStore = useChallengeStore();
  const leaderboardStore = useLeaderboardStore();
  const bibleStore = useBibleStore();

  // Destructure state once
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
    isPreviewingSound,
  } = meditationStore.state;

  const {
    parableReadMode,
    centeringReadMode,
    centeringRepeatIntervalSec,
    chantReflectionPauseSec,
  } = meditationStore.state as any;

  // Core state
  const [currentPromptIndex, setCurrentPromptIndex] = useState(0);
  const [challengeExpanded, setChallengeExpanded] = useState(false);
  const [showFirstTipModal, setShowFirstTipModal] = useState(false);
  const [showCustomTimeModal, setShowCustomTimeModal] = useState(false);
  const [smartPickDismissed, setSmartPickDismissed] = useState(false);
  const [showSetupModal, setShowSetupModal] = useState(false);

  // Refs for persistent data
  const pendingStartRef = useRef(false);
  const preSessionPointsRef = useRef<number | null>(null);
  const congratulatedRef = useRef(false);
  const hasMarkedComplete = useRef(false);
  const spokenPromptsRef = useRef<Set<number>>(new Set());
  const orchestratorRef = useRef<MeditationOrchestrator | null>(null);
  const countdownStartedRef = useRef(false);
  const nudgeShownRef = useRef(false);
  const activatedRef = useRef(false);
  const previewKeyRef = useRef<'meditation' | 'heartbeat' | null>(null);
  
  // Single source of truth for orchestrated guide
  const [orchestratedGuide, setOrchestratedGuide] = useState<OrchestratorMeditationGuide | null>(null);

  // Animation values
  const fadeAnim = useSharedValue(1);
  const numberScale = useSharedValue(1);
  const numberOpacity = useSharedValue(1);
  const pulseAnim = useSharedValue(0);
  const progressAnim = useSharedValue(0);
  const promptOpacity = useSharedValue(0);
  const bellScale = useSharedValue(1);
  const breathPhaseIndex = useSharedValue(0);
  const breatheTextOpacity = useSharedValue(0);

  // Load virtues on mount
  useEffect(() => {
    virtueStore.fetchVirtues();
  }, [virtueStore]);

  // Computed values - only calculate when needed
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
  const dailyPathStore = useDailyPathStore();
  const completedSessions = React.useMemo(() => {
    if (!selectedVirtue) return sessions.length;
    return sessions.filter(session => session.virtue_id === selectedVirtue).length;
  }, [sessions, selectedVirtue]);

  // Build fallback guide only (orchestrator builds real one)
  const fallbackGuide = React.useMemo(() => {
    if (meditationState !== MeditationState.SETUP) {
      return null; // Don't compute during active session
    }
    
    return MeditationOrchestrator.buildGuide({
      selectedStyle,
      selectedMinutes: selectedTime ?? null,
      selectedChallenge,
      sessionCount: completedSessions,
      virtueName: selectedStyle === 'virtue' ? (currentVirtue?.name || null) : null,
      centeringWord,
      chosenChantId: chosenChantId ?? null,
    });
  }, [
    meditationState,
    selectedStyle,
    selectedTime,
    selectedChallenge,
    completedSessions,
    currentVirtue?.name,
    centeringWord,
    chosenChantId,
  ]);

  const guideForUI = orchestratedGuide ?? fallbackGuide ?? {
    title: 'Meditation',
    imagery: '',
    scripture: '',
    prompts: [''],
    declaration: '',
    leadIn: '',
    focus: '',
    breathInvitation: '',
    closingReminder: '',
  };

  const currentPrompt = guideForUI.prompts[currentPromptIndex] || guideForUI.prompts[0];

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
  }, [challengeStore, currentVirtue?.name, selectedChallenge?.id, smartPickDismissed, meditationState, selectedStyle]);

  const styles = React.useMemo(
    () => createStyles(theme, currentVirtue),
    [theme, currentVirtue]
  );

  // Keep screen awake during active meditation
  useKeepAwake('meditation')

  // Use exclusive audio only while Meditation screen is focused
  useFocusEffect(
    React.useCallback(() => {
      setExclusiveAudioMode().catch(() => {});
      return () => {
        setMixingAudioMode().catch(() => {});
      };
    }, [])
  );

  useEffect(() => {
    meditationStore.setOfflineStatus(isOffline);
  }, [isOffline, meditationStore]);

  // Set default time
  useEffect(() => {
    if (selectedTime == null) {
      meditationStore.setSelectedTime(10);
    }
  }, [selectedTime]);

  // Auto-show setup modal for virtue mode
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

  // Reset smart pick on setup
  React.useEffect(() => {
    if (meditationState === MeditationState.SETUP) {
      setSmartPickDismissed(false);
    }
  }, [meditationState]);

  // App state listener - pause on background
  useEffect(() => {
    const onChange = (state: AppStateStatus) => {
      if (state === 'background' && 
          (meditationState === MeditationState.ACTIVE || meditationState === MeditationState.COUNTDOWN)) {
        meditationStore.pause();
        orchestratorRef.current?.pause();
      }
    };
    const sub = AppState.addEventListener('change', onChange);
    return () => { try { sub.remove(); } catch {} };
  }, [meditationState, meditationStore]);

  useEffect(() => {
    if (meditationState !== MeditationState.SETUP || selectedStyle === 'chant') {
      if (previewKeyRef.current) {
        try { stopMusic(previewKeyRef.current); } catch {}
        previewKeyRef.current = null;
      }
      return;
    }

    const desiredKey: 'meditation' | 'heartbeat' | null = isPreviewingSound
      ? (selectedBackgroundSound === 'ambient' ? 'meditation'
        : selectedBackgroundSound === 'heartbeat' ? 'heartbeat' : null)
      : null;

    if (desiredKey !== previewKeyRef.current) {
      if (previewKeyRef.current) {
        try { stopMusic(previewKeyRef.current); } catch {}
      }
      if (desiredKey) {
        try { playMusic(desiredKey, 0.6); } catch {}
      }
      previewKeyRef.current = desiredKey;
    }

    return () => {
      if (previewKeyRef.current) {
        try { stopMusic(previewKeyRef.current); } catch {}
        previewKeyRef.current = null;
      }
    };
  }, [meditationState, isPreviewingSound, selectedBackgroundSound, selectedStyle]);


  // Ensure setup preview is stopped and preload background when entering countdown
  useEffect(() => {
    if (meditationState === MeditationState.COUNTDOWN) {
      try { stopMusic('meditation'); } catch {}
      try { stopMusic('heartbeat'); } catch {}
      if (selectedStyle !== 'chant') {
        if (selectedBackgroundSound === 'ambient') { try { preloadMusicCue('meditation'); } catch {} }
        if (selectedBackgroundSound === 'heartbeat') { try { preloadMusicCue('heartbeat'); } catch {} }
      }
    }
  }, [meditationState, selectedStyle, selectedBackgroundSound]);

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
      
      // Show congratulations once
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
            toast.success('Meditation complete. Keep it up!');
          }
        })();
      }
    } else if (meditationState === MeditationState.SETUP) {
      congratulatedRef.current = false;
    }
  }, [meditationState, user?.id]);

  // Hard-stop any residual prompts/audio on completion
  useEffect(() => {
    if (meditationState === MeditationState.COMPLETE) {
      try { orchestratorRef.current?.stop(); } catch {}
      orchestratorRef.current = null;
      try { Speech.stop(); } catch {}
      try { clearSpeechQueue(); } catch {}
      try { stopMusic('meditation'); } catch {}
      try { stopMusic('heartbeat'); } catch {}
    }
  }, [meditationState]);

  // Reset session state when leaving active
  useEffect(() => {
    if (meditationState !== MeditationState.ACTIVE) {
      hasMarkedComplete.current = false;
      spokenPromptsRef.current.clear();
    }
  }, [meditationState]);

  // UI-only prompt display (speech handled by Orchestrator)
  const showPromptOnly = useCallback((index: number) => {
    if (spokenPromptsRef.current.has(index)) return;
    spokenPromptsRef.current.add(index);
    setCurrentPromptIndex(index);
    promptOpacity.value = withTiming(1, { duration: 1000 });
  }, [promptOpacity]);

  // Countdown animation
  const animateCountdownNumber = useCallback(() => {
    numberScale.value = withSequence(
      withTiming(1.2, { duration: 300, easing: Easing.out(Easing.quad) }),
      withTiming(0.8, { duration: 700, easing: Easing.inOut(Easing.quad) })
    );
    numberOpacity.value = withSequence(
      withTiming(1, { duration: 100, easing: Easing.out(Easing.quad) }),
      withTiming(0.5, { duration: 700, easing: Easing.inOut(Easing.quad) })
    );
  }, [numberScale, numberOpacity]);

  const animateBreathText = useCallback((phaseDuration: number) => {
    const fadeIn = Math.min(500, Math.max(250, phaseDuration * 0.25));
    const delay = Math.max(0, phaseDuration - fadeIn - 400);
    breatheTextOpacity.value = withSequence(
      withTiming(1, { duration: fadeIn, easing: Easing.out(Easing.quad) }),
      withDelay(delay, withTiming(0, { duration: 400, easing: Easing.inOut(Easing.quad) }))
    );
  }, [breatheTextOpacity]);

  // CONSOLIDATED ORCHESTRATOR LIFECYCLE
  useEffect(() => {
    const isCountdown = meditationState === MeditationState.COUNTDOWN;
    const isActive = meditationState === MeditationState.ACTIVE && selectedTime;

    // Create orchestrator once when entering countdown or active
    if ((isCountdown || isActive) && !orchestratorRef.current) {
      orchestratorRef.current = new MeditationOrchestrator({
        getConfig: () => ({
          selectedStyle,
          promptInterval,
          totalMeditationSeconds,
          selectedChallenge,
          centeringWord,
          centeringReadMode,
          centeringRepeatIntervalSec,
          chantReflectionPauseSec,
          parableReadMode,
          sessionCount: completedSessions,
          selectedMinutes: selectedTime ?? null,
          virtueName: selectedStyle === 'virtue' ? (currentVirtue?.name || null) : null,
          chosenChantId: chosenChantId ?? null,
          jesusPrayerPace: jesusPrayerPace,
          selectedBackgroundSound: (selectedBackgroundSound === 'ambient'
            ? 'ambient'
            : selectedBackgroundSound === 'heartbeat'
              ? 'heartbeat'
              : null) as 'ambient' | 'heartbeat' | null,
        }),
        callbacks: {
          showPrompt: showPromptOnly,
          onComplete: () => {
            if (!hasMarkedComplete.current) {
              hasMarkedComplete.current = true;
              meditationStore.endMeditationSession();
              try {
                const target = (dailyPathStore.todaysSteps || []).find(s => s.route === 'MeditationScreen' && !dailyPathStore.isStepComplete(s.id));
                if (target) {
                  dailyPathStore.markStepComplete(target.id);
                } else {
                  dailyPathStore.markStepComplete('meditation');
                }
              } catch {}
            }
          },
          onTick: (t: number, ratio: number) => {
            meditationStore.setMeditationTimer(t);
            progressAnim.value = ratio;
          },
          onGuide: (g: OrchestratorMeditationGuide) => {
            setOrchestratedGuide(g);
          },
          onIntroComplete: () => {
            breathPhaseIndex.value = 0;
          },
          onBreathPhase: (phase, durationMs) => {
            animateBreathText(durationMs);
            if (phase === 'in') {
              breathPhaseIndex.value = 0;
              pulseAnim.value = withTiming(1, { duration: durationMs, easing: Easing.inOut(Easing.quad) });
            } else if (phase === 'hold') {
              breathPhaseIndex.value = 1;
              pulseAnim.value = withTiming(1, { duration: durationMs, easing: Easing.linear });
            } else {
              breathPhaseIndex.value = 2;
              pulseAnim.value = withTiming(0, { duration: durationMs, easing: Easing.inOut(Easing.quad) });
            }
          },
          onCountdownTick: (n: number) => {
            meditationStore.setCountdown(n);
            animateCountdownNumber();
            if (n === 0 && !activatedRef.current) {
              activatedRef.current = true;
              progressAnim.value = 0;
              meditationStore.beginActivePhase();
            }
          },
        },
      });
    }

    // Start countdown once per session
    if (isCountdown && orchestratorRef.current) {
      if (!countdownStartedRef.current) {
        countdownStartedRef.current = true;
        activatedRef.current = false;
        orchestratorRef.current.startCountdown(countdown);
      }
    } else {
      countdownStartedRef.current = false;
    }

    if (isActive && orchestratorRef.current) {
      orchestratorRef.current.start();
    }

    // Cleanup when leaving countdown/active
    return () => {
      const stillInFlow = (meditationState === MeditationState.COUNTDOWN) || (meditationState === MeditationState.ACTIVE);
      if (!stillInFlow && orchestratorRef.current) {
        orchestratorRef.current.stop();
        orchestratorRef.current = null;
        countdownStartedRef.current = false;
      }
    };
  }, [meditationState, selectedTime, completedSessions, selectedStyle, currentVirtue?.name, chosenChantId, countdown]);

  // Intercept back actions during countdown/active to avoid background/duplicate sessions
  useEffect(() => {
    const shouldGuard = meditationState === MeditationState.COUNTDOWN || meditationState === MeditationState.ACTIVE;
    if (!shouldGuard) return;

    const confirmEnd = (proceedNav?: () => void) => {
      Alert.alert(
        'End meditation?',
        'Your meditation is currently running. Do you want to end it?',
        [
          { text: 'Keep Going', style: 'cancel' },
          {
            text: 'End Session',
            style: 'destructive',
            onPress: () => {
              try { orchestratorRef.current?.stop(); } catch {}
              orchestratorRef.current = null;
              meditationStore.endMeditationSession();
              try { Speech.stop(); } catch {}
              proceedNav?.();
            },
          },
        ]
      );
    };

    // Hardware back (Android)
    const onBack = () => {
      confirmEnd();
      return true; // prevent default
    };
    const bhSub = BackHandler.addEventListener('hardwareBackPress', onBack);

    // Navigation back (gesture or button)
    const beforeRemove = navigation.addListener('beforeRemove', (e) => {
      e.preventDefault();
      confirmEnd(() => {
        try { navigation.dispatch(e.data.action); } catch {}
      });
    });

    return () => {
      try { bhSub.remove(); } catch {}
      try { beforeRemove(); } catch {}
    };
  }, [navigation, meditationState, meditationStore]);

  // Handlers
  const startMeditation = async () => {
    const missingVirtue = selectedStyle === 'virtue' && !selectedVirtue;
    let minutes = selectedTime;
    
    if (selectedStyle === 'parable' && (minutes == null || minutes < 10)) {
      minutes = 10;
      meditationStore.setSelectedTime(10);
    }
    
    if (missingVirtue || !minutes) {
      fadeAnim.value = withSequence(
        withTiming(0.3, { duration: 200 }), 
        withTiming(1, { duration: 200 })
      );
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    try {
      const seen = await AsyncStorage.getItem('med_first_tip_shown');
      if (!seen) {
        pendingStartRef.current = true;
        setShowFirstTipModal(true);
        return;
      }
    } catch {}

    // Capture points snapshot
    preSessionPointsRef.current = leaderboardStore.userStats?.totalPoints ?? null;
    progressAnim.value = 0;
    meditationStore.setExternalDriver(true);
    meditationStore.startMeditation();
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const endMeditation = useCallback(() => {
    meditationStore.endMeditationSession();
    try { Speech.stop(); } catch {}
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }, [meditationStore]);

  const resumeMeditation = useCallback(() => {
    meditationStore.resume();
    orchestratorRef.current?.resume();
  }, [meditationStore]);

  const handleSelectTime = useCallback((minutes: number) => {
    const clamped = selectedStyle === 'parable' ? Math.max(10, minutes) : minutes;
    meditationStore.setSelectedTime(clamped);
    Haptics.selectionAsync();
    setShowCustomTimeModal(false);
  }, [meditationStore, selectedStyle]);

  const handleSmartPickJoin = useCallback((challenge: ChallengeRecommendation) => {
    void (async () => {
      const success = await challengeStore.joinChallenge(challenge.id);
      if (success) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        setSmartPickDismissed(true);
        navigation.navigate('DailyChallengeScreen');
      }
    })();
  }, [challengeStore, navigation]);

  const createChallenge = async () => {
    if (!selectedChallenge) {
      navigation.navigate('DailyChallengeScreen');
      return;
    }
    
    const endTime = new Date();
    endTime.setHours(endTime.getHours() + (selectedTime === 40 ? 24 : selectedTime === 15 ? 6 : 3));
    const challenge = { ...selectedChallenge, end_time: endTime.toISOString() };

    if (user) {
      await meditationStore.joinChallenge(selectedChallenge.id);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    }
    navigation.navigate('Home', { meditationComplete: true, challenge });
  };

  const formatTime = useCallback((seconds: number) => {
    const clamped = Math.max(0, seconds);
    const mins = Math.floor(clamped / 60);
    const secs = clamped % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }, []);

  // Animated styles
  const fadeAnimStyle = useAnimatedStyle(() => ({ opacity: fadeAnim.value }));
  const countdownNumberStyle = useAnimatedStyle(() => ({
    transform: [{ scale: numberScale.value }],
    opacity: numberOpacity.value,
  }));
  const breatheTextStyle = useAnimatedStyle(() => ({ opacity: breatheTextOpacity.value }));
  // const promptAnimStyle = useAnimatedStyle(() => ({
  //   opacity: promptOpacity.value,
  //   transform: [{ translateY: interpolate(promptOpacity.value, [0, 1], [20, 0]) }],
  // }));
  const bellButtonStyle = useAnimatedStyle(() => ({ transform: [{ scale: bellScale.value }] }));
  const breathingCircleStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pulseAnim.value, [0, 1], [0.7, 1.6]) }],
    opacity: interpolate(pulseAnim.value, [0, 1], [0.5, 0.9]),
  }));
  const breatheInLabelStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 0 ? 1 : 0 }));
  const breatheHoldLabelStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 1 ? 1 : 0 }));
  const breatheOutLabelStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 2 ? 1 : 0 }));
  const jpInStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 0 ? 1 : 0.4 }));
  const jpHoldStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 1 ? 1 : 0.4 }));
  const jpOutStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 2 ? 1 : 0.4 }));

  // Render functions
  const renderIdleScreen = () => {
    const last = sessions && sessions.length > 0 ? sessions[0] : null;
    const lastDuration = last?.duration_minutes ? `${last.duration_minutes} min` : null;
    return (
      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        <View style={styles.idleContainer}>
          <View style={styles.idleCard}>
            <Text style={styles.idleTitle}>Ready for a new session</Text>
            {lastDuration ? (
              <Text style={styles.idleSubtitle}>Last session: {lastDuration}</Text>
            ) : null}
          </View>
          <View style={styles.idleRow}>
            <TouchableOpacity style={[styles.idleBtn, styles.idleBtnPrimary]} onPress={() => {
              progressAnim.value = 0;
              meditationStore.startMeditation();
              Haptics.selectionAsync();
            }}>
              <Text style={[styles.idleBtnText, styles.idleBtnTextPrimary]}>Start Again</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.idleBtn} onPress={() => setShowSetupModal(true)}>
              <Text style={styles.idleBtnText}>Setup Options</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    );
  };

  const renderSetupScreen = () => (
    <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
      <Animated.View style={[styles.setupContainer, fadeAnimStyle]}>
        <View style={styles.guideCard}>
          <Text style={styles.guideTitle}>{guideForUI.title}</Text>
          <Text style={styles.guideImagery}>{guideForUI.imagery}</Text>
          {!!guideForUI.scripture && <Text style={styles.guideScripture}>{guideForUI.scripture}</Text>}
          <Text style={styles.guideFocus}>{guideForUI.focus}</Text>
          {guideForUI.stageNote && (
            <Text style={styles.guideStageNote}>{guideForUI.stageNote}</Text>
          )}
          {guideForUI.openReflection && (
            <Text style={styles.guideReflection}>{guideForUI.openReflection}</Text>
          )}
        </View>

        <Text style={styles.sectionTitle}>YOUR MEDITATION</Text>
        <View style={styles.selectedVirtueCollapsed}>
          <View style={styles.selectedVirtueContent}>
            <Text style={[styles.virtueText, { color: currentVirtue?.color_code || theme?.colors.primary }]}>
              {selectedStyle === 'virtue' ? (currentVirtue?.name || 'Choose a virtue') :
                selectedStyle === 'centering' ? `Centering: ${centeringWord || 'Jesus'}` :
                  selectedStyle === 'jesus_prayer' ? 'Jesus Prayer' :
                    selectedStyle === 'chant' ? (chosenChantId ? (getChantById(chosenChantId)?.label || 'Chant') : 'Chant') : 'Parable Meditation'}
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
                        meditationStore.setSelectedChallenge(null);
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

        {isOffline && (
          <View style={styles.offlinePill}>
            <MaterialIcons name="wifi-off" size={14} color={theme.colors.warning} />
            <Text style={styles.offlinePillText}>Offline — sessions sync later</Text>
          </View>
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

  const renderActiveScreen = () => {
    const totalSeconds = selectedTime ? selectedTime * 60 : null;
    const elapsedLabel = formatTime(meditationTimer);
    const totalLabel = totalSeconds ? formatTime(totalSeconds) : null;
    const isChant = selectedStyle === 'chant';
    const isCentering = selectedStyle === 'centering';
    const isJP = selectedStyle === 'jesus_prayer';
    const chantNow = chosenChantId ? (getChantById(chosenChantId)?.label || 'Chant') : 'Chant';

    return (
      <View style={[styles.activeContainer, { paddingBottom: theme?.spacing.lg + (insets.bottom || 0) }]}>
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
            <View style={[styles.baseCircle, { backgroundColor: theme.colors.background }]} />

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
              {isCentering ? (
                <Text style={styles.breatheInstruction}>{`Return to: ${centeringWord || 'Jesus'}`}</Text>
              ) : (
                <>
                  <Animated.Text style={[styles.breatheInstruction, breatheInLabelStyle]}>Breathe In</Animated.Text>
                  <Animated.Text style={[styles.breatheInstruction, breatheHoldLabelStyle]}>Keep still</Animated.Text>
                  <Animated.Text style={[styles.breatheInstruction, breatheOutLabelStyle]}>Breathe Out</Animated.Text>
                </>
              )}
            </View>
          </Animated.View>
        )}

        {!isChant && (
          <View style={styles.controlsRow}>
            <TouchableOpacity
              style={[styles.controlBtn, styles.pauseBtn]}
              onPress={() => meditationStore.pause()}
            >
              <Text style={[styles.controlBtnText, styles.pauseBtnText]}>Pause</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.controlBtn, styles.endBtn]}
              onPress={endMeditation}
            >
              <Text style={[styles.controlBtnText, styles.endBtnText]}>End</Text>
            </TouchableOpacity>
          </View>
        )}

        {isJP && (
          <View style={styles.jpGuideContainer}>
            <Animated.Text style={[styles.jpPhrase, jpInStyle]}>Lord Jesus Christ</Animated.Text>
            <Animated.Text style={[styles.jpPhrase, jpHoldStyle]}>Son of God</Animated.Text>
            <Animated.Text style={[styles.jpPhrase, jpOutStyle]}>have mercy on me</Animated.Text>
          </View>
        )}

        {isOffline && (
          <View style={styles.offlineBanner}>
            <MaterialIcons name="wifi-off" size={16} color={theme.colors.warning} />
            <Text style={styles.offlineBannerText}>Offline mode — your progress will sync once reconnected.</Text>
          </View>
        )}

        <View style={styles.declarationContainer}>
          <Text style={styles.declarationLabel}>Declaration</Text>
          <Text style={styles.declarationText}>{guideForUI.declaration}</Text>
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

  const renderPausedScreen = () => (
    <View style={styles.pausedOverlay}>
      <BlurView intensity={80} tint="default" style={styles.pausedBlur}>
        <View style={styles.pausedCard}>
          <View style={styles.pausedIconContainer}>
            <View style={[styles.pausedIcon, { backgroundColor: `${currentVirtue?.color_code || theme?.colors.primary}20` }]}>
              <Text style={[styles.pausedIconText, { color: currentVirtue?.color_code || theme?.colors.primary }]}>⏸</Text>
            </View>
          </View>
          <Text style={styles.pausedTitle}>Meditation Paused</Text>
          <Text style={styles.pausedSubtitle}>Take your time. Resume when you're ready.</Text>
          <View style={styles.pausedActions}>
            <TouchableOpacity
              style={[styles.pausedResumeButton, { backgroundColor: currentVirtue?.color_code || theme?.colors.primary }]}
              onPress={resumeMeditation}
              activeOpacity={0.8}
            >
              <Text style={styles.pausedResumeText}>Resume Meditation</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={styles.pausedEndButton} 
              onPress={endMeditation}
              activeOpacity={0.7}
            >
              <Text style={styles.pausedEndText}>End Session</Text>
            </TouchableOpacity>
          </View>
        </View>
      </BlurView>
    </View>
  );

  const renderCompleteScreen = () => (
    <MeditationCompleteView
      theme={theme}
      styles={styles}
      selectedStyle={selectedStyle}
      smartPickChallenge={smartPickChallenge as any}
      smartPickDismissed={smartPickDismissed}
      onDismissSmartPick={() => setSmartPickDismissed(true)}
      onJoinSmartPick={handleSmartPickJoin as any}
      onActivateChallenge={createChallenge}
      selectedChallenge={selectedChallenge as any}
      challengeExpanded={challengeExpanded}
      onToggleChallengeExpand={() => setChallengeExpanded(!challengeExpanded)}
      selectedTime={selectedTime}
      currentVirtue={currentVirtue as any}
      bellButtonStyle={bellButtonStyle}
      guideChallengePrompt={(selectedStyle === 'parable' || selectedStyle === 'virtue') ? guideForUI?.closingReminder : undefined}
      onFinish={() => {
        try {
          Speech.stop();
          stopMusic('meditation');
          stopMusic('heartbeat');
        } finally {
          meditationStore.setExternalDriver(false);
          meditationStore.resetMeditationSession();
          navigation.replace('Home', { meditationComplete: true });
        }
      }}
    />
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
          parableReadMode: parableReadMode,
          centeringReadMode: centeringReadMode,
          centeringRepeatIntervalSec: centeringRepeatIntervalSec,
          chantReflectionPauseSec: chantReflectionPauseSec,
        }}
        onStart={(values) => {
          meditationStore.setSelectedStyle(values.style);
          meditationStore.setSelectedBackgroundSound(values.sound ?? null);
          meditationStore.setSelectedVirtue(values.virtueId ?? null);
          meditationStore.setCenteringWord(values.centeringWord ?? null);
          meditationStore.setJesusPrayerPace(values.jesusPrayerPace ?? 'medium');
          meditationStore.setChosenChantId(values.chantId ?? null);
          meditationStore.setParableReadMode(values.parableReadMode ?? 'silent');
          meditationStore.setCenteringReadMode(values.centeringReadMode ?? 'silent');
          meditationStore.setCenteringRepeatIntervalSec(values.centeringRepeatIntervalSec ?? 15);
          meditationStore.setChantReflectionPauseSec(values.chantReflectionPauseSec ?? 20);
          Haptics.selectionAsync();
        }}
      />

      <Modal visible={showFirstTipModal} animationType="fade" transparent onRequestClose={() => setShowFirstTipModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Quick Tips</Text>
            <Text style={styles.modalText}>• Switch on Do Not Disturb to avoid distractions
              {'\n'}• If it's safe, gently close your eyes
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
                    meditationStore.setExternalDriver(true);
                    meditationStore.startMeditation();
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
        <View style={[styles.header, { paddingTop: theme?.spacing.lg + (insets.top || 0) }]}>
          <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme?.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Daily Meditation</Text>
          <View style={{ width: 24 }} />
        </View>
      )}

      {meditationState === MeditationState.SETUP && renderSetupScreen()}
      {meditationState === MeditationState.IDLE && renderIdleScreen()}
      {meditationState === MeditationState.COUNTDOWN && renderCountdownScreen()}
      {meditationState === MeditationState.ACTIVE && renderActiveScreen()}
      {meditationState === MeditationState.PAUSED && renderPausedScreen()}
      {meditationState === MeditationState.COMPLETE && renderCompleteScreen()}
      {isOffline && (
        <View style={styles.offlinePill}>
          <MaterialIcons name="wifi-off" size={16} color={theme.colors.warning} />
          <Text style={styles.offlinePillText}>Offline mode — your progress will sync once reconnected.</Text>
        </View>
      )}
    </View>
  );
};

export default observer(MeditationScreen);