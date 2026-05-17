import '../domain/models/daily_anchors.dart';
import '../domain/models/commitment.dart';

/// Offline fallback commitments for each virtue type
/// These are used when the API is unavailable
class OfflineCommitmentData {
  static const List<Map<String, dynamic>> _humilityCommitments = [
    {
      'id': -101,
      'title': 'Listen Before Speaking',
      'description':
          'Ask one clarifying question before you share your own view.',
      'tips': [
        'Take a breath before responding',
        'Count to 3 before speaking',
        'Focus on understanding rather than waiting to talk',
        'Ask "What did you mean by that?" or "Can you explain more?"',
      ],
      'durationMinutes': 0,
      'categoryTags': ['communication', 'listening', 'humility'],
      'difficultyLevel': 1,
      'themeId': 1,
    },
    {
      'id': -102,
      'title': 'Let Others Finish',
      'description':
          'Let the other person finish their story before you respond.',
      'tips': [
        'Resist the urge to interrupt with your own story',
        'Nod and maintain eye contact to show you\'re listening',
        'Wait for a natural pause before speaking',
        'Summarize what they said to show you understood',
      ],
      'durationMinutes': 0,
      'categoryTags': ['communication', 'patience', 'humility'],
      'difficultyLevel': 1,
      'themeId': 1,
    },
    {
      'id': -103,
      'title': 'Notice Quiet Efforts',
      'description':
          'Thank someone for a small, often unnoticed contribution today.',
      'durationMinutes': 0,
      'categoryTags': ['gratitude', 'awareness', 'humility'],
      'difficultyLevel': 1,
      'themeId': 1,
    },
    {
      'id': -104,
      'title': 'Give Credit Publicly',
      'description':
          'When sharing progress, name who helped you and what they did.',
      'durationMinutes': 0,
      'categoryTags': ['recognition', 'service', 'humility'],
      'difficultyLevel': 2,
      'themeId': 1,
    },
    {
      'id': -105,
      'title': 'Apologize Quickly',
      'description':
          'If you interrupt or misstep, say "Sorry about that" and let them continue.',
      'durationMinutes': 0,
      'categoryTags': ['communication', 'repair', 'humility'],
      'difficultyLevel': 2,
      'themeId': 1,
    },
    {
      'id': -106,
      'title': 'Ask Before Advising',
      'description':
          'Before giving advice, ask "Do you want advice or just a listener?"',
      'durationMinutes': 0,
      'categoryTags': ['listening', 'respect', 'humility'],
      'difficultyLevel': 2,
      'themeId': 1,
    },
    {
      'id': -107,
      'title': 'Take the Unglamorous Task',
      'description':
          'Pick up one unglamorous task today and do it well without announcement.',
      'durationMinutes': 0,
      'categoryTags': ['service', 'initiative', 'humility'],
      'difficultyLevel': 3,
      'themeId': 1,
    },
    {
      'id': -108,
      'title': 'Invite Feedback',
      'description':
          'Ask someone you trust, "Anything I could do better?" and listen fully.',
      'durationMinutes': 0,
      'categoryTags': ['feedback', 'growth', 'humility'],
      'difficultyLevel': 3,
      'themeId': 1,
    },
    {
      'id': -109,
      'title': 'Do the Unwanted Chore',
      'description':
          'Handle a task others avoid (dishes, cleanup, tidying) without seeking notice.',
      'durationMinutes': 0,
      'categoryTags': ['service', 'selflessness', 'humility'],
      'difficultyLevel': 3,
      'themeId': 1,
    },
    {
      'id': -110,
      'title': 'Own a Mistake',
      'description':
          'Admit one mistake today and state how you will fix or prevent it.',
      'durationMinutes': 0,
      'categoryTags': ['accountability', 'honesty', 'humility'],
      'difficultyLevel': 4,
      'themeId': 1,
    },
    {
      'id': -111,
      'title': 'Let Others Choose',
      'description':
          'Let someone else choose the plan or option today without pushback.',
      'durationMinutes': 0,
      'categoryTags': ['flexibility', 'preference', 'humility'],
      'difficultyLevel': 4,
      'themeId': 1,
    },
    {
      'id': -112,
      'title': 'Reflect Before Defending',
      'description':
          'In a disagreement, reflect back what you heard before sharing your side.',
      'durationMinutes': 0,
      'categoryTags': ['conflict', 'listening', 'humility'],
      'difficultyLevel': 4,
      'themeId': 1,
    },
    {
      'id': -113,
      'title': 'Share a Failure Lesson',
      'description':
          'Share a recent failure and the lesson you learned to help others.',
      'durationMinutes': 0,
      'categoryTags': ['growth', 'transparency', 'humility'],
      'difficultyLevel': 5,
      'themeId': 1,
    },
    {
      'id': -114,
      'title': 'Ask for Help Openly',
      'description': 'Ask for help with a weakness you usually hide.',
      'durationMinutes': 0,
      'categoryTags': ['vulnerability', 'support', 'humility'],
      'difficultyLevel': 5,
      'themeId': 1,
    },
    {
      'id': -115,
      'title': 'Make Amends',
      'description':
          'Apologize for a past hurt and ask what you can do to repair it.',
      'durationMinutes': 0,
      'categoryTags': ['repair', 'forgiveness', 'humility'],
      'difficultyLevel': 5,
      'themeId': 1,
    },
    {
      'id': -116,
      'title': 'Arrive Early to Serve',
      'description':
          'Be the first to arrive ready to serve and volunteer early for the tasks others avoid.',
      'durationMinutes': 0,
      'categoryTags': ['service', 'initiative', 'humility'],
      'difficultyLevel': 3,
      'themeId': 1,
    },
    {
      'id': -117,
      'title': 'Listen, Remember, Pray',
      'description':
          'Listen throughout the day, remember any feedback, pray for insight, and respond with God-honoring respect.',
      'durationMinutes': 0,
      'categoryTags': ['listening', 'reflection', 'humility'],
      'difficultyLevel': 4,
      'themeId': 1,
    },
  ];

