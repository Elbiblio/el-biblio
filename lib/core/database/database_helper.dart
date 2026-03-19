import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Centralized database access helper to ensure consistent type handling
/// and prevent common SQLite errors across all repositories
class DatabaseHelper {
  final Logger _logger;

  DatabaseHelper(this._logger);

  /// Safely execute a database query with proper error handling and type conversion
  Future<List<T>> safeQuery<T>(
    Database db,
    String query,
    List<Object?>? arguments, {
    T Function(Map<String, dynamic>)? mapper,
    String? operation,
  }) async {
    try {
      final List<Map<String, Object?>> rawMaps = await db.rawQuery(query, arguments);
      
      if (rawMaps.isEmpty) {
        return <T>[];
      }

      if (mapper != null) {
        return rawMaps.map<T>((e) => mapper(Map<String, dynamic>.from(e))).toList();
      }

      // Auto-mapping for single-column primitive results
      if (T == String || T == int || T == double || T == bool) {
        if (rawMaps.first.keys.length == 1) {
          final key = rawMaps.first.keys.first;
          return rawMaps.map<T>((map) {
            final val = map[key];
            if (val is T) return val;
            if (T == String) return val?.toString() as T;
            if (T == int && val is String) return int.tryParse(val) as T;
            if (T == double && val is String) return double.tryParse(val) as T;
            return val as T;
          }).toList();
        }
      }

      // Auto-mapping for Map / dynamic
      if (T == dynamic || T == Map<String, dynamic>) {
        return rawMaps.map<T>((e) => Map<String, dynamic>.from(e) as T).toList();
      }

      _logger.w('Warning: No mapper provided for type $T in safeQuery for $operation. Returning empty.');
      return <T>[];
    } catch (e) {
      _logger.e('Database query failed${operation != null ? ' for $operation' : ''}: $e');
      _logger.e('Query: $query');
      _logger.e('Arguments: $arguments');
      rethrow;
    }
  }

  /// Safely get a single value with type conversion
  Future<T?> safeGetValue<T>(
    Database db,
    String query,
    List<Object?>? arguments, {
    String? operation,
    T? defaultValue,
  }) async {
    try {
      final List<Map<String, Object?>> rawMaps = await db.rawQuery(query, arguments);
      
      if (rawMaps.isEmpty || rawMaps.first.values.isEmpty) {
        return defaultValue;
      }
      
      final value = rawMaps.first.values.first;
      
      // Handle type conversion safely
      if (value == null) return defaultValue;
      
      if (value is T) {
        return value as T;
      }
      
      // Try common type conversions
      if (T == int && value is String) {
        return int.tryParse(value) as T? ?? defaultValue;
      }
      
      if (T == double && value is String) {
        return double.tryParse(value) as T? ?? defaultValue;
      }
      
      if (T == String && value is! String) {
        return value.toString() as T;
      }
      
      _logger.w('Could not convert ${value.runtimeType} to $T for query: $query');
      return defaultValue;
    } catch (e) {
      _logger.e('Database value query failed${operation != null ? ' for $operation' : ''}: $e');
      return defaultValue;
    }
  }

  /// Get available tables in the database
  Future<List<String>> getAvailableTables(Database db) async {
    try {
      final tables = await safeQuery<String>(
        db,
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
        null,
        mapper: (map) => map['name'] as String,
        operation: 'get_available_tables',
      );
      return tables;
    } catch (e) {
      _logger.e('Failed to get available tables: $e');
      return [];
    }
  }

  /// Check if a table exists and has the expected structure
  Future<bool> validateTable(
    Database db,
    String tableName, {
    List<String>? requiredColumns,
  }) async {
    try {
      final tables = await getAvailableTables(db);
      if (!tables.contains(tableName)) {
        _logger.w('Table $tableName does not exist');
        return false;
      }

      if (requiredColumns != null) {
        final columns = await safeQuery<String>(
          db,
          'PRAGMA table_info($tableName)',
          null,
          mapper: (map) => map['name'] as String,
          operation: 'get_table_columns',
        );
        
        final columnNames = columns.map((col) => col.toLowerCase()).toList();
        for (final requiredCol in requiredColumns) {
          if (!columnNames.contains(requiredCol.toLowerCase())) {
            _logger.w('Required column $requiredCol not found in table $tableName');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      _logger.e('Failed to validate table $tableName: $e');
      return false;
    }
  }

  /// Get distinct values from a column with proper type handling
  Future<List<String>> getDistinctValues(
    Database db,
    String tableName,
    String column, {
    String? orderBy,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final query = 'SELECT DISTINCT $column FROM $tableName${where != null ? ' WHERE $where' : ''}${orderBy != null ? ' ORDER BY $orderBy' : ''}';
      
      final results = await safeQuery<String>(
        db,
        query,
        whereArgs,
        mapper: (row) => row[column]?.toString() ?? '',
        operation: 'get_distinct_values',
      );
      
      return results.where((val) => val.isNotEmpty).toList();
    } catch (e) {
      _logger.e('Failed to get distinct values from $tableName.$column: $e');
      return [];
    }
  }

  /// Get maximum value from a column with safe type conversion
  Future<int> getMaxValue(
    Database db,
    String tableName,
    String column, {
    String? where,
    List<Object?>? whereArgs,
    int defaultValue = 0,
  }) async {
    try {
      final query = 'SELECT MAX($column) as max_value FROM $tableName${where != null ? ' WHERE $where' : ''}';
      
      return await safeGetValue<int>(
        db,
        query,
        whereArgs,
        operation: 'get_max_value',
        defaultValue: defaultValue,
      ) ?? defaultValue;
    } catch (e) {
      _logger.e('Failed to get max value from $tableName.$column: $e');
      return defaultValue;
    }
  }

  /// Count records in a table
  Future<int> countRecords(
    Database db,
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final query = 'SELECT COUNT(*) as count FROM $tableName${where != null ? ' WHERE $where' : ''}';
      
      return await safeGetValue<int>(
        db,
        query,
        whereArgs,
        operation: 'count_records',
        defaultValue: 0,
      ) ?? 0;
    } catch (e) {
      _logger.e('Failed to count records in $tableName: $e');
      return 0;
    }
  }
}
