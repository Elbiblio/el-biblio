import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Modal, FlatList } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';

interface BiblePickerProps {
  value: number;
  items: number[];
  onSelect: (value: number) => void;
}

const BiblePicker: React.FC<BiblePickerProps> = ({ value, items, onSelect }) => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const [modalVisible, setModalVisible] = useState(false);

  return (
    <>
      <TouchableOpacity style={styles.pickerButton} onPress={() => setModalVisible(true)}>
        <Text style={styles.pickerText}>{value}</Text>
        <MaterialIcons name="arrow-drop-down" size={24} color={theme.colors.text.primary} />
      </TouchableOpacity>

      <Modal visible={modalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <FlatList
              data={items}
              keyExtractor={(item) => item.toString()}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={styles.pickerItem}
                  onPress={() => {
                    onSelect(item);
                    setModalVisible(false);
                  }}
                >
                  <Text style={styles.pickerItemText}>{item}</Text>
                </TouchableOpacity>
              )}
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
    pickerItemText: {
      ...theme.typography.body.sans,
      color: theme.colors.text.primary,
    },
  });

export default BiblePicker;