/// Static Bible book definitions for the standard Protestant canon
/// Used to avoid database queries and provide consistent book ordering
library;

class BibleBookDefinition {
  final String abbreviation;
  final String name;
  final String testament;
  final int chapters;

  const BibleBookDefinition({
    required this.abbreviation,
    required this.name,
    required this.testament,
    required this.chapters,
  });
}

// Standard Protestant Bible books (66 books)
const List<BibleBookDefinition> STANDARD_BIBLE_BOOKS = [
  // Old Testament (39 books)
  BibleBookDefinition(abbreviation: 'GEN', name: 'Genesis', testament: 'OT', chapters: 50),
  BibleBookDefinition(abbreviation: 'EXO', name: 'Exodus', testament: 'OT', chapters: 40),
  BibleBookDefinition(abbreviation: 'LEV', name: 'Leviticus', testament: 'OT', chapters: 27),
  BibleBookDefinition(abbreviation: 'NUM', name: 'Numbers', testament: 'OT', chapters: 36),
  BibleBookDefinition(abbreviation: 'DEU', name: 'Deuteronomy', testament: 'OT', chapters: 34),
  BibleBookDefinition(abbreviation: 'JOS', name: 'Joshua', testament: 'OT', chapters: 24),
  BibleBookDefinition(abbreviation: 'JDG', name: 'Judges', testament: 'OT', chapters: 21),
  BibleBookDefinition(abbreviation: 'RUT', name: 'Ruth', testament: 'OT', chapters: 4),
  BibleBookDefinition(abbreviation: '1SA', name: '1 Samuel', testament: 'OT', chapters: 31),
  BibleBookDefinition(abbreviation: '2SA', name: '2 Samuel', testament: 'OT', chapters: 24),
  BibleBookDefinition(abbreviation: '1KI', name: '1 Kings', testament: 'OT', chapters: 22),
  BibleBookDefinition(abbreviation: '2KI', name: '2 Kings', testament: 'OT', chapters: 25),
  BibleBookDefinition(abbreviation: '1CH', name: '1 Chronicles', testament: 'OT', chapters: 29),
  BibleBookDefinition(abbreviation: '2CH', name: '2 Chronicles', testament: 'OT', chapters: 36),
  BibleBookDefinition(abbreviation: 'EZR', name: 'Ezra', testament: 'OT', chapters: 10),
  BibleBookDefinition(abbreviation: 'NEH', name: 'Nehemiah', testament: 'OT', chapters: 13),
  BibleBookDefinition(abbreviation: 'EST', name: 'Esther', testament: 'OT', chapters: 10),
  BibleBookDefinition(abbreviation: 'JOB', name: 'Job', testament: 'OT', chapters: 42),
  BibleBookDefinition(abbreviation: 'PSA', name: 'Psalms', testament: 'OT', chapters: 150),
  BibleBookDefinition(abbreviation: 'PRO', name: 'Proverbs', testament: 'OT', chapters: 31),
  BibleBookDefinition(abbreviation: 'ECC', name: 'Ecclesiastes', testament: 'OT', chapters: 12),
  BibleBookDefinition(abbreviation: 'SNG', name: 'Song of Solomon', testament: 'OT', chapters: 8),
  BibleBookDefinition(abbreviation: 'ISA', name: 'Isaiah', testament: 'OT', chapters: 66),
  BibleBookDefinition(abbreviation: 'JER', name: 'Jeremiah', testament: 'OT', chapters: 52),
  BibleBookDefinition(abbreviation: 'LAM', name: 'Lamentations', testament: 'OT', chapters: 5),
  BibleBookDefinition(abbreviation: 'EZE', name: 'Ezekiel', testament: 'OT', chapters: 48),
  BibleBookDefinition(abbreviation: 'DAN', name: 'Daniel', testament: 'OT', chapters: 12),
  BibleBookDefinition(abbreviation: 'HOS', name: 'Hosea', testament: 'OT', chapters: 14),
  BibleBookDefinition(abbreviation: 'JOE', name: 'Joel', testament: 'OT', chapters: 3),
  BibleBookDefinition(abbreviation: 'AMO', name: 'Amos', testament: 'OT', chapters: 9),
  BibleBookDefinition(abbreviation: 'OBA', name: 'Obadiah', testament: 'OT', chapters: 1),
  BibleBookDefinition(abbreviation: 'JON', name: 'Jonah', testament: 'OT', chapters: 4),
  BibleBookDefinition(abbreviation: 'MIC', name: 'Micah', testament: 'OT', chapters: 7),
  BibleBookDefinition(abbreviation: 'NAH', name: 'Nahum', testament: 'OT', chapters: 3),
  BibleBookDefinition(abbreviation: 'HAB', name: 'Habakkuk', testament: 'OT', chapters: 3),
  BibleBookDefinition(abbreviation: 'ZEP', name: 'Zephaniah', testament: 'OT', chapters: 3),
  BibleBookDefinition(abbreviation: 'HAG', name: 'Haggai', testament: 'OT', chapters: 2),
  BibleBookDefinition(abbreviation: 'ZEC', name: 'Zechariah', testament: 'OT', chapters: 14),
  BibleBookDefinition(abbreviation: 'MAL', name: 'Malachi', testament: 'OT', chapters: 4),

  // New Testament (27 books)
  BibleBookDefinition(abbreviation: 'MAT', name: 'Matthew', testament: 'NT', chapters: 28),
  BibleBookDefinition(abbreviation: 'MAR', name: 'Mark', testament: 'NT', chapters: 16),
  BibleBookDefinition(abbreviation: 'LUK', name: 'Luke', testament: 'NT', chapters: 24),
  BibleBookDefinition(abbreviation: 'JOH', name: 'John', testament: 'NT', chapters: 21),
  BibleBookDefinition(abbreviation: 'ACT', name: 'Acts', testament: 'NT', chapters: 28),
  BibleBookDefinition(abbreviation: 'ROM', name: 'Romans', testament: 'NT', chapters: 16),
  BibleBookDefinition(abbreviation: '1CO', name: '1 Corinthians', testament: 'NT', chapters: 16),
  BibleBookDefinition(abbreviation: '2CO', name: '2 Corinthians', testament: 'NT', chapters: 13),
  BibleBookDefinition(abbreviation: 'GAL', name: 'Galatians', testament: 'NT', chapters: 6),
  BibleBookDefinition(abbreviation: 'EPH', name: 'Ephesians', testament: 'NT', chapters: 6),
  BibleBookDefinition(abbreviation: 'PHP', name: 'Philippians', testament: 'NT', chapters: 4),
  BibleBookDefinition(abbreviation: 'COL', name: 'Colossians', testament: 'NT', chapters: 4),
  BibleBookDefinition(abbreviation: '1TH', name: '1 Thessalonians', testament: 'NT', chapters: 5),
  BibleBookDefinition(abbreviation: '2TH', name: '2 Thessalonians', testament: 'NT', chapters: 3),
  BibleBookDefinition(abbreviation: '1TI', name: '1 Timothy', testament: 'NT', chapters: 6),
  BibleBookDefinition(abbreviation: '2TI', name: '2 Timothy', testament: 'NT', chapters: 4),
  BibleBookDefinition(abbreviation: 'TIT', name: 'Titus', testament: 'NT', chapters: 3),
  BibleBookDefinition(abbreviation: 'PHM', name: 'Philemon', testament: 'NT', chapters: 1),
  BibleBookDefinition(abbreviation: 'HEB', name: 'Hebrews', testament: 'NT', chapters: 13),
  BibleBookDefinition(abbreviation: 'JAS', name: 'James', testament: 'NT', chapters: 5),
  BibleBookDefinition(abbreviation: '1PE', name: '1 Peter', testament: 'NT', chapters: 5),
  BibleBookDefinition(abbreviation: '2PE', name: '2 Peter', testament: 'NT', chapters: 3),
  BibleBookDefinition(abbreviation: '1JO', name: '1 John', testament: 'NT', chapters: 5),
  BibleBookDefinition(abbreviation: '2JO', name: '2 John', testament: 'NT', chapters: 1),
  BibleBookDefinition(abbreviation: '3JO', name: '3 John', testament: 'NT', chapters: 1),
  BibleBookDefinition(abbreviation: 'JUD', name: 'Jude', testament: 'NT', chapters: 1),
  BibleBookDefinition(abbreviation: 'REV', name: 'Revelation', testament: 'NT', chapters: 22),
];

