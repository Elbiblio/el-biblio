import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../errors/app_exception.dart';

abstract class BaseRepository {
  BaseRepository(this.logger);

  final Logger logger;

  /// Checks if the given token is a guest token
  bool isGuestToken(String? token) {
    return token != null && token.startsWith('guest_token_');
  }

  /// Checks if a DioException is a 401 authentication error
  bool isAuthenticationError(DioException error) {
    return error.response?.statusCode == 401;
  }

  Future<T> guard<T>(
    Future<T> Function() run, {
    String operation = 'repository_operation',
    String? token,
  }) async {
    try {
      return await run();
    } on AppException {
      rethrow;
    } on DioException catch (error, stackTrace) {
      logger.e('Dio failure while $operation: ${error.type}', error: error, stackTrace: stackTrace);
      
      // If this is a 401 error for a guest token, throw a specific exception
      if (isAuthenticationError(error) && isGuestToken(token)) {
        logger.w('Guest token authentication failed for $operation - expected behavior');
        throw GuestUserException('Feature not available for guest users', operation);
      }
      
      // Extract the better error message if available
      String message = error.error?.toString() ?? error.message ?? 'A network error occurred.';
      
      throw NetworkException(message, {
        'type': error.type.toString(),
        'statusCode': error.response?.statusCode,
        'path': error.requestOptions.path,
        'method': error.requestOptions.method,
      });
    } catch (error, stackTrace) {
      logger.e('Unexpected failure while $operation', error: error, stackTrace: stackTrace);
      throw AppException(
        'Something went wrong while processing your request.',
        'unexpected_error',
        error.toString(),
      );
    }
  }
}
