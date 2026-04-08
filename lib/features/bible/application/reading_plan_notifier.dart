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

  /// Default offline reading plans so the section is never empty.
  static final List<ReadingPlan> _defaultPlans = [
    ReadingPlan(
      id: -1,
      title: 'Psalms in 30 Days',
      description: 'Journey through the Psalms — 5 psalms per day for a month of worship, lament, and praise.',
      durationDays: 30,
      isFeatured: true,
    ),
    ReadingPlan(
      id: -2,
      title: 'The Gospel of John',
      description: 'One chapter a day through the most intimate account of Jesus\' life and teaching.',
      durationDays: 21,
      isFeatured: true,
    ),
    ReadingPlan(
      id: -3,
      title: 'Proverbs: Wisdom for Daily Life',
      description: 'One chapter a day — practical wisdom for decisions, relationships, and integrity.',
      durationDays: 31,
    ),
    ReadingPlan(
      id: -4,
      title: 'The Sermon on the Mount',
      description: 'A deep 14-day study of Matthew 5-7 — the heart of Jesus\' teaching on kingdom living.',
      durationDays: 14,
    ),
    ReadingPlan(
      id: -5,
      title: 'Romans: Faith Foundations',
      description: 'Paul\'s letter to the Romans — the clearest explanation of grace, faith, and salvation.',
      durationDays: 16,
    ),
  ];

  Future<void> _loadPlansIfOnline() async {
    try {
      // Try to load plans, but don't fail if offline
      await loadPlans();
      await loadActivePlans();
    } catch (e) {
      // Silently handle network errors - fall back to defaults
      debugPrint('Background loading failed (likely offline): $e');
      if (state.plans.isEmpty) {
        state = state.copyWith(plans: _defaultPlans);
      }
    }
  }

  Future<void> loadPlans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _repository.getReadingPlans();
      state = state.copyWith(
        plans: plans.isEmpty ? _defaultPlans : plans,
        isLoading: false,
      );
    } catch (e) {
      // On error, use defaults if we have no plans yet
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        plans: state.plans.isEmpty ? _defaultPlans : null,
      );
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
