import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../domain/models/spiritual_profile.dart';
import '../domain/models/habit_assessment.dart';
import '../domain/models/forty_day_goal.dart';
import '../domain/models/career_alignment.dart';
import 'career_catalog.dart';

class AlignmentRepository {
  AlignmentRepository(this._logger);

  final Logger _logger;

  static const _boxName = 'alignment';
  static const _profileKey = 'spiritual_profile';
  static const _previousProfilesKey = 'previous_profiles';
  static const _habitsKey = 'habits';
  static const _goalKey = 'forty_day_goal';

  Future<Box<dynamic>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  // ── Spiritual Profile ─────────────────────────────────────────────────

  Future<SpiritualProfile?> getSpiritualProfile() async {
    try {
      final box = await _getBox();
      final raw = box.get(_profileKey);
      if (raw == null) return null;
      final map = Map<String, dynamic>.from(
        raw is String ? jsonDecode(raw) as Map : raw as Map,
      );
      return SpiritualProfile.fromJson(map);
    } catch (e, s) {
      _logger.e('Failed to get spiritual profile', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> saveSpiritualProfile(SpiritualProfile profile) async {
    try {
      final box = await _getBox();
      // Save current profile as previous before overwriting
      final current = await getSpiritualProfile();
      if (current != null) {
        final previousList = await getPreviousProfiles();
        previousList.insert(0, current);
        // Keep only the last 10 profiles
        final trimmed = previousList.take(10).toList();
        await box.put(
          _previousProfilesKey,
          jsonEncode(trimmed.map((p) => p.toJson()).toList()),
        );
      }
      await box.put(_profileKey, jsonEncode(profile.toJson()));
    } catch (e, s) {
      _logger.e('Failed to save spiritual profile', error: e, stackTrace: s);
    }
  }

  Future<List<SpiritualProfile>> getPreviousProfiles() async {
    try {
      final box = await _getBox();
      final raw = box.get(_previousProfilesKey);
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((e) => SpiritualProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, s) {
      _logger.e('Failed to get previous profiles', error: e, stackTrace: s);
      return [];
    }
  }

  // ── Habits ────────────────────────────────────────────────────────────

  Future<List<HabitItem>> getHabits() async {
    try {
      final box = await _getBox();
      final raw = box.get(_habitsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw as String) as List;
      return list
          .map((e) => HabitItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, s) {
      _logger.e('Failed to get habits', error: e, stackTrace: s);
      return [];
    }
  }

  Future<void> saveHabit(HabitItem habit) async {
    try {
      final habits = await getHabits();
      final index = habits.indexWhere((h) => h.id == habit.id);
      if (index >= 0) {
        habits[index] = habit;
      } else {
        habits.add(habit);
      }
      await _saveAllHabits(habits);
    } catch (e, s) {
      _logger.e('Failed to save habit', error: e, stackTrace: s);
    }
  }

  Future<void> saveAllHabits(List<HabitItem> habits) async {
    await _saveAllHabits(habits);
  }

  Future<void> _saveAllHabits(List<HabitItem> habits) async {
    try {
      final box = await _getBox();
      await box.put(
        _habitsKey,
        jsonEncode(habits.map((h) => h.toJson()).toList()),
      );
    } catch (e, s) {
      _logger.e('Failed to save habits', error: e, stackTrace: s);
    }
  }

  Future<void> updateHabitStreak(String id) async {
    try {
      final habits = await getHabits();
      final index = habits.indexWhere((h) => h.id == id);
      if (index < 0) return;

      final habit = habits[index];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCheck = habit.lastCheckIn;
      final lastDay = lastCheck != null
          ? DateTime(lastCheck.year, lastCheck.month, lastCheck.day)
          : null;

      int newStreak;
      if (lastDay == null) {
        newStreak = 1;
      } else if (lastDay == today) {
        newStreak = habit.currentStreak; // Already checked in today
      } else if (today.difference(lastDay).inDays == 1) {
        newStreak = habit.currentStreak + 1;
      } else {
        newStreak = 1; // Streak broken
      }

      habits[index] = habit.copyWith(
        currentStreak: newStreak,
        lastCheckIn: now,
      );
      await _saveAllHabits(habits);
    } catch (e, s) {
      _logger.e('Failed to update habit streak', error: e, stackTrace: s);
    }
  }

  // ── 40-Day Goal ───────────────────────────────────────────────────────

  Future<FortyDayGoal?> getActiveGoal() async {
    try {
      final box = await _getBox();
      final raw = box.get(_goalKey);
      if (raw == null) return null;
      final map = Map<String, dynamic>.from(
        raw is String ? jsonDecode(raw) as Map : raw as Map,
      );
      return FortyDayGoal.fromJson(map);
    } catch (e, s) {
      _logger.e('Failed to get active goal', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> saveGoal(FortyDayGoal goal) async {
    try {
      final box = await _getBox();
      await box.put(_goalKey, jsonEncode(goal.toJson()));
    } catch (e, s) {
      _logger.e('Failed to save goal', error: e, stackTrace: s);
    }
  }

  Future<void> completeDay(int dayNumber, DayCompletion completion) async {
    try {
      final goal = await getActiveGoal();
      if (goal == null) return;

      final completions = Map<int, DayCompletion>.from(goal.completions);
      completions[dayNumber] = completion;

      final updatedGoal = goal.copyWith(
        completions: completions,
        status: completions.length >= 40 ? GoalStatus.completed : GoalStatus.active,
      );
      await saveGoal(updatedGoal);
    } catch (e, s) {
      _logger.e('Failed to complete day', error: e, stackTrace: s);
    }
  }

  // ── Career Alignment ──────────────────────────────────────────────────

  CareerAlignment? getCareerAlignment(String archetypeId) {
    return CareerCatalog.forArchetype(archetypeId);
  }
}
