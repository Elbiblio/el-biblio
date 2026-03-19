import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/profile_repository.dart';
import '../domain/models/user_profile.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.stats,
  });

  final bool isLoading;
  final String? error;
  final UserProfile? profile;
  final UserStats? stats;

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfile? profile,
    UserStats? stats,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> loadProfile(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getUserProfile(userId);
      final stats = await _repository.getUserStats(userId);
      
      state = state.copyWith(
        profile: profile,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString(),
      );
    }
  }

  Future<void> loadProfileForUser(String userId) async {
    return loadProfile(int.tryParse(userId) ?? 1);
  }

  Future<void> loadCurrentUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getCurrentUserProfile();
      final stats = await _repository.getCurrentUserStats();
      
      state = state.copyWith(
        profile: profile,
        stats: stats,
        isLoading: false,
      );
    } on GuestUserException {
      // Guest user - this is expected behavior, use offline data
      final profile = UserProfile.createGuestProfile();
      final stats = UserStats.createGuestStats();
      
      state = state.copyWith(
        profile: profile,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString(),
      );
    }
  }
}
