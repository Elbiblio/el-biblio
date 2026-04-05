import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/faith_question.dart';
import '../domain/models/faith_quiz_level.dart';
import '../domain/models/faith_quiz_progress.dart';
import 'faith_question_catalog.dart';
import 'faith_quiz_level_catalog.dart';

class FaithQuestionsRepository {
  static const String _boxName = 'faith_quiz_progress';
  static const String _progressKey = 'current_progress';

  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  // ── Questions ───────────────────────────────────────────────────────

  List<FaithQuestion> getAllQuestions() {
    return FaithQuestionCatalog.allQuestions;
  }

  FaithQuestion getQuestionById(String id) {
    return FaithQuestionCatalog.getById(id);
  }

  List<FaithQuestion> getQuestionsByCategory(String category) {
    return FaithQuestionCatalog.getByCategory(category);
  }

  List<FaithQuestion> searchQuestions(String query) {
    final lower = query.toLowerCase();
    return FaithQuestionCatalog.allQuestions.where((q) {
      return q.question.toLowerCase().contains(lower) ||
          q.shortAnswer.toLowerCase().contains(lower) ||
          q.category.toLowerCase().contains(lower) ||
          q.scriptureRefs.any((r) => r.toLowerCase().contains(lower));
    }).toList();
  }

  // ── Levels ──────────────────────────────────────────────────────────

  List<FaithQuizLevel> getAllLevels() {
    return FaithQuizLevelCatalog.allLevels;
  }

  FaithQuizLevel getLevel(int level) {
    return FaithQuizLevelCatalog.getLevel(level);
  }

  List<FaithQuestion> getQuestionsForLevel(int level) {
    final quizLevel = FaithQuizLevelCatalog.getLevel(level);
    return quizLevel.questionIds
        .map((id) => FaithQuestionCatalog.getById(id))
        .toList();
  }

  // ── Progress ────────────────────────────────────────────────────────

  Future<FaithQuizProgress> getProgress() async {
    final box = await _getBox();
    final raw = box.get(_progressKey);
    if (raw == null) return FaithQuizProgress.initial();
    try {
      final map = Map<String, dynamic>.from(
        raw is String ? json.decode(raw) as Map : raw as Map,
      );
      return FaithQuizProgress.fromJson(map);
    } catch (_) {
      return FaithQuizProgress.initial();
    }
  }

  Future<void> saveProgress(FaithQuizProgress progress) async {
    final box = await _getBox();
    await box.put(_progressKey, json.encode(progress.toJson()));
  }

  Future<void> completeLevel({
    required int level,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
    required bool passed,
  }) async {
    final progress = await getProgress();

    final newCompleted = Set<int>.from(progress.completedLevels);
    if (passed) {
      newCompleted.add(level);
    }

    final nextLevel = passed && level < 10 ? level + 1 : progress.currentLevel;

    final updated = progress.copyWith(
      completedLevels: newCompleted,
      currentLevel: nextLevel > progress.currentLevel ? nextLevel : progress.currentLevel,
      totalXpEarned: progress.totalXpEarned + xpEarned,
      totalQuestionsAnswered: progress.totalQuestionsAnswered + totalQuestions,
      totalCorrect: progress.totalCorrect + correctAnswers,
    );

    await saveProgress(updated);
  }

  Future<void> resetProgress() async {
    await saveProgress(FaithQuizProgress.initial());
  }
}
