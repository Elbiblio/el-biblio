class QuickPrayer {
  const QuickPrayer({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.relatedVerse,
    required this.relatedVerseReference,
    required this.estimatedSeconds,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String relatedVerse;
  final String relatedVerseReference;
  final int estimatedSeconds;
  final bool isFavorite;

  QuickPrayer copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? relatedVerse,
    String? relatedVerseReference,
    int? estimatedSeconds,
    bool? isFavorite,
  }) {
    return QuickPrayer(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      relatedVerse: relatedVerse ?? this.relatedVerse,
      relatedVerseReference: relatedVerseReference ?? this.relatedVerseReference,
      estimatedSeconds: estimatedSeconds ?? this.estimatedSeconds,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory QuickPrayer.fromJson(Map<String, dynamic> json) {
    return QuickPrayer(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      relatedVerse: json['relatedVerse'] as String,
      relatedVerseReference: json['relatedVerseReference'] as String,
      estimatedSeconds: json['estimatedSeconds'] as int,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'relatedVerse': relatedVerse,
      'relatedVerseReference': relatedVerseReference,
      'estimatedSeconds': estimatedSeconds,
      'isFavorite': isFavorite,
    };
  }

  static const List<String> categories = [
    'anxiety',
    'gratitude',
    'healing',
    'strength',
    'forgiveness',
    'guidance',
    'protection',
    'peace',
  ];
}
