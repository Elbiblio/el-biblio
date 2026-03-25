import 'dart:ui';

/// Represents a single commitment in the 40-level graduated system.
class GraduatedCommitment {
  const GraduatedCommitment({
    required this.id,
    required this.level,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.tier,
    required this.virtue,
    this.tips = const [],
    required this.xpReward,
    required this.encouragement,
    required this.failureGrace,
  });

  final String id;
  final int level; // 1-40
  final String title;
  final String description;
  final int durationMinutes; // 2 to 1440 (24 hours)
  final CommitmentTier tier;
  final String virtue; // linked virtue
  final List<String> tips;
  final int xpReward;
  final String encouragement; // shown on completion
  final String failureGrace; // shown if they fail

  GraduatedCommitment copyWith({
    String? id,
    int? level,
    String? title,
    String? description,
    int? durationMinutes,
    CommitmentTier? tier,
    String? virtue,
    List<String>? tips,
    int? xpReward,
    String? encouragement,
    String? failureGrace,
  }) {
    return GraduatedCommitment(
      id: id ?? this.id,
      level: level ?? this.level,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tier: tier ?? this.tier,
      virtue: virtue ?? this.virtue,
      tips: tips ?? this.tips,
      xpReward: xpReward ?? this.xpReward,
      encouragement: encouragement ?? this.encouragement,
      failureGrace: failureGrace ?? this.failureGrace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'tier': tier.value,
      'virtue': virtue,
      'tips': tips,
      'xpReward': xpReward,
      'encouragement': encouragement,
      'failureGrace': failureGrace,
    };
  }

  factory GraduatedCommitment.fromJson(Map<String, dynamic> json) {
    return GraduatedCommitment(
      id: json['id'] as String,
      level: json['level'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      tier: CommitmentTier.fromValue(json['tier'] as int),
      virtue: json['virtue'] as String,
      tips: (json['tips'] as List<dynamic>?)?.cast<String>() ?? const [],
      xpReward: json['xpReward'] as int,
      encouragement: json['encouragement'] as String,
      failureGrace: json['failureGrace'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraduatedCommitment && other.id == id && other.level == level;
  }

  @override
  int get hashCode => Object.hash(id, level);

  @override
  String toString() => 'GraduatedCommitment(level: $level, title: $title)';
}

/// The four tiers of commitment difficulty.
enum CommitmentTier {
  quickWins(1, 'Quick Wins', '2-5 min', Color(0xFF4CAF50)),
  buildingBlocks(2, 'Building Blocks', '15-60 min', Color(0xFF2196F3)),
  halfDayChallenges(3, 'Half-Day Challenges', '2-6 hrs', Color(0xFFFF9800)),
  dayLong(4, 'Day-Long', '12-24 hrs', Color(0xFF9C27B0));

  final int value;
  final String label;
  final String timeRange;
  final Color color;

  const CommitmentTier(this.value, this.label, this.timeRange, this.color);

  static CommitmentTier fromLevel(int level) {
    if (level <= 10) return quickWins;
    if (level <= 20) return buildingBlocks;
    if (level <= 30) return halfDayChallenges;
    return dayLong;
  }

  static CommitmentTier fromValue(int value) {
    return CommitmentTier.values.firstWhere(
      (t) => t.value == value,
      orElse: () => quickWins,
    );
  }

  String get icon {
    switch (this) {
      case CommitmentTier.quickWins:
        return '\u26A1'; // lightning
      case CommitmentTier.buildingBlocks:
        return '\uD83E\uDDF1'; // brick
      case CommitmentTier.halfDayChallenges:
        return '\uD83D\uDD25'; // fire
      case CommitmentTier.dayLong:
        return '\uD83D\uDC51'; // crown
    }
  }
}
