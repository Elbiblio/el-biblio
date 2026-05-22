import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/application/push_token_notifier.dart';
import '../data/auth_repository.dart';
import '../domain/models/auth_models.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._dioClient, [this._pushTokenNotifier])
    : super(const AuthState());

  final AuthRepository _repository;
  final DioClient _dioClient;
  final PushTokenNotifier? _pushTokenNotifier;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _guestCredentialsKey = 'guest_credentials';

  Future<void> initialize() async {
    if (state.isInitialized) return;

    try {
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey);
      final storedUserData = prefs.getString(_userKey);
      final guestCreds = prefs.getString(_guestCredentialsKey);

      if (storedToken != null && storedUserData != null) {
        try {
          final userJson = jsonDecode(storedUserData) as Map<String, dynamic>;
          final user = User.fromJson(userJson);

          // Update DioClient with stored token
          _dioClient.updateAuthToken(storedToken);

          state = state.copyWith(
            token: storedToken,
            user: user,
            isAuthenticated: true,
            isRestoredSession: true,
            isGuest: guestCreds != null,
            isInitialized: true,
            isLoading: false,
          );
          return;
        } catch (e) {
          // Clear corrupted data
          await prefs.remove(_tokenKey);
          await prefs.remove(_userKey);
          _dioClient.updateAuthToken(null);
        }
      }

      // Try silent guest login if we have stored credentials
      if (guestCreds != null && storedToken == null) {
        try {
          final credentials = jsonDecode(guestCreds) as Map<String, dynamic>;
          final email = credentials['email'] as String;
          final password = credentials['password'] as String;

          final authResponse = await _repository.login(email, password);
          await _saveAuthData(
            authResponse.token,
            authResponse.user,
            credentials,
          );

          state = state.copyWith(
            token: authResponse.token,
            user: authResponse.user,
            isAuthenticated: true,
            isRestoredSession: true,
            isGuest: true,
            isInitialized: true,
            isLoading: false,
          );
          return;
        } catch (e) {
          await prefs.remove(_guestCredentialsKey);
        }
      }

      state = state.copyWith(isInitialized: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize auth: ${e.toString()}',
        isInitialized: true,
        isLoading: false,
      );
    }
  }

  Future<bool> signUpWithDetails({
    required String name,
    required String email,
    required String phone,
    String? password,
    String? ageBand,
    String? inviteToken,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final nameParts = name.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Generate a secure password
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final segmentStart = timestamp.length > 6 ? timestamp.length - 6 : 0;
      final randomSegment = timestamp.substring(segmentStart).padLeft(6, '0');
      final generatedPassword = '$randomSegment${firstName.toLowerCase()}!1';
      final resolvedPassword = password?.trim().isNotEmpty == true
          ? password!.trim()
          : generatedPassword;

      final signUpData = SignUpData(
        email: email,
        password: resolvedPassword,
        firstName: firstName,
        lastName: lastName.isNotEmpty ? lastName : null,
        phone: phone,
        primaryLanguage: 'en',
        ageBand: ageBand,
        inviteToken: inviteToken,
      );

      final authResponse = await _repository.signUp(signUpData);
      await _saveAuthData(authResponse.token, authResponse.user, null);

      state = state.copyWith(
        token: authResponse.token,
        user: authResponse.user,
        isAuthenticated: true,
        isRestoredSession: false,
        isGuest: false,
        isLoading: false,
      );

      // Sync push token after successful authentication
      await _syncPushToken(authResponse.user.id);

      return true;
    } catch (e) {
      String errorMessage = 'Signup failed';
      if (e is Exception) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        // Check for common validation messages
        if (msg.contains('email') && msg.contains('taken')) {
          errorMessage =
              'This email is already taken. Please use a different email.';
        } else if (msg.contains('email') && msg.contains('valid')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (msg.contains('Invalid response format')) {
          errorMessage = 'Signup failed. Please try again.';
        } else {
          errorMessage = msg;
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final authResponse = await _repository.login(email.trim(), password);
      await _saveAuthData(authResponse.token, authResponse.user, null);

      state = state.copyWith(
        token: authResponse.token,
        user: authResponse.user,
        isAuthenticated: true,
        isRestoredSession: false,
        isGuest: false,
        isLoading: false,
      );

      await _syncPushToken(authResponse.user.id);
      return true;
    } catch (e) {
      var errorMessage = 'Sign in failed';
      if (e is Exception) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('Invalid response format')) {
          errorMessage = 'Sign in failed. Please try again.';
        } else {
          errorMessage = msg;
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<bool> createGuestAccount() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final authResponse = await _repository.createGuestAccount();

      // Save guest credentials for potential re-login
      final guestCredentials = {
        'email': authResponse.user.email,
        // Note: We don't save the password for security, but could store a token
      };
      await _saveAuthData(
        authResponse.token,
        authResponse.user,
        guestCredentials,
      );

      state = state.copyWith(
        token: authResponse.token,
        user: authResponse.user,
        isAuthenticated: true,
        isRestoredSession: false,
        isGuest: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Guest account creation failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    try {
      if (state.user == null) {
        throw Exception('No authenticated user');
      }

      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = await _repository.updateUserProfile(
        state.user!.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        avatar: avatar,
      );

      state = state.copyWith(user: updatedUser, isLoading: false);

      // Save updated user data
      if (state.token != null) {
        await _saveAuthData(state.token!, updatedUser, null);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile update failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_guestCredentialsKey);

      _dioClient.updateAuthToken(null);

      // Clear push token state
      _pushTokenNotifier?.clearToken();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Logout failed: ${e.toString()}');
    }
  }

  /// Sync push token with backend after authentication
  Future<void> _syncPushToken(String userId) async {
    if (_pushTokenNotifier == null) return;

    try {
      final pushTokenState = _pushTokenNotifier.state;
      final token = pushTokenState.currentToken;

      if (token != null && token.isNotEmpty) {
        await _pushTokenNotifier.syncTokenToBackend(
          userId: userId,
          token: token,
        );

        // Subscribe to user-specific topics
        await _pushTokenNotifier.subscribeToUserTopics(userId);
      }
    } catch (e) {
      // Don't fail authentication if push token sync fails
      debugPrint('Failed to sync push token: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> _saveAuthData(
    String token,
    User user,
    Map<String, dynamic>? guestCredentials,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenSaved = await prefs.setString(_tokenKey, token);
    final userSaved = await prefs.setString(
      _userKey,
      jsonEncode(user.toJson()),
    );
    if (!tokenSaved || !userSaved) {
      await _clearStoredAuthData(prefs);
      throw Exception('Unable to save authentication session.');
    }

    if (guestCredentials != null) {
      final guestSaved = await prefs.setString(
        _guestCredentialsKey,
        jsonEncode(guestCredentials),
      );
      if (!guestSaved) {
        await _clearStoredAuthData(prefs);
        throw Exception('Unable to save guest session.');
      }
    } else {
      await prefs.remove(_guestCredentialsKey);
    }

    // Update DioClient with authentication token
    _dioClient.updateAuthToken(token);
  }

  Future<void> _clearStoredAuthData(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_guestCredentialsKey);
    _dioClient.updateAuthToken(null);
  }
}

// Extension to add toJson to User
extension UserToJson on User {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'points': points,
      'last_seen': lastSeen?.toIso8601String(),
      'total_active_time': totalActiveTime,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
