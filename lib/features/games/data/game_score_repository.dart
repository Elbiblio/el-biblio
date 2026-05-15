import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/network/dio_client.dart';

class GameScoreRepository {
  GameScoreRepository(this._dio, this._logger);

  final DioClient _dio;
  final Logger _logger;

  Future<bool> submitScore({
    required String gameId,
    required int score,
    Map<String, dynamic>? meta,
  }) async {
    if (score <= 0) return false;

    try {
      final response = await _dio.post(
        '/game/scores',
        data: <String, dynamic>{
          'game_id': gameId,
          'score': score,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          if (meta != null && meta.isNotEmpty) 'meta': meta,
        },
      );

      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } catch (error, stackTrace) {
      _logger.w(
        'Game score sync failed for $gameId',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

final gameScoreRepositoryProvider = Provider<GameScoreRepository>((ref) {
  return GameScoreRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});
