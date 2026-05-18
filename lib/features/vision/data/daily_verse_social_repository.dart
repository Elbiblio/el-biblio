import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../../bible/domain/models/verse.dart';
import '../domain/daily_verse_social_models.dart';

class DailyVerseSocialRepository extends BaseRepository {
  DailyVerseSocialRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<Verse?> todayVerse() {
    return guard(
      () async {
        final response = await _client.get<Map<String, dynamic>>(
          '/verses/daily',
          queryParameters: {'include': 'theme', 'date_range': 'today'},
        );
        final list = payloadList(response.data);
        if (list.isEmpty || list.first is! Map) return null;
        return Verse.fromJson(Map<String, dynamic>.from(list.first as Map));
      },
      operation: 'daily_verse_social_today',
      token: _client.currentAuthToken,
    );
  }

  Future<List<DailyVerseReflection>> reflectionsForVerse(
    int verseId, {
    int perPage = 20,
  }) {
    return guard(
      () async {
        final response = await _client.get<Map<String, dynamic>>(
          '/reflections',
          queryParameters: {
            'verse_id': verseId,
            'include': 'user,comments.user',
            'is_published': 1,
            '_sort_by': '-created_at',
            'per_page': perPage,
          },
        );
        return payloadList(response.data)
            .whereType<Map>()
            .map(
              (item) => DailyVerseReflection.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      },
      operation: 'daily_verse_social_reflections',
      token: _client.currentAuthToken,
    );
  }

  Future<DailyVerseReflection> postReflection({
    required int userId,
    required int verseId,
    required String content,
  }) {
    return guard(
      () async {
        final response = await _client.post<Map<String, dynamic>>(
          '/reflections',
          data: {
            'user_id': userId,
            'verse_id': verseId,
            'type': 2,
            'content': content.trim(),
            'is_published': true,
            'icon': 'message-circle',
          },
        );
        return DailyVerseReflection.fromJson(payloadMap(response.data));
      },
      operation: 'daily_verse_social_post_reflection',
      token: _client.currentAuthToken,
    );
  }

  Future<DailyVerseComment> postComment({
    required int userId,
    required int reflectionId,
    required String content,
  }) {
    return guard(
      () async {
        final response = await _client.post<Map<String, dynamic>>(
          '/comments',
          data: {
            'user_id': userId,
            'reflection_id': reflectionId,
            'content': content.trim(),
          },
        );
        return DailyVerseComment.fromJson(payloadMap(response.data));
      },
      operation: 'daily_verse_social_post_comment',
      token: _client.currentAuthToken,
    );
  }

  Future<DailyVerseLikeResult> setVerseLiked({
    required int verseId,
    required bool liked,
  }) {
    return guard(
      () async {
        final response = await _client.post<Map<String, dynamic>>(
          '/verses/$verseId/like',
          data: {'action': liked ? 'like' : 'unlike'},
        );
        return DailyVerseLikeResult.fromJson(payloadMap(response.data));
      },
      operation: 'daily_verse_social_like',
      token: _client.currentAuthToken,
    );
  }

  Future<DailyVerseVoteResult> voteVerse(int verseId) {
    return guard(
      () async {
        final response = await _client.post<Map<String, dynamic>>(
          '/verses/$verseId/vote',
        );
        return DailyVerseVoteResult.fromJson(payloadMap(response.data));
      },
      operation: 'daily_verse_social_vote',
      token: _client.currentAuthToken,
    );
  }

  Future<DailyVerseShareResult> trackShare({
    required int verseId,
    required String message,
    String platform = 'share_sheet',
  }) {
    return guard(
      () async {
        final response = await _client.post<Map<String, dynamic>>(
          '/verses/$verseId/share',
          data: {'platform': platform, 'message': message},
        );
        return DailyVerseShareResult.fromJson(payloadMap(response.data));
      },
      operation: 'daily_verse_social_share',
      token: _client.currentAuthToken,
    );
  }
}
