import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../domain/models/user_profile.dart';

class ProfileRepository extends BaseRepository {
  ProfileRepository(this._client, Logger logger) : super(logger);

  final DioClient _client;

  Future<UserProfile> getCurrentUserProfile() {
    return guard(() async {
      final token = _client.currentAuthToken;
      
      // Check if user is guest and return offline profile
      if (isGuestToken(token)) {
        logger.i('Creating offline guest user profile');
        return UserProfile.createGuestProfile();
      }
      
      final response = await _client.get('/auth/me');
      final data = response.data['data'] ?? response.data;
      return UserProfile.fromJson(data);
    }, operation: 'get_current_user_profile', token: _client.currentAuthToken);
  }

  Future<UserProfile> getUserProfile(int userId) {
    return guard(() async {
      final token = _client.currentAuthToken;
      
      // Check if user is guest and return offline profile
      if (isGuestToken(token)) {
        logger.i('Creating offline guest user profile for user ID: $userId');
        return UserProfile.createGuestProfile();
      }
      
      final response = await _client.get('/users/$userId');
      final data = response.data['data'] ?? response.data;
      return UserProfile.fromJson(data);
    }, operation: 'get_user_profile', token: _client.currentAuthToken);
  }

  Future<UserStats> getUserStats(int userId) {
    return guard(() async {
      final token = _client.currentAuthToken;
      
      // Check if user is guest and return offline stats
      if (isGuestToken(token)) {
        logger.i('Creating offline guest user stats for user ID: $userId');
        return UserStats.createGuestStats();
      }
      
      final response = await _client.get('/users/$userId/stats');
      final data = response.data['data'] ?? response.data;
      return UserStats.fromJson(data);
    }, operation: 'get_user_stats', token: _client.currentAuthToken);
  }

  Future<UserStats> getCurrentUserStats() {
    return guard(() async {
      final token = _client.currentAuthToken;
      
      // Check if user is guest and return offline stats
      if (isGuestToken(token)) {
        logger.i('Creating offline guest user stats');
        return UserStats.createGuestStats();
      }
      
      // First get current user to get their ID
      final userResponse = await _client.get('/auth/me');
      final userData = userResponse.data['data'] ?? userResponse.data;
      final userId = userData['id'];
      
      // Then get stats for that user
      final statsResponse = await _client.get('/users/$userId/stats');
      final statsData = statsResponse.data['data'] ?? statsResponse.data;
      return UserStats.fromJson(statsData);
    }, operation: 'get_current_user_stats', token: _client.currentAuthToken);
  }

}
