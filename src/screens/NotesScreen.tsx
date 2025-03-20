import React, { useState, useCallback, useEffect, memo, useMemo } from 'react';
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
import { useNoteStore } from '@/stores/notes';
import { toast } from 'sonner-native';
import NoteCard from '@/components/NoteCard';

export type NotesScreenProps = NativeStackScreenProps<RootStackParamList, 'NotesScreen'>;

const NotesScreen: React.FC<NotesScreenProps> = ({ navigation, route }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const navigationNative = useNavigation();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const {
    notes,
    isLoading,
    fetchNotes,
    addNote,
    updateNote,
    deleteNote,
    togglePin,
    initialize,
    syncNotes
  } = useNoteStore();

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
  const [showPublicNotes, setShowPublicNotes] = useState(false);
  const [showFeaturedOnly, setShowFeaturedOnly] = useState(false);
  const [isSearchingCommunity, setIsSearchingCommunity] = useState(false);

  useEffect(() => {
    const initializeData = async () => {
      await initialize();
      setIsInitialLoad(false);
    };

    initializeData();
  }, [initialize]);

  useEffect(() => {
    fetchNotes({ include: ['virtues'] });
  }, [fetchNotes]);

  useEffect(() => {
    const syncInterval = setInterval(syncNotes, 1000 * 60 * 5); // 5 minutes
    return () => clearInterval(syncInterval);
  }, [syncNotes]);

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
        note.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        note.text.toLowerCase().includes(searchQuery.toLowerCase());
      
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

  const groupedNotes = useMemo(() => {
    const pinned = filteredNotes.filter(note => note.isPinned);
    const unpinned = filteredNotes.filter(note => !note.isPinned);
    return { pinned, unpinned };
  }, [filteredNotes]);

  const handleViewNote = useCallback((note: Note) => {
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
    setActiveNote({
      note: null,
      mode: 'create',
      isEditing: true,
    });
    setSelectedVirtues([]);
  }, []);

  const handleSaveNote = useCallback(async ({ title, content, virtues }: {
    title: string;
    content: string;
    virtues: AllVirtues[];
  }) => {
    let result: Note | null;
    if (activeNote.mode === 'edit' && activeNote.note) {
      // Update existing note
      result = await updateNote({
        ...activeNote.note,
        title,
        text: content,
        virtues,
        color: getNotePastel(virtues),
        is_public: activeNote.note.is_public
      });
    } else {
      // Create new note
      result = await addNote({
        title,
        text: content,
        virtues,
        color: getNotePastel(virtues),
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
      await deleteNote(noteId);
      handleCloseNote();
      toast.success("Note deleted successfully");
    } catch (error) {
      console.error('Error deleting note:', error);
      toast.error("Error deleting note");
    }
  }, [deleteNote]);

  const handleToggleVisibility = useCallback(async () => {
    if (activeNote.note) {
      await updateNote({
        ...activeNote.note,
        is_public: !activeNote.note.is_public
      });
      setActiveNote(prev => ({
        ...prev,
        note: prev.note ? { ...prev.note, is_public: !prev.note.is_public } : null
      }));
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

  const ListEmptyComponent = useCallback(() => (
    <View style={styles.emptyState}>
      <Text style={styles.emptyStateText}>
        {searchQuery || virtueFilter.length > 0
          ? "No notes match your search criteria."
          : "You haven't created any notes yet. Tap the + button to get started."}
      </Text>
    </View>
  ), [searchQuery, virtueFilter, styles]);

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
          <Text style={styles.title}>
            {showPublicNotes ? 'Community Notes' : 'My Notes'}
          </Text>
          <View style={styles.headerActions}>
            <TouchableOpacity 
              style={[styles.visibilityToggle, showPublicNotes && styles.activeToggle]}
              onPress={() => {
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
});

export default memo(NotesScreen);