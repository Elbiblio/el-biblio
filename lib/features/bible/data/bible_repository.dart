import 'package:elbiblio/features/bible/data/services/enhanced_bible_database_service.dart';
import 'package:elbiblio/features/bible/data/services/bible_history_service.dart';
import 'package:elbiblio/features/bible/data/static_books.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:elbiblio/features/bible/domain/models/bible_content.dart';
import 'package:elbiblio/features/bible/domain/models/bible_insight.dart';
import 'package:elbiblio/features/bible/domain/models/bible_version.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Helper class for random verse selection
class _RandomChapter {
  final String book;
  final int chapter;
  
  const _RandomChapter(this.book, this.chapter);
}

class BibleRepository extends BaseRepository {
  BibleRepository(this._client, Logger logger, this._dbService, this._historyService) : super(logger);

  final DioClient _client;
  final EnhancedBibleDatabaseService _dbService;
  final BibleHistoryService _historyService;

  Future<List<BibleBook>> getBooks() {
    return guard(() async {
      // Use static books for instant offline loading
      try {
        const staticBooks = standardBibleBooks;
        final books = <BibleBook>[];
        
        for (final bookDef in staticBooks) {
          books.add(BibleBook(
            name: bookDef.name,
            abbreviation: bookDef.abbreviation,
            testament: bookDef.testament,
            chapters: bookDef.chapters,
          ));
        }
        
        return books;
      } catch (e) {
        logger.e('Failed to load static books, falling back to database: $e');
        
        // Fallback to database if static books fail
        try {
          final localBooks = await _dbService.getAvailableBooks('eng_rv_vpl');
          if (localBooks.isNotEmpty) {
            final books = <BibleBook>[];
            for (final bookName in localBooks) {
              final bookDef = getBookByAbbreviation(bookName);
              books.add(BibleBook(
                name: _getFullBookName(bookName),
                abbreviation: bookName,
                testament: _getTestamentForBook(bookName),
                chapters: bookDef?.chapters ?? 0, // Use static chapter count
              ));
            }
            return books;
          }
        } catch (e) {
          logger.w('Failed to get books from local database, falling back to API: $e');
        }

        // Final fallback to API
        final response = await _client.get('/bible/books');
      
        // Handle different response structures
        dynamic data;
        if (response.data is Map<String, dynamic>) {
          data = response.data['data'] ?? response.data;
        } else {
          data = response.data;
        }
      
        // Handle case where data might be a Map instead of List
        if (data is Map<String, dynamic>) {
          // If it's a map, try to extract books from common keys
          data = data['books'] ?? data['items'] ?? data.values.toList();
        }
      
        if (data is! List) {
          logger.e('Expected List but got ${data.runtimeType}: $data');
          return [];
        }
      
        final books = <BibleBook>[];
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              books.add(BibleBook.fromJson(item));
            }
          } catch (e) {
            logger.e('Error parsing BibleBook: $e, data: $item');
          }
        }
      
        return books;
      }
    }, operation: 'get_bible_books');
  }

  // Helper method to get full book name from abbreviation
  String _getFullBookName(String abbreviation) {
    // Use the static books data for consistent mapping
    final bookDef = getBookByAbbreviation(abbreviation);
    return bookDef?.name ?? abbreviation;
  }

  // Helper method to determine testament for a book
  String _getTestamentForBook(String bookName) {
    // Use the static books data for accurate testament information
    final bookDef = getBookByAbbreviation(bookName);
    return bookDef?.testament ?? (bookName.compareTo('MAT') < 0 ? 'OT' : 'NT');
  }

  Future<List<BibleVerseContent>> getVerses(String version, String book, int chapter, {Function(String, double)? onAutoDownloadProgress}) {
    return guard(() async {
      logger.d('Getting verses for version: $version, book: $book, chapter: $chapter');
      
      // Check if we should use local DB
      // We assume 'version' is the table name or abbreviation.
      // If it ends with .db or we know it's downloaded, use local.
      
      final isDownloaded = await _dbService.isVersionDownloaded(version);
      logger.d('Version $version isDownloaded: $isDownloaded');
      
      if (isDownloaded) {
        logger.d('Using local database for verses');
        final verses = await _dbService.getChapter(version, book, chapter);
        
        // Record navigation history
        await _historyService.recordHistory(
          type: BibleHistoryType.navigation,
          version: version,
          book: book,
          chapter: chapter,
        );
        
        return verses;
      }

      // Try API
      logger.d('Using API for verses');
      try {
        final response = await _client.get('/bible/verses/$version/$book/$chapter');
        
        logger.d('API Response: ${response.data}');
        
        // Handle different response structures
        dynamic data;
        if (response.data is Map<String, dynamic>) {
          data = response.data['data'] ?? response.data;
          // Handle paginated response
          if (data is Map<String, dynamic> && data['data'] != null) {
            data = data['data'];
          }
        } else {
          data = response.data;
        }
        
        if (data is! List) {
          logger.e('Expected List but got ${data.runtimeType}: $data');
          return [];
        }
        
        final verses = <BibleVerseContent>[];
        for (final item in data) {
          try {
            if (item is Map<String, dynamic>) {
              // Handle API response with flexible field mapping
              final verse = _mapApiVerseToContent(item, book, chapter, version: version);
              if (verse != null) {
                verses.add(verse);
              }
            }
          } catch (e) {
            logger.e('Error parsing BibleVerseContent: $e, data: $item');
          }
        }
        
        logger.d('Parsed ${verses.length} verses from API');
        
        // Record navigation history
        await _historyService.recordHistory(
          type: BibleHistoryType.navigation,
          version: version,
          book: book,
          chapter: chapter,
        );
        
        return verses;
      } catch (e) {
        logger.e('API request failed: $e');
        
        // Fallback: try bundled database if this is the default version
        if (version == 'eng_rv_vpl' || version == 'RSV' || version == 'engdra_vpl') {
          logger.d('API failed, trying bundled database as fallback');
          try {
            final verses = await _dbService.getChapter('eng_rv_vpl', book, chapter);
            return verses;
          } catch (fallbackError) {
            logger.e('Bundled database fallback also failed: $fallbackError');
          }
        }
        
        rethrow;
      }
    }, operation: 'get_bible_verses');
  }

  BibleVerseContent? _mapApiVerseToContent(Map<String, dynamic> json, String book, int chapter, {String? version}) {
    try {
      // Extract verse number with flexible field names
      final verse = int.tryParse(
        json['verse']?.toString() ?? 
        json['verse_number']?.toString() ?? 
        json['v']?.toString() ?? 
        '0'
      ) ?? 0;
      
      // Extract text with flexible field names
      final text = (json['text']?.toString() ?? 
                   json['verse_text']?.toString() ?? 
                   json['content']?.toString() ?? 
                   '').trim();
      
      // Extract ID or generate a deterministic one (stable across runs/platforms)
      final id = json['id'] != null
          ? int.tryParse(json['id'].toString()) ?? 0
          : int.parse(
                sha256
                    .convert(utf8.encode('${version ?? 'api'}:$book $chapter:$verse'))
                    .toString()
                    .substring(0, 8),
                radix: 16,
              ) &
              0x7FFFFFFF;
      
      // Extract book ID if available
      final bookId = json['book_id'] != null ? 
        int.tryParse(json['book_id'].toString()) : 
        null;
      
      // Generate reference if not provided
      final reference = json['reference']?.toString() ?? '$book $chapter:$verse';
      
      if (verse <= 0 || text.isEmpty) {
        logger.w('Invalid verse data: verse=$verse, text="${text.length > 50 ? text.substring(0, 50) : text}..."');
        return null;
      }
      
      return BibleVerseContent(
        id: id,
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        text: text,
        reference: reference,
      );
    } catch (e) {
      logger.e('Error mapping API verse to content: $e', error: e);
      return null;
    }
  }

  Future<List<BibleVersion>> getVersions() {
    return guard(() async {
      // Try the dedicated versions API first
      try {
        final response = await _client.get('https://api.elbiblio.com/dbs/versions.json');
        
        if (response.data is List) {
          final versions = <BibleVersion>[];
          for (final item in response.data) {
            try {
              if (item is Map<String, dynamic>) {
                // Map API fields to our model
                final version = BibleVersion(
                  id: item['tableName']?.toString(),
                  name: item['englishName']?.toString(),
                  abbreviation: item['shortName']?.toString() ?? '',
                  tableName: item['tableName']?.toString(),
                  dbFilename: item['dbFilename']?.toString() ?? '',
                  downloadUrl: item['downloadUrl']?.toString() ?? '',
                  preinstalled: item['preinstalled'] as bool? ?? false,
                );
                
                if (version.abbreviation.isNotEmpty) {
                  versions.add(version);
                }
              }
            } catch (e) {
              logger.e('Error parsing BibleVersion from versions API: $e, data: $item');
            }
          }
          
          // Check download status for each
          final checkedVersions = await Future.wait(versions.map((v) async {
            if (v.tableName != null) {
              final downloaded = await _dbService.isVersionDownloaded(v.tableName!);
              return v.copyWith(isDownloaded: downloaded);
            }
            return v;
          }));
          
          return checkedVersions;
        }
      } catch (e) {
        logger.e('Failed to fetch from versions API, falling back to regular API: $e');
      }
      
      // Fallback to the regular API
      final response = await _client.get('/bible/versions');
      
      // Handle different response structures
      dynamic data;
      if (response.data is Map<String, dynamic>) {
        data = response.data['data'] ?? response.data;
      } else {
        data = response.data;
      }
      
      if (data is! List) {
        logger.e('Expected List but got ${data.runtimeType}: $data');
        return [];
      }
      
      final versions = <BibleVersion>[];
      for (final item in data) {
        try {
          if (item is Map<String, dynamic>) {
            // Ensure required fields are not null
            if (item['abbreviation'] != null) {
              versions.add(BibleVersion.fromJson(item));
            } else {
              logger.w('Skipping BibleVersion with missing required fields: $item');
            }
          }
        } catch (e) {
          logger.e('Error parsing BibleVersion: $e, data: $item');
        }
      }
      
      // Check download status for each
      final checkedVersions = await Future.wait(versions.map((v) async {
        if (v.tableName != null) {
          final downloaded = await _dbService.isVersionDownloaded(v.tableName!);
          return v.copyWith(isDownloaded: downloaded);
        }
        return v;
      }));
      
      return checkedVersions;
    }, operation: 'get_bible_versions');
  }

  Future<void> downloadVersion(String versionId, {required Function(int, int) onProgress}) {
    return guard(() async {
      await _dbService.downloadVersion(versionId, onProgress: onProgress);
    }, operation: 'download_bible_version');
  }

  Future<void> downloadVersionWithUrl(String versionId, {required String downloadUrl, required Function(int, int) onProgress}) {
    return guard(() async {
      await _dbService.downloadVersionWithUrl(versionId, downloadUrl: downloadUrl, onProgress: onProgress);
    }, operation: 'download_bible_version_with_url');
  }

  Future<BibleInsight> getVerseInsight(int verseId) {
    return guard(() async {
      final token = _client.currentAuthToken;
      
      // Check if user is guest and return offline insight
      if (isGuestToken(token)) {
        logger.i('Guest user detected, returning offline insight for verse $verseId');
        return const BibleInsight(
          reference: 'Guest Mode',
          sections: [
            InsightSection(
              title: 'Guest Mode',
              content: 'AI insights are not available for guest users. Please create an account to access this feature.',
            ),
          ],
        );
      }
      
      final response = await _client.get('/bible/verses/$verseId/explain');
      final data = response.data['data'] ?? response.data;
      
      List<InsightSection> sections = [];
      String? reference;

      if (data is Map<String, dynamic>) {
        if (data['sections'] != null) {
          sections = (data['sections'] as List)
              .map((e) => InsightSection.fromJson(e))
              .toList();
        } else if (data['content'] != null) {
          // Fallback if structure is flat
          sections = [InsightSection(title: 'Insight', content: data['content'])];
        }
        reference = data['reference'];
      } else if (data is List) {
        sections = data.map((e) => InsightSection.fromJson(e)).toList();
      }

      return BibleInsight(sections: sections, reference: reference);
    }, operation: 'get_verse_insight', token: _client.currentAuthToken);
  }

  Future<List<BibleVerseContent>> searchVerses(String version, String query) {
    return guard(() async {
      final isDownloaded = await _dbService.isVersionDownloaded(version);
      if (isDownloaded) {
        return await _dbService.searchVerses(version, query);
      }

      final response = await _client.get(
        '/bible/search',
        queryParameters: {
          'q': query,
          'version': version,
        },
      );
      
      logger.d('Search API Response: ${response.data}');
      
      // Handle different response structures
      dynamic data;
      if (response.data is Map<String, dynamic>) {
        data = response.data['data'] ?? response.data;
        // Handle paginated response
        if (data is Map<String, dynamic> && data['data'] != null) {
          data = data['data'];
        }
      } else {
        data = response.data;
      }
      
      if (data is! List) {
        logger.e('Expected List but got ${data.runtimeType}: $data');
        return [];
      }
      
      final verses = <BibleVerseContent>[];
      for (final item in data) {
        try {
          if (item is Map<String, dynamic>) {
            // For search results, we need to extract book and chapter from the item
            final book = item['book']?.toString() ?? item['book_abbr']?.toString() ?? '';
            final chapter = int.tryParse(item['chapter']?.toString() ?? '0') ?? 1;
            
            if (book.isNotEmpty) {
              final verse = _mapApiVerseToContent(item, book, chapter, version: version);
              if (verse != null) {
                verses.add(verse);
              }
            }
          }
        } catch (e) {
          logger.e('Error parsing search result: $e, data: $item');
        }
      }
      
      // Record search history
      await _historyService.recordHistory(
        type: BibleHistoryType.search,
        version: version,
        query: query,
      );
      
      return verses;
    }, operation: 'search_bible_verses');
  }

  Future<List<Map<String, dynamic>>> compareVerses(String version, String reference) {
    return guard(() async {
      // Encode reference if needed, though dio handles path params if properly constructed
      // The route is /bible/{version}/compare/{reference}
      // Reference like "GEN 1:1" needs to be safe.
      final response = await _client.get('/bible/$version/compare/$reference');
      final List<dynamic> data = response.data['data'] ?? response.data;
      
      // Expected structure: [{ "version": "KJV", "text": "In the beginning..." }, ...]
      return data.cast<Map<String, dynamic>>();
    }, operation: 'compare_bible_verses');
  }

  Future<void> toggleHighlight(int verseId) {
    return guard(() async {
      await _client.post('/bible/verses/$verseId/highlight');
    }, operation: 'toggle_verse_highlight');
  }

  Future<void> toggleBookmark(int verseId) {
    return guard(() async {
      await _client.post('/bible/verses/$verseId/bookmark');
    }, operation: 'toggle_verse_bookmark');
  }

  Future<bool> likeVerse(int verseId) {
    return guard(() async {
      final response = await _client.post('/bible/verses/$verseId/like');
      return response.data['liked'] ?? false;
    }, operation: 'like_verse');
  }

  Future<bool> unlikeVerse(int verseId) {
    return guard(() async {
      final response = await _client.post('/verses/$verseId/like', data: {'action': 'unlike'});
      return response.data['liked'] ?? false;
    }, operation: 'unlike_verse');
  }

  Future<Map<String, dynamic>> shareVerse(int verseId, {String? platform, String? message}) {
    return guard(() async {
      final response = await _client.post('/bible/verses/$verseId/share', data: {
        'platform': platform ?? 'copy',
        if (message != null) 'message': message,
      });
      return {
        'share_url': response.data['share_url'] ?? '',
        'platform': response.data['platform'] ?? platform ?? 'copy',
      };
    }, operation: 'share_verse');
  }

  Future<void> saveVerseNote(int verseId, String note) {
    return guard(() async {
      // For now, we'll use a generic notes API endpoint
      // In a real implementation, this might be a specific verse notes endpoint
      await _client.post('/notes', data: {
        'verse_id': verseId,
        'content': note,
        'type': 'verse_note',
      });
    }, operation: 'save_verse_note');
  }

  Future<void> deleteVerseNote(int noteId) {
    return guard(() async {
      await _client.delete('/notes/$noteId');
    }, operation: 'delete_verse_note');
  }

  Future<List<Map<String, dynamic>>> getVerseNotes(int verseId) {
    return guard(() async {
      final response = await _client.get('/notes', queryParameters: {
        'verse_id': verseId,
        'type': 'verse_note',
      });
      
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    }, operation: 'get_verse_notes');
  }

  Future<List<BibleVerseContent>> getRandomVerses(int count) {
    return guard(() async {
      // Whitelist of inspirational books and chapters for true random verses
      final randomChapters = _getInspirationalChapters();
      
      final random = DateTime.now().millisecondsSinceEpoch;
      final selectedVerses = <BibleVerseContent>[];
      
      for (int i = 0; i < count && i < randomChapters.length; i++) {
        final chapterIndex = (random + i * 7) % randomChapters.length;
        final chapter = randomChapters[chapterIndex];
        
        try {
          // Try to get verses from the local database first
          final verses = await _dbService.getChapter('eng_rv_vpl', chapter.book, chapter.chapter);
          
          if (verses.isNotEmpty) {
            // Select a random verse from this chapter
            final verseIndex = (random + i * 13) % verses.length;
            selectedVerses.add(verses[verseIndex]);
          } else {
            // Fallback to API if local database doesn't have this chapter
            final apiVerses = await getVerses('eng_rv_vpl', chapter.book, chapter.chapter);
            if (apiVerses.isNotEmpty) {
              final verseIndex = (random + i * 13) % apiVerses.length;
              selectedVerses.add(apiVerses[verseIndex]);
            }
          }
        } catch (e) {
          logger.w('Failed to get verses for ${chapter.book} ${chapter.chapter}: $e');
          
          // Use fallback inspirational verse if we can't get the random one
          if (selectedVerses.length < count) {
            selectedVerses.add(_getFallbackVerse(i));
          }
        }
      }
      
      // If we couldn't get enough verses, fill with fallback verses
      while (selectedVerses.length < count) {
        selectedVerses.add(_getFallbackVerse(selectedVerses.length));
      }
      
      return selectedVerses;
    }, operation: 'get_random_verses');
  }

  List<_RandomChapter> _getInspirationalChapters() {
    return [
      // Wisdom Literature
      const _RandomChapter('PRO', 1), const _RandomChapter('PRO', 3), const _RandomChapter('PRO', 4), const _RandomChapter('PRO', 15), const _RandomChapter('PRO', 16), const _RandomChapter('PRO', 31),
      const _RandomChapter('ECC', 3), const _RandomChapter('ECC', 12), 
      const _RandomChapter('JOB', 1), const _RandomChapter('JOB', 38), const _RandomChapter('JOB', 42),
      
      // Psalms (key inspirational psalms)
      const _RandomChapter('PSA', 1), const _RandomChapter('PSA', 23), const _RandomChapter('PSA', 27), const _RandomChapter('PSA', 34), const _RandomChapter('PSA', 46), 
      const _RandomChapter('PSA', 51), const _RandomChapter('PSA', 91), const _RandomChapter('PSA', 103), const _RandomChapter('PSA', 119), const _RandomChapter('PSA', 121),
      const _RandomChapter('PSA', 139), const _RandomChapter('PSA', 145), const _RandomChapter('PSA', 150),
      
      // Gospels
      const _RandomChapter('MAT', 5), const _RandomChapter('MAT', 6), const _RandomChapter('MAT', 7), const _RandomChapter('MAT', 11), const _RandomChapter('MAT', 13), const _RandomChapter('MAT', 25),
      const _RandomChapter('MAR', 4), const _RandomChapter('MAR', 5), const _RandomChapter('MAR', 12),
      const _RandomChapter('LUK', 6), const _RandomChapter('LUK', 10), const _RandomChapter('LUK', 12), const _RandomChapter('LUK', 15), const _RandomChapter('LUK', 18),
      const _RandomChapter('JOH', 1), const _RandomChapter('JOH', 3), const _RandomChapter('JOH', 6), const _RandomChapter('JOH', 10), const _RandomChapter('JOH', 14), const _RandomChapter('JOH', 15),
      
      // Paul's Letters
      const _RandomChapter('ROM', 3), const _RandomChapter('ROM', 5), const _RandomChapter('ROM', 8), const _RandomChapter('ROM', 12), const _RandomChapter('ROM', 15),
      const _RandomChapter('1CO', 13), const _RandomChapter('1CO', 15),
      const _RandomChapter('2CO', 4), const _RandomChapter('2CO', 5), const _RandomChapter('2CO', 12),
      const _RandomChapter('GAL', 5), const _RandomChapter('GAL', 6),
      const _RandomChapter('EPH', 1), const _RandomChapter('EPH', 2), const _RandomChapter('EPH', 4), const _RandomChapter('EPH', 6),
      const _RandomChapter('PHP', 2), const _RandomChapter('PHP', 4),
      const _RandomChapter('COL', 1), const _RandomChapter('COL', 3),
      const _RandomChapter('1TH', 4), const _RandomChapter('1TH', 5),
      const _RandomChapter('2TI', 1), const _RandomChapter('2TI', 2), const _RandomChapter('2TI', 3),
      
      // Hebrews
      const _RandomChapter('HEB', 1), const _RandomChapter('HEB', 4), const _RandomChapter('HEB', 11), const _RandomChapter('HEB', 12), const _RandomChapter('HEB', 13),
      
      // General Letters
      const _RandomChapter('JAS', 1), const _RandomChapter('JAS', 2), const _RandomChapter('JAS', 3), const _RandomChapter('JAS', 4), const _RandomChapter('JAS', 5),
      const _RandomChapter('1PE', 1), const _RandomChapter('1PE', 2), const _RandomChapter('1PE', 3), const _RandomChapter('1PE', 4), const _RandomChapter('1PE', 5),
      const _RandomChapter('1JO', 1), const _RandomChapter('1JO', 2), const _RandomChapter('1JO', 3), const _RandomChapter('1JO', 4),
      
      // Old Testament Inspirational
      const _RandomChapter('ISA', 1), const _RandomChapter('ISA', 6), const _RandomChapter('ISA', 11), const _RandomChapter('ISA', 26), const _RandomChapter('ISA', 40), const _RandomChapter('ISA', 41), const _RandomChapter('ISA', 53), const _RandomChapter('ISA', 55),
      const _RandomChapter('JER', 17), const _RandomChapter('JER', 29), const _RandomChapter('JER', 31), const _RandomChapter('JER', 33),
      const _RandomChapter('EZE', 18), const _RandomChapter('EZE', 33), const _RandomChapter('EZE', 36), const _RandomChapter('EZE', 37),
      const _RandomChapter('DAN', 2), const _RandomChapter('DAN', 3), const _RandomChapter('DAN', 6), const _RandomChapter('DAN', 12),
      const _RandomChapter('JOS', 1), const _RandomChapter('JOS', 24),
      const _RandomChapter('GEN', 1), const _RandomChapter('GEN', 2), const _RandomChapter('GEN', 12), const _RandomChapter('GEN', 15), const _RandomChapter('GEN', 22), const _RandomChapter('GEN', 28), const _RandomChapter('GEN', 37), const _RandomChapter('GEN', 45), const _RandomChapter('GEN', 50),
      const _RandomChapter('EXO', 3), const _RandomChapter('EXO', 14), const _RandomChapter('EXO', 19), const _RandomChapter('EXO', 20), const _RandomChapter('EXO', 33), const _RandomChapter('EXO', 34),
      const _RandomChapter('DEU', 6), const _RandomChapter('DEU', 30), const _RandomChapter('DEU', 31),
    ];
  }

  BibleVerseContent _getFallbackVerse(int index) {
    final fallbackVerses = [
      const BibleVerseContent(
        id: 1001,
        chapter: 3,
        verse: 16,
        text: 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
        reference: 'John 3:16',
      ),
      const BibleVerseContent(
        id: 1002,
        chapter: 4,
        verse: 13,
        text: 'I can do all this through him who gives me strength.',
        reference: 'Philippians 4:13',
      ),
      const BibleVerseContent(
        id: 1003,
        chapter: 41,
        verse: 10,
        text: 'So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.',
        reference: 'Isaiah 41:10',
      ),
      const BibleVerseContent(
        id: 1004,
        chapter: 8,
        verse: 28,
        text: 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
        reference: 'Romans 8:28',
      ),
      const BibleVerseContent(
        id: 1005,
        chapter: 29,
        verse: 11,
        text: 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.',
        reference: 'Jeremiah 29:11',
      ),
    ];
    
    return fallbackVerses[index % fallbackVerses.length];
  }
}
