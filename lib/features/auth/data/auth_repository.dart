import 'dart:math';
import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../domain/models/auth_models.dart';

class AuthRepository {
  final DioClient _dioClient;
  final Logger _logger;

  AuthRepository(this._dioClient, this._logger);

  Future<AuthResponse> signUp(SignUpData data) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/users',
        data: {
          'email': data.email,
          'password': data.password,
          'first_name': data.firstName,
          'last_name': data.lastName,
          'phone': data.phone,
          'avatar': data.avatar,
          'primary_language': data.primaryLanguage ?? 'en',
        },
      );

      if (response.data == null) {
        throw Exception('Signup failed: No response data');
      }

      final responseData = response.data!;
      
      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Signup failed');
      }

      // Laravel API returns {success: true, data: {...}, message: "..."}
      // After successful registration, login instantly with the generated credentials
      if (responseData['success'] == true && responseData['data'] != null) {
        // Login immediately after successful registration
        return await login(data.email, data.password);
      }

      throw Exception('Invalid response format from server: $responseData');
    } catch (e) {
      _logger.e('Signup error', error: e);
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data == null) {
        throw Exception('Login failed: No response data');
      }

      final responseData = response.data!;
      
      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Login failed');
      }

      if (responseData['token'] != null && responseData['user'] != null) {
        return AuthResponse.fromJson(responseData);
      }

      throw Exception('Invalid response format from server');
    } catch (e) {
      _logger.e('Login error', error: e);
      rethrow;
    }
  }

  Future<AuthResponse> createGuestAccount() async {
    // Bypass API call and create a local guest account for onboarding flow
    final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = '${_randomString(6)}${timestampStr.substring(timestampStr.length - 4)}';
    final email = 'guest_$suffix@guest.elbiblio.com';

    _logger.i('[Auth] Creating local guest account with email: $email');

    // Create a mock user and auth response without server call
    final user = User(
      id: 'guest_$suffix',
      email: email,
      firstName: 'Guest',
      lastName: suffix,
      createdAt: DateTime.now(),
    );

    // Return a mock auth response
    return AuthResponse(
      token: 'guest_token_$suffix',
      user: user,
    );
  }

  Future<User> updateUserProfile(String userId, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (avatar != null) data['avatar'] = avatar;

      final response = await _dioClient.put<Map<String, dynamic>>(
        '/users/$userId',
        data: data,
      );

      if (response.data == null) {
        throw Exception('Profile update failed: No response data');
      }

      final responseData = response.data!;
      
      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Profile update failed');
      }

      // Handle different response formats
      Map<String, dynamic> userData;
      if (responseData['data'] != null) {
        userData = responseData['data'];
      } else if (responseData['user'] != null) {
        userData = responseData['user'];
      } else {
        userData = responseData;
      }

      return User.fromJson(userData);
    } catch (e) {
      _logger.e('Profile update error', error: e);
      rethrow;
    }
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
