import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/storage/settings_storage.dart';
import '../data/bible_repository.dart';
import '../domain/models/bible_content.dart';
import '../domain/models/bible_insight.dart';
import '../domain/models/bible_version.dart';
import 'bible_reading_notifier.dart';

class BibleState {
  const BibleState({
    this.books = const [],
    this.currentBook,
    this.currentChapter = 1,
    this.currentVersion,
    this.availableVersions = const [],
    this.verses = const [],
    this.isLoading = false,
    this.error,
    this.insight,
    this.isInsightLoading = false,
    this.downloadingVersionId,
    this.downloadProgress = 0.0,
    this.searchResults = const [],
    this.isSearching = false,
    this.fontSize = 16.0,
    this.comparisonResults = const [],
    this.isComparing = false,
    this.highlightedVerseId,
    this.scrollToVerseId,
    this.verseNotes = const {},
    this.likedVerses = const {},
  });

  final List<BibleBook> books;
  final BibleBook? currentBook;
  final int currentChapter;
  final BibleVersion? currentVersion;
  final List<BibleVersion> availableVersions;
  final List<BibleVerseContent> verses;
  final bool isLoading;
  final String? error;
  
  final BibleInsight? insight;
  final bool isInsightLoading;
  
  final String? downloadingVersionId;
  final double downloadProgress;
  
  final List<BibleVerseContent> searchResults;
  final bool isSearching;
  final double fontSize;

  final List<Map<String, dynamic>> comparisonResults;
  final bool isComparing;
  final int? highlightedVerseId;
  final int? scrollToVerseId;
  final Map<int, String> verseNotes; // verseId -> note text
  final Set<int> likedVerses; // Set of liked verse IDs

  BibleState copyWith({
    List<BibleBook>? books,
    BibleBook? currentBook,
    int? currentChapter,
    BibleVersion? currentVersion,
    List<BibleVersion>? availableVersions,
    List<BibleVerseContent>? verses,
    bool? isLoading,
    String? error,
    BibleInsight? insight,
    bool? isInsightLoading,
    String? downloadingVersionId,
    double? downloadProgress,
    List<BibleVerseContent>? searchResults,
    bool? isSearching,
    double? fontSize,
    List<Map<String, dynamic>>? comparisonResults,
    bool? isComparing,
    int? highlightedVerseId,
    int? scrollToVerseId,
    Map<int, String>? verseNotes,
    Set<int>? likedVerses,
  }) {
    return BibleState(
      books: books ?? this.books,
      currentBook: currentBook ?? this.currentBook,
      currentChapter: currentChapter ?? this.currentChapter,
      currentVersion: currentVersion ?? this.currentVersion,
      availableVersions: availableVersions ?? this.availableVersions,
      verses: verses ?? this.verses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      insight: insight,
      isInsightLoading: isInsightLoading ?? this.isInsightLoading,
      downloadingVersionId: downloadingVersionId,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      fontSize: fontSize ?? this.fontSize,
      comparisonResults: comparisonResults ?? this.comparisonResults,
      isComparing: isComparing ?? this.isComparing,
      highlightedVerseId: highlightedVerseId ?? this.highlightedVerseId,
      scrollToVerseId: scrollToVerseId ?? this.scrollToVerseId,
      verseNotes: verseNotes ?? this.verseNotes,
      likedVerses: likedVerses ?? this.likedVerses,
    );
  }
}

class BibleNotifier extends StateNotifier<BibleState> {
  static final _logger = Logger();
  
  BibleNotifier(this._repository, this._settingsStorage, this._readingNotifier, {double initialFontSize = 16.0}) 
      : super(BibleState(fontSize: initialFontSize)) {
    loadInitialData();
  }

  final BibleRepository _repository;
  final SettingsStorage _settingsStorage;
  final BibleReadingNotifier? _readingNotifier;

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _settingsStorage.updateBibleFontSize(size);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load books first (offline operation)
      final books = await _repository.getBooks();
      
      // Try to load versions with network fallback
      List<BibleVersion> versions = [];
      try {
        versions = await _repository.getVersions();
      } catch (e) {
        // Network failed - use offline fallback
        _logger.w('Network failed for versions, using offline fallback: $e');
        versions = _getOfflineVersions();
      }
      
      // Add local RV version if not present
      final hasLocalRV = versions.any((v) => v.tableName == 'eng_rv_vpl' || v.abbreviation == 'RV');
      if (!hasLocalRV) {
        const localRV = BibleVersion(
          abbreviation: 'RV',
          name: 'Revised Version',
          tableName: 'eng_rv_vpl',
          preinstalled: true,
          isDownloaded: true,
        );
        versions.add(localRV);
      }
      
