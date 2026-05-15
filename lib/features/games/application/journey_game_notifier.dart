import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/journey_repository.dart';
import '../data/game_score_repository.dart';
import '../domain/models/jesus_journey_event.dart';
import '../domain/models/journey_progress.dart';
import '../../../core/services/xp_service.dart';
import '../../../core/di/app_providers.dart';

// ── State ────────────────────────────────────────────────────────────

enum JourneyPhase {
  loading,
  map,
  viewingEvent,
  quiz,
  quizResult,
  eventComplete,
  journeyComplete,
}

class JourneyGameState {
  final JourneyPhase phase;
  final JourneyProgress progress;
  final JesusJourneyEvent? currentEvent;
  final int currentQuestionIndex; // 0-2
  final int? selectedAnswerIndex;
  final bool? isCorrect;
  final int sessionCorrect; // correct in this event's quiz (0-3)
  final int sessionScore;
  final String? errorMessage;

  const JourneyGameState({
    this.phase = JourneyPhase.loading,
    required this.progress,
    this.currentEvent,
    this.currentQuestionIndex = 0,
    this.selectedAnswerIndex,
    this.isCorrect,
    this.sessionCorrect = 0,
    this.sessionScore = 0,
    this.errorMessage,
  });

  JourneyGameState copyWith({
    JourneyPhase? phase,
    JourneyProgress? progress,
    JesusJourneyEvent? currentEvent,
    int? currentQuestionIndex,
    int? selectedAnswerIndex,
    bool? isCorrect,
    int? sessionCorrect,
    int? sessionScore,
    String? errorMessage,
    bool clearSelection = false,
    bool clearEvent = false,
  }) {
    return JourneyGameState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      currentEvent: clearEvent ? null : (currentEvent ?? this.currentEvent),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswerIndex: clearSelection
          ? null
          : (selectedAnswerIndex ?? this.selectedAnswerIndex),
      isCorrect: clearSelection ? null : (isCorrect ?? this.isCorrect),
      sessionCorrect: sessionCorrect ?? this.sessionCorrect,
      sessionScore: sessionScore ?? this.sessionScore,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────

class JourneyGameNotifier extends StateNotifier<JourneyGameState> {
  final JourneyRepository _repository;
  final Ref _ref;

  JourneyGameNotifier(this._repository, this._ref)
    : super(JourneyGameState(progress: JourneyProgress.initial())) {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    state = state.copyWith(phase: JourneyPhase.loading);
    try {
      final progress = await _repository.getProgress();
      state = state.copyWith(phase: JourneyPhase.map, progress: progress);
    } catch (e) {
      state = state.copyWith(
        phase: JourneyPhase.map,
        errorMessage: 'Failed to load progress',
      );
    }
  }

  /// Open an event for viewing (narrative + key verse)
  void openEvent(int order) {
    if (order > state.progress.currentEvent &&
        !state.progress.completedEvents.containsKey(order)) {
      return; // locked
    }
    final event = _repository.getEvent(order);
    state = state.copyWith(
      phase: JourneyPhase.viewingEvent,
      currentEvent: event,
      currentQuestionIndex: 0,
      sessionCorrect: 0,
      sessionScore: 0,
      clearSelection: true,
    );
  }

  /// Start the quiz for the currently viewed event
  void startQuiz() {
    if (state.currentEvent == null) return;
    state = state.copyWith(
      phase: JourneyPhase.quiz,
      currentQuestionIndex: 0,
      sessionCorrect: 0,
      sessionScore: 0,
      clearSelection: true,
    );
  }

  /// Submit an answer for the current question
  void submitAnswer(int answerIndex) {
    final event = state.currentEvent;
    if (event == null || state.selectedAnswerIndex != null) return;

    final question = event.questions[state.currentQuestionIndex];
    final correct = answerIndex == question.correctIndex;

    int scoreGain = 0;
    if (correct) {
      // Base: 100, bonus for difficulty
      scoreGain = 100 * question.difficulty;
    }

    state = state.copyWith(
      phase: JourneyPhase.quizResult,
      selectedAnswerIndex: answerIndex,
      isCorrect: correct,
      sessionCorrect: state.sessionCorrect + (correct ? 1 : 0),
      sessionScore: state.sessionScore + scoreGain,
    );
  }

  /// Proceed to next question or event completion
  Future<void> nextQuestion() async {
    final event = state.currentEvent;
    if (event == null) return;

    if (state.currentQuestionIndex < event.questions.length - 1) {
      // Next question
      state = state.copyWith(
        phase: JourneyPhase.quiz,
        currentQuestionIndex: state.currentQuestionIndex + 1,
        clearSelection: true,
      );
    } else {
      // All questions done -- complete event
      await _completeCurrentEvent();
    }
  }

  Future<void> _completeCurrentEvent() async {
    final event = state.currentEvent;
    if (event == null) return;

    final result = EventResult(
      eventOrder: event.order,
      correctAnswers: state.sessionCorrect,
      scoreEarned: state.sessionScore,
      completedAt: DateTime.now(),
    );

    await _repository.completeEvent(event.order, result);
    await _ref
        .read(gameScoreRepositoryProvider)
        .submitScore(
          gameId: 'jesus_journey',
          score: state.sessionScore,
          meta: <String, dynamic>{
            'event_order': event.order,
            'event_title': event.title,
            'correct_answers': state.sessionCorrect,
            'question_count': event.questions.length,
          },
        );

    // Award XP
    try {
      final xpService = _ref.read(xpServiceProvider);
      await xpService.addXP(
        type: XPActivityType.verseGame,
        description: 'Completed Journey event: ${event.title}',
        metadata: {
          'eventOrder': event.order,
          'correctAnswers': state.sessionCorrect,
          'score': state.sessionScore,
        },
      );
    } catch (_) {
      // XP service not initialized -- skip
    }

    final updatedProgress = await _repository.getProgress();

    if (updatedProgress.isComplete) {
      state = state.copyWith(
        phase: JourneyPhase.journeyComplete,
        progress: updatedProgress,
      );
    } else {
      state = state.copyWith(
        phase: JourneyPhase.eventComplete,
        progress: updatedProgress,
      );
    }
  }

  /// Return to the journey map
  void backToMap() {
    state = state.copyWith(
      phase: JourneyPhase.map,
      clearEvent: true,
      clearSelection: true,
    );
  }

  /// Reset the entire journey
  Future<void> resetJourney() async {
    await _repository.resetJourney();
    final progress = await _repository.getProgress();
    state = state.copyWith(
      phase: JourneyPhase.map,
      progress: progress,
      clearEvent: true,
      clearSelection: true,
      sessionCorrect: 0,
      sessionScore: 0,
    );
  }

  /// Refresh progress from storage
  Future<void> refresh() async {
    await _loadProgress();
  }
}

// ── Providers ────────────────────────────────────────────────────────

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository();
});

final journeyGameProvider =
    StateNotifierProvider<JourneyGameNotifier, JourneyGameState>((ref) {
      return JourneyGameNotifier(ref.watch(journeyRepositoryProvider), ref);
    });
