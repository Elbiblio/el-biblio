import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/di/app_providers.dart';
import '../data/church_repository.dart';
import '../domain/models/church.dart';

class ChurchFinderState {
  const ChurchFinderState({
    this.loading = false,
    this.permissionDenied = false,
    this.serviceDisabled = false,
    this.lat,
    this.lng,
    this.churches = const [],
    this.error,
  });

  final bool loading;
  final bool permissionDenied;
  final bool serviceDisabled;
  final double? lat;
  final double? lng;
  final List<Church> churches;
  final String? error;

  ChurchFinderState copyWith({
    bool? loading,
    bool? permissionDenied,
    bool? serviceDisabled,
    double? lat,
    double? lng,
    List<Church>? churches,
    String? error,
    bool clearError = false,
  }) {
    return ChurchFinderState(
      loading: loading ?? this.loading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      serviceDisabled: serviceDisabled ?? this.serviceDisabled,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      churches: churches ?? this.churches,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChurchFinderNotifier extends StateNotifier<ChurchFinderState> {
  ChurchFinderNotifier(this._repository) : super(const ChurchFinderState());

  final ChurchRepository _repository;

  Future<void> loadNearby({double radiusKm = 10, String? denomination}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(loading: false, serviceDisabled: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(loading: false, permissionDenied: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final churches = await _repository.findNearby(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: radiusKm,
        denomination: denomination,
      );

      state = ChurchFinderState(
        loading: false,
        lat: position.latitude,
        lng: position.longitude,
        churches: churches,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Could not find churches nearby. Try again in a moment.',
      );
    }
  }
}

final churchRepositoryProvider = Provider<ChurchRepository>((ref) {
  return ChurchRepository(
    ref.watch(authenticatedDioClientProvider),
    ref.watch(loggerProvider),
  );
});

final churchFinderProvider =
    StateNotifierProvider<ChurchFinderNotifier, ChurchFinderState>((ref) {
  return ChurchFinderNotifier(ref.watch(churchRepositoryProvider));
});
