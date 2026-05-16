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
      label: 'Making, starting, or finishing good things',
      description: 'You want to create, begin, or see good fruit.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Artisan',
          label: 'I want to use my gifts without comparing myself',
        ),
        CompassDiscoveryOption(
          archetype: 'Sower',
          label: 'I need courage to start something important',
        ),
        CompassDiscoveryOption(
          archetype: 'Harvester',
          label: 'I want good results without obsessing over numbers',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'tend_guard',
      label: 'Staying steady, careful, and faithful',
      description: 'You want patience, focus, and steady daily faith.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Cultivator',
          label: 'I need patience, rest, and small faithful steps',
        ),
        CompassDiscoveryOption(
          archetype: 'Watchman',
          label: 'I need more quiet, focus, and healthy limits',
        ),
        CompassDiscoveryOption(
          archetype: 'Pillar',
          label: 'I help people, but I also need care',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'heal_belong',
      label: 'Healing, friendship, and peace with people',
      description: 'You want support, repair, or a healthier connection.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Welcomer',
          label: 'I want close friendships with better boundaries',
        ),
        CompassDiscoveryOption(
          archetype: 'Bridgebuilder',
          label: 'I need peace, repair, and honest connection',
        ),
        CompassDiscoveryOption(
          archetype: 'Healer',
          label: 'I need healing, forgiveness, or fresh hope',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'discern_build',
      label: 'Seeing problems and building better ways',
      description: 'You notice what needs action, courage, or structure.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Sentinel',
          label: 'I notice important things and need to act on them',
        ),
        CompassDiscoveryOption(
          archetype: 'Reformer',
          label: 'I see what is wrong and want to help fix it',
        ),
        CompassDiscoveryOption(
          archetype: 'Architect',
          label: 'I need order without trying to control everything',
        ),
      ],
    ),
  ];

  static const pressureOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Look for a new idea instead of finishing one',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Watch for what could go wrong',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Slow down and care for what is in front of me',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Push myself to start before I feel ready',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Try to keep everyone happy',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Carry the load quietly',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Step back and think before I act',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Try to stop conflict from growing',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Feel other people\'s pain and try to help',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Measure progress and look for results',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Name what is wrong and want it fixed',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Make a plan and try to control the details',
    ),
  ];

  static const postponedOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Finishing one thing before starting another',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Protecting quiet, prayer, and focus',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Accepting a slower season without feeling like a failure',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Starting the thing I know matters',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Saying what I need',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Taking one step for my own growth',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Turning what I believe into one visible action',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Having the honest conversation',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Receiving care instead of always giving it',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Celebrating progress before rushing ahead',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Helping fix the problem, not just naming it',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Letting a good-enough plan begin',
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
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Courage to begin',
    ),
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
}
