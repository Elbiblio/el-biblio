class EvangelismContent {
  const EvangelismContent({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.type,
    this.relatedVerse,
    this.relatedVerseReference,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category; // encouragement, hope, love, faith, wisdom
  final String type; // verse_card, testimony_template, conversation_starter, guide, prayer_card
  final String? relatedVerse;
  final String? relatedVerseReference;
  final DateTime createdAt;

  EvangelismContent copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? type,
    String? relatedVerse,
    String? relatedVerseReference,
    DateTime? createdAt,
  }) {
    return EvangelismContent(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      type: type ?? this.type,
      relatedVerse: relatedVerse ?? this.relatedVerse,
      relatedVerseReference: relatedVerseReference ?? this.relatedVerseReference,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory EvangelismContent.fromJson(Map<String, dynamic> json) {
    return EvangelismContent(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      relatedVerse: json['relatedVerse'] as String?,
      relatedVerseReference: json['relatedVerseReference'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'type': type,
      'relatedVerse': relatedVerse,
      'relatedVerseReference': relatedVerseReference,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static const List<String> categories = [
    'encouragement',
    'hope',
    'love',
    'faith',
    'wisdom',
  ];

  static const List<String> types = [
    'verse_card',
    'testimony_template',
    'conversation_starter',
    'guide',
    'prayer_card',
  ];
}
