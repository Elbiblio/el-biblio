import '../models/meditation_enums.dart';
import '../models/meditation_guide.dart';

/// Builds a [MeditationGuide] for a given style, level, and configuration.
///
/// Port of the old MeditationOrchestrator.buildGuide static method.
class MeditationGuideBuilder {
  const MeditationGuideBuilder._();

  static MeditationLevel determineLevel({
    required int sessionCount,
    int? selectedMinutes,
  }) {
    if (selectedMinutes == null || sessionCount <= 2) {
      return MeditationLevel.foundation;
    }
    if (selectedMinutes >= 25 || sessionCount >= 8) {
      return MeditationLevel.deep;
    }
    return MeditationLevel.growth;
  }

  static MeditationGuide build({
    required MeditationStyle style,
    int? selectedMinutes,
    int sessionCount = 0,
    String? virtueName,
    String? centeringWord,
  }) {
    switch (style) {
      case MeditationStyle.centering:
        return _buildCentering(centeringWord);
      case MeditationStyle.jesusPrayer:
        return _buildJesusPrayer();
      case MeditationStyle.chant:
        return _buildChant();
      case MeditationStyle.virtue:
        return _buildVirtue(virtueName, sessionCount, selectedMinutes);
      case MeditationStyle.parable:
        return _buildParable(sessionCount, selectedMinutes);
    }
  }

  static MeditationGuide _buildCentering(String? centeringWord) {
    final word = (centeringWord ?? 'Jesus').trim();
    return MeditationGuide(
      title: 'Centering Prayer',
      imagery:
          'Choose a sacred word and rest quietly before God, letting the word '
          'return you to His presence whenever thoughts wander.',
      scripture: '',
      prompts: [
        'Sacred word anchoring your attention',
        'Opening to God beyond thoughts and emotions',
        'Practicing gentle surrender when distractions appear',
      ],
      declaration:
          'Return gently to your word whenever you are distracted.',
      leadIn:
          'Settle your body. Allow your breath to find a natural rhythm.',
      focus: 'Sacred word: $word',
      breathInvitation:
          "Breathe slowly and let your word bring you back to God's presence.",
      closingReminder:
          'Close with gratitude for any subtle movements of the heart.',
      openReflection:
          'Let your sacred word anchor your attitude and attention.',
      guidanceTips: [
        'Let your sacred word anchor your attitude and attention.',
        'Gently repeat your sacred word whenever you notice your attention drifting.',
        'Close with gratitude, acknowledging any subtle movements of the heart.',
      ],
    );
  }

  static MeditationGuide _buildJesusPrayer() {
    return const MeditationGuide(
      title: 'Jesus Prayer',
      imagery:
          'Pray the ancient phrase in rhythm with your breath.',
      scripture: '',
      prompts: [
        'Breathing in the first half of the prayer',
        'Breathing out the second half of the prayer',
        'Leaning into mercy and compassion',
      ],
      declaration: 'Have mercy on me, a sinner.',
      leadIn:
          'Match the prayer with your inhale and exhale gently.',
      focus: '"Lord Jesus Christ, Son of God, have mercy on me."',
      breathInvitation:
          'Inhale the first half, exhale the second half of the prayer.',
      closingReminder:
          'Carry mercy with you into your next steps.',
      openReflection:
          'Match the words to your inhale and exhale gently.',
      guidanceTips: [
        'Match the words to your inhale and exhale gently.',
        'If distractions come, return to the rhythm without judgment.',
        'Consider dedicating the prayer to someone who needs mercy.',
      ],
    );
  }

  static MeditationGuide _buildChant() {
    return const MeditationGuide(
      title: 'Chant',
      imagery:
          'Repeat short chants or scriptures set to simple melodies.',
      scripture: '',
      prompts: ['Singing is a deeper form of prayer'],
      declaration: 'Meditate on the words',
      leadIn: 'Begin',
      focus: '',
      guidanceTips: [
        'Sing quietly or hum along in prayer.',
        'Let the refrain linger.',
        'Close by resting in silence.',
      ],
    );
  }

  static MeditationGuide _buildVirtue(
    String? virtueName,
    int sessionCount,
    int? selectedMinutes,
  ) {
    final v = virtueName ?? 'this virtue';
    final level = determineLevel(
      sessionCount: sessionCount,
      selectedMinutes: selectedMinutes,
    );

    final stageNote = switch (level) {
      MeditationLevel.foundation =>
        'You are building a foundation. Let the virtue settle into your awareness.',
      MeditationLevel.growth =>
        'You are growing. Notice how this virtue shows up in your daily choices.',
      MeditationLevel.deep =>
        'You are deepening. Invite the Holy Spirit to reveal hidden areas.',
    };

    return MeditationGuide(
      title: 'Growing in ${v[0].toUpperCase()}${v.substring(1)}',
      imagery: 'Focus your heart on $v and invite God to shape you.',
      scripture: '',
      prompts: [
        'Where in my life am I lacking the most in $v?',
        'What can I do today to grow and improve in $v?',
        'Thank you Jesus for helping me acknowledge my deficiencies in $v, '
            'may the grace and strength of your Spirit renew me today to '
            'imitate you in $v. Amen.',
      ],
      declaration: 'I choose to grow in $v today, by the grace of God.',
      leadIn: 'Take a moment to quiet your mind and focus on $v.',
      focus: 'Let $v become the lens through which you see today.',
      breathInvitation: 'Breathe in God\'s grace for $v. Breathe out resistance.',
      closingReminder:
          'Carry this virtue with you. Let it shape one decision today.',
      stageNote: stageNote,
      openReflection:
          'Notice how $v connects with your life right now.',
    );
  }

