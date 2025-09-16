import { useTheme } from '@/contexts/ThemeContext';
import { type Note } from '@/types';
import { BlurView } from 'expo-blur';
import React from 'react';
import { Text, View, StyleSheet } from 'react-native';
import { TouchableOpacity } from 'react-native-gesture-handler';
import { Sparkle } from './Icons';

const NoteCard = ({ note, isGridView, onPress, styles }: {
  note: Note;
  isGridView: boolean;
  onPress: (note: Note) => void;
  styles: StyleSheet.NamedStyles<any>;
}) => {
  const theme = useTheme();

  return (
    <TouchableOpacity
      key={note.id}
      style={[
        styles.noteCard,
        isGridView ? styles.gridCard : styles.listCard,
        { backgroundColor: note.color || theme.colors.surface }
      ]}
      onPress={() => onPress(note)}
      activeOpacity={0.7}
    >
      <BlurView intensity={10} style={StyleSheet.absoluteFill} />
      <View style={styles.noteContent}>
        {note.isPinned && (
          <View style={styles.pinnedBadge}>
            <Sparkle size={12} color={theme.colors.primary} />
            <Text style={styles.pinnedText}>Pinned</Text>
          </View>
        )}

        <Text style={styles.noteTitle} numberOfLines={1}>
          {note.title}
        </Text>

        <Text
          style={styles.noteText}
          numberOfLines={isGridView ? 6 : 3}
        >
          {note.text}
        </Text>

        <View style={styles.virtueContainer}>
          {note.virtues?.slice(0, 3).map((virtue, index) => (
            <View
              key={`${note.id}-virtue-${index}`}
              style={[styles.virtueBadge, { backgroundColor: `${theme.colors.primary}15` }]}
            >
              <Text style={[styles.virtueText, { color: theme.colors.primary }]}>
                {virtue}
              </Text>
            </View>
          ))}
          {note.virtues && note.virtues.length > 3 && (
            <Text style={styles.moreVirtues}>
              +{note.virtues?.length - 3}
            </Text>
          )}
        </View>
      </View>
    </TouchableOpacity>
  );
};

export default NoteCard;