  static const List<Map<String, dynamic>> _loveCommitments = [
    {
      'id': -201,
      'title': 'Notice Someone\'s Effort',
      'description': 'Thank someone today for a specific effort they made.',
      'tips': [
        'Be specific about what you noticed',
        'Explain the impact their effort had',
        'Choose timing that feels natural',
        'Avoid making it about yourself - keep focus on them',
      ],
      'durationMinutes': 0,
      'categoryTags': ['gratitude', 'recognition', 'love'],
      'difficultyLevel': 1,
      'themeId': 2,
    },
    {
      'id': -202,
      'title': 'Send Encouragement',
      'description':
          'Send a brief message telling someone one thing you appreciate about them.',
      'durationMinutes': 0,
      'categoryTags': ['encouragement', 'relationship', 'love'],
      'difficultyLevel': 1,
      'themeId': 2,
    },
    {
      'id': -203,
      'title': 'Small Act of Care',
      'description':
          'Do one small act that makes someone\'s day easier (prep, tidy, carry).',
      'durationMinutes': 0,
      'categoryTags': ['service', 'kindness', 'love'],
      'difficultyLevel': 1,
      'themeId': 2,
    },
    {
      'id': -204,
      'title': 'Listen Without Fixing',
      'description':
          'When someone vents, listen and reflect back instead of offering solutions.',
      'durationMinutes': 0,
      'categoryTags': ['listening', 'empathy', 'love'],
      'difficultyLevel': 2,
      'themeId': 2,
    },
    {
      'id': -205,
      'title': 'Be Fully Present',
      'description':
          'During one conversation, keep your phone away and stay fully present.',
      'durationMinutes': 0,
      'categoryTags': ['presence', 'attention', 'love'],
      'difficultyLevel': 2,
      'themeId': 2,
    },
    {
      'id': -206,
      'title': 'Speak Gently',
      'description':
          'If tension rises today, lower your voice and choose gentle words.',
      'durationMinutes': 0,
      'categoryTags': ['communication', 'patience', 'love'],
      'difficultyLevel': 2,
      'themeId': 2,
    },
    {
      'id': -207,
      'title': 'Advocate for Someone',
      'description':
          'Recommend or back someone for credit or an opportunity today.',
      'durationMinutes': 0,
      'categoryTags': ['support', 'advocacy', 'love'],
      'difficultyLevel': 3,
      'themeId': 2,
    },
    {
      'id': -208,
      'title': 'Assume Positive Intent',
      'description':
          'When someone\'s action annoys you, choose a kind interpretation and respond kindly.',
      'durationMinutes': 0,
      'categoryTags': ['charity', 'interpretation', 'love'],
      'difficultyLevel': 3,
      'themeId': 2,
    },
    {
      'id': -209,
      'title': 'Do Their Least Favorite Task',
      'description':
          'Handle a task someone close to you dislikes to lighten their load.',
      'durationMinutes': 0,
      'categoryTags': ['service', 'sacrifice', 'love'],
      'difficultyLevel': 3,
      'themeId': 2,
    },
    {
      'id': -210,
      'title': 'Bridge a Conflict',
      'description':
          'Initiate a calm, solution-focused conversation between people who are misaligned.',
      'durationMinutes': 0,
      'categoryTags': ['peacemaking', 'mediation', 'love'],
      'difficultyLevel': 4,
      'themeId': 2,
    },
    {
      'id': -211,
      'title': 'Include the Overlooked',
      'description': 'Invite someone who\'s often overlooked to join in today.',
      'durationMinutes': 0,
      'categoryTags': ['inclusion', 'kindness', 'love'],
      'difficultyLevel': 4,
      'themeId': 2,
    },
    {
      'id': -212,
      'title': 'Pause Before Reacting',
      'description': 'When conflict sparks, pause, pray, and respond gently.',
      'durationMinutes': 0,
      'categoryTags': ['patience', 'self-control', 'love'],
      'difficultyLevel': 4,
      'themeId': 2,
    },
    {
      'id': -213,
      'title': 'Show Grace to Opposition',
      'description':
          'Do one kind, helpful act today for someone you normally disagree with.',
      'durationMinutes': 0,
      'categoryTags': ['grace', 'reconciliation', 'love'],
      'difficultyLevel': 5,
      'themeId': 2,
    },
    {
      'id': -214,
      'title': 'Repair a Strained Relationship',
      'description':
          'Send a sincere note to someone you\'re distant from, inviting a low-pressure reconnect.',
      'durationMinutes': 0,
      'categoryTags': ['healing', 'connection', 'love'],
      'difficultyLevel': 5,
      'themeId': 2,
    },
    {
      'id': -215,
      'title': 'Ask How to Make Amends',
      'description':
          'Ask someone you\'ve hurt, "What would help us heal this?" and do it.',
      'durationMinutes': 0,
      'categoryTags': ['reconciliation', 'service', 'love'],
      'difficultyLevel': 5,
      'themeId': 2,
    },
    {
      'id': -216,
      'title': 'Greet with Genuine Care',
      'description':
          'Observe and greet each person you encounter with genuine interest in their well-being.',
      'durationMinutes': 0,
      'categoryTags': ['kindness', 'presence', 'love'],
      'difficultyLevel': 2,
      'themeId': 2,
    },
    {
      'id': -217,
      'title': 'Gift for the Overlooked',
      'description':
          'Buy a small, thoughtful item for a seldom-seen coworker to encourage them quietly.',
      'durationMinutes': 0,
      'categoryTags': ['generosity', 'encouragement', 'love'],
      'difficultyLevel': 3,
      'themeId': 2,
    },
  ];

