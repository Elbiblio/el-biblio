import 'package:logger/logger.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../../../core/services/connectivity_service.dart';
import '../domain/models/commitment.dart';
import '../domain/models/daily_anchors.dart';
import 'offline_commitment_data.dart';

class CommitmentRepository extends BaseRepository {
  CommitmentRepository(this._dioClient, this._logger, {ConnectivityService? connectivityService})
      : _connectivityService = connectivityService, super(_logger);

  final DioClient _dioClient;
  final Logger _logger;
  final ConnectivityService? _connectivityService;

  Future<List<Commitment>> getCommitmentsForVirtue(int virtueId) async {
    try {
      // Check connectivity first
      if (_connectivityService != null) {
        final isConnected = await _connectivityService.checkConnectivity();
        if (!isConnected) {
          _logger.w('No internet connection, using offline data for virtue $virtueId');
          final virtueType = _virtueIdToType(virtueId);
          if (virtueType != null) {
            return OfflineCommitmentData.getCommitmentsForVirtue(virtueType);
          }
          throw Exception('No internet connection and virtue type not found');
        }
      }

      // Check if user is guest and use offline data
      final token = _dioClient.currentAuthToken;
      if (isGuestToken(token)) {
        _logger.w('Guest user detected, using offline data for virtue $virtueId');
        final virtueType = _virtueIdToType(virtueId);
        if (virtueType != null) {
          return OfflineCommitmentData.getCommitmentsForVirtue(virtueType);
        }
        throw Exception('Guest user and virtue type not found');
      }

      // Fixed: Removed double /api prefix - DioClient baseUrl already includes /api
      final response = await _dioClient.get('/virtues/$virtueId/commitments');
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _logger.i('Successfully loaded ${data.length} commitments for virtue $virtueId from API');
        return data.map((json) => Commitment.fromJson(json)).toList();
      }
      throw Exception('Failed to load commitments: Status ${response.statusCode}');
    } catch (e) {
      _logger.e('Error loading commitments for virtue $virtueId, falling back to offline data', error: e);
      
      // Convert virtueId to VirtueType for offline fallback
      final virtueType = _virtueIdToType(virtueId);
      if (virtueType != null) {
        _logger.i('Using offline fallback data for virtue $virtueId (${virtueType.name})');
        return OfflineCommitmentData.getCommitmentsForVirtue(virtueType);
      }
      
      // If we can't determine the virtue type, rethrow the original error
      rethrow;
    }
  }

  /// Convert virtue ID to VirtueType for offline fallback
  VirtueType? _virtueIdToType(int virtueId) {
    switch (virtueId) {
      case 1:
        return VirtueType.humility;
      case 2:
        return VirtueType.love;
      case 3:
        return VirtueType.faith;
      case 4:
        return VirtueType.knowledge;
      default:
        return null;
    }
  }
}
