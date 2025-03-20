import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  FlatList,
  Modal,
  Platform,
  Alert,
  ActivityIndicator
} from 'react-native';
import { BlurView } from 'expo-blur';
import { MaterialIcons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import BiblePicker from '@/components/BiblePicker';
import BookSelector from '@/components/BookSelector';
import { Book, BibleVersion, BibleVerse, VerseActivityMap } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';
import BibleDBService, { generateVPLId, parseVPLId } from '@/utils/database';
import { Brush, BrushOutlined, SizeDecrease, SizeIncrease } from '@/components/Icons';

interface BibleScreenProps {
  route?: { params?: { book?: string; chapter?: number; verse?: number } };
}

const BibleScreen: React.FC<BibleScreenProps> = ({ route }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const verseListRef = useRef<FlatList>(null);
  
  // State management
  const [installedVersions, setInstalledVersions] = useState<string[]>([]);
  const [currentVersion, setCurrentVersion] = useState<BibleVersion>({
    englishName: 'Revised Version',
    tableName: 'eng_rv_vpl',
    shortName: 'RV',
    downloadUrl: 'https://api.elbiblio.com/dbs/rv.db',
    preinstalled: true,
    dbFilename: 'rv.db'
  });
  const [currentBook, setCurrentBook] = useState<Book>(bibleBooks[0]);

  const [currentChapter, setCurrentChapter] = useState(1);
  const [verses, setVerses] = useState<BibleVerse[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<BibleVerse[]>([]);
  const [fontSize, setFontSize] = useState(16);
  const [history, setHistory] = useState<Array<{ book: Book; chapter: number }>>([]);
  const [showVersionsModal, setShowVersionsModal] = useState(false);
  const [bibleVersions, setBibleVersions] = useState<BibleVersion[]>([]);
  const [loading, setLoading] = useState(true);
  const [highlightedVerses, setHighlightedVerses] = useState<Set<string>>(new Set());
  const [bookmarkedVerses, setBookmarkedVerses] = useState<Set<string>>(new Set());
  const [verseActivity, setVerseActivity] = useState<VerseActivityMap>({});
  const [showActivityPanel, setShowActivityPanel] = useState(false);
  const [selectedVerseId, setSelectedVerseId] = useState<string | null>(null);
  const [showSearch, setShowSearch] = useState(false);
  const [isInstalling, setIsInstalling] = useState(false);

  // Handle initial params
  useEffect(() => {
    if (route?.params) {
      const { book, chapter, verse } = route.params;
      
      if (book) {
        const foundBook = bibleBooks.find(b => 
          b.name.toLowerCase() === book.toLowerCase() || 
          b.abbreviation.toLowerCase() === book.toLowerCase()
        );
        if (foundBook) {
          setCurrentBook(foundBook);
          if (chapter) {
            setCurrentChapter(Math.min(chapter, foundBook.chapters));
            // Schedule verse scroll after verses load
            if (verse) {
              setTimeout(() => {
                const verseIndex = verses.findIndex(v => {
                  const { verse: verseNum } = parseVPLId(v.id);
                  return verseNum === verse;
                });
                if (verseIndex !== -1) {
                  verseListRef.current?.scrollToIndex({
                    index: verseIndex,
                    animated: true,
                    viewPosition: 0.3
                  });
                }
              }, 500);
            }
          }
        }
      }
    }
  }, [route?.params]);

  // Modified initialization
  useEffect(() => {
    let mounted = true;
    
    const initializeBible = async () => {
      try {
        setLoading(true);
        await BibleDBService.initialize();
        
        if (!mounted) return;
        
        // Get installed versions first
        const installed = await BibleDBService.getInstalledVersions();
        if (mounted) {
          setInstalledVersions(installed);
          
          // Only show install alert if no versions are installed AND we haven't already started installing
          if (installed.length === 0 && !isInstalling) {
            setIsInstalling(true);
            await handleInstallVersion('eng_rv_vpl');
          }
          
          // Set current version to first installed version or default
          if (installed.length > 0 && !currentVersion) {
            setCurrentVersion(bibleVersions.find(v => v.dbFilename === installed[0]) || bibleVersions[0]);
          }
        }
        
        // Load saved position or use default
        const lastPosition = await AsyncStorage.getItem('lastBiblePosition');
        if (mounted && lastPosition) {
          const { book, chapter } = JSON.parse(lastPosition);
          const foundBook = bibleBooks.find(b => b.abbreviation === book);
          if (foundBook) {
            setCurrentBook(foundBook);
            setCurrentChapter(chapter);
          }
        } else if (mounted) {
          // Default to Genesis 1
          setCurrentBook(bibleBooks[0]);
          setCurrentChapter(1);
        }
        
      } catch (error) {
        console.error('Failed to initialize Bible:', error);
        if (mounted) {
          Alert.alert(
            'Error',
            'Failed to initialize Bible. Please try restarting the app.',
            [{ text: 'OK' }]
          );
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    };

    initializeBible();
    return () => { mounted = false; };
  }, []);

  // Fetch verses when book/chapter/version changes
  useEffect(() => {
    const fetchVerses = async () => {
      if (!currentBook || !currentVersion) return;
      
      setLoading(true);
      try {
        const versesData = await BibleDBService.getChapter(
          currentVersion.tableName,
          currentBook.abbreviation,
          currentChapter
        );
        
        const versesArray = versesData.map(v => ({
          id: generateVPLId(currentBook.abbreviation, currentChapter, v.verse),
          text: v.text,
          reference: `${currentBook.name} ${currentChapter}:${v.verse}`
        }));
        
        setVerses(versesArray);
      } catch (error) {
        console.error('Error fetching verses:', error);
        Alert.alert('Error', 'Failed to load verses');
      } finally {
        setLoading(false);
      }
    };

    fetchVerses();
  }, [currentBook, currentChapter, currentVersion]);

  // Handle book installation
  const handleInstallVersion = async (version: string) => {
    try {
      const versionData = bibleVersions.find(v => v.tableName === version);
      if (!versionData) throw new Error('Version not found');
      
      await BibleDBService.installVersion(versionData);
      const installed = await BibleDBService.getInstalledVersions();
      setInstalledVersions(installed);
    } catch (error) {
      console.error('Installation failed:', error instanceof Error ? error.message : 'Unknown error');
      Alert.alert('Installation Failed', error instanceof Error ? error.message : 'Unknown error occurred');
    }
  };

  // Search functionality
  const handleSearch = useCallback(async (query: string) => {
    if (!query || !currentVersion) return;
    
    try {
      const results = await BibleDBService.searchVerses(currentVersion.tableName, query);
      setSearchResults(results.map(v => {
        const { bookAbbr, chapter, verse } = parseVPLId(v.verseID);
        const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
        return {
          id: v.verseID,
          text: v.verseText,
          reference: `${book?.name} ${chapter}:${verse}`
        };
      }));
    } catch (error) {
      console.error('Search failed:', error);
      Alert.alert('Error', 'Search failed');
    }
  }, [currentVersion]);

  // Verse interaction handlers
  const toggleHighlight = useCallback((verseId: string) => {
    setHighlightedVerses(prev => {
      const newSet = new Set(prev);
      newSet.has(verseId) ? newSet.delete(verseId) : newSet.add(verseId);
      AsyncStorage.setItem('highlightedVerses', JSON.stringify([...newSet]));
      return newSet;
    });
  }, []);

  const toggleBookmark = useCallback((verseId: string) => {
    setBookmarkedVerses(prev => {
      const newSet = new Set(prev);
      newSet.has(verseId) ? newSet.delete(verseId) : newSet.add(verseId);
      AsyncStorage.setItem('bookmarkedVerses', JSON.stringify([...newSet]));
      return newSet;
    });
  }, []);


  // Enhanced header with activity panel
  const renderHeader = () => (
    <View style={styles.headerContainer}>
      <BlurView intensity={20} style={styles.header}>
        <View style={styles.headerLeft}>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => setShowVersionsModal(true)}
          >
            <Text style={styles.headerButtonText}>
              {currentVersion.shortName}
            </Text>
            <MaterialIcons name="menu-book" size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>


          <View style={styles.controlsGroup}>
            <BookSelector
              currentBook={currentBook}
              onSelect={setCurrentBook}
            />
            
            <BiblePicker
              value={currentChapter}
              items={Array.from({ length: currentBook.chapters }, (_, i) => i + 1)}
              onSelect={setCurrentChapter}
            />
          </View>
        </View>

        <View style={styles.headerRight}>
          <TouchableOpacity 
            style={styles.iconButton}
            onPress={() => setShowSearch(true)}
          >
            <MaterialIcons name="search" size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => setFontSize(prev => Math.max(12, prev - 2))}
            style={styles.iconButton}
          >
            <SizeDecrease size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => setFontSize(prev => Math.min(24, prev + 2))}
            style={styles.iconButton}
          >
            <SizeIncrease size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>
        </View>
      </BlurView>

      {showActivityPanel && selectedVerseId && (
        <BlurView intensity={15} style={styles.activityBar}>
          <View style={styles.activityContent}>
            <View style={styles.activityLeft}>
              <TouchableOpacity 
                style={styles.activityButton}
                onPress={() => toggleBookmark(selectedVerseId)}
              >
                <MaterialIcons 
                  name={bookmarkedVerses.has(selectedVerseId) ? "bookmark" : "bookmark-border"} 
                  size={20} 
                  color={theme.colors.primary} 
                />
                <Text style={styles.activityButtonText}>Bookmark</Text>
              </TouchableOpacity>

              <TouchableOpacity 
                style={styles.activityButton}
                onPress={() => toggleHighlight(selectedVerseId)}
              >
                {highlightedVerses.has(selectedVerseId) ? (
                  <Brush size={20} color={theme.colors.primary} />
                ) : (
                  <BrushOutlined size={20} color={theme.colors.primary} />
                )}
                <Text style={styles.activityButtonText}>Highlight</Text>
              </TouchableOpacity>
            </View>

            <TouchableOpacity 
              style={styles.closeButton}
              onPress={() => {
                setShowActivityPanel(false);
                setSelectedVerseId(null);
              }}
            >
              <MaterialIcons name="close" size={20} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>
        </BlurView>
      )}
    </View>
  );

  // Update version selection modal to use unique keys
  const renderVersionsModal = () => (
    <Modal visible={showVersionsModal} animationType="slide">
      <View style={styles.modalContainer}>
        <FlatList
          data={bibleVersions}
          keyExtractor={(item) => item.tableName}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.versionItem}
              onPress={() => {
                setCurrentVersion(item);
                setShowVersionsModal(false);
              }}
            >
              <Text style={styles.versionName}>
                {item.englishName} ({item.shortName})
              </Text>

              {installedVersions.includes(item.tableName) ? (
                <MaterialIcons name="check-circle" size={24} color={theme.colors.primary} />
              ) : (
                <TouchableOpacity 
                  onPress={(e) => {
                    e.stopPropagation();
                    handleInstallVersion(item.tableName);
                  }}
                >
                  <MaterialIcons name="download" size={24} color={theme.colors.text.secondary} />
                </TouchableOpacity>
              )}
            </TouchableOpacity>
          )}
        />
      </View>
    </Modal>
  );

  // Update verse text style to use fontSize state
  const renderVerse = ({ item }: { item: BibleVerse }) => {
    const { verse: verseNum } = parseVPLId(item.id);
    const isHighlighted = highlightedVerses.has(item.id);
    
    return (
      <View style={[
        styles.verseContainer,
        isHighlighted && styles.highlightedVerse
      ]}>
        <TouchableOpacity 
          style={styles.verseContent}
          onLongPress={() => toggleHighlight(item.id)}
          onPress={() => {
            setSelectedVerseId(item.id);
            setShowActivityPanel(true);
          }}
        >
          <Text style={styles.verseNumber}>
            {verseNum}
          </Text>
          <Text style={[styles.verseText, { fontSize }]}>
            {item.text}
          </Text>
        </TouchableOpacity>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.headerContainer}>
        {renderHeader()}
      </View>

      {/* Content Area */}
      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
        </View>
      ) : (
        <FlatList
          ref={verseListRef}
          data={verses}
          renderItem={renderVerse}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.contentContainer}
          initialNumToRender={20}
          maxToRenderPerBatch={10}
          windowSize={5}
          onScrollToIndexFailed={info => {
            setTimeout(() => {
              verseListRef.current?.scrollToIndex({
                index: info.index,
                animated: true
              });
            }, 500);
          }}
        />
      )}

      {/* Search Modal */}
      <Modal
        visible={showSearch}
        animationType="slide"
        onRequestClose={() => setShowSearch(false)}
      >
        <View style={styles.searchContainer}>
          <View style={styles.searchHeader}>
            <TextInput
              style={styles.searchInput}
              value={searchQuery}
              onChangeText={(text) => {
                setSearchQuery(text);
                handleSearch(text);
              }}
              placeholder="Search Bible..."
              autoFocus
            />
            <TouchableOpacity 
              style={styles.closeButton}
              onPress={() => {
                setShowSearch(false);
                setSearchQuery('');
                setSearchResults([]);
              }}
            >
              <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          <FlatList
            data={searchResults}
            renderItem={({ item }) => (
              <TouchableOpacity 
                style={styles.searchResultItem}
                onPress={() => {
                  const { bookAbbr, chapter, verse } = parseVPLId(item.id);
                  const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
                  if (book) {
                    setCurrentBook(book);
                    setCurrentChapter(chapter);
                    setShowSearch(false);
                    setSearchQuery('');
                    setSearchResults([]);
                  }
                }}
              >
                <Text style={styles.searchResultReference}>{item.reference}</Text>
                <Text style={styles.searchResultText}>{item.text}</Text>
              </TouchableOpacity>
            )}
            keyExtractor={item => item.id}
          />
        </View>
      </Modal>

      {renderVersionsModal()}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  headerContainer: {
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  header: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  headerButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: theme.colors.surface,
  },
  headerButtonText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  controlsGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  contentContainer: {
    padding: theme.spacing.md,
  },
  verseContainer: {
    paddingVertical: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
  },
  verseContent: {
    flexDirection: 'row',
    paddingHorizontal: theme.spacing.md,
  },
  verseNumber: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    marginRight: theme.spacing.sm,
    minWidth: 24,
    textAlign: 'right',
  },
  verseText: {
    flex: 1,
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
  },
  highlightedVerse: {
    backgroundColor: `${theme.colors.primary}15`,
  },
  bookmarkButton: {
    padding: theme.spacing.xs,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  searchContainer: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  searchHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  searchInput: {
    flex: 1,
    ...theme.typography.body.sans,
    padding: theme.spacing.sm,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.md,
    marginRight: theme.spacing.sm,
  },
  searchResultItem: {
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  searchResultReference: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    marginBottom: theme.spacing.xs,
  },
  searchResultText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  modalContainer: {
    flex: 1,
    padding: theme.spacing.md,
    backgroundColor: theme.colors.background,
  },
  activityBar: {
    height: 56,
    paddingHorizontal: theme.spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  activityContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  activityLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  activityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.primary}10`,
  },
  activityButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  closeButton: {
    padding: theme.spacing.xs,
  },
  iconButton: {
    padding: theme.spacing.xs,
    borderRadius: theme.borderRadius.sm,
    backgroundColor: `${theme.colors.primary}10`,
  },
  versionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  versionName: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
});


export default BibleScreen;