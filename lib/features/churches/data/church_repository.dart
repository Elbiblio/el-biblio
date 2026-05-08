import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../domain/models/church.dart';

class ChurchRepository {
  ChurchRepository(this._dio, this._logger);

  final DioClient _dio;
  final Logger _logger;

  Future<List<Church>> findNearby({
    required double lat,
    required double lng,
    double radiusKm = 10,
    int limit = 30,
    String? denomination,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/churches/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radiusKm,
          'limit': limit,
          if (denomination != null) 'denomination': denomination,
        },
      );

      final body = response.data;
      if (body == null) return const [];
      final raw = body['data'] ?? body['churches'] ?? body;
      if (raw is! List) return const [];

      final churches = raw
          .whereType<Map>()
          .map((m) => Church.fromMap(Map<String, dynamic>.from(m)))
          .toList();

      // Hydrate distance if backend did not include it.
      return churches
          .map((c) => c.distanceKm != null
              ? c
              : Church(
                  id: c.id,
                  name: c.name,
                  latitude: c.latitude,
                  longitude: c.longitude,
                  address: c.address,
                  denomination: c.denomination,
                  website: c.website,
                  phone: c.phone,
                  distanceKm: Church.computeDistanceKm(
                    lat1: lat,
                    lng1: lng,
                    lat2: c.latitude,
                    lng2: c.longitude,
                  ),
                ))
          .toList()
        ..sort((a, b) =>
            (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
    } catch (e) {
      _logger.w('[Churches] findNearby failed: $e');
      rethrow;
    }
  }
}