  static MeditationGuide _buildParable(
    int sessionCount,
    int? selectedMinutes,
  ) {
    final level = determineLevel(
      sessionCount: sessionCount,
      selectedMinutes: selectedMinutes,
    );

    // Rotate through a small set of parables based on session count
    const parables = _parablePool;
    final index = sessionCount % parables.length;
    final parable = parables[index];

    final stageNote = switch (level) {
      MeditationLevel.foundation =>
        'Let the story speak to you simply. Do not rush to interpret.',
      MeditationLevel.growth =>
        'Notice the characters. Which one mirrors your season?',
      MeditationLevel.deep =>
        'Sit with the tension in the story. What is Jesus revealing?',
    };

    return MeditationGuide(
      title: parable.title,
      imagery: parable.overview,
      scripture: parable.scripture,
      prompts: parable.prompts.take(2).toList(),
      declaration: parable.closingReminder,
      leadIn: 'Spend a moment with the ${parable.title}. ${parable.overview}',
      focus: parable.breathInvitation,
      breathInvitation: parable.breathInvitation,
      closingReminder: parable.closingReminder,
      stageNote: stageNote,
      openReflection: parable.openReflection,
    );
  }
}

// ---------------------------------------------------------------------------
// Lightweight parable data (replaces the large parableMeditations.ts import)
// ---------------------------------------------------------------------------

class _ParableData {
  const _ParableData({
    required this.title,
    required this.scripture,
    required this.overview,
    required this.breathInvitation,
    required this.prompts,
    required this.closingReminder,
    required this.openReflection,
  });

  final String title;
  final String scripture;
  final String overview;
  final String breathInvitation;
  final List<String> prompts;
  final String closingReminder;
  final String openReflection;
}

const _parablePool = <_ParableData>[
  _ParableData(
    title: 'The Good Samaritan',
    scripture: 'Luke 10:25-37',
    overview:
        'A man is beaten and left on the road. Religious leaders pass by, '
        'but a Samaritan stops to help.',
    breathInvitation:
        'Breathe in compassion. Breathe out indifference.',
    prompts: [
      'Who is the wounded person in your life right now?',
      'What keeps you from stopping to help?',
      'How can you be a neighbour today?',
      'What does mercy look like in your context?',
    ],
    closingReminder: 'Go and do likewise.',
    openReflection:
        'Notice which character you identify with most today.',
  ),
  _ParableData(
    title: 'The Prodigal Son',
    scripture: 'Luke 15:11-32',
    overview:
        'A son squanders his inheritance, returns home, and is welcomed '
        'with open arms by his father.',
    breathInvitation:
        'Breathe in the Father\'s welcome. Breathe out shame.',
    prompts: [
      'Where have you wandered from the Father?',
      'What prevents you from coming home?',
      'Can you receive extravagant grace today?',
      'Are you the younger son or the elder brother?',
    ],
    closingReminder:
        'The Father runs to meet you. Receive His embrace.',
    openReflection:
        'Which part of the story stirs the strongest emotion?',
  ),
  _ParableData(
    title: 'The Sower',
    scripture: 'Matthew 13:1-23',
    overview:
        'A farmer scatters seed on different soils — path, rocky ground, '
        'thorns, and good soil.',
    breathInvitation:
        'Breathe in receptivity. Breathe out distraction.',
    prompts: [
      'What kind of soil is your heart today?',
      'What thorns are choking the word in your life?',
      'How can you cultivate good soil this week?',
      'What fruit is God growing in you right now?',
    ],
    closingReminder:
        'Tend the soil of your heart. The seed is already planted.',
    openReflection:
        'Be honest about which soil describes your current season.',
  ),
  _ParableData(
    title: 'The Mustard Seed',
    scripture: 'Matthew 13:31-32',
    overview:
        'The kingdom of heaven is like a mustard seed — the smallest of '
        'seeds, yet it grows into the largest of garden plants.',
    breathInvitation:
        'Breathe in faith. Breathe out doubt.',
    prompts: [
      'What small act of faith is God asking of you?',
      'Where do you see tiny seeds of the Kingdom growing?',
      'Can you trust God with the growth timeline?',
      'What would it look like to plant one seed today?',
    ],
    closingReminder:
        'Small beginnings lead to great things in God\'s hands.',
    openReflection:
        'Consider the smallest good thing happening in your life.',
  ),
  _ParableData(
    title: 'The Lost Sheep',
    scripture: 'Luke 15:1-7',
    overview:
        'A shepherd leaves ninety-nine sheep to find the one that is lost, '
        'and rejoices when it is found.',
    breathInvitation:
        'Breathe in belonging. Breathe out isolation.',
    prompts: [
      'Do you feel like the one who wandered or the ninety-nine?',
      'Where is the Good Shepherd searching for you?',
      'Who in your life needs to know they are sought after?',
      'Can you let yourself be found today?',
    ],
    closingReminder:
        'You are worth the search. Heaven rejoices over you.',
    openReflection:
        'Let the image of the shepherd carrying you settle in.',
  ),
  _ParableData(
    title: 'The Talents',
    scripture: 'Matthew 25:14-30',
    overview:
        'A master entrusts talents to three servants. Two invest wisely; '
        'one buries his out of fear.',
    breathInvitation:
        'Breathe in courage. Breathe out fear of failure.',
    prompts: [
      'What has God entrusted to you?',
      'Are you investing or burying your gifts?',
      'What fear holds you back from stepping out?',
      'How can you be faithful with what you have today?',
    ],
    closingReminder:
        'Well done, good and faithful servant. Enter into joy.',
    openReflection:
        'Identify one gift you have been hesitant to use.',
  ),
];
