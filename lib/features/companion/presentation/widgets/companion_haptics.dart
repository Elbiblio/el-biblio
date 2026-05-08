import 'package:flutter/services.dart';

import '../../domain/models/companion_character.dart';

/// Per-character haptic signatures. Users learn the companion by touch alone.
///
/// Kept deliberately simple (HapticFeedback only — no platform channel for
/// custom amplitudes yet). Patterns differ by rhythm, not intensity.
class CompanionHaptics {
  const CompanionHaptics._();

  /// Light acknowledgement — used on tap-to-focus, selection changes.
  static Future<void> acknowledge(CompanionCharacter character) async {
    switch (character) {
      case CompanionCharacter.raziel:
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.selectionClick();
        await Future.delayed(const Duration(milliseconds: 80));
        await HapticFeedback.selectionClick();
        break;
      case CompanionCharacter.naomi:
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 110));
        await HapticFeedback.lightImpact();
        break;
      case CompanionCharacter.james:
        await HapticFeedback.mediumImpact();
        break;
    }
  }

  /// Reply-received signature — plays when the assistant message lands.
  static Future<void> replyLanded(CompanionCharacter character) async {
    switch (character) {
      case CompanionCharacter.raziel:
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.selectionClick();
        break;
      case CompanionCharacter.naomi:
        await HapticFeedback.lightImpact();
        break;
      case CompanionCharacter.james:
        await HapticFeedback.mediumImpact();
        break;
    }
  }
}
