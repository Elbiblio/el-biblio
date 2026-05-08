import 'package:flutter/material.dart';

/// The three companion personas. Naomi is the default fallback for any user
/// who skips selection — chosen for the broadest Christian resonance.
enum CompanionCharacter {
  raziel,
  naomi,
  james,
}

extension CompanionCharacterX on CompanionCharacter {
  String get code => switch (this) {
        CompanionCharacter.raziel => 'raziel',
        CompanionCharacter.naomi => 'naomi',
        CompanionCharacter.james => 'james',
      };

  String get displayName => switch (this) {
        CompanionCharacter.raziel => 'Raziel',
        CompanionCharacter.naomi => 'Naomi',
        CompanionCharacter.james => 'James',
      };

  String get tagline => switch (this) {
        CompanionCharacter.raziel => 'Wisdom to see',
        CompanionCharacter.naomi => 'Devotion to walk',
        CompanionCharacter.james => 'Faith that acts',
      };

  String get description => switch (this) {
        CompanionCharacter.raziel =>
          'Reflective and steady. Asks questions more than he states. Scripture as lamp for the next step.',
        CompanionCharacter.naomi =>
          'Warm and covenant-keeping. Speaks like an older sister in the faith, never rushing you.',
        CompanionCharacter.james =>
          'Plain and practical. Turns every reflection into a concrete next step — faith with hands.',
      };

  List<Color> get gradientStops => switch (this) {
        CompanionCharacter.raziel => const [
            Color(0xFF4F6BED), // deep indigo
            Color(0xFF8FB4FF), // clear sky
          ],
        CompanionCharacter.naomi => const [
            Color(0xFFE06C9F), // warm rose
            Color(0xFFFFD7B5), // amber candlelight
          ],
        CompanionCharacter.james => const [
            Color(0xFF2E8B57), // seasoned green
            Color(0xFFB5E48C), // spring leaf
          ],
      };

  /// Ordered book preference the companion draws daily verses from.
  /// First entry is highest priority. Used by the notification scheduler
  /// to pick tomorrow's verse in a way that matches the companion's voice.
  List<String> get dailyVerseBookPriority => switch (this) {
        CompanionCharacter.raziel => const [
            'Proverbs',
            'Wisdom',
            'Hebrews',
            'Daniel',
            'Revelation',
          ],
        CompanionCharacter.naomi => const [
            'Ruth',
            'Zechariah',
            'Matthew',
            'Proverbs',
            'Psalms',
          ],
        CompanionCharacter.james => const [
            'James',
            'John',
            'Romans',
            'Proverbs',
            'Ecclesiastes',
          ],
      };

  /// Emotion-framed, forbids streak/guilt copy. Used as template fallback
  /// when backend greeting is unavailable.
  String warmOpener({String? userFirstName}) {
    final name = (userFirstName ?? '').trim();
    final salute = name.isEmpty ? '' : ', $name';
    return switch (this) {
      CompanionCharacter.raziel =>
        'Good to meet you$salute. Before we begin — what is the question that has been circling your heart lately?',
      CompanionCharacter.naomi =>
        'I\'m glad you\'re here$salute. Take a breath. We don\'t have to hurry. Would you like to start with a Psalm, or tell me what\'s on your mind?',
      CompanionCharacter.james =>
        'Alright$salute — let\'s walk. Tell me one small thing you want your week to look different by Sunday, and we\'ll start there.',
    };
  }

  static CompanionCharacter fromCode(String? code) {
    return CompanionCharacter.values.firstWhere(
      (c) => c.code == code,
      orElse: () => CompanionCharacter.naomi,
    );
  }

  static CompanionCharacter? tryFromCode(String? code) {
    if (code == null) return null;
    for (final c in CompanionCharacter.values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Static mapping from archetype → recommended companion. Not hard rules —
/// the user may pick any. Used to pre-highlight the pick on the selection screen.
class CompanionRecommendation {
  static CompanionCharacter forArchetype(String? archetypeId) {
    if (archetypeId == null) return CompanionCharacter.naomi;
    switch (archetypeId) {
      case 'Watchman':
      case 'Sentinel':
      case 'Reformer':
      case 'Architect':
      case 'Sower':
        return CompanionCharacter.raziel;
      case 'Harvester':
      case 'Artisan':
        return CompanionCharacter.james;
      case 'Pillar':
      case 'Welcomer':
      case 'Healer':
      case 'Bridgebuilder':
      case 'Cultivator':
      default:
        return CompanionCharacter.naomi;
    }
  }

  /// Category override — Discipline-focused users get James regardless of archetype.
  static CompanionCharacter forProfile({
    required String? archetypeId,
    required String? commitmentCategory,
  }) {
    if (commitmentCategory == 'discipline') {
      return CompanionCharacter.james;
    }
    return forArchetype(archetypeId);
  }
}
