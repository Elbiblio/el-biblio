import 'package:flutter/animation.dart';

/// Shared animation constants for consistent micro-interactions across the app.
///
/// Use these instead of ad-hoc durations and curves to maintain a cohesive
/// feel. All values are tuned for spiritual-app UX: calm, intentional, not
/// frenetic.
abstract final class AppAnimations {
  // ---------------------------------------------------------------------------
  // Durations
  // ---------------------------------------------------------------------------

  /// Instant feedback — tab switches, selection highlights (150ms).
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions — expand/collapse, fade in/out (300ms).
  static const Duration normal = Duration(milliseconds: 300);

  /// Deliberate transitions — page swaps, card reveals (500ms).
  static const Duration slow = Duration(milliseconds: 500);

  /// Celebration moments — confetti, milestone reveals (800ms).
  static const Duration celebration = Duration(milliseconds: 800);

  /// Identity reveal — archetype card scale + fade (1200ms).
  static const Duration reveal = Duration(milliseconds: 1200);

  // ---------------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------------

  /// Default for most transitions — smooth deceleration.
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// Playful bounce for celebrations and reveals.
  static const Curve bounceCurve = Curves.elasticOut;

  /// Slight overshoot for attention-grabbing reveals.
  static const Curve springCurve = Curves.easeOutBack;

  /// Gentle ease for fade transitions.
  static const Curve fadeCurve = Curves.easeOut;

  /// Smooth for expand/collapse height changes.
  static const Curve sizeCurve = Curves.easeInOutCubic;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a staggered delay for item at [index] in a list reveal.
  ///
  /// Example: `Future.delayed(AppAnimations.staggerDelay(i), () => ...)`
  static Duration staggerDelay(int index, {Duration base = const Duration(milliseconds: 80)}) {
    return base * index;
  }

  /// Returns an [Interval] for staggered animations within a controller.
  ///
  /// [index] is the item position, [total] is the item count.
  /// Each item gets an equal slice with a 30% overlap for smooth flow.
  static Interval staggerInterval(int index, int total, {Curve curve = Curves.easeOutCubic}) {
    final slice = 1.0 / total;
    final overlap = slice * 0.3;
    final start = (index * slice - (index > 0 ? overlap : 0)).clamp(0.0, 1.0);
    final end = ((index + 1) * slice + overlap).clamp(0.0, 1.0);
    return Interval(start, end, curve: curve);
  }
}
