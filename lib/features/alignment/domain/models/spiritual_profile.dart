class SpiritualProfile {
  final String archetypeId;
  final String archetypeName;
  final String description;
  final Map<String, double> dimensions;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> growthAreas;
  final DateTime assessedAt;
  final List<SpiritualProfile>? previousProfiles;

  const SpiritualProfile({
    required this.archetypeId,
    required this.archetypeName,
    required this.description,
    required this.dimensions,
    required this.strengths,
    required this.weaknesses,
    required this.growthAreas,
    required this.assessedAt,
    this.previousProfiles,
  });

  SpiritualProfile copyWith({
    String? archetypeId,
    String? archetypeName,
    String? description,
    Map<String, double>? dimensions,
    List<String>? strengths,
    List<String>? weaknesses,
    List<String>? growthAreas,
    DateTime? assessedAt,
    List<SpiritualProfile>? previousProfiles,
  }) {
    return SpiritualProfile(
      archetypeId: archetypeId ?? this.archetypeId,
      archetypeName: archetypeName ?? this.archetypeName,
      description: description ?? this.description,
      dimensions: dimensions ?? this.dimensions,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      growthAreas: growthAreas ?? this.growthAreas,
      assessedAt: assessedAt ?? this.assessedAt,
      previousProfiles: previousProfiles ?? this.previousProfiles,
    );
  }

  factory SpiritualProfile.fromJson(Map<String, dynamic> json) {
    return SpiritualProfile(
      archetypeId: json['archetypeId'] as String,
      archetypeName: json['archetypeName'] as String,
      description: json['description'] as String,
      dimensions: (json['dimensions'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      strengths: List<String>.from(json['strengths'] as List),
      weaknesses: List<String>.from(json['weaknesses'] as List),
      growthAreas: List<String>.from(json['growthAreas'] as List),
      assessedAt: DateTime.parse(json['assessedAt'] as String),
      previousProfiles: json['previousProfiles'] != null
          ? (json['previousProfiles'] as List)
              .map((e) => SpiritualProfile.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'archetypeId': archetypeId,
      'archetypeName': archetypeName,
      'description': description,
      'dimensions': dimensions,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'growthAreas': growthAreas,
      'assessedAt': assessedAt.toIso8601String(),
      if (previousProfiles != null)
        'previousProfiles': previousProfiles!.map((e) => e.toJson()).toList(),
    };
  }

  /// Calculate the average dimension change compared to a previous profile.
  double growthSince(SpiritualProfile previous) {
    if (dimensions.isEmpty || previous.dimensions.isEmpty) return 0.0;
    double totalDelta = 0.0;
    int count = 0;
    for (final key in dimensions.keys) {
      final prev = previous.dimensions[key];
      if (prev != null) {
        totalDelta += dimensions[key]! - prev;
        count++;
      }
    }
    return count > 0 ? totalDelta / count : 0.0;
  }
}
