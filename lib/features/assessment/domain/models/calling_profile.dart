import '../../../commitments/domain/models/commitment_category.dart';
import '../../../mission/domain/models/mission_focus.dart';

/// A synthesized calling profile that translates archetype and assessment data
/// into actionable weekly priorities and spiritual direction.
class CallingProfile {
  const CallingProfile({
    required this.archetypeId,
    required this.archetypeIdentity,
    required this.weeklyPriorities,
    required this.burdensAndServiceTendencies,
    required this.growthRisks,
    required this.relationalFocus,
    required this.recommendedPractices,
    required this.personalDistractions,
    required this.commitmentCategory,
    required this.missionFocus,
    required this.createdAt,
  });

  /// The archetype this profile is based on
  final String archetypeId;

  /// The identity label (e.g., "Creator", "Guardian")
  final String archetypeIdentity;

  /// 3-5 weekly priority areas derived from archetype + commitment category
  final List<WeeklyPriority> weeklyPriorities;

  /// Specific burdens or service tendencies this person is drawn to
  final List<String> burdensAndServiceTendencies;

  /// Growth risks and pitfalls to watch for
  final List<String> growthRisks;

  /// Relational focus areas (e.g., mentoring, hospitality, peacemaking)
  final List<String> relationalFocus;

  /// Recommended daily/weekly practices specific to this profile
  final List<RecommendedPractice> recommendedPractices;

  /// User-selected personal distractions/addictions to address
  final List<String> personalDistractions;

  /// The commitment category (growth, discipline, charity)
  final String commitmentCategory;

  /// The primary mission focus (service, faithSharing, encouragement)
  final String missionFocus;

  /// When this profile was generated
  final DateTime createdAt;

  CallingProfile copyWith({
    String? archetypeId,
    String? archetypeIdentity,
    List<WeeklyPriority>? weeklyPriorities,
    List<String>? burdensAndServiceTendencies,
    List<String>? growthRisks,
    List<String>? relationalFocus,
    List<RecommendedPractice>? recommendedPractices,
    List<String>? personalDistractions,
    String? commitmentCategory,
    String? missionFocus,
    DateTime? createdAt,
  }) {
    return CallingProfile(
      archetypeId: archetypeId ?? this.archetypeId,
      archetypeIdentity: archetypeIdentity ?? this.archetypeIdentity,
      weeklyPriorities: weeklyPriorities ?? this.weeklyPriorities,
      burdensAndServiceTendencies: burdensAndServiceTendencies ?? this.burdensAndServiceTendencies,
      growthRisks: growthRisks ?? this.growthRisks,
      relationalFocus: relationalFocus ?? this.relationalFocus,
      recommendedPractices: recommendedPractices ?? this.recommendedPractices,
      personalDistractions: personalDistractions ?? this.personalDistractions,
      commitmentCategory: commitmentCategory ?? this.commitmentCategory,
      missionFocus: missionFocus ?? this.missionFocus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'archetypeId': archetypeId,
      'archetypeIdentity': archetypeIdentity,
      'weeklyPriorities': weeklyPriorities.map((p) => p.toMap()).toList(),
      'burdensAndServiceTendencies': burdensAndServiceTendencies,
      'growthRisks': growthRisks,
      'relationalFocus': relationalFocus,
      'recommendedPractices': recommendedPractices.map((p) => p.toMap()).toList(),
      'personalDistractions': personalDistractions,
      'commitmentCategory': CommitmentCategory.normalizeStorageValue(
        commitmentCategory,
      ),
      'missionFocus': MissionFocusTypeX.normalizeStorageValue(missionFocus),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CallingProfile.fromMap(Map<String, dynamic> map) {
    return CallingProfile(
      archetypeId: map['archetypeId'] as String,
      archetypeIdentity: map['archetypeIdentity'] as String,
      weeklyPriorities: (map['weeklyPriorities'] as List)
          .map((p) => WeeklyPriority.fromMap(p as Map<String, dynamic>))
          .toList(),
      burdensAndServiceTendencies: List<String>.from(map['burdensAndServiceTendencies'] as List),
      growthRisks: List<String>.from(map['growthRisks'] as List),
      relationalFocus: List<String>.from(map['relationalFocus'] as List),
      recommendedPractices: (map['recommendedPractices'] as List)
          .map((p) => RecommendedPractice.fromMap(p as Map<String, dynamic>))
          .toList(),
      personalDistractions: List<String>.from(map['personalDistractions'] as List),
      commitmentCategory: CommitmentCategory.normalizeStorageValue(
        map['commitmentCategory'] as String?,
      ),
      missionFocus: MissionFocusTypeX.normalizeStorageValue(
        map['missionFocus'] as String?,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// A weekly priority area with a focus and suggested actions
class WeeklyPriority {
  const WeeklyPriority({
    required this.area,
    required this.focus,
    required this.suggestedActions,
  });

  /// The priority area (e.g., "Creative Expression", "Intercession")
  final String area;

  /// The specific focus for this week
  final String focus;

  /// 2-3 concrete action suggestions
  final List<String> suggestedActions;

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'focus': focus,
      'suggestedActions': suggestedActions,
    };
  }

  factory WeeklyPriority.fromMap(Map<String, dynamic> map) {
    return WeeklyPriority(
      area: map['area'] as String,
      focus: map['focus'] as String,
      suggestedActions: List<String>.from(map['suggestedActions'] as List),
    );
  }
}

/// A recommended spiritual practice with frequency and description
class RecommendedPractice {
  const RecommendedPractice({
    required this.name,
    required this.description,
    required this.frequency,
    required this.category,
  });

  /// Name of the practice (e.g., "Morning Scripture", "Weekly Fast")
  final String name;

  /// Description of what the practice involves
  final String description;

  /// Frequency (e.g., "daily", "weekly", "as needed")
  final String frequency;

  /// Category (e.g., "growth", "discipline", "charity")
  final String category;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'frequency': frequency,
      'category': category,
    };
  }

  factory RecommendedPractice.fromMap(Map<String, dynamic> map) {
    return RecommendedPractice(
      name: map['name'] as String,
      description: map['description'] as String,
      frequency: map['frequency'] as String,
      category: CommitmentCategory.normalizeStorageValue(
        map['category'] as String?,
      ),
    );
  }
}