  static const List<Map<String, dynamic>> _faithCommitments = [
    {
      'id': -301,
      'title': 'Start with Trust',
      'description':
          'Before a task today, pause and entrust the outcome to God in a brief prayer.',
      'tips': [
        'Keep it simple - just 10-15 seconds',
        'Focus on surrender, not control',
        'Trust that God is working even when you can\'t see it',
        'Return to trust if anxiety rises during the task',
      ],
      'durationMinutes': 0,
      'categoryTags': ['prayer', 'trust', 'faith'],
      'difficultyLevel': 1,
      'themeId': 3,
    },
    {
      'id': -302,
      'title': 'Gratitude Pause',
      'description':
          'Take a short pause today to thank God for three things you notice.',
      'durationMinutes': 0,
      'categoryTags': ['gratitude', 'awareness', 'faith'],
      'difficultyLevel': 1,
      'themeId': 3,
    },
    {
      'id': -303,
      'title': 'Pray for Loved Ones',
      'description':
          'Say a brief prayer for the people closest to you before you start your day.',
      'durationMinutes': 0,
      'categoryTags': ['prayer', 'care', 'faith'],
      'difficultyLevel': 1,
      'themeId': 3,
    },
    {
      'id': -304,
      'title': 'Trust in Delays',
      'description':
          'When a delay happens today, pray instead of complaining and look for what you can learn.',
      'durationMinutes': 0,
      'categoryTags': ['patience', 'trust', 'faith'],
      'difficultyLevel': 2,
      'themeId': 3,
    },
    {
      'id': -305,
      'title': 'Act on a Nudge',
      'description':
          'Follow through on a small prompting today—call, text, or help someone.',
      'durationMinutes': 0,
      'categoryTags': ['obedience', 'service', 'faith'],
      'difficultyLevel': 2,
      'themeId': 3,
    },
    {
      'id': -306,
      'title': 'Share Gratitude Aloud',
      'description':
          'At a meal or moment together, share one way you saw God\'s goodness today.',
      'durationMinutes': 0,
      'categoryTags': ['gratitude', 'community', 'faith'],
      'difficultyLevel': 2,
      'themeId': 3,
    },
    {
      'id': -307,
      'title': 'Pray Before Decisions',
      'description':
          'Pray briefly before one key decision today, asking for wisdom and peace.',
      'durationMinutes': 0,
      'categoryTags': ['discernment', 'prayer', 'faith'],
      'difficultyLevel': 3,
      'themeId': 3,
    },
    {
      'id': -308,
      'title': 'Choose Faith Over Worry',
      'description':
          'When worry surfaces today, replace it with a short prayer of trust.',
      'durationMinutes': 0,
      'categoryTags': ['trust', 'prayer', 'faith'],
      'difficultyLevel': 3,
      'themeId': 3,
    },
    {
      'id': -309,
      'title': 'Surrender Control',
      'description':
          'Name one situation you can\'t control and pray, handing it to God.',
      'durationMinutes': 0,
      'categoryTags': ['surrender', 'trust', 'faith'],
      'difficultyLevel': 3,
      'themeId': 3,
    },
    {
      'id': -310,
      'title': 'Integrity Under Pressure',
      'description':
          'Make an honest choice today even if cutting corners would be easier.',
      'durationMinutes': 0,
      'categoryTags': ['integrity', 'courage', 'faith'],
      'difficultyLevel': 4,
      'themeId': 3,
    },
    {
      'id': -311,
      'title': 'Quiet Time Break',
      'description':
          'Take a 10-minute pause today to read a verse and pray, even if the day is busy.',
      'durationMinutes': 0,
      'categoryTags': ['devotion', 'rest', 'faith'],
      'difficultyLevel': 4,
      'themeId': 3,
    },
    {
      'id': -312,
      'title': 'Pray Together',
      'description':
          'Offer a short prayer aloud with someone close to you today for a shared need.',
      'durationMinutes': 0,
      'categoryTags': ['community', 'prayer', 'faith'],
      'difficultyLevel': 4,
      'themeId': 3,
    },
    {
      'id': -313,
      'title': 'Costly Integrity',
      'description':
          'Choose the truthful, ethical path today even if it risks approval or speed.',
      'durationMinutes': 0,
      'categoryTags': ['courage', 'ethics', 'faith'],
      'difficultyLevel': 5,
      'themeId': 3,
    },
    {
      'id': -314,
      'title': 'Sacrificial Generosity',
      'description':
          'Give time or money today in a way you feel, trusting God to provide.',
      'durationMinutes': 0,
      'categoryTags': ['generosity', 'trust', 'faith'],
      'difficultyLevel': 5,
      'themeId': 3,
    },
    {
      'id': -315,
      'title': 'Lead a Prayer',
      'description':
          'Initiate a brief prayer with others today, even if it feels uncomfortable.',
      'durationMinutes': 0,
      'categoryTags': ['leadership', 'prayer', 'faith'],
      'difficultyLevel': 5,
      'themeId': 3,
    },
  ];

