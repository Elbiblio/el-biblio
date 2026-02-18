import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../../../shared/domain/models/activity.dart';

class BibleReadingRepository extends BaseRepository {
  BibleReadingRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<Map<String, dynamic>> completeDailyReading({
    required String readingMode,
    String? planName,
    int? durationMinutes,
    List<String>? chaptersRead,
    String? notes,
    DateTime? date,
  }) {
    return guard(() async {
      final response = await _client.post(
        '/bible-reading/daily/complete',
        data: {
          'reading_mode': readingMode,
          if (planName != null) 'plan_name': planName,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
          if (chaptersRead != null) 'chapters_read': chaptersRead,
          if (notes != null) 'notes': notes,
          if (date != null) 'date': date.toIso8601String().split('T')[0],
        },
      );
      return response.data['data'] ?? response.data;
    }, operation: 'complete_daily_reading');
  }

  Future<List<Activity>> getHistory({DateTime? fromDate, DateTime? toDate, int perPage = 30}) {
    return guard(() async {
      final response = await _client.get(
        '/bible-reading/daily/history',
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate.toIso8601String().split('T')[0],
          if (toDate != null) 'to_date': toDate.toIso8601String().split('T')[0],
          'per_page': perPage,
        },
      );
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => Activity.fromJson(json)).toList();
    }, operation: 'get_reading_history');
  }

  Future<Map<String, dynamic>> getStreak() {
    return guard(() async {
      final response = await _client.get('/bible-reading/daily/streak');
      return response.data['data'] ?? response.data;
    }, operation: 'get_reading_streak');
  }
}
