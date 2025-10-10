import React, { useState, useMemo, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Modal, FlatList } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';

type PickerItem = number | { label: string; value: number };

interface BiblePickerProps {
  value: number;
  items: PickerItem[];
  onSelect: (value: number) => void;
  allowAlphabeticalSort?: boolean;
}

const BiblePicker: React.FC<BiblePickerProps> = ({
  value,
  items,
  onSelect,
  allowAlphabeticalSort = false
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const [modalVisible, setModalVisible] = useState(false);
  const [sortMode, setSortMode] = useState<'canonical' | 'alphabetical'>('canonical');

  type NormalizedItem = { label: string; value: number; canonicalIndex: number };

  const normalizedItems: NormalizedItem[] = useMemo(
    () =>
      items.map((item, index) => {
        if (typeof item === 'object' && item !== null && 'label' in item && 'value' in item) {
          const typedItem = item as { label: string; value: number };
          return {
            label: typedItem.label,
            value: typedItem.value,
            canonicalIndex: index
          };
        }

        const primitiveValue = item as number;
        return {
          label: String(primitiveValue),
          value: primitiveValue,
          canonicalIndex: index
        };
      }),
    [items]
  );

  const sortedItems = useMemo(() => {
    if (allowAlphabeticalSort && sortMode === 'alphabetical') {
      return [...normalizedItems].sort((a, b) => a.label.localeCompare(b.label));
    }
    return normalizedItems;
  }, [allowAlphabeticalSort, sortMode, normalizedItems]);

  const selectedLabel = useMemo(() => {
    const match = normalizedItems.find(
      (item) => item.value === value
    );
    return match?.label ?? String(value);
  }, [normalizedItems, value]);

  useEffect(() => {
    if (!modalVisible) {
      setSortMode('canonical');
    }
  }, [modalVisible]);

  return (
    <>
      <TouchableOpacity style={styles.pickerButton} onPress={() => setModalVisible(true)}>
        <Text style={styles.pickerText}>{selectedLabel}</Text>
        <MaterialIcons name="arrow-drop-down" size={24} color={theme.colors.text.primary} />
      </TouchableOpacity>

      <Modal visible={modalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            {allowAlphabeticalSort && (
              <View style={styles.sortToggleContainer}>
                <TouchableOpacity
                  style={[
                    styles.sortToggleButton,
                    styles.sortToggleButtonLeft,
                    sortMode === 'canonical' && styles.sortToggleButtonActive
                  ]}
                  onPress={() => setSortMode('canonical')}
                >
                  <Text
                    style={[
                      styles.sortToggleText,
                      sortMode === 'canonical' && styles.sortToggleTextActive
                    ]}
                  >
                    Book Order
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[
                    styles.sortToggleButton,
                    sortMode === 'alphabetical' && styles.sortToggleButtonActive
                  ]}
                  onPress={() => setSortMode('alphabetical')}
                >
                  <Text
                    style={[
                      styles.sortToggleText,
                      sortMode === 'alphabetical' && styles.sortToggleTextActive
                    ]}
                  >
                    A–Z
                  </Text>
                </TouchableOpacity>
              </View>
            )}
            <FlatList
              data={sortedItems}
              keyExtractor={(item) => `${item.canonicalIndex}-${item.value}`}
              renderItem={({ item }) => {
                const isSelected = item.value === value;
                return (
                  <TouchableOpacity
                    style={[styles.pickerItem, isSelected && styles.pickerItemSelected]}
                    onPress={() => {
                      onSelect(item.value);
                      setModalVisible(false);
                    }}
                  >
                    <Text
                      style={[styles.pickerItemText, isSelected && styles.pickerItemTextSelected]}
                    >
                      {item.label}
                    </Text>
                  </TouchableOpacity>
                );
              }}
            />
          </View>
        </View>
      </Modal>
    </>
  );
};

const createStyles = (theme: Theme) =>
  StyleSheet.create({
    pickerButton: {
      flexDirection: 'row',
      alignItems: 'center',
      padding: theme.spacing.sm,
      borderRadius: theme.borderRadius.sm,
      backgroundColor: theme.colors.surface,
    },
    pickerText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
    },
    sortToggleContainer: {
      flexDirection: 'row',
      marginBottom: theme.spacing.md,
      borderRadius: theme.borderRadius.md,
      borderWidth: 1,
      borderColor: theme.colors.border,
      overflow: 'hidden',
    },
    sortToggleButton: {
      flex: 1,
      paddingVertical: theme.spacing.sm,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: theme.colors.surface,
    },
    sortToggleButtonLeft: {
      borderRightWidth: 1,
      borderRightColor: theme.colors.border,
    },
    sortToggleButtonActive: {
      backgroundColor: `${theme.colors.primary}15`,
    },
    sortToggleText: {
      ...theme.typography.caption.primary,
      color: theme.colors.text.secondary,
    },
    sortToggleTextActive: {
      color: theme.colors.primary,
      ...theme.typography.caption.primary,
    },
    modalOverlay: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: 'rgba(0, 0, 0, 0.5)',
    },
    modalContent: {
      width: '80%',
      maxHeight: '60%',
      backgroundColor: theme.colors.background,
      borderRadius: theme.borderRadius.md,
      padding: theme.spacing.md,
    },
    pickerItem: {
      padding: theme.spacing.md,
      borderBottomWidth: 1,
      borderBottomColor: theme.colors.border,
    },
    pickerItemSelected: {
      backgroundColor: `${theme.colors.primary}10`,
    },
    pickerItemText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
    },
    pickerItemTextSelected: {
      color: theme.colors.primary,
      ...theme.typography.body.sans,
    },
  });

export default BiblePicker;