/// The phase/state of a meditation session lifecycle.
enum MeditationPhase {
  setup,
  countdown,
  active,
  paused,
  complete,
}

/// Available meditation styles matching the old app's architecture.
enum MeditationStyle {
  virtue('Grow a Virtue', 'Focus on a single virtue such as Love or Humility.'),
  parable('Parable of Jesus', "Sit with one of Jesus' parables."),
  centering('Centering Prayer', 'Choose a sacred word and rest in silence.'),
  jesusPrayer('Jesus Prayer', 'Pray "Lord Jesus Christ… have mercy on me" with your breath.'),
  chant('Chant', 'Meditate to a song for worship and drawing closer to God.');

  const MeditationStyle(this.label, this.description);
  final String label;
  final String description;
}

/// Background sound options during meditation.
enum BackgroundSound {
  ambient('Ambient'),
  heartbeat('Heartbeat'),
  silent('Silent');

  const BackgroundSound(this.label);
  final String label;
}

/// Breath pace for Jesus Prayer style.
enum BreathPace {
  slow('Slow', 'Steady and calming', inMs: 5200, holdMs: 3000, outMs: 6000),
  medium('Medium', 'Balanced rhythm', inMs: 4000, holdMs: 2000, outMs: 4800),
  fast('Fast', 'Energising cadence', inMs: 2800, holdMs: 1500, outMs: 3200);

  const BreathPace(
    this.label,
    this.description, {
    required this.inMs,
    required this.holdMs,
    required this.outMs,
  });

  final String label;
  final String description;
  final int inMs;
  final int holdMs;
  final int outMs;

  int get cycleDurationMs => inMs + holdMs + outMs;
}

/// The current breath phase during active meditation.
enum BreathPhase { breathIn, hold, breathOut }

/// Meditation level based on session count and duration.
enum MeditationLevel { foundation, growth, deep }
