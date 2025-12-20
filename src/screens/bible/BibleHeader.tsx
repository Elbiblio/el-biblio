import React, { useCallback, useMemo, useState, useRef } from 'react';
import { View, Text, TouchableOpacity, Modal, Dimensions } from 'react-native';
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
  const [showMoreMenu, setShowMoreMenu] = useState(false);
  const [menuPosition, setMenuPosition] = useState({ x: 0, y: 0 });
  const moreButtonRef = useRef<View>(null);
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

  const openMoreMenu = useCallback(() => {
    moreButtonRef.current?.measure((x, y, width, height, pageX, pageY) => {
      const screenWidth = Dimensions.get('window').width;
      const menuWidth = 160;
      const menuHeight = 100;
      
      // Position menu below the button, aligned to the right edge
      let menuX = pageX + width - menuWidth;
      let menuY = pageY + height + 8;
      
      // Ensure menu doesn't go off screen edges
      if (menuX < theme.spacing.md) {
        menuX = theme.spacing.md;
      }
      if (menuX + menuWidth > screenWidth - theme.spacing.md) {
        menuX = screenWidth - menuWidth - theme.spacing.md;
      }
      
      setMenuPosition({ x: menuX, y: menuY });
      setShowMoreMenu(true);
    });
  }, [theme.spacing.md]);

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
            <TouchableOpacity
              style={styles.testamentToggle}
              onPress={() => {
                const next = testamentFilter === 'all' ? 'ot' : testamentFilter === 'ot' ? 'nt' : 'all';
                if (next !== 'all') {
                  const nextBooks = baseBooks.filter(book =>
                    next === 'nt'
                      ? isNewTestamentAbbr(book.abbreviation)
                      : !isNewTestamentAbbr(book.abbreviation)
                  );
                  if (nextBooks.length > 0) {
                    const target = nextBooks[0];
                    bibleStore.setCurrentBook(target as any);
                    bibleStore.setCurrentChapter(1);
                  }
                }
                onTestamentFilterChange(next);
              }}
            >
              <Text style={styles.testamentOptionText}>
                {testamentFilter === 'all' ? 'All' : testamentFilter === 'ot' ? 'OT' : 'NT'}
              </Text>
            </TouchableOpacity>

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
            ref={moreButtonRef}
            style={styles.iconButton}
            onPress={openMoreMenu}
            accessibilityLabel="More options"
            accessibilityRole="button"
          >
            <MaterialIcons name="more-vert" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </BlurView>

      <Modal
        visible={showMoreMenu}
        transparent
        animationType="fade"
        onRequestClose={() => setShowMoreMenu(false)}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setShowMoreMenu(false)}
        >
          <View style={[
            styles.moreMenu,
            {
              backgroundColor: theme.colors.surface,
              position: 'absolute',
              left: menuPosition.x,
              top: menuPosition.y,
            }
          ]}>
            <TouchableOpacity
              style={styles.moreMenuItem}
              onPress={() => {
                setShowMoreMenu(false);
                onSearchPress();
              }}
            >
              <MaterialIcons name="search" size={20} color={theme.colors.text.primary} />
              <Text style={styles.moreMenuItemText}>Search</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.moreMenuItem}
              onPress={() => {
                setShowMoreMenu(false);
                onHistoryPress();
              }}
            >
              <MaterialIcons name="history" size={20} color={theme.colors.text.primary} />
              <Text style={styles.moreMenuItemText}>History</Text>
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Modal>
    </View>
  );
});
