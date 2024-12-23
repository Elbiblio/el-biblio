import { Heart, HomeLight, Crown, Brain, MessageCircle, BookOpen, NotePencil, Scroll, BookmarkSimple, ArrowLeft, Sparkle, Search, X, IconProps, Clock, Filter } from "@/components/Icons";
import { useTheme } from "@/contexts/ThemeContext";
import { Theme } from "@/theme";
import { User, RootStackParamList, SavedItemType, FoundationalVirtue, SavedItem, SavedItemsFilter } from "@/types";
import { formatRelativeTime } from "@/utils/schedule";
import { NativeStackScreenProps } from "@react-navigation/native-stack";
import { BlurView } from "expo-blur";
import React, { useState, useEffect, useMemo } from "react";
import { View, StyleSheet, Text, Image, TouchableOpacity, TextInput, ScrollView, Modal } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

const sampleSavedItems: SavedItem[] = [
  {
    id: '1',
    type: 'clip',
    content: "That's a profound observation about how faith and works complement each other. I hadn't considered that perspective before.",
    theme: 'faith',
    isPinned: true,
    savedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    author: {
      id: 'user1',
      first_name: 'Sarah',
      last_name: 'Mitchell',
      avatar: 'https://placehold.co/40x40'
    },
    context: 'Faith Discussion Hub'
  },
  {
    id: '2',
    type: 'verse',
    content: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.",
    reference: "Isaiah 40:31",
    theme: 'faith',
    isPinned: true,
    savedAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: '3',
    type: 'reflection',
    content: "Today's verse reminds me that humility isn't about thinking less of yourself, but thinking of yourself less. It's about creating space for others to grow and flourish.",
    theme: 'humility',
    isPinned: false,
    savedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    author: {
      id: 'user2',
      first_name: 'John',
      last_name: 'Doe',
      avatar: 'https://placehold.co/40x40'
    },
  },
  {
    id: '4',
    type: 'note',
    content: "Key insights from today's study:\n- Love is patient (makrothumia) - long-suffering, enduring\n- Love is kind (chresteuomai) - actively beneficial to others\n- These are actions, not just feelings",
    theme: 'love',
    isPinned: false,
    savedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
  }
];

