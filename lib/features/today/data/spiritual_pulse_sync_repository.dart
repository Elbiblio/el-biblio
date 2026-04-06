import 'package:elbiblio/core/errors/app_exception.dart';
import 'package:elbiblio/core/network/dio_client.dart';
import 'package:elbiblio/core/repository/base_repository.dart';
import 'package:logger/logger.dart';

import '../domain/models/daily_anchors.dart';

class SpiritualPulseSyncRepository extends BaseRepository {
  SpiritualPulseSyncRepository(this._dioClient, Logger logger) : super(logger);

  final DioClient _dioClient;

  Future<SpiritualPulseResponse?> fetchLatest() async {
    return guard(() async {
      try {
        final response = await _dioClient.get<Map<String, dynamic>>(
          '/spiritual-pulses/latest',
        );

        final data = response.data;
        if (data == null) return null;

        return SpiritualPulseResponse.fromJson(data);
      } catch (e) {
        // If latest doesn't exist, return null
        return null;
      }
    }, operation: 'fetch_latest_spiritual_pulse');
  }

  Future<SpiritualPulseResponse> createPulse(SpiritualPulseResponse pulse) async {
    return guard(() async {
      final payload = pulse.toJson();

      final response = await _dioClient.post<Map<String, dynamic>>(
        '/spiritual-pulses',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to create spiritual pulse', 'create_failed');
      }

      return SpiritualPulseResponse.fromJson(data);
    }, operation: 'create_spiritual_pulse');
  }

  Future<SpiritualPulseResponse> updatePulse(SpiritualPulseResponse pulse) async {
    return guard(() async {
      final payload = pulse.toJson();

      // Since SpiritualPulseResponse doesn't have an id, we'll update by date
      final dateKey = pulse.lastUpdated.toIso8601String().split('T')[0];
      final response = await _dioClient.put<Map<String, dynamic>>(
        '/spiritual-pulses/$dateKey',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw AppException('Failed to update spiritual pulse', 'update_failed');
      }

      return SpiritualPulseResponse.fromJson(data);
    }, operation: 'update_spiritual_pulse');
  }
}
