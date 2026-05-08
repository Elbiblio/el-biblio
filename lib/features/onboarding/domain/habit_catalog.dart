/// Apple-level, deduped catalog of habits and struggles offered during
/// onboarding. Lists are intentionally finite — every entry names one
/// distinct behavior. No synonyms, no near-duplicates.
///
/// Keys are stable (snake_case) and safe to store to the backend.
/// Labels are UI copy; emojis are small cues, not decoration.
library;

class HabitOption {
  const HabitOption({
    required this.key,
    required this.label,
    required this.emoji,
    this.description,
  });

  final String key;
  final String label;
  final String emoji;
  final String? description;
}

/// Currently practiced virtues. The user may already be living any of
/// these — we want to *name* them, not prescribe them, so the first
/// signal they give the app is strength, not deficit.
const List<HabitOption> kGoodHabitOptions = <HabitOption>[
  HabitOption(
    key: 'daily_prayer',
    label: 'Daily prayer',
    emoji: '🙏',
  ),
  HabitOption(
    key: 'daily_scripture',
    label: 'Daily Scripture reading',
    emoji: '📖',
  ),
  HabitOption(
    key: 'weekly_worship',
    label: 'Weekly worship / communion',
    emoji: '⛪',
  ),
  HabitOption(
    key: 'fasting',
    label: 'Fasting',
    emoji: '🤍',
  ),
  HabitOption(
    key: 'generous_giving',
    label: 'Generous giving',
    emoji: '💛',
    description: 'Alms, tithes, offerings',
  ),
  HabitOption(
    key: 'hospitality',
    label: 'Hospitality',
    emoji: '🏡',
    description: 'Hosting, welcoming',
  ),
  HabitOption(
    key: 'discipleship',
    label: 'Discipleship / mentoring',
    emoji: '🌱',
  ),
  HabitOption(
    key: 'acts_of_service',
    label: 'Acts of service',
    emoji: '🤲',
  ),
  HabitOption(
    key: 'encouragement',
    label: 'Encouragement & kind words',
    emoji: '💬',
  ),
  HabitOption(
    key: 'sabbath_rest',
    label: 'Sabbath rest',
    emoji: '☀️',
  ),
  HabitOption(
    key: 'evangelism',
    label: 'Sharing faith',
    emoji: '📣',
  ),
  HabitOption(
    key: 'confession',
    label: 'Confession of sin',
    emoji: '🕊️',
  ),
  HabitOption(
    key: 'gratitude',
    label: 'Gratitude practice',
    emoji: '🌅',
  ),
  HabitOption(
    key: 'forgiveness',
    label: 'Forgiveness practice',
    emoji: '🌿',
  ),
];

/// Current struggles. Deduped — "sexual impurity" covers pornography,
/// lust, and viewing nudes as one moral axis. "Masturbation" is a
/// distinct behavior and stays separate. No loaded labels, no shaming.
const List<HabitOption> kStruggleOptions = <HabitOption>[
  HabitOption(
    key: 'sexual_impurity',
    label: 'Sexual impurity',
    emoji: '🔒',
    description: 'Pornography, lust, nudes',
  ),
  HabitOption(
    key: 'masturbation',
    label: 'Masturbation',
    emoji: '🫧',
  ),
  HabitOption(
    key: 'adultery',
    label: 'Adultery / infidelity',
    emoji: '💔',
  ),
  HabitOption(
    key: 'lying',
    label: 'Lying & deception',
    emoji: '🎭',
  ),
  HabitOption(
    key: 'gossip',
    label: 'Gossip & slander',
    emoji: '🗣️',
  ),
  HabitOption(
    key: 'pride',
    label: 'Pride & self-exaltation',
    emoji: '👑',
  ),
  HabitOption(
    key: 'anger',
    label: 'Anger & unforgiveness',
    emoji: '🔥',
  ),
  HabitOption(
    key: 'envy',
    label: 'Envy & coveting',
    emoji: '🪞',
  ),
  HabitOption(
    key: 'gluttony',
    label: 'Gluttony',
    emoji: '🍽️',
    description: 'Food, drink',
  ),
  HabitOption(
    key: 'drunkenness',
    label: 'Drunkenness & substance abuse',
    emoji: '🥃',
  ),
  HabitOption(
    key: 'greed',
    label: 'Greed & materialism',
    emoji: '💰',
  ),
  HabitOption(
    key: 'sloth',
    label: 'Laziness / sloth',
    emoji: '🛏️',
  ),
  HabitOption(
    key: 'gambling',
    label: 'Gambling',
    emoji: '🎲',
  ),
  HabitOption(
    key: 'endless_scrolling',
    label: 'Endless scrolling',
    emoji: '📱',
    description: 'Social media, news, reels',
  ),
  HabitOption(
    key: 'gaming_excess',
    label: 'Gaming excess',
    emoji: '🎮',
  ),
];

/// Look up an option by key across either list. Used when rendering a
/// saved selection without rerunning the whole question.
HabitOption? habitOptionByKey(String key) {
  for (final o in kGoodHabitOptions) {
    if (o.key == key) return o;
  }
  for (final o in kStruggleOptions) {
    if (o.key == key) return o;
  }
  return null;
}

/// Stable key-sets for validation at storage boundaries. Any saved key not
/// in these sets is treated as stale (catalog entry renamed/removed) and
/// dropped on rehydrate rather than surfaced as an unrenderable option.
final Set<String> kGoodHabitKeys = {
  for (final o in kGoodHabitOptions) o.key,
};

final Set<String> kStruggleKeys = {
  for (final o in kStruggleOptions) o.key,
};
