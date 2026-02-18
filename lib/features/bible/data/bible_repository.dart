import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/bible_content.dart';
import '../domain/models/bible_insight.dart';
import '../domain/models/bible_version.dart';
import 'services/bible_database_service.dart';

class BibleRepository extends BaseRepository {
  BibleRepository(this._client, Logger logger, this._dbService) : super(logger);

  final DioClient _client;
  final BibleDatabaseService _dbService;

  Future<List<BibleBook>> getBooks() {
    return guard(() async {
      final response = await _client.get('/bible/books');
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => BibleBook.fromJson(json)).toList();
    }, operation: 'get_bible_books');
  }

  Future<List<BibleVerseContent>> getVerses(String version, String book, int chapter) {
    return guard(() async {
      // Check if we should use local DB
      // We assume 'version' is the table name or abbreviation.
      // If it ends with .db or we know it's downloaded, use local.
      
      final isDownloaded = await _dbService.isVersionDownloaded(version);
      if (isDownloaded) {
        return await _dbService.getChapter(version, book, chapter);
      }

      final response = await _client.get('/bible/verses/$version/$book/$chapter');
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => BibleVerseContent.fromJson(json)).toList();
    }, operation: 'get_bible_verses');
  }

  Future<List<BibleVersion>> getVersions() {
    return guard(() async {
      final response = await _client.get('/bible/versions');
      final List<dynamic> data = response.data['data'] ?? response.data;
      final versions = data.map((json) => BibleVersion.fromJson(json)).toList();
      
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

  Future<BibleInsight> getVerseInsight(int verseId) {
    return guard(() async {
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
    }, operation: 'get_verse_insight');
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
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => BibleVerseContent.fromJson(json)).toList();
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
}
