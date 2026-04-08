import 'package:flutter/services.dart';

/// Centralized haptic feedback for key interactions.
///
/// Provides semantic methods so call-sites read as intent rather than
/// implementation detail.
abstract final class HapticService {
  /// Light tap — option selection, chip toggle, nav switch.
  static void selection() => HapticFeedback.selectionClick();

  /// Subtle confirmation — anchor tap, minor action.
  static void light() => HapticFeedback.lightImpact();

  /// Positive outcome — check-in complete, answer confirmed.
  static void success() => HapticFeedback.mediumImpact();

  /// Major milestone — journey milestone, streak achievement, all anchors done.
  static void milestone() => HapticFeedback.heavyImpact();
}
