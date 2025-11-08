import React, { useState, useRef, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Platform,
  BackHandler,
  Modal,
  AppState,
  AppStateStatus,
} from 'react-native';

import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import MeditationCompleteView from '@/components/MeditationCompleteView';
import { observer } from 'mobx-react-lite';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import { RootStackParamList, Virtue } from '@/types';
import {
  ArrowLeft,
  Clock,
} from '@/components/Icons';
import { Theme } from '@/theme';
import { useAuthStore, useVirtueStore, useMeditationStore, useChallengeStore, useLeaderboardStore } from '@/stores/StoreProvider';
import * as Haptics from 'expo-haptics';
import { useKeepAwake } from 'expo-keep-awake';
import { playMusic, stopMusic, preloadMusicCue } from '@/services/audio';
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
  const auth = useAuthStore();
  const { user } = auth;

  // Store references
  const virtueStore = useVirtueStore();
  const { virtues } = virtueStore;
  const meditationStore = useMeditationStore();
  const challengeStore = useChallengeStore();
  const leaderboardStore = useLeaderboardStore();

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

    // Start flows
    if (isCountdown && orchestratorRef.current) {
      activatedRef.current = false;
      orchestratorRef.current.startCountdown(countdown);
    }
    
    if (isActive && orchestratorRef.current) {
      orchestratorRef.current.start();
    }

    // Cleanup when leaving countdown/active
    return () => {
      const stillInFlow = (meditationState === MeditationState.COUNTDOWN) || 
                          (meditationState === MeditationState.ACTIVE);
      if (!stillInFlow && orchestratorRef.current) {
        orchestratorRef.current.stop();
        orchestratorRef.current = null;
      }
    };
  }, [
    meditationState,
    selectedTime,
    countdown,
    // Don't include all config deps - orchestrator uses getConfig callback
  ]);

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
        toast.success('Challenge added to your day');
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
  const promptAnimStyle = useAnimatedStyle(() => ({
    opacity: promptOpacity.value,
    transform: [{ translateY: interpolate(promptOpacity.value, [0, 1], [20, 0]) }],
  }));
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
            <Animated.Text style={[styles.jpPhrase, jpInStyle]}>Lord Jesus Christ</Animated.Text>
            <Animated.Text style={[styles.jpPhrase, jpHoldStyle]}>Son of God</Animated.Text>
            <Animated.Text style={[styles.jpPhrase, jpOutStyle]}>have mercy on me</Animated.Text>
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
        <View style={styles.header}>
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
      fontSize: 16,
    },
    idleContainer: { padding: theme.spacing.lg },
    idleCard: {
      padding: theme.spacing.lg,
      borderRadius: theme.borderRadius.lg,
      backgroundColor: theme.colors.surface,
      borderWidth: 1,
      borderColor: theme.colors.border,
      marginBottom: theme.spacing.lg,
      alignItems: 'center',
    },
    idleTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
      fontWeight: '700',
    },
    idleSubtitle: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
      marginTop: 4,
    },
    idleRow: { flexDirection: 'row', gap: theme.spacing.sm },
    idleBtn: {
      flex: 1,
      paddingVertical: theme.spacing.md,
      borderRadius: theme.borderRadius.md,
      borderWidth: 1.5,
      borderColor: theme.colors.border,
      alignItems: 'center',
      backgroundColor: theme.colors.surface,
    },
    idleBtnPrimary: { backgroundColor: theme.colors.primary, borderColor: theme.colors.primary },
    idleBtnText: { ...theme.typography.body.sans, color: theme.colors.text.primary, fontWeight: '600' },
    idleBtnTextPrimary: { color: '#FFF' },
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
    finishButton: {
      marginTop: theme.spacing.xl,
      paddingVertical: theme.spacing.md,
      paddingHorizontal: theme.spacing.xl,
      borderRadius: theme.borderRadius.full,
      backgroundColor: theme.colors.primary,
      alignSelf: 'center',
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.15, shadowRadius: 8 },
        android: { elevation: 4 },
      }),
    },
    finishButtonText: {
      ...theme.typography.body.sans,
      color: '#FFFFFF',
      fontWeight: '700',
      fontSize: 16,
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
    pausedOverlay: {
      ...StyleSheet.absoluteFillObject,
      backgroundColor: 'rgba(0, 0, 0, 0.4)',
      justifyContent: 'center',
      alignItems: 'center',
      zIndex: 1000,
    },
    pausedBlur: {
      width: '85%',
      borderRadius: theme?.borderRadius.xl,
      overflow: 'hidden',
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 8 }, shadowOpacity: 0.3, shadowRadius: 16 },
        android: { elevation: 8 },
      }),
    },
    pausedCard: {
      padding: theme?.spacing.xl,
      backgroundColor: theme?.colors.surface + 'F5',
      alignItems: 'center',
      gap: theme?.spacing.md,
    },
    pausedIconContainer: {
      marginBottom: theme?.spacing.sm,
    },
    pausedIcon: {
      width: 80,
      height: 80,
      borderRadius: 40,
      justifyContent: 'center',
      alignItems: 'center',
    },
    pausedIconText: {
      fontSize: 40,
      fontWeight: '300',
    },
    pausedTitle: {
      ...theme?.typography.heading.medium,
      color: theme?.colors.text.primary,
      fontWeight: '700',
      textAlign: 'center',
    },
    pausedSubtitle: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      textAlign: 'center',
      marginBottom: theme?.spacing.sm,
    },
    pausedActions: {
      width: '100%',
      gap: theme?.spacing.sm,
      marginTop: theme?.spacing.md,
    },
    pausedResumeButton: {
      paddingVertical: theme?.spacing.md + 2,
      paddingHorizontal: theme?.spacing.xl,
      borderRadius: theme?.borderRadius.full,
      alignItems: 'center',
      ...Platform.select({
        ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.2, shadowRadius: 8 },
        android: { elevation: 4 },
      }),
    },
    pausedResumeText: {
      ...theme?.typography.body.sans,
      color: '#FFFFFF',
      fontWeight: '700',
      fontSize: 16,
    },
    pausedEndButton: {
      paddingVertical: theme?.spacing.md,
      paddingHorizontal: theme?.spacing.xl,
      borderRadius: theme?.borderRadius.full,
      alignItems: 'center',
      backgroundColor: 'transparent',
      borderWidth: 1.5,
      borderColor: theme?.colors.border,
    },
    pausedEndText: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      fontWeight: '600',
      fontSize: 15,
    },
  });

export default observer(MeditationScreen);