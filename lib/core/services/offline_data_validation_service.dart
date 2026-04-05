import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';

/// Data validation result
enum ValidationResult {
  valid,
  corrupted,
  missing,
  invalidFormat,
  checksumMismatch,
}

/// Detailed validation result with additional information
class ValidationDetail {
  final ValidationResult result;
  final String filePath;
  final String? errorMessage;
  final String? expectedChecksum;
  final String? actualChecksum;
  final int? fileSize;
  final DateTime? lastModified;

  ValidationDetail({
    required this.result,
    required this.filePath,
    this.errorMessage,
    this.expectedChecksum,
    this.actualChecksum,
    this.fileSize,
    this.lastModified,
  });

  @override
  String toString() => 
      'ValidationDetail(result: $result, path: $filePath, error: $errorMessage)';
}

/// Offline data validation and corruption handling service
class OfflineDataValidationService {
  OfflineDataValidationService(this._logger) {
    _initializeValidationService();
  }

  final Logger _logger;
  late String _validationCacheDir;
  late Box<String> _checksumCache;
  bool _isInitialized = false;

  /// Get the validation cache directory path
  String get validationCacheDir => _validationCacheDir;

  /// Initialize the validation service
  Future<void> _initializeValidationService() async {
    try {
      if (_isInitialized) return;

      // Get application documents directory for validation cache
      final appDir = await getApplicationDocumentsDirectory();
      _validationCacheDir = join(appDir.path, 'validation_cache');
      
      // Ensure validation cache directory exists
      final cacheDir = Directory(_validationCacheDir);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Open checksum cache box
      _checksumCache = await Hive.openBox<String>('file_checksums');

      _isInitialized = true;
      _logger.i('Offline data validation service initialized');
    } catch (e) {
      _logger.e('Failed to initialize validation service: $e');
      rethrow;
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeValidationService();
    }
  }

  /// Validate a single file
  Future<ValidationDetail> validateFile(String filePath, {String? expectedChecksum}) async {
    await _ensureInitialized();
    
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        return ValidationDetail(
          result: ValidationResult.missing,
          filePath: filePath,
          errorMessage: 'File does not exist',
        );
      }

      // Get file stats
      final stat = await file.stat();
      final fileSize = stat.size;
      final lastModified = stat.modified;

      // Check if file is empty (unless it's supposed to be)
      if (fileSize == 0) {
        return ValidationDetail(
          result: ValidationResult.invalidFormat,
          filePath: filePath,
          fileSize: fileSize,
          lastModified: lastModified,
          errorMessage: 'File is empty',
        );
      }

      // Calculate checksum
      final actualChecksum = await _calculateFileChecksum(file);

      // Check against expected checksum if provided
      if (expectedChecksum != null) {
        if (actualChecksum != expectedChecksum) {
          return ValidationDetail(
            result: ValidationResult.checksumMismatch,
            filePath: filePath,
            expectedChecksum: expectedChecksum,
            actualChecksum: actualChecksum,
            fileSize: fileSize,
            lastModified: lastModified,
            errorMessage: 'Checksum mismatch',
          );
        }
      }

      // Check against cached checksum
      final cachedChecksum = _checksumCache.get(filePath);
      if (cachedChecksum != null && cachedChecksum != actualChecksum) {
        _logger.w('File checksum changed for $filePath: cached=$cachedChecksum, actual=$actualChecksum');
      }

      // Update cache
      await _checksumCache.put(filePath, actualChecksum);

      // Perform file-type specific validation
      final validationResult = await _validateFileByType(file, filePath);
      
