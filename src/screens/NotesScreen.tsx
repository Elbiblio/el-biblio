import React, { useEffect, useCallback, useState, useMemo } from 'react';
import { observer } from 'mobx-react-lite';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  FlatList,
  Platform,
  ActivityIndicator,
  StatusBar,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';

import {
  NotePencil,
  ArrowLeft,
  Filter,
  Search,
  Plus,
  ViewGrid,
  ViewList,
  Sparkle,
  Globe,
} from '../components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { type RootStackParamList, type AllVirtues, Note } from '@/types';
import NoteEditor from '@/components/NoteEditor';
import VirtuePicker from '@/components/VirtuePicker';
import { getNotePastel } from '@/utils/notes';
import { useNotesStore } from '@/stores/NotesStore';
import { toast } from 'sonner-native';
import NoteCard from '@/components/NoteCard';
import { useGuestRestrictions } from '@/hooks/useGuestRestrictions';
import GuestRestrictionModal from '@/components/GuestRestrictionModal';
import { useWebSocket } from '@/services/websocket';
import * as Haptics from 'expo-haptics';
import { RefreshControl } from 'react-native';
import EmptyState from '@/components/EmptyState';

export type NotesScreenProps = NativeStackScreenProps<RootStackParamList, 'NotesScreen'>;

