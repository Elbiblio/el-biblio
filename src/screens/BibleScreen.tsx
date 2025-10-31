import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { observer } from 'mobx-react-lite';

import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  FlatList,
  Modal,
  ActivityIndicator,
  RefreshControl,
  ScrollView,
  Animated,
  Switch,
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
import VerseComparisonModal from '@/components/VerseComparisonModal';
import ReadingPlanSetupModal from '@/components/ReadingPlanSetupModal';
import ReminderTimePicker from '@/components/ReminderTimePicker';
import { Book, BibleVersion, BibleVerse } from '@/types';
import { ReadingPlanMode, ReadingPlanPhase } from '@/constants/readingPlanModes';
import { bibleBooks } from '@/constants/bibleBooks';
import { Brush, BrushOutlined } from '@/components/Icons';
import { useBibleStore, HistoryEntry } from '@/stores/BibleStore';
import { useJourneyStore, useDailyPathStore } from '@/stores/StoreProvider';

import { RootStackParamList, ScopedVerseParam } from '@/types';

import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';
import EmptyState from '@/components/EmptyState';

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
  const verseListRef = useRef<FlatList>(null);
  const pendingScrollVerseRef = useRef<number | null>(null);
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
  const [showFontModal, setShowFontModal] = useState(false);
  const [showVerseActions, setShowVerseActions] = useState(false);
  const [showComparisonModal, setShowComparisonModal] = useState(false);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [showAIInsights, setShowAIInsights] = useState(false);
  const resumeTarget = bibleStore.resumeTarget;
  const [isPlanSetupVisible, setIsPlanSetupVisible] = useState(false);
  const [showCompactPlan, setShowCompactPlan] = useState(false);
  const [builderReminder, setBuilderReminder] = useState('');
  const [scopedView, setScopedView] = useState<ScopedViewState | null>(null);

  // Auto-hide header on scroll
  const scrollY = useRef(new Animated.Value(0)).current;
  const clampedY = useRef(Animated.diffClamp(scrollY, 0, 56)).current;
  const headerTranslateY = clampedY.interpolate({
    inputRange: [0, 56],
    outputRange: [0, -56],
  });

  const routeParams = route?.params ?? null;

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
  const scrollToVerse = useCallback((targetVerse?: number | string | null) => {
    if (targetVerse == null) return;

    const parsedTarget = typeof targetVerse === 'string' ? parseInt(targetVerse, 10) : targetVerse;
    if (!Number.isFinite(parsedTarget) || parsedTarget <= 0) return;

    if (!bibleStore.verses.length) {
      pendingScrollVerseRef.current = parsedTarget;
      return;
    }

    const verseIndex = bibleStore.verses.findIndex(v => {
      try {
        const { verse: verseNum } = parseVPLId(v.id);
        return verseNum === parsedTarget;
      } catch {
        const match = v.reference?.match(/:(\d+)$/);
        return match ? Number(match[1]) === parsedTarget : false;
      }
    });

    if (verseIndex === -1) {
      pendingScrollVerseRef.current = parsedTarget;
      return;
    }

    pendingScrollVerseRef.current = null;
    requestAnimationFrame(() => {
      try {
        verseListRef.current?.scrollToIndex({
          index: verseIndex,
          animated: true,
          viewPosition: 0.3,
        });
      } catch {
        const approximateRowHeight = 64;
        verseListRef.current?.scrollToOffset({
          offset: verseIndex * approximateRowHeight,
          animated: true,
        });
      }
    });
  }, [bibleStore.verses]);

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
      const foundBook = bibleBooks.find(b =>
        b.name.toLowerCase() === book.toLowerCase() ||
        b.abbreviation.toLowerCase() === book.toLowerCase()
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
      bibleStore.fetchVerses(bibleStore.currentBook, bibleStore.currentChapter, bibleStore.currentVersion, bibleStore.pagination.currentPage + 1);
    }
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

  const handleEnterPlanMode = useCallback(() => {
    if (!bibleStore.readingPlan) {
      return;
    }
    if (bibleStore.isPlanMode) {
      void bibleStore.focusPlanSegment();
      return;
    }
    bibleStore.enablePlanMode();
    void bibleStore.focusPlanSegment();
  }, [bibleStore]);

  const handleExitPlanMode = useCallback(() => {
    if (!bibleStore.isPlanMode) {
      void bibleStore.restoreBrowsePosition();
      return;
    }
    bibleStore.disablePlanMode();
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
      toast.success('Bible Studio plan ready');
      setBuilderReminder(reminderTime?.trim?.() ?? reminderTime ?? '');
      setIsPlanSetupVisible(false);
      bibleStore.enablePlanMode();
      void bibleStore.focusPlanSegment();
      journeyStore.setBiblePlan({
        id: bibleStore.readingPlan?.id ?? '',
        books,
        timePerDay,
        readingMode,
        phases,
        reminderTime: reminderTime ?? null,
      });
      void journeyStore.syncUserProgress();
      setShowCompactPlan(true);
      dailyPathStore.setReadingPlanSetupCompleted(true);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to create plan.';
      toast.error(message);
    }
  }, [bibleStore, dailyPathStore]);

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
  }, [bibleStore, builderReminder]);

  const handleClearPlan = useCallback(async () => {
    await bibleStore.clearReadingPlan();
    toast.success('Reading plan cleared');
    journeyStore.setBiblePlan(null);
  }, [bibleStore]);

  const handleToggleSegment = useCallback(async (segmentId: string) => {
    try {
      await bibleStore.togglePlanSegmentCompletion(segmentId);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (error) {
      console.error('Failed to update segment', error);
      toast.error('Unable to update segment progress.');
    }
  }, [bibleStore]);

  const renderPlanHeader = () => {
    if (scopedView) {
      console.log('[BibleScreen] renderPlanHeader suppressed due to scoped view');
      return null;
    }

    if (!bibleStore.isInitialized) {
      return null;
    }

    const readingPlan = bibleStore.readingPlan;
    const { completed, total } = bibleStore.readingPlanProgress;
    const progressPercent = total ? Math.round((completed / total) * 100) : 0;
    const upcoming = bibleStore.upcomingSegments;
    const [currentSegment, ...upcomingSegments] = upcoming;

    if (readingPlan && showCompactPlan) {
      return (
        <View style={styles.compactPlanBar}>
          <TouchableOpacity
            style={styles.compactPlanButton}
            onPress={() => setShowCompactPlan(false)}
          >
            <MaterialIcons name="auto-stories" size={18} color={theme.colors.text.inverse} />
            <Text style={styles.compactPlanText}>
              {completed}/{total} · {progressPercent}%
            </Text>
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <View style={styles.planContainer}>
        <Text style={styles.planTitle}>Bible Studio</Text>
        <Text style={styles.planSubtitle}>
          Shape a rhythm of Scripture that meets you today and keeps you growing.
        </Text>

        {readingPlan ? (
          <View style={styles.planCard}>
            <View style={styles.planCardHeader}>
              <View>
                <Text style={styles.planCardTitle}>Your current plan</Text>
                <Text style={styles.planCardSummary}>
                  {completed} of {total} sessions complete ({progressPercent}%)
                </Text>
              </View>
              <TouchableOpacity style={styles.planCompactToggle} onPress={() => setShowCompactPlan(true)}>
                <MaterialIcons name="fullscreen-exit" size={18} color={theme.colors.text.secondary} />
                <Text style={styles.planCompactToggleText}>Minimize</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.planClearButton} onPress={handleClearPlan}>
                <MaterialIcons name="delete-outline" size={18} color={theme.colors.error} />
                <Text style={styles.planClearButtonText}>Clear plan</Text>
              </TouchableOpacity>
            </View>

            {currentSegment && (
              <View style={styles.planActiveSegment}>
                <Text style={styles.planSectionTitle}>Today’s focus</Text>
                <TouchableOpacity
                  style={[styles.planSegmentChip, currentSegment.completedAt && styles.planSegmentCompleted]}
                  onPress={() => handleToggleSegment(currentSegment.id)}
                >
                  <MaterialIcons
                    name={currentSegment.completedAt ? 'check-circle' : 'radio-button-unchecked'}
                    size={18}
                    color={currentSegment.completedAt ? theme.colors.primary : theme.colors.text.secondary}
                  />
                  <Text style={styles.planSegmentText}>
                    {`${currentSegment.bookName} ${currentSegment.chapterStart}${currentSegment.chapterEnd !== currentSegment.chapterStart ? `-${currentSegment.chapterEnd}` : ''}`}
                  </Text>
                </TouchableOpacity>
              </View>
            )}

            {!!upcomingSegments.length && (
              <View style={styles.planUpcomingSection}>
                <Text style={styles.planSectionTitle}>Up next</Text>
                <View style={styles.planSegmentList}>
                  {upcomingSegments.map(segment => (
                    <TouchableOpacity
                      key={segment.id}
                      style={[styles.planSegmentChip, segment.completedAt && styles.planSegmentCompleted]}
                      onPress={() => handleToggleSegment(segment.id)}
                    >
                      <MaterialIcons
                        name={segment.completedAt ? 'check-circle' : 'radio-button-unchecked'}
                        size={18}
                        color={segment.completedAt ? theme.colors.primary : theme.colors.text.secondary}
                      />
                      <Text style={styles.planSegmentText}>
                        {`${segment.bookName} ${segment.chapterStart}${segment.chapterEnd !== segment.chapterStart ? `-${segment.chapterEnd}` : ''}`}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            )}

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

            <View style={styles.planFooterActions}>
              <TouchableOpacity style={styles.planSecondaryButton} onPress={handleEnterPlanMode}>
                <MaterialIcons name="play-arrow" size={18} color={theme.colors.primary} />
                <Text style={styles.planSecondaryButtonText}>Focus plan</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.planSecondaryButton} onPress={() => setIsPlanSetupVisible(true)}>
                <MaterialIcons name="edit" size={18} color={theme.colors.primary} />
                <Text style={styles.planSecondaryButtonText}>Adjust plan</Text>
              </TouchableOpacity>
            </View>
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

  const handleOpenSettings = useCallback(() => {
    setShowSettingsModal(true);
  }, []);

  const handleCloseSettings = useCallback(() => {
    setShowSettingsModal(false);
  }, []);

  const handleSettingsHistoryPress = useCallback(async () => {
    await bibleStore.loadHistory();
    setShowSettingsModal(false);
    setShowHistoryModal(true);
  }, [bibleStore]);

  const handleSettingsSearchPress = useCallback(() => {
    setShowSettingsModal(false);
    bibleStore.setShowSearch(true);
  }, [bibleStore]);

  const handleSettingsFontPress = useCallback(() => {
    setShowSettingsModal(false);
    setShowFontModal(true);
  }, []);

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
  const renderHeader = () => (
    <View style={styles.headerContainer}>
      <BlurView intensity={20} style={styles.header}>
        <View style={styles.headerLeft}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => setShowVersionsModal(true)}
          >
            <Text style={styles.headerButtonText}>
              Versions
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
            onPress={handleOpenSettings}
          >
            <MaterialIcons name="settings" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </BlurView>
    </View>
  );

  // Update version selection modal to use unique keys
  const renderVersionsModal = () => (
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

  const renderVersesList = () => (
    <FlatList
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
  );

  return (
    <View style={styles.container}>
      <Animated.View style={[styles.headerContainer, { transform: [{ translateY: headerTranslateY }] }]}>
        {renderHeader()}
      </Animated.View>

      {resumeTarget && (
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
          { useNativeDriver: true }
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

      {renderVersionsModal()}

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
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: theme.spacing.md,
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
    borderRadius: theme.borderRadius.sm,
    borderWidth: 1,
    borderColor: theme.colors.primary,
    backgroundColor: theme.colors.background,
  },
  planSecondaryButtonText: {
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
    borderColor: theme.colors.border,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.surface,
    gap: theme.spacing.sm,
  },
  aiSectionTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  aiSectionBody: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    lineHeight: 20,
  },
  aiModalPlaceholder: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.xl,
  },
});

export default observer(BibleScreen);