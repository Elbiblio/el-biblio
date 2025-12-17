import React, { memo } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Modal } from 'react-native';
import { Clock } from '@/components/Icons';
import { Theme } from '@/theme';

const REMINDER_OPTIONS = [1, 4, 6];

export interface JoinReminderModalProps {
  visible: boolean;
  theme: Theme;
  selectedHours: number;
  isLoading: boolean;
  onSelectHours: (hours: number) => void;
  onConfirm: () => void;
  onClose: () => void;
}

const JoinReminderModal = memo(({
  visible,
  theme,
  selectedHours,
  isLoading,
  onSelectHours,
  onConfirm,
  onClose,
}: JoinReminderModalProps) => {
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  return (
    <Modal
      visible={visible}
      animationType="fade"
      transparent
      onRequestClose={onClose}
    >
      <View style={styles.modalBackdrop}>
        <View style={styles.modalCard}>
          <Text style={styles.modalTitle}>Set Challenge Reminder</Text>
          <Text style={styles.subtitle}>Choose how often you'd like to be reminded.</Text>
          <View style={{ gap: theme?.spacing.sm }}>
            {REMINDER_OPTIONS.map((hours) => (
              <TouchableOpacity
                key={hours}
                style={[
                  styles.reminderOption,
                  selectedHours === hours && styles.reminderOptionSelected,
                ]}
                onPress={() => onSelectHours(hours)}
              >
                <Clock size={20} color={selectedHours === hours ? theme?.colors.primary : theme?.colors.text.secondary} />
                <Text style={[
                  styles.reminderOptionText,
                  selectedHours === hours && styles.reminderOptionTextSelected,
                ]}>
                  Every {hours === 1 ? '1 hour' : `${hours} hours`}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <View style={[styles.formActions, { marginTop: theme?.spacing.lg }]}> 
            <TouchableOpacity
              style={[styles.formButton, styles.cancelButton]}
              onPress={onClose}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.formButton, styles.createButton, isLoading && { opacity: 0.7 }]}
              onPress={onConfirm}
              disabled={isLoading}
            >
              <Text style={styles.createButtonText}>Join</Text>
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
    marginBottom: theme?.spacing.sm,
  },
  subtitle: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.md,
  },
  reminderOption: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.sm,
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    backgroundColor: theme?.colors.background,
  },
  reminderOptionSelected: {
    backgroundColor: `${theme?.colors.primary}10`,
    borderColor: `${theme?.colors.primary}35`,
  },
  reminderOptionText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    fontWeight: '600',
  },
  reminderOptionTextSelected: {
    color: theme?.colors.primary,
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

JoinReminderModal.displayName = 'JoinReminderModal';

export default JoinReminderModal;
