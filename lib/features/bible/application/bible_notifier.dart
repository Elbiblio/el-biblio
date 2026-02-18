import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/settings_storage.dart';
import '../data/bible_repository.dart';
import '../domain/models/bible_content.dart';
import '../domain/models/bible_insight.dart';
import '../domain/models/bible_version.dart';

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
    );
  }
}

class BibleNotifier extends StateNotifier<BibleState> {
  BibleNotifier(this._repository, this._settingsStorage, {double initialFontSize = 16.0}) 
      : super(BibleState(fontSize: initialFontSize)) {
    loadInitialData();
  }

  final BibleRepository _repository;
  final SettingsStorage _settingsStorage;

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _settingsStorage.updateBibleFontSize(size);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final books = await _repository.getBooks();
      final versions = await _repository.getVersions();
      
      BibleVersion? initialVersion;
      if (versions.isNotEmpty) {
        // Prefer 'eng_rv_vpl' or first available
        initialVersion = versions.firstWhere(
          (v) => v.tableName == 'eng_rv_vpl',
          orElse: () => versions.first,
        );
      }

      state = state.copyWith(
        books: books,
        availableVersions: versions,
        currentVersion: initialVersion,
        isLoading: false,
      );
      
      // If no book selected, select Genesis (first one)
      if (state.currentBook == null && books.isNotEmpty) {
        selectBook(books.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectBook(BibleBook book) async {
    if (state.currentBook?.id == book.id) return;

    state = state.copyWith(
      currentBook: book,
      currentChapter: 1,
      verses: [],
    );
    await loadVerses();
  }

  Future<void> selectChapter(int chapter) async {
    if (state.currentChapter == chapter) return;

    state = state.copyWith(
      currentChapter: chapter,
      verses: [],
    );
    await loadVerses();
  }

  Future<void> selectVersion(BibleVersion version) async {
    if (state.currentVersion?.id == version.id) return;
    
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
      final currentIndex = state.books.indexWhere((b) => b.id == state.currentBook?.id);
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
      final currentIndex = state.books.indexWhere((b) => b.id == state.currentBook?.id);
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

    state = state.copyWith(isLoading: true, error: null);
    try {
      final verses = await _repository.getVerses(
        state.currentVersion!.tableName ?? state.currentVersion!.abbreviation,
        state.currentBook!.abbreviation,
        state.currentChapter,
      );
      state = state.copyWith(
        verses: verses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> downloadVersion(BibleVersion version) async {
    if (version.tableName == null) return;
    
    state = state.copyWith(
      downloadingVersionId: version.id,
      downloadProgress: 0.0,
    );

    try {
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
      
      // Update available versions list to reflect downloaded status
      final updatedVersions = state.availableVersions.map((v) {
        if (v.id == version.id) {
          return v.copyWith(isDownloaded: true);
        }
        return v;
      }).toList();

      state = state.copyWith(
        availableVersions: updatedVersions,
        downloadingVersionId: null,
      );
      
      // If this is the current version, reload verses to potentially switch to local DB (handled by repo logic)
      if (state.currentVersion?.id == version.id) {
        loadVerses();
      }
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to download version: $e',
        downloadingVersionId: null,
      );
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
}

