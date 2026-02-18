import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/models/activity.dart';
import '../data/bible_reading_repository.dart';

class BibleReadingState {
  const BibleReadingState({
    this.isLoading = false,
    this.error,
    this.history = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReadingDate,
    this.totalDays = 0,
  });

  final bool isLoading;
  final String? error;
  final List<Activity> history;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadingDate;
  final int totalDays;

  BibleReadingState copyWith({
    bool? isLoading,
    String? error,
    List<Activity>? history,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadingDate,
    int? totalDays,
  }) {
    return BibleReadingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      history: history ?? this.history,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
      totalDays: totalDays ?? this.totalDays,
    );
  }
}

class BibleReadingNotifier extends StateNotifier<BibleReadingState> {
  BibleReadingNotifier(this._repository) : super(const BibleReadingState()) {
    loadStreak();
  }

  final BibleReadingRepository _repository;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repository.getHistory();
      state = state.copyWith(
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadStreak() async {
    // Don't set loading for streak as it might be background
    try {
      final data = await _repository.getStreak();
      state = state.copyWith(
        currentStreak: data['current_streak'] as int? ?? 0,
        longestStreak: data['longest_streak'] as int? ?? 0,
        totalDays: data['total_days'] as int? ?? 0,
        lastReadingDate: data['last_reading_date'] != null 
            ? DateTime.parse(data['last_reading_date']) 
            : null,
      );
    } catch (e) {
      // Silent error for streak
      print('Error loading streak: $e');
    }
  }

  Future<bool> completeReading({
    required String readingMode,
    String? planName,
    int? durationMinutes,
    List<String>? chaptersRead,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.completeDailyReading(
        readingMode: readingMode,
        planName: planName,
        durationMinutes: durationMinutes,
        chaptersRead: chaptersRead,
        notes: notes,
      );
      
      // Reload streak and history
      await loadStreak();
      if (state.history.isNotEmpty) {
        await loadHistory();
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
