import '../domain/models/faith_question.dart';
import '../domain/models/faith_quiz_progress.dart';

enum FaithQuestionsMode { hub, faq, quizLevels, activeQuiz, quizResult }

class FaithQuestionsState {
  final FaithQuestionsMode mode;
  final String searchQuery;
  final String? selectedCategory;
  final FaithQuizProgress progress;

  // Active quiz state
  final int? activeQuizLevel;
  final List<FaithQuestion> quizQuestions;
  final int currentQuestionIndex;
  final Map<int, int> quizAnswers; // questionIndex -> selectedOptionIndex
  final int? selectedAnswerIndex;
  final bool? lastAnswerCorrect;
  final int sessionCorrect;
  final bool showingResult;

  // Loading / error
  final bool isLoading;
  final String? errorMessage;

  const FaithQuestionsState({
    this.mode = FaithQuestionsMode.hub,
    this.searchQuery = '',
    this.selectedCategory,
    this.progress = const FaithQuizProgress(),
    this.activeQuizLevel,
    this.quizQuestions = const [],
    this.currentQuestionIndex = 0,
    this.quizAnswers = const {},
    this.selectedAnswerIndex,
    this.lastAnswerCorrect,
    this.sessionCorrect = 0,
    this.showingResult = false,
    this.isLoading = false,
    this.errorMessage,
  });

  FaithQuestionsState copyWith({
    FaithQuestionsMode? mode,
    String? searchQuery,
    String? selectedCategory,
    FaithQuizProgress? progress,
    int? activeQuizLevel,
    List<FaithQuestion>? quizQuestions,
    int? currentQuestionIndex,
    Map<int, int>? quizAnswers,
    int? selectedAnswerIndex,
    bool? lastAnswerCorrect,
    int? sessionCorrect,
    bool? showingResult,
    bool? isLoading,
    String? errorMessage,
    bool clearCategory = false,
    bool clearSelection = false,
    bool clearQuiz = false,
  }) {
    return FaithQuestionsState(
      mode: mode ?? this.mode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      progress: progress ?? this.progress,
      activeQuizLevel:
          clearQuiz ? null : (activeQuizLevel ?? this.activeQuizLevel),
      quizQuestions:
          clearQuiz ? const [] : (quizQuestions ?? this.quizQuestions),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      quizAnswers: clearQuiz ? const {} : (quizAnswers ?? this.quizAnswers),
      selectedAnswerIndex: clearSelection
          ? null
          : (selectedAnswerIndex ?? this.selectedAnswerIndex),
      lastAnswerCorrect: clearSelection
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      sessionCorrect: sessionCorrect ?? this.sessionCorrect,
      showingResult: showingResult ?? this.showingResult,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
