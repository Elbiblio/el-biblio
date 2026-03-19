/// The four main phases of a guided meditation session
enum GuidedPhase {
  /// Initial breathing exercises to calm the mind and body
  breathing,
  
  /// Imagery journey to help declutter and focus the mind
  sceneryJourney,
  
  /// Focused prayer or meditation on the chosen theme
  focusPrayer,
  
  /// Gentle closing and transition back to daily life
  closing,
}

extension GuidedPhaseExtension on GuidedPhase {
  /// Get the display name for this phase
  String get displayName {
    switch (this) {
      case GuidedPhase.breathing:
        return 'Breathing';
      case GuidedPhase.sceneryJourney:
        return 'Journey';
      case GuidedPhase.focusPrayer:
        return 'Focus';
      case GuidedPhase.closing:
        return 'Closing';
    }
  }

  /// Get a brief description of what happens in this phase
  String get description {
    switch (this) {
      case GuidedPhase.breathing:
        return 'Close your eyes and follow guided breathing';
      case GuidedPhase.sceneryJourney:
        return 'Visualize a peaceful journey toward God\'s presence';
      case GuidedPhase.focusPrayer:
        return 'Draw attention to prayer and contemplation';
      case GuidedPhase.closing:
        return 'Gently return and carry peace forward';
    }
  }

  /// Get the typical duration for this phase (in percentage of total session)
  double get typicalDurationRatio {
    switch (this) {
      case GuidedPhase.breathing:
        return 0.15; // 15% of session
      case GuidedPhase.sceneryJourney:
        return 0.35; // 35% of session
      case GuidedPhase.focusPrayer:
        return 0.35; // 35% of session
      case GuidedPhase.closing:
        return 0.15; // 15% of session
    }
  }
}
