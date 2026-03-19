import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/reading_plan.dart';
import '../data/reading_plan_repository.dart';

class ReadingPlanState {
  const ReadingPlanState({
    this.isLoading = false,
    this.error,
    this.plans = const [],
    this.activePlans = const [],
    this.selectedPlan,
  });

  final bool isLoading;
  final String? error;
  final List<ReadingPlan> plans;
  final List<UserReadingPlan> activePlans;
  final ReadingPlan? selectedPlan;

  ReadingPlanState copyWith({
    bool? isLoading,
    String? error,
    List<ReadingPlan>? plans,
    List<UserReadingPlan>? activePlans,
    ReadingPlan? selectedPlan,
  }) {
    return ReadingPlanState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      plans: plans ?? this.plans,
      activePlans: activePlans ?? this.activePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
    );
  }
}

class ReadingPlanNotifier extends StateNotifier<ReadingPlanState> {
  ReadingPlanNotifier(this._repository) : super(const ReadingPlanState()) {
    // Load plans in background without blocking UI - only if network is available
    Future.microtask(() {
      _loadPlansIfOnline();
    });
  }

  final ReadingPlanRepository _repository;

  Future<void> _loadPlansIfOnline() async {
    try {
      // Try to load plans, but don't fail if offline
      await loadPlans();
      await loadActivePlans();
    } catch (e) {
      // Silently handle network errors - app should work offline
      debugPrint('Background loading failed (likely offline): $e');
    }
  }

  Future<void> loadPlans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _repository.getReadingPlans();
      state = state.copyWith(
        plans: plans,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadActivePlans() async {
    try {
      final activePlans = await _repository.getActivePlans();
      state = state.copyWith(activePlans: activePlans);
    } catch (e) {
      debugPrint('Error loading active plans: $e');
    }
  }

  Future<void> loadPlanDetails(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plan = await _repository.getReadingPlan(id);
      state = state.copyWith(
        selectedPlan: plan,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> startPlan(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.startPlan(id);
      await loadActivePlans();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