const SavedItemsScreen: React.FC<NativeStackScreenProps<RootStackParamList, 'SavedItemsScreen'>> = ({
  navigation
}) => {
  const theme: Theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // States
  const [items, setItems] = useState<SavedItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<SavedItemsFilter>({});
  const [activeTab, setActiveTab] = useState<SavedItem['type'] | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [pinnedItems, setPinnedItems] = useState<SavedItem[]>([]);

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
    loadSavedItems();
  }, []);

  const loadSavedItems = async () => {
    try {
      setIsLoading(true);
      // API call to fetch saved items
      // For now using sample data
      setItems(sampleSavedItems);
      setPinnedItems(sampleSavedItems.filter(item => item.isPinned));
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSearch = (text: string) => {
    setSearchQuery(text);
    setFilters(prev => ({ ...prev, searchQuery: text }));
  };

  const handlePin = async (itemId: string) => {
    try {
      // API call to toggle pin status
      setItems(prev => prev.map(item =>
        item.id === itemId ? { ...item, isPinned: !item.isPinned } : item
      ));
      await loadSavedItems(); // Refresh list to update pinned section
    } catch (error) {
      console.error(error);
    }
  };

  const filteredItems = useMemo(() => {
    return items.filter(item => {
      // Type filter
      if (activeTab && item.type !== activeTab) return false;

      // Theme filter
      if (filters.theme && item.theme !== filters.theme) return false;

      // Date range filter
      if (filters.dateRange) {
        const itemDate = new Date(item.savedAt);
        if (
          itemDate < filters.dateRange.start ||
          itemDate > filters.dateRange.end
        ) return false;
      }

      // Search query
      if (filters.searchQuery) {
        const query = filters.searchQuery.toLowerCase();
        const searchableContent = `${item.content} ${item.reference || ''} ${item.author?.first_name || ''} ${item.author?.last_name || ''}`.toLowerCase();
        if (!searchableContent.includes(query)) return false;
      }

      //exclude pinned items
      return activeTab ? true : !item.isPinned;
    });
  }, [items, activeTab, filters]);

  const renderItem = ({ item }: { item: SavedItem }) => {
    // Find theme option once instead of multiple times
    const themeOption = THEME_OPTIONS.find(t => t.value === item.theme);
    const ThemeIcon = themeOption?.Icon;
    const themeColor = themeOption?.color;

    // Get type-specific icon
    const TypeIcon = TYPE_TABS.find(t => t.value === item.type)?.Icon;

    return (
      <TouchableOpacity
        key={item.id}
        style={styles.itemCard}
        onPress={() => {
          // Handle item press based on type
          switch (item.type) {
            case 'clip':
              // Navigate to original message/context
              break;
            case 'reflection':
              // Navigate to reflection detail
              break;
            case 'verse':
              // Show verse detail modal
              break;
            case 'note':
              // Show note detail/editor
              break;
          }
        }}
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
                  {item.type.charAt(0).toUpperCase() + item.type.slice(1)}
                </Text>
              </View>

              {/* Theme Badge */}
              {item.theme && ThemeIcon && (
                <View style={[
                  styles.themeBadge,
                  { backgroundColor: `${themeColor}15` }
                ]}>
                  <ThemeIcon size={12} color={themeColor} />
                  <Text style={[styles.themeBadgeText, { color: themeColor }]}>
                    {item.theme.charAt(0).toUpperCase() + item.theme.slice(1)}
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
                color={item.isPinned ? theme.colors.primary : theme.colors.text.secondary}
                filled={item.isPinned}
              />
            </TouchableOpacity>
          </View>

          {/* Main Content */}
          <View style={styles.mainContent}>
            {/* Reference for verses */}
            {item.type === 'verse' && item.reference && (
              <Text style={styles.verseReference}>
                {item.reference}
              </Text>
            )}

            {/* Content */}
            <Text
              style={[
                styles.itemText,
                item.type === 'verse' && styles.verseText
              ]}
              numberOfLines={3}
            >
              {item.content}
            </Text>

            {/* Context Badge */}
            {item.context && (
              <View style={styles.contextBadge}>
                <MessageCircle size={12} color={theme.colors.text.secondary} />
                <Text style={styles.contextText}>{item.context}</Text>
              </View>
            )}
          </View>

          {/* Footer */}
          <View style={styles.itemFooter}>
            {/* Author Info - for clips and reflections */}
            {item.author && (
              <View style={styles.authorInfo}>
                <Image
                  source={{ uri: item.author.avatar }}
                  style={styles.authorAvatar}
                />
                <Text style={styles.authorName}>
                  {`${item.author.first_name} ${item.author.last_name}`}
                </Text>
              </View>
            )}

            {/* Save Time */}
            <View style={styles.timeContainer}>
              <Clock size={12} color={theme.colors.text.secondary} />
              <Text style={styles.savedTime}>
                {formatRelativeTime(item.savedAt)}
              </Text>
            </View>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

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
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.tabsContainer}
      >
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
      </ScrollView>

      {/* Main Content */}
      <ScrollView
        style={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Pinned Items */}
        {!activeTab && pinnedItems.length > 0 && (
          <View style={styles.pinnedSection}>
            <Text style={styles.sectionTitle}>Pinned</Text>
            {pinnedItems.map(item => renderItem({ item }))}
          </View>
        )}

        {/* All Items */}
        <View style={styles.allItemsSection}>
          <Text style={styles.sectionTitle}>{activeTab ? activeTab.charAt(0).toUpperCase() + activeTab.slice(1) + 's' : 'Saved Items'}</Text>
          {filteredItems.map(item => renderItem({ item }))}
        </View>
      </ScrollView>

      {/* Filter Modal */}
      <Modal
        visible={showFilters}
        transparent
        animationType="slide"
        onRequestClose={() => setShowFilters(false)}
      >
        <BlurView intensity={20} style={styles.modalOverlay}>
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


export default SavedItemsScreen;