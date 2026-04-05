/// A parsed Bible reference with book, chapter, and optional verse.
class BibleReference {
  final String book;
  final int chapter;
  final int? verse;

  const BibleReference({
    required this.book,
    required this.chapter,
    this.verse,
  });

  @override
  String toString() {
    if (verse != null) {
      return '$book $chapter:$verse';
    }
    return '$book $chapter';
  }
}

/// Parses Bible reference strings into structured [BibleReference] objects.
///
/// Handles:
/// - Simple references: "John 3:16"
/// - Multi-word books: "1 Corinthians 13:4"
/// - Numbered books: "2 Kings 5:1"
/// - Chapter-only references: "Psalm 23"
/// - Verse ranges (takes the starting verse): "Romans 8:28-30"
/// - Multiple references separated by semicolons: "Isaiah 7:14; Micah 5:2"
class BibleReferenceParser {
  // Matches patterns like:
  //   "John 3:16"
  //   "1 Corinthians 13:4"
  //   "Song of Solomon 2:1"
  //   "Psalm 23"
  //   "Romans 8:28-30"
  static final _referenceRegex = RegExp(
    r'((?:\d\s+)?[A-Za-z]+(?:\s+(?:of\s+)?[A-Za-z]+)*)\s+(\d+)(?::(\d+))?',
  );

  /// Parses the first Bible reference from a string.
  ///
  /// Returns `null` if no valid reference is found.
  ///
  /// Example:
  /// ```dart
  /// final ref = BibleReferenceParser.parse("John 3:16");
  /// // ref.book == "John", ref.chapter == 3, ref.verse == 16
  /// ```
  static BibleReference? parse(String reference) {
    final trimmed = reference.trim();
    if (trimmed.isEmpty) return null;

    final match = _referenceRegex.firstMatch(trimmed);
    if (match == null) return null;

    final book = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2)!);
    if (chapter == null) return null;

    final verseStr = match.group(3);
    int? verse;
    if (verseStr != null) {
      // Handle verse ranges like "28-30" by taking the first verse
      final dashIndex = verseStr.indexOf('-');
      if (dashIndex > 0) {
        verse = int.tryParse(verseStr.substring(0, dashIndex));
      } else {
        verse = int.tryParse(verseStr);
      }
    }

    return BibleReference(book: book, chapter: chapter, verse: verse);
  }

  /// Parses all Bible references from a semicolon-separated string.
  ///
  /// Example:
  /// ```dart
  /// final refs = BibleReferenceParser.parseAll("Isaiah 7:14; Micah 5:2");
  /// // refs.length == 2
  /// ```
  static List<BibleReference> parseAll(String references) {
    final parts = references.split(';');
    final results = <BibleReference>[];

    for (final part in parts) {
      final ref = parse(part);
      if (ref != null) {
        results.add(ref);
      }
    }

    return results;
  }
}
