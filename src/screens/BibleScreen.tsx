import React, { useCallback, useEffect, useMemo, useState, useRef } from 'react';
import { observer } from 'mobx-react-lite';

import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  TextInput,
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
} from 'react-native';
import { BlurView } from 'expo-blur';
import { MaterialIcons } from '@expo/vector-icons';
import { useNavigation, NavigationProp, RouteProp } from '@react-navigation/native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import BiblePicker from '@/components/BiblePicker';
import BookSelector from '@/components/BookSelector';
import HistoryModal, { HistoryModalEntry } from '@/components/HistoryModal';
import FontSizeModal from '@/components/FontSizeModal';
import VerseActionsSheet from '@/components/VerseActionsSheet';
import BibleDBService from '@/utils/database';
import VerseComparisonModal from '@/components/VerseComparisonModal';
import ReadingPlanSetupModal from '@/components/ReadingPlanSetupModal';
import ReminderTimePicker from '@/components/ReminderTimePicker';
import ReadingTimer from '@/components/ReadingTimer';
import PlanSegmentChip from '@/components/PlanSegmentChip';
import OverlayHost from '@/components/OverlayHost';
import { Book, BibleVersion, BibleVerse } from '@/types';
import { ReadingPlanMode, ReadingPlanPhase } from '@/constants/readingPlanModes';
import { bibleBooks } from '@/constants/bibleBooks';
import { useBibleStore } from '@/stores/BibleStore';
import { useJourneyStore, useDailyPathStore } from '@/stores/StoreProvider';
import { useSharedValue, withTiming } from 'react-native-reanimated';
import { HistoryEntry, DailyPhaseProgress } from '@/stores/BibleStore';

import { RootStackParamList, ScopedVerseParam } from '@/types';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';
import { Audio } from 'expo-av';
import EmptyState from '@/components/EmptyState';
import MeditationVerse from '@/components/MeditationVerse';
import { appTimerStore } from '@/stores/AppTimerStore';

const getLocalMidnightMs = (date: Date) => {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
};

const makeVerseKey = (chapter: number | string | null | undefined, verse: number | string | null | undefined) =>
  `${chapter ?? ''}:${verse ?? ''}`;

const parseVerseAddress = (verse: BibleVerse, fallbackChapter?: number) => {
  try {
    const { chapter, verse: verseNumber } = parseVPLId(verse.id);
    return { chapter, verse: verseNumber };
  } catch {
    const ref = verse.reference ?? '';
    const refMatch = ref.match(/(\d+):(\d+)/);
    const chapter = refMatch ? Number(refMatch[1]) : fallbackChapter ?? NaN;
    const verseNumber = refMatch ? Number(refMatch[2]) : NaN;
    return { chapter, verse: verseNumber };
  }
};

const makeSegmentRangeToken = (segment?: { chapterStart?: number | null; chapterEnd?: number | null; verseStart?: number | null; verseEnd?: number | null } | null) => {
  if (!segment) return '';
  const startChapter = segment.chapterStart ?? '';
  const endChapter = segment.chapterEnd ?? segment.chapterStart ?? '';
  const startVerse = segment.verseStart ?? '';
  const endVerse = segment.verseEnd ?? '';
  return `${startChapter}:${startVerse}-${endChapter}:${endVerse}`;
};

type ScopedViewState = {
  title?: string | null;
  subtitle?: string | null;
  verses: ScopedVerseParam[];
};

interface BibleScreenProps {
  route?: RouteProp<RootStackParamList, 'BibleScreen'>;
}

