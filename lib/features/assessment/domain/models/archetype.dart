import 'core_struggle.dart';

class Archetype {
  final String name;
  final String identity;
  final String strengths;
  final String distortions;
  final List<String> related;
  final List<String> typicalDistractions;
  final List<String> growthCommitments;
  final List<String> disciplineCommitments;
  final List<String> charityCommitments;
  final String inversionStrategy;

  /// The dominant core struggle this archetype tends toward when distorted.
  final CoreStruggle? primaryStruggle;

  /// The secondary struggle that reinforces the primary distortion pattern.
  final CoreStruggle? secondaryStruggle;

  /// Specific modern addiction patterns this archetype is most susceptible to.
  final List<String> modernAddictions;

  const Archetype({
    required this.name,
    required this.identity,
    required this.strengths,
    required this.distortions,
    required this.related,
    this.typicalDistractions = const [],
    this.growthCommitments = const [],
    this.disciplineCommitments = const [],
    this.charityCommitments = const [],
    this.inversionStrategy = '',
    this.primaryStruggle,
    this.secondaryStruggle,
    this.modernAddictions = const [],
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
      typicalDistractions: [
        'Social media validation seeking',
        'Entertainment and content overconsumption',
        'Novelty addiction — constantly chasing new apps, trends, or ideas',
        'Comparison scrolling and envy of others\' creative output',
      ],
      growthCommitments: [
        'Create something beautiful for God today',
        'Study a master artist\'s faith journey in Scripture',
        'Write or draw a prayer instead of typing one',
        'Meditate on how God creates — slowly, intentionally, with love',
      ],
      disciplineCommitments: [
        '30-minute social media fast',
        'Finish one creation before starting another',
        'No new content consumption until evening prayer is done',
        'Turn off notifications for 2 hours and create in silence',
      ],
      charityCommitments: [
        'Create something for someone who is hurting',
        'Teach your craft to a beginner for free',
        'Donate your creative time to a cause or ministry',
        'Write an encouraging note to someone you\'ve envied',
      ],
      inversionStrategy:
          'Your craving for novelty is actually a longing for the Creator. Channel it into discovering new facets of God\'s character through Scripture and prayer.',
      primaryStruggle: CoreStruggle.pride,
      secondaryStruggle: CoreStruggle.lust,
      modernAddictions: [
        'Social media validation and image curation',
        'Entertainment and content binging',
        'Comparison scrolling and creative envy',
        'Novelty addiction — chasing trends over depth',
      ],
    ),
    Archetype(
      name: 'Watchman',
      identity: 'Guardian',
      strengths:
          "Sharp discernment, Courage to confront danger, Loyalty, Intercessory alertness",
      distortions: "Following rules without mercy; Paranoia, Isolation, Resistance to grace",
      related: ['Sentinel', 'Reformer'],
      typicalDistractions: [
        'News doomscrolling and catastrophizing',
        'Obsessive information gathering for control',
        'Judgmental social media monitoring of others',
        'Isolation disguised as spiritual vigilance',
      ],
      growthCommitments: [
        'Pray for someone you\'ve been silently judging',
        'Read a passage about God\'s mercy and grace',
        'Practice seeing the good in one person today',
        'Study how Jesus balanced truth with compassion',
      ],
      disciplineCommitments: [
        'Limit news consumption to 15 minutes today',
        'No checking social media before morning prayer',
        'Fast from forming opinions about others for 1 hour',
        'Replace one worry session with intercessory prayer',
      ],
      charityCommitments: [
        'Reach out to someone you\'ve been avoiding',
        'Offer protection or help to someone vulnerable',
        'Share an encouraging word instead of a warning',
        'Volunteer for a community safety or mentoring initiative',
      ],
      inversionStrategy:
          'Your vigilance is a gift meant for intercession, not anxiety. When you feel the pull to monitor threats, redirect that energy into standing guard in prayer for those you love.',
      primaryStruggle: CoreStruggle.wrath,
      secondaryStruggle: CoreStruggle.pride,
      modernAddictions: [
        'Doomscrolling and catastrophizing',
        'Judgmental monitoring of others online',
        'Information hoarding for control',
        'Isolation disguised as vigilance',
      ],
    ),
    Archetype(
      name: 'Cultivator',
      identity: 'Nurturer',
      strengths:
          "Long-term investment mindset, Empathy, Ability to see hidden potential; Faithfulness in the mundane",
      distortions:
          "Overcontrol; Fear of change; Burnout, Resistance to pruning",
      related: ['Pillar', 'Healer'],
      typicalDistractions: [
        'Overworking and neglecting rest in the name of responsibility',
        'Controlling others\' growth instead of trusting God\'s timing',
        'Comfort-seeking through food, shopping, or routine avoidance',
        'Endless planning and research as a substitute for trusting God',
      ],
      growthCommitments: [
        'Trust God with one thing you\'ve been trying to control',
        'Read about seasons of rest in Scripture',
        'Celebrate someone else\'s growth today without taking credit',
        'Journal about what God is pruning in your life right now',
      ],
      disciplineCommitments: [
        'Take a full 30-minute rest without productivity guilt',
        'Say no to one request that isn\'t yours to carry',
        'Set a hard stop time for work today and honor it',
        'Fast from planning or researching for 1 hour — just be present',
      ],
      charityCommitments: [
        'Nurture someone outside your usual circle',
        'Give a resource or tool to someone who needs it more',
        'Mentor someone without expecting any return',
        'Prepare a meal or care package for someone who is struggling',
      ],
      inversionStrategy:
          'Your desire to control growth comes from a deep love for potential. Release the outcome to God and focus on faithful planting — He is the one who gives the increase.',
      primaryStruggle: CoreStruggle.gluttony,
      secondaryStruggle: CoreStruggle.sloth,
      modernAddictions: [
        'Comfort eating and shopping as stress relief',
        'Overworking to avoid surrendering control',
        'Endless planning as substitute for trust',
        'Routine avoidance of anything uncomfortable',
      ],
    ),
    Archetype(
      name: 'Sower',
      identity: 'Initiator',
      strengths:
          "Boldness to start without full clarity, Faith in unseen outcomes; Ability to inspire, Sensitivity to divine timing",
      distortions:
          "Impulsiveness, Shallow roots; Ego-driven ambition; Manipulation disguised as inspiration",
      related: ['Reformer', 'Artisan'],
      typicalDistractions: [
        'Starting new projects to avoid finishing current ones',
        'Chasing the next big idea or opportunity',
        'Social media self-promotion and personal branding obsession',
        'Impatience with slow, quiet spiritual growth',
      ],
      growthCommitments: [
        'Finish one thing you started before beginning anything new',
        'Study a biblical figure who waited patiently on God\'s timing',
        'Pray about your motives before launching your next idea',
        'Spend time in silence listening instead of planning',
      ],
      disciplineCommitments: [
        'No starting new projects today — tend what\'s already planted',
        'Limit idea-capture sessions to 10 minutes, then pray',
        'Fast from self-promotion on social media for 24 hours',
        'Practice patience by waiting 1 hour before acting on a new impulse',
      ],
      charityCommitments: [
        'Help someone else launch their idea instead of your own',
        'Sow encouragement into someone who feels invisible',
        'Give your time to support a project that isn\'t yours',
        'Share credit publicly with someone who helped you',
      ],
      inversionStrategy:
          'Your boldness to start is a prophetic gift — but scattered seeds don\'t bear fruit. Ask God which field He wants you to focus on, and pour your fire into that one place.',
      primaryStruggle: CoreStruggle.pride,
      secondaryStruggle: CoreStruggle.greed,
      modernAddictions: [
        'Self-promotion and personal branding obsession',
        'Novelty chasing — starting without finishing',
        'Impatience with slow spiritual growth',
        'Social media as validation platform',
      ],
    ),
    Archetype(
      name: 'Welcomer',
      identity: 'Host',
      strengths:
          "Generosity, Warmth, Attentiveness, Ability to set atmosphere for God's work",
      distortions:
          "People-pleasing; Neglect of self-care, Hospitality for personal gain, Avoidance of truth to keep comfort",
      related: ['Healer', 'Bridgebuilder'],
      typicalDistractions: [
        'People-pleasing and saying yes to everything',
        'Social media as a way to feel connected without real vulnerability',
        'Comfort eating, shopping, or escapism to avoid inner emptiness',
        'Avoiding difficult conversations to maintain surface peace',
      ],
      growthCommitments: [
        'Practice saying no to one request today without guilt',
        'Read about Jesus withdrawing to be alone with the Father',
        'Spend 10 minutes in silence without serving anyone',
        'Journal about what hospitality looks like when rooted in truth',
      ],
      disciplineCommitments: [
        'Set a boundary with someone who drains your energy',
        'No comfort purchases today — sit with the discomfort and pray',
        'Fast from agreeing with everyone — speak one gentle truth',
        'Limit social scrolling to 20 minutes and use the rest for self-care',
      ],
      charityCommitments: [
        'Welcome someone no one else is including',
        'Host a meal or gathering focused on others, not your image',
        'Write a handwritten note of welcome to a newcomer',
        'Volunteer at a shelter, food bank, or refugee center',
      ],
      inversionStrategy:
          'Your gift of creating belonging is powerful — but it becomes hollow when driven by fear of rejection. First welcome yourself into God\'s love, then extend that welcome to others from overflow.',
      primaryStruggle: CoreStruggle.sloth,
      secondaryStruggle: CoreStruggle.gluttony,
      modernAddictions: [
        'People-pleasing and saying yes to everything',
        'Comfort escapism — eating, shopping, streaming',
        'Shallow social media connection without vulnerability',
        'Avoiding difficult conversations for surface peace',
      ],
    ),
    Archetype(
      name: 'Pillar',
      identity: 'Supporter',
      strengths: "Loyalty, Humility, Perseverance; Reliability",
      distortions:
          "Neglect of own calling, Enabling unhealthy dependence, Resentment from lack of recognition; Fear of stepping forward",
      related: ['Cultivator', 'Bridgebuilder'],
      typicalDistractions: [
        'Passive consumption of others\' content while neglecting your own gifts',
        'Resentment scrolling — watching others get recognized while you serve unseen',
        'Enabling others\' poor habits by always picking up the slack',
        'Avoidance of your own calling through busyness for others',
      ],
      growthCommitments: [
        'Name one gift God has given you and take one step toward using it',
        'Read about Barnabas and how support and leadership can coexist',
        'Ask God what He\'s calling you to step forward in',
        'Celebrate your own faithfulness today without comparing to others',
      ],
      disciplineCommitments: [
        'Say no to one task that someone else should own',
        'Spend 30 minutes on your own calling before helping others',
        'Fast from checking if others noticed your contribution',
        'Set a boundary around your time — it belongs to God first',
      ],
      charityCommitments: [
        'Support someone else\'s dream without needing credit',
        'Encourage someone who serves quietly like you',
        'Teach someone a skill you\'ve mastered through faithful service',
        'Give anonymously to a cause you care about',
      ],
      inversionStrategy:
          'Your faithfulness in the background is not invisibility — it is the posture of Christ. But He also calls you to step forward. Your reliability is the foundation; now build something on it.',
      primaryStruggle: CoreStruggle.envy,
      secondaryStruggle: CoreStruggle.sloth,
      modernAddictions: [
        'Resentment scrolling — watching others get recognized',
        'Passive content consumption while neglecting own gifts',
        'Enabling others\' poor habits by always picking up slack',
        'Avoiding own calling through busyness for others',
      ],
    ),
    Archetype(
      name: 'Sentinel',
      identity: 'Observer',
      strengths:
          "Spiritual sensitivity, Authority in prayer, Discernment, Faithfulness in hidden places",
      distortions:
          "Isolation; Pride in insight, Neglect of action; Fear of exposure",
      related: ['Watchman', 'Bridgebuilder'],
      typicalDistractions: [
        'Overthinking and analysis paralysis',
        'Spiritual pride from having deep insights no one else sees',
        'Isolation disguised as contemplation',
        'Consuming theology and wisdom content without applying it',
      ],
      growthCommitments: [
        'Share one insight God gave you with someone today',
        'Act on one thing you\'ve been praying about instead of just praying more',
        'Read about how Jesus balanced solitude with community',
        'Journal about what God is asking you to do, not just understand',
      ],
      disciplineCommitments: [
        'Limit spiritual reading to 30 minutes and spend the next 30 doing something about it',
        'Reach out to one person today — break the isolation pattern',
        'Fast from forming theological opinions for a day — just listen and obey',
        'No spiritual content consumption after 8pm — rest in what you already know',
      ],
      charityCommitments: [
        'Use your discernment to encourage someone who is confused',
        'Pray with someone face to face, not just in your prayer closet',
        'Serve in a visible, practical way outside your comfort zone',
        'Write down your insights and share them freely with your community',
      ],
      inversionStrategy:
          'Your depth of insight is rare and precious — but insight without action is pride. God gave you eyes to see so that you can lead others into what He\'s revealing. Step out of the watchtower.',
      primaryStruggle: CoreStruggle.pride,
      secondaryStruggle: CoreStruggle.sloth,
      modernAddictions: [
        'Analysis paralysis and overthinking',
        'Spiritual pride from deep insights',
        'Content consumption without application',
        'Isolation disguised as contemplation',
      ],
    ),
    Archetype(
      name: 'Bridgebuilder',
      identity: 'Connector',
      strengths: "Empathy; Peacemaking; Unifying diverse groups, Humility",
      distortions:
          "People-pleasing, Compromise; Avoidance of conflict, Loss of identity",
      related: ['Welcomer', 'Pillar', 'Sentinel'],
      typicalDistractions: [
        'Social media as constant connection without depth',
        'People-pleasing across multiple relationships and platforms',
        'Avoiding your own convictions to maintain peace',
        'Identity diffusion — losing yourself in everyone else\'s needs',
      ],
      growthCommitments: [
        'Name one non-negotiable conviction and hold it gently today',
        'Read about how Jesus unified without compromising truth',
        'Spend time alone with God to remember who you are apart from others',
        'Journal about what bridges God is asking you to build vs. which ones to release',
      ],
      disciplineCommitments: [
        'Decline one social invitation to spend time with God alone',
        'Fast from mediating conflicts that aren\'t yours to carry',
        'Limit messaging/texting to 30 minutes today — be present where you are',
        'Practice stating your opinion kindly without softening it into nothingness',
      ],
      charityCommitments: [
        'Connect two people who would bless each other',
        'Reconcile with someone you\'ve been avoiding',
        'Volunteer as a mediator or peacemaker in your community',
        'Write to someone on the other side of a divide with genuine curiosity',
      ],
      inversionStrategy:
          'Your gift of connection becomes your weakness when you connect everything except yourself to God. Build the bridge between your own soul and the Father first — then your bridges to others will carry real weight.',
      primaryStruggle: CoreStruggle.sloth,
      secondaryStruggle: CoreStruggle.envy,
      modernAddictions: [
        'People-pleasing across multiple platforms',
        'Identity diffusion — losing self in others\' needs',
        'Avoiding personal convictions to maintain peace',
        'Shallow social media connection without depth',
      ],
    ),
    Archetype(
      name: 'Healer',
      identity: 'Restorer',
      strengths: "Compassion; Presence in pain; Restorative faith; Patience",
      distortions:
          "Savior complex; Emotional detachment, Burnout, Avoidance of hard truths",
      related: ['Welcomer', 'Artisan', 'Cultivator'],
      typicalDistractions: [
        'Absorbing everyone else\'s pain while neglecting your own wounds',
        'Emotional numbing through entertainment, food, or substances',
        'Savior complex — needing to fix everyone to feel worthy',
        'Avoiding hard truths about yourself by focusing on healing others',
      ],
      growthCommitments: [
        'Let God heal one wound in your own heart today',
        'Read about how Jesus wept — even the Healer needed to grieve',
        'Pray for yourself before praying for anyone else today',
        'Journal about a hard truth you\'ve been avoiding',
      ],
      disciplineCommitments: [
        'Say "I can\'t carry this for you" to someone today — with love',
        'Take a full break from counseling or caretaking for 2 hours',
        'Fast from emotional content (sad stories, heavy news) for one evening',
        'Set a boundary around your emotional availability today',
      ],
      charityCommitments: [
        'Offer your presence to someone in pain without trying to fix them',
        'Visit someone in a hospital, prison, or lonely place',
        'Share your own story of healing with someone who needs hope',
        'Donate to a mental health or recovery ministry',
      ],
      inversionStrategy:
          'Your compassion is Christ-like, but the Savior complex is a counterfeit. You are not the healer — God is. Your role is to be present, point to Him, and let Him do the restoring through you.',
      primaryStruggle: CoreStruggle.pride,
      secondaryStruggle: CoreStruggle.gluttony,
      modernAddictions: [
        'Emotional numbing through entertainment or food',
        'Savior complex — needing to fix everyone',
        'Absorbing others\' pain while neglecting own wounds',
        'Avoiding hard truths by focusing on healing others',
      ],
    ),
    Archetype(
      name: 'Harvester',
      identity: 'Gatherer',
      strengths:
          "Effectiveness, Joy in results, Mobilizing others, Celebration",
      distortions:
          "Exploitation; Obsession with metrics; Superficiality, Pride in results",
      related: ['Architect', 'Sower'],
      typicalDistractions: [
        'Metrics obsession — tracking followers, likes, productivity stats',
        'Workaholism disguised as harvest season',
        'Exploiting relationships for results',
        'Superficial engagement — wide but shallow connections',
      ],
      growthCommitments: [
        'Celebrate someone else\'s harvest without comparing it to yours',
        'Read about the parable of the workers in the vineyard — equal grace for unequal output',
        'Pray about one area where you\'re measuring success by the wrong metric',
        'Spend time being thankful for what God has already given, not what\'s next',
      ],
      disciplineCommitments: [
        'No checking stats, metrics, or analytics for 24 hours',
        'Take a full Sabbath rest — no productivity, no output',
        'Fast from mobilizing others and do something quietly by yourself',
        'Limit work to 8 hours today and guard the boundary',
      ],
      charityCommitments: [
        'Share your harvest — give away something you worked hard to gain',
        'Celebrate and publicize someone else\'s achievement',
        'Invest time in someone who will never produce results for you',
        'Donate to a ministry that works in slow, hidden places',
      ],
      inversionStrategy:
          'Your drive for results is a gift from the God who loves fruitfulness. But the harvest belongs to Him, not you. When you feel the pull to measure and optimize, pause and ask: "Am I gathering for God\'s kingdom or my own?"',
      primaryStruggle: CoreStruggle.greed,
      secondaryStruggle: CoreStruggle.pride,
      modernAddictions: [
        'Metrics obsession — followers, likes, productivity stats',
        'Workaholism disguised as harvest season',
        'Exploiting relationships for results',
        'Superficial engagement — wide but shallow connections',
      ],
    ),
    Archetype(
      name: 'Reformer',
      identity: 'Changer',
      strengths:
          "Righteous anger against injustice; Courage; Vision for transformation; Resilience",
      distortions: "Pride; Bitterness, Destructive rebellion, Idolizing change",
      related: ['Sower', 'Watchman'],
      typicalDistractions: [
        'Outrage addiction — always looking for the next injustice to fight',
        'Social media activism that replaces real action',
        'Bitterness toward institutions, leaders, or systems',
        'Idolizing disruption — tearing down without building up',
      ],
      growthCommitments: [
        'Pray for a leader or institution you\'ve been criticizing',
        'Read about how Nehemiah rebuilt — reformation requires building, not just breaking',
        'Channel your righteous anger into one concrete, constructive action',
        'Study how Jesus reformed with love, not just confrontation',
      ],
      disciplineCommitments: [
        'Fast from outrage content for 24 hours',
        'No posting critical opinions online today — pray instead',
        'Limit exposure to political/activist content to 15 minutes',
        'Practice one full day of gratitude for what is working, not what\'s broken',
      ],
      charityCommitments: [
        'Serve within the very institution you want to reform',
        'Write an encouraging letter to a leader who is trying',
        'Volunteer for a cause without needing to lead or change it',
        'Forgive one person or system you\'ve been holding bitterness toward',
      ],
      inversionStrategy:
          'Your fire for justice is prophetic — but bitterness extinguishes it. Reformation without love becomes destruction. Let God purify your anger so it builds up what He wants built, not just tears down what offends you.',
      primaryStruggle: CoreStruggle.wrath,
      secondaryStruggle: CoreStruggle.pride,
      modernAddictions: [
        'Outrage addiction — always seeking the next fight',
        'Social media activism replacing real action',
        'Bitterness toward institutions and leaders',
        'Idolizing disruption without building up',
      ],
    ),
    Archetype(
      name: 'Architect',
      identity: 'Builder',
      strengths:
          "Integrity, Strategic thinking, Faithfulness, Ability to multiply and sustain",
      distortions:
          "Rigid systems; Excessive control disguised as order; Perfectionism that hinders growth; Inflexibility in methods",
      related: ['Harvester', 'Cultivator'],
      typicalDistractions: [
        'Perfectionism that delays obedience',
        'Over-planning and systemizing as avoidance of surrender',
        'Control addiction — needing every detail managed',
        'Rigidity that resists the Spirit\'s spontaneous leading',
      ],
      growthCommitments: [
        'Do one thing imperfectly today and offer it to God anyway',
        'Read about how God uses broken vessels — perfection isn\'t required',
        'Pray about one area where you need to release control to God',
        'Study how the Holy Spirit moved unexpectedly in Acts',
      ],
      disciplineCommitments: [
        'Fast from planning for 2 hours — just respond to what comes',
        'Leave one thing unfinished today and trust God with it',
        'Limit system-building time to 1 hour and spend the rest in prayer',
        'No reorganizing, optimizing, or systematizing today — just be',
      ],
      charityCommitments: [
        'Build something for someone else\'s vision, not your own',
        'Help someone organize their chaos without imposing your system',
        'Donate your strategic thinking to a nonprofit or ministry',
        'Mentor someone in planning while learning flexibility from them',
      ],
      inversionStrategy:
          'Your desire for order reflects God\'s nature as the great Architect. But when your systems become your security instead of God, they become a prison. Build with open hands — the blueprint belongs to Him.',
      primaryStruggle: CoreStruggle.pride,
      secondaryStruggle: CoreStruggle.greed,
      modernAddictions: [
        'Perfectionism that delays obedience',
        'Over-planning as avoidance of surrender',
        'Control addiction — needing every detail managed',
        'Rigidity that resists the Spirit\'s leading',
      ],
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
