class FaithPrompt {
  const FaithPrompt({
    required this.id,
    required this.question,
    required this.context,
    required this.category,
    required this.relatedScripture,
    required this.scriptureReference,
    required this.discussionStarters,
    required this.date,
  });

  final String id;
  final String question;
  final String context;
  final String category;
  final String relatedScripture;
  final String scriptureReference;
  final List<String> discussionStarters;
  final DateTime date;

  FaithPrompt copyWith({
    String? id,
    String? question,
    String? context,
    String? category,
    String? relatedScripture,
    String? scriptureReference,
    List<String>? discussionStarters,
    DateTime? date,
  }) {
    return FaithPrompt(
      id: id ?? this.id,
      question: question ?? this.question,
      context: context ?? this.context,
      category: category ?? this.category,
      relatedScripture: relatedScripture ?? this.relatedScripture,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      discussionStarters: discussionStarters ?? this.discussionStarters,
      date: date ?? this.date,
    );
  }

  factory FaithPrompt.fromJson(Map<String, dynamic> json) {
    return FaithPrompt(
      id: json['id'] as String,
      question: json['question'] as String,
      context: json['context'] as String,
      category: json['category'] as String,
      relatedScripture: json['relatedScripture'] as String,
      scriptureReference: json['scriptureReference'] as String,
      discussionStarters: (json['discussionStarters'] as List<dynamic>).cast<String>(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'context': context,
      'category': category,
      'relatedScripture': relatedScripture,
      'scriptureReference': scriptureReference,
      'discussionStarters': discussionStarters,
      'date': date.toIso8601String(),
    };
  }

  static const List<String> categories = [
    'theology',
    'daily_life',
    'relationships',
    'suffering',
    'purpose',
    'growth',
  ];
}
