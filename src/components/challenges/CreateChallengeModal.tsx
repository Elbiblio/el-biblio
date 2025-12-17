import React, { memo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, TextInput, Modal } from 'react-native';
import { Star, X } from '@/components/Icons';
import { Theme } from '@/theme';
import { ChallengeType } from '@/types/challenges';

const CHALLENGE_TYPES = [
  { id: 'virtue', label: 'Develop Virtue', icon: Star, color: '#4CAF50' },
  { id: 'vice', label: 'Reduce Vice', icon: X, color: '#F44336' },
];

export interface CreateChallengeModalProps {
  visible: boolean;
  theme: Theme;
  title: string;
  description: string;
  type: ChallengeType;
  endTime: string;
  isLoading: boolean;
  onChangeTitle: (text: string) => void;
  onChangeDescription: (text: string) => void;
  onChangeType: (type: ChallengeType) => void;
  onChangeEndTime: (text: string) => void;
  onSubmit: () => void;
  onClose: () => void;
}

const CreateChallengeModal = memo(({
  visible,
  theme,
  title,
  description,
  type,
  endTime,
  isLoading,
  onChangeTitle,
  onChangeDescription,
  onChangeType,
  onChangeEndTime,
  onSubmit,
  onClose,
}: CreateChallengeModalProps) => {
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const canSubmit = !isLoading && title.trim().length > 0;

  return (
    <Modal visible={visible} animationType="fade" transparent onRequestClose={onClose}>
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <Text style={styles.modalTitle}>Create a Personal Challenge</Text>
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
          <View style={{ flexDirection: 'row', gap: theme?.spacing.sm, marginBottom: theme?.spacing.md }}>
            {CHALLENGE_TYPES.map((t) => (
              <TouchableOpacity
                key={t.id}
                style={[
                  styles.typeButton,
                  { backgroundColor: type === t.id ? `${theme?.colors.primary}15` : `${theme?.colors.text.secondary}10` },
                ]}
                onPress={() => onChangeType(t.id as ChallengeType)}
              >
                {(() => {
                  const Icon = t.icon as any;
                  return (
                    <Icon
                      size={16}
                      color={type === t.id ? theme?.colors.primary : theme?.colors.text.secondary}
                    />
                  );
                })()}
                <Text style={[styles.typeButtonText, { color: type === t.id ? theme?.colors.primary : theme?.colors.text.secondary }]}>
                  {t.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <TextInput
            style={styles.input}
            placeholder="End time (HH:MM)"
            placeholderTextColor={theme?.colors.text.secondary}
            value={endTime}
            onChangeText={onChangeEndTime}
          />
          <View style={styles.formActions}>
            <TouchableOpacity style={[styles.formButton, styles.cancelButton]} onPress={onClose}>
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.formButton, styles.createButton, !canSubmit && { opacity: 0.7 }]}
              onPress={onSubmit}
              disabled={!canSubmit}
            >
              <Text style={styles.createButtonText}>Create</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
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
  typeButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    gap: theme?.spacing.xs,
  },
  typeButtonText: {
    ...theme?.typography.caption.primary,
    fontWeight: '600',
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

CreateChallengeModal.displayName = 'CreateChallengeModal';

export default CreateChallengeModal;
