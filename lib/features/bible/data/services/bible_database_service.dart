import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/bible_content.dart';

class BibleDatabaseService {
  BibleDatabaseService(this._logger);

  final Logger _logger;
  final Map<String, Database> _databases = {};
  final String _cdnBaseUrl = 'https://api.elbiblio.com/dbs/';

  static final Map<String, String> _bookCodeMap = {
    'GEN': 'GN', 'EXO': 'EX', 'LEV': 'LV', 'NUM': 'NU', 'DEU': 'DT',
    'JOS': 'JS', 'JDG': 'JG', 'RUT': 'RT', '1SA': 'S1', '2SA': 'S2',
    '1KI': 'K1', '2KI': 'K2', '1CH': 'R1', '2CH': 'R2', 'EZR': 'ER',
    'NEH': 'NH', 'EST': 'ET', 'JOB': 'JB', 'PSA': 'PS', 'PRO': 'PR',
    'ECC': 'EC', 'SNG': 'SS', 'ISA': 'IS', 'JER': 'JR', 'LAM': 'LM',
    'EZK': 'EK', 'DAN': 'DN', 'HOS': 'HS', 'JOL': 'JL', 'AMO': 'AM',
    'OBA': 'OB', 'JON': 'JH', 'MIC': 'MC', 'NAM': 'NM', 'HAB': 'HK',
    'ZEP': 'ZP', 'HAG': 'HG', 'ZEC': 'ZC', 'MAL': 'ML',
    'MAT': 'MT', 'MRK': 'MK', 'LUK': 'LK', 'JHN': 'JN', 'ACT': 'AC',
    'ROM': 'RM', '1CO': 'C1', '2CO': 'C2', 'GAL': 'GL', 'EPH': 'EP',
    'PHP': 'PH', 'COL': 'CL', '1TH': 'H1', '2TH': 'H2', '1TI': 'T1',
    '2TI': 'T2', 'TIT': 'TT', 'PHM': 'PM', 'HEB': 'HB', 'JAS': 'JM',
    '1PE': 'P1', '2PE': 'P2', '1JN': 'J1', '2JN': 'J2', '3JN': 'J3',
    'JUD': 'JD', 'REV': 'RV',
    // Apocrypha
    'TOB': 'TB', 'JDT': 'JT', 'WIS': 'WS', 'SIR': 'SR', 'BAR': 'BR', 'LJE': 'LJ',
    '1MA': 'M1', '2MA': 'M2', '1ES': 'E1', '2ES': 'E2', 'MAN': 'PN', 'PS2': 'PA'
  };

  Future<void> init() async {
    // Ensure directory exists
    await _getDbDirectory();
  }

  Future<String> _getDbDirectory() async {
    if (Platform.isAndroid) {
      return await getDatabasesPath();
    } else if (Platform.isIOS) {
      final dir = await getLibraryDirectory();
      return join(dir.path, 'LocalDatabase');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return join(dir.path, 'BibleDBs');
    }
  }

  Future<String> _getDbPath(String version) async {
    final dir = await _getDbDirectory();
    // Normalize version name to match filename on server/local
    // Assuming version.tableName or version.abbreviation is used. 
    // In database.ts: const getDbFile = (version: string) => new File(Paths.document, 'SQLite', `${DB_PREFIX}${version}.db`);
    // DB_PREFIX = 'bible_'
    final filename = 'bible_$version.db';
    return join(dir, filename);
  }

  Future<bool> isVersionDownloaded(String version) async {
    final path = await _getDbPath(version);
    return File(path).exists();
  }

  Future<void> downloadVersion(String version, {required Function(int, int) onProgress}) async {
    try {
      final path = await _getDbPath(version);
      final url = '$_cdnBaseUrl$version.db';
      
      _logger.d('Downloading Bible DB from $url to $path');
      
      // Ensure directory exists
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final dio = Dio();
      await dio.download(
        url,
        path,
        onReceiveProgress: onProgress,
      );
      
      _logger.i('Bible DB downloaded successfully: $version');
    } catch (e) {
      _logger.e('Failed to download Bible DB', error: e);
      throw Exception('Failed to download Bible version: $e');
    }
  }

  Future<Database> _getDatabase(String version) async {
    if (_databases.containsKey(version)) {
      return _databases[version]!;
    }

    final path = await _getDbPath(version);
    if (!await File(path).exists()) {
      throw Exception('Database for version $version not found');
    }

    final db = await openDatabase(path, readOnly: true);
    _databases[version] = db;
    return db;
  }

