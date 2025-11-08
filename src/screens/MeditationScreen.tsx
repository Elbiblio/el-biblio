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
import { setAudioModeAsync } from 'expo-audio';
import { activateKeepAwake, deactivateKeepAwake } from 'expo-keep-awake';
import { playCue, playMusic, stopByKey, stopMusic, stopAllSounds, setMusicVolume, playLoopByKey, playOneShotByKey, SoundKey } from '@/services/audio';
import { AudioCoordinator } from '@/services/AudioCoordinator';
import { MeditationOrchestrator } from '@/services/MeditationOrchestrator';
import type { MeditationGuide as OrchestratorMeditationGuide } from '@/services/MeditationOrchestrator';
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
import MeditationSetupModal from '@/components/MeditationSetupModal';

const TIME_OPTIONS: number[] = [5, 10, 15, 20];
const ADVANCED_TIME_OPTIONS: number[] = [30, 45, 60];

const BREATH_CONFIG = {
  slow: { in: 5200, hold: 3000, out: 6000 },
  medium: { in: 4000, hold: 2000, out: 4800 },
  fast: { in: 2800, hold: 1500, out: 3200 },
};


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
    isPreviewingSound,
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
  const breathPhaseIndex = useSharedValue(0); // 0=in, 1=hold, 2=out

  // Centralized audio service
  const isSpeaking = useRef(false);
  const preSessionPointsRef = useRef<number | null>(null);
  const congratulatedRef = useRef(false);

  // Refs for flow control
  const hasMarkedComplete = useRef(false);
  const spokenPromptsRef = useRef<Set<number>>(new Set());
  const orchestratorRef = useRef<MeditationOrchestrator | null>(null);
  const [orchestratedGuide, setOrchestratedGuide] = useState<OrchestratorMeditationGuide | null>(null);
  const activatedRef = useRef(false);

  const pauseAllAudio = React.useCallback(() => {
    try { Speech.stop(); } catch {}
    try { stopMusic('meditation'); } catch {}
    try { stopMusic('heartbeat'); } catch {}
    try {
      const voice = CHANT_VOICE_MAP[chosenChantId || ''];
      const instrumental = CHANT_INSTRUMENTAL_MAP[chosenChantId || ''];
      if (instrumental) { void stopByKey(instrumental); }
      if (voice) { void stopByKey(voice); }
    } catch {}
    // Pause audio coordinator if in chant mode
    if (selectedStyle === 'chant' && audioCoordinatorRef.current) {
      audioCoordinatorRef.current.pause();
    }
    // Pause orchestrator
    if (orchestratorRef.current) {
      orchestratorRef.current.pause();
    }
  }, [chosenChantId, selectedStyle]);

  // Load virtues on mount
  useEffect(() => {
    virtueStore.fetchVirtues();
  }, [virtueStore]);

  const goalVirtueId = selectedVirtue;
  const [showSetupModal, setShowSetupModal] = useState(false);
  
  // Keep the screen awake while meditation is active
  useEffect(() => {
    if (meditationState === MeditationState.ACTIVE) {
      try { activateKeepAwake('meditation'); } catch {}
    } else {
      try { deactivateKeepAwake('meditation'); } catch {}
    }
    return () => { try { deactivateKeepAwake('meditation'); } catch {} };
  }, [meditationState]);

  const currentVirtue = React.useMemo(
    () => virtues?.find((v: Virtue) => v.id === selectedVirtue),
    [selectedVirtue, virtues]
  );
  const totalMeditationSeconds = React.useMemo(
    () => (selectedTime || 0) * 60,
    [selectedTime]
  );
  const promptInterval = totalMeditationSeconds > 0 ? Math.floor(totalMeditationSeconds / 4) : 0;
  const orchestratorConfigRef = useRef({
    selectedStyle,
    promptInterval,
    totalMeditationSeconds,
    selectedChallenge,
    centeringWord,
    centeringReadMode,
    centeringRepeatIntervalSec,
    chantReflectionPauseSec,
    parableReadMode,
    selectedBackgroundSound,
  });
  const orchestratorConfig = React.useMemo(() => ({
    selectedStyle,
    promptInterval,
    totalMeditationSeconds,
    selectedChallenge,
    centeringWord,
    centeringReadMode,
    centeringRepeatIntervalSec,
    chantReflectionPauseSec,
    parableReadMode,
    selectedBackgroundSound,
  }), [
    selectedStyle,
    promptInterval,
    totalMeditationSeconds,
    selectedChallenge,
    centeringWord,
    centeringReadMode,
    centeringRepeatIntervalSec,
    chantReflectionPauseSec,
    parableReadMode,
    selectedBackgroundSound,
  ]);
  // Assign memoized config to ref without causing effects
  orchestratorConfigRef.current = orchestratorConfig;

  const sessions = meditationStore.state.sessions;
  const completedSessions = React.useMemo(() => {
    if (!selectedVirtue) return sessions.length;
    return sessions.filter(session => session.virtue_id === selectedVirtue).length;
  }, [sessions, selectedVirtue]);
  const previewGuide = React.useMemo(() => {
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
    selectedStyle,
    selectedTime,
    selectedChallenge,
    completedSessions,
    currentVirtue?.name,
    centeringWord,
    chosenChantId,
  ]);
  const guideForUI = (orchestratedGuide ?? previewGuide);
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
    setAudioModeAsync({ playsInSilentMode: true }).catch(() => { });
    return () => {
      stopMusic('meditation');
      stopMusic('heartbeat');
      try {
        Object.values(CHANT_INSTRUMENTAL_MAP).forEach((key) => {
          if (key) stopByKey(key as any);
        });
      } catch { }
    };
  }, []);

  useEffect(() => {
    const onChange = (state: AppStateStatus) => {
      // Only pause when app goes to background, not on 'inactive' which can happen
      // during normal usage (notification center, control center, etc.)
      if (state === 'background' && (meditationState === MeditationState.ACTIVE || meditationState === MeditationState.COUNTDOWN)) {
        pauseAllAudio();
        meditationStore.pause();
        try { orchestratorRef.current?.pause(); } catch {}
        try { audioCoordinatorRef.current?.pause(); } catch {}
      }
    };
    const sub = AppState.addEventListener('change', onChange);
    return () => { try { sub.remove(); } catch {} };
  }, [meditationState, meditationStore, pauseAllAudio]);

  // Background sound PREVIEW in SETUP only (ACTIVE is orchestrated)
  useEffect(() => {
    if (meditationState !== MeditationState.SETUP) return;
    if (selectedStyle !== 'chant') {
      if (isPreviewingSound) {
        if (selectedBackgroundSound === 'ambient') playMusic('meditation', 0.6);
        if (selectedBackgroundSound === 'heartbeat') playMusic('heartbeat', 0.6);
      } else {
        stopMusic('meditation');
        stopMusic('heartbeat');
      }
    } else {
      stopMusic('meditation');
      stopMusic('heartbeat');
    }
    return () => {
      stopMusic('meditation');
      stopMusic('heartbeat');
    };
  }, [meditationState, isPreviewingSound, selectedBackgroundSound, selectedStyle]);

  useEffect(() => {
    if (meditationState === MeditationState.COMPLETE) {
      try { Speech.stop(); } catch { }
      try { stopAllSounds(); } catch { }
      try {
        const voice = CHANT_VOICE_MAP[chosenChantId || ''];
        const instrumental = CHANT_INSTRUMENTAL_MAP[chosenChantId || ''];
        if (instrumental) { void stopByKey(instrumental); }
        if (voice) { void stopByKey(voice); }
      } catch { }
      try {
        breathTimeoutsRef.current.forEach(clearTimeout);
        breathTimeoutsRef.current = [];
      } catch { }
      try {
        if (audioCoordinatorRef.current) {
          audioCoordinatorRef.current.stop();
          audioCoordinatorRef.current = null;
        }
      } catch { }
    }
  }, [meditationState, chosenChantId]);

  

  // UI-only prompt display (speech handled by Orchestrator)
  const showPromptOnly = (index: number) => {
    if (spokenPromptsRef.current.has(index)) return;
    spokenPromptsRef.current.add(index);
    setCurrentPromptIndex(index);
    setShowPrompt(true);
    promptOpacity.value = withTiming(1, { duration: 1000 });
  };

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
              startMeditationStore();
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

  // Countdown speech handled by Orchestrator
  const speakCountdownNumber = (_: number) => {};

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
  const audioCoordinatorRef = useRef<AudioCoordinator | null>(null);
  const breathCycleCount = useRef(0);

  useEffect(() => {
    if (selectedStyle === 'jesus_prayer' && jesusPrayerPace) {
      setSelectedPace(jesusPrayerPace);
    }
  }, [selectedStyle, jesusPrayerPace]);

  // Breath loop moved into Orchestrator via onBreathPhase

  // Enhanced breathing circle style with better animation match
  const breathingCircleStyle = useAnimatedStyle(() => ({
    transform: [{ scale: interpolate(pulseAnim.value, [0, 1], [0.7, 1.6]) }],
    opacity: interpolate(pulseAnim.value, [0, 1], [0.5, 0.9]),
  }));

  // Animated styles for breath labels and JP phrases
  const breatheInLabelStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 0 ? 1 : 0 }));
  const breatheHoldLabelStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 1 ? 1 : 0 }));
  const breatheOutLabelStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 2 ? 1 : 0 }));
  const jpInStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 0 ? 1 : 0.4 }));
  const jpHoldStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 1 ? 1 : 0.4 }));
  const jpOutStyle = useAnimatedStyle(() => ({ opacity: breathPhaseIndex.value === 2 ? 1 : 0.4 }));

  // Consolidated Orchestrator lifecycle (COUNTDOWN and ACTIVE)
  useEffect(() => {
    const isCountdown = meditationState === MeditationState.COUNTDOWN;
    const canStartActive = meditationState === MeditationState.ACTIVE && selectedTime;
    // Create orchestrator once when entering countdown/active
    if ((isCountdown || canStartActive) && !orchestratorRef.current) {
      orchestratorRef.current = new MeditationOrchestrator({
        getConfig: () => ({
          ...orchestratorConfigRef.current,
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
          showPrompt: (i: number) => showPromptOnly(i),
          onComplete: () => {
            if (!hasMarkedComplete.current) {
              hasMarkedComplete.current = true;
              endMeditationSession();
            }
          },
          onTick: (t: number, ratio: number) => {
            try { meditationStore.setMeditationTimer(t); } catch {}
            try { progressAnim.value = ratio; } catch {}
          },
          onGuide: (g: OrchestratorMeditationGuide) => {
            setOrchestratedGuide(g);
          },
          onIntroComplete: () => {
            setIntroCompleted(true);
            breathPhaseIndex.value = 0;
          },
          onBreathPhase: (phase, durationMs) => {
            // Batch breath text fade + pulse + phase index without React state
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
          onChantStart: ({ chantId, pauseDurationMs, cues }) => {
            try {
              if (audioCoordinatorRef.current) {
                audioCoordinatorRef.current.stop();
                audioCoordinatorRef.current = null;
              }
              const voice = CHANT_VOICE_MAP[chantId || ''];
              const instrumental = CHANT_INSTRUMENTAL_MAP[chantId || ''];
              const coordinator = new AudioCoordinator({
                voiceKey: voice as SoundKey,
                instrumentalKey: instrumental as SoundKey,
                cues,
                pauseDurationMs,
                onPhaseChange: () => {},
              });
              audioCoordinatorRef.current = coordinator;
              coordinator.preload().then(() => {
                if (audioCoordinatorRef.current === coordinator) {
                  coordinator.start();
                }
              }).catch(() => {});
            } catch {}
          },
          onChantStop: () => {
            try {
              if (audioCoordinatorRef.current) {
                audioCoordinatorRef.current.stop();
                audioCoordinatorRef.current = null;
              }
            } catch {}
          },
          onCountdownTick: (n: number) => {
            try { meditationStore.setCountdown(n); } catch {}
            animateCountdownNumber();
            if (n === 0 && !activatedRef.current) {
              activatedRef.current = true;
              progressAnim.value = 0;
              try { meditationStore.beginActivePhase(); } catch {}
            }
          },
        },
      });
    }
    // Start flows
    if (meditationState === MeditationState.COUNTDOWN && orchestratorRef.current) {
      activatedRef.current = false;
      orchestratorRef.current.startCountdown(countdown);
    }
    if (canStartActive && orchestratorRef.current) {
      orchestratorRef.current.start();
    }
    // Cleanup when leaving countdown/active
    return () => {
      const stillInFlow = (meditationState === MeditationState.COUNTDOWN) || (meditationState === MeditationState.ACTIVE);
      if (!stillInFlow && orchestratorRef.current) {
        orchestratorRef.current.stop();
        orchestratorRef.current = null;
      }
    };
  }, [meditationState, selectedTime, completedSessions, selectedStyle, currentVirtue?.name, chosenChantId, countdown]);

  // (removed duplicate orchestrator init effect)

  // Progress ring driven by Orchestrator onTick

  // Reset session state when meditation ends
  useEffect(() => {
    if (meditationState !== MeditationState.ACTIVE) {
      hasMarkedComplete.current = false;
      try { spokenPromptsRef.current.clear(); } catch {}
    }
  }, [meditationState]);

  // Chant mode coordination is now driven by orchestrator callbacks (onChantStart/onChantStop)

  // Refresh points and bell animation on complete
  useEffect(() => {
    if (meditationState === MeditationState.COMPLETE) {
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
            toast.success('Meditation complete. Keep it up!');
          }
        })();
      }
    } else if (meditationState === MeditationState.SETUP) {
      // reset congratulation guard when returning to setup
      congratulatedRef.current = false;
    }
  }, [meditationState]);

  // Handlers
  // Scripture reading handled by Orchestrator
  const readScriptureSlowly = React.useCallback(async (_reference?: string) => { return; }, []);

  const startMeditation = async () => {
    const missingVirtue = selectedStyle === 'virtue' && !selectedVirtue;
    let minutes = selectedTime;
    if (selectedStyle === 'parable' && (minutes == null || minutes < 10)) {
      minutes = 10;
      setStoreSelectedTime(10);
    }
    if (missingVirtue || !minutes) {
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
    } catch { }
    // capture points snapshot before session begins
    preSessionPointsRef.current = leaderboardStore.userStats?.totalPoints ?? null;
    progressAnim.value = 0;
    try { meditationStore.setExternalDriver(true); } catch {}
    setIntroCompleted(false);
    startMeditationStore();
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  // Store initializes itself; avoid re-initializing to prevent repeated API calls

  const endMeditation = () => {
    endMeditationSession();
    if (isSpeaking.current) Speech.stop();
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const resumeMeditation = React.useCallback(() => {
    meditationStore.resume();
    // Resume audio coordinator if in chant mode
    if (selectedStyle === 'chant' && audioCoordinatorRef.current) {
      audioCoordinatorRef.current.resume();
    }
    // Resume orchestrator
    if (orchestratorRef.current) {
      orchestratorRef.current.resume();
    }
  }, [meditationStore, selectedStyle]);

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

  

  // Render functions
  const handleSelectTime = React.useCallback((minutes: number) => {
    const min = selectedStyle === 'parable' ? 10 : minutes;
    const clamped = selectedStyle === 'parable' ? Math.max(10, minutes) : minutes;
    setStoreSelectedTime(clamped);
    Haptics.selectionAsync();
    setShowCustomTimeModal(false);
  }, [setStoreSelectedTime, selectedStyle]);

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
                    selectedStyle === 'chant' ? (chosenChantId ? CHANT_LABEL_MAP[chosenChantId] || 'Chant' : 'Chant') : 'Parable Meditation'}
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
          // Stop any ongoing speech
          if (isSpeaking.current) Speech.stop();
          Speech.stop();

          // Stop background music
          stopMusic('meditation');
          stopMusic('heartbeat');

          // Stop chant audio if any
          const voice = CHANT_VOICE_MAP[chosenChantId || ''];
          const instrumental = CHANT_INSTRUMENTAL_MAP[chosenChantId || ''];
          if (instrumental) { void stopByKey(instrumental); }
          if (voice) { void stopByKey(voice); }

          // Clear local timers/intervals
          breathTimeoutsRef.current.forEach(clearTimeout);
          breathTimeoutsRef.current = [];
          if (audioCoordinatorRef.current) {
            audioCoordinatorRef.current.stop();
            audioCoordinatorRef.current = null;
          }

          // Reset local animations
          try { bellScale.value = 1; } catch { }
          try { pulseAnim.value = 0; } catch { }

          // As a safety, stop all sounds
          void stopAllSounds();
        } finally {
          try { meditationStore.setExternalDriver(false); } catch {}
          meditationStore.resetMeditationSession();
          // Use replace to force navigation change
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
                  try { await AsyncStorage.setItem('med_first_tip_shown', '1'); } catch { }
                  setShowFirstTipModal(false);
                  if (pendingStartRef.current) {
                    pendingStartRef.current = false;
                    progressAnim.value = 0;
                    try { meditationStore.setExternalDriver(true); } catch {}
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