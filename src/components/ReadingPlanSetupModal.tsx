import React, { useState, useCallback, useMemo } from 'react';
import { View, Text, Modal, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { bibleBooks } from '@/constants/bibleBooks';
import { Check, X } from '@/components/Icons';
import {
  TIME_OPTIONS,
  READING_MODE_OPTIONS,
  DEFAULT_TIME_PER_DAY,
  DEFAULT_READING_MODE,
  buildPlanPhases,
  getModeSummaryLines,
  estimateChaptersPerDay,
  getReadingMinutes,
  ReadingPlanMode,
  ReadingPlanPhase,
} from '@/constants/readingPlanModes';
import { MaterialIcons } from '@expo/vector-icons';
import ReminderTimePicker from '@/components/ReminderTimePicker';
import { PLAN_PRESETS, getVirtueFocusFromPresets } from '@/constants/readingPlanPresets';

interface ReadingPlanSetupModalProps {
  visible: boolean;
  onClose: () => void;
  onCreatePlan: (options: {
    books: string[];
    timePerDay: number;
    readingMode: ReadingPlanMode;
    phases: ReadingPlanPhase[];
    reminderTime?: string;
    presetIds?: string[];
  }) => Promise<void>;
}

const ReadingPlanSetupModal: React.FC<ReadingPlanSetupModalProps> = observer(({ visible, onClose, onCreatePlan }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  
  const [selectedPresetIds, setSelectedPresetIds] = useState<string[]>([]);
  const [manualPlanBooks, setManualPlanBooks] = useState<string[]>([]);
  const [timePerDay, setTimePerDay] = useState(DEFAULT_TIME_PER_DAY);
  const [readingMode, setReadingMode] = useState<ReadingPlanMode>(DEFAULT_READING_MODE);
  const [reminderTime, setReminderTime] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const [currentStep, setCurrentStep] = useState<'books' | 'time' | 'mode' | 'reminder' | 'summary'>('books');

  const builderBooks = useMemo(() => {
    const presetBooks = selectedPresetIds.flatMap(id => {
      const preset = PLAN_PRESETS.find(p => p.id === id);
      return preset ? preset.books : [];
    });
    const combined = new Set<string>([...presetBooks, ...manualPlanBooks]);
    return Array.from(combined);
  }, [selectedPresetIds, manualPlanBooks]);

  const sessionPhases = useMemo(
    () => buildPlanPhases(readingMode, timePerDay),
    [readingMode, timePerDay]
  );

  const phaseSummaryLines = useMemo(
    () => getModeSummaryLines(readingMode, timePerDay),
    [readingMode, timePerDay]
  );

  const focusVirtue = useMemo(
    () => getVirtueFocusFromPresets(selectedPresetIds),
    [selectedPresetIds]
  );

  const estimatedChaptersPerDay = useMemo(
    () => estimateChaptersPerDay(timePerDay),
    [timePerDay]
  );

  const selectedMode = useMemo(
    () => READING_MODE_OPTIONS.find(option => option.id === readingMode) ?? READING_MODE_OPTIONS[0],
    [readingMode]
  );

  const totalChapters = useMemo(() => {
    if (!builderBooks.length) {
      return 0;
    }
    return builderBooks.reduce((sum, bookName) => {
      const meta = bibleBooks.find(book => book.name === bookName);
      return sum + (meta?.chapters ?? 0);
    }, 0);
  }, [builderBooks]);

  const AVERAGE_WORDS_PER_CHAPTER = 780;
  const AVERAGE_READING_SPEED_WPM = 180;

  const totalEstimatedWords = useMemo(() => totalChapters * AVERAGE_WORDS_PER_CHAPTER, [totalChapters]);

  const readingMinutesPerDay = useMemo(
    () => getReadingMinutes(readingMode, timePerDay),
    [readingMode, timePerDay]
  );

  const wordsPerDay = useMemo(() => readingMinutesPerDay * AVERAGE_READING_SPEED_WPM, [readingMinutesPerDay]);

  const estimatedDaysToComplete = useMemo(() => {
    if (!builderBooks.length || wordsPerDay <= 0 || totalEstimatedWords <= 0) {
      return null;
    }
    return Math.max(1, Math.ceil(totalEstimatedWords / wordsPerDay));
  }, [builderBooks.length, totalEstimatedWords, wordsPerDay]);

  const estimatedWeeksToComplete = useMemo(() => {
    if (!estimatedDaysToComplete) {
      return null;
    }
    return Math.max(1, Math.ceil(estimatedDaysToComplete / 7));
  }, [estimatedDaysToComplete]);

  const formatNumber = useCallback((value: number) => value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ','), []);

  const handleTogglePreset = useCallback((presetId: string) => {
    setSelectedPresetIds(prev => 
      prev.includes(presetId) 
        ? prev.filter(id => id !== presetId)
        : [...prev, presetId]
    );
  }, []);

  const handleAddManualBook = useCallback((bookName: string) => {
    setManualPlanBooks(prev => 
      prev.includes(bookName) ? prev : [...prev, bookName]
    );
  }, []);

  const handleRemoveBook = useCallback((bookName: string) => {
    setManualPlanBooks(prev => prev.filter(book => book !== bookName));
    setSelectedPresetIds(prev => prev.filter(id => {
      const preset = PLAN_PRESETS.find(p => p.id === id);
      return !preset?.books.includes(bookName);
    }));
  }, []);

  const handleCreate = useCallback(async () => {
    if (builderBooks.length === 0) {
      return;
    }
    
    try {
      setIsCreating(true);
      await onCreatePlan({
        books: builderBooks,
        timePerDay,
        readingMode,
        phases: sessionPhases,
        reminderTime: reminderTime.trim() || undefined,
        presetIds: selectedPresetIds,
      });
      onClose();
      // Reset state
      setCurrentStep('books');
      setSelectedPresetIds([]);
      setManualPlanBooks([]);
      setTimePerDay(DEFAULT_TIME_PER_DAY);
      setReadingMode(DEFAULT_READING_MODE);
      setReminderTime('');
    } finally {
      setIsCreating(false);
    }
  }, [builderBooks, timePerDay, readingMode, sessionPhases, reminderTime, onCreatePlan, onClose]);

  const handleNext = useCallback(() => {
    if (currentStep === 'books' && builderBooks.length > 0) {
      setCurrentStep('time');
    } else if (currentStep === 'time') {
      setCurrentStep('mode');
    } else if (currentStep === 'mode') {
      setCurrentStep('reminder');
    } else if (currentStep === 'reminder') {
      setCurrentStep('summary');
    }
  }, [currentStep, builderBooks.length]);

  const handleBack = useCallback(() => {
    if (currentStep === 'time') {
      setCurrentStep('books');
    } else if (currentStep === 'mode') {
      setCurrentStep('time');
    } else if (currentStep === 'reminder') {
      setCurrentStep('mode');
    } else if (currentStep === 'summary') {
      setCurrentStep('reminder');
    }
  }, [currentStep]);

  const handleClose = useCallback(() => {
    setCurrentStep('books');
    onClose();
  }, [onClose]);

  if (!visible) return null;

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            {currentStep !== 'books' && (
              <TouchableOpacity onPress={handleBack} style={styles.backButton}>
                <MaterialIcons name="arrow-back" size={24} color={theme.colors.text.primary} />
              </TouchableOpacity>
            )}
            <Text style={styles.title}>
              {currentStep === 'books' && 'Choose Your Focus'}
              {currentStep === 'time' && 'Daily Time'}
              {currentStep === 'mode' && 'Reading Experience'}
              {currentStep === 'reminder' && 'Set Reminder'}
              {currentStep === 'summary' && 'Review Your Plan'}
            </Text>
            <TouchableOpacity onPress={handleClose} style={styles.closeButton}>
              <X size={24} color={theme.colors.text.primary} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.content}>
            {currentStep === 'books' && (
              <View style={styles.section}>
                <Text style={styles.sectionSubtitle}>Select one or more themes to guide your reading journey</Text>
                <View style={styles.presetContainer}>
                  {PLAN_PRESETS.map(preset => (
                    <TouchableOpacity
                      key={preset.id}
                      style={[
                        styles.presetButton,
                        selectedPresetIds.includes(preset.id) && styles.presetButtonSelected
                      ]}
                      onPress={() => handleTogglePreset(preset.id)}
                    >
                      <View style={styles.presetContent}>
                        <Text style={[
                          styles.presetButtonText,
                          selectedPresetIds.includes(preset.id) && styles.presetButtonTextSelected
                        ]}>
                          {preset.label}
                        </Text>
                        <Text style={styles.presetDescription}>{preset.description}</Text>
                      </View>
                      {selectedPresetIds.includes(preset.id) && (
                        <Check size={20} color={theme.colors.primary} style={styles.checkIcon} />
                      )}
                    </TouchableOpacity>
                  ))}
                </View>

                {builderBooks.length > 0 && (
                  <View style={styles.selectedBooksPreview}>
                    <Text style={styles.selectedBooksCount}>
                      {builderBooks.length} {builderBooks.length === 1 ? 'book' : 'books'} • {totalChapters} chapters
                    </Text>
                  </View>
                )}
              </View>
            )}

            {currentStep === 'time' && (
              <View style={styles.section}>
                <Text style={styles.sectionSubtitle}>How much time can you dedicate each day?</Text>
                <View style={styles.timeOptionsRow}>
                  {TIME_OPTIONS.map(minutes => {
                    const isActive = minutes === timePerDay;
                    return (
                      <TouchableOpacity
                        key={minutes}
                        style={[styles.timeOption, isActive && styles.timeOptionActive]}
                        onPress={() => setTimePerDay(minutes)}
                      >
                        <Text style={[styles.timeOptionText, isActive && styles.timeOptionTextActive]}>
                          {minutes}
                        </Text>
                        <Text style={[styles.timeOptionLabel, isActive && styles.timeOptionLabelActive]}>
                          mins
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
                <Text style={styles.helperHint}>
                  Estimated {estimatedChaptersPerDay} {estimatedChaptersPerDay === 1 ? 'chapter' : 'chapters'} per day
                </Text>
              </View>
            )}

            {currentStep === 'mode' && (
              <View style={styles.section}>
                <Text style={styles.sectionSubtitle}>Choose how you'd like to engage with Scripture</Text>
                <View style={styles.readingModeList}>
                  {READING_MODE_OPTIONS.map(option => {
                    const isActive = option.id === readingMode;
                    return (
                      <TouchableOpacity
                        key={option.id}
                        style={[styles.modeCard, isActive && styles.modeCardActive]}
                        onPress={() => setReadingMode(option.id)}
                      >
                        <View style={styles.modeCardHeader}>
                          <Text style={[styles.modeCardTitle, isActive && styles.modeCardTitleActive]}>
                            {option.label}
                          </Text>
                          {isActive && <Check size={20} color={theme.colors.primary} />}
                        </View>
                        <Text style={[styles.modeCardDescription, isActive && styles.modeCardDescriptionActive]}>
                          {option.description}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {currentStep === 'reminder' && (
              <View style={styles.section}>
                <Text style={styles.sectionSubtitle}>Set a daily reminder to stay consistent (optional)</Text>
                <ReminderTimePicker
                  value={reminderTime || null}
                  onChange={next => setReminderTime(next ?? '')}
                  placeholder="Choose a time"
                  helperText="We'll send you a gentle nudge at this time each day"
                />
              </View>
            )}

            {currentStep === 'summary' && (
              <View style={styles.summaryContainer}>
                <View style={styles.summarySection}>
                  <Text style={styles.summarySectionTitle}>📖 Your Reading Plan</Text>
                  <View style={styles.summaryCard}>
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Books</Text>
                      <Text style={styles.summaryValue}>{builderBooks.length}</Text>
                    </View>
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Chapters</Text>
                      <Text style={styles.summaryValue}>{totalChapters}</Text>
                    </View>
                    <View style={styles.summaryRow}>
                      <Text style={styles.summaryLabel}>Daily time</Text>
                      <Text style={styles.summaryValue}>{timePerDay} mins</Text>
                    </View>
                    {estimatedDaysToComplete && (
                      <View style={styles.summaryRow}>
                        <Text style={styles.summaryLabel}>Duration</Text>
                        <Text style={styles.summaryValue}>
                          ~{estimatedDaysToComplete} {estimatedDaysToComplete === 1 ? 'day' : 'days'}
                        </Text>
                      </View>
                    )}
                    {focusVirtue && (
                      <View style={styles.summaryRow}>
                        <Text style={styles.summaryLabel}>Focus virtue</Text>
                        <Text style={styles.summaryValue}>{focusVirtue.displayLabel}</Text>
                      </View>
                    )}
                  </View>
                </View>

                <View style={styles.summarySection}>
                  <Text style={styles.summarySectionTitle}>📚 Selected Books</Text>
                  <View style={styles.booksGrid}>
                    {builderBooks.map(book => (
                      <View key={book} style={styles.summaryBookTag}>
                        <Text style={styles.summaryBookText}>{book}</Text>
                      </View>
                    ))}
                  </View>
                </View>

                <View style={styles.summarySection}>
                  <Text style={styles.summarySectionTitle}>🕊️ Daily Flow</Text>
                  <View style={styles.summaryCard}>
                    {phaseSummaryLines.map(line => (
                      <Text key={line} style={styles.summaryFlowText}>
                        • {line}
                      </Text>
                    ))}
                  </View>
                </View>

                {reminderTime && (
                  <View style={styles.summarySection}>
                    <Text style={styles.summarySectionTitle}>⏰ Reminder</Text>
                    <View style={styles.summaryCard}>
                      <Text style={styles.summaryValue}>{reminderTime}</Text>
                    </View>
                  </View>
                )}
              </View>
            )}
          </ScrollView>

          <View style={styles.footer}>
            {currentStep === 'summary' ? (
              <TouchableOpacity
                style={[styles.createButton, isCreating && styles.createButtonDisabled]}
                onPress={handleCreate}
                disabled={isCreating}
              >
                <Text style={styles.createButtonText}>
                  {isCreating ? 'Creating...' : 'Start My Plan'}
                </Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity
                style={[
                  styles.createButton,
                  (currentStep === 'books' && builderBooks.length === 0) && styles.createButtonDisabled
                ]}
                onPress={handleNext}
                disabled={currentStep === 'books' && builderBooks.length === 0}
              >
                <Text style={styles.createButtonText}>Continue</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      </View>
    </Modal>
  );
});

const createStyles = (theme: any) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    padding: 20,
  },
  container: {
    backgroundColor: theme.colors.background,
    borderRadius: 12,
    maxHeight: '90%',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  title: {
    ...theme.typography.h6,
    color: theme.colors.text.primary,
  },
  closeButton: {
    padding: 4,
  },
  content: {
    padding: 16,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    ...theme.typography.subtitle2,
    color: theme.colors.text.primary,
    marginBottom: 12,
  },
  label: {
    ...theme.typography.body2,
    color: theme.colors.text.secondary,
    marginTop: 4,
    marginBottom: 8,
  },
  presetContainer: {
    gap: 12,
  },
  presetButton: {
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
  },
  presetButtonSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
    borderWidth: 2,
  },
  presetContent: {
    flex: 1,
  },
  presetButtonText: {
    ...theme.typography.subtitle2,
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  presetButtonTextSelected: {
    color: theme.colors.primary,
  },
  presetDescription: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    lineHeight: 16,
  },
  checkIcon: {
    marginLeft: 8,
  },
  selectedBooksPreview: {
    marginTop: 16,
    padding: 12,
    backgroundColor: theme.colors.surfaceVariant,
    borderRadius: 8,
    gap: 4,
  },
  selectedBooksCount: {
    ...theme.typography.body2,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  estimatePreview: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
  },
  advancedToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 12,
    paddingHorizontal: 16,
    marginBottom: 16,
    borderRadius: 8,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  advancedToggleText: {
    ...theme.typography.button,
    color: theme.colors.text.secondary,
  },
  booksContainer: {
    minHeight: 100,
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 8,
    padding: 12,
  },
  emptyText: {
    ...theme.typography.body2,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: 16,
  },
  booksGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    margin: -4,
  },
  bookTag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
    borderRadius: 16,
    paddingVertical: 4,
    paddingHorizontal: 12,
    margin: 4,
  },
  bookTagText: {
    ...theme.typography.caption,
    color: theme.colors.text.primary,
  },
  removeBookButton: {
    marginLeft: 4,
    padding: 2,
  },
  readingModeList: {
    gap: 12,
    marginTop: 12,
  },
  modeSummaryCard: {
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 12,
    padding: 16,
    backgroundColor: theme.colors.surface,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 16,
  },
  modeSummaryCardActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  modeSummaryText: {
    flex: 1,
    gap: 4,
  },
  modeSummaryTitle: {
    ...theme.typography.subtitle2,
    color: theme.colors.text.primary,
  },
  modeSummaryDescription: {
    ...theme.typography.body2,
    color: theme.colors.text.secondary,
  },
  modeCard: {
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 12,
    padding: 16,
    backgroundColor: theme.colors.surface,
  },
  modeCardActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  modeCardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  modeCardTitle: {
    ...theme.typography.subtitle2,
    color: theme.colors.text.primary,
  },
  modeCardTitleActive: {
    color: theme.colors.primary,
  },
  modeCardDescription: {
    ...theme.typography.body2,
    color: theme.colors.text.secondary,
  },
  modeCardDescriptionActive: {
    color: theme.colors.text.primary,
  },
  timeOptionsRow: {
    flexDirection: 'row',
    gap: 8,
  },
  timeOption: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: theme.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.surface,
  },
  timeOptionActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
    borderWidth: 2,
  },
  timeOptionText: {
    ...theme.typography.body2,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  timeOptionTextActive: {
    color: theme.colors.primary,
  },
  secondaryHint: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    marginTop: 8,
  },
  sessionSummaryCard: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surfaceVariant,
    padding: 16,
    gap: 8,
  },
  sessionSummaryLine: {
    ...theme.typography.body2,
    color: theme.colors.text.primary,
  },
  sessionEstimateBox: {
    marginTop: 12,
    gap: 4,
  },
  sessionEstimateText: {
    ...theme.typography.body2,
    color: theme.colors.text.primary,
  },
  sessionEstimateHint: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
  },
  input: {
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 8,
    padding: 12,
    color: theme.colors.text.primary,
    ...theme.typography.body1,
  },
  footer: {
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
  },
  createButton: {
    backgroundColor: theme.colors.primary,
    borderRadius: 8,
    padding: 16,
    alignItems: 'center',
  },
  createButtonDisabled: {
    opacity: 0.5,
  },
  createButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  },
  backButton: {
    padding: 4,
    marginRight: 8,
  },
  sectionSubtitle: {
    ...theme.typography.body2,
    color: theme.colors.text.secondary,
    marginBottom: 20,
    lineHeight: 20,
  },
  timeOptionLabel: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  timeOptionLabelActive: {
    color: theme.colors.primary,
  },
  helperHint: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    marginTop: 12,
    textAlign: 'center',
  },
  summaryContainer: {
    gap: 24,
    paddingBottom: 48
  },
  summarySection: {
    gap: 12,
  },
  summarySectionTitle: {
    ...theme.typography.subtitle1,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  summaryCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  summaryLabel: {
    ...theme.typography.body2,
    color: theme.colors.text.secondary,
  },
  summaryValue: {
    ...theme.typography.body1,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  summaryBookTag: {
    backgroundColor: theme.colors.surfaceVariant,
    borderRadius: 16,
    paddingVertical: 6,
    paddingHorizontal: 12,
    margin: 4,
  },
  summaryBookText: {
    ...theme.typography.caption,
    color: theme.colors.text.primary,
    fontWeight: '500',
  },
  summaryFlowText: {
    ...theme.typography.body2,
    color: theme.colors.text.primary,
    lineHeight: 20,
  },
});

export default ReadingPlanSetupModal;