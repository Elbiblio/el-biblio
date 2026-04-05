/// A short 2-3 minute guided breathing + scripture session for a midday reset.
class QuickSanitySession {
  const QuickSanitySession({
    required this.id,
    required this.title,
    required this.scriptureText,
    required this.scriptureReference,
    required this.breathingPattern,
    required this.durationSeconds,
    required this.closingPrayer,
    this.description,
  });

  /// Unique identifier for this session.
  final String id;

  /// Short themed title (e.g. "Peace in the Storm").
  final String title;

  /// The scripture passage text.
  final String scriptureText;

  /// Book, chapter, and verse reference (e.g. "Psalm 46:10").
  final String scriptureReference;

  /// Breathing pattern as inhale-hold-exhale seconds (e.g. "4-4-6").
  final String breathingPattern;

  /// Total duration of the session in seconds (120-180).
  final int durationSeconds;

  /// A short closing prayer to end the session.
  final String closingPrayer;

  /// Optional one-line description.
  final String? description;

  /// Parse the breathing pattern into individual components.
  ({int inhale, int hold, int exhale}) get breathComponents {
    final parts = breathingPattern.split('-').map(int.parse).toList();
    return (
      inhale: parts[0],
      hold: parts.length > 1 ? parts[1] : 0,
      exhale: parts.length > 2 ? parts[2] : parts[0],
    );
  }

  /// Duration formatted as "X min" for display.
  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (seconds == 0) return '$minutes min';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