  static const List<Map<String, dynamic>> _knowledgeCommitments = [
    {
      'id': -401,
      'title': 'Ask One More Question',
      'description':
          'Ask one extra question to fully understand before deciding.',
      'durationMinutes': 0,
      'categoryTags': ['curiosity', 'clarity', 'knowledge'],
      'difficultyLevel': 1,
      'themeId': 4,
    },
    {
      'id': -402,
      'title': 'Learn a Small Fact',
      'description':
          'Read or watch something short and share one thing you learned with someone.',
      'durationMinutes': 0,
      'categoryTags': ['learning', 'sharing', 'knowledge'],
      'difficultyLevel': 1,
      'themeId': 4,
    },
    {
      'id': -403,
      'title': 'Ask Why',
      'description':
          'Ask someone about their day and a follow-up question to understand why it mattered.',
      'durationMinutes': 0,
      'categoryTags': ['curiosity', 'listening', 'knowledge'],
      'difficultyLevel': 1,
      'themeId': 4,
    },
    {
      'id': -404,
      'title': 'Clarify Before Acting',
      'description':
          'Before starting a task, restate the goal to ensure alignment.',
      'durationMinutes': 0,
      'categoryTags': ['alignment', 'precision', 'knowledge'],
      'difficultyLevel': 2,
      'themeId': 4,
    },
    {
      'id': -405,
      'title': 'Read with Attention',
      'description':
          'Read a short passage and summarize it in two sentences to someone.',
      'durationMinutes': 0,
      'categoryTags': ['study', 'comprehension', 'knowledge'],
      'difficultyLevel': 2,
      'themeId': 4,
    },
    {
      'id': -406,
      'title': 'Learn a Story',
      'description':
          'Ask about a story you don\'t know and listen for details.',
      'durationMinutes': 0,
      'categoryTags': ['listening', 'narrative', 'knowledge'],
      'difficultyLevel': 2,
      'themeId': 4,
    },
    {
      'id': -407,
      'title': 'Seek Wise Input',
      'description':
          'Ask someone more experienced for input on one decision today.',
      'durationMinutes': 0,
      'categoryTags': ['counsel', 'discernment', 'knowledge'],
      'difficultyLevel': 3,
      'themeId': 4,
    },
    {
      'id': -408,
      'title': 'Check a Source',
      'description':
          'Verify the source of one claim you hear or read before passing it on.',
      'durationMinutes': 0,
      'categoryTags': ['discernment', 'truth', 'knowledge'],
      'difficultyLevel': 3,
      'themeId': 4,
    },
    {
      'id': -409,
      'title': 'Reflect on a Habit',
      'description':
          'Notice one pattern today and consider why it keeps happening.',
      'durationMinutes': 0,
      'categoryTags': ['awareness', 'reflection', 'knowledge'],
      'difficultyLevel': 3,
      'themeId': 4,
    },
    {
      'id': -410,
      'title': 'Teach Back',
      'description':
          'Explain a concept to someone today to ensure you truly grasp it.',
      'durationMinutes': 0,
      'categoryTags': ['teaching', 'clarity', 'knowledge'],
      'difficultyLevel': 4,
      'themeId': 4,
    },
    {
      'id': -411,
      'title': 'Consider Another View',
      'description':
          'Engage one differing opinion today and name at least one thing you respect.',
      'durationMinutes': 0,
      'categoryTags': ['openness', 'empathy', 'knowledge'],
      'difficultyLevel': 4,
      'themeId': 4,
    },
    {
      'id': -412,
      'title': 'Apply One Insight',
      'description':
          'Use one thing you\'ve learned recently to improve a routine today.',
      'durationMinutes': 0,
      'categoryTags': ['application', 'growth', 'knowledge'],
      'difficultyLevel': 4,
      'themeId': 4,
    },
    {
      'id': -413,
      'title': 'Invite Review',
      'description': 'Share a draft or idea for critique before finalizing.',
      'durationMinutes': 0,
      'categoryTags': ['feedback', 'collaboration', 'knowledge'],
      'difficultyLevel': 5,
      'themeId': 4,
    },
    {
      'id': -414,
      'title': 'Admit Uncertainty',
      'description':
          'When you don\'t know something, say "I don\'t know" and look it up.',
      'durationMinutes': 0,
      'categoryTags': ['humility', 'learning', 'knowledge'],
      'difficultyLevel': 5,
      'themeId': 4,
    },
    {
      'id': -415,
      'title': 'Seek Feedback',
      'description':
          'Ask for honest feedback on one habit and thank them for their honesty.',
      'durationMinutes': 0,
      'categoryTags': ['feedback', 'growth', 'knowledge'],
      'difficultyLevel': 5,
      'themeId': 4,
    },
  ];

