import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

enum BibleHistoryType {
  search,
  verse,
  navigation,
}

class BibleHistoryEntry {
  const BibleHistoryEntry({
    required this.type,
    required this.version,
    required this.timestamp,
    this.book,
    this.chapter,
    this.verse,
    this.query,
  });

  final BibleHistoryType type;
  final String version;
  final int timestamp;
  final String? book;
  final int? chapter;
  final int? verse;
  final String? query;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'version': version,
      'timestamp': timestamp,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'query': query,
    };
  }

  factory BibleHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BibleHistoryEntry(
      type: BibleHistoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BibleHistoryType.verse,
      ),
      version: json['version'] as String,
      timestamp: json['timestamp'] as int,
      book: json['book'] as String?,
      chapter: json['chapter'] as int?,
      verse: json['verse'] as int?,
      query: json['query'] as String?,
    );
  }
}

class BibleHistoryService {
  BibleHistoryService(this._logger);

  final Logger _logger;
  static const String _historyKey = 'bible_history';
  static const int _maxHistoryEntries = 40;

  Future<void> recordHistory({
    required BibleHistoryType type,
    required String version,
    String? book,
    int? chapter,
    int? verse,
    String? query,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      List<BibleHistoryEntry> history = [];
      if (historyJson != null) {
        try {
          final List<dynamic> decoded = json.decode(historyJson);
          history = decoded.map((item) => BibleHistoryEntry.fromJson(item)).toList();
        } catch (e) {
          _logger.w('Failed to parse existing history, starting fresh: $e');
        }
      }

      // Create new entry
      final newEntry = BibleHistoryEntry(
        type: type,
        version: version,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        book: book,
        chapter: chapter,
        verse: verse,
        query: query,
      );

      // Check for duplicates
      if (history.isNotEmpty) {
        final lastEntry = history.first;
        final isDuplicate = lastEntry.type == type &&
            lastEntry.version == version &&
            (lastEntry.query?.toLowerCase() ?? '') == (query?.toLowerCase() ?? '') &&
            (lastEntry.book ?? '') == (book ?? '') &&
            (lastEntry.chapter) == (chapter) &&
            (lastEntry.verse) == (verse);

        if (isDuplicate) {
          _logger.d('Duplicate history entry, skipping');
          return;
        }
      }

      // Add new entry and keep only the most recent entries
      history.insert(0, newEntry);
      if (history.length > _maxHistoryEntries) {
        history = history.take(_maxHistoryEntries).toList();
      }

      // Save updated history
      await prefs.setString(_historyKey, json.encode(history.map((e) => e.toJson()).toList()));
      _logger.d('Recorded Bible history: ${type.name} for $version');
    } catch (e) {
      _logger.e('Failed to record Bible history: $e');
    }
  }

  Future<List<BibleHistoryEntry>> getHistory({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) {
        return [];
      }

      final List<dynamic> decoded = json.decode(historyJson);
      final history = decoded.map((item) => BibleHistoryEntry.fromJson(item)).toList();
      
      if (limit != null && limit > 0) {
        return history.take(limit).toList();
      }
      
      return history;
    } catch (e) {
      _logger.e('Failed to get Bible history: $e');
      return [];
    }
  }

  Future<List<BibleHistoryEntry>> getHistoryByType(BibleHistoryType type, {int? limit}) async {
    final allHistory = await getHistory();
    final filteredHistory = allHistory.where((entry) => entry.type == type).toList();
    
    if (limit != null && limit > 0) {
      return filteredHistory.take(limit).toList();
    }
    
    return filteredHistory;
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      _logger.d('Cleared Bible history');
    } catch (e) {
      _logger.e('Failed to clear Bible history: $e');
    }
  }

  Future<List<String>> getRecentBooks({int limit = 10}) async {
    final history = await getHistory();
    final books = <String>{};
    
    for (final entry in history) {
      if (entry.book != null) {
        books.add(entry.book!);
        if (books.length >= limit) break;
      }
    }
    
    return books.toList();
  }

  Future<Map<String, int>> getChapterFrequency({int limit = 20}) async {
    final history = await getHistory();
    final chapterFrequency = <String, int>{};
    
    for (final entry in history) {
      if (entry.book != null && entry.chapter != null) {
        final key = '${entry.book} ${entry.chapter}';
        chapterFrequency[key] = (chapterFrequency[key] ?? 0) + 1;
      }
    }
    
    // Sort by frequency and take top entries
    final sortedEntries = chapterFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(limit));
  }
}
