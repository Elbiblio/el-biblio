import React, { memo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, Modal, KeyboardAvoidingView, Platform, ScrollView } from 'react-native';
import { Theme } from '@/theme';

export interface SuggestChallengeModalProps {
  visible: boolean;
  theme: Theme;
  title: string;
  description: string;
  isLoading: boolean;
  onChangeTitle: (text: string) => void;
  onChangeDescription: (text: string) => void;
  onSubmit: () => void;
  onClose: () => void;
}

const SuggestChallengeModal = memo(({
  visible,
  theme,
  title,
  description,
  isLoading,
  onChangeTitle,
  onChangeDescription,
  onSubmit,
  onClose,
}: SuggestChallengeModalProps) => {
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const canSubmit = !isLoading && title.trim().length > 0;

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <KeyboardAvoidingView style={styles.modalBackdrop} behavior={Platform.OS === 'ios' ? 'padding' : undefined} keyboardVerticalOffset={0}>
        <View style={styles.modalCard}>
          <Text style={styles.modalTitle}>Suggest a Community Challenge</Text>
          <ScrollView keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 16 }}>
            <TextInput
              style={styles.input}
              placeholder="Title"
              placeholderTextColor={theme?.colors.text.secondary}
              value={title}
              onChangeText={onChangeTitle}
            />
            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder="Description (optional)"
              placeholderTextColor={theme?.colors.text.secondary}
              value={description}
              onChangeText={onChangeDescription}
              multiline
            />
          </ScrollView>
          <View style={styles.formActions}>
            <TouchableOpacity style={[styles.formButton, styles.cancelButton]} onPress={onClose}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.formButton, styles.createButton, !canSubmit && { opacity: 0.7 }]}
              onPress={onSubmit}
              disabled={!canSubmit}
            >
              <Text style={styles.createButtonText}>Submit</Text>
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
});

const createStyles = (theme: Theme) => StyleSheet.create({
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme?.spacing.md,
  },
  modalCard: {
    width: '100%',
    maxWidth: 520,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
  },
  modalTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  input: {
    backgroundColor: theme?.colors.background,
    borderRadius: theme?.borderRadius.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  formActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  formButton: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    marginLeft: theme?.spacing.sm,
  },
  cancelButton: {
    backgroundColor: `${theme?.colors.text.secondary}10`,
  },
  cancelButtonText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
  },
  createButton: {
    backgroundColor: theme?.colors.primary,
  },
  createButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
  },
});

SuggestChallengeModal.displayName = 'SuggestChallengeModal';

export default SuggestChallengeModal;
