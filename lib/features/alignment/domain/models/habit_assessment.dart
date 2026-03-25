import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum HabitCategory {
  spiritual,
  mental,
  physical,
  relational,
  digital;

  String get label => name[0].toUpperCase() + name.substring(1);

  Color get color => switch (this) {
        spiritual => const Color(0xFF7B68EE),
        mental => const Color(0xFF4B82C3),
        physical => const Color(0xFF5A8E67),
        relational => const Color(0xFFA97A46),
        digital => const Color(0xFFB55F68),
      };

  IconData get icon => switch (this) {
        spiritual => LucideIcons.sparkles,
        mental => LucideIcons.brain,
        physical => LucideIcons.heartPulse,
        relational => LucideIcons.users,
        digital => LucideIcons.smartphone,
      };
}

class HabitItem {
  final String id;
  final String name;
  final String description;
  final HabitCategory category;
  final bool isBadHabit;
  final String? counterHabit;
  final int severity;
  final String relatedVirtue;
  final List<String> conquestTips;
  final bool isActive;
  final int currentStreak;
  final DateTime? lastCheckIn;

  const HabitItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isBadHabit,
    this.counterHabit,
    required this.severity,
    required this.relatedVirtue,
    this.conquestTips = const [],
    this.isActive = false,
    this.currentStreak = 0,
    this.lastCheckIn,
  });

  HabitItem copyWith({
    String? id,
    String? name,
    String? description,
    HabitCategory? category,
    bool? isBadHabit,
    String? counterHabit,
    int? severity,
    String? relatedVirtue,
    List<String>? conquestTips,
    bool? isActive,
    int? currentStreak,
    DateTime? lastCheckIn,
  }) {
    return HabitItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isBadHabit: isBadHabit ?? this.isBadHabit,
      counterHabit: counterHabit ?? this.counterHabit,
      severity: severity ?? this.severity,
      relatedVirtue: relatedVirtue ?? this.relatedVirtue,
      conquestTips: conquestTips ?? this.conquestTips,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    );
  }

  factory HabitItem.fromJson(Map<String, dynamic> json) {
    return HabitItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: HabitCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HabitCategory.spiritual,
      ),
      isBadHabit: json['isBadHabit'] as bool,
      counterHabit: json['counterHabit'] as String?,
      severity: json['severity'] as int,
      relatedVirtue: json['relatedVirtue'] as String,
      conquestTips: List<String>.from(json['conquestTips'] as List? ?? []),
      isActive: json['isActive'] as bool? ?? false,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'isBadHabit': isBadHabit,
      'counterHabit': counterHabit,
      'severity': severity,
      'relatedVirtue': relatedVirtue,
      'conquestTips': conquestTips,
      'isActive': isActive,
      'currentStreak': currentStreak,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
    };
  }

  /// For bad habits: days since last occurrence.
  int get daysSinceLastOccurrence {
    if (lastCheckIn == null) return 0;
    return DateTime.now().difference(lastCheckIn!).inDays;
  }
}

class SelfAssessmentQuestion {
  final String id;
  final String question;
  final HabitCategory category;
  final List<String> relatedHabitIds;

  const SelfAssessmentQuestion({
    required this.id,
    required this.question,
    required this.category,
    required this.relatedHabitIds,
  });
}
