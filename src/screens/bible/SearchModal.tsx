import React, { useCallback, useMemo } from 'react';
import { View, Text, TextInput, TouchableOpacity, Modal, FlatList, ActivityIndicator, KeyboardAvoidingView, Platform } from 'react-native';
import { MaterialIcons } from '@expo/vector-icons';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import { useBibleStore } from '@/stores/BibleStore';
import { bibleBooks } from '@/constants/bibleBooks';
import { parseVPLId } from '@/utils/database';
import { createBibleStyles } from './styles';

interface SearchModalProps {
  visible: boolean;
  onClose: () => void;
  onSearch: (query: string) => void;
}

export const SearchModal = observer(({ visible, onClose, onSearch }: SearchModalProps) => {
  const theme = useTheme();
  const styles = useMemo(() => createBibleStyles(theme), [theme]);
  const bibleStore = useBibleStore();

  const handleSavedSearchSelect = useCallback((term: string) => {
    bibleStore.setSearchQuery(term);
    onSearch(term);
  }, [bibleStore, onSearch]);

  const handleRemoveSavedSearch = useCallback((term: string) => {
    bibleStore.removeSavedSearch(term);
  }, [bibleStore]);

  const handleResultPress = useCallback((item: any) => {
    const { bookAbbr, chapter } = parseVPLId(item.id);
    const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
    if (book) {
      bibleStore.setCurrentBook(book);
      bibleStore.setCurrentChapter(chapter);
      bibleStore.setShowSearch(false);
      bibleStore.clearSearch();
    }
  }, [bibleStore]);

  const renderItem = useCallback(
    ({ item }: { item: { id: string; reference: string; text: string } }) => (
      <TouchableOpacity style={styles.searchResultItem} onPress={() => handleResultPress(item)}>
        <Text style={styles.searchResultReference}>{item.reference}</Text>
        <Text style={styles.searchResultText}>{item.text}</Text>
      </TouchableOpacity>
    ),
    [styles.searchResultItem, styles.searchResultReference, styles.searchResultText, handleResultPress]
  );

  const ListHeader = useMemo(
    () =>
      bibleStore.savedSearches.length
        ? (
          <View style={styles.savedSearchContainer}>
            <View style={styles.savedSearchHeader}>
              <Text style={styles.savedSearchTitle}>Recent searches</Text>
              <TouchableOpacity onPress={() => bibleStore.clearSavedSearches()}>
                <Text style={styles.clearSavedSearchText}>Clear</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.savedSearchChips}>
              {bibleStore.savedSearches.map(term => (
                <View key={term} style={styles.savedSearchChip}>
                  <TouchableOpacity onPress={() => handleSavedSearchSelect(term)}>
                    <Text style={styles.savedSearchText}>{term}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => handleRemoveSavedSearch(term)}>
                    <MaterialIcons name="close" size={14} color={theme.colors.text.secondary} />
                  </TouchableOpacity>
                </View>
              ))}
            </View>
          </View>
        )
        : null,
    [
      bibleStore.savedSearches,
      bibleStore.clearSavedSearches,
      theme.colors.text.secondary,
      styles.savedSearchContainer,
      styles.savedSearchHeader,
      styles.savedSearchTitle,
      styles.clearSavedSearchText,
      styles.savedSearchChips,
      styles.savedSearchChip,
      styles.savedSearchText,
      handleSavedSearchSelect,
      handleRemoveSavedSearch,
    ]
  );

  const ListEmpty = useMemo(
    () =>
      bibleStore.isSearchLoading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
        </View>
      ) : (
        <View style={styles.emptySearchContainer}>
          <MaterialIcons name="search" size={32} color={theme.colors.text.secondary} />
          <Text style={styles.emptySearchText}>Start typing to search across the Bible.</Text>
        </View>
      ),
    [
      bibleStore.isSearchLoading,
      theme.colors.primary,
      theme.colors.text.secondary,
      styles.loadingContainer,
      styles.emptySearchContainer,
      styles.emptySearchText,
    ]
  );

  const keyExtractor = useCallback((item: { id: string }) => item.id, []);

  return (
    <Modal visible={visible} animationType="slide" onRequestClose={onClose}>
      <KeyboardAvoidingView
        style={styles.searchContainer}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={0}
      >
        <View style={styles.searchHeader}>
          <TextInput
            style={styles.searchInput}
            value={bibleStore.searchQuery}
            onChangeText={onSearch}
            placeholder="Search Bible..."
            autoFocus
          />
          <TouchableOpacity
            style={styles.closeButton}
            onPress={() => {
              bibleStore.setShowSearch(false);
              bibleStore.clearSearch();
            }}
          >
            <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>

        <FlatList
          data={bibleStore.searchResults}
          ListHeaderComponent={ListHeader}
          renderItem={renderItem}
          keyExtractor={keyExtractor}
          ListEmptyComponent={ListEmpty}
        />
      </KeyboardAvoidingView>
    </Modal>
  );
});
