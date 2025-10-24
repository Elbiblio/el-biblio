import React, { useState, useCallback, useMemo } from 'react';
import { View, Text, Modal, TouchableOpacity, StyleSheet, ScrollView, TextInput } from 'react-native';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { bibleBooks } from '@/constants/bibleBooks';
import { Check, X } from '@/components/Icons';

type ReadingPlanPreset = {
  id: string;
  label: string;
  books: string[];
  description: string;
};

const PLAN_PRESETS: ReadingPlanPreset[] = [
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
];

interface ReadingPlanSetupModalProps {
  visible: boolean;
  onClose: () => void;
  onCreatePlan: (options: { books: string[]; chaptersPerDay: number; reminderTime?: string }) => Promise<void>;
}

const ReadingPlanSetupModal: React.FC<ReadingPlanSetupModalProps> = observer(({ visible, onClose, onCreatePlan }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  
  const [selectedPresetIds, setSelectedPresetIds] = useState<string[]>([]);
  const [manualPlanBooks, setManualPlanBooks] = useState<string[]>([]);
  const [chaptersPerDay, setChaptersPerDay] = useState(1);
  const [reminderTime, setReminderTime] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  const builderBooks = useMemo(() => {
    const presetBooks = selectedPresetIds.flatMap(id => {
      const preset = PLAN_PRESETS.find(p => p.id === id);
      return preset ? preset.books : [];
    });
    const combined = new Set<string>([...presetBooks, ...manualPlanBooks]);
    return Array.from(combined);
  }, [selectedPresetIds, manualPlanBooks]);

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
        chaptersPerDay,
        reminderTime: reminderTime.trim() || undefined,
      });
      onClose();
    } finally {
      setIsCreating(false);
    }
  }, [builderBooks, chaptersPerDay, reminderTime, onCreatePlan, onClose]);

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
            <Text style={styles.title}>Create Reading Plan</Text>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <X size={24} color={theme.colors.text.primary} />
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.content}>
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Quick Start</Text>
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
                    <Text style={styles.presetButtonText}>{preset.label}</Text>
                    {selectedPresetIds.includes(preset.id) && (
                      <Check size={16} color={theme.colors.primary} style={styles.checkIcon} />
                    )}
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Selected Books ({builderBooks.length})</Text>
              <View style={styles.booksContainer}>
                {builderBooks.length === 0 ? (
                  <Text style={styles.emptyText}>Select books or choose a preset above</Text>
                ) : (
                  <View style={styles.booksGrid}>
                    {builderBooks.map(book => (
                      <View key={book} style={styles.bookTag}>
                        <Text style={styles.bookTagText}>{book}</Text>
                        <TouchableOpacity 
                          onPress={() => handleRemoveBook(book)}
                          style={styles.removeBookButton}
                        >
                          <X size={14} color={theme.colors.text.secondary} />
                        </TouchableOpacity>
                      </View>
                    ))}
                  </View>
                )}
              </View>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Reading Pace</Text>
              <Text style={styles.label}>Chapters per day: {chaptersPerDay}</Text>
              <View style={styles.paceSliderContainer}>
                {[1, 2, 3, 4, 5].map(num => (
                  <TouchableOpacity
                    key={num}
                    style={[
                      styles.paceButton,
                      chaptersPerDay === num && styles.paceButtonActive
                    ]}
                    onPress={() => setChaptersPerDay(num)}
                  >
                    <Text style={[
                      styles.paceButtonText,
                      chaptersPerDay === num && styles.paceButtonTextActive
                    ]}>
                      {num}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Daily Reminder (Optional)</Text>
              <TextInput
                style={styles.input}
                value={reminderTime}
                onChangeText={setReminderTime}
                placeholder="e.g., 8:00 AM"
                placeholderTextColor={theme.colors.text.secondary}
              />
            </View>
          </ScrollView>

          <View style={styles.footer}>
            <TouchableOpacity
              style={[
                styles.createButton,
                (builderBooks.length === 0 || isCreating) && styles.createButtonDisabled
              ]}
              onPress={handleCreate}
              disabled={builderBooks.length === 0 || isCreating}
            >
              <Text style={styles.createButtonText}>
                {isCreating ? 'Creating...' : 'Create Plan'}
              </Text>
            </TouchableOpacity>
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
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginHorizontal: -4,
  },
  presetButton: {
    borderWidth: 1,
    borderColor: theme.colors.border,
    borderRadius: 8,
    padding: 12,
    margin: 4,
    flex: 1,
    minWidth: '45%',
    flexDirection: 'row',
    alignItems: 'center',
  },
  presetButtonSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}10`,
  },
  presetButtonText: {
    ...theme.typography.body2,
    color: theme.colors.text.primary,
    flex: 1,
  },
  checkIcon: {
    marginLeft: 8,
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
  paceSliderContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  paceButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  paceButtonActive: {
    backgroundColor: theme.colors.primary,
    borderColor: theme.colors.primary,
  },
  paceButtonText: {
    ...theme.typography.body1,
    color: theme.colors.text.primary,
  },
  paceButtonTextActive: {
    color: theme.colors.text.inverse,
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
});

export default ReadingPlanSetupModal;
