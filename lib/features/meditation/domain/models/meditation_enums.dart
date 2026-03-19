/// The phase/state of a meditation session lifecycle.
enum MeditationPhase {
  setup,
  countdown,
  active,
  paused,
  complete,
}

/// Available meditation styles - simplified to 4 main options.
enum MeditationStyle {
  quietReflection('Quiet Reflection', 'Sit with Jesus in silent contemplation.'),
  bible('Bible', 'Reflect on words of the Bible.'),
  affirmation('Affirmation', 'Grow a virtue or stop a habit.'),
  chant('Chant', 'Meditate on a song.');

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