const NotesScreen = ({ navigation, route }: NotesScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const navigationNative = useNavigation();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const {
    notes,
    isLoading,
    fetchNotes,
    createNote: addNote,
    updateNote,
    deleteNote,
    setFilters,
    resetFilters,
    pagination,
  } = useNotesStore();

  const [isInitialLoad, setIsInitialLoad] = useState(true);
  const [selectedVirtues, setSelectedVirtues] = useState<AllVirtues[]>([]);
  const [showVirtueSelector, setShowVirtueSelector] = useState(false);
  const [isGridView, setIsGridView] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeNote, setActiveNote] = useState<{
    note: Note | null;
    mode: 'read' | 'edit' | 'create' | null;
    isEditing: boolean;
  }>({ note: null, mode: null, isEditing: false });
  const [virtueFilter, setVirtueFilter] = useState<AllVirtues[]>([]);
  const [showPublicNotes, setShowPublicNotes] = useState(true);
  const [showFeaturedOnly, setShowFeaturedOnly] = useState(false);
  const [isSearchingCommunity, setIsSearchingCommunity] = useState(false);
  const [showRestrictionModal, setShowRestrictionModal] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const { restrictions } = useGuestRestrictions();
  const { isConnected } = useWebSocket();

  useEffect(() => {
    const initializeData = async () => {
      await fetchNotes(1);
      setIsInitialLoad(false);
    };

    initializeData();
  }, [fetchNotes]);

  useEffect(() => {
    fetchNotes(1);
  }, [fetchNotes]);

  // Handle load more
  const handleLoadMore = useCallback(() => {
    if (pagination.hasMore && !isLoading) {
      fetchNotes(pagination.currentPage + 1);
    }
  }, [pagination.hasMore, pagination.currentPage, isLoading, fetchNotes]);

  // Handle refresh
  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    try {
      await fetchNotes(1);
    } finally {
      setIsRefreshing(false);
    }
  }, [fetchNotes]);

  if (isInitialLoad) {
    return (
      <View style={[styles.container, styles.centerContent]}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  const filteredNotes = useMemo(() => {
    return notes.filter(note => {
      const matchesSearch = 
        searchQuery === '' || 
        (note.title && note.title.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (note.text && note.text.toLowerCase().includes(searchQuery.toLowerCase()));
      
      const matchesVirtues = 
        virtueFilter.length === 0 || 
        virtueFilter.every(v => note.virtues?.includes(v));
      
      // Filter based on visibility settings
      if (!showPublicNotes) {
        // Show only user's personal notes
        return matchesSearch && matchesVirtues && !note.is_public;
      } else {
        // Show only public/community notes
        const isPublicNote = note.is_public;
        const isFeatured = note.is_featured || false;
        
        if (showFeaturedOnly) {
          return matchesSearch && matchesVirtues && isPublicNote && isFeatured;
        } else {
          return matchesSearch && matchesVirtues && isPublicNote;
        }
      }
    });
  }, [notes, searchQuery, virtueFilter, showPublicNotes, showFeaturedOnly]);

  // Priority display: when in community mode and not filtering to featured only,
  // sort featured notes to the top.
  const prioritizedNotes = useMemo(() => {
    if (!showPublicNotes || showFeaturedOnly) return filteredNotes;
    const arr = [...filteredNotes];
    arr.sort((a, b) => Number(!!b.is_featured) - Number(!!a.is_featured));
    return arr;
  }, [filteredNotes, showPublicNotes, showFeaturedOnly]);

  const groupedNotes = useMemo(() => {
    if (showPublicNotes) {
      // No pinning concept for community notes in UI; just prioritized list
      return { pinned: [], unpinned: prioritizedNotes };
    }
    const pinned = filteredNotes.filter(note => note.isPinned);
    const unpinned = filteredNotes.filter(note => !note.isPinned);
    return { pinned, unpinned };
  }, [filteredNotes, prioritizedNotes, showPublicNotes]);

  const handleViewNote = useCallback((note: Note) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setActiveNote({
      note,
      mode: 'read',
      isEditing: false,
    });
    setSelectedVirtues(note.virtues || []);
  }, []);

  const handleCloseNote = useCallback(() => {
    setActiveNote({ note: null, mode: null, isEditing: false });
    setSelectedVirtues([]);
  }, []);

  const handleCreateNote = useCallback(() => {
    if (!restrictions.canPostNotes) {
      setShowRestrictionModal(true);
      return;
    }
    
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setActiveNote({
      note: null,
      mode: 'create',
      isEditing: true,
    });
    setSelectedVirtues([]);
  }, [restrictions.canPostNotes]);

  const handleSaveNote = useCallback(async ({ title, content, virtues }: {
    title: string;
    content: string;
    virtues: AllVirtues[];
  }) => {
    let result: Note | null;
    if (activeNote.mode === 'edit' && activeNote.note) {
      // Update existing note
      const success = await updateNote(activeNote.note.id, {
        title,
        text: content,
        virtues,
        is_public: activeNote.note.is_public
      });
      result = success ? activeNote.note : null;
    } else {
      // Create new note
      result = await addNote({
        title,
        text: content,
        virtues,
        is_public: false
      });
    }
    if (result) {
      handleCloseNote();
      toast.success("Note saved successfully");
    } else {
      toast.error("Error saving note");
    }
  }, [activeNote, updateNote, addNote]);

  const handleDeleteNote = useCallback(async (noteId: string) => {
    try {
      const success = await deleteNote(noteId);
      if (success) {
        handleCloseNote();
        toast.success("Note deleted successfully");
      } else {
        toast.error("Error deleting note");
      }
    } catch (error) {
      console.error('Error deleting note:', error);
      toast.error("Error deleting note");
    }
  }, [deleteNote, handleCloseNote]);

  const handleToggleVisibility = useCallback(async () => {
    if (activeNote.note) {
      const success = await updateNote(activeNote.note.id, {
        is_public: !activeNote.note.is_public
      });
      if (success) {
        setActiveNote(prev => ({
          ...prev,
          note: prev.note ? { ...prev.note, is_public: !prev.note.is_public } : null
        }));
      }
    }
  }, [activeNote, updateNote]);

  const renderItem = useCallback(({ item }: { item: Note }) => (
    <NoteCard
      note={item}
      styles={styles}
      isGridView={isGridView}
      onPress={handleViewNote}
    />
  ), [isGridView, handleViewNote]);

  const renderNoteEditor = useCallback(() => {
    if (!activeNote.note && !activeNote.isEditing) return null;
    
    return (
      <NoteEditor
        initialTitle={activeNote.note?.title || ''}
        initialContent={activeNote.note?.text || ''}
        initialVirtues={selectedVirtues}
        onSubmit={handleSaveNote}
        onCancel={handleCloseNote}
        onDelete={() => handleDeleteNote(activeNote.note?.id || '')}
        isEditing={activeNote.isEditing}
        isPublic={activeNote.note?.is_public || false}
        onToggleVisibility={handleToggleVisibility}
      />
    );
  }, [activeNote, selectedVirtues, handleSaveNote, handleCloseNote, handleDeleteNote, handleToggleVisibility]);

  const ListEmptyComponent = useCallback(() => {
    const hasFilters = !!searchQuery || virtueFilter.length > 0;
    return (
      <EmptyState
        title={hasFilters ? 'No notes found' : 'No notes yet'}
        message={hasFilters ? 'No notes match your current search or filters.' : 'Write your first note and begin your journey.'}
        ctaText={hasFilters ? 'Clear filters' : 'Create a note'}
        onPressCTA={hasFilters ? () => { setSearchQuery(''); setVirtueFilter([]); } : handleCreateNote}
        IconComponent={NotePencil as any}
      />
    );
  }, [searchQuery, virtueFilter, handleCreateNote]);

  const toggleCommunitySearch = useCallback(() => {
    // Clear search when switching modes
    setSearchQuery('');
    setIsSearchingCommunity(!isSearchingCommunity);
    
    // When enabling community search, make sure we're viewing public notes
    if (!isSearchingCommunity && !showPublicNotes) {
      setShowPublicNotes(true);
    }
  }, [isSearchingCommunity, showPublicNotes]);

  return (
    <>
      <StatusBar barStyle="dark-content" />
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigationNative.goBack()}>
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <View style={styles.titleContainer}>
            <Text style={styles.title}>
              {showPublicNotes ? 'Community Notes' : 'My Notes'}
            </Text>
            {isConnected && (
              <View style={styles.connectionIndicator}>
                <View style={[styles.connectionDot, { backgroundColor: theme.colors.success }]} />
                <Text style={styles.connectionText}>Live</Text>
              </View>
            )}
          </View>
          <View style={styles.headerActions}>
            <TouchableOpacity 
              style={[styles.visibilityToggle, showPublicNotes && styles.activeToggle]}
              onPress={() => {
                if (!showPublicNotes && !restrictions.canViewNotes) {
                  setShowRestrictionModal(true);
                  return;
                }
                
                setShowPublicNotes(!showPublicNotes);
                // Reset featured filter when switching between personal/community
                if (!showPublicNotes) {
                  setShowFeaturedOnly(false);
                }
                // Reset community search when switching to personal notes
                if (showPublicNotes && isSearchingCommunity) {
                  setIsSearchingCommunity(false);
                }
              }}
            >
              <Globe size={20} color={showPublicNotes ? theme.colors.text.inverse : theme.colors.text.secondary} />
            </TouchableOpacity>
            
            {showPublicNotes && (
              <TouchableOpacity 
                style={[styles.featuredToggle, showFeaturedOnly && styles.activeToggle]}
                onPress={() => setShowFeaturedOnly(!showFeaturedOnly)}
              >
                <Sparkle size={20} color={showFeaturedOnly ? theme.colors.text.inverse : theme.colors.text.secondary} />
              </TouchableOpacity>
            )}
            
            <TouchableOpacity onPress={() => setIsGridView(!isGridView)}>
              {isGridView ?
                <ViewGrid size={24} color={theme.colors.text.primary} /> :
                <ViewList size={24} color={theme.colors.text.primary} />
              }
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.searchContainer}>
          <View style={[
            styles.searchBar,
            isSearchingCommunity && styles.communitySearchBar
          ]}>
            <Search size={20} color={theme.colors.text.secondary} />
            <TextInput
              style={styles.searchInput}
              placeholder={isSearchingCommunity ? "Search community notes" : "Search notes"}
              placeholderTextColor={theme.colors.text.placeholder}
              value={searchQuery}
              onChangeText={setSearchQuery}
            />
            {isSearchingCommunity && (
              <View style={styles.communityBadge}>
                <Text style={styles.communityBadgeText}>Community</Text>
              </View>
            )}
          </View>
          
          <TouchableOpacity
            style={[
              styles.filterButton,
              virtueFilter.length > 0 && styles.activeFilter
            ]}
            onPress={() => setShowVirtueSelector(!showVirtueSelector)}
          >
            <Filter size={20} color={virtueFilter.length > 0 ? theme.colors.text.inverse : theme.colors.text.secondary} />
          </TouchableOpacity>
          
          <TouchableOpacity
            style={[
              styles.searchModeButton,
              isSearchingCommunity && styles.activeSearchMode
            ]}
            onPress={toggleCommunitySearch}
          >
            <Globe size={20} color={isSearchingCommunity ? theme.colors.text.inverse : theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>

        <FlatList
          data={groupedNotes.unpinned}
          renderItem={renderItem}
          keyExtractor={item => item.id.toString()}
          numColumns={isGridView ? 2 : 1}
          contentContainerStyle={styles.listContent}
          refreshControl={
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={handleRefresh}
              colors={[theme.colors.primary]}
              tintColor={theme.colors.primary}
            />
          }
          onEndReached={handleLoadMore}
          onEndReachedThreshold={0.5}
          ListHeaderComponent={() => (
            <>
              {showPublicNotes && (
                <View style={styles.communityHeader}>
                  <Text style={styles.sectionTitle}>
                    {showFeaturedOnly ? 'Featured Community Notes' : 'All Community Notes'}
                  </Text>
                  {!isSearchingCommunity && (
                    <TouchableOpacity 
                      style={styles.searchCommunityButton}
                      onPress={toggleCommunitySearch}
                    >
                      <Search size={16} color={theme.colors.primary} />
                      <Text style={styles.searchCommunityButtonText}>
                        Search Community
                      </Text>
                    </TouchableOpacity>
                  )}
                </View>
              )}
              
              {!showPublicNotes && groupedNotes.pinned.length > 0 && (
                <>
                  <Text style={styles.sectionTitle}>Pinned</Text>
                  <FlatList
                    data={groupedNotes.pinned}
                    renderItem={renderItem}
                    keyExtractor={item => item.id.toString()}
                    numColumns={isGridView ? 2 : 1}
                    scrollEnabled={false}
                  />
                  <Text style={[styles.sectionTitle, { marginTop: theme.spacing.lg }]}>
                    All Notes
                  </Text>
                </>
              )}
            </>
          )}
          ListEmptyComponent={ListEmptyComponent}
          ListFooterComponent={
            isLoading && pagination.currentPage > 1 ? (
              <View style={styles.loadingMoreContainer}>
                <ActivityIndicator size="small" color={theme.colors.primary} />
                <Text style={styles.loadingMoreText}>Loading more notes...</Text>
              </View>
            ) : null
          }
          showsVerticalScrollIndicator={false}
          key={isGridView ? 'grid' : 'list'}
        />

        {!showPublicNotes && (
          <TouchableOpacity
            style={styles.addButton}
            onPress={handleCreateNote}
          >
            <Plus size={24} color={theme.colors.text.inverse} />
          </TouchableOpacity>
        )}
      </View>

      {renderNoteEditor()}

      {showVirtueSelector && (
        <VirtuePicker
          selectedVirtues={activeNote.note ? selectedVirtues : virtueFilter}
          onVirtueSelect={(virtue) => {
            if (activeNote.note) {
              setSelectedVirtues(prev =>
                prev.includes(virtue)
                  ? prev.filter(v => v !== virtue)
                  : [...prev, virtue]
              );
            } else {
              setVirtueFilter(prev =>
                prev.includes(virtue)
                  ? prev.filter(v => v !== virtue)
                  : [...prev, virtue]
              );
            }
          }}
          onClose={() => setShowVirtueSelector(false)}
        />
      )}

      <GuestRestrictionModal
        visible={showRestrictionModal}
        onClose={() => setShowRestrictionModal(false)}
        feature="creating notes"
      />
    </>
  );
};

