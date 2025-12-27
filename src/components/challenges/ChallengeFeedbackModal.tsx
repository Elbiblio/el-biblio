import React from 'react';
import { Modal, View, TouchableOpacity, TextInput, Text, StyleSheet } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';

export type ChallengeFeedbackModalProps = {
  visible: boolean;
  value: string;
  onChangeText: (text: string) => void;
  onSkip: () => void | Promise<void>;
  onSubmit: () => void | Promise<void>;
  onClose?: () => void;
  submitting?: boolean;
  skipLabel?: string;
  submitLabel?: string;
  title?: string;
  subtitle?: string;
};

const ChallengeFeedbackModal: React.FC<ChallengeFeedbackModalProps> = ({
  visible,
  value,
  onChangeText,
  onSkip,
  onSubmit,
  onClose,
  submitting = false,
  skipLabel = 'Skip',
  submitLabel = 'Share & Done',
  title = 'Share a quick feedback?',
  subtitle = "A short note helps others stick with it.",
}) => {
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const handleClose = onClose ?? onSkip;

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={handleClose}>
      <View style={styles.overlay}>
        <TouchableOpacity style={StyleSheet.absoluteFill} activeOpacity={1} onPress={handleClose} />
        <View style={styles.card}>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.subtitle}>{subtitle}</Text>
          <TextInput
            style={styles.input}
            placeholder="What helped you complete this today?"
            placeholderTextColor={theme?.colors.text.tertiary}
            value={value}
            onChangeText={onChangeText}
            multiline
          />
          <View style={styles.actions}>
            <TouchableOpacity style={styles.secondaryButton} onPress={onSkip} activeOpacity={0.85}>
              <Text style={styles.secondaryText}>{skipLabel}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.primaryButton, submitting && styles.primaryButtonDisabled]}
              onPress={onSubmit}
              activeOpacity={0.85}
              disabled={submitting}
            >
              <Text style={styles.primaryText}>{submitting ? 'Sending…' : submitLabel}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const createStyles = (theme: Theme) =>
  StyleSheet.create({
    overlay: {
      flex: 1,
      backgroundColor: 'rgba(0,0,0,0.5)',
      justifyContent: 'center',
      alignItems: 'center',
      padding: theme?.spacing.md,
    },
    card: {
      width: '100%',
      maxWidth: 420,
      backgroundColor: theme?.colors.surface,
      borderRadius: theme?.borderRadius.xl,
      padding: theme?.spacing.lg,
      borderWidth: 1,
      borderColor: theme?.colors.border,
    },
    title: {
      ...theme?.typography.heading.small,
      color: theme?.colors.text.primary,
    },
    subtitle: {
      ...theme?.typography.caption.secondary,
      color: theme?.colors.text.secondary,
      marginTop: theme?.spacing.xs,
      marginBottom: theme?.spacing.md,
    },
    input: {
      borderWidth: 1,
      borderColor: theme?.colors.border,
      borderRadius: theme?.borderRadius.lg,
      paddingHorizontal: theme?.spacing.md,
      paddingVertical: theme?.spacing.sm,
      minHeight: 100,
      textAlignVertical: 'top',
      ...theme?.typography.body.sans,
      color: theme?.colors.text.primary,
      marginBottom: theme?.spacing.lg,
      backgroundColor: theme?.colors.background,
    },
    actions: {
      flexDirection: 'row',
      justifyContent: 'flex-end',
      gap: theme?.spacing.sm,
    },
    secondaryButton: {
      paddingVertical: theme?.spacing.sm,
      paddingHorizontal: theme?.spacing.lg,
      borderRadius: theme?.borderRadius.full,
      backgroundColor: `${theme?.colors.text.secondary}10`,
    },
    secondaryText: {
      ...theme?.typography.body.sans,
      color: theme?.colors.text.secondary,
      fontWeight: '600',
    },
    primaryButton: {
      paddingVertical: theme?.spacing.sm,
      paddingHorizontal: theme?.spacing.lg,
      borderRadius: theme?.borderRadius.full,
      backgroundColor: theme?.colors.primary,
    },
    primaryButtonDisabled: {
      opacity: 0.7,
    },
    primaryText: {
      ...theme?.typography.body.sans,
      color: '#fff',
      fontWeight: '600',
    },
  });

export default ChallengeFeedbackModal;
