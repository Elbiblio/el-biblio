import React, { useCallback, useMemo } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { BlurView } from 'expo-blur';
import { MaterialIcons } from '@expo/vector-icons';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { Book, BibleVersion } from '@/types';
import BiblePicker from '@/components/BiblePicker';
import BookSelector from '@/components/BookSelector';
import { bibleBooks } from '@/constants/bibleBooks';
import { useBibleStore } from '@/stores/BibleStore';
import { TestamentFilter } from './types';
import { isNewTestamentAbbr } from './utils';
import { createBibleStyles } from './styles';

interface BibleHeaderProps {
  testamentFilter: TestamentFilter;
  onTestamentFilterChange: (filter: TestamentFilter) => void;
  onVersionsPress: () => void;
  onSearchPress: () => void;
  onHistoryPress: () => void;
  isOffline: boolean;
}

export const BibleHeader = observer(({
  testamentFilter,
  onTestamentFilterChange,
  onVersionsPress,
  onSearchPress,
  onHistoryPress,
  isOffline,
}: BibleHeaderProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const bibleStore = useBibleStore();

  const currentVersionLabel = useMemo(() => {
    const version = bibleStore.currentVersion;
    if (!version) return 'Versions';
    const candidate = (version as any).shortName ?? (version as any).code ?? version.englishName;
    return typeof candidate === 'string' && candidate.trim().length > 0 ? candidate : 'Versions';
  }, [bibleStore.currentVersion]);

  const handleInlineBookSelect = useCallback((book: Book) => {
    bibleStore.setCurrentBook(book as any);
  }, [bibleStore]);

  const handleInlineChapterSelect = useCallback((chapter: number) => {
    bibleStore.setCurrentChapter(chapter);
  }, [bibleStore]);

  const baseBooks = (bibleStore.filteredBooks as unknown as Book[]) || [];
  const selectorBooks =
    testamentFilter === 'all'
      ? baseBooks
      : baseBooks.filter(book =>
          testamentFilter === 'nt'
            ? isNewTestamentAbbr(book.abbreviation)
            : !isNewTestamentAbbr(book.abbreviation)
        );

  const currentBookForSelector =
    (bibleStore.currentBook as unknown as Book | null) ||
    selectorBooks[0] ||
    bibleBooks[0];

  return (
    <View style={styles.headerContainer}>
      <BlurView intensity={20} style={styles.header}>
        <View style={styles.headerLeft}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={onVersionsPress}
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
            <View style={styles.testamentToggle}>
              {(['all', 'ot', 'nt'] as const).map(key => (
                <TouchableOpacity
                  key={key}
                  style={[
                    styles.testamentOption,
                    testamentFilter === key && styles.testamentOptionActive,
                  ]}
                  onPress={() => {
                    if (key !== 'all') {
                      const nextBooks = baseBooks.filter(book =>
                        key === 'nt'
                          ? isNewTestamentAbbr(book.abbreviation)
                          : !isNewTestamentAbbr(book.abbreviation)
                      );
                      if (nextBooks.length > 0) {
                        const target = nextBooks[0];
                        bibleStore.setCurrentBook(target as any);
                        bibleStore.setCurrentChapter(1);
                      }
                    }
                    onTestamentFilterChange(key);
                  }}
                >
                  <Text
                    style={[
                      styles.testamentOptionText,
                      testamentFilter === key && styles.testamentOptionTextActive,
                    ]}
                  >
                    {key === 'all' ? 'All' : key === 'ot' ? 'OT' : 'NT'}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <BookSelector
              currentBook={currentBookForSelector}
              onSelect={handleInlineBookSelect}
              books={selectorBooks as any}
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
            onPress={onSearchPress}
          >
            <MaterialIcons name="search" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.iconButton}
            onPress={onHistoryPress}
            accessibilityLabel="Open history"
            accessibilityRole="button"
          >
            <MaterialIcons name="history" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </BlurView>
    </View>
  );
});
