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
  RefreshControl
} from 'react-native';
import { BlurView } from 'expo-blur';
import { MaterialIcons } from '@expo/vector-icons';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import BiblePicker from '@/components/BiblePicker';
import BookSelector from '@/components/BookSelector';
import HistoryModal, { HistoryModalEntry } from '@/components/HistoryModal';
import FontSizeModal from '@/components/FontSizeModal';
import VerseActionsSheet from '@/components/VerseActionsSheet';
import VerseComparisonModal from '@/components/VerseComparisonModal';
import { Book, BibleVersion, BibleVerse } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';
import { Brush, BrushOutlined } from '@/components/Icons';
import { useBibleStore, HistoryEntry } from '@/stores/BibleStore';

import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';
import EmptyState from '@/components/EmptyState';

const PLAN_PRESETS = [
  {
    id: 'gospels',
    label: 'Journey through the Gospels',
    books: ['Matthew', 'Mark', 'Luke', 'John'],
    description: 'Walk with Jesus across the four gospel accounts.',
  },
  {
    id: 'wisdom',
    label: 'Wisdom & Poetry',
    books: ['Psalms', 'Proverbs', 'Ecclesiastes'],
    description: 'Sit with songs, proverbs, and reflections for the heart.',
  },
  {
    id: 'acts-letters',
    label: 'Acts & Early Letters',
    books: ['Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians'],
    description: 'Follow the story of the early church and letters of Paul.',
  },
  {
    id: 'torah',
    label: 'Foundations (Torah)',
    books: ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy'],
    description: 'Trace God’s covenant story from creation to the promised land.',
  },
  {
    id: 'letters',
    label: 'Letters of Hope',
    books: ['Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians', 'James', '1 Peter'],
    description: 'Lean into letters that encourage perseverance and joy.',
  },
];

const CHAPTER_OPTIONS = [1, 2, 3, 4, 5];

interface BibleScreenProps {
  route?: { params?: { book?: string; chapter?: number; verse?: number } };
}

