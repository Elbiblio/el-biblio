import 'dart:math' as math;

/// A church returned by the `/churches/nearby` endpoint.
///
/// Backend source is the internal `churches` table (Laravel `ChurchResource`).
/// Denomination is optional so the model tolerates both the current
/// Catholic-only filter and the forthcoming multi-denomination query.
class Church {
  const Church({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.denomination,
    this.distanceKm,
    this.website,
    this.phone,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? denomination;

  /// Pre-computed by backend (haversine). Null if not provided; client
  /// re-derives via [computeDistanceKm].
  final double? distanceKm;
  final String? website;
  final String? phone;

  factory Church.fromMap(Map<String, dynamic> map) {
    return Church(
      id: (map['id'] ?? map['uuid'] ?? '').toString(),
      name: (map['name'] ?? 'Unnamed church').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      address: map['address'] as String?,
      denomination: map['denomination'] as String?,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ??
          (map['distance'] as num?)?.toDouble(),
      website: map['website'] as String?,
      phone: map['phone'] as String?,
    );
  }

  /// Haversine between two lat/lng points, km.
  static double computeDistanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}
