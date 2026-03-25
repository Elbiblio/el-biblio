import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alignment_repository.dart';
import '../domain/models/habit_assessment.dart';

class HabitState {
  final List<HabitItem> habits;
  final HabitCategory? selectedCategory;
  final bool isLoading;
  final String? error;

  const HabitState({
    this.habits = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
  });

  HabitState copyWith({
    List<HabitItem>? habits,
    HabitCategory? selectedCategory,
    bool? isLoading,
    String? error,
    bool clearCategory = false,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<HabitItem> get activeHabits => habits.where((h) => h.isActive).toList();

  List<HabitItem> get filteredHabits {
    final active = activeHabits;
    if (selectedCategory == null) return active;
    return active.where((h) => h.category == selectedCategory).toList();
  }

  List<HabitItem> get activeBadHabits =>
      activeHabits.where((h) => h.isBadHabit).toList();

  List<HabitItem> get activeGoodHabits =>
      activeHabits.where((h) => !h.isBadHabit).toList();

  int get longestStreak {
    if (activeHabits.isEmpty) return 0;
    return activeHabits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
  }

  int get totalActiveDays {
    return activeHabits.fold(0, (sum, h) => sum + h.currentStreak);
  }

  double get consistencyPercent {
    if (activeHabits.isEmpty) return 0.0;
    final total = activeHabits.length;
    final checkedInToday = activeHabits.where((h) {
      if (h.lastCheckIn == null) return false;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final checkDay = DateTime(
        h.lastCheckIn!.year,
        h.lastCheckIn!.month,
        h.lastCheckIn!.day,
      );
      return checkDay == today;
    }).length;
    return checkedInToday / total;
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  HabitNotifier(this._repository) : super(const HabitState());

  final AlignmentRepository _repository;

  Future<void> loadHabits() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final habits = await _repository.getHabits();
      state = state.copyWith(habits: habits, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setCategory(HabitCategory? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  Future<void> addHabit(HabitItem habit) async {
    final activated = habit.copyWith(isActive: true);
    await _repository.saveHabit(activated);
    await loadHabits();
  }

  Future<void> addHabits(List<HabitItem> habits) async {
    final existing = await _repository.getHabits();
    final existingIds = existing.map((h) => h.id).toSet();
    final newHabits = habits
        .where((h) => !existingIds.contains(h.id))
        .map((h) => h.copyWith(isActive: true))
        .toList();
    await _repository.saveAllHabits([...existing, ...newHabits]);
    await loadHabits();
  }

  Future<void> toggleHabit(String id) async {
    final habits = List<HabitItem>.from(state.habits);
    final index = habits.indexWhere((h) => h.id == id);
    if (index < 0) return;
    habits[index] = habits[index].copyWith(isActive: !habits[index].isActive);
    await _repository.saveAllHabits(habits);
    state = state.copyWith(habits: habits);
  }

  Future<void> checkInHabit(String id) async {
    await _repository.updateHabitStreak(id);
    await loadHabits();
  }

  Future<void> removeHabit(String id) async {
    final habits = state.habits.where((h) => h.id != id).toList();
    await _repository.saveAllHabits(habits);
    state = state.copyWith(habits: habits);
  }
}
