import React from 'react';
import {
  View,
  Text,
  StyleSheet,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { BookOpen, Sparkle } from './Icons';
import { formatVerseReference } from '@/utils/verseReference';
import { useTheme } from '@/contexts/ThemeContext';
import { useVerseStore, useAuthStore } from '@/stores/StoreProvider';
import { Theme } from '@/theme';
import type { Verse } from '@/types';

interface VerseContextProps {
  verse: Verse | null;
  style?: any;
}

const VerseContext: React.FC<VerseContextProps> = ({ verse, style }) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  if (!verse) return null;

  return (
    <BlurView
      intensity={10}
      style={[styles.container, style]}
    >
      <View style={styles.header}>
        <View style={styles.iconContainer}>
          <BookOpen size={16} color={theme.colors.primary} />
        </View>
        <Text style={styles.reference}>{formatVerseReference(verse.reference_display)}</Text>
        {verse.theme && (
          <View style={styles.themeBadge}>
            <Sparkle size={12} color={theme.colors.secondary} />
            <Text style={styles.themeText}>{verse.theme.display_name}</Text>
          </View>
        )}
      </View>
      
      <Text style={styles.verseText} numberOfLines={2}>
        {verse.text}
      </Text>
      
      <View style={styles.guidance}>
        <Text style={styles.guidanceText}>
          Reflect on how this verse illuminates our sojourn through earth
        </Text>
      </View>
    </BlurView>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    backgroundColor: `${theme.colors.surface}CC`,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginHorizontal: theme.spacing.md,
    marginBottom: theme.spacing.md,
    borderLeftWidth: 3,
    borderLeftColor: theme.colors.primary,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
    flexWrap: 'wrap',
    gap: theme.spacing.xs,
    minHeight: 32,
  },
  iconContainer: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: `${theme.colors.primary}20`,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reference: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
    flex: 1,
    minWidth: 80,
  },
  themeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: theme.spacing.xs,
    paddingVertical: 2,
    backgroundColor: `${theme.colors.secondary}20`,
    borderRadius: theme.borderRadius.full,
  },
  themeText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.secondary,
    fontWeight: '500',
  },
  verseText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    lineHeight: 20,
    marginBottom: theme.spacing.sm,
    fontStyle: 'italic',
  },
  guidance: {
    backgroundColor: `${theme.colors.background}50`,
    borderRadius: theme.borderRadius.sm,
    padding: theme.spacing.sm,
    marginTop: theme.spacing.xs,
  },
  guidanceText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    fontSize: 12,
    lineHeight: 16,
  },
});

export default VerseContext;
