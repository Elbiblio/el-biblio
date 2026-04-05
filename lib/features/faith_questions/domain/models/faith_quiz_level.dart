class FaithQuizLevel {
  final int level;
  final String title;
  final String description;
  final int requiredCorrect;
  final List<String> questionIds;
  final int xpReward;

  const FaithQuizLevel({
    required this.level,
    required this.title,
    required this.description,
    required this.requiredCorrect,
    required this.questionIds,
    required this.xpReward,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'title': title,
      'description': description,
      'requiredCorrect': requiredCorrect,
      'questionIds': questionIds,
      'xpReward': xpReward,
    };
  }

  factory FaithQuizLevel.fromJson(Map<String, dynamic> json) {
    return FaithQuizLevel(
      level: json['level'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      requiredCorrect: json['requiredCorrect'] as int,
      questionIds: (json['questionIds'] as List).cast<String>(),
      xpReward: json['xpReward'] as int,
    );
  }
}
