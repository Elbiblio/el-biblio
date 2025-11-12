
import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity, ScrollView, Modal, ViewStyle, TextStyle } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { X, BookmarkSimple } from '@/components/Icons';
import { useNavigation, NavigationProp } from '@react-navigation/native';
import { RootStackParamList, ScopedVerseParam } from '@/types';
import type { Verse as AppVerse } from '@/types';
import { useVerseStore, useAuthStore } from '@/stores/StoreProvider';
import { toast } from 'sonner-native';

type Verse = AppVerse;

type VersePreviewContext = 'default' | 'daily-verses' | 'home';

const buildScopedNavigationParams = (
  verse: Verse,
  contextData?: VersePreviewModalProps['contextData'],
): RootStackParamList['BibleScreen'] | null => {
  const primaryText = verse.text?.trim();
  if (!primaryText) {
    return null;
  }

  const scopedVerses: ScopedVerseParam[] = [];
  const baseReference = verse.reference?.replace(/:\d+.*$/, '') ?? null;
  const primaryReference = verse.reference_display || verse.reference || undefined;
  const addVerse = (entry: ScopedVerseParam) => {
    const key = `${entry.reference ?? ''}|${entry.text}`;
    if (scopedVerses.some(existing => `${existing.reference ?? ''}|${existing.text}` === key)) {
      return;
    }
    scopedVerses.push(entry);
  };

  const mainVerseNumber = typeof verse.verse === 'number' ? verse.verse : null;

  const contextLines = (verse.context_text ?? '')
    .split(/\n+/)
    .map(line => line.trim())
    .filter(Boolean);

  contextLines.forEach(line => {
    const match = line.match(/^(\d+)[\s.:\-]*\s*(.*)$/);
    const candidateNumber = match ? Number(match[1]) : null;
    const text = (match ? match[2] : line).trim();
    if (!text) {
      return;
    }

    const isPrimary = candidateNumber != null && mainVerseNumber != null ? candidateNumber === mainVerseNumber : (!!primaryText && text === primaryText);
    const reference = candidateNumber != null
      ? (baseReference ? `${baseReference}:${candidateNumber}` : `${verse.book ?? ''} ${verse.chapter ?? ''}:${candidateNumber}`.trim())
      : verse.context_reference ?? primaryReference;

    addVerse({
      text,
      reference,
      isPrimary,
    });
  });

  if (!scopedVerses.some(item => item.isPrimary) && primaryText) {
    addVerse({
      text: primaryText,
      reference: primaryReference,
      isPrimary: true,
    });
  }

  if (!scopedVerses.length) {
    return null;
  }

  return {
    book: verse.book ?? undefined,
    chapter: verse.chapter ?? undefined,
    verse: verse.verse ?? undefined,
    mode: 'scoped',
    scopedTitle: verse.context_reference ?? primaryReference ?? undefined,
    scopedSubtitle: contextData?.subheading ?? verse.translation ?? undefined,
    scopedVerses,
  };
};

interface VersePreviewModalProps {
  verse: Verse | null;
  onClose: () => void;
  onVersePress?: (verse: Verse) => void;
  context?: VersePreviewContext;
  contextData?: {
    heading?: string;
    subheading?: string;
  } | null;
}

