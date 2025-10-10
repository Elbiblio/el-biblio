import React from 'react';
import { Modal, View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';

interface FontSizeModalProps {
  visible: boolean;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  onChange: (value: number) => void;
  onClose: () => void;
}

const FontSizeModal: React.FC<FontSizeModalProps> = ({
  visible,
  value,
  min = 12,
  max = 28,
  step = 1,
  onChange,
  onClose,
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  const sizeOptions = React.useMemo(() => {
    const options: number[] = [];
    for (let s = min; s <= max; s += step) {
      options.push(Math.round(s));
    }
    return options;
  }, [min, max, step]);

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.title}>Text Size</Text>
            <TouchableOpacity onPress={onClose}>
              <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          <View style={styles.preview}>
            <Text style={[styles.previewText, { fontSize: value }]}>"The Word is a lamp to my feet."</Text>
          </View>

          <View style={styles.optionsContainer}>
            {sizeOptions.map((option) => {
              const isSelected = option === value;
              return (
                <TouchableOpacity
                  key={option}
                  style={[styles.optionPill, isSelected && styles.optionPillSelected]}
                  onPress={() => onChange(option)}
                >
                  <Text style={[styles.optionText, isSelected && styles.optionTextSelected]}>{option}</Text>
                </TouchableOpacity>
              );
            })}
          </View>

          <View style={styles.controlsRow}>
            <TouchableOpacity
              style={styles.controlButton}
              onPress={() => onChange(Math.max(min, value - step))}
            >
              <MaterialIcons name="remove" size={24} color={theme.colors.primary} />
            </TouchableOpacity>

            <Text style={styles.valueLabel}>{value} pt</Text>

            <TouchableOpacity
              style={styles.controlButton}
              onPress={() => onChange(Math.min(max, value + step))}
            >
              <MaterialIcons name="add" size={24} color={theme.colors.primary} />
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.45)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.lg,
  },
  container: {
    width: '100%',
    maxWidth: 420,
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    gap: theme.spacing.lg,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.2,
    shadowRadius: 12,
    elevation: 4,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: {
    ...theme.typography.body.sans,
    fontWeight: '600',
    color: theme.colors.text.primary,
  },
  preview: {
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.lg,
    borderRadius: theme.borderRadius.md,
  },
  previewText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    textAlign: 'center',
  },
  optionsContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginVertical: theme.spacing.sm,
  },
  optionPill: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: theme.colors.border,
    backgroundColor: theme.colors.surface,
    marginHorizontal: theme.spacing.xs,
    marginVertical: theme.spacing.xs,
  },
  optionPillSelected: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}15`,
  },
  optionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  optionTextSelected: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  controlsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  controlButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme.colors.primary}15`,
  },
  valueLabel: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
});

export default FontSizeModal;
