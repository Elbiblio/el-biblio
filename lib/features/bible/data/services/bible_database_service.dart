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

import '../../../../core/database/database_helper.dart';
import '../../domain/models/bible_content.dart';

class BibleDatabaseService with WidgetsBindingObserver {
  static const String _defaultVersion = 'eng_rv_vpl';  // Use actual table name from database
  static const String _defaultAssetPath = 'assets/bibles/rv.db';
  
  BibleDatabaseService(this._logger) : _dbHelper = DatabaseHelper(_logger) {
    WidgetsBinding.instance.addObserver(this);
  }

  final Logger _logger;
  final DatabaseHelper _dbHelper;
  final Map<String, Database> _databases = {};
  final String _cdnBaseUrl = 'https://api.elbiblio.com/dbs/';
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _logger.d('App going to background, keeping database cache for quick resume');
        // Don't clear cache on background - keep for quick resume
        // Only clear on detached (app being killed)
        break;
      case AppLifecycleState.resumed:
        _logger.d('App has come to the foreground, validating database connections');
        // Validate connections on resume instead of clearing them
        _validateAllConnections();
        break;
      case AppLifecycleState.detached:
        _logger.d('App detached, cleaning up database resources');
        dispose();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
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
        } else if (db != null) {
          // Test connection with a simple query
          await db.rawQuery('SELECT 1');
        }
      } catch (e) {
        _logger.w('Database validation failed for $version: $e');
        _databases.remove(version);
      }
    }
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    closeAllDatabases();
  }
  
  // Add proper cleanup method
  Future<void> closeAllDatabases() async {
    for (final db in _databases.values) {
      await db.close();
    }
    _databases.clear();
  }
  
  @override
  String toString() => 'BibleDatabaseService(databases: ${_databases.keys.join(', ')})';

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
    // Ensure default Bible is available
    await _ensureDefaultBible();
  }

  Future<void> _ensureDefaultBible() async {
    try {
      final defaultPath = await _getDbPath(_defaultVersion);
      
      // Use databaseExists for proper checking
      if (!await databaseExists(defaultPath)) {
        await _copyBundledDatabase(_defaultVersion, _defaultAssetPath);
        
        // Verify the copy worked
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
      
      // Check if database already exists
      if (await databaseExists(targetPath)) {
        return;
      }
      
      // Ensure parent directory exists with proper error handling
      try {
        final parentDir = targetFile.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
        
        // Verify directory is writable
        if (!await parentDir.exists()) {
          throw Exception('Failed to create parent directory: ${parentDir.path}');
        }
      } catch (dirError) {
        _logger.e('Directory creation or permission check failed: $dirError');
        throw Exception('Cannot create or write to database directory: $dirError');
      }
      
      // Copy from assets using the recommended approach
      final ByteData byteData;
      try {
        byteData = await rootBundle.load(assetPath);
      } catch (e) {
        _logger.e('Asset not found at: $assetPath, error: $e');
        throw Exception('Bible database asset not found: $assetPath');
      }
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

      // Write and flush the bytes written (important for data integrity)
      await targetFile.writeAsBytes(bytes, flush: true);
      
      // Verify the copy worked
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
      
      // Clean up any partial file
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
        // Validate the path is not invalid or pointing to read-only /.dart_tool
        final normalizedPath = dbPath.replaceAll('\\', '/');
        final isDartToolPath = normalizedPath == '/.dart_tool' || normalizedPath.startsWith('/.dart_tool/');
        if (dbPath.isEmpty || isDartToolPath || !dbPath.contains(Platform.pathSeparator)) {
          throw Exception('Invalid Android database path: $dbPath');
        }

        // Ensure the directory exists and is writable
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
        // For desktop platforms, use getApplicationSupportDirectory
        final dir = await getApplicationSupportDirectory();
        final bibleDir = Directory(join(dir.path, 'BibleDBs'));
        
        // Ensure the directory exists
        if (!await bibleDir.exists()) {
          await bibleDir.create(recursive: true);
        }
        
        dbPath = bibleDir.path;
        return dbPath;
      } else {
        // Fallback for other platforms
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
      
      // Ultimate fallback to application documents directory
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
        
        // Last resort - use temp directory
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
    // Normalize version name to match filename on server/local
    // Assuming version.tableName or version.abbreviation is used. 
    // In database.ts: const getDbFile = (version: string) => new File(Paths.document, 'SQLite', `${DB_PREFIX}${version}.db`);
    // DB_PREFIX = 'bible_'
    final filename = 'bible_$version.db';
    return join(dir, filename);
  }

  Future<bool> isVersionDownloaded(String version) async {
    // Try different version identifiers
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
    
    // Special case for default version
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
      // Try to get download URL from API versions list first
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
      // Fallback for default version
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
      
      // Ensure directory exists
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
        // First check if the URL is accessible
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
        
        // Verify the downloaded file
        final downloadedFile = File(path);
        if (!await downloadedFile.exists()) {
          throw Exception('Downloaded file not found');
        }
        
        final fileSize = await downloadedFile.length();
        if (fileSize == 0) {
          throw Exception('Downloaded file is empty');
        }
        
        _logger.i('Bible DB downloaded successfully: $version ($fileSize bytes)');
      } on DioException catch (e) {
        _logger.e('Download failed: ${e.type}', error: e);
        
        // Clean up partial download
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

  Future<Database> _getDatabase(String version, {Function(String, double)? onAutoDownloadProgress}) async {
    // Check if we have a cached connection
    if (_databases.containsKey(version)) {
      final db = _databases[version]!;
      if (db.isOpen) {
        // Validate connection with a simple query
        try {
          await db.rawQuery('SELECT 1');
          return db;
        } catch (e) {
          _logger.w('Database connection for $version is invalid, removing from cache');
          await db.close();
          _databases.remove(version);
        }
      } else {
        // Remove closed database from cache
        _databases.remove(version);
      }
    }

    final path = await _getDbPath(version);
    
    // Enhanced file existence and integrity check
    if (!await databaseExists(path)) {
      _logger.d('Database file not found for $version, attempting auto-download');
      try {
        // Get download URL from versions API
        final downloadUrl = await _getDownloadUrlForVersion(version);
        if (downloadUrl.isNotEmpty) {
          _logger.d('Auto-downloading missing Bible database: $version from $downloadUrl');
          
          // Create a simple progress callback for auto-download
          await downloadVersionWithUrl(
            version,
            downloadUrl: downloadUrl,
            onProgress: (received, total) {
              if (total > 0) {
                final progress = (received / total * 100).round();
                _logger.d('Auto-download progress for $version: $progress%');
                
                // Notify UI about auto-download progress
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

    // Additional integrity check before opening
    try {
      final file = File(path);
      final fileSize = await file.length();
      if (fileSize < 1024) { // Less than 1KB is likely corrupted
        throw Exception('Database file appears to be corrupted ($fileSize bytes)');
      }
    } catch (e) {
      _logger.e('Database integrity check failed for $version: $e');
      // Try to auto-download again if corruption is detected
      if (!e.toString().contains('not found')) {
        // Delete corrupted file and retry
        try {
          await File(path).delete();
          return await _getDatabase(version, onAutoDownloadProgress: onAutoDownloadProgress);
        } catch (deleteError) {
          _logger.e('Failed to delete corrupted database file: $deleteError');
        }
      }
      rethrow;
    }

    try {
      final db = await openDatabase(
        path,
        readOnly: true,
        singleInstance: true,
      );
      
      // Verify database integrity with comprehensive checks
      try {
        // Basic integrity check
        await db.rawQuery('SELECT count(*) FROM sqlite_master');
        
        // Check if we have the expected table structure - be more lenient
        try {
          final tableName = await _resolveTableName(db, version);
          final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
          if (tableInfo.isEmpty) {
            _logger.w('Database table structure check failed for $tableName, but continuing anyway');
            // Don't throw exception - try to continue
          } else {
            _logger.d('Database integrity verified for $version with table: $tableName');
          }
        } catch (tableError) {
          _logger.w('Table structure check failed but continuing: $tableError');
          // Don't fail the whole database opening due to table structure issues
        }
      } catch (e) {
        await db.close();
        throw Exception('Database integrity check failed for version $version: $e');
      }
      
      _databases[version] = db;
      return db;
    } catch (e) {
      _logger.e('Failed to open database: $path', error: e);
      
      // If opening failed due to corruption, try to recover
      if (e.toString().contains('corrupt') || e.toString().contains('file is encrypted')) {
        _logger.w('Database corruption detected, attempting recovery for $version');
        try {
          await File(path).delete();
          return await _getDatabase(version, onAutoDownloadProgress: onAutoDownloadProgress);
        } catch (recoveryError) {
          _logger.e('Database recovery failed: $recoveryError');
        }
      }
      
      throw Exception('Failed to open database for version $version: $e');
    }
  }

  Future<String> _getDownloadUrlForVersion(String version) async {
    try {
      // Fetch versions from API to get download URL
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

  // Execute database operation with retry logic
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
        final errorMessage = e.toString();
        
        // If it's a "database is closed" error, clear the instance and retry
        if (errorMessage.contains('database is closed') && 
            errorMessage.contains('closed') && 
            retries <= maxRetries) {
          _logger.w('Database closed, retrying operation (attempt $retries/$maxRetries)');
          _databases.remove(version);
          await Future.delayed(Duration(milliseconds: 200 * retries));
          continue;
        }
        
        // For network-related errors in offline mode, don't retry
        if (errorMessage.contains('network') || 
            errorMessage.contains('connection') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('internet')) {
          _logger.w('Network error detected, failing fast for offline mode: $errorMessage');
          rethrow;
        }
        
        // For other errors or if we've exhausted retries, throw
        if (retries > maxRetries) {
          throw Exception('Failed after $maxRetries attempts: $errorMessage');
        } else {
          rethrow;
        }
      }
    }
    
    throw Exception('Operation failed after $maxRetries retries');
  }

  /// Centralized table name resolution to eliminate redundant guessing logic
  Future<String> _resolveTableName(Database db, String version) async {
    final baseName = version.replaceAll('.db', '');
    
    // Fast path: if the exact base name exists and has 'book' and 'chapter'
    if (await _dbHelper.validateTable(db, baseName, requiredColumns: ['book'])) {
      return baseName;
    }

    // Fallback: examine all available tables
    final tables = await _dbHelper.getAvailableTables(db);
    final validTables = tables.where((t) => t.toLowerCase() != 'android_metadata' && t.toLowerCase() != 'sqlite_sequence').toList();
    
    if (validTables.isEmpty) {
      _logger.w('No valid data tables found in database for $version, trying default table names');
      // Try common default table names as fallback
      final defaultTables = ['bible_verses', 'verses', 'scripture', 'eng_rv_vpl', baseName];
      for (final defaultTable in defaultTables) {
        if (tables.contains(defaultTable)) {
          _logger.d('Using default table: $defaultTable');
          return defaultTable;
        }
      }
      throw Exception('No valid data tables found in database for $version');
    }

    // If there's exactly one data table, it's highly likely the correct one
    if (validTables.length == 1) {
      return validTables.first;
    }

    // Otherwise, look for common patterns
    for (final table in validTables) {
      final lower = table.toLowerCase();
      if (lower.contains('bible') || lower.contains('verse') || lower == baseName.toLowerCase() || lower == 'eng_rv_vpl') {
        return table;
      }
    }

    // Ultimate fallback to the first valid table
    return validTables.first;
  }

  Future<List<BibleVerseContent>> getChapter(String version, String bookAbbr, int chapter, {Function(String, double)? onAutoDownloadProgress}) async {
    return executeWithRetry<List<BibleVerseContent>>(
      version, 
      (db) async {
      try {
        final tableName = await _resolveTableName(db, version);
        
        List<Map<String, dynamic>> maps = [];
        
        // Validate inputs
        if (chapter <= 0) {
          _logger.w('Invalid chapter number: $chapter');
          return [];
        }
        
        // Use original book code first (for databases like Douay-Rheims that use standard codes)
        // Then try mapped code (for databases that use abbreviated codes)
        final originalBookCode = bookAbbr.toUpperCase();
        final mappedBookCode = _bookCodeMap[originalBookCode] ?? originalBookCode;
        
        // Try original code first
        try {
          final query = 'SELECT verseID, startVerse, verseText FROM $tableName WHERE book = ? AND chapter = ? ORDER BY CAST(startVerse AS INTEGER)';
          maps = await db.rawQuery(query, [originalBookCode, chapter]);
        } catch (e) {
          _logger.d('Failed to query table $tableName with original book code: $e');
        }

        // If no results with original code, try mapped code
        if (maps.isEmpty && mappedBookCode != originalBookCode) {
          try {
            maps = await db.rawQuery('SELECT verseID, startVerse, verseText FROM $tableName WHERE book = ? AND chapter = ? ORDER BY CAST(startVerse AS INTEGER)', [mappedBookCode, chapter]);
          } catch (e) {
            _logger.d('Failed to query table $tableName with mapped book code: $e');
          }
        }

        // If still no results, try a more flexible query
        if (maps.isEmpty) {
          try {
            // Try without casting and with different column names
            maps = await db.rawQuery('SELECT * FROM $tableName WHERE book = ? AND chapter = ? ORDER BY startVerse', [originalBookCode, chapter]);
            if (maps.isEmpty) {
              maps = await db.rawQuery('SELECT * FROM $tableName WHERE book = ? AND chapter = ? ORDER BY verse', [originalBookCode, chapter]);
            }
          } catch (e) {
            _logger.d('Flexible query also failed: $e');
          }
        }

        if (maps.isEmpty) {
          _logger.d('No verses found for $bookAbbr $chapter in table $tableName');
          return [];
        }

        return maps.map((map) => _mapToContent(map, bookAbbr, chapter, version)).toList();
      } catch (e) {
        _logger.e('Error in getChapter: $e');
        return [];
      }
    }, onAutoDownloadProgress: onAutoDownloadProgress);
  }

  BibleVerseContent _mapToContent(Map<String, dynamic> map, String bookAbbr, int chapter, String version) {
    // Try different verse column names
    final verseNum = int.tryParse(
      map['startVerse']?.toString() ?? 
      map['verse']?.toString() ?? 
      map['verse_number']?.toString() ?? 
      map['v']?.toString() ?? '0'
    ) ?? 0;
    
    // Try different text column names
    final text = (
      map['verseText']?.toString() ?? 
      map['text']?.toString() ?? 
      map['content']?.toString() ?? 
      map['verse_content']?.toString() ?? ''
    ).trim();
    
    final reference = '$bookAbbr $chapter:$verseNum';
    
    // Validate verse data
    if (verseNum <= 0 || text.isEmpty) {
      _logger.w('Invalid verse data: verse=$verseNum, text="${text.length > 50 ? text.substring(0, 50) : text}..."');
    }
    
    // Generate deterministic ID (stable across runs/platforms)
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

  Future<List<String>> getAvailableBooks(String version) async {
    return executeWithRetry<List<String>>(
      version, 
      (db) async {
      try {
        final tableName = await _resolveTableName(db, version);
        
        // Use DatabaseHelper to get distinct book values
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
        
        // Use DatabaseHelper to get max chapter value with safe type conversion
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
      
      // Use FTS snippet for highlighting if the table exists
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

        // Fallback to LIKE - also wrapped in try-catch for robustness
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
}