const VersePreviewModal: React.FC<VersePreviewModalProps> = ({ verse, onClose, onVersePress, context = 'default', contextData }) => {
  const theme = useTheme();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const { createBookmark, removeBookmark } = useVerseStore();
  const { user } = useAuthStore();

  if (!verse) return null;

  const handleVersePress = (verseToHandle: Verse) => {
    if (onVersePress) {
      onVersePress(verseToHandle);
    }
  };

  const styles = createStyles(theme);

  const isBookmarked = Boolean((verse as any).isBookmarked);

  const handleToggleBookmark = async () => {
    if (!user) {
      toast.info('Please log in to bookmark verses');
      return;
    }
    try {
      if (isBookmarked) {
        const ok = await removeBookmark(verse.id, 'App\\Models\\Verse');
        if (ok) toast.success('Bookmark removed'); else toast.error('Failed to remove bookmark');
      } else {
        const ok = await createBookmark({
          user_id: user.id,
          bookmarkable_type: 'App\\Models\\Verse',
          bookmarkable_id: verse.id,
        });
        if (ok) {
          toast.success('Verse bookmarked');
        } else {
          const key = `App\\Models\\Verse_${verse.id}`;
          const exists = useVerseStore().state.bookmarks.has(key);
          if (exists) {
            toast.info('Verse already bookmarked');
          } else {
            toast.error('Failed to bookmark');
          }
        }
      }
    } catch (error: any) {
      const status = error?.status || error?.response?.status;
      if (status === 409) {
        toast.info('Verse already bookmarked');
      } else {
        toast.error('Failed to update bookmark');
      }
    }
  };

  return (
    <Modal
      visible={!!verse}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            <View style={styles.headerTextContainer}>
              <Text style={styles.reference} numberOfLines={2}>
                {contextData?.heading || verse.reference_display || verse.reference}
              </Text>
              {contextData?.subheading ? (
                <Text style={styles.translation}>{contextData.subheading}</Text>
              ) : verse.translation ? (
                <Text style={styles.translation}>{verse.translation}</Text>
              ) : null}
            </View>
            <View style={styles.rightActions}>
              <TouchableOpacity onPress={handleToggleBookmark} style={{ marginRight: 8 }}>
                <BookmarkSimple
                  size={20}
                  color={isBookmarked ? theme.colors.primary : theme.colors.text.secondary}
                  filled={isBookmarked}
                />
              </TouchableOpacity>
              <TouchableOpacity onPress={onClose}>
                <X size={20} color={theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>
          </View>

          <ScrollView
            contentContainerStyle={styles.bodyContent}
            style={styles.body}
            showsVerticalScrollIndicator={false}
          >
            {verse.text ? (
              <View style={styles.section}>
                <Text style={styles.sectionLabel}>Verse</Text>
                <Text style={styles.verseText}>{verse.text.trim()}</Text>
              </View>
            ) : null}

            {verse.context_text ? (
              <View style={styles.section}>
                <Text style={styles.sectionLabel}>Context</Text>
                <Text style={styles.contextText}>{verse.context_text.trim()}</Text>
              </View>
            ) : (
              <Text style={styles.contextPlaceholder}>Context not available yet.</Text>
            )}
          </ScrollView>

          <View style={styles.footer}>
            {verse.book && verse.chapter ? (
              <TouchableOpacity
                style={styles.primaryButton}
                onPress={() => {
                  const scopedParams = buildScopedNavigationParams(verse, contextData);
                  if (scopedParams) {
                    console.log('[VersePreviewModal] Navigating to BibleScreen with scoped payload', scopedParams);
                    navigation.navigate('BibleScreen', scopedParams);
                  } else {
                    console.log('[VersePreviewModal] Navigating to BibleScreen with fallback verse', {
                      book: verse.book,
                      chapter: verse.chapter,
                      verse: verse.verse,
                    });
                    navigation.navigate('BibleScreen', {
                      book: verse.book || undefined,
                      chapter: verse.chapter || undefined,
                      verse: verse.verse || undefined,
                    });
                  }
                  onClose();
                }}
              >
                <Text style={styles.primaryButtonText}>Open in Bible</Text>
              </TouchableOpacity>
            ) : null}

            {context === 'daily-verses' ? null : (
              <TouchableOpacity
                style={[
                  styles.secondaryButton,
                  !(verse.book && verse.chapter) && styles.secondaryButtonFullWidth,
                ]}
                onPress={() => {
                  console.log('[VersePreviewModal] View Details pressed', {
                    verseId: verse.id,
                    context,
                  });
                  handleVersePress(verse);
                  onClose();
                }}
              >
                <Text style={styles.secondaryButtonText}>
                  View Details
                </Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      </View>
    </Modal>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    padding: 20,
  } as ViewStyle,
  container: {
    backgroundColor: theme.colors.background,
    borderRadius: 16,
    maxHeight: '90%',
    overflow: 'hidden',
  } as ViewStyle,
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  } as ViewStyle,
  headerTextContainer: {
    flex: 1,
    marginRight: 12,
  } as ViewStyle,
  rightActions: {
    flexDirection: 'row',
    alignItems: 'center',
  } as ViewStyle,
  reference: {
    ...theme.typography.heading.small,
  } as TextStyle,
  translation: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    marginTop: 4,
  } as TextStyle,
  body: {
    maxHeight: '70%',
  } as ViewStyle,
  bodyContent: {
    paddingHorizontal: 20,
    paddingVertical: 24,
    gap: 20,
  } as ViewStyle,
  section: {
    gap: 8,
  } as ViewStyle,
  sectionLabel: {
    ...theme.typography.caption,
    color: theme.colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 1,
  } as TextStyle,
  verseText: {
    ...theme.typography.body1,
    lineHeight: 26,
  } as TextStyle,
  contextText: {
    ...theme.typography.body2,
    lineHeight: 24,
  } as TextStyle,
  contextPlaceholder: {
    ...theme.typography.body2,
    lineHeight: 24,
    color: theme.colors.text.secondary,
  } as TextStyle,
  footer: {
    flexDirection: 'row',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: theme.colors.border,
    gap: 12,
  } as ViewStyle,
  primaryButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.primary,
  } as ViewStyle,
  primaryButtonText: {
    ...theme.typography.button,
    color: theme.colors.text.inverse,
  } as TextStyle,
  secondaryButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme.colors.primary,
  } as ViewStyle,
  secondaryButtonFullWidth: {
    flex: 2,
  } as ViewStyle,
  secondaryButtonText: {
    ...theme.typography.button,
    color: theme.colors.primary,
  } as TextStyle,
});

export default VersePreviewModal;

