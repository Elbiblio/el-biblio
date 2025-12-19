import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { PassageSummary } from '@/stores/VerseBuilderStore';
import { Check, X, BookOpen } from 'lucide-react-native';
import Animated, { FadeIn, FadeOut } from 'react-native-reanimated';

interface VerseBuilderPassageSummaryProps {
  summary: PassageSummary;
  onDismiss: () => void;
}

export const VerseBuilderPassageSummary: React.FC<VerseBuilderPassageSummaryProps> = ({
  summary,
  onDismiss,
}) => {
  const theme = useTheme();

  const { passage, correctCount, totalCount } = summary;
  const percentage = Math.round((correctCount / totalCount) * 100);
  const verseRange = passage.startVerse === passage.endVerse 
    ? `${passage.startVerse}` 
    : `${passage.startVerse}-${passage.endVerse}`;

  const styles = StyleSheet.create({
    overlay: {
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.85)',
      justifyContent: 'center',
      alignItems: 'center',
      padding: 20,
      zIndex: 1000,
    },
    container: {
      backgroundColor: theme.colors.surface,
      borderRadius: 16,
      padding: 24,
      width: '100%',
      maxWidth: 400,
      maxHeight: '80%',
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.3,
      shadowRadius: 8,
      elevation: 8,
    },
    header: {
      alignItems: 'center',
      marginBottom: 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.colors.border,
    },
    iconContainer: {
      width: 56,
      height: 56,
      borderRadius: 28,
      backgroundColor: theme.colors.primary + '20',
      justifyContent: 'center',
      alignItems: 'center',
      marginBottom: 12,
    },
    title: {
      fontSize: 20,
      fontWeight: '700',
      color: theme.colors.text.primary,
      marginBottom: 4,
    },
    reference: {
      fontSize: 16,
      fontWeight: '600',
      color: theme.colors.primary,
      marginBottom: 8,
    },
    scoreText: {
      fontSize: 14,
      color: theme.colors.text.secondary,
      fontWeight: '500',
    },
    versesContainer: {
      maxHeight: 300,
      marginBottom: 20,
    },
    verseItem: {
      flexDirection: 'row',
      paddingVertical: 12,
      paddingHorizontal: 12,
      marginBottom: 8,
      borderRadius: 8,
      backgroundColor: theme.colors.surfaceVariant,
    },
    verseItemCorrect: {
      backgroundColor: theme.colors.success + '15',
      borderLeftWidth: 3,
      borderLeftColor: theme.colors.success,
    },
    verseItemIncorrect: {
      backgroundColor: theme.colors.error + '15',
      borderLeftWidth: 3,
      borderLeftColor: theme.colors.error,
    },
    verseIcon: {
      marginRight: 12,
      marginTop: 2,
    },
    verseContent: {
      flex: 1,
    },
    verseText: {
      fontSize: 14,
      lineHeight: 20,
      color: theme.colors.text.primary,
    },
    button: {
      backgroundColor: theme.colors.primary,
      paddingVertical: 14,
      paddingHorizontal: 24,
      borderRadius: 12,
      alignItems: 'center',
      shadowColor: theme.colors.primary,
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.3,
      shadowRadius: 4,
      elevation: 4,
    },
    buttonText: {
      color: '#FFFFFF',
      fontSize: 16,
      fontWeight: '600',
    },
  });

  return (
    <Animated.View 
      style={styles.overlay}
      entering={FadeIn.duration(300)}
      exiting={FadeOut.duration(200)}
    >
      <Animated.View 
        style={styles.container}
        entering={FadeIn.delay(100).springify()}
      >
        <View style={styles.header}>
          <View style={styles.iconContainer}>
            <BookOpen size={28} color={theme.colors.primary} />
          </View>
          <Text style={styles.title}>Passage Complete</Text>
          <Text style={styles.reference}>
            {passage.bookName} {passage.chapter}:{verseRange}
          </Text>
          <Text style={styles.scoreText}>
            {correctCount} of {totalCount} correct ({percentage}%)
          </Text>
        </View>

        <ScrollView 
          style={styles.versesContainer}
          showsVerticalScrollIndicator={false}
        >
          {passage.verses.map((verse, index) => (
            <View
              key={verse.id}
              style={[
                styles.verseItem,
                verse.correct === true && styles.verseItemCorrect,
                verse.correct === false && styles.verseItemIncorrect,
              ]}
            >
              <View style={styles.verseIcon}>
                {verse.correct === true ? (
                  <Check size={18} color={theme.colors.success} strokeWidth={3} />
                ) : verse.correct === false ? (
                  <X size={18} color={theme.colors.error} strokeWidth={3} />
                ) : null}
              </View>
              <View style={styles.verseContent}>
                <Text style={styles.verseText}>{verse.text}</Text>
              </View>
            </View>
          ))}
        </ScrollView>

        <TouchableOpacity
          style={styles.button}
          onPress={onDismiss}
          activeOpacity={0.8}
        >
          <Text style={styles.buttonText}>Continue</Text>
        </TouchableOpacity>
      </Animated.View>
    </Animated.View>
  );
};