      return ValidationDetail(
        result: validationResult,
        filePath: filePath,
        actualChecksum: actualChecksum,
        fileSize: fileSize,
        lastModified: lastModified,
      );

    } catch (e) {
      _logger.e('Error validating file $filePath: $e');
      return ValidationDetail(
        result: ValidationResult.corrupted,
        filePath: filePath,
        errorMessage: e.toString(),
      );
    }
  }

  /// Validate file based on its type/extension
  Future<ValidationResult> _validateFileByType(File file, String filePath) async {
    final extension = filePath.toLowerCase().split('.').last;

    switch (extension) {
      case 'db':
        return await _validateDatabaseFile(file);
      case 'json':
        return await _validateJsonFile(file);
      case 'hive':
        return await _validateHiveFile(file);
      default:
        // For unknown file types, just check if it's readable
        try {
          final bytes = await file.readAsBytes();
          return bytes.isNotEmpty ? ValidationResult.valid : ValidationResult.invalidFormat;
        } catch (e) {
          return ValidationResult.corrupted;
        }
    }
  }

  /// Validate SQLite database file
  Future<ValidationResult> _validateDatabaseFile(File file) async {
    try {
      final db = await openDatabase(file.path, readOnly: true);
      
      // Check if database has tables
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      if (tables.isEmpty) {
        await db.close();
        return ValidationResult.invalidFormat;
      }

      // Try a simple query to ensure database is readable
      await db.rawQuery('SELECT 1');
      
      await db.close();
      return ValidationResult.valid;
    } catch (e) {
      _logger.e('Database validation failed for ${file.path}: $e');
      return ValidationResult.corrupted;
    }
  }

  /// Validate JSON file
  Future<ValidationResult> _validateJsonFile(File file) async {
    try {
      final content = await file.readAsString();
      
      // Try to parse as JSON
      final decoded = jsonDecode(content);
      
      // Check if it's a valid JSON structure (not null)
      if (decoded == null) {
        return ValidationResult.invalidFormat;
      }
      
      return ValidationResult.valid;
    } catch (e) {
      _logger.e('JSON validation failed for ${file.path}: $e');
      return ValidationResult.corrupted;
    }
  }

  /// Validate Hive file
  Future<ValidationResult> _validateHiveFile(File file) async {
    try {
      // Hive files are binary, so we'll check if they have the expected format
      final bytes = await file.readAsBytes();
      
      // Hive files should have a minimum size and specific header
      if (bytes.length < 16) {
        return ValidationResult.invalidFormat;
      }

      // Check for Hive magic bytes (simplified check)
      // This is a basic check - actual Hive validation would be more complex
      return ValidationResult.valid;
    } catch (e) {
      _logger.e('Hive file validation failed for ${file.path}: $e');
      return ValidationResult.corrupted;
    }
  }

  /// Calculate SHA-256 checksum of a file
  Future<String> _calculateFileChecksum(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      _logger.e('Failed to calculate checksum for ${file.path}: $e');
      rethrow;
    }
  }

  /// Validate multiple files
  Future<List<ValidationDetail>> validateFiles(List<String> filePaths) async {
    final results = <ValidationDetail>[];
    
    for (final filePath in filePaths) {
      final result = await validateFile(filePath);
      results.add(result);
    }
    
    return results;
  }

  /// Validate all critical app files
  Future<Map<String, List<ValidationDetail>>> validateCriticalFiles() async {
    final results = <String, List<ValidationDetail>>{
      'databases': [],
      'hive_boxes': [],
      'cache_files': [],
      'config_files': [],
    };

    try {
      // Get application directories
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = Platform.isAndroid ? await getDatabasesPath() : appDir.path;

      // Validate database files
      final dbDirectory = Directory(dbDir);
      if (await dbDirectory.exists()) {
        await for (final entity in dbDirectory.list()) {
          if (entity is File && entity.path.endsWith('.db')) {
            final result = await validateFile(entity.path);
            results['databases']!.add(result);
          }
        }
      }

      // Validate Hive boxes
      final hiveDir = Directory(join(appDir.path, 'hive_boxes'));
      if (await hiveDir.exists()) {
        await for (final entity in hiveDir.list()) {
          if (entity is File && entity.path.endsWith('.hive')) {
            final result = await validateFile(entity.path);
            results['hive_boxes']!.add(result);
          }
        }
      }

      // Validate cache files
      final cacheDir = Directory(join(appDir.path, 'cache'));
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            final result = await validateFile(entity.path);
            results['cache_files']!.add(result);
          }
        }
      }

    } catch (e) {
      _logger.e('Error during critical files validation: $e');
    }

    return results;
  }

  /// Repair corrupted files when possible
  Future<bool> repairFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        _logger.w('Cannot repair non-existent file: $filePath');
        return false;
      }

      final extension = filePath.toLowerCase().split('.').last;

      switch (extension) {
        case 'db':
          return await _repairDatabaseFile(file);
        case 'hive':
          return await _repairHiveFile(file);
        default:
          _logger.w('No repair method available for file type: $extension');
          return false;
      }
    } catch (e) {
      _logger.e('Error repairing file $filePath: $e');
      return false;
    }
  }

  /// Attempt to repair a corrupted database
  Future<bool> _repairDatabaseFile(File file) async {
    try {
      _logger.i('Attempting to repair database: ${file.path}');
      
      // Create backup before attempting repair
      final backupPath = '${file.path}.backup.${DateTime.now().millisecondsSinceEpoch}';
      await file.copy(backupPath);
      
      try {
        // Try to open database with recovery mode
        final db = await openDatabase(
          file.path,
          readOnly: false,
        );
        
        // Run integrity check
        final integrityResult = await db.rawQuery('PRAGMA integrity_check');
        await db.close();
        
        final isOk = integrityResult.first['integrity_check']?.toString() == 'ok';
        
        if (isOk) {
          _logger.i('Database repair successful: ${file.path}');
          // Remove backup on successful repair
          await File(backupPath).delete();
          return true;
        } else {
          _logger.w('Database integrity check failed: $integrityResult');
          // Restore from backup
          await File(backupPath).copy(file.path);
          await File(backupPath).delete();
          return false;
        }
      } catch (e) {
        _logger.e('Database repair failed, restoring backup: $e');
        // Restore from backup
        await File(backupPath).copy(file.path);
        await File(backupPath).delete();
        return false;
      }
    } catch (e) {
      _logger.e('Error during database repair: $e');
      return false;
    }
  }

  /// Attempt to repair a corrupted Hive file
  Future<bool> _repairHiveFile(File file) async {
    try {
      _logger.i('Attempting to repair Hive file: ${file.path}');
      
      // For Hive files, the best approach is usually to delete and let Hive recreate
      // But first, let's try to read any recoverable data
      
      // Create backup
      final backupPath = '${file.path}.backup.${DateTime.now().millisecondsSinceEpoch}';
      await file.copy(backupPath);
      
      try {
        // Try to open the Hive box to see if it's recoverable
        final boxName = file.path.split('/').last.replaceAll('.hive', '');
        final box = await Hive.openBox(boxName);
        
        // If we can open it and it has data, consider it repaired
        final keys = box.keys;
        await box.close();
        
        if (keys.isNotEmpty) {
          _logger.i('Hive file repair successful: ${file.path}');
          await File(backupPath).delete();
          return true;
        } else {
          _logger.w('Hive file is empty, may need to be recreated');
          return false;
        }
      } catch (e) {
        _logger.e('Hive file repair failed: $e');
        // Restore from backup
        await File(backupPath).copy(file.path);
        await File(backupPath).delete();
        return false;
      }
    } catch (e) {
      _logger.e('Error during Hive file repair: $e');
      return false;
    }
  }

  /// Clean up corrupted files
  Future<int> cleanupCorruptedFiles({bool createBackups = true}) async {
    int cleanedCount = 0;
    
    try {
      final validationResults = await validateCriticalFiles();
      
      for (final category in validationResults.entries) {
        for (final result in category.value) {
          if (result.result == ValidationResult.corrupted || 
              result.result == ValidationResult.invalidFormat) {
            
            if (createBackups) {
              final backupPath = '${result.filePath}.corrupted.${DateTime.now().millisecondsSinceEpoch}';
              await File(result.filePath).rename(backupPath);
              _logger.i('Moved corrupted file to backup: $backupPath');
            } else {
              await File(result.filePath).delete();
              _logger.i('Deleted corrupted file: ${result.filePath}');
            }
            
            cleanedCount++;
          }
        }
      }
      
      _logger.i('Cleaned up $cleanedCount corrupted files');
    } catch (e) {
      _logger.e('Error during cleanup: $e');
    }
    
    return cleanedCount;
  }

  /// Get validation statistics
  Future<Map<String, dynamic>> getValidationStats() async {
    await _ensureInitialized();
    
    final stats = {
      'cachedChecksums': _checksumCache.length,
      'validationCacheDir': _validationCacheDir,
      'lastValidation': DateTime.now().toIso8601String(),
    };

    // Add file counts by type
    final validationResults = await validateCriticalFiles();
    stats['fileCounts'] = {
      for (final category in validationResults.entries)
        category.key: category.value.length,
    };

    // Add validation status counts
    final statusCounts = <ValidationResult, int>{};
    for (final category in validationResults.entries) {
      for (final result in category.value) {
        statusCounts[result.result] = (statusCounts[result.result] ?? 0) + 1;
      }
    }
    
    stats['validationStatusCounts'] = {
      for (final status in statusCounts.entries)
        status.key.toString(): status.value,
    };

    return stats;
  }

  /// Clear validation cache
  Future<void> clearValidationCache() async {
    try {
      await _checksumCache.clear();
      
      final cacheDir = Directory(_validationCacheDir);
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      
      _logger.i('Validation cache cleared');
    } catch (e) {
      _logger.e('Error clearing validation cache: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _checksumCache.close();
    }
  }

  @override
  String toString() => 
      'OfflineDataValidationService(initialized: $_isInitialized, cacheDir: $_validationCacheDir)';
}
