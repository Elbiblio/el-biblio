import React, { useState, useCallback, useEffect, memo } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  FlatList,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  NotePencil,
  ArrowLeft,
  Filter,
  Search,
  Plus,
  ViewGrid,
  ViewList,
  Sparkle,
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
  // Theme and layout hooks
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // Store hooks
  const {
    notes,
    isLoading,
    fetchNote,
    addNote,
    updateNote,
    deleteNote,
    initialize,
    syncNotes
  } = useNoteStore();

  // State hooks
  const [isInitialLoad, setIsInitialLoad] = useState(true);
  const [selectedVirtues, setSelectedVirtues] = useState<AllVirtues[]>([]);
  const [showVirtueSelector, setShowVirtueSelector] = useState(false);
  const [isGridView, setIsGridView] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeNote, setActiveNote] = useState<{
    note: Note | null;
    mode: 'read' | 'edit' | 'create' | null;
  }>({ note: null, mode: null });
  const [virtueFilter, setVirtueFilter] = useState<AllVirtues[]>([]);

  // Route params
  const { noteId } = route.params || {};

  // Initialize notes
  useEffect(() => {
    const initializeData = async () => {
      await initialize();
      setIsInitialLoad(false);
    };

    initializeData();
  }, [initialize]);

  const loadNote = useCallback(async (id: number | string) => {
    const localNote = notes.find(n => n.id === id);
    if (localNote) {
      setActiveNote({
        note: localNote,
        mode: 'read'
      });
      setSelectedVirtues(localNote.virtues || []);
    } else {
      const fetchedNote = await fetchNote(id.toString(10));
      if (fetchedNote) {
        setActiveNote({
          note: fetchedNote,
          mode: 'read'
        });
        setSelectedVirtues(fetchedNote.virtues || []);
      } else {
        toast.error('Note not found');
        navigation.goBack();
      }
    }
  }, [notes, fetchNote, navigation]);

  //load from params
  useEffect(() => {
    if (noteId && !isInitialLoad) {
      loadNote(noteId);
    }
  }, [noteId, isInitialLoad, loadNote]);

  useEffect(() => {
    const syncInterval = setInterval(syncNotes, 1000 * 60 * 5); // 5 minutes
    return () => clearInterval(syncInterval);
  }, [syncNotes]);

  // Loading state
  if (isInitialLoad) {
    return (
      <View style={[styles.container, styles.centerContent]}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  // Rest of the filtering logic remains the same
  const filteredNotes = React.useMemo(() => {
    return notes.filter(note => {
      if (searchQuery) {
        const searchLower = searchQuery.toLowerCase();
        const matchesTitle = note.title.toLowerCase().includes(searchLower);
        const matchesContent = note.text.toLowerCase().includes(searchLower);
        if (!matchesTitle && !matchesContent) return false;
      }

      if (virtueFilter.length > 0) {
        if (!virtueFilter.some(virtue => note.virtues?.includes(virtue))) {
          return false;
        }
      }

      return true;
    });
  }, [notes, searchQuery, virtueFilter]);

  // Group notes by pinned status
  const groupedNotes = React.useMemo(() => {
    const pinned = filteredNotes.filter(note => note.isPinned);
    const unpinned = filteredNotes.filter(note => !note.isPinned);
    return { pinned, unpinned };
  }, [filteredNotes]);


  const handleViewNote = useCallback((note: Note) => {
    setActiveNote({ note, mode: 'read' });
    setSelectedVirtues(note.virtues || []);
  }, []);

  const handleCloseNote = useCallback(() => {
    setActiveNote({ note: null, mode: null });
    setSelectedVirtues([]);
  }, []);

  const handleCreateNote = useCallback(() => {
    setActiveNote({
      note: {
        id: `local_${Date.now()}`,
        title: '',
        text: '',
        virtues: [],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        isPinned: false,
        color: getNotePastel([])
      },
      mode: 'create'
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
        color: getNotePastel(virtues)
      });
    } else {
      // Create new note
      result = await addNote({
        title,
        text: content,
        virtues,
        color: getNotePastel(virtues)
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

  const renderItem = useCallback(({ item }: { item: Note }) => (
    <NoteCard
      note={item}
      isGridView={isGridView}
      onPress={handleViewNote}
    />
  ), [isGridView, handleViewNote]);

  const renderNoteEditor = () => {
    if (activeNote.mode === null) return null;

    return (
      <NoteEditor
        initialTitle={activeNote.note?.title}
        initialContent={activeNote.note?.text}
        initialVirtues={activeNote.note?.virtues}
        onSubmit={handleSaveNote}
        onCancel={handleCloseNote}
        onDelete={activeNote.note?.id ? () => handleDeleteNote(activeNote.note!.id) : undefined}
        isEditing={activeNote.mode !== 'read'}
      />
    );
  };

  const ListEmptyComponent = useCallback(() => (
    <View style={styles.emptyState}>
      <NotePencil size={48} color={theme.colors.text.secondary} />
      <Text style={styles.emptyStateText}>
        No notes found. Start capturing your thoughts and reflections.
      </Text>
    </View>
  ), [theme, styles]);

  return (
    <>

      <View style={[styles.container, { paddingTop: insets.top }]}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <ArrowLeft size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
          <Text style={styles.title}>Notes</Text>
          <TouchableOpacity onPress={() => setIsGridView(!isGridView)}>
            {isGridView ?
              <ViewGrid size={24} color={theme.colors.text.primary} /> :
              <ViewList size={24} color={theme.colors.text.primary} />
            }
          </TouchableOpacity>
        </View>

        {/* Search and Filter */}
        <View style={styles.searchContainer}>
          <View style={styles.searchBar}>
            <Search size={20} color={theme.colors.text.secondary} />
            <TextInput
              style={styles.searchInput}
              placeholder="Search notes"
              value={searchQuery}
              onChangeText={setSearchQuery}
            />
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
        </View>

        {/* Notes List */}
        <FlatList
          data={groupedNotes.unpinned}
          renderItem={renderItem}
          keyExtractor={item => item.id.toString()}
          numColumns={isGridView ? 2 : 1}
          contentContainerStyle={styles.listContent}
          ListHeaderComponent={() => (
            <>
              {groupedNotes.pinned.length > 0 && (
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

        {/* Add Note Button */}
        <TouchableOpacity
          style={styles.addButton}
          onPress={handleCreateNote}
        >
          <Plus size={24} color={theme.colors.text.inverse} />
        </TouchableOpacity>

      </View>

      {/* Note Editor Modal */}
      {renderNoteEditor()}

      {/* Virtue Selector Modal */}
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
    backgroundColor: `${theme.colors.primary}`,
    color: theme.colors.text.inverse,
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
});

export default memo(NotesScreen);