// Helper functions to get books by testament
List<BibleBookDefinition> getOldTestamentBooks() {
  return STANDARD_BIBLE_BOOKS.where((book) => book.testament == 'OT').toList();
}

List<BibleBookDefinition> getNewTestamentBooks() {
  return STANDARD_BIBLE_BOOKS.where((book) => book.testament == 'NT').toList();
}

BibleBookDefinition? getBookByAbbreviation(String abbreviation) {
  try {
    return STANDARD_BIBLE_BOOKS.firstWhere((book) => book.abbreviation == abbreviation);
  } catch (e) {
    return null;
  }
}

// Map for quick abbreviation to full name lookup
const Map<String, String> BOOK_ABBREVIATION_MAP = {
  'GEN': 'Genesis',
  'EXO': 'Exodus',
  'LEV': 'Leviticus',
  'NUM': 'Numbers',
  'DEU': 'Deuteronomy',
  'JOS': 'Joshua',
  'JDG': 'Judges',
  'RUT': 'Ruth',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Kings',
  '2KI': '2 Kings',
  '1CH': '1 Chronicles',
  '2CH': '2 Chronicles',
  'EZR': 'Ezra',
  'NEH': 'Nehemiah',
  'EST': 'Esther',
  'JOB': 'Job',
  'PSA': 'Psalms',
  'PRO': 'Proverbs',
  'ECC': 'Ecclesiastes',
  'SNG': 'Song of Solomon',
  'ISA': 'Isaiah',
  'JER': 'Jeremiah',
  'LAM': 'Lamentations',
  'EZE': 'Ezekiel',
  'DAN': 'Daniel',
  'HOS': 'Hosea',
  'JOE': 'Joel',
  'AMO': 'Amos',
  'OBA': 'Obadiah',
  'JON': 'Jonah',
  'MIC': 'Micah',
  'NAH': 'Nahum',
  'HAB': 'Habakkuk',
  'ZEP': 'Zephaniah',
  'HAG': 'Haggai',
  'ZEC': 'Zechariah',
  'MAL': 'Malachi',
  'MAT': 'Matthew',
  'MAR': 'Mark',
  'LUK': 'Luke',
  'JOH': 'John',
  'ACT': 'Acts',
  'ROM': 'Romans',
  '1CO': '1 Corinthians',
  '2CO': '2 Corinthians',
  'GAL': 'Galatians',
  'EPH': 'Ephesians',
  'PHP': 'Philippians',
  'COL': 'Colossians',
  '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians',
  '1TI': '1 Timothy',
  '2TI': '2 Timothy',
  'TIT': 'Titus',
  'PHM': 'Philemon',
  'HEB': 'Hebrews',
  'JAS': 'James',
  '1PE': '1 Peter',
  '2PE': '2 Peter',
  '1JO': '1 John',
  '2JO': '2 John',
  '3JO': '3 John',
  'JUD': 'Jude',
  'REV': 'Revelation',
};
