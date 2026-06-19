/// Denomination-agnostic Christian tradition classification.
///
/// All traditions are equal — none is privileged. Tradition only affects
/// suggestion ranking (which commitment plans to rank higher), default
/// prayer content, and companion character recommendation. App
/// functionality, community matching, and content access are identical
/// regardless of tradition.
enum ChristianTradition {
  catholic(
    label: 'Catholic',
    description: 'Rooted in the universal Church with apostolic succession, '
        'sacraments, and a rich liturgical tradition.',
    emphasizedPractices: [
      'Daily Mass or Communion',
      'Rosary and liturgical prayer',
      'Confession and spiritual direction',
      'Saints and Marian devotion',
      'Lectio Divina',
    ],
    commitmentSuggestions: [
      'Daily Mass reading reflection',
      'Rosary commitment',
      'Scripture study',
      'Corporal works of mercy',
    ],
  ),
  orthodox(
    label: 'Orthodox',
    description: 'Rooted in the Eastern Christian tradition with rich liturgy, '
        'iconography, and the Jesus Prayer tradition.',
    emphasizedPractices: [
      'Jesus Prayer',
      'Liturgical worship and icons',
      'Fasting discipline',
      'Prayer rope',
      'Philokalia tradition',
    ],
    commitmentSuggestions: [
      'Jesus Prayer commitment',
      'Icon reflection',
      'Fasting discipline',
      'Scripture reading',
    ],
  ),
  protestantMainline(
    label: 'Protestant (Mainline)',
    description: 'Methodist, Lutheran, Presbyterian, Anglican — '
        'historic Protestant traditions with structured liturgy and social witness.',
    emphasizedPractices: [
      'Sermon-based reflection',
      'Small groups and fellowship',
      'Sacramental worship',
      'Social justice engagement',
      'Daily devotional reading',
    ],
    commitmentSuggestions: [
      'Daily devotional reading',
      'Small group commitment',
      'Service and outreach',
      'Prayer journaling',
    ],
  ),
  protestantEvangelical(
    label: 'Protestant (Evangelical)',
    description: 'Baptist, Pentecostal, Nondenominational — '
        'emphasizing personal faith, Scripture authority, and evangelism.',
    emphasizedPractices: [
      'Personal Bible study',
      'Worship and praise',
      'Prayer and fasting',
      'Evangelism and outreach',
      'Accountability groups',
    ],
    commitmentSuggestions: [
      'Daily Bible reading plan',
      'Prayer and fasting',
      'Scripture memorization',
      'Evangelism commitment',
    ],
  ),
  protestantReformed(
    label: 'Protestant (Reformed)',
    description: 'Reformed and Presbyterian traditions emphasizing '
        'God\'s sovereignty, covenant theology, and expository preaching.',
    emphasizedPractices: [
      'Expository Bible study',
      'Catechism and confession study',
      'Covenantal family worship',
      'Sabbath observance',
      'Theological reading',
    ],
    commitmentSuggestions: [
      'Systematic Bible reading',
      'Catechism study',
      'Family worship',
      'Theological study',
    ],
  ),
  other(
    label: 'Other Christian',
    description: 'Another Christian tradition not listed above.',
    emphasizedPractices: [],
    commitmentSuggestions: [],
  ),
  exploring(
    label: 'Exploring',
    description: 'Curious about faith but not yet aligned with a specific tradition.',
    emphasizedPractices: [],
    commitmentSuggestions: [
      'Read the Gospels',
      'Try different prayer styles',
      'Explore a local church',
      'Ask faith questions with companion',
    ],
  );

  final String label;
  final String description;
  final List<String> emphasizedPractices;
  final List<String> commitmentSuggestions;

  const ChristianTradition({
    required this.label,
    required this.description,
    required this.emphasizedPractices,
    required this.commitmentSuggestions,
  });

  static ChristianTradition fromString(String value) {
    return ChristianTradition.values.firstWhere(
      (t) => t.name == value,
      orElse: () => ChristianTradition.exploring,
    );
  }
}