  /// Get offline commitments for a specific virtue type with dynamic duration support
  static List<Commitment> getCommitmentsForVirtue(
    VirtueType virtueType, {
    int? defaultDurationMinutes,
  }) {
    List<Map<String, dynamic>> commitments;

    switch (virtueType) {
      case VirtueType.humility:
        commitments = _humilityCommitments;
        break;
      case VirtueType.love:
        commitments = _loveCommitments;
        break;
      case VirtueType.faith:
        commitments = _faithCommitments;
        break;
      case VirtueType.knowledge:
        commitments = _knowledgeCommitments;
        break;
    }

    return commitments.map((data) {
      // Use provided duration or default to 240 minutes (4 hours) for compatibility
      final duration = defaultDurationMinutes ?? 240;

      return Commitment(
        id: data['id'] as int,
        title: data['title'] as String,
        description: data['description'] as String,
        durationMinutes: duration,
        categoryTags: (data['categoryTags'] as List<dynamic>).cast<String>(),
        difficultyLevel: data['difficultyLevel'] as int,
        themeId: data['themeId'] as int,
        tips: data['tips'] != null
            ? (data['tips'] as List<dynamic>).cast<String>()
            : <String>[],
      );
    }).toList();
  }

  /// Get offline commitments with multiple duration options for user selection
  static List<Commitment> getCommitmentsWithDurationOptions(
    VirtueType virtueType,
  ) {
    final baseCommitments = getCommitmentsForVirtue(virtueType);
    final durationOptions = [60, 120, 180, 240]; // 1h, 2h, 3h, 4h options

    // Create multiple versions of each commitment with different durations
    final List<Commitment> commitmentsWithOptions = [];

    for (final baseCommitment in baseCommitments) {
      for (final duration in durationOptions) {
        commitmentsWithOptions.add(
          baseCommitment.copyWith(
            durationMinutes: duration,
            // Create unique ID by combining base ID with duration
            id: baseCommitment.id * 1000 + duration,
          ),
        );
      }
    }

    return commitmentsWithOptions;
  }

