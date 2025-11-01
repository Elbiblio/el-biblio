import React from 'react';
import { TouchableOpacity, View, Text, StyleSheet, GestureResponderEvent } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { MaterialIcons } from '@expo/vector-icons';

type Props = {
  label: string;
  completed?: boolean;
  onPress?: (e: GestureResponderEvent) => void;
  onLongPress?: (e: GestureResponderEvent) => void;
  disabled?: boolean;
};

const PlanSegmentChip: React.FC<Props> = ({ label, completed = false, onPress, onLongPress, disabled = false }) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  const content = (
    <View style={[styles.chip, completed && styles.chipCompleted, disabled && styles.chipDisabled]}>
      <MaterialIcons
        name={completed ? 'check-circle' : 'radio-button-unchecked'}
        size={18}
        color={completed ? theme.colors.primary : theme.colors.text.secondary}
      />
      <Text style={styles.text}>{label}</Text>
    </View>
  );

  if (disabled) return content;
  return (
    <TouchableOpacity onPress={onPress} onLongPress={onLongPress} activeOpacity={0.8}>
      {content}
    </TouchableOpacity>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) =>
  StyleSheet.create({
    chip: {
      flexDirection: 'row',
      alignItems: 'center',
      gap: theme.spacing.xs,
      paddingVertical: theme.spacing.xs,
      paddingHorizontal: theme.spacing.sm,
      borderRadius: theme.borderRadius.full,
      borderWidth: 1,
      borderColor: theme.colors.border,
      backgroundColor: theme.colors.surface,
    },
    chipCompleted: {
      backgroundColor: `${theme.colors.primary}10`,
      borderColor: theme.colors.primary,
    },
    chipDisabled: {
      opacity: 0.6,
    },
    text: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
      fontWeight: '500',
    },
  });

export default PlanSegmentChip;
