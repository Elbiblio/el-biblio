import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../errors/app_exception.dart';
import 'api_cache_interceptor.dart';

class DioClient {
  DioClient(this._logger, {String? baseUrl, String? authToken})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? 'https://api.elbiblio.com/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          responseType: ResponseType.json,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'User-Agent': 'ElBiblio-Agent/1.0',
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
          validateStatus: (status) => status != null && status < 400,
        ),
      ) {
    _dio.interceptors.addAll(<Interceptor>[
      ApiCacheInterceptor(),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('[Dio] ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            '[Dio] Response ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          if (_isExpectedEmptyNotificationsResponse(error)) {
            _logger.d(
              '[Dio] Empty notifications response ${error.response?.statusCode}',
            );
          } else {
            _logger.e(
              '[Dio] Error ${error.requestOptions.method} ${error.requestOptions.path} - ${error.type}',
              error: error,
              stackTrace: error.stackTrace,
            );
          }

          // Provide better error messages
          String errorMessage =
              _messageFromResponse(error.response?.data) ??
              'Network request failed';
          switch (error.type) {
            case DioExceptionType.connectionTimeout:
              errorMessage =
                  'Connection timeout. Please check your internet connection.';
              break;
            case DioExceptionType.sendTimeout:
              errorMessage = 'Request timeout. Please try again.';
              break;
            case DioExceptionType.receiveTimeout:
              errorMessage = 'Server response timeout. Please try again.';
              break;
            case DioExceptionType.connectionError:
              errorMessage =
                  'No internet connection. Please check your network settings.';
              break;
            case DioExceptionType.badCertificate:
              errorMessage =
                  'SSL certificate error. Please check your device\'s date and time settings.';
              break;
            case DioExceptionType.badResponse:
              final statusCode = error.response?.statusCode;
              if (statusCode != null) {
                switch (statusCode) {
                  case 401:
                    errorMessage =
                        _messageFromResponse(error.response?.data) ??
                        'Authentication failed. Please log in again.';
                    break;
                  case 403:
                    errorMessage =
                        _messageFromResponse(error.response?.data) ??
                        'Access forbidden. You don\'t have permission to access this resource.';
                    break;
                  case 404:
                    errorMessage =
                        _messageFromResponse(error.response?.data) ??
                        'Resource not found.';
                    break;
                  case 429:
                    errorMessage =
                        _messageFromResponse(error.response?.data) ??
                        'Too many requests. Please wait and try again.';
                    break;
                  case 500:
                    errorMessage =
                        _messageFromResponse(error.response?.data) ??
                        'Server error. Please try again later.';
                    break;
                  default:
                    errorMessage =
                        _messageFromResponse(error.response?.data) ??
                        'Server error ($statusCode). Please try again.';
                }
              }
              break;
            case DioExceptionType.cancel:
              errorMessage = 'Request was cancelled.';
              break;
            case DioExceptionType.unknown:
              errorMessage = 'Unknown network error occurred.';
              break;
          }

          // Create a new error with better message
          final betterError = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: errorMessage,
            stackTrace: error.stackTrace,
          );

          handler.next(betterError);
        },
      ),
    ]);
  }

  final Logger _logger;
  final Dio _dio;

  Dio get raw => _dio;

  void updateAuthToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Gets the current auth token from the headers
  String? get currentAuthToken {
    final authHeader = _dio.options.headers['Authorization'] as String?;
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7); // Remove 'Bearer ' prefix
    }
    return null;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw _networkExceptionFor(error);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final options = headers != null ? Options(headers: headers) : null;
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw _networkExceptionFor(error);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw _networkExceptionFor(error);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw _networkExceptionFor(error);
    }
  }

  NetworkException _networkExceptionFor(DioException error) {
    final statusCode = error.response?.statusCode;
    final message =
        _messageFromResponse(error.response?.data) ??
        error.message ??
        'Network request failed.';
    if (statusCode != null) {
      return ApiRequestException(
        statusCode: statusCode,
        message: message,
        details: error.response?.data,
      );
    }
    return NetworkException(message, error.response?.data);
  }

  static String? _messageFromResponse(dynamic data) {
    if (data is Map) {
      final direct = data['message'] ?? data['error'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return first.toString();
      }
    }
    return null;
  }

  static bool _isExpectedEmptyNotificationsResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 400 && statusCode != 404) return false;
    if (error.requestOptions.path != '/notifications/user') return false;
    final message = _messageFromResponse(error.response?.data)?.toLowerCase();
    return message != null &&
        message.contains('notification') &&
        message.contains('not found');
  }
}
