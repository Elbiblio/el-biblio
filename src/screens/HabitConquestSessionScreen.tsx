import React, { useMemo, useEffect, useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Modal } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Speech from 'expo-speech';
import { useTheme } from '@/contexts/ThemeContext';
import ReadingTimer from '@/components/ReadingTimer';
import { useDailyPathStore } from '@/stores/StoreProvider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import type { ReadingPlanPhase } from '@/constants/readingPlanModes';
import { getCelebrationMessage, getPhaseInstructions } from '@/modules/habitConquestVoicePrompts';
import { HabitConquerOrchestrator } from '@/services/HabitConquerOrchestrator';

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

  const timerPhases: ReadingPlanPhase[] = React.useMemo(
    () => HabitConquerOrchestrator.toReadingTimerPhases(scaledPhasesRaw),
    [scaledPhasesRaw],
  );

  const [showIntro, setShowIntro] = useState(false);
  const [introStep, setIntroStep] = useState(0);
  const [showGuide, setShowGuide] = useState(false);
  const [currentGuide, setCurrentGuide] = useState<{title: string; text: string} | null>(null);
  const [completedSessionsToday, setCompletedSessionsToday] = useState(0);
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
  const [promptText, setPromptText] = useState('');
  const [timeOfDay, setTimeOfDay] = useState<'morning'|'afternoon'|'evening'|'night'>('morning');
  const orchestratorRef = useRef<HabitConquerOrchestrator | null>(null);

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
    orchestratorRef.current?.stop();
    orchestratorRef.current = new HabitConquerOrchestrator({
      getConfig: () => ({
        phases: scaledPhasesRaw,
        vice: hc?.vice ?? null,
        doorOfSin: hc?.doorOfSin ?? null,
        pledgeGood: hc?.pledgeGood ?? null,
        voiceEnabled,
      }),
      callbacks: {
        onPrompt: (text) => setPromptText(text),
        onGuide: (guide) => {
          if (!guide) return;
          setCurrentGuide(guide);
          setShowGuide(true);
        },
      },
    });
    return () => {
      orchestratorRef.current?.stop();
    };
  }, [scaledPhasesRaw, hc?.vice, hc?.doorOfSin, hc?.pledgeGood, voiceEnabled]);

  useEffect(() => {
    return () => {
      orchestratorRef.current?.stop();
      Speech.stop();
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

  const handlePhaseComplete = useCallback((phase: ReadingPlanPhase, elapsedSeconds: number) => {
    const phaseId = scaledPhasesRaw.find(p => p.label === phase.label)?.id;
    const phaseIdx = scaledPhasesRaw.findIndex(p => p.label === phase.label);
    if (phaseIdx >= 0 && phaseIdx + 1 < scaledPhasesRaw.length) {
      const nextPhase = scaledPhasesRaw[phaseIdx + 1];
      setCurrentPhaseLabel(nextPhase.label);
      orchestratorRef.current?.startPhaseByLabel(nextPhase.label);
    } else {
      orchestratorRef.current?.stop();
    }
  }, [scaledPhasesRaw]);

  const handleStart = useCallback(() => {
    const first = scaledPhasesRaw[0];
    if (first) {
      setCurrentPhaseLabel(first.label);
      orchestratorRef.current?.startPhaseByLabel(first.label);
    }
  }, [scaledPhasesRaw]);

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

      {!showIntro && !startNow && !showResumePrompt && (
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

      {startNow && (
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
          orchestratorRef.current?.stop();
          
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
            const todayKey = new Date().toISOString().slice(0, 10);
            const pendingDates = Array.from(new Set([...(Array.isArray(missing) ? missing : []), todayKey]));
            navigation.navigate('HabitConquestReflectionScreen', { pendingDates });
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
