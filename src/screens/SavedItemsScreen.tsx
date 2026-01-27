import { Heart, HomeLight, Crown, Brain, MessageCircle, BookOpen, NotePencil, Scroll, BookmarkSimple, ArrowLeft, Sparkle, Search, X, IconProps, Clock, Filter } from "@/components/Icons";
import { useTheme } from "@/contexts/ThemeContext";
import { Theme } from "@/theme";
import { User, RootStackParamList, SavedItemType, FoundationalVirtue, SavedItem, SavedItemsFilter, Bookmark } from "@/types";
import { formatRelativeTime } from "@/utils/schedule";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { BlurView } from "expo-blur";
import React, { useState, useEffect, useMemo, useCallback } from "react";
import { View, StyleSheet, Text, Image, TouchableOpacity, TextInput, SectionList, Modal } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useBookmarkStore, useVerseStore, useReflectionStore } from '@/stores/StoreProvider';
import { observer } from 'mobx-react-lite';

import { toast } from "sonner-native";
import EmptyState from '@/components/EmptyState';

const SavedItemsScreen = ({
  navigation
}: NativeStackScreenProps<RootStackParamList, 'SavedItemsScreen'>) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { bookmarks, isLoading, fetchBookmarks, togglePin, deleteBookmark } = useBookmarkStore();
  const safeBookmarks: Bookmark[] = Array.isArray(bookmarks) ? bookmarks : [];
  const { fetchVerseOnly } = useVerseStore();
    const { fetchReflectionById } = useReflectionStore();

  // States
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<SavedItemsFilter>({});
  const [activeTab, setActiveTab] = useState<SavedItemType | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  const [pinnedItems, setPinnedItems] = useState<Bookmark[]>([]);

  // Filter options
  const THEME_OPTIONS: { value: FoundationalVirtue; label: string; Icon: React.FC<IconProps>; color: string }[] = [
    { value: 'love', label: 'Love', Icon: Heart, color: theme.colors.like },
    { value: 'faith', label: 'Faith', Icon: HomeLight, color: theme.colors.primary },
    { value: 'humility', label: 'Humility', Icon: Crown, color: theme.colors.primaryDark },
    { value: 'knowledge', label: 'Knowledge', Icon: Brain, color: theme.colors.secondary },
  ];

  const TYPE_TABS: { value: SavedItemType; label: string; Icon: React.FC<IconProps> }[] = [
    { value: 'clip', label: 'Clips', Icon: MessageCircle },
    { value: 'reflection', label: 'Reflections', Icon: BookOpen },
    { value: 'note', label: 'Notes', Icon: NotePencil },
    { value: 'verse', label: 'Verses', Icon: Scroll },
  ];

  useEffect(() => {
    loadBookmarks();
  }, []);

  useEffect(() => {
    setPinnedItems(safeBookmarks.filter(item => item.is_pinned));
  }, [safeBookmarks]);

  const loadBookmarks = async () => {
    await fetchBookmarks({
      include: ['bookmarkable', 'bookmarkable.author'],
      sort: '-created_at',
      per_page: 50
    });
  };

  const handlePin = async (id: number) => {
    await togglePin(id);
  };

  const handleDelete = async (id: number) => {
    await deleteBookmark(id);
  };

  const handleSearch = (text: string) => {
    setSearchQuery(text);
    setFilters(prev => ({ ...prev, searchQuery: text }));
  };

  const handleItemPress = async (bookmarkable: NonNullable<Bookmark['bookmarkable']>) => {
    try {
      switch (bookmarkable.type) {
        case 'verse': {
          const verse = await fetchVerseOnly(bookmarkable.id.toString(10));
          if (verse) {
            navigation.navigate('VerseDetail', { verse });
          }
          break;
        }

        case 'reflection': {
                    const reflection = await fetchReflectionById(bookmarkable.id.toString(10));
          if (reflection) {
            navigation.navigate('ReflectionDetail', { reflection });
          }
          break;
        }
        case 'note':
          navigation.navigate('NoteDetail', { noteId: bookmarkable.id });
          break;
        case 'clip':
          toast.info('Clip view is not available yet');
          break;
      }
    } catch (error) {
      console.error('Navigation error:', error);
      toast.error('Failed to load item');
    }
  };

  const filteredItems = useMemo(() => {
    return safeBookmarks.filter(item => {
      // Type filter
      if (activeTab && item.bookmarkable?.type !== activeTab) return false;

      // Theme filter
      if (filters.theme && item.bookmarkable?.theme !== filters.theme) return false;

      // Date range filter
      if (filters.dateRange) {
        const itemDate = new Date(item.created_at);
        if (
          itemDate < filters.dateRange.start ||
          itemDate > filters.dateRange.end
        ) return false;
      }

      // Search query
      if (filters.searchQuery) {
        const query = filters.searchQuery.toLowerCase();
        const searchableContent = `${item.bookmarkable?.content || ''} ${item.bookmarkable?.reference || ''} ${item.bookmarkable?.author?.first_name || ''} ${item.bookmarkable?.author?.last_name || ''}`.toLowerCase();
        if (!searchableContent.includes(query)) return false;
      }

      //exclude pinned items
      return activeTab ? true : !item.is_pinned;
    });
  }, [safeBookmarks, activeTab, filters]);

  const sections = useMemo(() => {
    const out: { title: string; data: Bookmark[] }[] = [];
    if (!activeTab && pinnedItems.length > 0) {
      out.push({ title: 'Pinned', data: pinnedItems });
    }
    if (filteredItems.length > 0) {
      const title = activeTab ? activeTab.charAt(0).toUpperCase() + activeTab.slice(1) + 's' : 'Saved Items';
      out.push({ title, data: filteredItems });
    }
    return out;
  }, [activeTab, pinnedItems, filteredItems]);

  const renderItem = useCallback(({ item }: { item: Bookmark }) => {
    const bookmarkable = item.bookmarkable;
    if (!bookmarkable) return null;

    const themeOption = THEME_OPTIONS.find(t => t.value === bookmarkable.theme);
    const ThemeIcon = themeOption?.Icon;
    const themeColor = themeOption?.color;
    const TypeIcon = TYPE_TABS.find(t => t.value === bookmarkable.type)?.Icon;

    return (
      <TouchableOpacity
        key={item.id}
        style={styles.itemCard}
        onPress={() => handleItemPress(bookmarkable)}
      >
        <BlurView intensity={10} style={StyleSheet.absoluteFill} />
        <View style={styles.itemContent}>
          {/* Header: Type, Theme, and Pin */}
          <View style={styles.itemHeader}>
            <View style={styles.headerLeft}>
              {/* Type Badge */}
              <View style={[styles.typeBadge, { backgroundColor: theme.colors.surface }]}>
                {TypeIcon && <TypeIcon size={14} color={theme.colors.text.secondary} />}
                <Text style={styles.typeText}>
                  {bookmarkable.type.charAt(0).toUpperCase() + bookmarkable.type.slice(1)}
                </Text>
              </View>

              {/* Theme Badge */}
              {bookmarkable.theme && ThemeIcon && (
                <View style={[
                  styles.themeBadge,
                  { backgroundColor: `${themeColor}15` }
                ]}>
                  <ThemeIcon size={12} color={themeColor} />
                  <Text style={[styles.themeBadgeText, { color: themeColor }]}>
                    {bookmarkable.theme.charAt(0).toUpperCase() + bookmarkable.theme.slice(1)}
                  </Text>
                </View>
              )}
            </View>

            {/* Pin Button */}
            <TouchableOpacity
              style={styles.pinButton}
              onPress={() => handlePin(item.id)}
              hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
            >
              <BookmarkSimple
                size={20}
                color={item.is_pinned ? theme.colors.primary : theme.colors.text.secondary}
                filled={item.is_pinned}
              />
            </TouchableOpacity>
          </View>

          {/* Main Content */}
          <View style={styles.mainContent}>
            {/* Reference for verses */}
            {bookmarkable.type === 'verse' && bookmarkable.reference && (
              <Text style={styles.verseReference}>
                {bookmarkable.reference}
              </Text>
            )}

            {/* Content */}
            <Text
              style={[
                styles.itemText,
                bookmarkable.type === 'verse' && styles.verseText
              ]}
              numberOfLines={3}
            >
              {bookmarkable.content}
            </Text>

            {/* Context Badge */}
            {bookmarkable.context && (
              <View style={styles.contextBadge}>
                <MessageCircle size={12} color={theme.colors.text.secondary} />
                <Text style={styles.contextText}>{bookmarkable.context}</Text>
              </View>
            )}
          </View>

          {/* Footer */}
          <View style={styles.itemFooter}>
            {/* Author Info - for clips and reflections */}
            {bookmarkable.author && (
              <View style={styles.authorInfo}>
                <Image
                  source={{ uri: bookmarkable.author.avatar }}
                  style={styles.authorAvatar}
                />
                <Text style={styles.authorName}>
                  {`${bookmarkable.author.first_name} ${bookmarkable.author.last_name}`}
                </Text>
              </View>
            )}

            {/* Save Time */}
            <View style={styles.timeContainer}>
              <Clock size={12} color={theme.colors.text.secondary} />
              <Text style={styles.savedTime}>
                {formatRelativeTime(item.created_at)}
              </Text>
            </View>
          </View>
        </View>
      </TouchableOpacity>
    );
  }, [theme, styles, handleItemPress, handlePin, THEME_OPTIONS, TYPE_TABS]);

  const keyExtractor = useCallback((item: Bookmark) => String(item.id), []);

  const renderSectionHeader = useCallback(
    ({ section }: { section: { title: string } }) => (
      <View style={styles.pinnedSection}>
        <Text style={styles.sectionTitle}>{section.title}</Text>
      </View>
    ),
    [styles]
  );

  const ListEmpty = useCallback(() => {
    if (isLoading) {
      return (
        <View style={[styles.pinnedSection, { alignItems: 'center' }]}>
          <Text style={styles.sectionTitle}>Loading saved items...</Text>
        </View>
      );
    }
    if (safeBookmarks.length === 0) {
      return (
        <EmptyState
          title="No saved items yet"
          message="Bookmark verses, reflections, and notes to see them here."
          ctaText="Browse community"
          onPressCTA={() => navigation.navigate('CommunityScreen')}
        />
      );
    }
    return (
      <EmptyState
        title="No results"
        message="Try clearing filters or selecting a different type."
        ctaText="Reset filters"
        onPressCTA={() => setFilters({})}
      />
    );
  }, [isLoading, safeBookmarks.length, styles, navigation]);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Saved Items</Text>
        <TouchableOpacity onPress={() => setShowFilters(true)}>
          <Filter size={24} color={theme.colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <View style={styles.searchBar}>
          <Search size={20} color={theme.colors.text.secondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search saved items"
            value={searchQuery}
            onChangeText={handleSearch}
          />
        </View>
      </View>

      {/* Type Tabs */}
      <View style={styles.tabsContainer}>
        {TYPE_TABS.map(tab => (
          <TouchableOpacity
            key={tab.value}
            style={[
              styles.tab,
              activeTab === tab.value && styles.activeTab
            ]}
            onPress={() => {
              if (activeTab === tab.value) {
                setActiveTab(null);
              } else {
                setActiveTab(tab.value);
              }
            }}
          >
            <tab.Icon
              size={16}
              color={activeTab === tab.value ? theme.colors.text.inverse : theme.colors.text.secondary}
            />
            <Text style={[
              styles.tabText,
              activeTab === tab.value && styles.activeTabText
            ]}>
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Main Content */}
      <SectionList
        sections={sections}
        renderItem={renderItem}
        renderSectionHeader={renderSectionHeader}
        keyExtractor={keyExtractor}
        ListEmptyComponent={ListEmpty}
        stickySectionHeadersEnabled={false}
        style={styles.content}
        contentContainerStyle={sections.length === 0 ? { flexGrow: 1 } : undefined}
        showsVerticalScrollIndicator={false}
        windowSize={7}
        maxToRenderPerBatch={10}
      />

      {/* Filter Modal */}
      <Modal
        visible={showFilters}
        transparent
        animationType="slide"
        onRequestClose={() => setShowFilters(false)}
      >
        <BlurView intensity={20} style={styles.modalOverlay} pointerEvents="none">
          <View style={styles.filterModal}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Filters</Text>
              <TouchableOpacity
                onPress={() => setShowFilters(false)}
              >
                <X size={24} color={theme.colors.text.primary} />
              </TouchableOpacity>
            </View>

            {/* Theme Filter */}
            <View style={styles.filterSection}>
              <Text style={styles.filterTitle}>Theme</Text>
              <View style={styles.themeGrid}>
                {THEME_OPTIONS.map(themeOption => (
                  <TouchableOpacity
                    key={themeOption.value}
                    style={[
                      styles.themeOption,
                      filters.theme === themeOption.value && {
                        backgroundColor: `${themeOption.color}15`
                      }
                    ]}
                    onPress={() => setFilters(prev => ({
                      ...prev,
                      theme: prev.theme === themeOption.value ? undefined : themeOption.value
                    }))}
                  >
                    <themeOption.Icon
                      size={16}
                      color={themeOption.color}
                    />
                    <Text style={[
                      styles.themeOptionText,
                      { color: themeOption.color }
                    ]}>
                      {themeOption.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>

            {/* Date Range Filter */}
            <View style={styles.filterSection}>
              <Text style={styles.filterTitle}>Date Range</Text>
              {/* Add date range picker component here */}
            </View>

            {/* Filter Actions */}
            <View style={styles.filterActions}>
              <TouchableOpacity
                style={styles.resetButton}
                onPress={() => setFilters({})}
              >
                <Text style={styles.resetButtonText}>Reset</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.applyButton}
                onPress={() => setShowFilters(false)}
              >
                <Text style={styles.applyButtonText}>Apply Filters</Text>
              </TouchableOpacity>
            </View>
          </View>
        </BlurView>
      </Modal>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  searchContainer: {
    padding: theme.spacing.md,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.md,
    height: 40,
  },
  searchInput: {
    flex: 1,
    marginLeft: theme.spacing.sm,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  tabsContainer: {
    paddingHorizontal: theme.spacing.md,
    maxHeight: 50
  },
  tab: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    marginRight: theme.spacing.sm,
    gap: theme.spacing.xs,
  },
  activeTab: {
    backgroundColor: theme.colors.primary,
  },
  tabText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  activeTabText: {
    color: theme.colors.text.inverse,
  },
  content: {
    flex: 1,
    padding: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  referenceText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  
  itemCard: {
    borderRadius: theme.borderRadius.lg,
    marginBottom: theme.spacing.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    overflow: 'hidden',
  },
  itemContent: {
    padding: theme.spacing.md,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  typeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    gap: 4,
  },
  typeText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
    color: theme.colors.text.secondary,
  },
  themeBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    gap: 4,
  },
  themeBadgeText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
  },
  mainContent: {
    gap: theme.spacing.xs,
  },
  verseReference: {
    ...theme.typography.verse.emphasis,
    color: theme.colors.primary,
    fontSize: 14,
    marginBottom: theme.spacing.xs,
  },
  itemText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontSize: 15,
    lineHeight: 22,
  },
  verseText: {
    ...theme.typography.verse.regular,
    fontSize: 16,
    lineHeight: 24,
  },
  contextBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    gap: 4,
    marginTop: theme.spacing.xs,
  },
  contextText: {
    ...theme.typography.caption.secondary,
    fontSize: 12,
    color: theme.colors.text.secondary,
  },
  itemFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: theme.spacing.md,
    paddingTop: theme.spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme.colors.border,
  },
  authorInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  authorAvatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: theme.colors.surface,
  },
  authorName: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  timeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  savedTime: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
  },
  pinButton: {
    padding: 4,
  },
  itemActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  filterModal: {
    backgroundColor: theme.colors.background,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.lg,
  },
  modalTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
  },
  filterSection: {
    marginBottom: theme.spacing.lg,
  },
  filterTitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  themeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
  },
  themeOption: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    gap: theme.spacing.xs,
  },
  themeOptionText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
  },
  filterActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: theme.spacing.md,
    marginTop: theme.spacing.lg,
  },
  resetButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
  },
  resetButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  applyButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
  },
  applyButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  pinnedSection: {
    marginBottom: theme.spacing.xl,
  },
  allItemsSection: {
    flex: 1,
  }
});

export default observer(SavedItemsScreen);