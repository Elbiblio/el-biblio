class FaithQuestion {
  final String id;
  final String question;
  final String shortAnswer;
  final String fullAnswer;
  final String parable;
  final List<String> scriptureRefs;
  final String category;
  final int difficulty;
  final List<String> quizOptions;
  final int correctOptionIndex;

  const FaithQuestion({
    required this.id,
    required this.question,
    required this.shortAnswer,
    required this.fullAnswer,
    this.parable = '',
    required this.scriptureRefs,
    required this.category,
    required this.difficulty,
    required this.quizOptions,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'shortAnswer': shortAnswer,
      'fullAnswer': fullAnswer,
      'parable': parable,
      'scriptureRefs': scriptureRefs,
      'category': category,
      'difficulty': difficulty,
      'quizOptions': quizOptions,
      'correctOptionIndex': correctOptionIndex,
    };
  }

  factory FaithQuestion.fromJson(Map<String, dynamic> json) {
    return FaithQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      shortAnswer: (json['shortAnswer'] ?? json['short_answer'] ?? '') as String,
      fullAnswer: (json['fullAnswer'] ?? json['full_answer'] ?? '') as String,
      parable: (json['parable'] ?? '') as String,
      scriptureRefs: (json['scriptureRefs'] ?? json['scripture_refs'] as List? ?? []).cast<String>(),
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      quizOptions: ((json['quizOptions'] ?? json['quiz_options']) as List).cast<String>(),
      correctOptionIndex: (json['correctOptionIndex'] ?? json['correct_option_index']) as int,
    );
  }
}
