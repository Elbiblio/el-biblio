class CompassDiscoveryOption {
  const CompassDiscoveryOption({required this.archetype, required this.label});

  final String archetype;
  final String label;
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

  static const pressureOptions = [
    CompassDiscoveryOption(
      archetype: 'Sentinel',
      label: 'Withdraw, observe, and process alone',
    ),
    CompassDiscoveryOption(
      archetype: 'Architect',
      label: 'Try to control every variable',
    ),
    CompassDiscoveryOption(
      archetype: 'Healer',
      label: 'Absorb everyone else\'s pain',
    ),
    CompassDiscoveryOption(
      archetype: 'Watchman',
      label: 'Protect attention and boundaries',
    ),
  ];

  static const postponedOptions = [
    CompassDiscoveryOption(
      archetype: 'Sower',
      label: 'Beginning the thing I know matters',
    ),
    CompassDiscoveryOption(
      archetype: 'Artisan',
      label: 'Finishing one creation before chasing novelty',
    ),
    CompassDiscoveryOption(
      archetype: 'Bridgebuilder',
      label: 'Having an honest conversation',
    ),
    CompassDiscoveryOption(
      archetype: 'Pillar',
      label: 'Taking a step for my own calling',
    ),
  ];

  static const peopleNeedOptions = [
    CompassDiscoveryOption(
      archetype: 'Cultivator',
      label: 'Patient care and steady encouragement',
    ),
    CompassDiscoveryOption(
      archetype: 'Welcomer',
      label: 'Warmth, welcome, and belonging',
    ),
    CompassDiscoveryOption(
      archetype: 'Reformer',
      label: 'Courage to name what must change',
    ),
    CompassDiscoveryOption(
      archetype: 'Harvester',
      label: 'Momentum, mobilizing, and celebration',
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