const BibleScreen = ({ route }: BibleScreenProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const verseListRef = useRef<FlatList>(null);

  // Network status
  const { isOffline } = useNetworkStatus();

  // Bible store
  const bibleStore = useBibleStore();

  // Local state for UI
  const [showVersionsModal, setShowVersionsModal] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [showFontModal, setShowFontModal] = useState(false);
  const [showVerseActions, setShowVerseActions] = useState(false);
  const [showComparisonModal, setShowComparisonModal] = useState(false);
  const [showPlanBookModal, setShowPlanBookModal] = useState(false);
  const resumeTarget = bibleStore.resumeTarget;

  const [selectedPresetIds, setSelectedPresetIds] = useState<string[]>([]);
  const [manualPlanBooks, setManualPlanBooks] = useState<string[]>([]);
  const builderBooks = useMemo(() => {
    const presetBooks = selectedPresetIds.flatMap(id => {
      const preset = PLAN_PRESETS.find(p => p.id === id);
      return preset ? preset.books : [];
    });
    const combined = new Set<string>([...presetBooks, ...manualPlanBooks]);
    return Array.from(combined);
  }, [selectedPresetIds, manualPlanBooks]);
  const [chaptersPerDayOption, setChaptersPerDayOption] = useState<number>(1);
  const [builderReminder, setBuilderReminder] = useState('');

  useEffect(() => {
    if (!bibleStore.readingPlan) {
      return;
    }
    setBuilderReminder(bibleStore.readingPlan.reminderTime ?? bibleStore.readingReminder?.time ?? '');
  }, [bibleStore.readingPlan, bibleStore.readingReminder?.time]);

  // Handle initial params (apply once and only if different)
  const appliedInitialParamsRef = useRef(false);
  useEffect(() => {
    if (appliedInitialParamsRef.current) return;
    if (!route?.params) return;

    const { book, chapter, verse } = route.params;
    if (!book) return;

    const foundBook = bibleBooks.find(b => 
      b.name.toLowerCase() === book.toLowerCase() || 
      b.abbreviation.toLowerCase() === book.toLowerCase()
    );
    if (!foundBook) return;

    const isSameBook = bibleStore.currentBook?.abbreviation === foundBook.abbreviation;
    const isSameChapter = chapter ? bibleStore.currentChapter === Math.min(chapter, foundBook.chapters) : true;
    if (isSameBook && isSameChapter) {
      appliedInitialParamsRef.current = true;
      return;
    }

    bibleStore.setCurrentBook(foundBook);
    if (chapter) {
      bibleStore.setCurrentChapter(Math.min(chapter, foundBook.chapters));
      if (verse) {
        setTimeout(() => {
          const verseIndex = bibleStore.verses.findIndex(v => {
            try {
              const { verse: verseNum } = parseVPLId(v.id);
              return verseNum === verse;
            } catch {
              return false;
            }
          });
          if (verseIndex !== -1) {
            verseListRef.current?.scrollToIndex({
              index: verseIndex,
              animated: true,
              viewPosition: 0.3
            });
          }
        }, 500);
      }
    }

    appliedInitialParamsRef.current = true;
  }, [route?.params, bibleStore.currentBook, bibleStore.currentChapter]);

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

  const handleTogglePreset = useCallback((presetId: string) => {
    setSelectedPresetIds(prev => {
      if (prev.includes(presetId)) {
        return prev.filter(id => id !== presetId);
      }
      return [...prev, presetId];
    });
  }, []);

  const handleAddManualBook = useCallback((bookName: string) => {
    setManualPlanBooks(prev => {
      if (prev.includes(bookName)) {
        return prev;
      }
      return [...prev, bookName];
    });
  }, []);

  const handleRemovePlanBook = useCallback((bookName: string) => {
    setManualPlanBooks(prev => prev.filter(book => book !== bookName));
    setSelectedPresetIds(prev => prev.filter(id => {
      const preset = PLAN_PRESETS.find(p => p.id === id);
      if (!preset) return true;
      return !preset.books.includes(bookName);
    }));
  }, []);

  const handleCreatePlan = useCallback(async () => {
    try {
      await bibleStore.createReadingPlan({
        books: builderBooks,
        chaptersPerDay: chaptersPerDayOption,
        reminderTime: builderReminder.trim() ? builderReminder.trim() : undefined,
      });
      toast.success('Bible Studio plan ready');
      setSelectedPresetIds([]);
      setManualPlanBooks([]);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to create plan.';
      toast.error(message);
    }
  }, [bibleStore, builderBooks, chaptersPerDayOption, builderReminder]);

  const handleApplyReminder = useCallback(async () => {
    try {
      await bibleStore.setReadingReminder(builderReminder.trim() || null);
      toast.success(builderReminder.trim() ? 'Reminder updated' : 'Reminder cleared');
    } catch (error) {
      console.error('Failed to update reminder', error);
      toast.error('Unable to update reminder.');
    }
  }, [bibleStore, builderReminder]);

  const handleClearPlan = useCallback(async () => {
    await bibleStore.clearReadingPlan();
    toast.success('Reading plan cleared');
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

  const renderPlanBookModal = () => (
    <Modal
      visible={showPlanBookModal}
      animationType="slide"
      onRequestClose={() => setShowPlanBookModal(false)}
    >
      <View style={styles.modalContainer}>
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Add books to your plan</Text>
          <TouchableOpacity onPress={() => setShowPlanBookModal(false)}>
            <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>

        <FlatList
          data={bibleBooks}
          keyExtractor={item => item.abbreviation}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.versionItem}
              onPress={() => {
                handleAddManualBook(item.name);
                setShowPlanBookModal(false);
              }}
            >
              <Text style={styles.versionName}>{item.name}</Text>
              <MaterialIcons
                name={manualPlanBooks.includes(item.name) ? 'check-circle' : 'add-circle-outline'}
                size={22}
                color={manualPlanBooks.includes(item.name) ? theme.colors.primary : theme.colors.text.secondary}
              />
            </TouchableOpacity>
          )}
        />
      </View>
    </Modal>
  );

  const renderPlanHeader = () => {
    if (!bibleStore.isInitialized) {
      return null;
    }

    const readingPlan = bibleStore.readingPlan;
    const { completed, total } = bibleStore.readingPlanProgress;
    const progressPercent = total ? Math.round((completed / total) * 100) : 0;
    const upcoming = bibleStore.upcomingSegments;
    const [currentSegment, ...upcomingSegments] = upcoming;

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
                <Text style={styles.planReminderHint}>Enter time in 24h format, e.g. 07:30</Text>
              </View>
              <View style={styles.planReminderControls}>
                <TextInput
                  value={builderReminder}
                  onChangeText={setBuilderReminder}
                  placeholder="HH:MM"
                  style={styles.planReminderInput}
                  keyboardType="numbers-and-punctuation"
                />
                <TouchableOpacity style={styles.planReminderButton} onPress={handleApplyReminder}>
                  <Text style={styles.planReminderButtonText}>Save</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        ) : (
          <View style={styles.planCard}>
            <Text style={styles.planCardTitle}>Start a new reading journey</Text>
            <Text style={styles.planCardSummary}>
              Choose a focus, decide how many chapters per day, and set an optional reminder.
            </Text>

            <View style={styles.planPresetList}>
              {PLAN_PRESETS.map(preset => {
                const active = selectedPresetIds.includes(preset.id);
                return (
                  <TouchableOpacity
                    key={preset.id}
                    style={[styles.planPresetItem, active && styles.planPresetItemActive]}
                    onPress={() => handleTogglePreset(preset.id)}
                  >
                    <View style={styles.planPresetHeader}>
                      <Text style={styles.planPresetTitle}>{preset.label}</Text>
                      <MaterialIcons
                        name={active ? 'check-circle' : 'add-circle-outline'}
                        size={20}
                        color={active ? theme.colors.primary : theme.colors.text.secondary}
                      />
                    </View>
                    <Text style={styles.planPresetDescription}>{preset.description}</Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            <View style={styles.planBooksRow}>
              <Text style={styles.planSectionTitle}>Selected books</Text>
              <TouchableOpacity onPress={() => setShowPlanBookModal(true)}>
                <Text style={styles.planActionLink}>Add books</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.planBookChips}>
              {builderBooks.length ? (
                builderBooks.map(book => (
                  <TouchableOpacity key={book} style={styles.planBookChip} onPress={() => handleRemovePlanBook(book)}>
                    <Text style={styles.planBookChipText}>{book}</Text>
                    <MaterialIcons name="close" size={16} color={theme.colors.text.secondary} />
                  </TouchableOpacity>
                ))
              ) : (
                <Text style={styles.planEmptyText}>No books selected yet.</Text>
              )}
            </View>

            <View style={styles.planControlsRow}>
              <View style={styles.planChaptersGroup}>
                <Text style={styles.planSectionTitle}>Chapters per day</Text>
                <View style={styles.planChaptersOptions}>
                  {CHAPTER_OPTIONS.map(option => (
                    <TouchableOpacity
                      key={option}
                      style={[styles.planChapterOption, chaptersPerDayOption === option && styles.planChapterOptionActive]}
                      onPress={() => setChaptersPerDayOption(option)}
                    >
                      <Text style={styles.planChapterOptionText}>{option}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>

              <View style={styles.planReminderInline}>
                <Text style={styles.planSectionTitle}>Reminder (optional)</Text>
                <TextInput
                  value={builderReminder}
                  onChangeText={setBuilderReminder}
                  placeholder="HH:MM"
                  style={styles.planReminderInput}
                  keyboardType="numbers-and-punctuation"
                />
              </View>
            </View>

            <TouchableOpacity
              style={[styles.planPrimaryButton, (!builderBooks.length) && styles.planPrimaryButtonDisabled]}
              onPress={handleCreatePlan}
              disabled={!builderBooks.length}
            >
              <Text style={styles.planPrimaryButtonText}>Create plan</Text>
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
              Bible Studio
            </Text>
            <MaterialIcons name="menu-book" size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>
          
          {isOffline && (
            <View style={styles.offlineIndicator}>
              <MaterialIcons name="wifi-off" size={12} color={theme.colors.warning} />
              <Text style={styles.offlineText}>Offline</Text>
            </View>
          )}

          <View style={styles.controlsGroup}>
            <BookSelector
              currentBook={bibleStore.currentBook || (bibleStore.availableBooks[0] as any) || bibleBooks[0]}
              onSelect={bibleStore.setCurrentBook}
              books={(bibleStore.availableBooks.length ? bibleStore.availableBooks : bibleBooks) as any}
            />
            
            <BiblePicker
              value={bibleStore.currentChapter}
              items={Array.from({ length: bibleStore.getChapterCount() }, (_, i) => i + 1)}
              onSelect={bibleStore.setCurrentChapter}
            />
          </View>
        </View>

        <View style={styles.headerRight}>
          <TouchableOpacity
            style={styles.iconButton}
            onPress={async () => {
              await bibleStore.loadHistory();
              setShowHistoryModal(true);
            }}
          >
            <MaterialIcons name="history" size={22} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.iconButton}
            onPress={() => bibleStore.setShowSearch(true)}
          >
            <MaterialIcons name="search" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.iconButton}
            onPress={() => setShowFontModal(true)}
          >
            <MaterialIcons name="text-fields" size={22} color={theme.colors.text.primary} />
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

  return (
    <View style={styles.container}>
      {renderPlanBookModal()}
      <View style={styles.headerContainer}>
        {renderHeader()}
      </View>

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
  controlsGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
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
});

export default observer(BibleScreen);