  Future<List<BibleVerseContent>> getChapter(String version, String bookAbbr, int chapter) async {
    try {
      final db = await _getDatabase(version);
      final tableName = version.replaceAll('.db', '');
      
      // Use mapping if available, otherwise fallback to input abbr
      final bookCode = _bookCodeMap[bookAbbr.toUpperCase()] ?? bookAbbr;
      
      // The DB schema likely uses 'verseID' like 'GN1_1' or similar, 
      // OR it has 'book' 'chapter' columns.
      // Based on database.ts: 
      // SELECT verseID, startVerse, verseText FROM ${normalizedVersion} WHERE book = ? AND chapter = ?
      // It seems 'book' column stores the mapped code (e.g. 'GN') or the Abbr? 
      // database.ts uses `bookCodeMap[bookAbbr]` to generate VPLId, but `getChapter` query uses `where book = ?` passing `book` arg.
      // Wait, `getChapter` in database.ts:
      // `SELECT ... WHERE book = ? AND chapter = ?`
      // It passes `book` argument. 
      // But `getVerse` uses `verseID` with mapping.
      // Let's assume the 'book' column in SQLite uses the mapped code if `verseID` does. 
      // But actually, `getChapter` in `database.ts` is passed `book`. 
      // And in `BibleStore.ts`: `BibleDBService.getVerse(..., bookAbbr, ...)`
      // Let's try Querying with the mapped code first.
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        columns: ['verseID', 'startVerse', 'verseText'],
        where: 'book = ? AND chapter = ?',
        whereArgs: [bookCode, chapter],
        orderBy: 'CAST(startVerse AS INTEGER)',
      );

      // If no results, maybe try original abbr?
      if (maps.isEmpty && bookCode != bookAbbr) {
         final retryMaps = await db.query(
          tableName,
          columns: ['verseID', 'startVerse', 'verseText'],
          where: 'book = ? AND chapter = ?',
          whereArgs: [bookAbbr, chapter],
          orderBy: 'CAST(startVerse AS INTEGER)',
        );
        if (retryMaps.isNotEmpty) {
           return retryMaps.map((map) => _mapToContent(map, bookAbbr, chapter)).toList();
        }
      }

      return maps.map((map) => _mapToContent(map, bookAbbr, chapter)).toList();
    } catch (e) {
      _logger.e('Error querying chapter from local DB', error: e);
      return [];
    }
  }

  BibleVerseContent _mapToContent(Map<String, dynamic> map, String bookAbbr, int chapter) {
    final verse = int.tryParse(map['startVerse'].toString()) ?? 0;
    final text = map['verseText'].toString().trim();
    final reference = '$bookAbbr $chapter:$verse';
    
    // Generate a pseudo-ID for local verses to ensure UI list uniqueness.
    // Note: These IDs will not work with backend actions (highlight/bookmark) 
    // unless the backend supports lookup by reference or we sync differently.
    // Using hashCode ensures consistency for the same verse.
    final id = reference.hashCode;

    return BibleVerseContent(
      id: id, 
      bookId: 0, 
      chapter: chapter,
      verse: verse,
      text: text,
      reference: reference,
    );
  }

  Future<List<String>> getAvailableBooks(String version) async {
    try {
      final db = await _getDatabase(version);
      final tableName = version.replaceAll('.db', '');
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT DISTINCT book FROM $tableName ORDER BY book' // Note: Ordering by book might be alphabetical, usually we want canonical.
        // Canon order usually requires a mapping or a canon_order column.
      );
      
      return maps.map((e) => e['book'] as String).toList();
    } catch (e) {
      _logger.e('Error querying books from local DB', error: e);
      return [];
    }
  }

  Future<List<BibleVerseContent>> searchVerses(String version, String query, {int limit = 100}) async {
    try {
      final db = await _getDatabase(version);
      final tableName = version.replaceAll('.db', '');
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        columns: ['verseID', 'book', 'chapter', 'startVerse', 'verseText'],
        where: 'verseText LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'verseID ASC',
        limit: limit,
      );

      return maps.map((map) {
        final verse = int.tryParse(map['startVerse'].toString()) ?? 0;
        final chapter = int.tryParse(map['chapter'].toString()) ?? 0;
        final bookAbbr = map['book'].toString();
        
        return BibleVerseContent(
          id: 0,
          bookId: 0,
          chapter: chapter,
          verse: verse,
          text: map['verseText'].toString().trim(),
          reference: '$bookAbbr $chapter:$verse',
        );
      }).toList();
    } catch (e) {
      _logger.e('Error searching verses in local DB', error: e);
      return [];
    }
  }
}
