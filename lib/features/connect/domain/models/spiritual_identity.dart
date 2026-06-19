import 'christian_tradition.dart';

/// The user's spiritual identity — the soul of UX personalization.
///
/// Every field is optional. The app works fully without any identity set.
class SpiritualIdentity {
  final ChristianTradition? tradition;
  final List<String> archetypeIds;
  final String spiritualAgeStage;
  final String commitmentCategory;
  final String primaryVirtue;
  final String prayerStyle;
  final String biblePreference;
  final String communityPreference;

  const SpiritualIdentity({
    this.tradition,
    this.archetypeIds = const [],
    this.spiritualAgeStage = '',
    this.commitmentCategory = '',
    this.primaryVirtue = '',
    this.prayerStyle = '',
    this.biblePreference = '',
    this.communityPreference = '',
  });

  SpiritualIdentity copyWith({
    ChristianTradition? tradition,
    List<String>? archetypeIds,
    String? spiritualAgeStage,
    String? commitmentCategory,
    String? primaryVirtue,
    String? prayerStyle,
    String? biblePreference,
    String? communityPreference,
    bool clearTradition = false,
  }) {
    return SpiritualIdentity(
      tradition: clearTradition ? null : (tradition ?? this.tradition),
      archetypeIds: archetypeIds ?? this.archetypeIds,
      spiritualAgeStage: spiritualAgeStage ?? this.spiritualAgeStage,
      commitmentCategory: commitmentCategory ?? this.commitmentCategory,
      primaryVirtue: primaryVirtue ?? this.primaryVirtue,
      prayerStyle: prayerStyle ?? this.prayerStyle,
      biblePreference: biblePreference ?? this.biblePreference,
      communityPreference: communityPreference ?? this.communityPreference,
    );
  }

  Map<String, dynamic> toJson() => {
    'tradition': tradition?.name,
    'archetype_ids': archetypeIds,
    'spiritual_age_stage': spiritualAgeStage,
    'commitment_category': commitmentCategory,
    'primary_virtue': primaryVirtue,
    'prayer_style': prayerStyle,
    'bible_preference': biblePreference,
    'community_preference': communityPreference,
  };

  factory SpiritualIdentity.fromJson(Map<String, dynamic> json) {
    return SpiritualIdentity(
      tradition: json['tradition'] != null
          ? ChristianTradition.fromString(json['tradition'] as String)
          : null,
      archetypeIds: (json['archetype_ids'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      spiritualAgeStage: json['spiritual_age_stage'] as String? ?? '',
      commitmentCategory: json['commitment_category'] as String? ?? '',
      primaryVirtue: json['primary_virtue'] as String? ?? '',
      prayerStyle: json['prayer_style'] as String? ?? '',
      biblePreference: json['bible_preference'] as String? ?? '',
      communityPreference: json['community_preference'] as String? ?? '',
    );
  }
}
