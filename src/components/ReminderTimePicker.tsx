import React, { useCallback, useMemo, useState, useEffect } from 'react';
import {
  Modal,
  View,
  Text,
  TouchableOpacity,
  Pressable,
  ScrollView,
  StyleSheet,
} from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';

const HOURS = Array.from({ length: 24 }, (_, index) => index);
const MINUTES = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
const QUICK_SUGGESTIONS = ['06:00', '06:30', '07:00', '07:30', '08:00', '12:00', '18:00', '21:00'];

const padTime = (value: number) => value.toString().padStart(2, '0');

const parseTimeValue = (value?: string | null) => {
  if (!value) {
    return { hour: 7, minute: 0 };
  }
  const match = value.match(/^(\d{1,2}):(\d{2})$/);
  if (!match) {
    return { hour: 7, minute: 0 };
  }
  let hour = Number(match[1]);
  let minute = Number(match[2]);
  if (!Number.isFinite(hour) || hour < 0 || hour > 23) {
    hour = 7;
  }
  if (!Number.isFinite(minute) || minute < 0 || minute > 59) {
    minute = 0;
  }
  return { hour, minute };
};

export type ReminderTimePickerProps = {
  value?: string | null;
  onChange: (value: string | null) => void;
  placeholder?: string;
  label?: string;
  helperText?: string;
  allowClear?: boolean;
  disabled?: boolean;
};

