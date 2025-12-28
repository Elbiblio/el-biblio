import React, { useCallback, useEffect, useMemo, useState, useRef } from 'react';
import { observer } from 'mobx-react-lite';

import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  FlatList,
  Modal,
  Alert,
  AppState,
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  Animated,
  Switch,
  NativeScrollEvent,
  NativeSyntheticEvent,
  TouchableWithoutFeedback,
  LayoutChangeEvent,
  ViewToken,
  SafeAreaView,
  PanResponder,
  GestureResponderEvent,
  PanResponderGestureState,
} from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { useNavigation, NavigationProp, RouteProp, useFocusEffect } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import HistoryModal, { HistoryModalEntry } from '@/components/HistoryModal';
import FontSizeModal from '@/components/FontSizeModal';
import VerseActionsSheet from '@/components/VerseActionsSheet';
import BibleDBService from '@/utils/database';
import VerseComparisonModal from '@/components/VerseComparisonModal';
import ReadingPlanSetupModal from '@/components/ReadingPlanSetupModal';
import ReminderTimePicker from '@/components/ReminderTimePicker';
import PlanSegmentChip from '@/components/PlanSegmentChip';
import OverlayHost from '@/components/OverlayHost';
import { Book, BibleVersion, BibleVerse } from '@/types';
import { ReadingPlanMode, ReadingPlanPhase } from '@/constants/readingPlanModes';
import { bibleBooks } from '@/constants/bibleBooks';
import { useBibleStore } from '@/stores/BibleStore';
import { useJourneyStore, useDailyPathStore, useAuthStore } from '@/stores/StoreProvider';
import { ReminderSyncService } from '@/services/reminderSync';
import { useSharedValue, withTiming } from 'react-native-reanimated';
import { HistoryEntry, DailyPhaseProgress } from '@/stores/BibleStore';

import { RootStackParamList, ScopedVerseParam } from '@/types';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';
import { Audio } from 'expo-av';
import { setExclusiveAudioMode, setMixingAudioMode } from '@/services/audio';
import EmptyState from '@/components/EmptyState';
import MeditationVerse from '@/components/MeditationVerse';
import { appTimerStore } from '@/stores/AppTimerStore';
import { useKeepAwake } from 'expo-keep-awake';

// Modular components
import {
  ScopedViewState,
  TestamentFilter,
  CreatePlanParams,
  getLocalMidnightMs,
  makeVerseKey,
  parseVerseAddress,
  makeSegmentRangeToken,
  isNewTestamentAbbr,
  TESTAMENT_FILTER_KEY,
  formatSegmentLabel,
  formatTime,
  BibleHeader,
  VerseItem,
  SearchModal,
  VersionsModal,
  ScopedViewModal,
  TimerModal,
  AIInsightsModal,
  AdvancedActionsModal,
  createBibleStyles,
} from './bible';

// Utility functions and types are now imported from ./bible

interface BibleScreenProps {
  route?: RouteProp<RootStackParamList, 'BibleScreen'>;
}