  /// Get a single commitment with a specific duration
  static Commitment getCommitmentWithDuration(
    VirtueType virtueType,
    int commitmentIndex,
    int durationMinutes,
  ) {
    final commitments = getCommitmentsForVirtue(
      virtueType,
      defaultDurationMinutes: durationMinutes,
    );
    if (commitmentIndex >= 0 && commitmentIndex < commitments.length) {
      return commitments[commitmentIndex];
    }
    throw ArgumentError(
      'Invalid commitment index: $commitmentIndex for virtue $virtueType',
    );
  }

  /// Get a random subset of commitments for variety (3-6 commitments)
  static List<Commitment> getRandomSubsetForVirtue(
    VirtueType virtueType, {
    int count = 4,
    int? defaultDurationMinutes,
  }) {
    final allCommitments = getCommitmentsForVirtue(
      virtueType,
      defaultDurationMinutes: defaultDurationMinutes,
    );
    allCommitments.shuffle();
    return allCommitments.take(count).toList();
  }

  /// Get commitments by difficulty level
  static List<Commitment> getCommitmentsByDifficulty(
    VirtueType virtueType,
    int difficultyLevel, {
    int? defaultDurationMinutes,
  }) {
    final allCommitments = getCommitmentsForVirtue(
      virtueType,
      defaultDurationMinutes: defaultDurationMinutes,
    );
    return allCommitments
        .where((c) => c.difficultyLevel == difficultyLevel)
        .toList();
  }

  /// Check if offline commitments are available for a virtue
  static bool hasOfflineCommitments(VirtueType virtueType) {
    return getCommitmentsForVirtue(virtueType).isNotEmpty;
  }
}
