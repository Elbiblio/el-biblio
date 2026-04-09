import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/models/bible_content.dart';
import '../static_books.dart';

/// Enhanced Bible database service with improved offline support
class EnhancedBibleDatabaseService with WidgetsBindingObserver {
  static const String _defaultVersion = 'eng_rv_vpl';
  static const String _defaultAssetPath = 'assets/bibles/rv.db';

  final Logger _logger;
  final DatabaseHelper _dbHelper;
  final Map<String, Database> _databases = {};
  final Map<String, String> _resolvedTableNames = {};
  final Map<String, Map<String, int>> _verseIdMappings = {};
  final String _cdnBaseUrl = 'https://api.elbiblio.com/dbs/';
  static const String _verseIdMappingsKey = 'verse_id_mappings';
  SharedPreferences? _prefs;

  EnhancedBibleDatabaseService(this._logger) : _dbHelper = DatabaseHelper(_logger) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _logger.d('App going to background, keeping database cache for quick resume');
        // Don't close databases on background - keep for quick resume.
        // Only close on detached (app being killed).
        break;
      case AppLifecycleState.resumed:
        _logger.d('App has come to the foreground, validating database connections');
        _validateAllConnections();
        break;
      case AppLifecycleState.detached:
        _logger.d('App detached, cleaning up database resources');
        dispose();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
  
  /// Validate all cached database connections and refresh if needed
  Future<void> _validateAllConnections() async {
    final versionsToValidate = List<String>.from(_databases.keys);

    for (final version in versionsToValidate) {
      try {
        final db = _databases[version];
        if (db != null && !db.isOpen) {
          _logger.w('Database connection for $version is closed, removing from cache');
          _databases.remove(version);
          _resolvedTableNames.remove(version);
        } else if (db != null) {
          await db.rawQuery('SELECT 1');
        }
      } catch (e) {
        _logger.w('Database validation failed for $version: $e');
        _databases.remove(version);
        _resolvedTableNames.remove(version);
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    closeAllDatabases();
  }

  Future<void> closeAllDatabases() async {
    for (final db in _databases.values) {
      try {
        await db.close();
      } catch (_) {
        // Ignore close errors during cleanup
      }
    }
    _databases.clear();
    _resolvedTableNames.clear();
  }

  static final Map<String, String> _bookCodeMap = {
    'GEN': 'GN', 'EXO': 'EX', 'LEV': 'LV', 'NUM': 'NU', 'DEU': 'DT',
    'JOS': 'JS', 'JDG': 'JG', 'RUT': 'RT', '1SA': 'S1', '2SA': 'S2',
    '1KI': 'K1', '2KI': 'K2', '1CH': 'R1', '2CH': 'R2', 'EZR': 'ER',
    'NEH': 'NH', 'EST': 'ET', 'JOB': 'JB', 'PSA': 'PS', 'PRO': 'PR',
    'ECC': 'EC', 'SNG': 'SS', 'ISA': 'IS', 'JER': 'JR', 'LAM': 'LM',
    'EZK': 'EK', 'EZE': 'EK', // static_books uses EZE
    'DAN': 'DN', 'HOS': 'HS',
    'JOL': 'JL', 'JOE': 'JL', // static_books uses JOE
    'AMO': 'AM',
    'OBA': 'OB', 'JON': 'JH', 'MIC': 'MC',
    'NAM': 'NM', 'NAH': 'NM', // static_books uses NAH
    'HAB': 'HK',
    'ZEP': 'ZP', 'HAG': 'HG', 'ZEC': 'ZC', 'MAL': 'ML',
    'MAT': 'MT', 'MRK': 'MK', 'LUK': 'LK', 'JHN': 'JN', 'ACT': 'AC',
    'ROM': 'RM', '1CO': 'C1', '2CO': 'C2', 'GAL': 'GL', 'EPH': 'EP',
    'PHP': 'PH', 'COL': 'CL', '1TH': 'H1', '2TH': 'H2', '1TI': 'T1',
    '2TI': 'T2', 'TIT': 'TT', 'PHM': 'PM', 'HEB': 'HB', 'JAS': 'JM',
    '1PE': 'P1', '2PE': 'P2', '1JN': 'J1', '2JN': 'J2', '3JN': 'J3',
    'JUD': 'JD', 'REV': 'RV',
  };

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _getDbDirectory();
      await _ensureDefaultBible();
      await _loadVerseIdMappings();
      _initialized = true;
    } catch (e) {
      _logger.e('Bible DB init failed (will retry on next access): $e');
      // Don't rethrow — allow graceful degradation with API fallback.
    }
  }

