import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/verse.dart';

class VerseRepository extends BaseRepository {
  VerseRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<List<Verse>> getDailyVerses() {
    return guard(() async {
      final response = await _client.get(
        '/verses/daily',
        queryParameters: {
          'include': 'theme',
          'sort': '-created_at',
          'date_range': 'both', // Get both today and tomorrow's verses
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => Verse.fromJson(json)).toList();
    }, operation: 'get_daily_verses');
  }

  Future<Verse?> getVerse(int id) {
    return guard(() async {
      final response = await _client.get(
        '/verses/$id',
        queryParameters: {
          'include': 'theme',
        },
      );

      final data = response.data['data'];
      return Verse.fromJson(data);
    }, operation: 'get_verse');
  }

  Future<bool> voteVerse(int id) {
    return guard(() async {
      final response = await _client.raw.post('/verses/$id/vote');
      return response.data['success'] == true;
    }, operation: 'vote_verse');
  }
}
