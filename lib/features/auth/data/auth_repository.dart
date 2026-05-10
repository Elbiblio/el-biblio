import 'package:logger/logger.dart';

import '../../../core/errors/app_exception.dart';
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
          if (data.ageBand != null) 'user_settings': {'age_band': data.ageBand},
        },
      );

      if (response.data == null) {
        throw Exception('Signup failed: No response data');
      }

      final responseData = response.data!;

      // Handle Laravel validation errors (422 responses)
      if (response.statusCode == 422 || responseData['errors'] != null) {
        final errors = responseData['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          // Get the first validation error message
          final firstErrors = errors.values.first;
          final message = firstErrors is List && firstErrors.isNotEmpty
              ? firstErrors.first.toString()
              : responseData['message'] ?? 'Validation failed';
          throw Exception(message);
        }
        throw Exception(responseData['message'] ?? 'Validation failed');
      }

      if (responseData['success'] == false) {
        throw Exception(responseData['message'] ?? 'Signup failed');
      }

      // Laravel API returns {success: true, data: {...}, message: "..."}
      // After successful registration, login instantly with the generated credentials
      if (responseData['success'] == true && responseData['data'] != null) {
        return await login(data.email, data.password);
      }

      throw Exception('Signup failed. Please try again.');
    } catch (e) {
      _logger.e('Signup error', error: e);
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
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
    throw GuestUserException(
      'Guest mode is unavailable for launch. Please create an account to continue.',
      'guest_auth_disabled',
    );
  }

  Future<User> updateUserProfile(
    String userId, {
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
}
