import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../errors/app_exception.dart';
import 'api_cache_interceptor.dart';

class DioClient {
  DioClient(this._logger)
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
            responseType: ResponseType.json,
            headers: const <String, dynamic>{
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.addAll(<Interceptor>[
      ApiCacheInterceptor(),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('[Dio] ${options.method} ${options.path}');
          handler.next(options);
        },
        onError: (error, handler) {
          _logger.e(
            '[Dio] Error ${error.requestOptions.path}',
            error: error,
            stackTrace: error.stackTrace,
          );
          handler.next(error);
        },
      ),
    ]);
  }

  final Logger _logger;
  final Dio _dio;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw NetworkException(
        error.message ?? 'Network request failed.',
        error.response?.data,
      );
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw NetworkException(
        error.message ?? 'Network request failed.',
        error.response?.data,
      );
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw NetworkException(
        error.message ?? 'Network request failed.',
        error.response?.data,
      );
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw NetworkException(
        error.message ?? 'Network request failed.',
        error.response?.data,
      );
    }
  }
}