const BibleScreen = ({ route }: BibleScreenProps) => {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
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
  return timerId ? appTimerStore.totalRemaining(timerId) : null;
}, [bibleStore]);

  // Auto-hide header on scroll
  const scrollY = useRef(new Animated.Value(0)).current;
  const clampedY = useRef(Animated.diffClamp(scrollY, 0, 56)).current;
  const headerTranslateY = clampedY.interpolate({
    inputRange: [0, 56],
    outputRange: [0, -56],
  });

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
      } catch {}
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
    } catch {}
    
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
  } catch {}

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

  useEffect(() => {
    // Open plan setup if requested by navigation and no plan exists
    const openPlan = (route as any)?.params?.openPlanSetup;
    if (openPlan && !bibleStore.readingPlan) {
      setIsPlanSetupVisible(true);
      // clear the flag to prevent reopening on re-render
      try { (navigation as any).setParams?.({ openPlanSetup: undefined }); } catch {}
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
        toast.success(`${version.englishName} installed successfully`);
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
    }
  }, []);

  const handleToggleBookmark = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const success = await bibleStore.toggleBookmark(verseId);
    if (success) {
      await bibleStore.saveUserPreferences();
    }
  }, []);

  const handleLikeVerse = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await bibleStore.likeVerse(verseId);
  }, []);

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
      toast.success('All done for today — great job!');
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
  
  if (bibleStore.dailySession?.completed) {
    toast.success('All done for today — great job!');
    return;
  }
  
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

  const handleCreatePlan = useCallback(async ({ books, timePerDay, readingMode, phases, reminderTime }: { books: string[]; timePerDay: number; readingMode: ReadingPlanMode; phases: ReadingPlanPhase[]; reminderTime?: string }) => {
    try {
      await bibleStore.createReadingPlan({
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime,
      });
      
      setBuilderReminder(reminderTime?.trim?.() ?? reminderTime ?? '');
      setIsPlanSetupVisible(false);
      
      // Enable plan mode and navigate to first segment
      bibleStore.enablePlanMode();
      const navigated = await bibleStore.focusPlanSegment();
      
      if (navigated) {
        toast.success('Your reading plan has started!');
        setShowTimerModal(true);
        setShowCompactPlan(true);
        
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
      } else {
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
      });
      void journeyStore.syncUserProgress();
      // Keep compact plan minimized while focused
      dailyPathStore.setReadingPlanSetupCompleted(true);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to create plan.';
      toast.error(message);
    }
  }, [bibleStore, dailyPathStore, journeyStore]);

  const handleApplyReminder = useCallback(async () => {
    try {
      await bibleStore.setReadingReminder(builderReminder.trim() || null);
      toast.success(builderReminder.trim() ? 'Reminder updated' : 'Reminder cleared');
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
      toast.error('Unable to update reminder.');
    }
  }, [bibleStore, builderReminder, journeyStore]);

  const handleClearPlan = useCallback(async () => {
    const ok = await new Promise<boolean>(resolve => {
      Alert.alert(
        'Clear plan',
        'This will remove your current reading plan. Continue?',
        [
          { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
          { text: 'OK', style: 'destructive', onPress: () => resolve(true) },
        ],
        { cancelable: true }
      );
    });
    if (!ok) return;
    await bibleStore.clearReadingPlan();
    toast.success('Reading plan cleared');
    journeyStore.setBiblePlan(null);
  }, [bibleStore, builderReminder, journeyStore]);

  const handleToggleSegment = useCallback(async (segmentId: string) => {
    resetIdleTimer();
    try {
      await bibleStore.togglePlanSegmentCompletion(segmentId);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (error) {
      console.error('Failed to update segment', error);
      toast.error('Unable to update segment progress.');
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
                      const daysSinceStart = Math.max(1, Math.floor((nowMs - startMs) / (24*60*60*1000)) + 1);
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
                      disabled={(function() {
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
                          toast.success('All done for today — previewing next session');
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

  const handleSavedSearchSelect = useCallback((term: string) => {
    bibleStore.setSearchQuery(term);
    handleSearch(term);
  }, [bibleStore, handleSearch]);

  const handleRemoveSavedSearch = useCallback((term: string) => {
    bibleStore.removeSavedSearch(term);
  }, [bibleStore]);

  const handleInlineBookSelect = useCallback((book: Book) => {
    bibleStore.setCurrentBook(book as any);
  }, [bibleStore]);

  const handleInlineChapterSelect = useCallback((chapter: number) => {
    bibleStore.setCurrentChapter(chapter);
  }, [bibleStore]);

  const handleSearchPress = useCallback(() => {
    bibleStore.setShowSearch(true);
  }, [bibleStore]);

  // Enhanced header with activity panel
  const currentVersionLabel = useMemo(() => {
    const version = bibleStore.currentVersion;
    if (!version) return 'Versions';
    const candidate = (version as any).shortName ?? (version as any).code ?? version.englishName;
    return typeof candidate === 'string' && candidate.trim().length > 0 ? candidate : 'Versions';
  }, [bibleStore.currentVersion]);

  const renderHeader = () => (
    <View style={styles.headerContainer}>
      <BlurView intensity={20} style={styles.header}>
        <View style={styles.headerLeft}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => setShowVersionsModal(true)}
          >
            <Text style={styles.headerButtonText}>
              {currentVersionLabel}
            </Text>
            <MaterialIcons name="menu-book" size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>
          
          {isOffline && (
            <View style={styles.offlineIndicator}>
              <MaterialIcons name="wifi-off" size={12} color={theme.colors.warning} />
              <Text style={styles.offlineText}>Offline</Text>
            </View>
          )}

          <View style={styles.inlineSelectors}>
            <BookSelector
              currentBook={bibleStore.currentBook || bibleStore.filteredBooks[0] || bibleBooks[0]}
              onSelect={handleInlineBookSelect}
              books={bibleStore.filteredBooks as any}
            />
            <BiblePicker
              value={bibleStore.currentChapter}
              items={Array.from({ length: bibleStore.getChapterCount() }, (_, i) => i + 1)}
              onSelect={handleInlineChapterSelect}
            />
          </View>
        </View>

        <View style={styles.headerRight}>
          <TouchableOpacity
            style={styles.iconButton}
            onPress={handleSearchPress}
          >
            <MaterialIcons name="search" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.iconButton}
            onPress={() => setShowHistoryModal(true)}
            accessibilityLabel="Open history"
            accessibilityRole="button"
          >
            <MaterialIcons name="history" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </BlurView>
    </View>
  );


  // Update verse text style to use fontSize state
  const renderVerse = ({ item }: { item: BibleVerse }) => {
    let verseNum = 0;
    try {
      verseNum = parseVPLId(item.id).verse;
    } catch {
      // Fallback: try to infer verse number from item.reference or default to 0
      const match = item.reference?.match(/:(\d+)$/);
      verseNum = match ? parseInt(match[1], 10) : 0;
    }
    const isHighlighted = bibleStore.highlightedVerses.has(item.id);
    const isBookmarked = bibleStore.bookmarkedVerses.has(item.id);
    const isLiked = bibleStore.likedVerses.has(item.id);
    
    return (
      <View style={[
        styles.verseContainer,
        isHighlighted && styles.highlightedVerse
      ]}>
        <TouchableOpacity 
          style={styles.verseContent}
          onLongPress={() => handleToggleHighlight(item.id)}
          onPress={() => handleOpenVerseActions(item.id)}
        >
          {(isBookmarked || isLiked) && (
            <View style={styles.verseMarkers}>
              {isBookmarked && (
                <MaterialIcons name="bookmark" size={14} color={theme.colors.primary} />
              )}
              {isLiked && (
                <MaterialIcons name="favorite" size={14} color={theme.colors.error} />
              )}
            </View>
          )}

          <Text style={styles.verseNumber}>
            {verseNum}
          </Text>
          <Text style={[styles.verseText, { fontSize: bibleStore.fontSize }]}>
            {item.text}
          </Text>
        </TouchableOpacity>
      </View>
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
    if (!scopedView) {
      return null;
    }

    console.log('[BibleScreen] rendering scoped view', scopedView);

    return (
      <View style={styles.scopedContainer}>
        <View style={styles.scopedHeader}>
          <View style={styles.scopedHeaderText}>
            {scopedView.title ? (
              <Text style={styles.scopedTitle}>{scopedView.title}</Text>
            ) : null}
            {scopedView.subtitle ? (
              <Text style={styles.scopedSubtitle}>{scopedView.subtitle}</Text>
            ) : null}
          </View>
          <TouchableOpacity style={styles.scopedDismissButton} onPress={handleExitScopedView}>
            <MaterialIcons name="close" size={20} color={theme.colors.text.secondary} />
            <Text style={styles.scopedDismissText}>Dismiss</Text>
          </TouchableOpacity>
        </View>

        <ScrollView
          style={styles.scopedScroll}
          contentContainerStyle={styles.scopedScrollContent}
          showsVerticalScrollIndicator={false}
        >
          {scopedView.verses.map((verse, index) => (
            <View
              key={`${verse.text}-${index}`}
              style={[styles.scopedVerseCard, verse.isPrimary && styles.scopedVersePrimary]}
            >
              {verse.reference ? (
                <Text style={styles.scopedReference}>{verse.reference}</Text>
              ) : null}
              <Text style={styles.scopedVerseText}>{verse.text}</Text>
            </View>
          ))}
        </ScrollView>
      </View>
    );
  };

  const renderTimerModal = () => {
    const timerId = bibleStore.getTodayTimerIdPublic();
    if (!timerId) return null;

    return (
      <Modal visible={showTimerModal} animationType="slide" transparent>
        <View style={styles.timerModalBackdrop}>
          <View style={styles.timerModalCard}>
            <View style={styles.timerModalHeader}>
              <Text style={styles.timerModalTitle}>Today's Focus</Text>
              <TouchableOpacity onPress={() => setShowTimerModal(false)}>
                <MaterialIcons name="close" size={22} color={theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>
            
            <ReadingTimer
              timerId={timerId}
              phases={phasesForToday}
              onPhaseComplete={handlePhaseComplete}
              onAllPhasesComplete={handleAllPhasesComplete}
              passages={(() => {
                const seg = bibleStore.activeReadingSegment;
                if (!seg) return undefined;
                return [formatSegmentLabel(seg)];
              })()}
            />
          </View>
        </View>
      </Modal>
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

  const remainingSeconds = appTimerStore.remainingInPhase(timer.id);

  return (
    <Modal visible={showMeditationMode} animationType="fade" transparent onRequestClose={() => setShowMeditationMode(false)}>
      <MeditationVerse
        verses={versesForMeditation}
        phase={currentPhase}
        isActive={timer.isActive}
        remainingSeconds={Math.max(0, remainingSeconds)}
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
    <View style={styles.container}>
      <Animated.View style={[styles.headerContainer, { transform: [{ translateY: headerTranslateY }] }]}>
        {renderHeader()}
      </Animated.View>

      {resumeTarget && !bibleStore.isPlanMode && (
        <View style={styles.resumeBar}>
          <Text style={styles.resumeText}>
            Resume {resumeTarget.bookName || bibleBooks.find(b => b.abbreviation === resumeTarget.book)?.name || resumeTarget.book} {resumeTarget.chapter}
          </Text>
          <TouchableOpacity
            style={styles.resumeButton}
            onPress={async () => {
              const resumed = await bibleStore.resumeLastRead(true);
              if (!resumed) {
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
      <Modal
        visible={bibleStore.showSearch}
        animationType="slide"
        onRequestClose={() => bibleStore.setShowSearch(false)}
      >
        <View style={styles.searchContainer}>
          <View style={styles.searchHeader}>
            <TextInput
              style={styles.searchInput}
              value={bibleStore.searchQuery}
              onChangeText={handleSearch}
              placeholder="Search Bible..."
              autoFocus
            />
            <TouchableOpacity 
              style={styles.closeButton}
              onPress={() => {
                bibleStore.setShowSearch(false);
                bibleStore.clearSearch();
              }}
            >
              <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          <FlatList
            data={bibleStore.searchResults}
            ListHeaderComponent={() => (
              bibleStore.savedSearches.length ? (
                <View style={styles.savedSearchContainer}>
                  <View style={styles.savedSearchHeader}>
                    <Text style={styles.savedSearchTitle}>Recent searches</Text>
                    <TouchableOpacity onPress={() => bibleStore.clearSavedSearches()}>
                      <Text style={styles.clearSavedSearchText}>Clear</Text>
                    </TouchableOpacity>
                  </View>
                  <View style={styles.savedSearchChips}>
                    {bibleStore.savedSearches.map(term => (
                      <View key={term} style={styles.savedSearchChip}>
                        <TouchableOpacity onPress={() => handleSavedSearchSelect(term)}>
                          <Text style={styles.savedSearchText}>{term}</Text>
                        </TouchableOpacity>
                        <TouchableOpacity onPress={() => handleRemoveSavedSearch(term)}>
                          <MaterialIcons name="close" size={14} color={theme.colors.text.secondary} />
                        </TouchableOpacity>
                      </View>
                    ))}
                  </View>
                </View>
              ) : null
            )}
            renderItem={({ item }) => (
              <TouchableOpacity 
                style={styles.searchResultItem}
                onPress={() => {
                  const { bookAbbr, chapter } = parseVPLId(item.id);
                  const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
                  if (book) {
                    bibleStore.setCurrentBook(book);
                    bibleStore.setCurrentChapter(chapter);
                    bibleStore.setShowSearch(false);
                    bibleStore.clearSearch();
                  }
                }}
              >
                <Text style={styles.searchResultReference}>{item.reference}</Text>
                <Text style={styles.searchResultText}>{item.text}</Text>
              </TouchableOpacity>
            )}
            keyExtractor={item => item.id}
            ListEmptyComponent={() => (
              bibleStore.isSearchLoading ? (
                <View style={styles.loadingContainer}>
                  <ActivityIndicator size="large" color={theme.colors.primary} />
                </View>
              ) : (
                <View style={styles.emptySearchContainer}>
                  <MaterialIcons name="search" size={32} color={theme.colors.text.secondary} />
                  <Text style={styles.emptySearchText}>Start typing to search across the Bible.</Text>
                </View>
              )
            )}
          />
        </View>
      </Modal>

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

      <Modal visible={showAdvancedActions} transparent animationType="fade" onRequestClose={() => setShowAdvancedActions(false)}>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <TouchableOpacity
              style={styles.dangerRow}
              onPress={async () => {
                const confirm = await new Promise<boolean>(resolve => {
                  Alert.alert(
                    'Start over',
                    'This will reset your plan progress and set today as the new start date. Continue?',
                    [
                      { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
                      { text: 'OK', style: 'destructive', onPress: () => resolve(true) },
                    ],
                    { cancelable: true }
                  );
                });
                if (!confirm) return;
                setShowAdvancedActions(false);
                const ok = await bibleStore.startOverPlan();
                if (ok) {
                  await bibleStore.focusPlanSegment();
                  await bibleStore.ensureDailySessionPrepared();
                  if (!bibleStore.dailySession?.completed) setShowTimerModal(true);
                  toast.success('Plan started over from today');
                } else {
                  toast.error('Unable to start over');
                }
              }}
            >
              <MaterialIcons name="restart-alt" size={18} color={theme.colors.error} />
              <Text style={styles.dangerText}>Start over</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.dangerRow}
              onPress={async () => {
                setShowAdvancedActions(false);
                await handleClearPlan();
              }}
            >
              <MaterialIcons name="delete-outline" size={18} color={theme.colors.error} />
              <Text style={styles.dangerText}>Clear plan</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.modalRow}
              onPress={async () => {
                const confirm = await new Promise<boolean>(resolve => {
                  Alert.alert(
                    'Reset start date',
                    'This will set your plan start date to today. Your completions remain unchanged. Continue?',
                    [
                      { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
                      { text: 'OK', onPress: () => resolve(true) },
                    ],
                    { cancelable: true }
                  );
                });
                if (!confirm) return;
                setShowAdvancedActions(false);
                const ok = await bibleStore.resetPlanStartDateToToday();
                if (ok) {
                  await bibleStore.focusPlanSegment();
                  await bibleStore.ensureDailySessionPrepared();
                  toast.success('Plan start date set to today');
                } else {
                  toast.error('Unable to reset start date');
                }
              }}
            >
              <Text style={styles.modalText}>Reset start date to today</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.modalRow}
              onPress={async () => {
                const confirm = await new Promise<boolean>(resolve => {
                  Alert.alert(
                    'Repair plan to today',
                    'This will mark segments as completed up to today’s expected pace. Continue?',
                    [
                      { text: 'Cancel', style: 'cancel', onPress: () => resolve(false) },
                      { text: 'OK', onPress: () => resolve(true) },
                    ],
                    { cancelable: true }
                  );
                });
                if (!confirm) return;
                setShowAdvancedActions(false);
                const ok = await bibleStore.repairPlanToExpectedByToday();
                if (ok) {
                  await bibleStore.focusPlanSegment();
                  await bibleStore.ensureDailySessionPrepared();
                  toast.success('Plan repaired to expected by today');
                } else {
                  toast.error('Unable to repair plan');
                }
              }}
            >
              <Text style={styles.modalText}>Repair plan to expected by today</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.modalRow} onPress={() => setShowAdvancedActions(false)}>
              <Text style={styles.modalText}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

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

      <Modal visible={showVersionsModal} animationType="slide">
      <View style={styles.modalContainer}>
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Bible Versions</Text>
          <TouchableOpacity onPress={() => setShowVersionsModal(false)}>
            <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>
        
        {bibleStore.isVersionsLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={theme.colors.primary} />
          </View>
        ) : (
          <FlatList
            data={bibleStore.availableVersions}
            keyExtractor={(item) => item.shortName}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.versionItem}
                onPress={() => {
                  bibleStore.setCurrentVersion(item);
                  setShowVersionsModal(false);
                }}
              >
                <View style={styles.versionInfo}>
                  <Text style={styles.versionName}>
                    {item.englishName} ({item.shortName})
                  </Text>
                  {item.preinstalled && (
                    <Text style={styles.versionSubtext}>Pre-installed</Text>
                  )}
                </View>

                {bibleStore.installedVersions.includes(item.shortName) ? (
                  <MaterialIcons name="check-circle" size={24} color={theme.colors.primary} />
                ) : bibleStore.isInstallingVersion && bibleStore.installingVersionId === item.shortName ? (
                  <ActivityIndicator size="small" color={theme.colors.primary} />
                ) : (
                  <TouchableOpacity 
                    onPress={(e) => {
                      e.stopPropagation();
                      handleInstallVersion(item);
                    }}
                    disabled={bibleStore.isInstallingVersion}
                  >
                    <MaterialIcons 
                      name="download" 
                      size={24} 
                      color={bibleStore.isInstallingVersion ? theme.colors.text.secondary : theme.colors.primary} 
                    />
                  </TouchableOpacity>
                )}
              </TouchableOpacity>
            )}
          />
        )}
      </View>
    </Modal>

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

      <Modal
        visible={showAIInsights}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={handleCloseAIInsights}
      >
        <View style={styles.aiModalContainer}>
          <View style={styles.aiModalHeader}>
            <View style={{ flex: 1 }}>
              <Text style={styles.aiModalTitle}>AI Insights</Text>
              {bibleStore.aiInsightReference ? (
                <Text style={styles.aiModalReference}>{bibleStore.aiInsightReference}</Text>
              ) : null}
            </View>
            <TouchableOpacity onPress={handleCloseAIInsights}>
              <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          {bibleStore.isAIInsightLoading ? (
            <View style={styles.aiModalLoading}>
              <ActivityIndicator size="large" color={theme.colors.primary} />
              <Text style={styles.aiModalLoadingText}>Gathering historical context...</Text>
            </View>
          ) : bibleStore.aiInsightError ? (
            <View style={styles.aiModalError}>
              <MaterialIcons name="error-outline" size={20} color={theme.colors.error} />
              <Text style={styles.aiModalErrorText}>{bibleStore.aiInsightError}</Text>
            </View>
          ) : (
            <ScrollView contentContainerStyle={styles.aiModalContent}>
              {bibleStore.aiInsightSections.length ? (
                bibleStore.aiInsightSections.map(section => (
                  <View key={`${section.title}-${section.content.slice(0, 20)}`} style={styles.aiSection}>
                    <Text style={styles.aiSectionTitle}>{section.title}</Text>
                    <Text style={styles.aiSectionBody}>{section.content}</Text>
                  </View>
                ))
              ) : (
                <Text style={styles.aiModalPlaceholder}>No insights available for this verse yet.</Text>
              )}
            </ScrollView>
          )}
        </View>
      </Modal>

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

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  headerContainer: {
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  header: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  headerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.surface,
  },
  headerButtonText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  settingsOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  settingsCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.xl,
    paddingVertical: theme.spacing.lg,
    paddingHorizontal: theme.spacing.lg,
    maxHeight: '85%',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}12`,
    shadowColor: theme.colors.shadow,
    shadowOpacity: 0.18,
    shadowRadius: 18,
    elevation: 8,
  },
  settingsHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
  },
  settingsTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  settingsCloseButton: {
    padding: theme.spacing.xs,
  },
  settingsContent: {
    gap: theme.spacing.lg,
    paddingBottom: theme.spacing.md,
  },
  settingsSection: {
    gap: theme.spacing.sm,
  },
  settingsSectionLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  settingsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    flexWrap: 'wrap',
  },
  settingsItemText: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  settingsItemTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  settingsItemSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  settingsDivider: {
    height: 1,
    backgroundColor: `${theme.colors.border}60`,
  },
  settingsAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  settingsActionText: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  settingsActionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  settingsActionSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  inlineSelectors: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginLeft: theme.spacing.md,
  },
  controlsGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  apocryphaToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.surface}AA`,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  apocryphaLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontWeight: '600',
  },
  contentContainer: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xxl,
  },
  planHeader: {
    paddingBottom: theme.spacing.lg,
  },
  planContainer: {
    gap: theme.spacing.lg,
    paddingTop: theme.spacing.lg,
    paddingBottom: theme.spacing.md,
  },
  planTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  planSubtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  planCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    gap: theme.spacing.md,
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 12,
    elevation: 3,
  },
  planCardHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: theme.spacing.md,
    flexWrap: 'wrap',
  },
  planCompactToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.surface,
  },
  planCompactToggleText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  planCardTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  planCardSummary: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  planCardMeta: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.tertiary,
    marginTop: theme.spacing.xs,
  },
  planSessionSummaryCard: {
    marginTop: theme.spacing.xs,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: `${theme.colors.surface}F2`,
    borderWidth: 1,
    borderColor: `${theme.colors.border}80`,
    gap: theme.spacing.xs,
  },
  planSessionSummaryTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  planSessionSummaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  planSessionSummaryLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  planSessionSummaryValue: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  todayContainer: {
    marginTop: theme.spacing.sm,
    paddingTop: theme.spacing.xs,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
    gap: theme.spacing.xs,
  },
  todayRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 2,
  },
  todayLabel: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  todayValue: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: '#00000066',
    justifyContent: 'flex-end',
  },
  modalCard: {
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    borderTopLeftRadius: theme.borderRadius.lg,
    borderTopRightRadius: theme.borderRadius.lg,
  },
  modalRow: {
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
  },
  modalText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  dangerRow: {
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    gap: theme.spacing.xs,
  },
  dangerText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    fontWeight: '600',
  },
  planClearButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    backgroundColor: `${theme.colors.error}12`,
    borderRadius: theme.borderRadius.sm,
  },
  planClearButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
  },
  planActiveSegment: {
    gap: theme.spacing.xs,
  },
  planSectionTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  planSegmentChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: `${theme.colors.primary}12`,
  },
  planSegmentCompleted: {
    backgroundColor: `${theme.colors.primary}22`,
  },
  planSegmentText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  planUpcomingSection: {
    gap: theme.spacing.sm,
  },
  planSegmentList: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.xs,
  },
  planReminderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: theme.spacing.md,
  },
  planReminderInfo: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  planReminderHint: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  planReminderControls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  planReminderInput: {
    width: 76,
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  planReminderButton: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.primary,
  },
  planReminderButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  planPresetList: {
    gap: theme.spacing.sm,
  },
  planPresetItem: {
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}25`,
    padding: theme.spacing.md,
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.background,
  },
  planPresetItemActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}12`,
  },
  planPresetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  planPresetTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  planPresetDescription: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  planBooksRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  planActionLink: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  planBookChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.xs,
  },
  planBookChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.primary}15`,
  },
  planBookChipText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  planEmptyText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  planControlsRow: {
    flexDirection: 'row',
    gap: theme.spacing.md,
    flexWrap: 'wrap',
  },
  planChaptersGroup: {
    flex: 1,
    gap: theme.spacing.sm,
  },
  planChaptersOptions: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.xs,
  },
  planChapterOption: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.background,
  },
  planChapterOptionActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}18`,
  },
  planChapterOptionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  planReminderInline: {
    flexBasis: 140,
    gap: theme.spacing.xs,
  },
  planPrimaryButton: {
    marginTop: theme.spacing.sm,
    alignSelf: 'flex-start',
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.md,
    backgroundColor: theme.colors.primary,
  },
  planPrimaryButtonDisabled: {
    backgroundColor: `${theme.colors.primary}40`,
  },
  planPrimaryButtonText: {
    ...theme.typography.button.primary,
    color: theme.colors.text.inverse,
  },
  planFooterActions: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
  },
  planCompactRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: theme.spacing.sm,
  },
  planCardControls: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    alignItems: 'center',
    flexWrap: 'wrap',
  },
  planCompactActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    flexShrink: 0,
  },
  planCompactActionButton: {
    paddingHorizontal: theme.spacing.sm,
  },
  planCompactIconButton: {
    height: 32,
    width: 32,
    borderRadius: theme.borderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme.colors.primary}10`,
  },
  planIconLauncher: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
    alignSelf: 'flex-start',
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.primary}12`,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}30`,
  },
  planIconLauncherText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  compactPlanBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-start',
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.md,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
  },
  compactPlanButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  compactPlanText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  planSecondaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
  },
  planSecondaryButtonLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  scopedContainer: {
    flex: 1,
    padding: theme.spacing.lg,
    gap: theme.spacing.lg,
  },
  scopedHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: theme.spacing.md,
  },
  scopedHeaderText: {
    flex: 1,
    gap: theme.spacing.xs,
  },
  scopedTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  scopedSubtitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
  scopedDismissButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.surface,
  },
  scopedDismissText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  scopedScroll: {
    flex: 1,
  },
  scopedScrollContent: {
    gap: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
  },
  scopedVerseCard: {
    gap: theme.spacing.xs,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    shadowColor: theme.colors.shadow,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.08,
    shadowRadius: 12,
    elevation: 2,
  },
  scopedVersePrimary: {
    borderWidth: 1,
    borderColor: `${theme.colors.primary}40`,
    backgroundColor: `${theme.colors.primary}12`,
  },
  scopedReference: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  scopedVerseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
    lineHeight: 26,
  },
  nextSegmentFooter: {
    marginHorizontal: theme.spacing.lg,
    marginVertical: theme.spacing.xl,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  nextSegmentTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    textAlign: 'center',
  },
  nextSegmentSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  nextSegmentButton: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
  },
  nextSegmentButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  // Floating compact timer pill
  floatingTimer: {
    position: 'absolute',
    right: theme.spacing.md,
    top: 56 + theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: `${theme.colors.surface}E6`,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.xs,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  floatingTimerCircle: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.surfaceVariant,
  },
  floatingTimerText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  overlayHost: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    zIndex: 35,
    elevation: 5,
  },
  // Bottom overlay next chapter CTA
  bottomOverlay: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: theme.spacing.lg,
    alignItems: 'center',
    zIndex: 40,
    elevation: 6,
  },
  bottomOverlayButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    shadowColor: theme.colors.shadow,
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  bottomOverlayText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  // Timer modal
  timerModalBackdrop: {
    flex: 1,
    backgroundColor: '#00000066',
    justifyContent: 'flex-end',
  },
  timerModalCard: {
    backgroundColor: theme.colors.surface,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    gap: theme.spacing.md,
  },
  timerModalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.sm,
  },
  timerModalTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  resumeBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: `${theme.colors.primary}10`,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  resumeText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  resumeButton: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.sm,
  },
  resumeButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  verseContainer: {
    paddingVertical: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
  },
  verseContent: {
    flexDirection: 'row',
    paddingHorizontal: theme.spacing.md,
  },
  verseNumber: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    marginRight: theme.spacing.sm,
    minWidth: 24,
    textAlign: 'right',
  },
  verseText: {
    flex: 1,
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
  },
  verseMarkers: {
    flexDirection: 'column',
    alignItems: 'flex-start',
    gap: theme.spacing.xs,
    marginLeft: 0-theme.spacing.sm,
    marginTop: theme.spacing.xs,
  },
  highlightedVerse: {
    backgroundColor: `${theme.colors.primary}15`,
  },
  bookmarkButton: {
    padding: theme.spacing.xs,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  searchContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  searchHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  searchInput: {
    flex: 1,
    ...theme.typography.body.sans,
    padding: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    marginRight: theme.spacing.sm,
  },
  searchResultItem: {
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  searchResultReference: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    marginBottom: theme.spacing.xs,
  },
  searchResultText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  modalContainer: {
    flex: 1,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  modalTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  versionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  versionInfo: {
    flex: 1,
  },
  versionName: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  versionSubtext: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  activityBar: {
    height: 56,
    paddingHorizontal: theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  activityContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  activityLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  activityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.primary}10`,
  },
  activityButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  closeButton: {
    padding: theme.spacing.xs,
  },
  iconButton: {
    padding: theme.spacing.xs,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.primary}10`,
  },
  loadingFooter: {
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
  },
  loadingText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  savedSearchContainer: {
    paddingHorizontal: theme.spacing.md,
    paddingTop: theme.spacing.md,
    paddingBottom: theme.spacing.sm,
    gap: theme.spacing.sm,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: theme.spacing.lg,
  },
  savedSearchHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  savedSearchTitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  clearSavedSearchText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  savedSearchChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
  },
  savedSearchChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: `${theme.colors.primary}15`,
  },
  savedSearchText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  emptyText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.sm,
  },
  emptySearchContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.xl,
    gap: theme.spacing.sm,
  },
  emptySearchText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  errorText: {
    ...theme.typography.body.sans,
    color: theme.colors.error,
    textAlign: 'center',
    marginBottom: theme.spacing.sm,
  },
  retryButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    backgroundColor: theme.colors.primary,
    borderRadius: theme.borderRadius.md,
  },
  retryButtonText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.inverse,
  },
  offlineIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.warning}15`,
  },
  offlineText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.warning,
    fontSize: 10,
  },
  aiModalContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
    paddingTop: theme.spacing.xl,
    paddingHorizontal: theme.spacing.lg,
  },
  aiModalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.lg,
  },
  aiModalTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  aiModalReference: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  aiModalLoading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.md,
  },
  aiModalLoadingText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  aiModalError: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    padding: theme.spacing.md,
    backgroundColor: `${theme.colors.error}10`,
  },
  aiModalErrorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    flex: 1,
  },
  aiModalContent: {
    paddingBottom: theme.spacing.xxl,
    gap: theme.spacing.lg,
  },
  aiSection: {
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.xl,
  },
  aiSectionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
    textAlign: 'center',
  },
  aiSectionBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  aiModalPlaceholder: {
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.sm,
  },
});

export default observer(BibleScreen);