  /// Ensure init has run before any DB operation. Safe to call repeatedly.
  Future<void> ensureInitialized() async {
    if (!_initialized) await init();
  }

  Future<void> _ensureDefaultBible() async {
    try {
      final defaultPath = await _getDbPath(_defaultVersion);
      
      if (!await databaseExists(defaultPath)) {
        await _copyBundledDatabase(_defaultVersion, _defaultAssetPath);
        
        if (await databaseExists(defaultPath)) {
          final file = File(defaultPath);
          final fileSize = await file.length();
          _logger.i('Default Bible copied to: $defaultPath ($fileSize bytes)');
        } else {
          throw Exception('Failed to copy default Bible to: $defaultPath');
        }
      }
    } catch (e) {
      _logger.e('Failed to ensure default Bible: $e');
      rethrow;
    }
  }

  Future<void> _copyBundledDatabase(String version, String assetPath) async {
    try {
      final targetPath = await _getDbPath(version);
      final targetFile = File(targetPath);
      
      if (await databaseExists(targetPath)) {
        return;
      }
      
      try {
        final parentDir = targetFile.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        
        if (!await parentDir.exists()) {
          throw Exception('Failed to create parent directory: ${parentDir.path}');
        }
      } catch (dirError) {
        _logger.e('Directory creation or permission check failed: $dirError');
        throw Exception('Cannot create or write to database directory: $dirError');
      }
      
      final ByteData byteData;
      try {
        byteData = await rootBundle.load(assetPath);
      } catch (e) {
        _logger.e('Asset not found at: $assetPath, error: $e');
        throw Exception('Bible database asset not found: $assetPath');
      }
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

      await targetFile.writeAsBytes(bytes, flush: true);
      
      if (await targetFile.exists()) {
        final fileSize = await targetFile.length();
        if (fileSize > 0) {
          _logger.i('Successfully copied bundled Bible database: $version ($fileSize bytes)');
        } else {
          throw Exception('Copied database file is empty: $targetPath');
        }
      } else {
        throw Exception('Failed to create database file: $targetPath');
      }
      
    } catch (e) {
      _logger.e('Failed to copy bundled Bible database: $e');
      
      try {
        final cleanupPath = await _getDbPath(version);
        final partialFile = File(cleanupPath);
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
      } catch (cleanupError) {
        _logger.w('Failed to clean up partial file: $cleanupError');
      }
      
      rethrow;
    }
  }

