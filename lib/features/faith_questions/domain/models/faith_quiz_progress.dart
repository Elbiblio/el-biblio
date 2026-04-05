class FaithQuizProgress {
  final Set<int> completedLevels;
  final int currentLevel;
  final int totalXpEarned;
  final int totalQuestionsAnswered;
  final int totalCorrect;

  const FaithQuizProgress({
    this.completedLevels = const {},
    this.currentLevel = 1,
    this.totalXpEarned = 0,
    this.totalQuestionsAnswered = 0,
    this.totalCorrect = 0,
  });

  double get accuracy =>
      totalQuestionsAnswered > 0 ? totalCorrect / totalQuestionsAnswered : 0.0;

  bool isLevelUnlocked(int level) {
    if (level == 1) return true;
    return completedLevels.contains(level - 1);
  }

  FaithQuizProgress copyWith({
    Set<int>? completedLevels,
    int? currentLevel,
    int? totalXpEarned,
    int? totalQuestionsAnswered,
    int? totalCorrect,
  }) {
    return FaithQuizProgress(
      completedLevels: completedLevels ?? this.completedLevels,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      totalQuestionsAnswered:
          totalQuestionsAnswered ?? this.totalQuestionsAnswered,
      totalCorrect: totalCorrect ?? this.totalCorrect,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedLevels': completedLevels.toList(),
      'currentLevel': currentLevel,
      'totalXpEarned': totalXpEarned,
      'totalQuestionsAnswered': totalQuestionsAnswered,
      'totalCorrect': totalCorrect,
    };
  }

  factory FaithQuizProgress.fromJson(Map<String, dynamic> json) {
    return FaithQuizProgress(
      completedLevels: (json['completedLevels'] as List?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      currentLevel: json['currentLevel'] as int? ?? 1,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      totalQuestionsAnswered: json['totalQuestionsAnswered'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
    );
  }

  factory FaithQuizProgress.initial() {
    return const FaithQuizProgress();
  }
}
