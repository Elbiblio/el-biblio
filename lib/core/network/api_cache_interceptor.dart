import 'package:dio/dio.dart';

class ApiCacheInterceptor extends Interceptor {
  ApiCacheInterceptor({
    this.maxEntries = 150,
    this.cacheDuration = const Duration(minutes: 10),
  });

  final int maxEntries;
  final Duration cacheDuration;
  final _cache = <String, _CachedResponse>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }

    final key = _cacheKey(options);
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          data: cached.data,
          statusCode: 200,
        ),
      );
      return;
    }

    if (cached != null && cached.isExpired) {
      _cache.remove(key);
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    if (options.method.toUpperCase() == 'GET' && response.statusCode == 200) {
      final key = _cacheKey(options);
      _cache[key] = _CachedResponse(
        data: response.data,
        expiresAt: DateTime.now().add(cacheDuration),
      );

      while (_cache.length > maxEntries) {
        _cache.remove(_cache.keys.first);
      }
    }

    handler.next(response);
  }

  String _cacheKey(RequestOptions options) {
    final query = options.queryParameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    return '${options.path}?$query';
  }

  void clear() {
    _cache.clear();
  }
}

class _CachedResponse {
  _CachedResponse({
    required this.data,
    required this.expiresAt,
  });

  final dynamic data;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
