class JourneyProgress {
  final int currentEvent;
  final Map<int, EventResult> completedEvents;
  final int totalScore;
  final int totalXpEarned;
  final int perfectAnswers;
  final DateTime startedAt;
  final DateTime? completedAt;

  const JourneyProgress({
    this.currentEvent = 0,
    this.completedEvents = const {},
    this.totalScore = 0,
    this.totalXpEarned = 0,
    this.perfectAnswers = 0,
    required this.startedAt,
    this.completedAt,
  });

  double get overallProgress => completedEvents.length / 30.0;
  bool get isComplete => completedEvents.length >= 30;

  JourneyProgress copyWith({
    int? currentEvent,
    Map<int, EventResult>? completedEvents,
    int? totalScore,
    int? totalXpEarned,
    int? perfectAnswers,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return JourneyProgress(
      currentEvent: currentEvent ?? this.currentEvent,
      completedEvents: completedEvents ?? this.completedEvents,
      totalScore: totalScore ?? this.totalScore,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      perfectAnswers: perfectAnswers ?? this.perfectAnswers,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentEvent': currentEvent,
      'completedEvents': completedEvents.map(
        (k, v) => MapEntry(k.toString(), v.toJson()),
      ),
      'totalScore': totalScore,
      'totalXpEarned': totalXpEarned,
      'perfectAnswers': perfectAnswers,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    final completedMap = <int, EventResult>{};
    final rawCompleted = json['completedEvents'] as Map<String, dynamic>?;
    if (rawCompleted != null) {
      for (final entry in rawCompleted.entries) {
        final key = int.tryParse(entry.key);
        if (key != null && entry.value is Map) {
          completedMap[key] =
              EventResult.fromJson(Map<String, dynamic>.from(entry.value as Map));
        }
      }
    }
    return JourneyProgress(
      currentEvent: json['currentEvent'] as int? ?? 0,
      completedEvents: completedMap,
      totalScore: json['totalScore'] as int? ?? 0,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      perfectAnswers: json['perfectAnswers'] as int? ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  factory JourneyProgress.initial() {
    return JourneyProgress(startedAt: DateTime.now());
  }
}

class EventResult {
  final int eventOrder;
  final int correctAnswers;
  final int scoreEarned;
  final DateTime completedAt;

  const EventResult({
    required this.eventOrder,
    required this.correctAnswers,
    required this.scoreEarned,
    required this.completedAt,
  });

  bool get isPerfect => correctAnswers == 3;

  Map<String, dynamic> toJson() {
    return {
      'eventOrder': eventOrder,
      'correctAnswers': correctAnswers,
      'scoreEarned': scoreEarned,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory EventResult.fromJson(Map<String, dynamic> json) {
    return EventResult(
      eventOrder: json['eventOrder'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      scoreEarned: json['scoreEarned'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }
}
