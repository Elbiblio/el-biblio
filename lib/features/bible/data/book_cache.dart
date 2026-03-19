import 'static_books.dart';

/// Cache service for Bible books to improve loading performance
class BookCache {
  static List<BibleBookDefinition>? _oldTestamentBooks;
  static List<BibleBookDefinition>? _newTestamentBooks;
  static Map<String, BibleBookDefinition>? _bookMap;

  /// Get cached Old Testament books or load them if not cached
  static List<BibleBookDefinition> getOldTestamentBooks() {
    _oldTestamentBooks ??= STANDARD_BIBLE_BOOKS.where((book) => book.testament == 'OT').toList();
    return _oldTestamentBooks!;
  }

  /// Get cached New Testament books or load them if not cached
  static List<BibleBookDefinition> getNewTestamentBooks() {
    _newTestamentBooks ??= STANDARD_BIBLE_BOOKS.where((book) => book.testament == 'NT').toList();
    return _newTestamentBooks!;
  }

  /// Get cached book map for quick lookups
  static Map<String, BibleBookDefinition> getBookMap() {
    _bookMap ??= Map.fromEntries(
      STANDARD_BIBLE_BOOKS.map((book) => MapEntry(book.abbreviation, book))
    );
    return _bookMap!;
  }

  /// Get book by abbreviation from cache
  static BibleBookDefinition? getBookByAbbreviation(String abbreviation) {
    return getBookMap()[abbreviation];
  }

  /// Clear cache (useful for testing or when books need to be refreshed)
  static void clearCache() {
    _oldTestamentBooks = null;
    _newTestamentBooks = null;
    _bookMap = null;
  }

  /// Preload all books into cache (call this at app startup)
  static void preloadCache() {
    getOldTestamentBooks();
    getNewTestamentBooks();
    getBookMap();
  }
}
