class Archetype {
  final String name;
  final String identity;
  final String strengths;
  final String distortions;
  final List<String> related;

  const Archetype({
    required this.name,
    required this.identity,
    required this.strengths,
    required this.distortions,
    required this.related,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Archetype &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  static const List<Archetype> allArchetypes = [
    Archetype(
      name: 'Artisan',
      identity: 'Creator',
      strengths:
          "Creativity that reflects God's nature, Ability to evoke emotion; Innovation; Prophetic symbolism",
      distortions:
          "Vanity, Feeling Superior to others; Addiction to novelty; Compromise for popularity",
      related: ['Sower', 'Healer'],
    ),
    Archetype(
      name: 'Watchman',
      identity: 'Guardian',
      strengths:
          "Sharp discernment, Courage to confront danger, Loyalty, Intercessory alertness",
      distortions: "Following rules without mercy; Paranoia, Isolation, Resistance to grace",
      related: ['Sentinel', 'Reformer'],
    ),
    Archetype(
      name: 'Cultivator',
      identity: 'Nurturer',
      strengths:
          "Long-term investment mindset, Empathy, Ability to see hidden potential; Faithfulness in the mundane",
      distortions:
          "Overcontrol; Fear of change; Burnout, Resistance to pruning",
      related: ['Pillar', 'Healer'],
    ),
    Archetype(
      name: 'Sower',
      identity: 'Initiator',
      strengths:
          "Boldness to start without full clarity, Faith in unseen outcomes; Ability to inspire, Sensitivity to divine timing",
      distortions:
          "Impulsiveness, Shallow roots; Ego-driven ambition; Manipulation disguised as inspiration",
      related: ['Reformer', 'Artisan'],
    ),
    Archetype(
      name: 'Welcomer',
      identity: 'Host',
      strengths:
          "Generosity, Warmth, Attentiveness, Ability to set atmosphere for God's work",
      distortions:
          "People-pleasing; Neglect of self-care, Hospitality for personal gain, Avoidance of truth to keep comfort",
      related: ['Healer', 'Bridgebuilder'],
    ),
    Archetype(
      name: 'Pillar',
      identity: 'Supporter',
      strengths: "Loyalty, Humility, Perseverance; Reliability",
      distortions:
          "Neglect of own calling, Enabling unhealthy dependence, Resentment from lack of recognition; Fear of stepping forward",
      related: ['Cultivator', 'Bridgebuilder'],
    ),
    Archetype(
      name: 'Sentinel',
      identity: 'Observer',
      strengths:
          "Spiritual sensitivity, Authority in prayer, Discernment, Faithfulness in hidden places",
      distortions:
          "Isolation; Pride in insight, Neglect of action; Fear of exposure",
      related: ['Watchman', 'Bridgebuilder'],
    ),
    Archetype(
      name: 'Bridgebuilder',
      identity: 'Connector',
      strengths: "Empathy; Peacemaking; Unifying diverse groups, Humility",
      distortions:
          "People-pleasing, Compromise; Avoidance of conflict, Loss of identity",
      related: ['Welcomer', 'Pillar', 'Sentinel'],
    ),
    Archetype(
      name: 'Healer',
      identity: 'Restorer',
      strengths: "Compassion; Presence in pain; Restorative faith; Patience",
      distortions:
          "Savior complex; Emotional detachment, Burnout, Avoidance of hard truths",
      related: ['Welcomer', 'Artisan', 'Cultivator'],
    ),
    Archetype(
      name: 'Harvester',
      identity: 'Gatherer',
      strengths:
          "Effectiveness, Joy in results, Mobilizing others, Celebration",
      distortions:
          "Exploitation; Obsession with metrics; Superficiality, Pride in results",
      related: ['Architect', 'Sower'],
    ),
    Archetype(
      name: 'Reformer',
      identity: 'Changer',
      strengths:
          "Righteous anger against injustice; Courage; Vision for transformation; Resilience",
      distortions: "Pride; Bitterness, Destructive rebellion, Idolizing change",
      related: ['Sower', 'Watchman'],
    ),
    Archetype(
      name: 'Architect',
      identity: 'Builder',
      strengths:
          "Integrity, Strategic thinking, Faithfulness, Ability to multiply and sustain",
      distortions:
          "Rigid systems; Excessive control disguised as order; Perfectionism that hinders growth; Inflexibility in methods",
      related: ['Harvester', 'Cultivator'],
    ),
  ];

  static const List<String> segmentColors = [
    '#e6dace',
    '#d2b48c',
    '#bca89f',
    '#a99a86',
    '#e6dace',
    '#d2b48c',
    '#bca89f',
    '#a99a86',
    '#e6dace',
    '#d2b48c',
    '#bca89f',
    '#a99a86',
  ];
}