  Future<String> _getDbDirectory() async {
    String dbPath;
    try {
      if (Platform.isAndroid) {
        dbPath = await getDatabasesPath();
        final normalizedPath = dbPath.replaceAll('\\', '/');
        final isDartToolPath = normalizedPath == '/.dart_tool' || normalizedPath.startsWith('/.dart_tool/');
        if (dbPath.isEmpty || isDartToolPath || !dbPath.contains(Platform.pathSeparator)) {
          throw Exception('Invalid Android database path: $dbPath');
        }

        final dir = Directory(dbPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir.path;
      } else if (Platform.isIOS) {
        final dir = await getLibraryDirectory();
        dbPath = join(dir.path, 'LocalDatabase');
        return dbPath;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final dir = await getApplicationSupportDirectory();
        final bibleDir = Directory(join(dir.path, 'BibleDBs'));
        
        if (!await bibleDir.exists()) {
          await bibleDir.create(recursive: true);
        }
        
        dbPath = bibleDir.path;
        return dbPath;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final bibleDir = Directory(join(dir.path, 'BibleDBs'));
        
        if (!await bibleDir.exists()) {
          await bibleDir.create(recursive: true);
        }
        
        dbPath = bibleDir.path;
        return dbPath;
      }
    } catch (e) {
      _logger.w('Failed to get standard database path, using fallback: $e');
      
      try {
        final dir = await getApplicationDocumentsDirectory();
        final bibleDir = Directory(join(dir.path, 'BibleDBs'));
        
        if (!await bibleDir.exists()) {
          await bibleDir.create(recursive: true);
        }
        
        dbPath = bibleDir.path;
        return dbPath;
      } catch (fallbackError) {
        _logger.e('Even fallback failed, using temp directory: $fallbackError');
        
        final tempDir = Directory.systemTemp;
        final bibleDir = Directory(join(tempDir.path, 'elbiblio_bibles'));
        
        if (!await bibleDir.exists()) {
          await bibleDir.create(recursive: true);
        }
        
        dbPath = bibleDir.path;
        return dbPath;
      }
    }
  }

  Future<String> _getDbPath(String version) async {
    final dir = await _getDbDirectory();
    final filename = 'bible_$version.db';
    return join(dir, filename);
  }

  Future<bool> isVersionDownloaded(String version) async {
    await ensureInitialized();
    final possibleNames = <String>[
      version,
      version.replaceAll('.db', ''),
      'bible_$version',
      'bible_${version.replaceAll('.db', '')}',
    ];
    
    for (final name in possibleNames) {
      final path = await _getDbPath(name.replaceAll('bible_', ''));
      if (await databaseExists(path)) {
        return true;
      }
    }
    
    if (version == 'eng_rv_vpl' || version == 'RSV' || version == 'engdra_vpl') {
      final defaultPath = await _getDbPath(_defaultVersion);
      if (await databaseExists(defaultPath)) {
        return true;
      }
    }
    return false;
  }

  Future<void> downloadVersion(String version, {required Function(int, int) onProgress}) async {
    try {
      String? downloadUrl;
      try {
        downloadUrl = await _getDownloadUrlForVersion(version);
        if (downloadUrl.isEmpty) {
          downloadUrl = '$_cdnBaseUrl$version.db';
        }
      } catch (e) {
        downloadUrl = '$_cdnBaseUrl$version.db';
      }
      
      await downloadVersionWithUrl(version, downloadUrl: downloadUrl, onProgress: onProgress);
    } catch (e) {
      if (version == _defaultVersion) {
        _logger.d('Download failed for default version, copying from assets');
        await _copyBundledDatabase(version, _defaultAssetPath);
        return;
      }
      rethrow;
    }
  }

  Future<void> downloadVersionWithUrl(String version, {required String downloadUrl, required Function(int, int) onProgress}) async {
    try {
      final path = await _getDbPath(version);
      
      _logger.d('Downloading Bible DB from $downloadUrl to $path');
      
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/octet-stream',
          'User-Agent': 'El-Biblio-App/1.0',
        },
      ));
      