      BibleVersion? initialVersion;
      if (versions.isNotEmpty) {
        // First try to find a version that matches our local database
        initialVersion = versions.firstWhere(
          (v) => v.tableName == 'eng_rv_vpl' || v.abbreviation == 'RV',
          orElse: () => versions.first,
        );
      }
      
      state = state.copyWith(
        books: books,
        availableVersions: versions,
        currentVersion: initialVersion,
        isLoading: false,
      );
      
      // Restore last reading location after initial data is loaded
      await _restoreLastReadingLocation(books);
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _restoreLastReadingLocation(List<BibleBook> books) async {
    try {
      // Get the most recent reading location from BibleReadingNotifier
      if (_readingNotifier != null && _readingNotifier.state.history.isNotEmpty) {
        final lastActivity = _readingNotifier.state.history.first;
        final metadata = lastActivity.metadata;
        
        final bookName = metadata?['book']?.toString();
        final chapter = _parseInt(metadata?['chapter']);
        
        if (bookName != null && chapter != null && chapter > 0) {
          // Find the book by name or abbreviation
          BibleBook? targetBook;
          try {
            targetBook = books.firstWhere(
              (book) => book.name.toLowerCase() == bookName.toLowerCase() ||
                        book.abbreviation.toLowerCase() == bookName.toLowerCase(),
            );
          } catch (e) {
            _logger.w('Book "$bookName" not found in available books: $e');
          }
          
          if (targetBook != null) {
            _logger.i('Restoring last reading location: $bookName $chapter');
            
            // Restore the book and chapter
            state = state.copyWith(
              currentBook: targetBook,
              currentChapter: chapter,
            );
            
            // Load verses for the restored location
            await loadVerses();
            return;
          }
        }
      }
      
      // Fallback: select Matthew (first NT book) or Genesis as fallback
      if (state.currentBook == null && books.isNotEmpty) {
        final ntBooks = books.where((book) => book.testament == 'NT').toList();
        if (ntBooks.isNotEmpty) {
          await selectBook(ntBooks.first);
        } else {
          await selectBook(books.first);
        }
      }
    } catch (e) {
      _logger.w('Failed to restore last reading location: $e');
      
      // Ensure we have at least some book selected
      if (state.currentBook == null && books.isNotEmpty) {
        await selectBook(books.first);
      }
    }
  }

  // Helper method to safely parse integers
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  List<BibleVersion> _getOfflineVersions() {
    return [
      const BibleVersion(
        abbreviation: 'RV',
        name: 'Revised Version (Offline)',
        tableName: 'eng_rv_vpl',
        preinstalled: true,
        isDownloaded: true,
      ),
    ];
  }

  Future<void> selectBook(BibleBook book) async {
    if (state.currentBook?.abbreviation == book.abbreviation && state.verses.isNotEmpty && state.error == null) return;

    state = state.copyWith(
      currentBook: book,
      currentChapter: 1,
      verses: [],
    );
    
    // Track reading location when book changes
    if (_readingNotifier != null) {
      _readingNotifier.trackReadingLocation(
        bookName: book.name,
        chapter: 1,
        testament: book.testament,
      );
    }
    
    await loadVerses();
  }

  Future<void> selectChapter(int chapter) async {
    if (state.currentChapter == chapter && state.verses.isNotEmpty && state.error == null) return;

    state = state.copyWith(
      currentChapter: chapter,
      verses: [],
    );
    
    // Track reading location when chapter changes
    if (state.currentBook != null && _readingNotifier != null) {
      _readingNotifier.trackReadingLocation(
        bookName: state.currentBook!.name,
        chapter: chapter,
        testament: state.currentBook!.testament,
      );
    }
    
    await loadVerses();
  }

  Future<void> selectVersion(BibleVersion version) async {
    if (state.currentVersion?.abbreviation == version.abbreviation) return;
    
    state = state.copyWith(
      currentVersion: version,
      verses: [],
    );
    await loadVerses();
  }

  Future<void> nextChapter() async {
    if (state.currentBook == null) return;
    
    final maxChapters = state.currentBook?.chapters ?? 50;
    
    if (state.currentChapter < maxChapters) {
      await selectChapter(state.currentChapter + 1);
    } else {
      final currentIndex = state.books.indexWhere((b) => b.abbreviation == state.currentBook?.abbreviation);
      if (currentIndex != -1 && currentIndex < state.books.length - 1) {
        await selectBook(state.books[currentIndex + 1]);
      }
    }
  }

