import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../errors/app_exception.dart';

abstract class BaseRepository {
  BaseRepository(this.logger);

  final Logger logger;

  Future<T> guard<T>(
    Future<T> Function() run, {
    String operation = 'repository_operation',
  }) async {
    try {
      return await run();
    } on AppException {
      rethrow;
    } on DioException catch (error, stackTrace) {
      logger.e('Dio failure while $operation', error: error, stackTrace: stackTrace);
      throw NetworkException(
        error.message ?? 'A network error occurred.',
        error.response?.data,
      );
    } catch (error, stackTrace) {
      logger.e('Unexpected failure while $operation', error: error, stackTrace: stackTrace);
      throw AppException(
        'Something went wrong while processing your request.',
        'unexpected_error',
        error,
      );
    }
  }
}
