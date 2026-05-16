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
      label: 'My creativity needs to become worship, not comparison',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'My attention needs rebuilding, guarding, and quiet',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'I need patience, rest, and ordinary faithfulness',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'I need courage to begin what I keep delaying',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'I need warmer belonging with better boundaries',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'I need to serve faithfully without disappearing',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'I need to turn insight and prayer into action',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'I need repair, peace, and honest connection',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'I need healing, forgiveness, or supported hope',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'I need fruitfulness without metrics becoming my master',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Holy frustration needs to become constructive change',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'I need order without control or perfectionism',
    ),
  ];

  static const seasonClusters = [
    CompassDiscoveryCluster(
      id: 'create_begin',
      label: 'Creating, beginning, or gathering fruit',
      description: 'Something in me wants to make, start, or multiply good.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Artisan',
          label: 'My creativity needs to become worship, not comparison',
        ),
        CompassDiscoveryOption(
          archetype: 'Sower',
          label: 'I need courage to begin what I keep delaying',
        ),
        CompassDiscoveryOption(
          archetype: 'Harvester',
          label: 'I need fruitfulness without metrics becoming my master',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'tend_guard',
      label: 'Tending, guarding, or staying faithful',
      description: 'I am learning patience, attention, and steady presence.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Cultivator',
          label: 'I need patience, rest, and ordinary faithfulness',
        ),
        CompassDiscoveryOption(
          archetype: 'Watchman',
          label: 'My attention needs rebuilding, guarding, and quiet',
        ),
        CompassDiscoveryOption(
          archetype: 'Pillar',
          label: 'I need to serve faithfully without disappearing',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'heal_belong',
      label: 'Healing, belonging, or repairing connection',
      description: 'Relationships, pain, or peace are asking for attention.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Welcomer',
          label: 'I need warmer belonging with better boundaries',
        ),
        CompassDiscoveryOption(
          archetype: 'Bridgebuilder',
          label: 'I need repair, peace, and honest connection',
        ),
        CompassDiscoveryOption(
          archetype: 'Healer',
          label: 'I need healing, forgiveness, or supported hope',
        ),
      ],
    ),
    CompassDiscoveryCluster(
      id: 'discern_build',
      label: 'Discerning, ordering, or changing what is broken',
      description: 'I can see what needs structure, courage, or action.',
      options: [
        CompassDiscoveryOption(
          archetype: 'Sentinel',
          label: 'I need to turn insight and prayer into action',
        ),
        CompassDiscoveryOption(
          archetype: 'Reformer',
          label: 'Holy frustration needs to become constructive change',
        ),
        CompassDiscoveryOption(
          archetype: 'Architect',
          label: 'I need order without control or perfectionism',
        ),
      ],
    ),
  ];

  static const pressureOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Chase a better idea instead of staying with one',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Scan for what could go wrong and tighten boundaries',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Slow down, tend what is in front of me, and wait',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Push myself to start before I feel ready',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Try to keep everyone close and comfortable',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Carry the load quietly so others can keep going',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Withdraw, observe, and process before acting',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Try to reduce conflict before it spreads',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Absorb the pain in the room and try to soothe it',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Measure progress and look for useful fruit',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Name what is wrong and want it fixed quickly',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Try to control every variable and build a plan',
    ),
  ];

  static const postponedOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Finishing one creation instead of chasing a new one',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Protecting quiet, prayer, and attention from noise',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Accepting a slower season without calling it failure',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Beginning the thing I know matters',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Saying what I need instead of only making room for others',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Taking a step for my own calling',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Turning private conviction into one visible act',
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
      label: 'Celebrating fruit without rushing to the next target',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Building the repair instead of only naming the problem',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Letting a good-enough plan move before it is perfect',
    ),
  ];

  static const peopleNeedOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Fresh imagination and a more beautiful way to see',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Discernment, protection, and help noticing drift',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Patient care and steady encouragement',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Courage to begin and take the next step',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Warmth, welcome, and belonging',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Reliable presence when life gets heavy',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Prayerful clarity and timely warning',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Repair, peace, and honest connection',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Tenderness, forgiveness, and supported hope',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Momentum, mobilizing, and celebration',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Courage to name what must change',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Order, structure, and a path people can follow',
    ),
  ];

  static const distortionFearOptions = [
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Being unseen, ordinary, or creatively irrelevant',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Letting danger, disorder, or compromise slip through',
    ),
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Change, pruning, or losing control of growth',
    ),
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Wasting potential by moving too slowly',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Rejection, disapproval, or disappointing people',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Being needed by everyone but never truly chosen',
    ),
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Being exposed before my inner life feels ready',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Conflict, division, or losing connection',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Not being able to fix pain I can clearly feel',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Fruitlessness, wasted effort, or falling behind',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Injustice continuing because I stayed quiet',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Chaos, imperfection, or plans slipping out of place',
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
