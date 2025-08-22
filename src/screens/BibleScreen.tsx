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
  ActivityIndicator,
  RefreshControl
} from 'react-native';
import { BlurView } from 'expo-blur';
import { MaterialIcons } from '@expo/vector-icons';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import BiblePicker from '@/components/BiblePicker';
import BookSelector from '@/components/BookSelector';
import { Book, BibleVersion, BibleVerse } from '@/types';
import { bibleBooks } from '@/constants/bibleBooks';
import { Brush, BrushOutlined, SizeDecrease, SizeIncrease } from '@/components/Icons';
import { useBibleStore } from '@/stores/bible';
import { useNetworkStatus } from '@/hooks/useNetworkStatus';
import { parseVPLId } from '@/utils/database';
import { toast } from 'sonner-native';
import * as Haptics from 'expo-haptics';

interface BibleScreenProps {
  route?: { params?: { book?: string; chapter?: number; verse?: number } };
}

const BibleScreen: React.FC<BibleScreenProps> = ({ route }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const verseListRef = useRef<FlatList>(null);
  
  // Network status
  const { isOffline } = useNetworkStatus();

  // Bible store
  const {
    currentBook,
    currentChapter,
    currentVersion,
    verses,
    searchResults,
    isVersesLoading,
    isSearchLoading,
    isInstallingVersion,
    versesError,
    searchError,
    installError,
    highlightedVerses,
    bookmarkedVerses,
    fontSize,
    searchQuery,
    showSearch,
    showActivityPanel,
    selectedVerseId,
    installedVersions,
    availableVersions,
    isVersionsLoading,
    pagination,
    isOffline: bibleOffline,
    fetchVerses,
    searchVerses,
    fetchBibleVersions,
    installVersion,
    toggleHighlight,
    toggleBookmark,
    likeVerse,
    shareVerse,
    setCurrentBook,
    setCurrentChapter,
    setCurrentVersion,
    setFontSize,
    setSearchQuery,
    setShowSearch,
    setShowActivityPanel,
    setSelectedVerseId,
    clearErrors,
    clearSearch,
    loadUserPreferences,
    saveUserPreferences,
    syncUserInteractions,
    setIsOffline,
  } = useBibleStore();

  // Local state for UI
  const [showVersionsModal, setShowVersionsModal] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

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
                  const verseNum = parseInt(v.id.split(':')[2] || '1');
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

  // Update offline status in Bible store
  useEffect(() => {
    setIsOffline(isOffline);
  }, [isOffline, setIsOffline]);

  // Initialize Bible
  useEffect(() => {
    const initializeBible = async () => {
      try {
        await loadUserPreferences();
        await fetchBibleVersions();
        
        // Set default version if none selected
        if (!currentVersion && availableVersions.length > 0) {
          const defaultVersion = availableVersions.find(v => v.preinstalled) || availableVersions[0];
          setCurrentVersion(defaultVersion);
        }
        
        // Set default book if none selected
        if (!currentBook) {
          setCurrentBook(bibleBooks[0]);
        }
        
        // Sync user interactions if online
        if (!isOffline) {
          await syncUserInteractions();
        }
        
      } catch (error) {
        console.error('Failed to initialize Bible:', error);
        toast.error('Failed to initialize Bible. Please try restarting the app.');
      }
    };

    initializeBible();
  }, [loadUserPreferences, fetchBibleVersions, currentVersion, availableVersions, setCurrentVersion, setCurrentBook, currentBook, isOffline, syncUserInteractions]);

  // Fetch verses when book/chapter/version changes
  useEffect(() => {
    if (currentBook && currentVersion) {
      fetchVerses(currentBook, currentChapter, currentVersion);
    }
  }, [currentBook, currentChapter, currentVersion]);

  // Handle errors
  useEffect(() => {
    if (versesError) {
      toast.error(versesError);
      clearErrors();
    }
    if (searchError) {
      toast.error(searchError);
      clearErrors();
    }
    if (installError) {
      toast.error(installError);
      clearErrors();
    }
  }, [versesError, searchError, installError]);

  // Handle refresh
  const handleRefresh = async () => {
    setRefreshing(true);
    if (currentBook && currentVersion) {
      await fetchVerses(currentBook, currentChapter, currentVersion, 1);
    }
    setRefreshing(false);
  };

  // Handle load more
  const handleLoadMore = () => {
    if (pagination.hasMore && !isVersesLoading && currentBook && currentVersion) {
      fetchVerses(currentBook, currentChapter, currentVersion, pagination.currentPage + 1);
    }
  };

  // Handle book installation
  const handleInstallVersion = async (version: BibleVersion) => {
    try {
      const success = await installVersion(version);
      if (success) {
        toast.success(`${version.englishName} installed successfully`);
      }
    } catch (error) {
      console.error('Installation failed:', error);
    }
  };

  // Search functionality
  const handleSearch = useCallback(async (query: string) => {
    if (!query || !currentVersion) return;
    
    setSearchQuery(query);
    await searchVerses(query, currentVersion);
  }, [currentVersion, searchVerses, setSearchQuery]);

  // Verse interaction handlers
  const handleToggleHighlight = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const success = await toggleHighlight(verseId);
    if (success) {
      await saveUserPreferences();
    }
  }, [toggleHighlight, saveUserPreferences]);

  const handleToggleBookmark = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const success = await toggleBookmark(verseId);
    if (success) {
      await saveUserPreferences();
    }
  }, [toggleBookmark, saveUserPreferences]);

  const handleLikeVerse = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await likeVerse(verseId);
  }, [likeVerse]);

  const handleShareVerse = useCallback(async (verseId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await shareVerse(verseId);
  }, [shareVerse]);

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
              {currentVersion?.shortName || 'RV'}
            </Text>
            <MaterialIcons name="menu-book" size={20} color={theme.colors.text.primary} />
          </TouchableOpacity>
          
          {isOffline && (
            <View style={styles.offlineIndicator}>
              <MaterialIcons name="wifi-off" size={12} color={theme.colors.warning} />
              <Text style={styles.offlineText}>Offline</Text>
            </View>
          )}

          <View style={styles.controlsGroup}>
            <BookSelector
              currentBook={currentBook || bibleBooks[0]}
              onSelect={setCurrentBook}
            />
            
            <BiblePicker
              value={currentChapter}
              items={Array.from({ length: (currentBook || bibleBooks[0]).chapters }, (_, i) => i + 1)}
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
            onPress={() => setFontSize(Math.max(12, fontSize - 2))}
            style={styles.iconButton}
          >
            <SizeDecrease size={24} color={theme.colors.text.primary} />
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => setFontSize(Math.min(24, fontSize + 2))}
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
                onPress={() => handleToggleBookmark(selectedVerseId)}
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
                onPress={() => handleToggleHighlight(selectedVerseId)}
              >
                {highlightedVerses.has(selectedVerseId) ? (
                  <Brush size={20} color={theme.colors.primary} />
                ) : (
                  <BrushOutlined size={20} color={theme.colors.primary} />
                )}
                <Text style={styles.activityButtonText}>Highlight</Text>
              </TouchableOpacity>

              <TouchableOpacity 
                style={styles.activityButton}
                onPress={() => handleLikeVerse(selectedVerseId)}
              >
                <MaterialIcons name="thumb-up" size={20} color={theme.colors.primary} />
                <Text style={styles.activityButtonText}>Like</Text>
              </TouchableOpacity>

              <TouchableOpacity 
                style={styles.activityButton}
                onPress={() => handleShareVerse(selectedVerseId)}
              >
                <MaterialIcons name="share" size={20} color={theme.colors.primary} />
                <Text style={styles.activityButtonText}>Share</Text>
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
        <View style={styles.modalHeader}>
          <Text style={styles.modalTitle}>Bible Versions</Text>
          <TouchableOpacity onPress={() => setShowVersionsModal(false)}>
            <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
          </TouchableOpacity>
        </View>
        
        {isVersionsLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={theme.colors.primary} />
          </View>
        ) : (
          <FlatList
            data={availableVersions}
            keyExtractor={(item) => item.shortName}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.versionItem}
                onPress={() => {
                  setCurrentVersion(item);
                  setShowVersionsModal(false);
                }}
              >
                <View style={styles.versionInfo}>
                  <Text style={styles.versionName}>
                    {item.englishName} ({item.shortName})
                  </Text>
                  {item.preinstalled && (
                    <Text style={styles.versionSubtext}>Pre-installed</Text>
                  )}
                </View>

                {installedVersions.includes(item.shortName) ? (
                  <MaterialIcons name="check-circle" size={24} color={theme.colors.primary} />
                ) : (
                  <TouchableOpacity 
                    onPress={(e) => {
                      e.stopPropagation();
                      handleInstallVersion(item);
                    }}
                    disabled={isInstallingVersion}
                  >
                    <MaterialIcons 
                      name="download" 
                      size={24} 
                      color={isInstallingVersion ? theme.colors.text.secondary : theme.colors.primary} 
                    />
                  </TouchableOpacity>
                )}
              </TouchableOpacity>
            )}
          />
        )}
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
          onLongPress={() => handleToggleHighlight(item.id)}
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

  const ListFooter = () => {
    if (isVersesLoading && pagination.currentPage > 1) {
      return (
        <View style={styles.loadingFooter}>
          <ActivityIndicator color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading more verses...</Text>
        </View>
      );
    }
    return null;
  };

  const ListEmpty = () => {
    if (isVersesLoading) {
      return (
        <View style={styles.emptyContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.emptyText}>Loading verses...</Text>
        </View>
      );
    }

    if (versesError) {
      return (
        <View style={styles.emptyContainer}>
          <Text style={styles.errorText}>Failed to load verses</Text>
          <TouchableOpacity 
            style={styles.retryButton} 
            onPress={() => currentBook && currentVersion && fetchVerses(currentBook, currentChapter, currentVersion)}
          >
            <Text style={styles.retryButtonText}>Retry</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return (
      <View style={styles.emptyContainer}>
        <Text style={styles.emptyText}>No verses available</Text>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.headerContainer}>
        {renderHeader()}
      </View>

      {/* Content Area */}
      <FlatList
        ref={verseListRef}
        data={verses}
        renderItem={renderVerse}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.contentContainer}
        initialNumToRender={20}
        maxToRenderPerBatch={10}
        windowSize={5}
        onEndReached={handleLoadMore}
        onEndReachedThreshold={0.1}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={[theme.colors.primary]}
            tintColor={theme.colors.primary}
          />
        }
        ListFooterComponent={ListFooter}
        ListEmptyComponent={ListEmpty}
        onScrollToIndexFailed={info => {
          setTimeout(() => {
            verseListRef.current?.scrollToIndex({
              index: info.index,
              animated: true
            });
          }, 500);
        }}
      />

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
              onChangeText={handleSearch}
              placeholder="Search Bible..."
              autoFocus
            />
            <TouchableOpacity 
              style={styles.closeButton}
              onPress={() => {
                setShowSearch(false);
                clearSearch();
              }}
            >
              <MaterialIcons name="close" size={24} color={theme.colors.text.secondary} />
            </TouchableOpacity>
          </View>

          {isSearchLoading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={theme.colors.primary} />
            </View>
          ) : (
            <FlatList
              data={searchResults}
              renderItem={({ item }) => (
                <TouchableOpacity 
                  style={styles.searchResultItem}
                  onPress={() => {
                    const parts = item.id.split(':');
                    const bookAbbr = parts[0];
                    const chapter = parseInt(parts[1] || '1');
                    const book = bibleBooks.find(b => b.abbreviation === bookAbbr);
                    if (book) {
                      setCurrentBook(book);
                      setCurrentChapter(chapter);
                      setShowSearch(false);
                      clearSearch();
                    }
                  }}
                >
                  <Text style={styles.searchResultReference}>{item.reference}</Text>
                  <Text style={styles.searchResultText}>{item.text}</Text>
                </TouchableOpacity>
              )}
              keyExtractor={item => item.id}
            />
          )}
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
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  modalTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  versionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  versionInfo: {
    flex: 1,
  },
  versionName: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  versionSubtext: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
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
  loadingFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme.spacing.md,
  },
  loadingText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.sm,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: theme.spacing.lg,
  },
  emptyText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.sm,
  },
     errorText: {
     ...theme.typography.body.sans,
     color: theme.colors.error,
     textAlign: 'center',
     marginBottom: theme.spacing.sm,
   },
   retryButton: {
     paddingVertical: theme.spacing.sm,
     paddingHorizontal: theme.spacing.lg,
     backgroundColor: theme.colors.primary,
     borderRadius: theme.borderRadius.md,
   },
   retryButtonText: {
     ...theme.typography.body.sans,
     color: theme.colors.text.inverse,
   },
   offlineIndicator: {
     flexDirection: 'row',
     alignItems: 'center',
     gap: theme.spacing.xs,
     paddingHorizontal: theme.spacing.sm,
     paddingVertical: theme.spacing.xs,
     borderRadius: theme.borderRadius.sm,
     backgroundColor: `${theme.colors.warning}15`,
   },
   offlineText: {
     ...theme.typography.caption.secondary,
     color: theme.colors.warning,
     fontSize: 10,
   },
});


export default BibleScreen;