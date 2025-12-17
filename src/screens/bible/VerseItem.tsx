import React, { useCallback, useMemo } from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { BibleVerse } from '@/types';
import { useBibleStore } from '@/stores/BibleStore';
import { parseVPLId } from '@/utils/database';
import { createBibleStyles } from './styles';

interface VerseItemProps {
  verse: BibleVerse;
  onPress: (verseId: string) => void;
  onLongPress: (verseId: string) => void;
}

export const VerseItem = observer(({ verse, onPress, onLongPress }: VerseItemProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const bibleStore = useBibleStore();

  let verseNum = 0;
  try {
    verseNum = parseVPLId(verse.id).verse;
  } catch {
    const match = verse.reference?.match(/:(\d+)$/);
    verseNum = match ? parseInt(match[1], 10) : 0;
  }

  const isHighlighted = bibleStore.highlightedVerses.has(verse.id);
  const isBookmarked = bibleStore.bookmarkedVerses.has(verse.id);
  const isLiked = bibleStore.likedVerses.has(verse.id);

  return (
    <View style={[styles.verseContainer, isHighlighted && styles.highlightedVerse]}>
      <TouchableOpacity
        style={styles.verseContent}
        onLongPress={() => onLongPress(verse.id)}
        onPress={() => onPress(verse.id)}
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

        <Text style={styles.verseNumber}>{verseNum}</Text>
        <Text style={[styles.verseText, { fontSize: bibleStore.fontSize }]}>
          {verse.text}
        </Text>
      </TouchableOpacity>
    </View>
  );
});
