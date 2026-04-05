import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/faith_questions_repository.dart';
import '../domain/models/faith_question.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/di/app_providers.dart';
import 'faith_questions_state.dart';

class FaithQuestionsNotifier extends StateNotifier<FaithQuestionsState> {
  final FaithQuestionsRepository _repository;
  final Ref _ref;

  FaithQuestionsNotifier(this._repository, this._ref)
      : super(const FaithQuestionsState()) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    state = state.copyWith(isLoading: true);
    try {
      final progress = await _repository.getProgress();
      state = state.copyWith(
        progress: progress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load progress',
      );
    }
  }

  // ── FAQ Mode ────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  List<FaithQuestion> getFilteredQuestions() {
    List<FaithQuestion> questions = _repository.getAllQuestions();

    if (state.searchQuery.isNotEmpty) {
      questions = _repository.searchQuestions(state.searchQuery);
    }

    if (state.selectedCategory != null) {
      questions =
          questions.where((q) => q.category == state.selectedCategory).toList();
    }

    return questions;
  }

  // ── Quiz Mode ───────────────────────────────────────────────────────

  void startQuizLevel(int level) {
    if (!state.progress.isLevelUnlocked(level)) return;

    final questions = _repository.getQuestionsForLevel(level);
    state = state.copyWith(
      mode: FaithQuestionsMode.activeQuiz,
      activeQuizLevel: level,
      quizQuestions: questions,
      currentQuestionIndex: 0,
      quizAnswers: {},
      sessionCorrect: 0,
      showingResult: false,
      clearSelection: true,
    );
  }

  void submitAnswer(int optionIndex) {
    if (state.selectedAnswerIndex != null) return;
    if (state.currentQuestionIndex >= state.quizQuestions.length) return;

    final question = state.quizQuestions[state.currentQuestionIndex];
    final correct = optionIndex == question.correctOptionIndex;

    final newAnswers = Map<int, int>.from(state.quizAnswers);
    newAnswers[state.currentQuestionIndex] = optionIndex;

    state = state.copyWith(
      selectedAnswerIndex: optionIndex,
      lastAnswerCorrect: correct,
      quizAnswers: newAnswers,
      sessionCorrect: state.sessionCorrect + (correct ? 1 : 0),
      showingResult: true,
    );
  }

  Future<void> nextQuestion() async {
    if (state.currentQuestionIndex < state.quizQuestions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        showingResult: false,
        clearSelection: true,
      );
    } else {
      // Quiz complete
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    final level = state.activeQuizLevel;
    if (level == null) return;

    final quizLevel = _repository.getLevel(level);
    final passed = state.sessionCorrect >= quizLevel.requiredCorrect;
    final xpEarned = passed ? quizLevel.xpReward : (quizLevel.xpReward ~/ 3);

    await _repository.completeLevel(
      level: level,
      correctAnswers: state.sessionCorrect,
      totalQuestions: state.quizQuestions.length,
      xpEarned: xpEarned,
      passed: passed,
    );

    // Award XP
    try {
      final xpService = _ref.read(xpServiceProvider);
      await xpService.addXP(
        type: XPActivityType.verseGame,
        description: 'Faith Quiz Level $level: ${passed ? "Passed" : "Attempted"}',
        metadata: {
          'level': level,
          'correct': state.sessionCorrect,
          'total': state.quizQuestions.length,
          'passed': passed,
        },
      );
    } catch (_) {
      // XP service not initialized -- skip
    }

    final updatedProgress = await _repository.getProgress();

    state = state.copyWith(
      mode: FaithQuestionsMode.quizResult,
      progress: updatedProgress,
    );
  }

  void backToHub() {
    state = state.copyWith(
      mode: FaithQuestionsMode.hub,
      clearQuiz: true,
      clearSelection: true,
      showingResult: false,
    );
  }

  void retryLevel() {
    final level = state.activeQuizLevel;
    if (level == null) return;
    startQuizLevel(level);
  }

  Future<void> refresh() async {
    await _loadProgress();
  }

  Future<void> resetProgress() async {
    await _repository.resetProgress();
    await _loadProgress();
  }
}

// ── Providers ──────────────────────────────────────────────────────────

final faithQuestionsRepositoryProvider =
    Provider<FaithQuestionsRepository>((ref) {
  return FaithQuestionsRepository();
});

final faithQuestionsProvider =
    StateNotifierProvider<FaithQuestionsNotifier, FaithQuestionsState>((ref) {
  return FaithQuestionsNotifier(
    ref.watch(faithQuestionsRepositoryProvider),
    ref,
  );
});
