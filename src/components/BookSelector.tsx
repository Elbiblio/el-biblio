import React, { useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Modal, FlatList } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Book } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';

interface BookSelectorProps {
  currentBook: Book;
  onSelect: (book: Book) => void;
  books?: Book[];
}

const BookSelector: React.FC<BookSelectorProps> = ({ currentBook, onSelect, books }) => {
  const theme = useTheme();
  const styles = createStyles(theme);
  const [modalVisible, setModalVisible] = useState(false);
  const data = books && books.length > 0 ? books : bibleBooks;

  const renderItem = useCallback(
    ({ item }: { item: Book }) => (
      <TouchableOpacity
        style={styles.pickerItem}
        onPress={() => {
          onSelect(item);
          setModalVisible(false);
        }}
      >
        <Text style={styles.pickerItemText}>{item.name}</Text>
      </TouchableOpacity>
    ),
    [styles.pickerItem, styles.pickerItemText, onSelect]
  );

  const keyExtractor = useCallback((item: Book) => item.abbreviation, []);

  return (
    <>
      <TouchableOpacity style={styles.pickerButton} onPress={() => setModalVisible(true)}>
        <Text style={styles.pickerText}>{currentBook.name}</Text>
        <MaterialIcons name="menu-book" size={24} color={theme.colors.text.primary} />
      </TouchableOpacity>

      <Modal visible={modalVisible} transparent animationType="slide" onRequestClose={() => setModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <FlatList
              data={data}
              keyExtractor={keyExtractor}
              renderItem={renderItem}
              initialNumToRender={20}
              maxToRenderPerBatch={20}
              windowSize={11}
              removeClippedSubviews
              showsVerticalScrollIndicator={false}
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

export default BookSelector;