const BibleScreen = ({ route }: BibleScreenProps) => {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const isAdvancingSegmentRef = useRef(false);
  const verseListRef = useRef<FlatList<BibleVerse>>(null);
  const pendingScrollVerseRef = useRef<number | null>(null);
  const verseLayoutMapRef = useRef(new Map<string, { offset: number; height: number }>());
  const lastAutoScrollKeyRef = useRef<string | null>(null);
  const currentVisibleVerseRef = useRef<{ id: string; verse: number; chapter: number } | null>(null);
  const viewabilityConfigRef = useRef({ itemVisiblePercentThreshold: 25 });
  const listDimensionsRef = useRef({ height: 0 });
  const lastAppliedParamsRef = useRef<string | null>(null);

  // Network status
  const { isOffline } = useNetworkStatus();

  // Bible store
  const bibleStore = useBibleStore();
  const journeyStore = useJourneyStore();
  const dailyPathStore = useDailyPathStore();
  const { user } = useAuthStore();

  // Local state for UI
  const [showVersionsModal, setShowVersionsModal] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [showAdvancedActions, setShowAdvancedActions] = useState(false);
  const [showFontModal, setShowFontModal] = useState(false);
  const [showVerseActions, setShowVerseActions] = useState(false);
  const [showComparisonModal, setShowComparisonModal] = useState(false);
  const [showAIInsights, setShowAIInsights] = useState(false);
  const resumeTarget = bibleStore.resumeTarget;
  const [isPlanSetupVisible, setIsPlanSetupVisible] = useState(false);
  const [showCompactPlan, setShowCompactPlan] = useState(false);
  const [planDetailsExpanded, setPlanDetailsExpanded] = useState(false);
  // Local controller type removed; timer is globally managed via AppTimerStore

  const [showTimerModal, setShowTimerModal] = useState(false);
  const [showMeditationMode, setShowMeditationMode] = useState(false);
  const [meditationVerses, setMeditationVerses] = useState<Array<{ text: string; reference: string }>>([]);
  // Paused verses are persisted in BibleStore.dailySession
  const [insightByKey, setInsightByKey] = useState<Record<string, string>>({});
  const [testamentFilter, setTestamentFilter] = useState<'all' | 'ot' | 'nt'>('all');
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const stored = await AsyncStorage.getItem(TESTAMENT_FILTER_KEY);
        if (!stored) return;
        if (stored === 'all' || stored === 'ot' || stored === 'nt') {
          if (!cancelled) {
            setTestamentFilter(stored as 'all' | 'ot' | 'nt');
          }
        }
      } catch { }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    AsyncStorage.setItem(TESTAMENT_FILTER_KEY, testamentFilter).catch(() => { });
  }, [testamentFilter]);


  // Timer view derived from AppTimerStore via BibleStore
  const timerId = bibleStore.getTodayTimerIdPublic();
  const tv = timerId ? appTimerStore.get(timerId) : null;

  const [atEnd, setAtEnd] = useState(false);
  const [builderReminder, setBuilderReminder] = useState('');
  const [showFloatingProgress, setShowFloatingProgress] = useState(false);
  const idleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [scopedView, setScopedView] = useState<ScopedViewState | null>(null);
  const progressShared = useSharedValue(0);
  const routeParams = route?.params ?? null;
  const [showDoneOverlay, setShowDoneOverlay] = useState(false);
  const hasShownCompletionToastRef = useRef(false);

  const goToNextChapterGeneric = useCallback(async () => {
    if (!bibleStore.currentBook || !bibleStore.currentVersion) return;
    const nextChapter = Math.max(1, (bibleStore.currentChapter || 1) + 1);
    const lastInBook = bibleStore.currentBook.chapters || nextChapter;
    if (nextChapter > lastInBook) return;
    await bibleStore.fetchVerses(bibleStore.currentBook, nextChapter, bibleStore.currentVersion, 1);
  }, [bibleStore]);

  // Use exclusive audio only while Bible screen is focused
  useFocusEffect(
    React.useCallback(() => {
      setExclusiveAudioMode().catch(() => { });
      return () => {
        setMixingAudioMode().catch(() => { });
      };
    }, [])
  );



  const resetIdleTimer = useCallback(() => {
    if (idleTimerRef.current) {
      clearTimeout(idleTimerRef.current);
    }
    idleTimerRef.current = setTimeout(() => setShowFloatingProgress(true), 5000);
  }, []);

  const phasesForToday = useMemo(() => {
    const plan = bibleStore.readingPlan;
    if (plan?.phases && plan.phases.length > 0) return plan.phases;
    if (plan) {
      const minutes = Math.max(1, Math.floor(plan.timePerDay || 15));
      return [
        {
          id: 'reading',
          label: 'Reading',
          minutes,
          hint: "Focus on today's passage",
        } as ReadingPlanPhase,
      ];
    }
    return [] as ReadingPlanPhase[];
  }, [bibleStore.readingPlan]);

  const formatSegmentLabel = useCallback((seg: any) => {
    if (!seg) return 'Next segment';
    const vs = seg.verseStart ?? seg.startVerse ?? seg.start_verse ?? null;
    const ve = seg.verseEnd ?? seg.endVerse ?? seg.end_verse ?? null;
    const sameChapter = (seg.chapterEnd ?? seg.chapterStart) === seg.chapterStart;
    if (vs || ve) {
      if (sameChapter) {
        const right = ve ? `-${ve}` : '';
        const left = vs ? `:${vs}` : '';
        return `${seg.bookName} ${seg.chapterStart}${left}${right}`;
      }
      const left = vs ? `:${vs}` : '';
      const right = ve ? `:${ve}` : '';
      return `${seg.bookName} ${seg.chapterStart}${left}-${seg.chapterEnd}${right}`;
    }
    return `${seg.bookName} ${seg.chapterStart}${(seg.chapterEnd ?? seg.chapterStart) !== seg.chapterStart ? `-${seg.chapterEnd}` : ''}`;
  }, []);

  const totalPlanSeconds = useMemo(
    () => phasesForToday.reduce((sum, phase) => sum + phase.minutes * 60, 0),
    [phasesForToday]
  );

  const planRemainingSeconds = useMemo(() => {
    const timerId = bibleStore.getTodayTimerIdPublic();
    // Access appTimerStore.timers to ensure reactivity when timer state changes
    const _timers = appTimerStore.timers;
    return timerId ? appTimerStore.totalRemaining(timerId) : null;
  }, [bibleStore, appTimerStore.timers]);

  // Auto-hide header on scroll
  const scrollY = useRef(new Animated.Value(0)).current;
  const clampedY = useRef(Animated.diffClamp(scrollY, 0, 56)).current;
  const headerTranslateY = clampedY.interpolate({
    inputRange: [0, 56],
    outputRange: [0, -56],
  });

  useKeepAwake('bible-screen');

  const lastAtEndRef = useRef(false);

  const handleScrollNearEnd = useCallback((event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const { layoutMeasurement, contentOffset, contentSize } = event.nativeEvent;
    const nearEnd = layoutMeasurement.height + contentOffset.y >= contentSize.height - 40;
    setAtEnd(nearEnd);
    setShowFloatingProgress(false);
    resetIdleTimer();
  }, [resetIdleTimer]);

  useEffect(() => {
    return () => {
      if (idleTimerRef.current) {
        clearTimeout(idleTimerRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (atEnd && !lastAtEndRef.current) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    lastAtEndRef.current = atEnd;
  }, [atEnd]);

  useEffect(() => {
    try {
      (navigation as any).setOptions?.({ gestureEnabled: !atEnd });
    } catch { }
  }, [atEnd, navigation]);

  useEffect(() => {
    if (!bibleStore.isPlanMode) {
      setShowFloatingProgress(false);
      if (idleTimerRef.current) {
        clearTimeout(idleTimerRef.current);
        idleTimerRef.current = null;
      }
    }
  }, [bibleStore.isPlanMode]);

  useEffect(() => {
    if (bibleStore.isPlanMode && bibleStore.activeReadingSegment?.id && !bibleStore.dailySession?.completed) {
      setShowCompactPlan(true);
      resetIdleTimer();
    }
  }, [bibleStore.isPlanMode, bibleStore.activeReadingSegment?.id, bibleStore.dailySession?.completed, resetIdleTimer]);

  useEffect(() => {
    if (bibleStore.dailySession?.completed) {
      setShowFloatingProgress(false);
    }
  }, [bibleStore.dailySession?.completed]);

  // Paused verses are persisted per daily session; no local reset needed

  // Auto-hide the completion overlay after 5 seconds when the day completes
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout> | null = null;
    if (bibleStore.dailySession?.completed) {
      setShowDoneOverlay(true);
      timer = setTimeout(() => setShowDoneOverlay(false), 5000);
    } else {
      setShowDoneOverlay(false);
    }
    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [bibleStore.dailySession?.completed]);

  // Prepare daily session state when plan mode is active; restore timer state accurately on return
  useEffect(() => {
    let mounted = true;
    (async () => {
      if (!bibleStore.isPlanMode || !bibleStore.readingPlan) return;
      await bibleStore.ensureDailySessionPrepared();
      if (!mounted) return;
      const session = bibleStore.dailySession;
      // Only auto-open timer if session exists and has progress or active phases
      if (session && !session.completed) {
        const hasProgress = session.phases.some(p => p.elapsedSeconds > 0) ||
          (session.secondsRemainingInPhase < ((phasesForToday[session.currentPhaseIndex]?.minutes ?? 0) * 60));
        // Don't auto-open if user was in meditation/contemplation and minimized
        setShowTimerModal(hasProgress && session.currentPhaseIndex === 0);
      }
    })();
    return () => {
      mounted = false;
    };
  }, [bibleStore.isPlanMode, bibleStore.readingPlan?.id]);

  // Build meditation verses list from the current segment (can span multiple chapters)
  useEffect(() => {
    const buildMeditationList = async () => {
      if (!showMeditationMode) return;
      const seg = bibleStore.activeReadingSegment;
      const planTable = bibleStore.readingPlan?.versionTable ?? bibleStore.currentVersion?.tableName;
      if (!seg || !planTable) {
        setMeditationVerses([]);
        return;
      }
      try {
        await BibleDBService.initialize?.();
      } catch { }
      const verses: Array<{ text: string; reference: string }> = [];
      const start = Math.max(1, seg.chapterStart);
      const end = Math.max(start, seg.chapterEnd ?? seg.chapterStart);
      for (let ch = start; ch <= end; ch++) {
        try {
          const rows: any[] = await (BibleDBService as any).getChapter(planTable, seg.bookAbbreviation, ch);
          for (const v of rows) {
            verses.push({ text: v.text, reference: `${seg.bookName} ${ch}:${v.verse}` });
            if (verses.length >= 200) break;
          }
          if (verses.length >= 200) break;
        } catch (e) {
          // ignore chapter errors and continue
        }
      }
      setMeditationVerses(verses);
    };
    void buildMeditationList();
  }, [showMeditationMode, bibleStore.activeReadingSegment?.id, bibleStore.readingPlan?.versionTable]);

  // Prefetch insights for paused/marked verses in contemplation mode
  useEffect(() => {
    const run = async () => {
      const tid = bibleStore.getTodayTimerIdPublic();
      if (!tid) return;
      const t = appTimerStore.get(tid);
      if (!t) return;
      const curPhase = phasesForToday[t.currentPhaseIndex];
      if (!curPhase || curPhase.id !== 'contemplation') return;
      const paused = bibleStore.getPausedMeditationVersesScoped?.() ?? [];
      if (!paused.length) return;
      // Fetch insights sequentially for stability and store locally by key
      for (const p of paused) {
        const key = `${p.reference}::${p.text}`;
        if (insightByKey[key]) continue;
        try {
          // Try to locate a BibleVerse matching this paused verse from current list
          const bv = bibleStore.verses.find(v => (v.reference && p.reference && v.reference === p.reference) || (v.text && p.text && v.text.trim() === p.text.trim())) || null;
          if (!bv) continue;
          await bibleStore.explainVerse(bv);
          const joined = (bibleStore.aiInsightSections || []).map(s => s.content).filter(Boolean).join('\n\n');
          if (joined && joined.trim().length) {
            setInsightByKey(prev => ({ ...prev, [key]: joined.trim() }));
          }
        } catch { }
      }
    };
    void run();
  }, [showMeditationMode, bibleStore.dailySession?.pausedMeditationVerses?.length, phasesForToday, tv?.currentPhaseIndex]);

  useEffect(() => {
    if (!totalPlanSeconds || planRemainingSeconds == null) {
      progressShared.value = withTiming(0, { duration: 250 });
      return;
    }
    const ratio = Math.max(0, Math.min(1, 1 - planRemainingSeconds / totalPlanSeconds));
    progressShared.value = withTiming(ratio, { duration: 250 });
  }, [planRemainingSeconds, totalPlanSeconds, progressShared]);

  useEffect(() => {
    if (showTimerModal) {
      setShowFloatingProgress(false);
      if (idleTimerRef.current) {
        clearTimeout(idleTimerRef.current);
        idleTimerRef.current = null;
      }
    } else if (bibleStore.isPlanMode && phasesForToday.length) {
      resetIdleTimer();
    }
  }, [showTimerModal, bibleStore.isPlanMode, phasesForToday.length, resetIdleTimer]);

  // React to phase changes: when entering a non-reading phase, show meditation view; otherwise show timer modal
  useEffect(() => {
    if (!bibleStore.isPlanMode) return;
    const tid = bibleStore.getTodayTimerIdPublic();
    if (!tid) return;
    const t = appTimerStore.get(tid);
    if (!t) return;
    const curPhase = phasesForToday[t.currentPhaseIndex];
    if (!curPhase) return;
    const isReading = curPhase.id === 'reading';
    if (isReading) {
      if (t.isActive) {
        if (showTimerModal) setShowTimerModal(false);
      } else {
        if (!showTimerModal) setShowTimerModal(true);
      }
      if (showMeditationMode) setShowMeditationMode(false);
    } else {
      if (!t.isActive) appTimerStore.resume(tid);
      if (!showMeditationMode) setShowMeditationMode(true);
      if (showTimerModal) setShowTimerModal(false);
      // If entering contemplation phase and there are no paused verses, cap remaining time to 2 minutes for silent listening
      if (curPhase.id === 'contemplation') {
        try {
          const pausedScoped = bibleStore.getPausedMeditationVersesScoped?.() ?? [];
          const remaining = appTimerStore.remainingInPhase(tid);
          if ((pausedScoped.length === 0) && remaining > 120) {
            const phases = t.phases.map(p => ({ id: p.id, label: p.label, plannedSeconds: p.plannedSeconds }));
            const summaries = t.summaries.map(s => ({ id: s.id, label: s.label, plannedSeconds: s.plannedSeconds, elapsedSeconds: s.elapsedSeconds }));
            appTimerStore.setFromSnapshot(
              tid,
              phases,
              t.currentPhaseIndex,
              120,
              summaries,
              true,
              t.completed
            );
          }
        } catch { }
      }
    }
  }, [bibleStore.isPlanMode, phasesForToday, appTimerStore.now, showTimerModal, showMeditationMode]);

  useEffect(() => {
    isAdvancingSegmentRef.current = false;
  }, [bibleStore.activeReadingSegment?.id]);

  // Phase completion handlers (moved up to avoid use-before-declaration)
  const handlePhaseComplete = useCallback(async (phase: ReadingPlanPhase, elapsed: number) => {
    console.log('Phase complete:', phase.label, 'elapsed', elapsed);
    try {
      const { sound } = await Audio.Sound.createAsync(require('../../assets/sounds/bell.wav'));
      await sound.playAsync();
      sound.setOnPlaybackStatusUpdate(status => {
        if (status.isLoaded && status.didJustFinish) {
          sound.unloadAsync();
        }
      });
    } catch (error) {
      console.warn('Could not play phase chime', error);
    }
  }, []);

  const handleAllPhasesComplete = useCallback(async () => {
    if (hasShownCompletionToastRef.current) return;
    hasShownCompletionToastRef.current = true;
    toast.success('Daily reading complete! 🎉');
    try {
      const { sound } = await Audio.Sound.createAsync(require('../../assets/sounds/cheers.mp3'));
      await sound.playAsync();
      sound.setOnPlaybackStatusUpdate(status => {
        if (status.isLoaded && status.didJustFinish) {
          sound.unloadAsync();
        }
      });
    } catch (error) {
      console.warn('Could not play completion chime', error);
    }
    const seg = bibleStore.activeReadingSegment;
    if (seg) {
      await bibleStore.markSegmentComplete(seg.id);
      const chapters = Math.max(0, (seg.chapterEnd ?? seg.chapterStart) - seg.chapterStart + 1);
      if (chapters > 0) {
        await bibleStore.incrementChaptersCompletedBy(chapters);
      }
    }
    await bibleStore.markTodaySessionCompleted();
    // Immediately collapse compact UI for the day
    setShowFloatingProgress(false);
    setShowCompactPlan(false);
    try { dailyPathStore.markStepComplete('knowledge'); } catch { }
  }, [bibleStore]);

  // React to timer completion from AppTimerStore
  useEffect(() => {
    if (!bibleStore.isPlanMode || !tv) return;
    if (tv.completed && !bibleStore.dailySession?.completed) {
      void handleAllPhasesComplete();
      setShowTimerModal(false);
    }
  }, [tv?.completed, bibleStore.isPlanMode, bibleStore.dailySession?.completed, handleAllPhasesComplete]);

  const completeCurrentPhase = useCallback(async () => {
    const timerId = bibleStore.getTodayTimerIdPublic();
    if (!timerId) return;

    const timer = appTimerStore.get(timerId);
    if (!timer) return;

    const phase = phasesForToday[timer.currentPhaseIndex];
    if (phase) {
      try {
        await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      } catch { }

      // Fire-and-forget chime
      void handlePhaseComplete(phase, timer.elapsedInCurrentPhase);
    }

    appTimerStore.advancePhase(timerId);
  }, [phasesForToday, handlePhaseComplete, bibleStore]);

  // Pause timer when app goes to background
  useEffect(() => {
    const sub = AppState.addEventListener('change', (state) => {
      if (state !== 'active') {
        const timerId = bibleStore.getTodayTimerIdPublic();
        if (timerId) {
          appTimerStore.pause(timerId);
        }
      }
    });
    return () => sub.remove();
  }, [bibleStore]);

  const advanceToNextSegment = useCallback(async () => {
    if (!bibleStore.isPlanMode) {
      return;
    }
    const segment = bibleStore.activeReadingSegment;
    if (!segment || isAdvancingSegmentRef.current) {
      return;
    }

    isAdvancingSegmentRef.current = true;

    try {
      const moved = await bibleStore.markSegmentComplete(segment.id);
      if (moved) {
        await bibleStore.markTodaySessionCompleted();
        try {
          const { sound } = await Audio.Sound.createAsync(
            require('../../assets/sounds/bell.wav')
          );
          await sound.playAsync();
          sound.setOnPlaybackStatusUpdate(status => {
            if (status.isLoaded && status.didJustFinish) {
              sound.unloadAsync();
            }
          });
        } catch (error) {
          console.warn('Could not play next segment chime', error);
        }

        setShowTimerModal(false);
        setTimeout(() => {
          verseListRef.current?.scrollToOffset({ offset: 0, animated: true });
        }, 250);
      } else {
        toast.success('You have completed every segment in this plan!');
      }
    } catch (error) {
      console.error('Failed to advance to next segment', error);
      toast.error('Unable to open the next chapter right now.');
    } finally {
      isAdvancingSegmentRef.current = false;
    }
  }, [bibleStore]);

  const handleCompleteSegment = useCallback(async () => {
    try {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch { }

    const timerId = bibleStore.getTodayTimerIdPublic();
    const timer = timerId ? appTimerStore.get(timerId) : null;

    if (phasesForToday.length > 0 && timer && !timer.completed) {
      setShowTimerModal(true);
      void completeCurrentPhase();
      return;
    }

    await advanceToNextSegment();
  }, [phasesForToday.length, completeCurrentPhase, advanceToNextSegment, bibleStore]);


  const goToNextChapterWithinSegment = useCallback(async () => {
    const seg = bibleStore.activeReadingSegment;
    if (!bibleStore.currentBook || !bibleStore.currentVersion || !seg) return;
    const nextChapter = (bibleStore.currentChapter || 1) + 1;
    const lastChapter = seg.chapterEnd ?? seg.chapterStart;
    if (nextChapter > lastChapter) return;
    await bibleStore.fetchVerses(bibleStore.currentBook, nextChapter, bibleStore.currentVersion, 1);
  }, [bibleStore]);

  const handleRightSwipeToNext = useCallback(async () => {
    try { await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); } catch { }
    if (bibleStore.isPlanMode) {
      const seg = bibleStore.activeReadingSegment;
      const cur = bibleStore.currentChapter || 1;
      const last = seg ? (seg.chapterEnd ?? seg.chapterStart) : null;
      if (seg && last && cur < last) {
        await goToNextChapterWithinSegment();
        return;
      }
    }
    await goToNextChapterGeneric();
  }, [bibleStore.isPlanMode, bibleStore.activeReadingSegment, bibleStore.currentChapter, goToNextChapterWithinSegment, goToNextChapterGeneric]);

  const panResponder = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_evt: GestureResponderEvent, gesture: PanResponderGestureState) => {
        if (!atEnd) return false;
        const isHorizontal = Math.abs(gesture.dx) > 18 && Math.abs(gesture.dy) < 10;
        const isRightSwipe = gesture.dx > 18;
        const fromLeftEdge = (gesture.x0 ?? 0) < 28;
        return isHorizontal && isRightSwipe && fromLeftEdge;
      },
      onPanResponderRelease: async (_evt, gesture) => {
        if (!atEnd) return;
        const isRightSwipe = gesture.dx > 30 && Math.abs(gesture.dy) < 20;
        if (isRightSwipe) {
          await handleRightSwipeToNext();
        }
      },
      onPanResponderTerminationRequest: () => true,
      onPanResponderTerminate: () => { },
    })
  ).current;

  useEffect(() => {
    // Open plan setup if requested by navigation and no plan exists
    const openPlan = (route as any)?.params?.openPlanSetup;
    if (openPlan && !bibleStore.readingPlan) {
      setIsPlanSetupVisible(true);
      // clear the flag to prevent reopening on re-render
      try { (navigation as any).setParams?.({ openPlanSetup: undefined }); } catch { }
    }

    console.log('[BibleScreen] route params changed', routeParams);
    if (!routeParams || routeParams.mode !== 'scoped' || !routeParams.scopedVerses?.length) {
      if (scopedView) {
        console.log('[BibleScreen] clearing scoped view', {
          hasRouteParams: !!routeParams,
          mode: routeParams?.mode,
          scopedCount: routeParams?.scopedVerses?.length ?? 0,
        });
        setScopedView(null);
      }
      return;
    }

    console.log('[BibleScreen] received scoped payload', {
      title: routeParams.scopedTitle,
      subtitle: routeParams.scopedSubtitle,
      verseCount: routeParams.scopedVerses.length,
    });

    const sanitized = routeParams.scopedVerses
      .map(item => {
        if (!item || typeof item.text !== 'string') {
          return null;
        }
        const trimmed = item.text.trim();
        if (!trimmed) {
          return null;
        }
        return {
          text: trimmed,
          reference: item.reference ?? null,
          isPrimary: item.isPrimary ?? false,
        } as ScopedVerseParam;
      })
      .filter((item): item is ScopedVerseParam => !!item);

    console.log('[BibleScreen] sanitized scoped verses', sanitized);

    if (!sanitized.length) {
      if (scopedView) {
        console.log('[BibleScreen] sanitized payload empty – clearing scoped view');
        setScopedView(null);
      }
      return;
    }

    setScopedView(prev => {
      if (
        prev &&
        prev.title === (routeParams.scopedTitle ?? null) &&
        prev.subtitle === (routeParams.scopedSubtitle ?? null) &&
        prev.verses.length === sanitized.length &&
        prev.verses.every((verse, index) => {
          const candidate = sanitized[index];
          return (
            verse.text === candidate.text &&
            (verse.reference ?? null) === (candidate.reference ?? null) &&
            (!!verse.isPrimary) === (!!candidate.isPrimary)
          );
        })
      ) {
        console.log('[BibleScreen] scoped view unchanged');
        return prev;
      }

      const nextView = {
        title: routeParams.scopedTitle ?? null,
        subtitle: routeParams.scopedSubtitle ?? null,
        verses: sanitized,
      };

      console.log('[BibleScreen] updating scoped view', nextView);
      return {
        title: routeParams.scopedTitle ?? null,
        subtitle: routeParams.scopedSubtitle ?? null,
        verses: sanitized,
      };
    });
  }, [routeParams, scopedView]);

  useEffect(() => {
    console.log('[BibleScreen] scopedView state changed', scopedView);
  }, [scopedView]);

  const routeVerseParam = routeParams?.verse;



  useEffect(() => {
    if (!bibleStore.readingPlan) {
      setBuilderReminder('');
      journeyStore.setBiblePlan(null);
      return;
    }
    setBuilderReminder(bibleStore.readingPlan.reminderTime ?? bibleStore.readingReminder?.time ?? '');
    journeyStore.setBiblePlan({
      id: bibleStore.readingPlan.id,
      currentIndex: bibleStore.readingPlan.currentIndex,
      totalSegments: bibleStore.readingPlan.segments.length,
      reminderTime: bibleStore.readingPlan.reminderTime ?? null,
    });
  }, [bibleStore.readingPlan, bibleStore.readingReminder?.time]);

  // Handle initial params (apply once and only if different)
  const scrollToVerse = useCallback((targetVerse?: number | string | null, opts?: { immediate?: boolean }) => {
    if (targetVerse == null) return;

    const parsedTarget = typeof targetVerse === 'string' ? parseInt(targetVerse, 10) : targetVerse;
    if (!Number.isFinite(parsedTarget) || parsedTarget <= 0) return;

    const immediate = opts?.immediate ?? false;

    if (!bibleStore.verses.length) {
      pendingScrollVerseRef.current = parsedTarget;
      return;
    }

    let targetIndex = -1;
    bibleStore.verses.some((v, idx) => {
      const { verse } = parseVerseAddress(v, bibleStore.currentChapter ?? undefined);
      if (verse === parsedTarget) {
        targetIndex = idx;
        return true;
      }
      return false;
    });

    if (targetIndex === -1) {
      pendingScrollVerseRef.current = parsedTarget;
      return;
    }

    const key = makeVerseKey(bibleStore.currentChapter, parsedTarget);
    const layout = verseLayoutMapRef.current.get(key);
    const scrollAction = () => {
      if (layout && listDimensionsRef.current.height > 0) {
        const desiredOffset = layout.offset - Math.max(0, listDimensionsRef.current.height * 0.2);
        verseListRef.current?.scrollToOffset({
          offset: Math.max(0, desiredOffset),
          animated: !immediate,
        });
      } else {
        try {
          verseListRef.current?.scrollToIndex({
            index: targetIndex,
            animated: !immediate,
            viewPosition: 0.3,
          });
        } catch {
          const approximateRowHeight = 64;
          verseListRef.current?.scrollToOffset({
            offset: targetIndex * approximateRowHeight,
            animated: !immediate,
          });
        }
      }
    };

    pendingScrollVerseRef.current = null;
    if (immediate) {
      scrollAction();
    } else {
      requestAnimationFrame(scrollAction);
    }
  }, [bibleStore.verses, bibleStore.currentChapter]);

  useEffect(() => {
    if (!bibleStore.isPlanMode) {
      lastAutoScrollKeyRef.current = null;
      return;
    }

    if (routeVerseParam) {
      // Respect explicit navigation requests when a verse param is provided
      return;
    }

    const segment = bibleStore.activeReadingSegment;
    const verseStart = segment?.verseStart ?? null;
    if (!segment || typeof verseStart !== 'number' || Number.isNaN(verseStart)) {
      return;
    }

    const key = `${segment.id}:${makeSegmentRangeToken(segment)}:${routeParams?.mode ?? 'default'}`;

    if (key === lastAutoScrollKeyRef.current && pendingScrollVerseRef.current == null) {
      return;
    }

    if ((bibleStore.currentChapter ?? 0) !== (segment.chapterStart ?? 0)) {
      return;
    }

    lastAutoScrollKeyRef.current = key;
    scrollToVerse(verseStart, { immediate: true });
  }, [bibleStore.isPlanMode, bibleStore.activeReadingSegment, bibleStore.currentChapter, routeVerseParam, bibleStore.verses, scrollToVerse, routeParams?.mode]);

  useEffect(() => {
    if (!routeParams || routeParams.mode === 'scoped') {
      return;
    }

    const { book, chapter, verse, mode } = routeParams;
    if (!book && !chapter && !verse) return;

    const paramsKey = `${book ?? ''}:${chapter ?? ''}:${verse ?? ''}:${mode ?? 'default'}`;
    if (lastAppliedParamsRef.current === paramsKey) {
      if (verse) {
        scrollToVerse(verse);
      }
      return;
    }

    lastAppliedParamsRef.current = paramsKey;

    if (book) {
      const foundBook = bibleBooks.find((bookEntry: Book) =>
        bookEntry.name.toLowerCase() === book.toLowerCase() ||
        bookEntry.abbreviation.toLowerCase() === book.toLowerCase()
      );
      if (foundBook) {
        if (!bibleStore.currentBook || bibleStore.currentBook.abbreviation !== foundBook.abbreviation) {
          bibleStore.setCurrentBook(foundBook);
        }

        if (chapter) {
          const targetChapter = Math.min(chapter, foundBook.chapters);
          if (bibleStore.currentChapter !== targetChapter) {
            bibleStore.setCurrentChapter(targetChapter);
          }
        }
      }
    } else if (chapter && bibleStore.currentBook) {
      const targetChapter = Math.min(chapter, bibleStore.currentBook.chapters);
      if (bibleStore.currentChapter !== targetChapter) {
        bibleStore.setCurrentChapter(targetChapter);
      }
    }

    if (verse) {
      scrollToVerse(verse);
    }
  }, [routeParams, bibleStore.currentBook, bibleStore.currentChapter, scrollToVerse, bibleStore]);

  useEffect(() => {
    if (pendingScrollVerseRef.current) {
      scrollToVerse(pendingScrollVerseRef.current);
    }
  }, [bibleStore.verses, scrollToVerse]);

  // When entering scoped mode, also ensure the underlying chapter is prepared
  useEffect(() => {
    if (!routeParams || routeParams.mode !== 'scoped') return;
    const { book, chapter, verse, version } = routeParams;
    // Optionally switch version if provided
    if (version && bibleStore.availableVersions?.length) {
      const nextVersion = bibleStore.availableVersions.find(v => v.shortName.toLowerCase() === String(version).toLowerCase());
      if (nextVersion && (!bibleStore.currentVersion || bibleStore.currentVersion.shortName !== nextVersion.shortName)) {
        bibleStore.setCurrentVersion(nextVersion);
      }
    }

    if (book) {
      const foundBook = bibleBooks.find((b: Book) => b.name.toLowerCase() === book.toLowerCase() || b.abbreviation.toLowerCase() === book.toLowerCase());
      if (foundBook) {
        if (!bibleStore.currentBook || bibleStore.currentBook.abbreviation !== foundBook.abbreviation) {
          bibleStore.setCurrentBook(foundBook);
        }
        if (chapter && bibleStore.currentChapter !== chapter) {
          bibleStore.setCurrentChapter(Math.min(chapter, foundBook.chapters));
        }
      }
    } else if (chapter && bibleStore.currentBook) {
      if (bibleStore.currentChapter !== chapter) {
        bibleStore.setCurrentChapter(Math.min(chapter, bibleStore.currentBook.chapters));
      }
    }

    if (verse != null) {
      scrollToVerse(verse);
    }
  }, [routeParams?.mode, routeParams?.book, routeParams?.chapter, routeParams?.verse, routeParams?.version, bibleStore.availableVersions, bibleStore.currentVersion, bibleStore.currentBook, bibleStore.currentChapter, scrollToVerse]);

  // Update offline status in Bible store
  useEffect(() => {
    bibleStore.setIsOffline(isOffline);
  }, [isOffline]);

  // Initialize Bible
  const hasInitializedRef = useRef(false);

  useEffect(() => {
    const initializeBible = async () => {
      try {
        if (!hasInitializedRef.current) {
          await bibleStore.loadUserPreferences();
          await bibleStore.fetchBibleVersions();
          await bibleStore.ensureInitialPassage();

          if (bibleStore.currentBook && bibleStore.currentVersion) {
            lastFetchKeyRef.current = `${bibleStore.currentVersion.tableName}:${bibleStore.currentBook.abbreviation}:${bibleStore.currentChapter}`;
          }

          hasInitializedRef.current = true;
        }

        if (!isOffline) {
          await bibleStore.syncUserInteractions();
        }
      } catch (error) {
        console.error('Failed to initialize Bible:', error);
        toast.error('Failed to initialize Bible. Please try restarting the app.');
      }
    };

    initializeBible();
  }, [isOffline]);

  // Fetch verses when book/chapter/version changes (guard against redundant requests)
  const lastFetchKeyRef = useRef<string | null>(null);
  useEffect(() => {
    if (!bibleStore.currentBook || !bibleStore.currentVersion) return;
    const key = `${bibleStore.currentVersion.tableName}:${bibleStore.currentBook.abbreviation}:${bibleStore.currentChapter}`;
    if (lastFetchKeyRef.current === key) return;
    lastFetchKeyRef.current = key;
    bibleStore.fetchVerses(bibleStore.currentBook, bibleStore.currentChapter, bibleStore.currentVersion);
  }, [bibleStore.currentBook, bibleStore.currentChapter, bibleStore.currentVersion]);

  // Handle errors
  useEffect(() => {
    if (bibleStore.versesError) {
      toast.error(bibleStore.versesError);
      bibleStore.clearErrors();
    }
    if (bibleStore.searchError) {
      toast.error(bibleStore.searchError);
      bibleStore.clearErrors();
    }
    if (bibleStore.installError) {
      toast.error(bibleStore.installError);
      bibleStore.clearErrors();
    }
  }, [bibleStore.versesError, bibleStore.searchError, bibleStore.installError]);

  // Handle refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    lastFetchKeyRef.current = null;
    await bibleStore.ensureInitialPassage(true);
    if (bibleStore.currentBook && bibleStore.currentVersion) {
      lastFetchKeyRef.current = `${bibleStore.currentVersion.tableName}:${bibleStore.currentBook.abbreviation}:${bibleStore.currentChapter}`;
    }
    setRefreshing(false);
  };

  // Handle load more
  const handleLoadMore = () => {
    if (bibleStore.pagination.hasMore && !bibleStore.isVersesLoading && bibleStore.currentBook && bibleStore.currentVersion) {
      bibleStore.fetchVerses(
        bibleStore.currentBook,
        bibleStore.currentChapter,
        bibleStore.currentVersion,
        bibleStore.pagination.currentPage + 1
      );
      return;
    }

    if (!bibleStore.isPlanMode || !bibleStore.activeReadingSegment) {
      return;
    }

    return;
  };

  // Handle book installation
  const handleInstallVersion = async (version: BibleVersion) => {
    try {
      const success = await bibleStore.installVersion(version);
      if (success) {
        await bibleStore.fetchBibleVersions();
        bibleStore.setCurrentVersion(version);
        toast.success(`${version.englishName} installed and selected`);
      }
    } catch (error) {
      console.error('Installation failed:', error);
    }
  };

  // Search functionality
  const handleSearch = useCallback(async (query: string) => {
    bibleStore.setSearchQuery(query);

    if (!query.trim()) {
      bibleStore.clearSearch();
      return;
    }

    if (!bibleStore.currentVersion) return;

    await bibleStore.searchVerses(query, bibleStore.currentVersion);
  }, [bibleStore]);

  // Verse interaction handlers
  const handleToggleHighlight = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const success = await bibleStore.toggleHighlight(verseId);
    if (success) {
      await bibleStore.saveUserPreferences();
      if (!isOffline) {
        toast.success('Verse highlighted');
      }
    } else if (!isOffline) {
      toast.error('Failed to highlight verse');
    }
  }, [isOffline]);

  const handleToggleBookmark = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const success = await bibleStore.toggleBookmark(verseId);
    if (success) {
      await bibleStore.saveUserPreferences();
      if (!isOffline) {
        toast.success('Verse bookmarked');
      }
    } else if (!isOffline) {
      toast.error('Failed to bookmark verse');
    }
  }, [isOffline]);

  const handleLikeVerse = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const success = await bibleStore.likeVerse(verseId);
    if (success && !isOffline) {
      toast.success('Verse liked');
    } else if (!success && !isOffline) {
      toast.error('Failed to like verse');
    }
  }, [isOffline]);

  const handleShareVerse = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await bibleStore.shareVerse(verseId);
  }, []);

  const handleOpenVerseActions = useCallback((verseId: string) => {
    bibleStore.setSelectedVerseId(verseId);
    setShowVerseActions(true);
  }, [bibleStore]);

  const handleCloseVerseActions = useCallback(() => {
    setShowVerseActions(false);
    bibleStore.setSelectedVerseId(null);
  }, [bibleStore]);

  const handleCompareSelectedVerse = useCallback(() => {
    if (!bibleStore.selectedVerseId) return;
    // Open modal first so the spinner is visible while loading
    setShowComparisonModal(true);
    // Fire-and-forget to avoid blocking UI updates
    void bibleStore.loadComparisonForSelectedVerse();
  }, [bibleStore]);

  const handleCloseComparisonModal = useCallback(() => {
    setShowComparisonModal(false);
  }, []);

  const selectedVerse = useMemo(() => {
    if (!bibleStore.selectedVerseId) return null;
    return bibleStore.verses.find(v => v.id === bibleStore.selectedVerseId) ?? null;
  }, [bibleStore.selectedVerseId, bibleStore.verses]);

  const handleEnterPlanMode = useCallback(async () => {
    if (!bibleStore.readingPlan) {
      return;
    }

    await bibleStore.ensureDailySessionPrepared();

    if (bibleStore.isPlanMode) {
      void bibleStore.focusPlanSegment();
      setShowCompactPlan(true);

      if (bibleStore.dailySession?.completed) {
        if (!isOffline) {
          toast.success('All done for today — great job!');
        }
        return;
      }

      const timerId = bibleStore.getTodayTimerIdPublic();
      if (!timerId) return;

      const timer = appTimerStore.get(timerId);
      if (!timer) return;

      const phase = phasesForToday[timer.currentPhaseIndex];

      if (phase && phase.id !== 'reading') {
        appTimerStore.resume(timer.id);
        setShowMeditationMode(true);
      } else {
        setShowTimerModal(true);

        // Play start chime
        try {
          const { sound } = await Audio.Sound.createAsync(
            require('../../assets/sounds/bell.wav')
          );
          await sound.playAsync();
          sound.setOnPlaybackStatusUpdate(status => {
            if (status.isLoaded && status.didJustFinish) {
              sound.unloadAsync();
            }
          });
        } catch (error) {
          console.warn('Could not play start chime', error);
        }
      }
      return;
    }

    bibleStore.enablePlanMode();
    await bibleStore.focusPlanSegment();
    setShowCompactPlan(true);

    await bibleStore.ensureDailySessionPrepared();

    const timerId = bibleStore.getTodayTimerIdPublic();
    if (!timerId) return;

    const timer = appTimerStore.get(timerId);
    if (!timer) return;

    const phase = phasesForToday[timer.currentPhaseIndex];

    if (phase && phase.id !== 'reading') {
      appTimerStore.resume(timer.id);
      setShowMeditationMode(true);
    } else {
      setShowTimerModal(true);
    }

    // Play start chime
    try {
      const { sound } = await Audio.Sound.createAsync(
        require('../../assets/sounds/bell.wav')
      );
      await sound.playAsync();
      sound.setOnPlaybackStatusUpdate(status => {
        if (status.isLoaded && status.didJustFinish) {
          sound.unloadAsync();
        }
      });
    } catch (error) {
      console.warn('Could not play start chime', error);
    }
  }, [bibleStore, phasesForToday]);

  const handleExitPlanMode = useCallback(() => {
    const cleanup = () => {
      setShowTimerModal(false);
      setShowMeditationMode(false);
      setShowCompactPlan(true);
      setPlanDetailsExpanded(false);
    };

    if (!bibleStore.isPlanMode) {
      void bibleStore.restoreBrowsePosition();
      cleanup();
      return;
    }
    bibleStore.disablePlanMode();
    cleanup();
    void bibleStore.restoreBrowsePosition();
  }, [bibleStore]);

  const handleOpenCurrentSegment = useCallback(() => {
    if (!bibleStore.readingPlan) {
      return;
    }
    void bibleStore.focusPlanSegment();
  }, [bibleStore]);

  const handleExplainWithAI = useCallback(async () => {
    if (!selectedVerse) {
      return;
    }
    bibleStore.clearAIInsights();
    setShowAIInsights(true);
    await bibleStore.explainVerse(selectedVerse);
  }, [bibleStore, selectedVerse]);

  const handleCloseAIInsights = useCallback(() => {
    setShowAIInsights(false);
    bibleStore.clearAIInsights();
  }, [bibleStore]);

  const handleExitScopedView = useCallback(() => {
    if (!scopedView) {
      return;
    }

    setScopedView(null);
    navigation.setParams({
      mode: undefined,
      scopedTitle: undefined,
      scopedSubtitle: undefined,
      scopedVerses: undefined,
    });
  }, [navigation, scopedView]);

  const handleCreatePlan = useCallback(async ({ books, timePerDay, readingMode, phases, reminderTime, presetIds, minChaptersPerDay, maxChaptersPerDay, readingPaceWpm }: { books: string[]; timePerDay: number; readingMode: ReadingPlanMode; phases: ReadingPlanPhase[]; reminderTime?: string; presetIds?: string[]; minChaptersPerDay?: number; maxChaptersPerDay?: number; readingPaceWpm?: number }) => {
    try {
      await bibleStore.createReadingPlan({
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
        presetIds,
        minChaptersPerDay,
        maxChaptersPerDay,
        readingPaceWpm,
      });

      setBuilderReminder(reminderTime?.trim?.() ?? reminderTime ?? '');
      setIsPlanSetupVisible(false);

      setShowCompactPlan(true);
      if (!isOffline) {
        toast.success('Bible Studio plan ready');
      }

      // Sync with journey store
      journeyStore.setBiblePlan({
        id: bibleStore.readingPlan?.id ?? '',
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
        presetIds: presetIds ?? [],
        focusVirtue: bibleStore.readingPlan?.focusVirtue ?? null,
      });
      void journeyStore.syncUserProgress();
      // Keep compact plan minimized while focused
      dailyPathStore.setReadingPlanSetupCompleted(true);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to create plan.';
      if (!isOffline) {
        toast.error(message);
      }
    }
  }, [bibleStore, dailyPathStore, journeyStore]);

  const handleApplyReminder = useCallback(async () => {
    try {
      await bibleStore.setReadingReminder(builderReminder.trim() || null);
      if (!isOffline) {
        toast.success(builderReminder.trim() ? 'Reminder updated' : 'Reminder cleared');
      }

      const trimmed = builderReminder.trim();
      const reminderTime = ReminderSyncService.convertTimeStringToReminderTime(trimmed || null);
      await ReminderSyncService.syncToBackend(
        String(user?.id ?? ''),
        'daily_reminder',
        !!reminderTime,
        reminderTime ? [reminderTime] : []
      );

      if (bibleStore.readingPlan) {
        journeyStore.setBiblePlan({
          id: bibleStore.readingPlan.id,
          currentIndex: bibleStore.readingPlan.currentIndex,
          totalSegments: bibleStore.readingPlan.segments.length,
          reminderTime: builderReminder.trim() || null,
        });
      }
    } catch (error) {
      console.error('Failed to update reminder', error);
      if (!isOffline) {
        toast.error('Unable to update reminder.');
      }
    }
  }, [bibleStore, builderReminder, journeyStore, user?.id]);

  const handleToggleSegment = useCallback(async (segmentId: string) => {
    resetIdleTimer();
    try {
      await bibleStore.togglePlanSegmentCompletion(segmentId);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (error) {
      console.error('Failed to update segment', error);
      if (!isOffline) {
        toast.error('Unable to update segment progress.');
      }
    }
  }, [bibleStore, resetIdleTimer]);

  const renderPlanHeader = () => {
    if (scopedView) {
      console.log('[BibleScreen] renderPlanHeader suppressed due to scoped view');
      return null;
    }

    if (!bibleStore.isInitialized) {
      return null;
    }

    const readingPlan = bibleStore.readingPlan;
    const session = bibleStore.dailySession;
    const completedToday = !!session?.completed;
    const { completed, total } = bibleStore.readingPlanProgress;
    const progressPercent = total ? Math.round((completed / total) * 100) : 0;
    const upcoming = bibleStore.upcomingSegments;
    const [currentSegment, ...upcomingSegments] = upcoming;

    if (readingPlan && showCompactPlan && !bibleStore.isPlanMode) {
      return (
        <View style={styles.planContainer}>
          <TouchableOpacity
            style={styles.planIconLauncher}
            onPress={() => {
              setShowCompactPlan(false);
              setPlanDetailsExpanded(true);
              handleEnterPlanMode();
            }}
            accessibilityLabel="Open reading plan"
            accessibilityRole="button"
          >
            <MaterialIcons name="menu-book" size={22} color={theme.colors.primary} />
            <Text style={styles.planIconLauncherText}>Plan</Text>
          </TouchableOpacity>
        </View>
      );
    }

    if (readingPlan && showCompactPlan && !bibleStore.dailySession?.completed) {
      return (
        <View style={styles.planContainer}>
          <TouchableWithoutFeedback
            onPress={() => {
              setPlanDetailsExpanded(true);
              setShowCompactPlan(false);
              resetIdleTimer();
            }}
          >
            <View style={styles.planCard}>
              <View style={styles.planCompactRow}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.planSectionTitle}>Today’s focus</Text>
                  <Text style={styles.planCardSummary} numberOfLines={1}>
                    {currentSegment ? formatSegmentLabel(currentSegment) : 'Next segment'}
                  </Text>
                  {bibleStore.isPlanMode && (() => {
                    const timerId = bibleStore.getTodayTimerIdPublic();
                    const remaining = timerId ? appTimerStore.totalRemaining(timerId) : null;
                    return (
                      <Text style={styles.planReminderHint}>
                        {remaining != null
                          ? `Time remaining: ${Math.floor(Math.max(0, remaining) / 60)}:${String(Math.max(0, remaining) % 60).padStart(2, '0')}`
                          : `Planned: ${phasesForToday.reduce((m, p) => m + p.minutes, 0)} min`}
                      </Text>
                    );
                  })()}

                </View>
                <View style={styles.planCompactActions}>
                  <TouchableOpacity
                    style={[styles.planSecondaryButton, styles.planCompactActionButton]}
                    onPress={() => {
                      if (bibleStore.isPlanMode) {
                        const timerId = bibleStore.getTodayTimerIdPublic();
                        const timer = timerId ? appTimerStore.get(timerId) : null;

                        if (timer) {
                          const curPhase = phasesForToday[timer.currentPhaseIndex];
                          if (curPhase && curPhase.id !== 'reading') {
                            appTimerStore.resume(timer.id);
                            setShowMeditationMode(true);
                            setShowCompactPlan(false);
                          } else {
                            setPlanDetailsExpanded(true);
                            setShowCompactPlan(false);
                          }
                        }
                      } else {
                        handleEnterPlanMode();
                      }
                      resetIdleTimer();
                    }}
                  >
                    <MaterialIcons name="play-arrow" size={18} color={theme.colors.primary} />
                    <Text style={styles.planSecondaryButtonLabel}>
                      {bibleStore.isPlanMode ? 'Expand' : 'Focus'}
                    </Text>
                  </TouchableOpacity>
                  {bibleStore.isPlanMode && (
                    <TouchableOpacity
                      style={styles.planCompactIconButton}
                      accessibilityLabel="Exit plan mode"
                      accessibilityRole="button"
                      onPress={handleExitPlanMode}
                    >
                      <MaterialIcons name="close" size={18} color={theme.colors.primary} />
                    </TouchableOpacity>
                  )}
                  <TouchableOpacity
                    style={styles.planCompactIconButton}
                    onPress={() => {
                      setPlanDetailsExpanded(true);
                      setShowCompactPlan(false);
                      resetIdleTimer();
                    }}
                    accessibilityLabel="Reading plan options"
                    accessibilityRole="button"
                  >
                    <MaterialIcons name="tune" size={18} color={theme.colors.primary} />
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          </TouchableWithoutFeedback>
        </View>
      );
    }

    // Minimal compact summary when completed
    if (readingPlan && showCompactPlan && completedToday) {
      const phases = (session?.phases ?? []).filter(p => p.plannedSeconds > 0);
      const fmt = (s: number) => {
        const mins = Math.floor(Math.max(0, s) / 60);
        const secs = Math.max(0, Math.floor(Math.max(0, s) % 60));
        return `${mins}:${String(secs).padStart(2, '0')}`;
      };
      return (
        <View style={styles.planContainer}>
          <TouchableWithoutFeedback
            onPress={() => {
              setPlanDetailsExpanded(true);
              setShowCompactPlan(false);
              resetIdleTimer();
            }}
          >
            <View style={styles.planCard}>
              <View style={styles.planCompactRow}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.planSectionTitle}>Today’s session completed</Text>
                  <View style={styles.planSessionSummaryCard}>
                    <View style={styles.planSessionSummaryRow}>
                      <Text style={styles.planSessionSummaryLabel}>Chapters</Text>
                      <Text style={styles.planSessionSummaryValue}>{Math.max(0, session?.chaptersCompleted || 0)}</Text>
                    </View>
                    {phases.map(phase => (
                      <View key={phase.id} style={styles.planSessionSummaryRow}>
                        <Text style={styles.planSessionSummaryLabel}>{phase.label}</Text>
                        <Text style={styles.planSessionSummaryValue}>{fmt(phase.elapsedSeconds)}</Text>
                      </View>
                    ))}
                  </View>
                </View>
                {bibleStore.isPlanMode && (
                  <TouchableOpacity
                    style={styles.planCompactIconButton}
                    accessibilityLabel="Exit plan mode"
                    accessibilityRole="button"
                    onPress={handleExitPlanMode}
                  >
                    <MaterialIcons name="close" size={18} color={theme.colors.primary} />
                  </TouchableOpacity>
                )}
              </View>
            </View>
          </TouchableWithoutFeedback>
        </View>
      );
    }

    return (
      <View style={styles.planContainer}>
        <Text style={styles.planTitle}>Bible Studio</Text>
        <Text style={styles.planSubtitle}>
          Choose a rhythm of Scripture that meets you today and keeps you growing.
        </Text>

        {readingPlan ? (
          <View style={styles.planCard}>
            <View style={styles.planCardHeader}>
              <View>
                <Text style={styles.planCardTitle}>Your current plan</Text>
                <Text style={styles.planCardSummary}>
                  {bibleStore.dailySession?.completed
                    ? `Today's session completed — ${completed} of ${total} sessions complete (${progressPercent}%)`
                    : `${completed} of ${total} sessions complete (${progressPercent}%)`}
                </Text>
                {readingPlan?.createdAt && total > 0 && (
                  <Text style={styles.planCardMeta}>
                    {(() => {
                      const startMs = getLocalMidnightMs(new Date(readingPlan.createdAt));
                      const nowMs = getLocalMidnightMs(new Date());
                      const daysSinceStart = Math.max(1, Math.floor((nowMs - startMs) / (24 * 60 * 60 * 1000)) + 1);
                      const expectedByToday = Math.min(total, daysSinceStart);
                      const delta = completed - expectedByToday;
                      if (delta > 0) return `Ahead by ${delta} ${delta === 1 ? 'session' : 'sessions'} for today`;
                      if (delta < 0) return `Behind by ${Math.abs(delta)} ${Math.abs(delta) === 1 ? 'session' : 'sessions'} for today`;
                      return 'On track for today';
                    })()}
                  </Text>
                )}
              </View>
              <View style={styles.planCardControls}>
                {bibleStore.isPlanMode && (
                  <TouchableOpacity
                    style={styles.planCompactToggle}
                    onPress={() => {
                      handleExitPlanMode();
                    }}
                    accessibilityLabel="Exit plan mode"
                  >
                    <MaterialIcons name="close" size={18} color={theme.colors.text.secondary} />
                    <Text style={styles.planCompactToggleText}>Exit</Text>
                  </TouchableOpacity>
                )}
                <TouchableOpacity
                  style={styles.planCompactToggle}
                  onPress={() => {
                    setPlanDetailsExpanded(false);
                    setShowCompactPlan(true);
                  }}
                >
                  <MaterialIcons name="fullscreen-exit" size={18} color={theme.colors.text.secondary} />
                  <Text style={styles.planCompactToggleText}>Minimize</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.planCompactToggle} onPress={() => setShowAdvancedActions(true)}>
                  <MaterialIcons name="tune" size={18} color={theme.colors.text.secondary} />
                  <Text style={styles.planCompactToggleText}>Advanced</Text>
                </TouchableOpacity>
              </View>
            </View>

            {currentSegment && (
              <View style={styles.planActiveSegment}>
                {bibleStore.dailySession?.completed ? (
                  (() => {
                    const ds = bibleStore.dailySession;
                    const safePhases = ds?.phases ?? [];
                    const fmt = (s: number) => {
                      const mins = Math.floor(Math.max(0, s) / 60);
                      const secs = Math.max(0, Math.floor(Math.max(0, s) % 60));
                      return `${mins}:${String(secs).padStart(2, '0')}`;
                    };
                    const chapters = Math.max(0, ds?.chaptersCompleted || 0);
                    return (
                      <View style={styles.planSessionSummaryCard}>
                        <Text style={styles.planSessionSummaryTitle}>Today’s session completed</Text>
                        <View style={styles.planSessionSummaryRow}>
                          <Text style={styles.planSessionSummaryLabel}>Chapters</Text>
                          <Text style={styles.planSessionSummaryValue}>{chapters}</Text>
                        </View>
                        {phasesForToday.map((p, idx) => {
                          const sum = safePhases[idx];
                          const elapsed = sum ? Math.max(0, sum.elapsedSeconds) : 0;
                          return (
                            <View key={p.id} style={styles.planSessionSummaryRow}>
                              <Text style={styles.planSessionSummaryLabel}>{p.label}</Text>
                              <Text style={styles.planSessionSummaryValue}>{fmt(elapsed)}</Text>
                            </View>
                          );
                        })}
                      </View>
                    );
                  })()
                ) : (
                  <>
                    <Text style={styles.planSectionTitle}>Today’s focus</Text>
                    <PlanSegmentChip
                      label={formatSegmentLabel(currentSegment)}
                      completed={!!currentSegment.completedAt}
                      onPress={() => {
                        const tid = bibleStore.getTodayTimerIdPublic();
                        const t = tid ? appTimerStore.get(tid) : null;
                        const curPhase = t ? phasesForToday[t.currentPhaseIndex] : null;
                        const isNonReading = !!curPhase && curPhase.id !== 'reading' && !t?.completed;
                        if (isNonReading && t) {
                          appTimerStore.resume(t.id);
                          setShowMeditationMode(true);
                          setShowCompactPlan(false);
                        } else {
                          handleEnterPlanMode();
                        }
                      }}
                      onLongPress={async () => {
                        const ok = await new Promise<boolean>(resolve => {
                          Alert.alert(
                            'Mark segment',
                            currentSegment.completedAt ? 'Unmark this segment as completed?' : 'Mark this segment as completed?',
                            [
                              { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
                              { text: 'OK', style: 'destructive', onPress: () => resolve(true) },
                            ],
                            { cancelable: true }
                          );
                        });
                        if (ok) {
                          await handleToggleSegment(currentSegment.id);
                        }
                      }}
                    />
                  </>
                )}
              </View>
            )}

            {planDetailsExpanded && !!upcomingSegments.length && !bibleStore.dailySession?.completed && (
              <View style={styles.planUpcomingSection}>
                <Text style={styles.planSectionTitle}>Up next</Text>
                <View style={styles.planSegmentList}>
                  {upcomingSegments.map(segment => (
                    <PlanSegmentChip
                      key={segment.id}
                      label={formatSegmentLabel(segment)}
                      completed={!!segment.completedAt}
                      disabled={(function () {
                        const tid = bibleStore.getTodayTimerIdPublic();
                        const t = tid ? appTimerStore.get(tid) : null;
                        const curPhase = t ? phasesForToday[t.currentPhaseIndex] : null;
                        return !!curPhase && curPhase.id !== 'reading' && !t?.completed;
                      })()}
                      onPress={async () => {
                        const tid = bibleStore.getTodayTimerIdPublic();
                        const t = tid ? appTimerStore.get(tid) : null;
                        const curPhase = t ? phasesForToday[t.currentPhaseIndex] : null;
                        const isNonReading = !!curPhase && curPhase.id !== 'reading' && !t?.completed;
                        if (isNonReading) return;
                        await bibleStore.focusPlanSegment(segment.id);
                        if (!bibleStore.dailySession?.completed) {
                          setShowTimerModal(true);
                        } else {
                          setShowTimerModal(true);
                          if (!isOffline) {
                            toast.success('All done for today — previewing next session');
                          }
                        }
                      }}
                      onLongPress={() => handleToggleSegment(segment.id)}
                    />
                  ))}
                </View>
              </View>
            )}

            {planDetailsExpanded && (
              <View style={styles.planReminderRow}>
                <View style={styles.planReminderInfo}>
                  <Text style={styles.planSectionTitle}>Daily reminder</Text>
                  <Text style={styles.planReminderHint}>Pick a time to receive a gentle nudge.</Text>
                </View>
                <View style={styles.planReminderControls}>
                  <ReminderTimePicker
                    value={builderReminder || null}
                    onChange={next => setBuilderReminder(next ?? '')}
                    placeholder="Set reminder time"
                    helperText={builderReminder ? `Current: ${builderReminder}` : undefined}
                  />
                  <TouchableOpacity style={styles.planReminderButton} onPress={handleApplyReminder}>
                    <Text style={styles.planReminderButtonText}>Save</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}

            {planDetailsExpanded && (
              <View style={styles.planFooterActions}>
                <TouchableOpacity style={styles.planSecondaryButton} onPress={handleEnterPlanMode}>
                  <MaterialIcons name="play-arrow" size={18} color={theme.colors.primary} />
                  <Text style={styles.planSecondaryButtonLabel}>Focus plan</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.planSecondaryButton} onPress={() => setIsPlanSetupVisible(true)}>
                  <MaterialIcons name="edit" size={18} color={theme.colors.primary} />
                  <Text style={styles.planSecondaryButtonLabel}>Adjust plan</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        ) : (
          <View style={styles.planCard}>
            <Text style={styles.planCardTitle}>Start a new reading journey</Text>
            <Text style={styles.planCardSummary}>
              Choose a focus, set your daily time, pick a reading rhythm, and add an optional reminder.
            </Text>

            <TouchableOpacity
              style={styles.planPrimaryButton}
              onPress={() => setIsPlanSetupVisible(true)}
            >
              <Text style={styles.planPrimaryButtonText}>Open plan builder</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>
    );
  };

  const handleTestamentFilterChange = useCallback((next: 'all' | 'ot' | 'nt') => {
    if (next === testamentFilter) {
      return;
    }

    if (next === 'all') {
      setTestamentFilter(next);
      return;
    }

    const baseBooks = (bibleStore.filteredBooks as unknown as Book[]) || [];
    const nextBooks = baseBooks.filter(book =>
      next === 'nt'
        ? isNewTestamentAbbr(book.abbreviation)
        : !isNewTestamentAbbr(book.abbreviation)
    );

    if (nextBooks.length > 0) {
      const current = (bibleStore.currentBook as unknown as Book | null) || null;
      const currentInNext = current
        ? nextBooks.some(b => b.abbreviation === current.abbreviation)
        : false;

      if (!currentInNext) {
        const target = nextBooks[0];
        bibleStore.setCurrentBook(target as any);
        bibleStore.setCurrentChapter(1);
      }
    }

    setTestamentFilter(next);
  }, [testamentFilter, bibleStore.filteredBooks, bibleStore.currentBook, bibleStore]);

  const handleSearchPress = useCallback(() => {
    bibleStore.setShowSearch(true);
  }, [bibleStore]);

  // Enhanced header with activity panel
  const renderHeader = () => {
    return (
      <BibleHeader
        testamentFilter={testamentFilter}
        onTestamentFilterChange={handleTestamentFilterChange}
        onVersionsPress={() => setShowVersionsModal(true)}
        onSearchPress={handleSearchPress}
        onHistoryPress={() => setShowHistoryModal(true)}
        isOffline={isOffline}
      />
    );
  };


  // Update verse text style to use fontSize state
  const renderVerse = ({ item }: { item: BibleVerse }) => {
    return (
      <VerseItem
        verse={item}
        onLongPress={handleToggleHighlight}
        onPress={handleOpenVerseActions}
      />
    );
  };

  const ListFooter = () => {
    if (bibleStore.isVersesLoading && bibleStore.pagination.currentPage > 1) {
      return (
        <View style={styles.loadingFooter}>
          <ActivityIndicator color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading more verses...</Text>
        </View>
      );
    }
    return null;
  };

  const ListEmpty = () => {
    if (bibleStore.isVersesLoading) {
      return (
        <View style={styles.emptyContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.emptyText}>Loading verses...</Text>
        </View>
      );
    }

    if (bibleStore.versesError) {
      return (
        <EmptyState
          title="Failed to load verses"
          message={bibleStore.versesError}
          ctaText="Retry"
          onPressCTA={() => bibleStore.currentBook && bibleStore.currentVersion && bibleStore.fetchVerses(bibleStore.currentBook, bibleStore.currentChapter, bibleStore.currentVersion)}
        />
      );
    }

    return (
      <EmptyState
        title="Preparing Bible database"
        message="Please hold on while we load the Scriptures."
      />
    );
  };

  const renderScopedView = () => {
    return <ScopedViewModal scopedView={scopedView} onClose={handleExitScopedView} />;
  };

  const renderTimerModal = () => {
    return (
      <TimerModal
        visible={showTimerModal}
        timerId={bibleStore.getTodayTimerIdPublic()}
        phases={phasesForToday}
        onClose={() => setShowTimerModal(false)}
        onPhaseComplete={handlePhaseComplete}
        onAllPhasesComplete={handleAllPhasesComplete}
      />
    );
  };

  const renderMeditationModal = () => {
    const timerId = bibleStore.getTodayTimerIdPublic();
    const timer = timerId ? appTimerStore.get(timerId) : null;

    if (!timer) return null;

    const currentPhase = phasesForToday[timer.currentPhaseIndex];
    if (!currentPhase || currentPhase.id === 'reading') {
      return null;
    }

    const readingMode = bibleStore.readingPlan?.readingMode;
    const focusVirtueTerms = bibleStore.readingPlan?.focusVirtue?.matchTerms ?? null;

    let versesForMeditation = meditationVerses.length
      ? meditationVerses
      : (bibleStore.verses || []).map(v => ({ text: v.text, reference: v.reference ?? v.id })).slice(0, 40);

    if (!versesForMeditation.length) {
      const seg = bibleStore.activeReadingSegment;
      if (seg) {
        versesForMeditation.push({
          text: formatSegmentLabel(seg),
          reference: `${seg.bookName} ${seg.chapterStart}${seg.chapterEnd && seg.chapterEnd !== seg.chapterStart ? '-' + seg.chapterEnd : ''}`
        });
      }
    }

    // During prayer/contemplation, prepend paused verses and de-duplicate
    if (currentPhase.id === 'prayer' || currentPhase.id === 'contemplation') {
      const dedup = new Map<string, { text: string; reference: string }>();
      const keyOf = (v: { text: string; reference: string }) => `${v.reference}::${v.text}`;
      const paused = bibleStore.dailySession?.pausedMeditationVerses ?? [];
      paused.forEach(v => dedup.set(keyOf(v), v));
      versesForMeditation.forEach(v => {
        const k = keyOf(v);
        if (!dedup.has(k)) dedup.set(k, v);
      });
      versesForMeditation = Array.from(dedup.values());
    }

    const remainingSeconds = appTimerStore.remainingInPhase(timer.id);

    return (
      <Modal visible={showMeditationMode} animationType="fade" transparent onRequestClose={() => setShowMeditationMode(false)}>
        <MeditationVerse
          verses={versesForMeditation}
          phase={currentPhase}
          isActive={timer.isActive}
          remainingSeconds={Math.max(0, remainingSeconds)}
          readingMode={readingMode}
          focusVirtueTerms={focusVirtueTerms}
          pausedKeys={(bibleStore.getPausedMeditationVersesScoped?.() ?? []).map(v => `${v.reference}::${v.text}`)}
          onPauseAtVerse={(v) => { bibleStore.addPausedMeditationVerse(v); }}
          onDeletePausedVerse={(v) => { bibleStore.removePausedMeditationVerse(v); }}
          insightByKey={insightByKey}
          onReturn={() => {
            setShowMeditationMode(false);
            setPlanDetailsExpanded(true);
            setShowCompactPlan(false);
          }}
          onCompletePhase={() => {
            void completeCurrentPhase();
            setShowMeditationMode(false);
          }}
        />
      </Modal>
    );
  };

  return (
    <View style={styles.container} {...panResponder.panHandlers}>
      <Animated.View style={[styles.headerContainer, { transform: [{ translateY: headerTranslateY }] }]}>
        {renderHeader()}
      </Animated.View>

      {resumeTarget && !bibleStore.isPlanMode && (
        <View style={styles.resumeBar}>
          <Text style={styles.resumeText}>
            Resume {resumeTarget.bookName || bibleBooks.find(b => b.abbreviation === resumeTarget.book)?.name || resumeTarget.book} {resumeTarget.chapter}
          </Text>
          {isOffline && (
            <View style={styles.offlinePill}>
              <MaterialIcons name="wifi-off" size={14} color={theme.colors.warning} />
              <Text style={styles.offlinePillText}>Offline — actions sync later</Text>
            </View>
          )}
          <TouchableOpacity
            style={styles.resumeButton}
            onPress={async () => {
              const resumed = await bibleStore.resumeLastRead(true);
              if (!resumed && !isOffline) {
                toast.error('Unable to resume last reading position.');
              }
            }}
          >
            <Text style={styles.resumeButtonText}>Open</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Content Area */}
      <Animated.FlatList
        ref={verseListRef}
        data={bibleStore.verses}
        renderItem={renderVerse}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.contentContainer}
        ListHeaderComponent={renderPlanHeader}
        ListHeaderComponentStyle={styles.planHeader}
        initialNumToRender={20}
        maxToRenderPerBatch={10}
        windowSize={5}
        onEndReached={handleLoadMore}
        onEndReachedThreshold={0.1}
        onScroll={Animated.event(
          [{ nativeEvent: { contentOffset: { y: scrollY } } }],
          {
            useNativeDriver: true,
            listener: handleScrollNearEnd,
          }
        )}
        scrollEventThrottle={16}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={[theme.colors.primary]}
            tintColor={theme.colors.primary}
          />
        }
        ListFooterComponent={ListFooter}
        ListEmptyComponent={ListEmpty}
        onScrollToIndexFailed={info => {
          setTimeout(() => {
            verseListRef.current?.scrollToIndex({
              index: info.index,
              animated: true
            });
          }, 500);
        }}
      />

      {/* Search Modal */}
      <SearchModal
        visible={bibleStore.showSearch}
        onClose={() => bibleStore.setShowSearch(false)}
        onSearch={handleSearch}
      />

      <OverlayHost>
        {bibleStore.isPlanMode && showFloatingProgress && !showTimerModal && !bibleStore.dailySession?.completed && (() => {
          const timerId = bibleStore.getTodayTimerIdPublic();
          const timer = timerId ? appTimerStore.get(timerId) : null;
          const remaining = timerId ? appTimerStore.totalRemaining(timerId) : null;

          if (!timer || !timer.isActive || remaining == null) return null;

          return (
            <TouchableOpacity style={styles.floatingTimer} onPress={() => setShowTimerModal(true)}>
              <View style={styles.floatingTimerCircle}>
                <MaterialIcons name="timer" size={14} color={theme.colors.text.secondary} />
              </View>
              <Text style={styles.floatingTimerText}>
                {`Time remaining: ${Math.floor(Math.max(0, remaining) / 60)}:${String(Math.max(0, remaining) % 60).padStart(2, '0')}`}
              </Text>
            </TouchableOpacity>
          );
        })()}

        {bibleStore.isPlanMode && showDoneOverlay && (
          <View style={styles.bottomOverlay}>
            <View style={styles.bottomOverlayButton}>
              <MaterialIcons name="check-circle" size={18} color={theme.colors.text.inverse} />
              <Text style={styles.bottomOverlayText}>All done for today — great job!</Text>
            </View>
          </View>

        )}

        {bibleStore.isPlanMode && bibleStore.activeReadingSegment && !bibleStore.dailySession?.completed && !showTimerModal && (() => {
          const tid = bibleStore.getTodayTimerIdPublic();
          const t = tid ? appTimerStore.get(tid) : null;
          const curPhase = t ? phasesForToday[t.currentPhaseIndex] : null;
          const isReadingPhase = !curPhase || curPhase.id === 'reading';
          if (!isReadingPhase) return null;
          return (
            (() => {
              const seg = bibleStore.activeReadingSegment;
              const lastChapter = seg.chapterEnd ?? seg.chapterStart;
              const cur = bibleStore.currentChapter || 1;
              return (
                <View style={styles.bottomOverlay}>
                  {cur < lastChapter ? (
                    <TouchableOpacity style={styles.bottomOverlayButton} onPress={async () => { await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light); await goToNextChapterWithinSegment(); }}>
                      <MaterialIcons name="arrow-forward" size={18} color={theme.colors.text.inverse} />
                      <Text style={styles.bottomOverlayText}>Next</Text>
                    </TouchableOpacity>
                  ) : (
                    <TouchableOpacity style={styles.bottomOverlayButton} onPress={handleCompleteSegment}>
                      <MaterialIcons name="check" size={18} color={theme.colors.text.inverse} />
                      <Text style={styles.bottomOverlayText}>Complete segment</Text>
                    </TouchableOpacity>
                  )}
                </View>
              );
            })()
          );
        })()}
      </OverlayHost>

      <AdvancedActionsModal
        visible={showAdvancedActions}
        onClose={() => setShowAdvancedActions(false)}
        onPlanCleared={() => {
          journeyStore.setBiblePlan(null);
        }}
        onAfterStartOver={() => {
          if (!bibleStore.dailySession?.completed) setShowTimerModal(true);
        }}
      />

      <HistoryModal
        visible={showHistoryModal}
        isLoading={bibleStore.isHistoryLoading}
        entries={bibleStore.historyEntries.map((entry, index) => {
          const label = entry.type === 'search'
            ? `Search: ${entry.query ?? ''}`
            : `${entry.bookName ?? entry.bookAbbr ?? 'Unknown'}${entry.chapter ? ` ${entry.chapter}` : ''}${entry.verse ? `:${entry.verse}` : ''}`;
          const subLabel = new Date(entry.timestamp).toLocaleString();
          return {
            id: `${entry.timestamp}-${index}`,
            type: entry.type,
            label,
            subLabel,
            timestamp: entry.timestamp,
            data: entry as HistoryEntry,
          };
        })}
        onClear={async () => {
          await bibleStore.clearHistory();
        }}
        onSelect={(item) => {
          setShowHistoryModal(false);
          const data = item.data as HistoryEntry | undefined;
          if (!data) return;

          if (data.type === 'search' && data.query && bibleStore.currentVersion) {
            bibleStore.searchVerses(data.query, bibleStore.currentVersion);
            bibleStore.setShowSearch(true);
            bibleStore.setSearchQuery(data.query);
          } else if ((data.bookAbbr || data.bookName) && data.chapter) {
            const book = bibleStore.availableBooks.find(b => b.abbreviation === data.bookAbbr) ||
              bibleBooks.find(b => b.abbreviation === data.bookAbbr) ||
              bibleBooks.find(b => b.name === data.bookName);
            if (book) {
              bibleStore.setCurrentBook(book);
              bibleStore.setCurrentChapter(data.chapter);
              if (data.verse) {
                setTimeout(() => {
                  const index = bibleStore.verses.findIndex(v => {
                    try {
                      return parseVPLId(v.id).verse === data.verse;
                    } catch {
                      return false;
                    }
                  });
                  if (index >= 0) {
                    verseListRef.current?.scrollToIndex({ index, animated: true, viewPosition: 0.3 });
                  }
                }, 300);
              }
            }
          }
        }}
        onClose={() => setShowHistoryModal(false)}
      />

      <FontSizeModal
        visible={showFontModal}
        value={bibleStore.fontSize}
        onChange={(next) => {
          bibleStore.setFontSize(next);
        }}
        onClose={() => setShowFontModal(false)}
      />

      <VersionsModal
        visible={showVersionsModal}
        onClose={() => setShowVersionsModal(false)}
        onInstallVersion={handleInstallVersion}
      />

      <VerseActionsSheet
        visible={showVerseActions && !!selectedVerse}
        verse={selectedVerse}
        isBookmarked={selectedVerse ? bibleStore.bookmarkedVerses.has(selectedVerse.id) : false}
        isHighlighted={selectedVerse ? bibleStore.highlightedVerses.has(selectedVerse.id) : false}
        isLiked={selectedVerse ? bibleStore.likedVerses.has(selectedVerse.id) : false}
        onClose={handleCloseVerseActions}
        onBookmark={() => {
          if (!selectedVerse) return;
          handleToggleBookmark(selectedVerse.id);
        }}
        onHighlight={() => {
          if (!selectedVerse) return;
          handleToggleHighlight(selectedVerse.id);
        }}
        onLike={() => {
          if (!selectedVerse) return;
          handleLikeVerse(selectedVerse.id);
        }}
        onShare={() => {
          if (!selectedVerse) return;
          handleShareVerse(selectedVerse.id);
        }}
        onCompare={handleCompareSelectedVerse}
        onExplainWithAI={() => {
          handleCloseVerseActions();
          handleExplainWithAI();
        }}
      />

      <VerseComparisonModal
        visible={showComparisonModal}
        onClose={handleCloseComparisonModal}
        onRetry={handleCompareSelectedVerse}
        results={bibleStore.comparisonResults}
        isLoading={bibleStore.isComparisonLoading}
        error={bibleStore.comparisonError}
        reference={bibleStore.comparisonReference || selectedVerse?.reference}
        offline={isOffline}
      />

      <AIInsightsModal visible={showAIInsights} onClose={handleCloseAIInsights} />


      {renderScopedView()}
      {renderTimerModal()}
      {renderMeditationModal()}

      <ReadingPlanSetupModal
        visible={isPlanSetupVisible}
        onClose={() => setIsPlanSetupVisible(false)}
        onCreatePlan={handleCreatePlan}
      />
    </View>
  );
};

// Styles are now imported from ./bible/styles.ts via createBibleStyles

export default observer(BibleScreen);
