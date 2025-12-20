import React, { useMemo, useEffect, useState, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Modal, ScrollView } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import ReadingTimer from '@/components/ReadingTimer';
import { useDailyPathStore } from '@/stores/StoreProvider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import type { ReadingPlanPhase } from '@/constants/readingPlanModes';
import { getVoicePromptsForPhase, getCelebrationMessage, getPhaseInstructions } from '@/modules/habitConquestVoicePrompts';

// Minimal session runner for Habit Conquest
// Uses configured per-session phases from DailyPathStore

type Props = NativeStackScreenProps<RootStackParamList, 'HabitConquestSessionScreen'>;

const HabitConquestSessionScreen: React.FC<Props> = ({ navigation }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const dailyPathStore = useDailyPathStore();

  const hc = dailyPathStore.state.habitConquest;
  const phases = hc?.phases ?? [
    { id: 'affirmation', label: 'Affirmation', minutes: 2 },
    { id: 'meditation', label: 'Meditation', minutes: 3 },
    { id: 'mercy', label: 'Prayer for Mercy', minutes: 2 },
    { id: 'forgiveness', label: 'Prayer for Forgiveness', minutes: 2 },
    { id: 'thanksgiving', label: 'Prayer for Thanksgiving', minutes: 1 },
  ];

  const sessionsCount = hc?.split === 'thrice' ? 3 : hc?.split === 'twice' ? 2 : 1;
  const targetPerSession = Math.max(0, Math.round((hc?.dailyMinutes ?? phases.reduce((s,p)=>s+p.minutes,0)) / sessionsCount));

  const scaledPhasesRaw = React.useMemo(() => {
    const baseTotal = phases.reduce((s, p) => s + (p.minutes || 0), 0);
    if (baseTotal <= 0) return phases;
    if (!targetPerSession || targetPerSession === baseTotal) return phases;
    const ratio = targetPerSession / baseTotal;
    // First pass: floor
    const prelim = phases.map(p => ({ ...p, minutes: Math.max(0, Math.floor(p.minutes * ratio)) }));
    let diff = targetPerSession - prelim.reduce((s, p) => s + p.minutes, 0);
    if (diff === 0) return prelim;
    // Distribute remainder across phases in order
    const next = [...prelim];
    let i = 0;
    while (diff > 0 && next.length) {
      next[i % next.length].minutes += 1;
      diff -= 1;
      i += 1;
    }
    return next;
  }, [phases, targetPerSession]);

  const timerPhases: ReadingPlanPhase[] = scaledPhasesRaw.map(p => {
    let id: ReadingPlanPhase['id'];
    switch (p.id) {
      case 'meditation':
        id = 'meditation';
        break;
      case 'mercy':
      case 'forgiveness':
      case 'thanksgiving':
        id = 'prayer';
        break;
      case 'affirmation':
      default:
        id = 'contemplation';
    }
    const hint = (() => {
      switch (p.id) {
        case 'affirmation':
          return 'Affirm your identity in Christ and your intention to heal. Speak your pledge aloud.';
        case 'meditation':
          return 'Sit with God. Notice thoughts and urges without judgment. Breathe and receive grace.';
        case 'mercy':
          return 'Ask for mercy. God delights to help you in weakness. Invite His strength.';
        case 'forgiveness':
          return 'Confess honestly. Receive forgiveness and release any shame back to the Cross.';
        case 'thanksgiving':
          return 'Give thanks for every small victory. Gratitude strengthens your new path.';
        default:
          return undefined;
      }
    })();
    return { id, label: p.label, minutes: p.minutes, hint } as ReadingPlanPhase;
  });

  const [checkinQueue, setCheckinQueue] = useState<string[]>([]);
  const [checkinIndex, setCheckinIndex] = useState(0);
  const [modalVisible, setModalVisible] = useState(false);
  const [clean, setClean] = useState<boolean>(true);
  const [pledged, setPledged] = useState<boolean>(true);
  const [showIntro, setShowIntro] = useState(false);
  const [introStep, setIntroStep] = useState(0);
  const [showGuide, setShowGuide] = useState(false);
  const [currentGuide, setCurrentGuide] = useState<{title: string; text: string} | null>(null);
  const [completedSessionsToday, setCompletedSessionsToday] = useState(0);
  const [accountabilityTriggered, setAccountabilityTriggered] = useState(false);
  const [showCelebration, setShowCelebration] = useState(false);
  const [celebrationMessage, setCelebrationMessage] = useState('');
  const [isPaused, setIsPaused] = useState(false);
  const [currentPhaseLabel, setCurrentPhaseLabel] = useState('');
  const [voiceEnabled, setVoiceEnabled] = useState(true);
  const [showResumePrompt, setShowResumePrompt] = useState(false);
  const [savedSessionState, setSavedSessionState] = useState<any>(null);
  const [startNow, setStartNow] = useState(false);
  const [initPhaseIndex, setInitPhaseIndex] = useState<number | undefined>(undefined);
  const [initSecondsRemaining, setInitSecondsRemaining] = useState<number | undefined>(undefined);
  const [initSummaries, setInitSummaries] = useState<any[] | undefined>(undefined);
  const [showInlineAcc, setShowInlineAcc] = useState(false);
  const [promptText, setPromptText] = useState('');
  const [timeOfDay, setTimeOfDay] = useState<'morning'|'afternoon'|'evening'|'night'>('morning');
  const promptTimersRef = React.useRef<number[]>([]);

  useEffect(() => {
    if (!dailyPathStore.state.hasSeenHabitConquestIntro) {
      setShowIntro(true);
    }
  }, [dailyPathStore.state.hasSeenHabitConquestIntro]);

  // Determine time of day for contextual messaging
  useEffect(() => {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 12) setTimeOfDay('morning');
    else if (hour >= 12 && hour < 17) setTimeOfDay('afternoon');
    else if (hour >= 17 && hour < 21) setTimeOfDay('evening');
    else setTimeOfDay('night');
  }, []);

  useEffect(() => {
    const loadSessionData = async () => {
      try {
        const today = new Date().toISOString().slice(0, 10);
        const countKey = `hc_sessions_${today}`;
        const stateKey = `hc_session_state_${today}`;
        const stored = await AsyncStorage.getItem(countKey);
        if (stored) {
          setCompletedSessionsToday(parseInt(stored, 10) || 0);
        }
        const savedState = await AsyncStorage.getItem(stateKey);
        if (savedState) {
          const parsed = JSON.parse(savedState);
          const age = Date.now() - (parsed.timestamp || 0);
          if (age < 3600000) {
            setSavedSessionState(parsed);
            setShowResumePrompt(true);
          } else {
            await AsyncStorage.removeItem(stateKey);
          }
        }
      } catch {}
    };
    void loadSessionData();
  }, []);

  useEffect(() => {
    if (showIntro) return;
    // Ensure accountability panel is hidden on fresh start
    setShowInlineAcc(false);
    // Do not show accountability on session start; handle after session completes.
  }, [showIntro]);

  // Cleanup on unmount: stop all speech and timers
  useEffect(() => {
    return () => {
      Speech.stop();
      for (const id of promptTimersRef.current) {
        try { clearTimeout(id as any); } catch {}
      }
      promptTimersRef.current = [];
    };
  }, []);

  const getContextualWelcome = useCallback(() => {
    const greetings = {
      morning: 'Good morning',
      afternoon: 'Good afternoon',
      evening: 'Good evening',
      night: 'Welcome back'
    };
    const greeting = greetings[timeOfDay];
    
    if (completedSessionsToday === 0) {
      return `${greeting}. Ready to begin your healing journey today?`;
    } else if (completedSessionsToday < sessionsCount) {
      return `${greeting}. You've completed ${completedSessionsToday} of ${sessionsCount} sessions today. Keep going!`;
    } else {
      return `${greeting}. You've completed all sessions for today. Well done!`;
    }
  }, [timeOfDay, completedSessionsToday, sessionsCount]);

  const getGuideForPhase = useCallback((phaseId: string) => {
    switch (phaseId) {
      case 'affirmation':
        return {
          title: 'Affirmation',
          text: 'Speak your identity in Christ aloud. You are loved, forgiven, and empowered to change. Declare your pledge to radiate goodness today.'
        };
      case 'meditation':
        return {
          title: 'Meditation with God',
          text: 'Sit quietly with God. Notice any thoughts or urges without judgment. Breathe deeply and receive His grace. Let Him renew your mind.'
        };
      case 'mercy':
        return {
          title: 'Prayer for Mercy',
          text: 'Ask God for mercy. He delights to help you in your weakness. Invite His strength to fill the places where you feel powerless.'
        };
      case 'forgiveness':
        return {
          title: 'Prayer for Forgiveness',
          text: 'Confess honestly to God. Receive His forgiveness fully. Release any shame back to the Cross—it has no hold on you.'
        };
      case 'thanksgiving':
        return {
          title: 'Prayer of Thanksgiving',
          text: 'Give thanks for every small victory, for God\'s patience, and for the new path He is building in you. Gratitude strengthens your resolve.'
        };
      default:
        return null;
    }
  }, []);

  const speakPrompt = useCallback((text: string) => {
    if (voiceEnabled) {
      Speech.speak(text, {
        language: 'en',
        pitch: 1.0,
        rate: 0.7,
      });
    }
  }, [voiceEnabled]);

  const clearPromptTimers = useCallback(() => {
    for (const id of promptTimersRef.current) {
      try { clearTimeout(id as any); } catch {}
    }
    promptTimersRef.current = [];
  }, []);

  const stagePromptsForPhase = useCallback((phase: { id: string; minutes: number }) => {
    clearPromptTimers();
    const prompts = getVoicePromptsForPhase(
      phase.id,
      phase.minutes * 60,
      hc?.vice,
      hc?.doorOfSin,
      hc?.pledgeGood,
    );
    const startP = prompts.find(p => p.timing === 'start');
    const midP = prompts.find(p => p.timing === 'middle');
    const endP = prompts.find(p => p.timing === 'end');
    
    if (startP) {
      const tid = setTimeout(() => setPromptText(startP.text), 0) as unknown as number;
      promptTimersRef.current.push(tid);
      const ts = setTimeout(() => speakPrompt(startP.text), 1200) as unknown as number;
      promptTimersRef.current.push(ts);
    }
    if (midP) {
      const tid = setTimeout(() => {
        setPromptText(midP.text);
        speakPrompt(midP.text);
      }, Math.max(1000, (phase.minutes * 60 * 1000) / 2)) as unknown as number;
      promptTimersRef.current.push(tid);
    }
    if (endP) {
      const when = Math.max(1000, (phase.minutes * 60 - 15) * 1000);
      const tid = setTimeout(() => setPromptText(endP.text), when) as unknown as number;
      promptTimersRef.current.push(tid);
    }
  }, [hc, speakPrompt, clearPromptTimers]);

  const handlePhaseComplete = useCallback((phase: ReadingPlanPhase, elapsedSeconds: number) => {
    const phaseId = scaledPhasesRaw.find(p => p.label === phase.label)?.id;
    const phaseIdx = scaledPhasesRaw.findIndex(p => p.label === phase.label);
    if (phaseIdx >= 0 && phaseIdx + 1 < scaledPhasesRaw.length) {
      const nextPhase = scaledPhasesRaw[phaseIdx + 1];
      setCurrentPhaseLabel(nextPhase.label);
      const guide = getGuideForPhase(nextPhase.id);
      if (guide) {
        setCurrentGuide(guide);
        setShowGuide(true);
      }
      stagePromptsForPhase({ id: nextPhase.id, minutes: nextPhase.minutes });
    }
  }, [scaledPhasesRaw, getGuideForPhase, stagePromptsForPhase]);

  const handleStart = useCallback(() => {
    const first = scaledPhasesRaw[0];
    if (first) {
      setCurrentPhaseLabel(first.label);
      const guide = getGuideForPhase(first.id);
      if (guide) {
        setCurrentGuide(guide);
        setShowGuide(true);
      }
      stagePromptsForPhase({ id: first.id, minutes: first.minutes });
    }
  }, [scaledPhasesRaw, getGuideForPhase, stagePromptsForPhase]);

  const formatDate = useCallback((dateKey: string) => {
    const d = new Date(dateKey);
    return d.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
  }, []);

  const handleSubmitCheckin = useCallback(() => {
    const dateKey = checkinQueue[checkinIndex];
    if (dateKey) {
      dailyPathStore.recordHabitConquestCheckin(dateKey, { clean, pledged });
      const nextIndex = checkinIndex + 1;
      if (nextIndex < checkinQueue.length) {
        setCheckinIndex(nextIndex);
        setClean(true);
        setPledged(true);
      } else {
        setModalVisible(false);
        setCheckinQueue([]);
      }
    } else {
      const today = null;
      dailyPathStore.recordHabitConquestCheckin(today, { clean, pledged });
      setModalVisible(false);
    }
  }, [checkinIndex, checkinQueue, clean, pledged, dailyPathStore]);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backText}>Back</Text>
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Habit Conquest</Text>
          {hc?.vice ? <Text style={styles.subtitle}>{hc.vice}</Text> : null}
        </View>
        <TouchableOpacity onPress={() => setVoiceEnabled(!voiceEnabled)} style={styles.voiceBtn}>
          <Text style={styles.voiceText}>{voiceEnabled ? '🔊' : '🔇'}</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => navigation.navigate('HabitConquestProgressScreen')} style={styles.progressBtn}>
          <Text style={styles.progressText}>Progress</Text>
        </TouchableOpacity>
      </View>

      {currentPhaseLabel && (
        <View style={styles.phaseIndicator}>
          <Text style={styles.phaseLabel}>{currentPhaseLabel}</Text>
          <Text style={styles.phaseInstruction}>{promptText || getPhaseInstructions(scaledPhasesRaw.find(p => p.label === currentPhaseLabel)?.id || '')}</Text>
        </View>
      )}

      {!showIntro && !startNow && !showResumePrompt && !showInlineAcc && (
        <View style={{ paddingHorizontal: 16, gap: 12 }}>
          <View style={styles.welcomeCard}>
            <Text style={styles.welcomeText}>{getContextualWelcome()}</Text>
            {completedSessionsToday > 0 && (
              <Text style={styles.sessionProgressText}>
                Session {completedSessionsToday + 1} of {sessionsCount}
              </Text>
            )}
          </View>
          <TouchableOpacity style={styles.accPrimary} onPress={() => setStartNow(true)}>
            <Text style={styles.accPrimaryText}>Begin Session</Text>
          </TouchableOpacity>
        </View>
      )}

      {startNow && !showInlineAcc && (
        <View style={styles.promptCard}>
          <Text style={styles.promptTitle}>Current Guidance</Text>
          <Text style={styles.promptText}>{promptText || 'Preparing your guidance...'}</Text>
        </View>
      )}

      <Modal visible={showIntro} transparent={false} animationType="slide" onRequestClose={() => setShowIntro(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            {introStep === 0 && (
              <>
                <Text style={styles.introTitle}>Welcome to Habit Conquest</Text>
                <Text style={styles.introText}>
                  This is a healing path to overcome vice with grace. Each day, you will spend a few focused minutes with God to renew your mind and strengthen virtue.
                </Text>
              </>
            )}
            {introStep === 1 && (
              <>
                <Text style={styles.introTitle}>How it works</Text>
                <Text style={styles.introText}>
                  Your session moves through stages: Affirmation, Meditation, and Prayer. Each stage helps you heal, draw closer to God, and build lasting change.
                </Text>
              </>
            )}
            {introStep === 2 && (
              <>
                <Text style={styles.introTitle}>Accountability that supports</Text>
                <Text style={styles.introText}>
                  At the end of each day, you will check in: Did you keep your door to temptation shut? Did you do something nice towards being better? This keeps you honest and hopeful.
                </Text>
              </>
            )}
            <View style={styles.introActions}>
              {introStep < 2 ? (
                <>
                  <TouchableOpacity onPress={() => setShowIntro(false)} style={styles.introSkip}>
                    <Text style={styles.introSkipText}>Skip</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => setIntroStep(s => s + 1)} style={styles.introNext}>
                    <Text style={styles.modalPrimaryText}>Next</Text>
                  </TouchableOpacity>
                </>
              ) : (
                <TouchableOpacity
                  onPress={() => {
                    const fn: any = (dailyPathStore as any).setHasSeenHabitConquestIntro;
                    if (typeof fn === 'function') {
                      fn(true);
                    } else {
                      // Defensive fallback for stale instances
                      try {
                        (dailyPathStore as any).state.hasSeenHabitConquestIntro = true;
                        (dailyPathStore as any).saveToStorage?.();
                      } catch {}
                    }
                    setShowIntro(false);
                  }}
                  style={styles.introStart}
                >
                  <Text style={styles.modalPrimaryText}>Start</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        </View>
      </Modal>

      <ReadingTimer
        timerId={`habit-conquest-${new Date().toISOString().slice(0,10)}`}
        phases={timerPhases}
        autoStart={startNow && !showIntro}
        initialPhaseIndex={typeof initPhaseIndex === 'number' ? initPhaseIndex : 0}
        initialSecondsRemaining={typeof initSecondsRemaining === 'number' ? initSecondsRemaining : undefined}
        initialSummaries={initSummaries}
        onStart={handleStart}
        onPhaseComplete={handlePhaseComplete}
        onAllPhasesComplete={async () => {
          // Stop all voice prompts and timers immediately
          Speech.stop();
          clearPromptTimers();
          
          const newCount = completedSessionsToday + 1;
          setCompletedSessionsToday(newCount);
          try {
            const today = new Date().toISOString().slice(0, 10);
            const key = `hc_sessions_${today}`;
            await AsyncStorage.setItem(key, String(newCount));
            await AsyncStorage.removeItem(`hc_session_state_${today}`);
          } catch {}
          const isLastSession = newCount >= sessionsCount;
          if (isLastSession) {
            const missing = dailyPathStore.getMissingHabitConquestDates();
            setCheckinQueue([...(Array.isArray(missing) ? missing : []), 'today']);
            setCheckinIndex(0);
            setClean(true);
            setPledged(true);
            setModalVisible(true);
          } else {
            const message = getCelebrationMessage(false, newCount, sessionsCount, true, true);
            setCelebrationMessage(message);
            setShowCelebration(true);
          }
        }}
      />

      <Modal visible={showGuide} transparent animationType="fade" onRequestClose={() => setShowGuide(false)}>
        <View style={styles.guideOverlay}>
          <View style={styles.guideCard}>
            {currentGuide && (
              <>
                <Text style={styles.guideTitle}>{currentGuide.title}</Text>
                <Text style={styles.guideText}>{currentGuide.text}</Text>
                <TouchableOpacity
                  style={styles.guideContinue}
                  onPress={() => setShowGuide(false)}
                >
                  <Text style={styles.modalPrimaryText}>Continue</Text>
                </TouchableOpacity>
              </>
            )}
          </View>
        </View>
      </Modal>

      {showInlineAcc ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 16 }}>
          <View style={styles.accCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.accTitle}>Daily accountability</Text>
              {(() => {
                const key = (checkinQueue.length && checkinQueue[checkinIndex] && checkinQueue[checkinIndex] !== 'today') ? checkinQueue[checkinIndex] : null;
                const d = key ? new Date(key) : new Date();
                const day = d.toLocaleDateString(undefined, { weekday: 'long' });
                const date = d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
                const count = checkinQueue.length > 1 ? ` • ${checkinIndex + 1}/${checkinQueue.length}` : '';
                return (
                  <Text style={styles.accSubtitle}>{day} • {date}{count}</Text>
                );
              })()}
            </View>
            <View style={[styles.checkRow, { marginTop: 16 }]}>
              <TouchableOpacity
                style={[styles.checkBox, clean && styles.checkBoxChecked]}
                onPress={() => setClean(!clean)}
                activeOpacity={0.85}
              >
                {clean ? <Text style={styles.checkTick}>✓</Text> : null}
              </TouchableOpacity>
              <Text style={styles.checkLabelLarge}>Kept my door to temptation shut</Text>
            </View>
            <View style={[styles.checkRow, { marginTop: 16 }]}>
              <TouchableOpacity
                style={[styles.checkBox, pledged && styles.checkBoxChecked]}
                onPress={() => setPledged(!pledged)}
                activeOpacity={0.85}
              >
                {pledged ? <Text style={styles.checkTick}>✓</Text> : null}
              </TouchableOpacity>
              <Text style={styles.checkLabelLarge}>Did something nice today to help myself grow</Text>
            </View>
            <View style={[styles.modalActions, { marginTop: 28 }]}>
              <TouchableOpacity style={styles.accPrimary} onPress={() => {
                if (checkinQueue.length && checkinQueue[checkinIndex] === 'today') {
                  dailyPathStore.recordHabitConquestCheckin(null, { clean, pledged });
                  dailyPathStore.markStepComplete('habit_conquest');
                  setShowInlineAcc(false);
                  const message = getCelebrationMessage(true, completedSessionsToday + 1, sessionsCount, clean, pledged);
                  setCelebrationMessage(message);
                  setShowCelebration(true);
                  return;
                }
                handleSubmitCheckin();
              }}>
                <Text style={styles.accPrimaryText}>{checkinIndex < checkinQueue.length - 1 ? 'Save & Next' : 'Save'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      ) : null}

      <Modal visible={showCelebration} transparent animationType="fade" onRequestClose={() => setShowCelebration(false)}>
        <View style={styles.celebrationOverlay}>
          <View style={styles.celebrationCard}>
            <Text style={styles.celebrationEmoji}>🎉</Text>
            <Text style={styles.celebrationTitle}>Session Complete!</Text>
            <Text style={styles.celebrationMessage}>{celebrationMessage}</Text>
            <TouchableOpacity
              style={styles.celebrationButton}
              onPress={() => {
                setShowCelebration(false);
                navigation.goBack();
              }}
            >
              <Text style={styles.modalPrimaryText}>Done</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      <Modal visible={showResumePrompt} transparent animationType="fade" onRequestClose={() => setShowResumePrompt(false)}>
        <View style={styles.celebrationOverlay}>
          <View style={styles.celebrationCard}>
            <Text style={styles.celebrationTitle}>Resume Session?</Text>
            <Text style={styles.celebrationMessage}>You have an unfinished session from earlier. Would you like to continue where you left off?</Text>
            <View style={styles.resumeActions}>
              <TouchableOpacity
                style={styles.resumeSecondary}
                onPress={() => {
                  setShowResumePrompt(false);
                  setSavedSessionState(null);
                  setInitPhaseIndex(0);
                  setInitSecondsRemaining(undefined);
                  setInitSummaries(undefined);
                }}
              >
                <Text style={styles.resumeSecondaryText}>Start Fresh</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.resumePrimary}
                onPress={() => {
                  setShowResumePrompt(false);
                  if (savedSessionState) {
                    setInitPhaseIndex(Number(savedSessionState.phaseIndex) || 0);
                    setInitSecondsRemaining(Number(savedSessionState.secondsRemaining) || undefined);
                    setInitSummaries(Array.isArray(savedSessionState.phaseSummaries) ? savedSessionState.phaseSummaries : undefined);
                  }
                  setStartNow(true);
                }}
              >
                <Text style={styles.modalPrimaryText}>Resume</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background, padding: 16, gap: 12 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  backBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface },
  backText: { color: theme.colors.text.primary },
  title: { color: theme.colors.text.primary, fontWeight: '700', fontSize: 18 },
  subtitle: { color: theme.colors.text.secondary, fontSize: 12, marginTop: 2 },
  progressBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface },
  progressText: { color: theme.colors.primary, fontWeight: '600' },
  modalOverlay: { flex: 1, backgroundColor: theme.colors.background, justifyContent: 'center', padding: 20 },
  modalCard: { backgroundColor: theme.colors.background, borderRadius: 16, padding: 16, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  modalHeader: { marginBottom: 8 },
  modalTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 18 },
  modalSubtitle: { color: theme.colors.text.secondary, marginTop: 4, marginBottom: 12 },
  modalQuestion: { color: theme.colors.text.primary, flex: 1, paddingRight: 12 },
  checkRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  checkBox: { width: 24, height: 24, borderRadius: 8, borderWidth: 2, borderColor: theme.colors.border, backgroundColor: theme.colors.surface, alignItems: 'center', justifyContent: 'center' },
  checkBoxChecked: { backgroundColor: `${(theme as any).colors.primary}22`, borderColor: theme.colors.primary },
  checkTick: { color: theme.colors.primary, fontWeight: '800', lineHeight: 18 },
  checkLabel: { color: theme.colors.text.primary, fontWeight: '500' },
  rowBetween: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  toggleRow: { flexDirection: 'row', gap: 8 },
  toggleBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  toggleActive: { backgroundColor: `${(theme as any).colors.primary}15`, borderColor: theme.colors.primary },
  toggleText: { color: theme.colors.text.secondary },
  toggleTextActive: { color: theme.colors.primary, fontWeight: '600' },
  modalActions: { marginTop: 16 },
  modalPrimary: { backgroundColor: theme.colors.primary, borderRadius: 12, paddingVertical: 10, alignItems: 'center' },
  modalPrimaryText: { color: theme.colors.text.inverse, fontWeight: '700' },
  introSkipText: { color: theme.colors.text.primary, fontWeight: '700' },
  introTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 18, marginBottom: 8 },
  introText: { color: theme.colors.text.secondary, marginBottom: 12 },
  introActions: { flexDirection: 'row', gap: 12, justifyContent: 'flex-end', marginTop: 8 },
  introSkip: { paddingVertical: 10, paddingHorizontal: 14, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  introNext: { paddingVertical: 10, paddingHorizontal: 14, borderRadius: 12, backgroundColor: theme.colors.primary },
  introStart: { paddingVertical: 10, paddingHorizontal: 14, borderRadius: 12, backgroundColor: theme.colors.primary },
  guideOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'center', padding: 20 },
  guideCard: { backgroundColor: theme.colors.background, borderRadius: 16, padding: 20, borderWidth: 2, borderColor: theme.colors.primary },
  guideTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 20, marginBottom: 12 },
  guideText: { color: theme.colors.text.secondary, fontSize: 15, lineHeight: 22, marginBottom: 16 },
  guideContinue: { backgroundColor: theme.colors.primary, borderRadius: 12, paddingVertical: 12, alignItems: 'center' },
  voiceBtn: { paddingHorizontal: 12, paddingVertical: 8, borderRadius: 12, backgroundColor: theme.colors.surface },
  voiceText: { fontSize: 18 },
  phaseIndicator: { padding: 16, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  phaseLabel: { color: theme.colors.text.primary, fontWeight: '700', fontSize: 16, marginBottom: 6 },
  phaseInstruction: { color: theme.colors.text.secondary, fontSize: 13, lineHeight: 18 },
  celebrationOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.85)', justifyContent: 'center', alignItems: 'center', padding: 20 },
  celebrationCard: { backgroundColor: theme.colors.background, borderRadius: 20, padding: 24, maxWidth: 340, width: '100%', alignItems: 'center' },
  celebrationEmoji: { fontSize: 48, marginBottom: 12 },
  celebrationTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 22, marginBottom: 12, textAlign: 'center' },
  celebrationMessage: { color: theme.colors.text.secondary, fontSize: 15, lineHeight: 22, textAlign: 'center', marginBottom: 20 },
  celebrationButton: { backgroundColor: theme.colors.primary, borderRadius: 12, paddingVertical: 14, paddingHorizontal: 32, width: '100%', alignItems: 'center' },
  resumeActions: { flexDirection: 'row', gap: 12, width: '100%', marginTop: 8 },
  resumeSecondary: { flex: 1, paddingVertical: 12, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, alignItems: 'center' },
  resumeSecondaryText: { color: theme.colors.text.primary, fontWeight: '600' },
  resumePrimary: { flex: 1, paddingVertical: 12, borderRadius: 12, backgroundColor: theme.colors.primary, alignItems: 'center' },
  accOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.6)', justifyContent: 'center', alignItems: 'center', padding: 20 },
  accCard: { width: '92%', maxWidth: 420, backgroundColor: theme.colors.background, borderRadius: 20, padding: 22, borderWidth: 2, borderColor: theme.colors.primary },
  accTitle: { color: theme.colors.text.primary, fontWeight: '900', fontSize: 22, textAlign: 'center' },
  accSubtitle: { color: theme.colors.text.secondary, marginTop: 6, marginBottom: 16, textAlign: 'center' },
  checkLabelLarge: { color: theme.colors.text.primary, fontSize: 16, lineHeight: 22, fontWeight: '600', flex: 1 },
  accPrimary: { backgroundColor: theme.colors.primary, borderRadius: 14, paddingVertical: 14, alignItems: 'center' },
  accPrimaryText: { color: theme.colors.text.inverse, fontWeight: '800', fontSize: 16 },
  promptCard: { marginHorizontal: 16, marginBottom: 12, padding: 14, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  promptTitle: { color: theme.colors.text.primary, fontWeight: '700', marginBottom: 6 },
  promptText: { color: theme.colors.text.secondary },
  welcomeCard: { padding: 16, borderRadius: 12, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  welcomeText: { color: theme.colors.text.primary, fontSize: 16, lineHeight: 22, marginBottom: 8 },
  sessionProgressText: { color: theme.colors.text.secondary, fontSize: 14, fontWeight: '600' },
});

export default HabitConquestSessionScreen;
