/// The 7 cardinal vices (capital sins) with their modern manifestations.
///
/// Each vice represents a fundamental distortion of desire that, when
/// unchecked, produces specific modern behavioral patterns (addictions,
/// compulsions, avoidance strategies). The opposing virtue is the path
/// of grace that redeems the distorted desire.
enum CardinalVice {
  pride(
    label: 'Pride',
    latinName: 'Superbia',
    opposingVirtue: 'Humility',
    description:
        'Disordered self-love that places oneself above God and others. '
        'Manifests as vanity, perfectionism, spiritual superiority, '
        'and the need to be seen.',
    modernManifestations: [
      'Social media vanity and image curation',
      'Spiritual superiority and judgmentalism',
      'Perfectionism that paralyzes obedience',
      'Self-promotion and personal branding obsession',
      'Savior complex — needing to be the hero',
      'Resistance to correction or feedback',
    ],
  ),
  greed(
    label: 'Greed',
    latinName: 'Avaritia',
    opposingVirtue: 'Generosity',
    description:
        'Insatiable desire for more — whether money, power, status, '
        'or control. Manifests as workaholism, exploitation, and hoarding.',
    modernManifestations: [
      'Workaholism disguised as ambition or calling',
      'Metrics obsession — followers, productivity stats, KPIs',
      'Hoarding information, resources, or relationships',
      'Materialism and lifestyle inflation',
      'Control addiction — needing every detail managed',
      'Exploitation of relationships for personal gain',
    ],
  ),
  lust(
    label: 'Lust',
    latinName: 'Luxuria',
    opposingVirtue: 'Chastity',
    description:
        'Disordered desire for pleasure and stimulation beyond what is '
        'ordered. Manifests as pornography, novelty addiction, and '
        'validation seeking.',
    modernManifestations: [
      'Pornography and sexual content consumption',
      'Novelty and stimulation addiction — chasing the next high',
      'Validation seeking through likes, comments, and attention',
      'Entertainment binging and content overconsumption',
      'Romantic fantasizing as escape from reality',
      'Using relationships for emotional stimulation rather than love',
    ],
  ),
  envy(
    label: 'Envy',
    latinName: 'Invidia',
    opposingVirtue: 'Kindness',
    description:
        'Sorrow at another\'s good fortune and resentment of their gifts. '
        'Manifests as comparison, gossip, and subtle sabotage.',
    modernManifestations: [
      'Comparison scrolling on social media',
      'Resentment toward those who receive recognition',
      'Status anxiety and keeping up appearances',
      'Gossip and tearing down others\' reputations',
      'Inability to celebrate others\' success genuinely',
      'Passive-aggressive undermining of peers',
    ],
  ),
  gluttony(
    label: 'Gluttony',
    latinName: 'Gula',
    opposingVirtue: 'Temperance',
    description:
        'Disordered consumption — seeking comfort through excess. '
        'Manifests as overeating, substance abuse, and emotional numbing '
        'through overconsumption.',
    modernManifestations: [
      'Comfort eating and emotional eating patterns',
      'Shopping addiction and retail therapy',
      'Overconsumption of digital content (doom-binging)',
      'Substance abuse — alcohol, drugs, nicotine',
      'Emotional numbing through entertainment or food',
      'Excessive comfort-seeking as avoidance of growth',
    ],
  ),
  wrath(
    label: 'Wrath',
    latinName: 'Ira',
    opposingVirtue: 'Patience',
    description:
        'Uncontrolled anger that seeks destruction rather than justice. '
        'Manifests as outrage addiction, bitterness, and judgmental behavior.',
    modernManifestations: [
      'Outrage addiction — always seeking the next injustice to fight',
      'Doomscrolling through negative news feeds',
      'Judgmental monitoring of others\' behavior online',
      'Bitterness toward institutions, leaders, or systems',
      'Road rage and disproportionate anger at small offenses',
      'Social media pile-ons and cancel culture participation',
    ],
  ),
  sloth(
    label: 'Sloth',
    latinName: 'Acedia',
    opposingVirtue: 'Diligence',
    description:
        'Spiritual apathy and avoidance of the good. Not mere laziness, '
        'but a deeper resistance to spiritual effort. Manifests as '
        'people-pleasing, conflict avoidance, and passive consumption.',
    modernManifestations: [
      'People-pleasing as avoidance of authentic engagement',
      'Conflict avoidance at the cost of truth',
      'Passive content consumption without application',
      'Procrastination of spiritual disciplines',
      'Identity diffusion — losing yourself in others\' expectations',
      'Scrolling as avoidance of silence and self-reflection',
    ],
  );

  final String label;
  final String latinName;
  final String opposingVirtue;
  final String description;
  final List<String> modernManifestations;

  const CardinalVice({
    required this.label,
    required this.latinName,
    required this.opposingVirtue,
    required this.description,
    required this.modernManifestations,
  });
}
