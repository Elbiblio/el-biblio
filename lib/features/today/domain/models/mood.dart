import 'package:flutter/material.dart';

enum MoodType {
  peaceful,
  thankful,
  joyful,
  divine,
  neutral,
  struggling,
}

extension MoodTypeX on MoodType {
  String get displayName => switch (this) {
        MoodType.peaceful => 'Peaceful',
        MoodType.thankful => 'Thankful',
        MoodType.joyful => 'Joyful',
        MoodType.divine => 'Divine',
        MoodType.neutral => 'Neutral',
        MoodType.struggling => 'Struggling',
      };

  String get emoji => switch (this) {
        MoodType.peaceful => '😊',
        MoodType.thankful => '🙏',
        MoodType.joyful => '😊',
        MoodType.divine => '✨',
        MoodType.neutral => '😐',
        MoodType.struggling => '😔',
      };

  List<Color> get gradientColors => switch (this) {
        MoodType.peaceful => [
          const Color(0xFFE8F5E8), // Soft blue-green
          const Color(0xFFB8E6E8),
        ],
        MoodType.thankful => [
          const Color(0xFFFFF5E6), // Warm gold
          const Color(0xFFFFD700),
        ],
        MoodType.joyful => [
          const Color(0xFFFFF8E6), // Bright yellow-orange
          const Color(0xFFFFB347),
        ],
        MoodType.divine => [
          const Color(0xFFE8E6FF), // Deep purple-blue
          const Color(0xFF9370DB),
        ],
        MoodType.neutral => [
          const Color(0xFFF5F5F0), // Warm gray
          const Color(0xFFE8E8E0),
        ],
        MoodType.struggling => [
          const Color(0xFFF0E8F5), // Gentle purple-gray
          const Color(0xFFD8D0E0),
        ],
      };

  static MoodType? fromStorage(String? value) {
    for (final type in MoodType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }
}

class Mood {
  const Mood({
    required this.type,
    required this.selectedAt,
  });

  final MoodType type;
  final DateTime selectedAt;

  Mood copyWith({
    MoodType? type,
    DateTime? selectedAt,
  }) {
    return Mood(
      type: type ?? this.type,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      type: MoodType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => MoodType.neutral,
      ),
      selectedAt: DateTime.parse(json['selectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'selectedAt': selectedAt.toIso8601String(),
    };
  }
}

enum TimeContext {
  morning,
  midday,
  evening,
  night,
}

extension TimeContextX on TimeContext {
  String get greeting => switch (this) {
        TimeContext.morning => 'Good morning!',
        TimeContext.midday => 'Good afternoon!',
        TimeContext.evening => 'Good evening!',
        TimeContext.night => 'Rest well',
      };

  String get focus => switch (this) {
        TimeContext.morning => 'Time for presence and intention',
        TimeContext.midday => 'How is your spiritual alignment?',
        TimeContext.evening => 'Time to complete and reflect',
        TimeContext.night => 'Prepare for restorative rest',
      };

  static TimeContext fromHour(int hour) {
    if (hour >= 6 && hour < 12) return TimeContext.morning;
    if (hour >= 12 && hour < 18) return TimeContext.midday;
    if (hour >= 18 && hour < 22) return TimeContext.evening;
    return TimeContext.night;
  }
}
