class VerseMoment {
  const VerseMoment({
    required this.verseText,
    required this.reference,
    this.bookContext,
    this.explanation,
    required this.generatedAt,
    this.isBookmarked = false,
  });

  final String verseText;
  final String reference;
  final String? bookContext;
  final String? explanation;
  final DateTime generatedAt;
  final bool isBookmarked;

  VerseMoment copyWith({
    String? verseText,
    String? reference,
    String? bookContext,
    String? explanation,
    DateTime? generatedAt,
    bool? isBookmarked,
  }) {
    return VerseMoment(
      verseText: verseText ?? this.verseText,
      reference: reference ?? this.reference,
      bookContext: bookContext ?? this.bookContext,
      explanation: explanation ?? this.explanation,
      generatedAt: generatedAt ?? this.generatedAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  factory VerseMoment.fromJson(Map<String, dynamic> json) {
    return VerseMoment(
      verseText: json['verseText'] as String,
      reference: json['reference'] as String,
      bookContext: json['bookContext'] as String?,
      explanation: json['explanation'] as String?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verseText': verseText,
      'reference': reference,
      'bookContext': bookContext,
      'explanation': explanation,
      'generatedAt': generatedAt.toIso8601String(),
      'isBookmarked': isBookmarked,
    };
  }
}
