import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alignment_repository.dart';
import '../domain/models/forty_day_goal.dart';

class FortyDayState {
  final FortyDayGoal? activeGoal;
  final bool isLoading;
  final String? error;

  const FortyDayState({
    this.activeGoal,
    this.isLoading = false,
    this.error,
  });

  FortyDayState copyWith({
    FortyDayGoal? activeGoal,
    bool? isLoading,
    String? error,
    bool clearGoal = false,
  }) {
    return FortyDayState(
      activeGoal: clearGoal ? null : (activeGoal ?? this.activeGoal),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasActiveGoal =>
      activeGoal != null && activeGoal!.status == GoalStatus.active;

  int get currentDay => activeGoal?.currentDay ?? 0;
  double get progress => activeGoal?.progress ?? 0.0;
  int get streakDays => activeGoal?.streakDays ?? 0;
}

class FortyDayNotifier extends StateNotifier<FortyDayState> {
  FortyDayNotifier(this._repository) : super(const FortyDayState());

  final AlignmentRepository _repository;

  Future<void> loadGoal() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final goal = await _repository.getActiveGoal();
      state = state.copyWith(activeGoal: goal, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> startGoal(FortyDayGoal template) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final goal = template.copyWith(
      id: '${template.id}_${now.millisecondsSinceEpoch}',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 40)),
      status: GoalStatus.active,
      completions: {},
    );
    await _repository.saveGoal(goal);
    state = state.copyWith(activeGoal: goal);
  }

  Future<void> completeDay({
    required int dayNumber,
    String? reflectionNote,
    int rating = 3,
  }) async {
    if (state.activeGoal == null) return;

    final completion = DayCompletion(
      dayNumber: dayNumber,
      completedAt: DateTime.now(),
      reflectionNote: reflectionNote,
      rating: rating,
    );

    await _repository.completeDay(dayNumber, completion);
    await loadGoal();
  }

  Future<void> abandonGoal() async {
    if (state.activeGoal == null) return;
    final abandoned = state.activeGoal!.copyWith(status: GoalStatus.abandoned);
    await _repository.saveGoal(abandoned);
    state = state.copyWith(activeGoal: abandoned);
  }
}