      try {
        final headResponse = await dio.head(downloadUrl);
        _logger.d('HEAD response status: ${headResponse.statusCode}, content-length: ${headResponse.headers['content-length']}');
        
        final contentLength = headResponse.headers['content-length'];
        String? contentLengthStr;
        if (contentLength is List<String> && contentLength.isNotEmpty) {
          contentLengthStr = contentLength.first;
        }
        if (contentLengthStr == '0' || contentLengthStr == null) {
          throw Exception('Download file is empty or not available');
        }
        
        await dio.download(
          downloadUrl,
          path,
          onReceiveProgress: onProgress,
          options: Options(
            receiveTimeout: const Duration(seconds: 120),
          ),
        );
        
        final downloadedFile = File(path);
        if (!await downloadedFile.exists()) {
          throw Exception('Downloaded file not found');
        }
        
        final fileSize = await downloadedFile.length();
        if (fileSize == 0) {
          throw Exception('Downloaded file is empty');
        }
        
        // Validate downloaded database
        if (!await _validateDatabaseIntegrity(path)) {
          throw Exception('Downloaded database failed integrity check');
        }
        
        _logger.i('Bible DB downloaded successfully: $version ($fileSize bytes)');
      } on DioException catch (e) {
        _logger.e('Download failed: ${e.type}', error: e);
        
        final partialFile = File(path);
        if (await partialFile.exists()) {
          await partialFile.delete();
        }
        
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          throw Exception('Download timeout: Please check your internet connection');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('Connection failed: Please check your internet connection');
        } else if (e.response?.statusCode == 404) {
          throw Exception('Bible version not found on server');
        } else if (e.response?.statusCode == 403) {
          throw Exception('Access denied: Download not authorized');
        } else {
          throw Exception('Download failed: ${e.message ?? 'Unknown error'}');
        }
      } finally {
        dio.close();
      }
      
    } catch (e) {
      _logger.e('Failed to download Bible DB', error: e);
      throw Exception('Failed to download Bible version: $e');
    }
  }

  Future<bool> _validateDatabaseIntegrity(String dbPath) async {
    try {
      final db = await openDatabase(dbPath, readOnly: true);
      
      // Check if database has required tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      if (tables.isEmpty) {
        await db.close();
        return false;
      }
      
      // Check if main table has required columns
      final tableName = tables.first['name'] as String;
      final columns = await db.rawQuery("PRAGMA table_info($tableName)");
      
      final requiredColumns = ['book', 'chapter', 'startVerse', 'verseText'];
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      final hasAllColumns = requiredColumns.every((col) => columnNames.contains(col));
      
      await db.close();
      return hasAllColumns;
    } catch (e) {
      _logger.e('Database integrity validation failed: $e');
      return false;
    }
  }

  Future<Database> _getDatabase(String version, {Function(String, double)? onAutoDownloadProgress}) async {
    if (_databases.containsKey(version)) {
      final db = _databases[version]!;
      if (db.isOpen) {
        try {
          await db.rawQuery('SELECT 1');
          return db;
        } catch (e) {
          _logger.w('Cached database connection invalid for $version, reopening: $e');
          _databases.remove(version);
          try {
            await db.close();
          } catch (_) {
            // Already broken, ignore close error
          }
          // Fall through to open fresh
        }
      } else {
        _logger.w('Cached database for $version is closed, removing from cache');
        _databases.remove(version);
      }
    }

    final path = await _getDbPath(version);
    
    if (!await databaseExists(path)) {
      _logger.d('Database file not found for $version, attempting auto-download');
      try {
        final downloadUrl = await _getDownloadUrlForVersion(version);
        if (downloadUrl.isNotEmpty) {
          _logger.d('Auto-downloading missing Bible database: $version from $downloadUrl');
          
          await downloadVersionWithUrl(
            version,
            downloadUrl: downloadUrl,
            onProgress: (received, total) {
              if (total > 0) {
                final progress = (received / total * 100).round();
                _logger.d('Auto-download progress for $version: $progress%');
                
                onAutoDownloadProgress?.call(version, received / total);
              }
            },
          );
          
          _logger.i('Auto-download completed for $version');
        } else {
          _logger.w('No download URL found for version $version');
          throw Exception('Database for version $version not found and no download URL available');
        }
      } catch (e) {
        _logger.e('Auto-download failed for $version: $e');
        throw Exception('Database for version $version not found and auto-download failed: $e');
      }
    }

    try {
      final db = await openDatabase(path, readOnly: true, singleInstance: true);

      try {
        await db.rawQuery('SELECT count(*) FROM sqlite_master');
      } catch (e) {
        await db.close();
        throw Exception('Database integrity check failed for version $version: $e');
      }
      
      _databases[version] = db;
      return db;
    } catch (e) {
      _logger.e('Failed to open database: $path', error: e);
      throw Exception('Failed to open database for version $version: $e');
    }
  }

  Future<String> _getDownloadUrlForVersion(String version) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      final response = await dio.get('https://api.elbiblio.com/dbs/versions.json');
      
      if (response.data is List) {
        for (final item in response.data) {
          if (item is Map<String, dynamic>) {
            final tableName = item['tableName']?.toString();
            final downloadUrl = item['downloadUrl']?.toString();
            
            if (tableName == version && downloadUrl?.isNotEmpty == true) {
              dio.close();
              return downloadUrl!;
            }
          }
        }
      }
      
      dio.close();
    } catch (e) {
      _logger.e('Failed to get download URL for $version: $e');
    }
    
    return '';
  }

  Future<T> executeWithRetry<T>(
    String version,
    Future<T> Function(Database db) operation, {
    int maxRetries = 2,
    Function(String, double)? onAutoDownloadProgress,
  }) async {
    int retries = 0;

    while (retries <= maxRetries) {
      try {
        final db = await _getDatabase(version, onAutoDownloadProgress: onAutoDownloadProgress);
        return await operation(db);
      } catch (e) {
        retries++;
        final errorMessage = e.toString().toLowerCase();

        // Network errors: fail fast, no retry
        if (errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('internet')) {
          _logger.w('Network error detected, failing fast for offline mode: $e');
          rethrow;
        }

        // Database errors that are retryable: closed, locked, corrupt, disk I/O
        final isRetryable = errorMessage.contains('closed') ||
            errorMessage.contains('locked') ||
            errorMessage.contains('disk i/o') ||
            errorMessage.contains('unable to open') ||
            errorMessage.contains('not a database') ||
            errorMessage.contains('no such table');

        if (isRetryable && retries <= maxRetries) {
          _logger.w('Database error for $version (attempt $retries/$maxRetries), retrying: $e');
          _databases.remove(version);
          _resolvedTableNames.remove(version);
          await Future.delayed(Duration(milliseconds: 200 * retries));
          continue;
        }

        if (retries > maxRetries) {
          throw Exception('Failed after $maxRetries attempts: $e');
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Operation failed after $maxRetries retries');
  }

  Future<String> _resolveTableName(Database db, String version) async {
    // Check cache first to avoid repeated sqlite_master queries
    if (_resolvedTableNames.containsKey(version)) {
      return _resolvedTableNames[version]!;
    }

    final baseName = version.replaceAll('.db', '');

    String cacheAndReturn(String tableName) {
      _resolvedTableNames[version] = tableName;
      return tableName;
    }

    // Fast path: if the exact base name exists and has 'book' column
    if (await _dbHelper.validateTable(db, baseName, requiredColumns: ['book'])) {
      return cacheAndReturn(baseName);
    }

    // Fallback: examine all available tables
    final tables = await _dbHelper.getAvailableTables(db);
    final validTables = tables
        .where((t) =>
            t.toLowerCase() != 'android_metadata' &&
            t.toLowerCase() != 'sqlite_sequence')
        .toList();

    if (validTables.isEmpty) {
      _logger.w('No valid data tables found in database for $version, trying default table names');
      // Try common default table names as fallback
      final defaultTables = ['bible_verses', 'verses', 'scripture', 'eng_rv_vpl', baseName];
      for (final defaultTable in defaultTables) {
        if (tables.contains(defaultTable)) {
          _logger.d('Using default table: $defaultTable');
          return cacheAndReturn(defaultTable);
        }
      }
      throw Exception('No valid data tables found in database for $version');
    }

    // If there's exactly one data table, it's highly likely the correct one
    if (validTables.length == 1) {
      return cacheAndReturn(validTables.first);
    }

    // Otherwise, look for common patterns
    for (final table in validTables) {
      final lower = table.toLowerCase();
      if (lower.contains('bible') ||
          lower.contains('verse') ||
          lower == baseName.toLowerCase() ||
          lower == 'eng_rv_vpl') {
        return cacheAndReturn(table);
      }
    }

    // Ultimate fallback to the first valid table
    return cacheAndReturn(validTables.first);
  }

  Future<List<BibleVerseContent>> getChapter(String version, String bookAbbr, int chapter, {Function(String, double)? onAutoDownloadProgress}) async {
    await ensureInitialized();
    return executeWithRetry<List<BibleVerseContent>>(
      version,
      (db) async {
      final tableName = await _resolveTableName(db, version);

      if (chapter <= 0) {
        _logger.w('Invalid chapter number: $chapter');
        return [];
      }

      final query = 'SELECT verseID, startVerse, verseText FROM $tableName WHERE book = ? AND chapter = ? ORDER BY CAST(startVerse AS INTEGER)';

      // Try multiple book code variations for robustness
      final codesToTry = _getBookCodeVariations(bookAbbr);

      for (final code in codesToTry) {
        try {
          final maps = await db.rawQuery(query, [code, chapter]);
          if (maps.isNotEmpty) {
            return maps.map((map) => _mapToContent(map, bookAbbr, chapter, version)).toList();
          }
        } catch (e) {
          _logger.d('Failed to query table $tableName with book code "$code": $e');
        }
      }

      _logger.d('No verses found for $bookAbbr chapter $chapter in table $tableName (tried codes: $codesToTry)');
      return [];
    }, onAutoDownloadProgress: onAutoDownloadProgress);
  }

  /// Returns all possible book code variations for a given abbreviation,
  /// covering mismatches between standard abbreviations and database-specific codes.
  List<String> _getBookCodeVariations(String abbrev) {
    final upperAbbrev = abbrev.toUpperCase();
    final variations = <String>[upperAbbrev];

    // Try the database-specific mapped code (e.g. GEN -> GN)
    if (_bookCodeMap.containsKey(upperAbbrev)) {
      variations.add(_bookCodeMap[upperAbbrev]!);
    }

    // Try reverse lookup: if abbrev is already a mapped code, find the standard one
    for (final entry in _bookCodeMap.entries) {
      if (entry.value == upperAbbrev && !variations.contains(entry.key)) {
        variations.add(entry.key);
      }
    }

    // Try the static_books abbreviation (handles MAR vs MRK, JOH vs JHN, etc.)
    final bookDef = standardBibleBooks.where((b) => b.abbreviation == upperAbbrev).firstOrNull;
    if (bookDef != null) {
      // Add full book name as some databases use it
      if (!variations.contains(bookDef.name)) {
        variations.add(bookDef.name);
      }
    } else {
      // abbrev might not match static_books - try finding by _bookCodeMap cross-reference
      // e.g. if abbrev is MRK but static_books has MAR
      for (final book in standardBibleBooks) {
        if (_bookCodeMap[book.abbreviation] == _bookCodeMap[upperAbbrev] &&
            !variations.contains(book.abbreviation)) {
          variations.add(book.abbreviation);
        }
      }
    }

    // Additional cross-reference: static_books uses different abbrevs than _bookCodeMap keys
    // Handle known divergences explicitly
    const crossRefCodes = <String, List<String>>{
      'MRK': ['MAR', 'MK'],
      'MAR': ['MRK', 'MK'],
      'JHN': ['JOH', 'JN'],
      'JOH': ['JHN', 'JN'],
      '1JN': ['1JO', 'J1'],
      '1JO': ['1JN', 'J1'],
      '2JN': ['2JO', 'J2'],
      '2JO': ['2JN', 'J2'],
      '3JN': ['3JO', 'J3'],
      '3JO': ['3JN', 'J3'],
      'EZK': ['EZE', 'EK'],
      'EZE': ['EZK', 'EK'],
      'JOL': ['JOE', 'JL'],
      'JOE': ['JOL', 'JL'],
      'NAM': ['NAH', 'NM'],
      'NAH': ['NAM', 'NM'],
    };

    if (crossRefCodes.containsKey(upperAbbrev)) {
      for (final alt in crossRefCodes[upperAbbrev]!) {
        if (!variations.contains(alt)) {
          variations.add(alt);
        }
      }
    }

    // Try lowercase and common truncations
    variations.add(upperAbbrev.toLowerCase());
    if (upperAbbrev.length > 3) {
      variations.add(upperAbbrev.substring(0, 3));
    }

    return variations.toSet().toList(); // Deduplicate
  }

  BibleVerseContent _mapToContent(Map<String, dynamic> map, String bookAbbr, int chapter, String version) {
    final verseNum = int.tryParse(map['startVerse'].toString()) ?? 0;
    final text = (map['verseText']?.toString() ?? '').trim();
    final reference = '$bookAbbr $chapter:$verseNum';
    
    if (verseNum <= 0 || text.isEmpty) {
      _logger.w('Invalid verse data: verse=$verseNum, text="${text.length > 50 ? text.substring(0, 50) : text}..."');
    }
    
    // Generate consistent ID using SHA-256 hash for better uniqueness
    final idBytes = utf8.encode('$version:$reference');
    final idHash = sha256.convert(idBytes);
    final id = int.parse(idHash.toString().substring(0, 8), radix: 16) & 0x7FFFFFFF;

    return BibleVerseContent(
      id: id, 
      bookId: 0, // Will be populated by backend if needed
      chapter: chapter,
      verse: verseNum,
      text: text,
      reference: reference,
    );
  }

  Future<void> _loadVerseIdMappings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final mappingsJson = _prefs!.getString(_verseIdMappingsKey);
      if (mappingsJson != null) {
        final decoded = jsonDecode(mappingsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final version = entry.key;
          final innerMap = entry.value as Map<String, dynamic>;
          _verseIdMappings[version] = {
            for (final e in innerMap.entries) e.key: e.value as int
          };
        }
        _logger.d('Loaded ${_verseIdMappings.length} verse ID mappings from storage');
      }
    } catch (e) {
      _logger.w('Failed to load verse ID mappings: $e');
    }
  }

  /// Save verse ID mappings to SharedPreferences
  Future<void> _saveVerseIdMappings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final encoded = {
        for (final entry in _verseIdMappings.entries)
          entry.key: entry.value
      };
      await _prefs!.setString(_verseIdMappingsKey, jsonEncode(encoded));
      _logger.d('Saved ${_verseIdMappings.length} verse ID mappings to storage');
    } catch (e) {
      _logger.w('Failed to save verse ID mappings: $e');
    }
  }

  Future<int> getBackendVerseId(String version, String bookAbbr, int chapter, int verse) async {
    final reference = '$bookAbbr $chapter:$verse';
    
    // Check if we have a cached mapping
    if (_verseIdMappings.containsKey(version) && 
        _verseIdMappings[version]!.containsKey(reference)) {
      return _verseIdMappings[version]![reference]!;
    }
    
    // Generate a consistent temporary ID
    final idBytes = utf8.encode('$version:$reference');
    final idHash = sha256.convert(idBytes);
    final tempId = int.parse(idHash.toString().substring(0, 8), radix: 16) & 0x7FFFFFFF;
    
    // Cache the temporary mapping
    _verseIdMappings.putIfAbsent(version, () => {})[reference] = tempId;
    
    return tempId;
  }

  Future<void> updateVerseIdMapping(String version, String bookAbbr, int chapter, int verse, int backendId) async {
    final reference = '$bookAbbr $chapter:$verse';
    _verseIdMappings.putIfAbsent(version, () => {})[reference] = backendId;
    _logger.d('Updated verse ID mapping for $reference -> $backendId');
    await _saveVerseIdMappings();
  }

  Future<List<String>> getAvailableBooks(String version) async {
    return executeWithRetry<List<String>>(
      version, 
      (db) async {
      try {
        final tableName = await _resolveTableName(db, version);
        
        return await _dbHelper.getDistinctValues(
          db,
          tableName,
          'book',
          orderBy: 'book',
        );
      } catch (e) {
        _logger.w('Failed to get available books via _resolveTableName: $e');
        return [];
      }
    });
  }

  Future<int> getChapterCount(String version, String bookAbbr) async {
    return executeWithRetry<int>(
      version, 
      (db) async {
      try {
        final tableName = await _resolveTableName(db, version);
        
        return await _dbHelper.getMaxValue(
          db,
          tableName,
          'chapter',
          where: 'book = ?',
          whereArgs: [bookAbbr],
          defaultValue: 0,
        );
      } catch (e) {
        _logger.w('Failed to get chapter count via _resolveTableName: $e');
        return 0;
      }
    });
  }

  Future<List<BibleVerseContent>> searchVerses(String version, String query, {int limit = 100}) async {
    return executeWithRetry<List<BibleVerseContent>>(
      version, 
      (db) async {
      if (query.trim().isEmpty) {
        _logger.w('Empty search query provided');
        return [];
      }
      
      final tableName = await _resolveTableName(db, version);
      final ftsTableName = 'fts_$tableName';
      
      try {
        final List<Map<String, dynamic>> maps = await db.rawQuery('''
          SELECT 
            t.verseID, 
            t.book, 
            t.chapter, 
            t.startVerse, 
            t.verseText,
            snippet($ftsTableName, '<b>', '</b>', '...', -1, 64) as snippet
          FROM $ftsTableName f
          JOIN $tableName t ON t.rowid = f.docid
          WHERE $ftsTableName MATCH ?
          ORDER BY t.rowid ASC
          LIMIT ?
        ''', ['${query.replaceAll(RegExp(r'[^\w\s]'), '')}*', limit > 0 ? limit : -1]);

        return maps.map((map) {
          final verse = int.tryParse(map['startVerse'].toString()) ?? 0;
          final chapter = int.tryParse(map['chapter'].toString()) ?? 0;
          final bookAbbr = map['book']?.toString() ?? '';
          final text = map['snippet']?.toString() ?? map['verseText']?.toString() ?? '';
          final reference = '$bookAbbr $chapter:$verse';
          
          return BibleVerseContent(
            id: int.parse(sha256.convert(utf8.encode('$version:$reference')).toString().substring(0, 8), radix: 16) & 0x7FFFFFFF,
            bookId: 0,
            chapter: chapter,
            verse: verse,
            text: text,
            reference: reference,
          );
        }).where((verse) => verse.verse > 0 && verse.text.isNotEmpty).toList();
      } catch (e) {
        _logger.w('FTS search failed, falling back to LIKE: $e');

        // Fallback to LIKE query - also wrapped in try-catch for robustness
        try {
          final List<Map<String, dynamic>> maps = await db.query(
            tableName,
            columns: ['verseID', 'book', 'chapter', 'startVerse', 'verseText'],
            where: 'verseText LIKE ?',
            whereArgs: ['%$query%'],
            orderBy: 'rowid ASC',
            limit: limit > 0 ? limit : null,
          );

          return maps.map((map) {
            final verse = int.tryParse(map['startVerse'].toString()) ?? 0;
            final chapter = int.tryParse(map['chapter'].toString()) ?? 0;
            final bookAbbr = map['book']?.toString() ?? '';
            final text = (map['verseText']?.toString() ?? '').trim();
            final reference = '$bookAbbr $chapter:$verse';

            return BibleVerseContent(
              id: int.parse(sha256.convert(utf8.encode('$version:$reference')).toString().substring(0, 8), radix: 16) & 0x7FFFFFFF,
              bookId: 0,
              chapter: chapter,
              verse: verse,
              text: text,
              reference: reference,
            );
          }).where((verse) => verse.verse > 0 && verse.text.isNotEmpty).toList();
        } catch (likeError) {
          _logger.e('LIKE search fallback also failed: $likeError');
          return [];
        }
      }
    });
  }

  Future<Map<String, dynamic>> getDatabaseStats(String version) async {
    try {
      final db = await _getDatabase(version);
      final tableName = await _resolveTableName(db, version);

      final verseCount = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final bookCount = await db.rawQuery('SELECT COUNT(DISTINCT book) as count FROM $tableName');
      final chapterCount = await db.rawQuery('SELECT COUNT(DISTINCT book || chapter) as count FROM $tableName');

      // Do NOT close db here - it is cached in _databases and closing it
      // would cause "database is closed" errors for subsequent operations.
      final hasFts = await _hasFullTextSearch(db, tableName);

      return {
        'version': version,
        'tableName': tableName,
        'verseCount': verseCount.first['count'],
        'bookCount': bookCount.first['count'],
        'chapterCount': chapterCount.first['count'],
        'hasFullTextSearch': hasFts,
      };
    } catch (e) {
      _logger.e('Failed to get database stats for $version: $e');
      return {};
    }
  }

  Future<bool> _hasFullTextSearch(Database db, String tableName) async {
    try {
      final ftsTableName = 'fts_$tableName';
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [ftsTableName]
      );
      return tables.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> optimizeDatabase(String version) async {
    try {
      final db = await _getDatabase(version);

      // Run VACUUM to optimize database
      await db.execute('VACUUM');

      // Analyze tables for better query planning
      await db.execute('ANALYZE');

      // Do NOT close db here - it is cached in _databases.
      _logger.i('Database optimized for version: $version');
    } catch (e) {
      _logger.e('Failed to optimize database for $version: $e');
    }
  }
}