export const createStyles = (theme: Theme) => StyleSheet.create({
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
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  connectionIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  connectionDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  connectionText: {
    ...theme.typography.caption.secondary,
    fontSize: 10,
    fontWeight: '600',
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  searchBar: {
    flex: 1,
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
  filterButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activeFilter: {
    backgroundColor: theme.colors.primary,
  },
  visibilityToggle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme.spacing.xs,
  },
  activeToggle: {
    backgroundColor: theme.colors.primary,
  },
  listContent: {
    padding: theme.spacing.md,
    paddingBottom: 80, // Space for FAB
  },
  noteCard: {
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    marginBottom: theme.spacing.md,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  gridCard: {
    flex: 1,
    margin: theme.spacing.xs,
    minHeight: 200,
  },
  listCard: {
    marginBottom: theme.spacing.md,
  },
  noteContent: {
    padding: theme.spacing.md,
  },
  pinnedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: `${theme.colors.primary}15`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    marginBottom: theme.spacing.xs,
    gap: 4,
  },
  pinnedText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.primary,
    fontSize: 12,
    fontWeight: '600',
  },
  noteTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
    fontSize: 16,
  },
  noteText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  virtueContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.xs,
    marginTop: 'auto',
  },
  virtueBadge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
  },
  virtueText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
  },
  moreVirtues: {
    ...theme.typography.caption.secondary,
    verticalAlign: 'middle',
    color: theme.colors.text.secondary,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.xl,
    marginTop: theme.spacing.xl * 2,
  },
  emptyStateText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.md,
    lineHeight: 24,
  },
  addButton: {
    position: 'absolute',
    right: theme.spacing.lg,
    bottom: theme.spacing.lg,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: theme.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 100,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.primary,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 8,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  timestamp: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 12,
    marginTop: theme.spacing.xs,
  },
  modalContainer: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContent: {
    flex: 1,
    backgroundColor: theme.colors.background,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    padding: theme.spacing.lg,
    marginTop: 'auto',
  },
  centerContent: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  communityHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  searchCommunityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: `${theme.colors.primary}15`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    gap: 4,
  },
  searchCommunityButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 12,
  },
  communitySearchBar: {
    borderWidth: 1,
    borderColor: theme.colors.primary,
  },
  communityBadge: {
    backgroundColor: `${theme.colors.primary}15`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 2,
    borderRadius: theme.borderRadius.full,
    marginLeft: 'auto',
  },
  communityBadgeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontSize: 10,
  },
  featuredToggle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme.spacing.xs,
  },
  searchModeButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activeSearchMode: {
    backgroundColor: theme.colors.primary,
  },
  loadingMoreContainer: {
    padding: theme.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingMoreText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.sm,
  },
});

export default observer(NotesScreen);