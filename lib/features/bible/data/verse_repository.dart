import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/verse.dart';

class VerseRepository extends BaseRepository {
  VerseRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<List<Verse>> getDailyVerses() async {
    try {
      final token = _client.currentAuthToken;

      // For guest users, return empty list since verse API requires authentication
      if (isGuestToken(token)) {
        logger.w('Guest user detected, verse API not available');
        return [];
      }

      final response = await _client.get(
        '/verses/daily',
        queryParameters: {'include': 'theme', 'date_range': 'both'},
      );

      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Verse.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load daily verses: $e');
    }
  }

  Future<List<Verse>> getRandomVerses(int count) async {
    try {
      final token = _client.currentAuthToken;

      // For guest users, return empty list since verse API requires authentication
      if (isGuestToken(token)) {
        logger.w('Guest user detected, verse API not available');
        return [];
      }

      final response = await _client.get(
        '/verses/random',
        queryParameters: {'count': count},
      );

      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Verse.fromJson(json)).toList();
    } catch (e) {
      final fallback = await getDailyVerses();
      if (fallback.isEmpty) {
        rethrow;
      }
      final shuffled = List<Verse>.from(fallback)..shuffle();
      return shuffled.take(count.clamp(1, shuffled.length)).toList();
    }
  }

  Future<Map<String, dynamic>> explainVerse({
    required String verseId,
    required String reference,
    required String text,
    String? version,
    String? prompt,
  }) async {
    try {
      final token = _client.currentAuthToken;

      // For guest users, return basic explanation since AI insights require authentication
      if (isGuestToken(token)) {
        logger.w('Guest user detected, AI insights not available');
        return {
          'explanation': 'Create an account to open AI-powered insights.',
          'available': false,
        };
      }

      final payload = {
        'reference': reference,
        'text': text.trim(),
        'version': version ?? 'eng_rv_vpl',
        if (prompt != null) 'prompt': prompt,
      };

      final response = await _client.post(
        '/bible/verses/$verseId/explain',
        data: payload,
      );

      if (response.data['success'] == false) {
        throw Exception(
          response.data['message'] ?? 'Unable to generate insight.',
        );
      }

      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to explain verse: $e');
    }
  }

  Future<Verse?> getVerse(int id) {
    return guard(
      () async {
        final token = _client.currentAuthToken;

        // For guest users, return null since verse API requires authentication
        if (isGuestToken(token)) {
          logger.w('Guest user detected, verse API not available');
          return null;
        }

        final response = await _client.get(
          '/verses/$id',
          queryParameters: {'include': 'theme'},
        );

        final data = response.data['data'];
        return Verse.fromJson(data);
      },
      operation: 'get_verse',
      token: _client.currentAuthToken,
    );
  }

  Future<bool> voteVerse(int id) {
    return guard(
      () async {
        final token = _client.currentAuthToken;

        // For guest users, return false since voting requires authentication
        if (isGuestToken(token)) {
          logger.w('Guest user detected, voting not available');
          return false;
        }

        final response = await _client.raw.post('/verses/$id/vote');
        return response.data['success'] == true;
      },
      operation: 'vote_verse',
      token: _client.currentAuthToken,
    );
  }
}