const ReminderTimePicker: React.FC<ReminderTimePickerProps> = ({
  value,
  onChange,
  placeholder = 'Select time',
  label,
  helperText,
  allowClear = true,
  disabled,
}) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const [{ hour, minute }, setSelection] = useState(() => parseTimeValue(value));
  const [modalVisible, setModalVisible] = useState(false);

  useEffect(() => {
    setSelection(parseTimeValue(value));
  }, [value]);

  const formattedValue = value ? `${padTime(parseTimeValue(value).hour)}:${padTime(parseTimeValue(value).minute)}` : '';

  const handleOpen = useCallback(() => {
    if (disabled) return;
    setSelection(parseTimeValue(value));
    setModalVisible(true);
  }, [disabled, value]);

  const handleClose = useCallback(() => {
    setModalVisible(false);
  }, []);

  const handleApply = useCallback(() => {
    const nextValue = `${padTime(hour)}:${padTime(minute)}`;
    onChange(nextValue);
    setModalVisible(false);
  }, [hour, minute, onChange]);

  const handleQuickSelect = useCallback(
    (time: string) => {
      onChange(time);
      setSelection(parseTimeValue(time));
      setModalVisible(false);
    },
    [onChange]
  );

  const handleClear = useCallback(() => {
    onChange(null);
    setModalVisible(false);
  }, [onChange]);

  return (
    <View style={styles.container}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      <TouchableOpacity
        style={[styles.trigger, disabled && styles.triggerDisabled, !formattedValue && styles.triggerPlaceholder]}
        onPress={handleOpen}
        activeOpacity={0.8}
        disabled={disabled}
      >
        <Text style={[styles.triggerText, !formattedValue && styles.placeholderText]}>
          {formattedValue || placeholder}
        </Text>
      </TouchableOpacity>
      {helperText ? <Text style={styles.helperText}>{helperText}</Text> : null}

      <Modal
        visible={modalVisible}
        animationType="fade"
        transparent
        onRequestClose={handleClose}
      >
        <Pressable style={styles.backdrop} onPress={handleClose}>
          <View style={styles.sheet}>
            <Text style={styles.sheetTitle}>Choose reminder time</Text>

            <View style={styles.quickList}>
              {QUICK_SUGGESTIONS.map(suggestion => {
                const isActive = suggestion === formattedValue;
                return (
                  <TouchableOpacity
                    key={suggestion}
                    style={[styles.quickChip, isActive && styles.quickChipActive]}
                    onPress={() => handleQuickSelect(suggestion)}
                  >
                    <Text style={[styles.quickChipText, isActive && styles.quickChipTextActive]}>
                      {suggestion}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            <View style={styles.pickerRow}>
              <View style={styles.pickerColumn}>
                <Text style={styles.columnLabel}>Hour</Text>
                <ScrollView style={styles.pickerScroll} showsVerticalScrollIndicator={false}>
                  {HOURS.map(option => {
                    const isActive = option === hour;
                    return (
                      <TouchableOpacity
                        key={option}
                        onPress={() => setSelection(current => ({ ...current, hour: option }))}
                        style={[styles.optionChip, isActive && styles.optionChipActive]}
                      >
                        <Text style={[styles.optionText, isActive && styles.optionTextActive]}>
                          {padTime(option)}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </ScrollView>
              </View>
              <View style={styles.pickerColumn}>
                <Text style={styles.columnLabel}>Minute</Text>
                <ScrollView style={styles.pickerScroll} showsVerticalScrollIndicator={false}>
                  {MINUTES.map(option => {
                    const isActive = option === minute;
                    return (
                      <TouchableOpacity
                        key={option}
                        onPress={() => setSelection(current => ({ ...current, minute: option }))}
                        style={[styles.optionChip, isActive && styles.optionChipActive]}
                      >
                        <Text style={[styles.optionText, isActive && styles.optionTextActive]}>
                          {padTime(option)}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </ScrollView>
              </View>
            </View>

            <View style={styles.actionRow}>
              {allowClear ? (
                <TouchableOpacity style={styles.clearButton} onPress={handleClear}>
                  <Text style={styles.clearText}>Clear</Text>
                </TouchableOpacity>
              ) : (
                <View style={styles.actionSpacer} />
              )}
              <TouchableOpacity style={styles.applyButton} onPress={handleApply}>
                <Text style={styles.applyText}>Set time</Text>
              </TouchableOpacity>
            </View>
          </View>
        </Pressable>
      </Modal>
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    container: {
      gap: 6,
    },
    label: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
    },
    helperText: {
      ...theme.typography.caption.secondary,
      color: theme.colors.text.secondary,
    },
    trigger: {
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.sm,
      borderWidth: 1,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
    },
    triggerDisabled: {
      opacity: 0.6,
    },
    triggerPlaceholder: {
      borderStyle: 'dashed',
    },
    triggerText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
    },
    placeholderText: {
      color: theme.colors.text.secondary,
    },
    backdrop: {
      flex: 1,
      backgroundColor: '#00000066',
      justifyContent: 'flex-end',
      padding: theme.spacing.md,
    },
    sheet: {
      backgroundColor: theme.colors.background,
      borderRadius: theme.borderRadius.xl,
      padding: theme.spacing.lg,
      gap: theme.spacing.lg,
    },
    sheetTitle: {
      ...theme.typography.heading.small,
      color: theme.colors.text.primary,
      textAlign: 'center',
    },
    quickList: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: theme.spacing.sm,
      justifyContent: 'center',
    },
    quickChip: {
      paddingVertical: theme.spacing.xs,
      paddingHorizontal: theme.spacing.md,
      borderRadius: theme.borderRadius.full,
      borderWidth: 1,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
    },
    quickChipActive: {
      borderColor: theme.colors.primary,
      backgroundColor: `${theme.colors.primary}15`,
    },
    quickChipText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
    },
    quickChipTextActive: {
      color: theme.colors.primary,
      fontWeight: '600',
    },
    pickerRow: {
      flexDirection: 'row',
      gap: theme.spacing.md,
    },
    pickerColumn: {
      flex: 1,
    },
    columnLabel: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
      marginBottom: theme.spacing.xs,
    },
    pickerScroll: {
      maxHeight: 200,
    },
    optionChip: {
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.sm,
      alignItems: 'center',
      marginBottom: theme.spacing.xs,
      backgroundColor: theme.colors.surfaceVariant,
    },
    optionChipActive: {
      backgroundColor: `${theme.colors.primary}20`,
    },
    optionText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.secondary,
    },
    optionTextActive: {
      color: theme.colors.primary,
      fontWeight: '600',
    },
    actionRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: theme.spacing.md,
    },
    clearButton: {
      paddingVertical: theme.spacing.sm,
      paddingHorizontal: theme.spacing.md,
    },
    clearText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
    },
    actionSpacer: {
      width: theme.spacing.lg,
    },
    applyButton: {
      flex: 1,
      paddingVertical: theme.spacing.sm,
      borderRadius: theme.borderRadius.sm,
      backgroundColor: theme.colors.primary,
      alignItems: 'center',
    },
    applyText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.inverse,
      fontWeight: '600',
    },
  });

export default ReminderTimePicker;