  Future<void> previousChapter() async {
    if (state.currentChapter > 1) {
      await selectChapter(state.currentChapter - 1);
    } else {
      if (state.currentBook == null) return;
      final currentIndex = state.books.indexWhere((b) => b.abbreviation == state.currentBook?.abbreviation);
      if (currentIndex > 0) {
        final prevBook = state.books[currentIndex - 1];
        state = state.copyWith(
          currentBook: prevBook,
          currentChapter: prevBook.chapters ?? 1,
          verses: [],
        );
        await loadVerses();
      }
    }
  }

  Future<void> loadVerses() async {
    if (state.currentBook == null || state.currentVersion == null) return;

    final versionIdentifier = state.currentVersion!.tableName ?? state.currentVersion!.abbreviation;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final verses = await _repository.getVerses(
        versionIdentifier,
        state.currentBook!.abbreviation,
        state.currentChapter,
        onAutoDownloadProgress: (version, progress) {
          // Update state to show auto-download progress
          state = state.copyWith(
            isLoading: true,
            error: 'Downloading $version... ${(progress * 100).toInt()}%',
          );
        },
      );
      
      if (verses.isEmpty) {
        // If no verses found, it might be a database issue - try to be helpful
        final errorMessage = 'No verses found for ${state.currentBook!.name} ${state.currentChapter} in ${state.currentVersion!.name}. Try selecting a different book or version.';
        state = state.copyWith(
          verses: verses,
          isLoading: false,
          error: errorMessage,
        );
        
        // Clear error after 8 seconds for no verses found
        Future.delayed(const Duration(seconds: 8), () {
          if (state.error == errorMessage) {
            state = state.copyWith(error: null);
          }
        });
      } else {
        state = state.copyWith(
          verses: verses,
          isLoading: false,
          error: null, // Clear any auto-download messages
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      
      // Check if this is an auto-download related error
      if (errorMessage.contains('auto-download failed') || errorMessage.contains('not found and no download')) {
        errorMessage = 'Unable to download ${state.currentVersion?.name}. Please try downloading it manually from the versions list.';
      } else if (errorMessage.contains('Failed to open database') || errorMessage.contains('Database integrity check failed')) {
        errorMessage = 'Database issue with ${state.currentVersion?.name}. Try selecting a different version or restarting the app.';
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
      
      // Clear error after 5 seconds for download errors
      if (errorMessage.contains('download') || errorMessage.contains('Unable to download') || errorMessage.contains('Database issue')) {
        Future.delayed(const Duration(seconds: 5), () {
          if (state.error == errorMessage) {
            state = state.copyWith(error: null);
          }
        });
      }
    }
  }

  Future<void> downloadVersion(BibleVersion version) async {
    if (version.tableName == null) return;
    
    state = state.copyWith(
      downloadingVersionId: version.abbreviation,
      downloadProgress: 0.0,
      error: null, // Clear previous errors
    );

    try {
      // Use the download URL from the version object if available, otherwise let the service figure it out
      if (version.downloadUrl.isNotEmpty) {
        await _repository.downloadVersionWithUrl(
          version.tableName!,
          downloadUrl: version.downloadUrl,
          onProgress: (received, total) {
            if (total != -1) {
              state = state.copyWith(
                downloadProgress: received / total,
              );
            }
          },
        );
      } else {
        await _repository.downloadVersion(
          version.tableName!,
          onProgress: (received, total) {
            if (total != -1) {
              state = state.copyWith(
                downloadProgress: received / total,
              );
            }
          },
        );
      }
      
      // Update available versions list to reflect downloaded status
      final updatedVersions = state.availableVersions.map((v) {
        if (v.abbreviation == version.abbreviation) {
          return v.copyWith(isDownloaded: true);
        }
        return v;
      }).toList();
      
      state = state.copyWith(
        availableVersions: updatedVersions,
        downloadingVersionId: null,
        downloadProgress: 0.0,
      );
      
      // If this is the current version, reload verses to potentially switch to local DB (handled by repo logic)
      if (state.currentVersion?.abbreviation == version.abbreviation) {
        loadVerses();
      }
      
    } catch (e) {
      // Provide user-friendly error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('empty') || errorMessage.contains('not found')) {
        errorMessage = '${version.name} is not available for download at this time.';
      } else if (errorMessage.contains('timeout') || errorMessage.contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('404')) {
        errorMessage = '${version.name} is not available on the server.';
      } else {
        errorMessage = 'Failed to download ${version.name}: $errorMessage';
      }
      
      state = state.copyWith(
        downloadingVersionId: null,
        downloadProgress: 0.0,
        error: errorMessage,
      );
      
      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (state.error == errorMessage) {
          state = state.copyWith(error: null);
        }
      });
    }
  }

  Future<void> getInsight(int verseId) async {
    state = state.copyWith(isInsightLoading: true, insight: null);
    try {
      final insight = await _repository.getVerseInsight(verseId);
      state = state.copyWith(
        insight: insight,
        isInsightLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to get insight: $e',
        isInsightLoading: false,
      );
    }
  }
  
  void clearInsight() {
    state = state.copyWith(insight: null);
  }

  Future<void> search(String query) async {
    if (query.isEmpty || state.currentVersion == null) return;
    
    state = state.copyWith(isSearching: true, searchResults: []);
    
    try {
      final results = await _repository.searchVerses(
        state.currentVersion!.tableName ?? state.currentVersion!.abbreviation,
        query,
      );
      state = state.copyWith(
        isSearching: false,
        searchResults: results,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: 'Search failed: $e',
      );
    }
  }
  
  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }

  void toggleHighlight(int verseId) {
    // Optimistic update
    final updatedVerses = state.verses.map((v) {
      if (v.id == verseId) {
        return v.copyWith(isHighlighted: !v.isHighlighted);
      }
      return v;
    }).toList();
    state = state.copyWith(verses: updatedVerses);

    // Persist
    _repository.toggleHighlight(verseId).catchError((e) {
      // Revert if failed
      final revertedVerses = state.verses.map((v) {
        if (v.id == verseId) {
          return v.copyWith(isHighlighted: !v.isHighlighted);
        }
        return v;
      }).toList();
      state = state.copyWith(verses: revertedVerses, error: 'Failed to highlight: $e');
    });
  }

  void toggleBookmark(int verseId) {
    // Optimistic update
    final updatedVerses = state.verses.map((v) {
      if (v.id == verseId) {
        return v.copyWith(isBookmarked: !v.isBookmarked);
      }
      return v;
    }).toList();
    state = state.copyWith(verses: updatedVerses);

    // Persist
    _repository.toggleBookmark(verseId).catchError((e) {
      // Revert if failed
      final revertedVerses = state.verses.map((v) {
        if (v.id == verseId) {
          return v.copyWith(isBookmarked: !v.isBookmarked);
        }
        return v;
      }).toList();
      state = state.copyWith(verses: revertedVerses, error: 'Failed to bookmark: $e');
    });
  }

  Future<void> compareVerses(String reference) async {
    if (state.currentVersion == null) return;
    
    state = state.copyWith(isComparing: true, comparisonResults: []);
    
    try {
      final results = await _repository.compareVerses(
        state.currentVersion!.tableName ?? state.currentVersion!.abbreviation,
        reference,
      );
      state = state.copyWith(
        isComparing: false,
        comparisonResults: results,
      );
    } catch (e) {
      state = state.copyWith(
        isComparing: false,
        error: 'Comparison failed: $e',
      );
    }
  }

  void clearComparison() {
    state = state.copyWith(comparisonResults: []);
  }

  Future<void> navigateToSpecificVerse(String bookName, int chapter, int verseNumber) async {
    // Find the book by name
    final targetBook = state.books.firstWhere(
      (book) => book.name.toLowerCase() == bookName.toLowerCase(),
      orElse: () => state.books.firstWhere(
        (book) => book.abbreviation.toLowerCase() == bookName.toLowerCase(),
        orElse: () => state.books.first, // fallback to first book
      ),
    );

    // Set book and chapter together, then load once (avoids double loadVerses)
    state = state.copyWith(
      currentBook: targetBook,
      currentChapter: chapter,
      verses: [],
    );

    // Track reading location
    if (_readingNotifier != null) {
      _readingNotifier.trackReadingLocation(
        bookName: targetBook.name,
        chapter: chapter,
        testament: targetBook.testament,
      );
    }

    await loadVerses();

    // Set the highlighted verse
    state = state.copyWith(highlightedVerseId: verseNumber);
  }

  Future<void> scrollToVerse(String bookName, int chapter, [int? verseNumber]) async {
    _logger.i('Navigating to: $bookName $chapter${verseNumber != null ? ':$verseNumber' : ''}');
    
    // Ensure books are loaded before trying to navigate
    if (state.books.isEmpty) {
      _logger.w('Books not loaded yet, loading initial data first');
      await loadInitialData();
    }
    
    // Find the book by name
    BibleBook? targetBook;
    try {
      targetBook = state.books.firstWhere(
        (book) => book.name.toLowerCase() == bookName.toLowerCase(),
      );
      _logger.i('Found book by name: ${targetBook.name}');
    } catch (e) {
      try {
        targetBook = state.books.firstWhere(
          (book) => book.abbreviation.toLowerCase() == bookName.toLowerCase(),
        );
        _logger.i('Found book by abbreviation: ${targetBook.name}');
      } catch (e) {
        _logger.w('Book "$bookName" not found, trying to find closest match');
        
        // Try to find a book that contains the bookName as substring
        try {
          targetBook = state.books.firstWhere(
            (book) => book.name.toLowerCase().contains(bookName.toLowerCase()) ||
                      bookName.toLowerCase().contains(book.name.toLowerCase()),
          );
          _logger.i('Found book by substring match: ${targetBook.name}');
        } catch (e) {
          _logger.w('No match found for "$bookName", using first available book');
          if (state.books.isNotEmpty) {
            targetBook = state.books.first;
            _logger.i('Using fallback book: ${targetBook.name}');
          } else {
            _logger.e('No books available for navigation');
            return;
          }
        }
      }
    }

    // Set book and chapter together, then load once (avoids double loadVerses)
    state = state.copyWith(
      currentBook: targetBook,
      currentChapter: chapter,
      verses: [],
    );

    // Track reading location
    if (_readingNotifier != null) {
      _readingNotifier.trackReadingLocation(
        bookName: targetBook.name,
        chapter: chapter,
        testament: targetBook.testament,
      );
    }

    await loadVerses();

    if (verseNumber != null) {
      // Scroll to verse without highlighting
      state = state.copyWith(scrollToVerseId: verseNumber);

      _logger.i('Scrolled to verse: ${targetBook.name} $chapter:$verseNumber');

      // Clear the scroll target after a short delay to prevent re-scrolling
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state.scrollToVerseId == verseNumber) {
          state = state.copyWith(scrollToVerseId: null);
        }
      });
    }
  }

  void setHighlightedVerse(int verseNumber) {
    state = state.copyWith(highlightedVerseId: verseNumber);
  }

  void clearHighlightedVerse() {
    state = state.copyWith(highlightedVerseId: null);
  }

  Future<void> getAllInsightsForVerse(int verseId) async {
    // For now, we'll just get the single insight and wrap it in a list
    // In a real implementation, this would fetch multiple insights
    try {
      await getInsight(verseId);
    } catch (e) {
      // Handle error silently for now
    }
  }

  List<BibleInsight> getAllInsights() {
    if (state.insight != null) {
      return [state.insight!];
    }
    return [];
  }

  String? getVerseNote(int verseId) {
    return state.verseNotes[verseId];
  }

  Future<void> saveVerseNote(int verseId, String note) async {
    final updatedNotes = Map<int, String>.from(state.verseNotes);
    if (note.isEmpty) {
      updatedNotes.remove(verseId);
    } else {
      updatedNotes[verseId] = note;
    }
    state = state.copyWith(verseNotes: updatedNotes);
    
    // Persist to API
    try {
      await _repository.saveVerseNote(verseId, note);
    } catch (e) {
      // Handle error - could revert state or show error message
      // For now, we'll keep the optimistic update
    }
  }

  Future<void> deleteVerseNote(int verseId) async {
    await saveVerseNote(verseId, '');
  }

  bool isVerseLiked(int verseId) {
    return state.likedVerses.contains(verseId);
  }

  Future<void> toggleLikeVerse(int verseId) async {
    final isLiked = isVerseLiked(verseId);
    
    try {
      if (isLiked) {
        // Unlike the verse
        final success = await _repository.unlikeVerse(verseId);
        if (!success) {
          // If unlike failed, keep it as liked
          return;
        }
        
        final updatedLikes = Set<int>.from(state.likedVerses)..remove(verseId);
        state = state.copyWith(likedVerses: updatedLikes);
      } else {
        // Like the verse
        final success = await _repository.likeVerse(verseId);
        if (!success) {
          // If like failed, keep it as unliked
          return;
        }
        
        final updatedLikes = Set<int>.from(state.likedVerses)..add(verseId);
        state = state.copyWith(likedVerses: updatedLikes);
      }
    } catch (e) {
      // Handle error silently or show error message
      // Could add error state handling here if needed
    }
  }

  Future<Map<String, dynamic>?> shareVerse(int verseId, {String? platform, String? message}) async {
    try {
      final result = await _repository.shareVerse(verseId, platform: platform, message: message);
      return result;
    } catch (e) {
      // Handle error silently or show error message
      return null;
    }
  }
}

