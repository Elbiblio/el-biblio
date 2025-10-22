import React from 'react';
import { Modal, View, Text, TouchableOpacity, TouchableWithoutFeedback, StyleSheet } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { Brush, BrushOutlined } from '@/components/Icons';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { BibleVerse } from '@/types';

interface VerseActionsSheetProps {
  visible: boolean;
  verse: BibleVerse | null;
  isBookmarked: boolean;
  isHighlighted: boolean;
  isLiked: boolean;
  onClose: () => void;
  onBookmark: () => void;
  onHighlight: () => void;
  onLike: () => void;
  onShare: () => void;
  onCompare: () => void;
  onExplainWithAI: () => void;
}

const VerseActionsSheet: React.FC<VerseActionsSheetProps> = ({
  visible,
  verse,
  isBookmarked,
  isHighlighted,
  isLiked,
  onClose,
  onBookmark,
  onHighlight,
  onLike,
  onShare,
  onCompare,
  onExplainWithAI,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <TouchableWithoutFeedback onPress={onClose}>
        <View style={styles.overlay}>
          <TouchableWithoutFeedback>
            <View style={styles.sheet}>
              <View style={styles.header}>
                <Text style={styles.headerTitle}>{verse?.reference ?? 'Verse actions'}</Text>
                <TouchableOpacity onPress={onClose}>
                  <MaterialIcons name="close" size={22} color={theme.colors.text.secondary} />
                </TouchableOpacity>
              </View>

              {verse ? (
                <Text style={styles.previewText} numberOfLines={3}>
                  {verse.text}
                </Text>
              ) : null}

              <View style={styles.actionsContainer}>
                <ActionButton
                  icon={
                    <MaterialIcons
                      name={isBookmarked ? 'bookmark' : 'bookmark-border'}
                      size={24}
                      color={theme.colors.primary}
                    />
                  }
                  label={isBookmarked ? 'Remove bookmark' : 'Bookmark'}
                  onPress={onBookmark}
                />

                <ActionButton
                  icon={isHighlighted ? (
                    <Brush size={22} color={theme.colors.primary} />
                  ) : (
                    <BrushOutlined size={22} color={theme.colors.primary} />
                  )}
                  label={isHighlighted ? 'Remove highlight' : 'Highlight'}
                  onPress={onHighlight}
                />

                <ActionButton
                  icon={
                    <MaterialIcons
                      name={isLiked ? 'thumb-up' : 'thumb-up-off-alt'}
                      size={24}
                      color={theme.colors.primary}
                    />
                  }
                  label={isLiked ? 'Unlike' : 'Like'}
                  onPress={onLike}
                />

                <ActionButton
                  icon={<MaterialIcons name="share" size={24} color={theme.colors.primary} />}
                  label="Share"
                  onPress={onShare}
                />

                <ActionButton
                  icon={<MaterialIcons name="compare-arrows" size={24} color={theme.colors.primary} />}
                  label="Compare"
                  onPress={onCompare}
                />

                <ActionButton
                  icon={<MaterialIcons name="auto-awesome" size={24} color={theme.colors.primary} />}
                  label="Explain with AI"
                  onPress={onExplainWithAI}
                />
              </View>
            </View>
          </TouchableWithoutFeedback>
        </View>
      </TouchableWithoutFeedback>
    </Modal>
  );
};

interface ActionButtonProps {
  icon: React.ReactNode;
  label: string;
  onPress: () => void;
}

const ActionButton: React.FC<ActionButtonProps> = ({ icon, label, onPress }) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  return (
    <TouchableOpacity style={styles.actionButton} onPress={onPress}>
      <View style={styles.actionIcon}>{icon}</View>
      <Text style={styles.actionLabel}>{label}</Text>
    </TouchableOpacity>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: theme.colors.background,
    padding: theme.spacing.lg,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    gap: theme.spacing.lg,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerTitle: {
    ...theme.typography.body.sans,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  previewText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  actionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.md,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    minWidth: '45%',
    backgroundColor: theme.colors.surface,
  },
  actionIcon: {
    marginRight: theme.spacing.sm,
  },
  actionLabel: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
});

export default VerseActionsSheet;
