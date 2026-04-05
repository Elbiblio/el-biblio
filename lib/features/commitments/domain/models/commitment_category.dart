import 'dart:ui';

/// The three commitment categories aligned with spiritual identity.
///
/// Each category represents a different approach to spiritual growth:
/// - **Growth**: Build spiritual muscle through learning and deepening faith
/// - **Discipline**: Build structure and order to create space for clarity
/// - **Charity**: Fight addiction through grace, service, and generosity
///
/// Key insight: Discipline alone does not conquer addiction — grace and
/// sincere commitment do. Charity teaches patience and helps obtain
/// graces and blessings to aid the journey.
enum CommitmentCategory {
  growth(
    label: 'Growth',
    icon: '\u{1F331}', // seedling
    color: Color(0xFF4CAF50),
    description: 'Build spiritual muscle through learning, prayer, and deepening your faith.',
    tagline: 'Grow into who God made you to be.',
    completionMessage: 'You are growing stronger in the Spirit. Keep pressing in — God is doing a deep work in you.',
    failureMessage: 'Growth is not a straight line. Every setback is a setup for a deeper root. Try again tomorrow.',
  ),
  discipline(
    label: 'Discipline',
    icon: '\u{1F6E1}', // shield
    color: Color(0xFF2196F3),
    description: 'Build structure and order in your life so spiritual clarity can thrive.',
    tagline: 'Order your life so clarity can thrive.',
    completionMessage: 'Structure creates freedom. You are building a life that makes room for God\'s voice.',
    failureMessage: 'Discipline bends before it breaks. Rest today, and rebuild the wall tomorrow. God is your strength.',
  ),
  charity(
    label: 'Charity',
    icon: '\u{1F49B}', // yellow heart
    color: Color(0xFFFF9800),
    description: 'Fight addiction through grace, generosity, and sincere commitment to stop. Charity teaches patience and helps obtain graces and blessings.',
    tagline: 'Grace conquers what discipline alone cannot.',
    completionMessage: 'Every act of charity plants a seed of freedom. Grace is working in you — you are not alone in this fight.',
    failureMessage: 'Addiction fights hard, but God fights harder. Rest in His grace today. Your sincere desire to stop is already a victory.',
  );

  final String label;
  final String icon;
  final Color color;
  final String description;
  final String tagline;
  final String completionMessage;
  final String failureMessage;

  const CommitmentCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.tagline,
    required this.completionMessage,
    required this.failureMessage,
  });

  static CommitmentCategory fromString(String value) {
    return CommitmentCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CommitmentCategory.growth,
    );
  }

  /// Returns the recommended starting category for a given archetype.
  ///
  /// Archetypes prone to addiction/compulsion patterns start with Charity.
  /// Archetypes prone to disorder/chaos start with Discipline.
  /// Others default to Growth.
  static CommitmentCategory recommendedForArchetype(String archetypeName) {
    return switch (archetypeName) {
      // Charity-first: archetypes whose distortions involve addiction patterns
      'Artisan' => CommitmentCategory.charity, // novelty addiction, validation seeking
      'Harvester' => CommitmentCategory.charity, // metrics obsession, workaholism
      'Reformer' => CommitmentCategory.charity, // outrage addiction, bitterness
      'Healer' => CommitmentCategory.charity, // savior complex, emotional numbing
      // Discipline-first: archetypes whose distortions involve disorder or avoidance
      'Sower' => CommitmentCategory.discipline, // impulsiveness, shallow roots
      'Bridgebuilder' => CommitmentCategory.discipline, // people-pleasing, identity loss
      'Welcomer' => CommitmentCategory.discipline, // people-pleasing, self-neglect
      // Growth-first: archetypes who benefit from deepening before structuring
      'Watchman' => CommitmentCategory.growth, // needs mercy and grace understanding
      'Cultivator' => CommitmentCategory.growth, // needs to trust God's timing
      'Pillar' => CommitmentCategory.growth, // needs to discover own calling
      'Sentinel' => CommitmentCategory.growth, // needs to move from insight to action
      'Architect' => CommitmentCategory.growth, // needs to release control to God
      _ => CommitmentCategory.growth,
    };
  }
}
