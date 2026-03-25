import '../domain/models/graduated_commitment.dart';

/// Static catalog of all 40 graduated commitments.
///
/// Designed around psychological commitment escalation:
///  - Tier 1 (1-10): Quick Wins, 2-5 minutes
///  - Tier 2 (11-20): Building Blocks, 15-60 minutes
///  - Tier 3 (21-30): Half-Day Challenges, 2-6 hours
///  - Tier 4 (31-40): Day-Long Commitments, 12-24 hours
class CommitmentCatalog {
  CommitmentCatalog._();

  static GraduatedCommitment getByLevel(int level) {
    return _all.firstWhere(
      (c) => c.level == level,
      orElse: () => _all.first,
    );
  }

  static List<GraduatedCommitment> get all => List.unmodifiable(_all);

  static List<GraduatedCommitment> getForTier(CommitmentTier tier) {
    return _all.where((c) => c.tier == tier).toList();
  }

  // ---------------------------------------------------------------------------
  // Tier 1: Quick Wins (2-5 minutes)
  // ---------------------------------------------------------------------------
  static final List<GraduatedCommitment> _all = [
    const GraduatedCommitment(
      id: 'gc_01',
      level: 1,
      title: 'Pause and Breathe',
      description:
          'Stop what you are doing right now. Take 3 slow, deep breaths. With each exhale, release one worry to God.',
      durationMinutes: 2,
      tier: CommitmentTier.quickWins,
      virtue: 'peace',
      tips: [
        'Breathe in for 4 counts, hold for 4, out for 6.',
        'Close your eyes if you can.',
        'Name the worry silently before releasing it.',
      ],
      xpReward: 10,
      encouragement:
          'You just took the first step. Every great journey begins with a single breath of faith.',
      failureGrace:
          'Even wanting to pause shows growth. Try again whenever you are ready \u2014 no rush.',
    ),
    const GraduatedCommitment(
      id: 'gc_02',
      level: 2,
      title: 'One Gratitude',
      description:
          'Say out loud one specific thing you are grateful for right now. Let yourself truly feel it.',
      durationMinutes: 2,
      tier: CommitmentTier.quickWins,
      virtue: 'gratitude',
      tips: [
        'Be specific \u2014 not just "my family" but "the way my child laughed this morning."',
        'Place your hand on your heart as you say it.',
        'Smile while you speak.',
      ],
      xpReward: 10,
      encouragement:
          'Gratitude rewires your brain for joy. You just planted a seed of contentment.',
      failureGrace:
          'Some days the words are hard to find. That is okay. Tomorrow the sun rises again.',
    ),
    const GraduatedCommitment(
      id: 'gc_03',
      level: 3,
      title: 'Read One Verse',
      description:
          'Open your Bible and read just one verse. Let it sit in your mind for a full minute afterward.',
      durationMinutes: 3,
      tier: CommitmentTier.quickWins,
      virtue: 'faith',
      tips: [
        'Try Psalm 46:10 if you do not know where to start.',
        'Read it twice \u2014 once aloud, once silently.',
        'Ask yourself: What is God saying to me in this?',
      ],
      xpReward: 12,
      encouragement:
          'One verse can change an entire day. You chose to listen to the Author of life.',
      failureGrace:
          'The Bible will always be there when you are ready. No condemnation, only invitation.',
    ),
    const GraduatedCommitment(
      id: 'gc_04',
      level: 4,
      title: 'Encouraging Text',
      description:
          'Send an encouraging message to someone right now. It can be a simple text, a compliment, or words of support.',
      durationMinutes: 3,
      tier: CommitmentTier.quickWins,
      virtue: 'love',
      tips: [
        'Think of someone who might be struggling.',
        'Keep it genuine \u2014 even "thinking of you" is enough.',
        'Do not overthink it; sincerity matters more than eloquence.',
      ],
      xpReward: 15,
      encouragement:
          'Your words just became someone\'s bright spot. Love multiplies when shared.',
      failureGrace:
          'Reaching out can feel vulnerable. The fact that you considered it shows a caring heart.',
    ),
    const GraduatedCommitment(
      id: 'gc_05',
      level: 5,
      title: 'Two-Minute Prayer',
      description:
          'Set a timer for 2 minutes and pray. Talk to God about whatever is on your heart right now.',
      durationMinutes: 2,
      tier: CommitmentTier.quickWins,
      virtue: 'faith',
      tips: [
        'You do not need fancy words. Speak as you would to a friend.',
        'Start with "God, right now I feel..." and go from there.',
        'It is okay to sit in silence \u2014 that is prayer too.',
      ],
      xpReward: 12,
      encouragement:
          'Two minutes with God is worth more than hours of worry. He heard every word.',
      failureGrace:
          'Prayer is a conversation, not a performance. Come back anytime \u2014 He is always listening.',
    ),
    const GraduatedCommitment(
      id: 'gc_06',
      level: 6,
      title: 'Forgive One Thing',
      description:
          'Think of a small grudge or frustration you are holding. Choose to release it right now, even silently.',
      durationMinutes: 3,
      tier: CommitmentTier.quickWins,
      virtue: 'humility',
      tips: [
        'It does not mean what happened was okay \u2014 it means you are choosing freedom.',
        'Say: "I release this. I choose peace over bitterness."',
        'Forgiveness is a decision, not a feeling. The feeling follows.',
      ],
      xpReward: 15,
      encouragement:
          'Forgiveness is the bravest form of strength. You just freed yourself.',
      failureGrace:
          'Some hurts run deep. Even acknowledging them is a step. Be gentle with yourself.',
    ),
    const GraduatedCommitment(
      id: 'gc_07',
      level: 7,
      title: 'Name Your Blessing',
      description:
          'Write down three blessings from the past 24 hours. Be as specific as possible.',
      durationMinutes: 4,
      tier: CommitmentTier.quickWins,
      virtue: 'gratitude',
      tips: [
        'Include one blessing you usually take for granted.',
        'Use your journal or a scrap of paper \u2014 writing makes it real.',
        'Challenge: Can you find a blessing hidden inside a difficulty?',
      ],
      xpReward: 15,
      encouragement:
          'You are training your eyes to see abundance. This changes everything over time.',
      failureGrace:
          'If blessings feel invisible today, that is when this practice matters most. Try again tomorrow.',
    ),
    const GraduatedCommitment(
      id: 'gc_08',
      level: 8,
      title: 'Compliment a Stranger',
      description:
          'Give a genuine compliment to someone you encounter today \u2014 a coworker, barista, neighbor, or stranger.',
      durationMinutes: 3,
      tier: CommitmentTier.quickWins,
      virtue: 'love',
      tips: [
        'Notice something real: their effort, their kindness, their style.',
        'Make eye contact and smile.',
        'Do not expect anything in return \u2014 this is about giving freely.',
      ],
      xpReward: 15,
      encouragement:
          'You just made someone\'s day brighter. Kindness is never wasted.',
      failureGrace:
          'Social courage takes practice. Even thinking about being kind to others builds the muscle.',
    ),
    const GraduatedCommitment(
      id: 'gc_09',
      level: 9,
      title: 'Scripture Memorization',
      description:
          'Pick one short verse and repeat it 5 times until you can say it from memory.',
      durationMinutes: 5,
      tier: CommitmentTier.quickWins,
      virtue: 'knowledge',
      tips: [
        'Try Philippians 4:13 or Proverbs 3:5-6.',
        'Write it on a sticky note and place it where you will see it.',
        'Say it with emphasis on a different word each time.',
      ],
      xpReward: 18,
      encouragement:
          'You now carry God\'s word in your heart. It will speak to you when you need it most.',
      failureGrace:
          'Memory is a skill, not a talent. Every attempt strengthens the connection.',
    ),
    const GraduatedCommitment(
      id: 'gc_10',
      level: 10,
      title: 'Five-Minute Silence',
      description:
          'Sit in complete silence for 5 minutes. No phone, no music, no distractions. Just be.',
      durationMinutes: 5,
      tier: CommitmentTier.quickWins,
      virtue: 'peace',
      tips: [
        'Set a gentle timer so you do not watch the clock.',
        'When thoughts come, acknowledge them and let them pass like clouds.',
        'This is not about emptying your mind \u2014 it is about being present.',
      ],
      xpReward: 20,
      encouragement:
          'You completed Tier 1! Silence is where God often speaks loudest. You are learning to listen.',
      failureGrace:
          'Stillness is hard in a noisy world. Even 30 seconds of trying counts. You will get there.',
    ),

    // -------------------------------------------------------------------------
    // Tier 2: Building Blocks (15-60 minutes)
    // -------------------------------------------------------------------------
    const GraduatedCommitment(
      id: 'gc_11',
      level: 11,
      title: 'Social Media Fast',
      description:
          'Put your phone on Do Not Disturb and avoid all social media for the next 30 minutes.',
      durationMinutes: 30,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'self-control',
      tips: [
        'Move social apps off your home screen temporarily.',
        'Notice the urge to check \u2014 that urge itself teaches you about dependence.',
        'Replace scrolling time with one of the quick wins you have already mastered.',
      ],
      xpReward: 25,
      encouragement:
          'You just proved that you control your phone \u2014 it does not control you.',
      failureGrace:
          'Digital habits are deeply wired. Noticing the pull is the first victory.',
    ),
    const GraduatedCommitment(
      id: 'gc_12',
      level: 12,
      title: 'Focused Prayer Time',
      description:
          'Spend 15 uninterrupted minutes in prayer. Use a prayer list if it helps you stay focused.',
      durationMinutes: 15,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'faith',
      tips: [
        'Start with praise, then thanksgiving, then requests.',
        'Pray for others before yourself.',
        'Keep a notepad nearby for distracting thoughts you can return to later.',
      ],
      xpReward: 25,
      encouragement:
          'Fifteen minutes of honest prayer can move mountains. God treasures this time with you.',
      failureGrace:
          'A wandering mind during prayer is normal. God sees the heart behind the effort.',
    ),
    const GraduatedCommitment(
      id: 'gc_13',
      level: 13,
      title: 'Journaling Session',
      description:
          'Spend 20 minutes journaling about your day, your feelings, or what God is teaching you.',
      durationMinutes: 20,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'knowledge',
      tips: [
        'Start with: "Right now I feel... because..."',
        'Write without editing \u2014 this is for your eyes only.',
        'End with one thing you want to remember from today.',
      ],
      xpReward: 25,
      encouragement:
          'Writing is thinking made visible. You just processed your soul on paper.',
      failureGrace:
          'Not every day produces profound writing. The act itself is what heals.',
    ),
    const GraduatedCommitment(
      id: 'gc_14',
      level: 14,
      title: 'Phoneless Walk',
      description:
          'Walk outside for 15 minutes without your phone. Notice creation around you.',
      durationMinutes: 15,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'peace',
      tips: [
        'Pay attention to five things you can see, four you can hear, three you can touch.',
        'Walk slowly and deliberately.',
        'Thank God for one thing you notice during the walk.',
      ],
      xpReward: 25,
      encouragement:
          'You chose presence over productivity. That takes real courage in today\'s world.',
      failureGrace:
          'Sometimes we cannot step away. The intention to connect with creation still matters.',
    ),
    const GraduatedCommitment(
      id: 'gc_15',
      level: 15,
      title: 'No Complaining Challenge',
      description:
          'For the next 30 minutes, catch every complaint before it leaves your mouth and reframe it as gratitude.',
      durationMinutes: 30,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'gratitude',
      tips: [
        '"This traffic is terrible" becomes "I am grateful I have a car."',
        'Wear a rubber band on your wrist and snap it gently each time you catch a complaint.',
        'It is okay to think the complaint \u2014 the goal is to not voice it.',
      ],
      xpReward: 30,
      encouragement:
          'You just rewired 30 minutes of negativity into gratitude. Your words shape your world.',
      failureGrace:
          'Complaints are deeply habitual. Catching even one is a win. Keep noticing.',
    ),
    const GraduatedCommitment(
      id: 'gc_16',
      level: 16,
      title: 'Serve Someone',
      description:
          'Do one act of service for someone in the next 30 minutes. Dishes, a chore, a favor \u2014 anything that helps.',
      durationMinutes: 30,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'love',
      tips: [
        'Look for what needs doing, not what you feel like doing.',
        'Do it without announcing it or expecting thanks.',
        'Serve with joy, not obligation.',
      ],
      xpReward: 30,
      encouragement:
          'Service is love with its work clothes on. You just wore them beautifully.',
      failureGrace:
          'The willingness to serve already changes your heart, even if the timing did not work out.',
    ),
    const GraduatedCommitment(
      id: 'gc_17',
      level: 17,
      title: 'Deep Bible Study',
      description:
          'Read one chapter of the Bible slowly. Write down one observation, one question, and one application.',
      durationMinutes: 30,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'knowledge',
      tips: [
        'Try a Gospel chapter (Matthew, Mark, Luke, or John).',
        'Observation: What does the text say?',
        'Application: How does this change my day today?',
      ],
      xpReward: 30,
      encouragement:
          'Studying Scripture deeply is how you build an unshakable foundation.',
      failureGrace:
          'The Bible can feel overwhelming. Even opening it is an act of faith.',
    ),
    const GraduatedCommitment(
      id: 'gc_18',
      level: 18,
      title: 'Patience Practice',
      description:
          'For the next 45 minutes, practice deliberate patience. Slow down everything: walking, talking, eating, responding.',
      durationMinutes: 45,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'patience',
      tips: [
        'Before responding to anyone, take one breath first.',
        'Choose the slower checkout line on purpose.',
        'When you feel rushed, whisper: "I have enough time."',
      ],
      xpReward: 35,
      encouragement:
          'Patience is not passive waiting \u2014 it is active trust. You just exercised deep faith.',
      failureGrace:
          'Impatience is deeply human. Every moment of awareness is progress.',
    ),
    const GraduatedCommitment(
      id: 'gc_19',
      level: 19,
      title: 'Technology Sabbath',
      description:
          'Spend 1 hour with absolutely no screens. Read, pray, walk, create, or simply rest.',
      durationMinutes: 60,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'self-control',
      tips: [
        'Announce to others you are going offline so they know not to expect replies.',
        'Have a physical book or journal ready as an alternative.',
        'Notice how your brain feels after 20 minutes without stimulation.',
      ],
      xpReward: 40,
      encouragement:
          'One hour of digital freedom! You are reclaiming your attention for what truly matters.',
      failureGrace:
          'Our brains are wired for stimulation. Even 20 minutes offline rewires something.',
    ),
    const GraduatedCommitment(
      id: 'gc_20',
      level: 20,
      title: 'Listening Hour',
      description:
          'In every conversation for the next 60 minutes, focus entirely on listening. Ask questions. Do not redirect to yourself.',
      durationMinutes: 60,
      tier: CommitmentTier.buildingBlocks,
      virtue: 'humility',
      tips: [
        'Repeat back what you hear: "So you are saying..."',
        'Resist the urge to share your own similar experience.',
        'Make eye contact and put your phone completely away.',
      ],
      xpReward: 40,
      encouragement:
          'You completed Tier 2! True listening is one of the rarest gifts. You gave it freely today.',
      failureGrace:
          'Listening without self-focus is incredibly hard. Each attempt reshapes your relational instincts.',
    ),

    // -------------------------------------------------------------------------
    // Tier 3: Half-Day Challenges (2-6 hours)
    // -------------------------------------------------------------------------
    const GraduatedCommitment(
      id: 'gc_21',
      level: 21,
      title: 'Morning Social Media Fast',
      description:
          'No social media from now until lunchtime. Fill that time with meaningful connection or creation.',
      durationMinutes: 180,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'self-control',
      tips: [
        'Log out of all social apps right now.',
        'Each time you reach for your phone, say a brief prayer instead.',
        'Notice what fills the space \u2014 that reveals what social media was masking.',
      ],
      xpReward: 50,
      encouragement:
          'A whole morning free from the scroll. You are discovering who you are without the feed.',
      failureGrace:
          'Social media is engineered to be addictive. Every minute resisted is a step toward freedom.',
    ),
    const GraduatedCommitment(
      id: 'gc_22',
      level: 22,
      title: 'Complaining Fast',
      description:
          'Fast from all complaining for 4 hours. Every complaint becomes a prayer of thanksgiving.',
      durationMinutes: 240,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'gratitude',
      tips: [
        'Keep a tally of how many complaints you catch \u2014 awareness builds the muscle.',
        'When a complaint arises, immediately find one related blessing.',
        'Share a positive observation with someone every hour.',
      ],
      xpReward: 55,
      encouragement:
          'Four hours of gratitude-powered speech! Your words are building a better inner world.',
      failureGrace:
          'Complaining is a deep reflex. Catching even half of them is remarkable progress.',
    ),
    const GraduatedCommitment(
      id: 'gc_23',
      level: 23,
      title: 'Dedicated Service Block',
      description:
          'Dedicate 2 full hours to helping someone else. Ask what they need and give your time generously.',
      durationMinutes: 120,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'love',
      tips: [
        'Ask: "What can I do for you today?" and mean it.',
        'Put your own agenda completely on hold.',
        'Serve with cheerfulness, not martyrdom.',
      ],
      xpReward: 55,
      encouragement:
          'Two hours of your life given away. That is what love looks like with hands and feet.',
      failureGrace:
          'Time is our most precious resource. Even wanting to give it shows a generous spirit.',
    ),
    const GraduatedCommitment(
      id: 'gc_24',
      level: 24,
      title: 'Screen Entertainment Fast',
      description:
          'No screen entertainment for 3 hours. No TV, no streaming, no YouTube, no gaming.',
      durationMinutes: 180,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'self-control',
      tips: [
        'Prepare alternative activities in advance: reading, crafts, board games, cooking.',
        'This applies to entertainment only \u2014 necessary work use is fine.',
        'Notice what emotions arise when entertainment is removed.',
      ],
      xpReward: 55,
      encouragement:
          'Three hours reclaimed from screens. You are proving that joy exists beyond pixels.',
      failureGrace:
          'Entertainment numbs real feelings. Any time spent facing them instead is courageous.',
    ),
    const GraduatedCommitment(
      id: 'gc_25',
      level: 25,
      title: 'Extended Prayer and Meditation',
      description:
          'Spend 2 hours in prayer, meditation on Scripture, and listening to God. This can be in segments.',
      durationMinutes: 120,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'faith',
      tips: [
        'Break it up: 30 min reading, 30 min prayer, 30 min silence, 30 min worship.',
        'Find a quiet place where you will not be interrupted.',
        'Bring a journal to capture what you hear.',
      ],
      xpReward: 60,
      encouragement:
          'Two hours with the Creator. You are building the deepest relationship possible.',
      failureGrace:
          'Extended time with God can feel impossible in a busy life. Any portion you gave was received.',
    ),
    const GraduatedCommitment(
      id: 'gc_26',
      level: 26,
      title: 'Kindness Marathon',
      description:
          'For the next 4 hours, perform one deliberate act of kindness every hour.',
      durationMinutes: 240,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'love',
      tips: [
        'Ideas: hold a door, buy someone coffee, write a thank-you note, help a colleague.',
        'Track each act \u2014 writing them down reinforces the habit.',
        'Look for needs that others have not voiced.',
      ],
      xpReward: 60,
      encouragement:
          'Four acts of deliberate kindness. You are becoming the kind of person the world needs.',
      failureGrace:
          'Kindness takes awareness and energy. Even attempting this challenge changes you.',
    ),
    const GraduatedCommitment(
      id: 'gc_27',
      level: 27,
      title: 'Honesty Commitment',
      description:
          'For the next 3 hours, commit to complete honesty in all interactions. No white lies, no exaggerations, no omissions.',
      durationMinutes: 180,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'integrity',
      tips: [
        'Before speaking, ask: "Is this completely true?"',
        'Honesty includes admitting "I don\'t know" instead of guessing.',
        'Being honest is not the same as being harsh \u2014 speak truth with kindness.',
      ],
      xpReward: 60,
      encouragement:
          'Three hours of radical honesty. Integrity is who you are when convenience tempts you to bend.',
      failureGrace:
          'We tell small lies without even noticing. Awareness of them is the foundation of change.',
    ),
    const GraduatedCommitment(
      id: 'gc_28',
      level: 28,
      title: 'Worry Surrender',
      description:
          'For the next 4 hours, every time a worry arises, write it down and pray about it instead of dwelling on it.',
      durationMinutes: 240,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'peace',
      tips: [
        'Carry a small notepad or use your journal app.',
        'Write the worry, then write: "God, I give this to You."',
        'At the end, review the list \u2014 notice how many worries never materialized.',
      ],
      xpReward: 60,
      encouragement:
          'You spent 4 hours exchanging worry for prayer. That is the essence of Philippians 4:6.',
      failureGrace:
          'Worry is a deeply ingrained reflex. Redirecting even some of it to prayer is powerful.',
    ),
    const GraduatedCommitment(
      id: 'gc_29',
      level: 29,
      title: 'Generosity Challenge',
      description:
          'For the next 3 hours, look for ways to be generous: with your time, words, resources, or attention.',
      durationMinutes: 180,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'generosity',
      tips: [
        'Generosity is not just money \u2014 it is attention, patience, and presence.',
        'Give someone the gift of unhurried time.',
        'Leave a bigger tip. Share your lunch. Offer genuine encouragement.',
      ],
      xpReward: 60,
      encouragement:
          'Generosity flows from abundance, and you just proved your heart is full.',
      failureGrace:
          'Giving when you feel empty is hard. Rest and try again from a place of overflow.',
    ),
    const GraduatedCommitment(
      id: 'gc_30',
      level: 30,
      title: 'Half-Day Humility',
      description:
          'For the next 6 hours, put others first in every interaction. Last in line, first to listen, quick to serve.',
      durationMinutes: 360,
      tier: CommitmentTier.halfDayChallenges,
      virtue: 'humility',
      tips: [
        'Let others choose first: the restaurant, the movie, the meeting topic.',
        'When praised, redirect credit to others.',
        'Ask yourself every hour: "Whose needs did I just put before mine?"',
      ],
      xpReward: 70,
      encouragement:
          'You completed Tier 3! Six hours of humble service. You are becoming someone others can trust deeply.',
      failureGrace:
          'Humility goes against every instinct of self-preservation. Each attempt softens the ego.',
    ),

    // -------------------------------------------------------------------------
    // Tier 4: Day-Long Commitments (12-24 hours)
    // -------------------------------------------------------------------------
    const GraduatedCommitment(
      id: 'gc_31',
      level: 31,
      title: 'Full-Day Social Media Fast',
      description:
          'No social media for 24 hours. Rediscover what fills your time when the feed is gone.',
      durationMinutes: 1440,
      tier: CommitmentTier.dayLong,
      virtue: 'self-control',
      tips: [
        'Delete the apps from your phone for today (you can reinstall tomorrow).',
        'Tell one friend what you are doing \u2014 accountability helps.',
        'Journal about what you discover during the day.',
      ],
      xpReward: 80,
      encouragement:
          'A full day free! You just proved social media is a choice, not a necessity.',
      failureGrace:
          'Digital detox is one of the hardest challenges in modern life. Partial success still matters.',
    ),
    const GraduatedCommitment(
      id: 'gc_32',
      level: 32,
      title: 'All-Day Patience',
      description:
          'Practice patience all day long. No road rage, no frustration at others, no sighing in lines.',
      durationMinutes: 720,
      tier: CommitmentTier.dayLong,
      virtue: 'patience',
      tips: [
        'Start the day with: "Today I choose patience as my teacher."',
        'When frustrated, count to 10 before responding.',
        'See every delay as God rearranging timing for your good.',
      ],
      xpReward: 80,
      encouragement:
          'A full day of patience! You have strengthened a muscle that most people never exercise.',
      failureGrace:
          'Patience for an entire day is heroic. Every patient moment in between counts.',
    ),
    const GraduatedCommitment(
      id: 'gc_33',
      level: 33,
      title: 'Negative Speech Fast',
      description:
          'Fast from all negative speech for the entire day: no gossip, no criticism, no sarcasm, no negativity.',
      durationMinutes: 720,
      tier: CommitmentTier.dayLong,
      virtue: 'integrity',
      tips: [
        'If you cannot say something kind or constructive, stay silent.',
        'Replace criticism with curiosity: "I wonder why they did that."',
        'When you catch negativity, immediately say something positive.',
      ],
      xpReward: 85,
      encouragement:
          'A full day of life-giving speech. Your words today built people up instead of tearing them down.',
      failureGrace:
          'Negative speech is so common we barely notice it. Each caught word is a victory.',
    ),
    const GraduatedCommitment(
      id: 'gc_34',
      level: 34,
      title: 'Servant Heart Day',
      description:
          'All day today, put the needs of others before your own. Serve your family, colleagues, and strangers first.',
      durationMinutes: 720,
      tier: CommitmentTier.dayLong,
      virtue: 'love',
      tips: [
        'Start by asking your family: "What can I do for you today?"',
        'At work, look for tasks no one wants to do. Do them.',
        'End the day by reflecting: "Who did I serve today?"',
      ],
      xpReward: 85,
      encouragement:
          'A day lived for others. This is the heart of Christ in action.',
      failureGrace:
          'Self-sacrifice for a whole day is extraordinary. Any service you gave mattered.',
    ),
    const GraduatedCommitment(
      id: 'gc_35',
      level: 35,
      title: 'Gratitude Immersion',
      description:
          'Spend the entire day actively practicing gratitude. Thank God and others for everything you notice.',
      durationMinutes: 720,
      tier: CommitmentTier.dayLong,
      virtue: 'gratitude',
      tips: [
        'Set hourly reminders to pause and name three blessings.',
        'Thank every person who serves you today: cashiers, drivers, coworkers.',
        'Write a gratitude letter to someone who shaped your life.',
      ],
      xpReward: 85,
      encouragement:
          'A full day of gratitude transforms how you see the world. Nothing is ordinary anymore.',
      failureGrace:
          'Sustained gratitude is exhausting in a complaining culture. Any grateful moment was real.',
    ),
    const GraduatedCommitment(
      id: 'gc_36',
      level: 36,
      title: 'No Entertainment Day',
      description:
          'No entertainment media for the entire day. No TV, streaming, social media, gaming, or mindless browsing.',
      durationMinutes: 960,
      tier: CommitmentTier.dayLong,
      virtue: 'self-control',
      tips: [
        'Plan your day in advance with meaningful activities.',
        'Use the time for relationships, creation, learning, or rest.',
        'Notice what emotions surface when entertainment is not available to numb them.',
      ],
      xpReward: 90,
      encouragement:
          'You spent an entire day without numbing yourself with media. That takes incredible strength.',
      failureGrace:
          'Entertainment withdrawal reveals deep needs. Recognizing them is the start of healing.',
    ),
    const GraduatedCommitment(
      id: 'gc_37',
      level: 37,
      title: 'Day of Listening',
      description:
          'Spend the entire day prioritizing listening over speaking. In every interaction, listen more than you talk.',
      durationMinutes: 720,
      tier: CommitmentTier.dayLong,
      virtue: 'humility',
      tips: [
        'Ask follow-up questions instead of sharing your own stories.',
        'In meetings, speak last instead of first.',
        'Listen to God as well: spend quiet time without requests, just receiving.',
      ],
      xpReward: 90,
      encouragement:
          'A day of listening. You gave others the gift of feeling truly heard.',
      failureGrace:
          'We are conditioned to talk. Every moment of genuine listening was a gift to someone.',
    ),
    const GraduatedCommitment(
      id: 'gc_38',
      level: 38,
      title: 'Prayer and Fasting Day',
      description:
          'Combine a food fast (skip one meal) with extended prayer throughout the day.',
      durationMinutes: 960,
      tier: CommitmentTier.dayLong,
      virtue: 'faith',
      tips: [
        'When hunger pangs come, use them as a prompt to pray.',
        'Stay hydrated \u2014 drink plenty of water.',
        'Break your fast gently with a small, grateful meal.',
      ],
      xpReward: 95,
      encouragement:
          'Fasting and prayer is one of the most powerful spiritual disciplines. You honored God with your body and spirit.',
      failureGrace:
          'Fasting is not for everyone medically. Any form of intentional denial for spiritual gain counts.',
    ),
    const GraduatedCommitment(
      id: 'gc_39',
      level: 39,
      title: 'Full Forgiveness Day',
      description:
          'Spend the day actively forgiving. Write letters of forgiveness (you do not need to send them). Release every grudge.',
      durationMinutes: 720,
      tier: CommitmentTier.dayLong,
      virtue: 'peace',
      tips: [
        'Make a list of anyone you hold resentment toward.',
        'Write each person a letter expressing your hurt and then your choice to forgive.',
        'End with forgiving yourself for things you carry guilt about.',
      ],
      xpReward: 95,
      encouragement:
          'A day of radical forgiveness. Chains that held your heart have been broken.',
      failureGrace:
          'Deep forgiveness is a journey, not a single day. Today was one powerful step on that path.',
    ),
    const GraduatedCommitment(
      id: 'gc_40',
      level: 40,
      title: 'The Surrender',
      description:
          'Spend 24 hours living fully surrendered to God. Before every decision, ask: "What would You have me do?" Obey what you hear.',
      durationMinutes: 1440,
      tier: CommitmentTier.dayLong,
      virtue: 'faith',
      tips: [
        'Start the morning on your knees: "Today is Yours."',
        'Before each decision, pause and ask God for direction.',
        'Journal every moment you sensed divine guidance.',
        'End the day with praise for what God did through you.',
      ],
      xpReward: 100,
      encouragement:
          'You have completed the journey. 40 commitments. 40 steps of faith. You are not the same person who started.',
      failureGrace:
          'Full surrender is the work of a lifetime, not a single day. The desire itself honors God.',
    ),
  ];
}
