class CompassDiscoveryOption {
  const CompassDiscoveryOption({required this.archetype, required this.label});

  final String archetype;
  final String label;
}

class CompassDiscoveryCluster {
  const CompassDiscoveryCluster({
    required this.id,
    required this.label,
    required this.description,
    required this.options,
  });

  final String id;
  final String label;
  final String description;
  final List<CompassDiscoveryOption> options;

  bool contains(String? archetype) {
    return options.any((option) => option.archetype == archetype);
  }
}

class CompassDiscoveryCatalog {
  const CompassDiscoveryCatalog._();

  static const archetypeOrder = [
    'Artisan',
    'Watchman',
    'Cultivator',
    'Sower',
    'Welcomer',
    'Pillar',
    'Sentinel',
    'Bridgebuilder',
    'Healer',
    'Harvester',
    'Reformer',
    'Architect',
  ];

  static const seasonOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'I want to use my gifts without comparing myself',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'I need more quiet, focus, and healthy limits',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'I need patience, rest, and small faithful steps',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'I need courage to start something important',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'I want close friendships with better boundaries',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'I help people, but I also need care',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'I notice important things and need to act on them',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'I need peace, repair, and honest connection',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'I need healing, forgiveness, or fresh hope',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'I want good results without obsessing over numbers',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'I see what is wrong and want to help fix it',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'I need order without trying to control everything',
    ),
  ];

  static const seasonClusters = [
    CompassDiscoveryCluster(
      id: 'create_begin',
      label: 'Create, start, or bring work to completion',
      description: 'You are drawn toward making, beginning, or finishing.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Artisan',
          label: 'I keep comparing my gifts instead of offering them',
        ),
        CompassDiscoveryOption(
          archetype: 'Sower',
          label: 'I know the first step but keep waiting to begin',
        ),
        CompassDiscoveryOption(
          archetype: 'Harvester',
          label: 'I can become too focused on results and progress',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'tend_guard',
      label: 'Protect attention, patience, and steady faith',
      description: 'You are drawn toward guarding what matters each day.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Cultivator',
          label: 'I need to trust slow growth and keep showing up',
        ),
        CompassDiscoveryOption(
          archetype: 'Watchman',
          label: 'I need quiet, focus, and clearer limits',
        ),
        CompassDiscoveryOption(
          archetype: 'Pillar',
          label: 'People rely on me, but I rarely ask for help',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'heal_belong',
      label: 'Heal, welcome, or repair relationships',
      description: 'You are drawn toward care, belonging, and peace.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Welcomer',
          label: 'I make room for people but need better boundaries',
        ),
        CompassDiscoveryOption(
          archetype: 'Bridgebuilder',
          label: 'I often notice where peace needs to be rebuilt',
        ),
        CompassDiscoveryOption(
          archetype: 'Healer',
          label: 'I carry pain and want hope to become practical again',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'discern_build',
      label: 'Discern, confront, or build better order',
      description: 'You are drawn toward clarity, courage, and structure.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Sentinel',
          label: 'I notice what others miss but can stay hidden',
        ),
        CompassDiscoveryOption(
          archetype: 'Reformer',
          label: 'I see what is wrong and want change to be honest',
        ),
        CompassDiscoveryOption(
          archetype: 'Architect',
          label: 'I bring order but can grip the plan too tightly',
        ),
      ],
    ),
  ];

  static const pressureOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Start chasing a new idea',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Look for danger or drift',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Slow down and keep tending what is already here',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Force a beginning before I feel ready',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Try to keep everyone comfortable',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Carry more than I should and stay quiet',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Pull back and watch before acting',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Smooth conflict before people say the hard thing',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Take in the pain around me',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Check whether the effort is producing fruit',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Name the problem quickly',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Make a plan and tighten control',
    ),
  ];

  static const postponedOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Finishing before I start something new',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Turning noise off so I can pray and focus',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Accepting slow growth without calling it failure',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Taking the first step I already know',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Saying what I need instead of only hosting others',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Letting someone support me too',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Turning private conviction into one visible action',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Having the honest conversation I keep softening',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Receiving care instead of always giving care',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Celebrating progress before chasing the next target',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Building repair after I name the problem',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Letting a good plan begin before it is perfect',
    ),
  ];

  static const peopleNeedOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Fresh ideas and a hopeful way to see',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Wise warnings and help staying focused',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Patience and steady encouragement',
    ),
    CompassDiscoveryOption(archetype: 'Sower', label: 'Courage to begin'),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Warmth, welcome, and belonging',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'A reliable person when life feels heavy',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Clear thinking and prayerful warning',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Peace and honest connection',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Kindness, forgiveness, and hope',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Motivation and celebration',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Courage to name what should change',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Order and a clear path to follow',
    ),
  ];

  static const distortionFearOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Feeling unseen or not special',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Missing danger or letting noise take over',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Change or slow growth',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Wasting my chance by moving too slowly',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Rejection or disappointing people',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Being needed but not really known',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Being seen before I feel ready',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Conflict or losing connection',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Feeling pain I cannot fix',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Wasted effort or falling behind',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Wrong things continuing because I stayed quiet',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Mess, mistakes, or plans falling apart',
    ),
  ];

  static CompassDiscoveryCluster? clusterFor(String? archetype) {
    if (archetype == null) return null;
    for (final cluster in seasonClusters) {
      if (cluster.contains(archetype)) return cluster;
    }
    return null;
  }

  static CompassDiscoveryCluster? clusterById(String? id) {
    if (id == null) return null;
    for (final cluster in seasonClusters) {
      if (cluster.id == id) return cluster;
    }
    return null;
  }

  static List<CompassDiscoveryOption> pressureOptionsFor(
    Iterable<String?> signals, {
    int maxOptions = 4,
  }) {
    return _rankOptions(pressureOptions, signals, maxOptions: maxOptions);
  }

  static List<CompassDiscoveryOption> postponedOptionsFor(
    Iterable<String?> signals, {
    int maxOptions = 4,
  }) {
    return _rankOptions(postponedOptions, signals, maxOptions: maxOptions);
  }

  static List<CompassDiscoveryOption> peopleNeedOptionsFor(
    Iterable<String?> signals, {
    int maxOptions = 4,
  }) {
    return _rankOptions(peopleNeedOptions, signals, maxOptions: maxOptions);
  }

  static List<CompassDiscoveryOption> distortionOptionsFor(
    Iterable<String?> signals, {
    int maxOptions = 4,
  }) {
    return _rankOptions(distortionFearOptions, signals, maxOptions: maxOptions);
  }

  static List<CompassDiscoveryOption> _rankOptions(
    List<CompassDiscoveryOption> options,
    Iterable<String?> signals, {
    required int maxOptions,
  }) {
    final scores = {for (final archetype in archetypeOrder) archetype: 0};

    for (final signal in signals) {
      if (signal == null || !scores.containsKey(signal)) continue;
      scores[signal] = scores[signal]! + 3;
      final cluster = clusterFor(signal);
      if (cluster == null) continue;
      for (final option in cluster.options) {
        scores[option.archetype] = scores[option.archetype]! + 1;
      }
    }

    final ranked = List<String>.from(archetypeOrder)
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        if (byScore != 0) return byScore;
        return archetypeOrder.indexOf(a).compareTo(archetypeOrder.indexOf(b));
      });
    final candidates = ranked.where((name) => scores[name]! > 0).toList();
    final selected = candidates.isEmpty
        ? archetypeOrder.take(maxOptions).toList()
        : candidates.take(maxOptions).toList();

    return selected
        .map(
          (archetype) =>
              options.firstWhere((option) => option.archetype == archetype),
        )
        .toList();
  }

  static String seasonNameFor(String archetype) {
    return switch (archetype) {
      'Artisan' => 'Creative devotion',
      'Watchman' => 'Guarded attention',
      'Cultivator' => 'Patient formation',
      'Sower' => 'Courageous beginning',
      'Welcomer' => 'Honest hospitality',
      'Pillar' => 'Hidden faithfulness',
      'Sentinel' => 'Prayer into action',
      'Bridgebuilder' => 'Relational repair',
      'Healer' => 'Restorative presence',
      'Harvester' => 'Fruitful stewardship',
      'Reformer' => 'Constructive justice',
      'Architect' => 'Open-handed order',
      _ => 'Steady formation',
    };
  }

  static String callingFor(String archetype) {
    return switch (archetype) {
      'Artisan' => 'to make beauty that helps people notice God',
      'Watchman' => 'to guard attention, truth, and prayerful focus',
      'Cultivator' => 'to grow steady faith in ordinary places',
      'Sower' => 'to begin good work and encourage first steps',
      'Welcomer' => 'to create belonging without losing your own boundaries',
      'Pillar' => 'to strengthen people through dependable presence',
      'Sentinel' => 'to turn hidden conviction into timely action',
      'Bridgebuilder' => 'to help people move toward repair and peace',
      'Healer' => 'to bring mercy, hope, and patient care to pain',
      'Harvester' => 'to gather fruit and help good work become visible',
      'Reformer' => 'to name what is broken and build faithful repair',
      'Architect' => 'to create order that helps people move forward',
      _ => 'to practice steady faithfulness in this season',
    };
  }

  static String distortionFor(String archetype) {
    return switch (archetype) {
      'Artisan' => 'comparison, attention-seeking, novelty chasing',
      'Watchman' => 'suspicion, isolation, harsh judgment',
      'Cultivator' => 'passivity, fear of change, comfort-seeking',
      'Sower' => 'restlessness, shallow starts, fear of missing out',
      'Welcomer' => 'people-pleasing, blurred boundaries, fear of rejection',
      'Pillar' => 'over-carrying, resentment, disappearing under duty',
      'Sentinel' => 'withdrawal, overthinking, hiding behind observation',
      'Bridgebuilder' => 'conflict avoidance, false peace, losing your voice',
      'Healer' => 'savior pressure, emotional exhaustion, numbing pain',
      'Harvester' => 'scorekeeping, hurry, treating fruit like identity',
      'Reformer' => 'anger, contempt, outrage without repair',
      'Architect' => 'control, perfectionism, fear of disorder',
      _ => 'avoidance, distraction, and trying to grow without support',
    };
  }

  static String maturitySentence(int score) {
    if (score < 45) {
      return 'Your gift is real, but it needs simple support and a small daily practice before heavier responsibility.';
    }
    if (score < 65) {
      return 'Your gift is taking shape. You likely need steady rhythms, feedback, and one clear commitment at a time.';
    }
    if (score < 82) {
      return 'Your gift is becoming dependable. The next step is consistency without pride or pressure.';
    }
    return 'Your gift looks mature enough for deeper service, but it still needs humility, rest, and honest accountability.';
  }
}
