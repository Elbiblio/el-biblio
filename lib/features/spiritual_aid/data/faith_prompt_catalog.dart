import '../domain/models/faith_prompt.dart';

class FaithPromptCatalog {
  const FaithPromptCatalog._();

  static final List<FaithPrompt> all = [
    // ─── THEOLOGY (5) ────────────────────────────────────────────────
    FaithPrompt(
      id: 'theo_01',
      question: 'What does it mean that God is both just and merciful? How do you reconcile these two attributes in your own life?',
      context: 'The Bible describes God as perfectly just, never letting wrongdoing go unaddressed, and yet overflowing with mercy toward those who turn to Him. This tension is resolved at the cross, where justice and mercy meet.',
      category: 'theology',
      relatedScripture: 'The Lord, the Lord, the compassionate and gracious God, slow to anger, abounding in love and faithfulness, maintaining love to thousands, and forgiving wickedness, rebellion and sin.',
      scriptureReference: 'Exodus 34:6-7',
      discussionStarters: [
        'Think of a time you experienced both consequences and mercy.',
        'How does the cross demonstrate justice and mercy together?',
        'Does understanding God\'s justice make His mercy more meaningful?',
      ],
      date: DateTime(2025, 1, 1),
    ),
    FaithPrompt(
      id: 'theo_02',
      question: 'How do you understand the Trinity, and why does it matter for your daily walk with God?',
      context: 'Christians believe in one God who exists in three persons: Father, Son, and Holy Spirit. This is not three gods, but one God in a perfect community of love, which shapes how we understand relationships and community.',
      category: 'theology',
      relatedScripture: 'Therefore go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit.',
      scriptureReference: 'Matthew 28:19',
      discussionStarters: [
        'How does the Trinity model perfect community and love?',
        'Which person of the Trinity do you connect with most easily?',
        'How does the Spirit\'s presence change your daily experience?',
      ],
      date: DateTime(2025, 1, 2),
    ),
    FaithPrompt(
      id: 'theo_03',
      question: 'What does grace really mean, and how is it different from simply being nice or tolerant?',
      context: 'Grace is receiving what we do not deserve. It is not earned, not merited, and not repayable. Grace transforms because it comes from love, not obligation, and it calls us to transformation, not complacency.',
      category: 'theology',
      relatedScripture: 'For it is by grace you have been saved, through faith -- and this is not from yourselves, it is the gift of God -- not by works, so that no one can boast.',
      scriptureReference: 'Ephesians 2:8-9',
      discussionStarters: [
        'When did you first truly understand grace?',
        'How does cheap grace differ from costly grace?',
        'Is it harder to receive grace or to give it?',
      ],
      date: DateTime(2025, 1, 3),
    ),
    FaithPrompt(
      id: 'theo_04',
      question: 'What role does prayer play when God already knows everything?',
      context: 'If God is omniscient and sovereign, why pray? Prayer is less about informing God and more about aligning our hearts with His. It is the primary way we relate to God, express dependence, and participate in His work.',
      category: 'theology',
      relatedScripture: 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
      scriptureReference: 'Philippians 4:6',
      discussionStarters: [
        'Has prayer ever changed your perspective more than your circumstances?',
        'What makes prayer different from meditation or self-reflection?',
        'How do you handle prayers that seem unanswered?',
      ],
      date: DateTime(2025, 1, 4),
    ),
    FaithPrompt(
      id: 'theo_05',
      question: 'How do you approach the parts of the Bible you find confusing or difficult?',
      context: 'Scripture contains passages that challenge, confuse, and even disturb us. Wrestling with difficult texts is not a sign of weak faith but of honest engagement with the living Word of God.',
      category: 'theology',
      relatedScripture: 'All Scripture is God-breathed and is useful for teaching, rebuking, correcting and training in righteousness.',
      scriptureReference: '2 Timothy 3:16',
      discussionStarters: [
        'What passage of Scripture has challenged you the most?',
        'How do you hold tension between understanding and faith?',
        'What resources help you study difficult passages?',
      ],
      date: DateTime(2025, 1, 5),
    ),

    // ─── DAILY LIFE (5) ──────────────────────────────────────────────
    FaithPrompt(
      id: 'daily_01',
      question: 'How do you practice the presence of God in ordinary moments like commuting, cooking, or waiting in line?',
      context: 'Brother Lawrence, a 17th-century monk, taught that peeling potatoes could be as worshipful as kneeling in a cathedral. The sacred is not separate from the ordinary; God meets us in both.',
      category: 'daily_life',
      relatedScripture: 'So whether you eat or drink or whatever you do, do it all for the glory of God.',
      scriptureReference: '1 Corinthians 10:31',
      discussionStarters: [
        'What ordinary activity could become a moment of worship?',
        'How do you remind yourself of God\'s presence throughout the day?',
        'What happens to your stress levels when you invite God into mundane tasks?',
      ],
      date: DateTime(2025, 1, 6),
    ),
    FaithPrompt(
      id: 'daily_02',
      question: 'What does it look like to love your neighbor in your specific context right now?',
      context: 'Jesus said the second greatest commandment is to love your neighbor as yourself. But who is your neighbor? The person next door, the coworker, the stranger online, the one who is hard to love.',
      category: 'daily_life',
      relatedScripture: 'Love your neighbor as yourself.',
      scriptureReference: 'Mark 12:31',
      discussionStarters: [
        'Who is the "neighbor" you find hardest to love?',
        'What is one practical act of love you could do this week?',
        'How does loving others connect to loving God?',
      ],
      date: DateTime(2025, 1, 7),
    ),
    FaithPrompt(
      id: 'daily_03',
      question: 'How do you handle the tension between being productive and being still before God?',
      context: 'Our culture rewards busyness and productivity. But God commands rest, sabbath, and stillness. Finding the balance between doing and being is one of the great challenges of the spiritual life.',
      category: 'daily_life',
      relatedScripture: 'Be still, and know that I am God.',
      scriptureReference: 'Psalm 46:10',
      discussionStarters: [
        'Do you feel guilty when you rest? Why?',
        'How does sabbath rest differ from just being lazy?',
        'What would change if you built intentional stillness into each day?',
      ],
      date: DateTime(2025, 1, 8),
    ),
    FaithPrompt(
      id: 'daily_04',
      question: 'How does your faith influence the way you use money and possessions?',
      context: 'Jesus talked about money more than almost any other topic. Our relationship with material things reveals the condition of our hearts and our trust in God\'s provision.',
      category: 'daily_life',
      relatedScripture: 'For where your treasure is, there your heart will be also.',
      scriptureReference: 'Matthew 6:21',
      discussionStarters: [
        'What does generosity look like in your current season?',
        'How do you discern between needs and wants?',
        'Does your spending reflect your stated values?',
      ],
      date: DateTime(2025, 1, 9),
    ),
    FaithPrompt(
      id: 'daily_05',
      question: 'How do you respond when your faith is tested by a bad day?',
      context: 'It is easy to praise God on mountaintops. The true test of faith comes in the valleys, on the bad days, when nothing goes right and God feels far away.',
      category: 'daily_life',
      relatedScripture: 'Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds, because you know that the testing of your faith produces perseverance.',
      scriptureReference: 'James 1:2-3',
      discussionStarters: [
        'What is your default reaction to a bad day?',
        'How can difficulty actually strengthen faith?',
        'What truth do you cling to when emotions say otherwise?',
      ],
      date: DateTime(2025, 1, 10),
    ),

    // ─── RELATIONSHIPS (5) ───────────────────────────────────────────
    FaithPrompt(
      id: 'rel_01',
      question: 'What does it mean to speak the truth in love, especially when the truth is hard?',
      context: 'Truth without love is brutality. Love without truth is sentimentality. The Bible calls us to both, speaking honestly while honoring the dignity of the other person.',
      category: 'relationships',
      relatedScripture: 'Instead, speaking the truth in love, we will grow to become in every respect the mature body of him who is the head, that is, Christ.',
      scriptureReference: 'Ephesians 4:15',
      discussionStarters: [
        'When has someone spoken a hard truth to you in a loving way?',
        'How do you decide when to speak up versus when to stay silent?',
        'What makes truth feel loving rather than attacking?',
      ],
      date: DateTime(2025, 1, 11),
    ),
    FaithPrompt(
      id: 'rel_02',
      question: 'How do you maintain unity with people who believe differently from you?',
      context: 'The body of Christ is diverse. Not every believer agrees on every doctrine, political stance, or cultural practice. Unity does not mean uniformity; it means love despite difference.',
      category: 'relationships',
      relatedScripture: 'Make every effort to keep the unity of the Spirit through the bond of peace.',
      scriptureReference: 'Ephesians 4:3',
      discussionStarters: [
        'Where do you draw the line between essential and non-essential beliefs?',
        'How do you disagree with someone without dismissing them?',
        'What can you learn from Christians who see things differently?',
      ],
      date: DateTime(2025, 1, 12),
    ),
    FaithPrompt(
      id: 'rel_03',
      question: 'How do you set healthy boundaries while still being loving and available?',
      context: 'Even Jesus withdrew from crowds to pray. Boundaries are not selfish; they are stewardship of the energy and capacity God has given you. You cannot pour from an empty cup.',
      category: 'relationships',
      relatedScripture: 'Very early in the morning, while it was still dark, Jesus got up, left the house and went off to a solitary place, where he prayed.',
      scriptureReference: 'Mark 1:35',
      discussionStarters: [
        'Where in your life do you need to set a boundary?',
        'How do you say no without feeling guilty?',
        'What did Jesus model about boundaries and availability?',
      ],
      date: DateTime(2025, 1, 13),
    ),
    FaithPrompt(
      id: 'rel_04',
      question: 'What does genuine community look like, and where do you find it?',
      context: 'We were not made to walk the faith journey alone. The early church met together, shared meals, confessed sins, and bore one another\'s burdens. True community requires vulnerability.',
      category: 'relationships',
      relatedScripture: 'Carry each other\'s burdens, and in this way you will fulfill the law of Christ.',
      scriptureReference: 'Galatians 6:2',
      discussionStarters: [
        'Do you have someone you can be completely honest with?',
        'What prevents you from being vulnerable in community?',
        'How can you create deeper community this month?',
      ],
      date: DateTime(2025, 1, 14),
    ),
    FaithPrompt(
      id: 'rel_05',
      question: 'How do you love someone who continually disappoints you?',
      context: 'Loving imperfect people is exhausting and necessary. God loves us in our constant failure. The question is not whether others deserve our love but whether we will imitate the love shown to us.',
      category: 'relationships',
      relatedScripture: 'Love is patient, love is kind. It does not envy, it does not boast, it is not proud.',
      scriptureReference: '1 Corinthians 13:4',
      discussionStarters: [
        'Who in your life tests your patience the most?',
        'How do you distinguish between enabling and loving?',
        'What would change if you loved that person without expecting change?',
      ],
      date: DateTime(2025, 1, 15),
    ),

    // ─── SUFFERING (5) ───────────────────────────────────────────────
    FaithPrompt(
      id: 'suf_01',
      question: 'How do you hold onto faith when God seems silent in your suffering?',
      context: 'The psalmists cried out to a God who seemed absent. Job questioned the heavens. Jesus Himself asked why He had been forsaken. Silence is not absence; sometimes the deepest work is done in quiet.',
      category: 'suffering',
      relatedScripture: 'My God, my God, why have you forsaken me? Why are you so far from saving me, so far from my cries of anguish?',
      scriptureReference: 'Psalm 22:1',
      discussionStarters: [
        'Have you experienced God\'s silence? What was that like?',
        'How do you distinguish between God being silent and you not listening?',
        'What sustained you during your darkest season?',
      ],
      date: DateTime(2025, 1, 16),
    ),
    FaithPrompt(
      id: 'suf_02',
      question: 'Can something good truly come from suffering? Have you experienced this?',
      context: 'Romans 8:28 promises that God works all things for good, but this does not mean all things are good. Suffering is real and painful. Yet many testify that their deepest growth came from their deepest pain.',
      category: 'suffering',
      relatedScripture: 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
      scriptureReference: 'Romans 8:28',
      discussionStarters: [
        'Share a time when suffering led to unexpected growth.',
        'How do you comfort someone without minimizing their pain?',
        'Is it okay to grieve and trust God at the same time?',
      ],
      date: DateTime(2025, 1, 17),
    ),
    FaithPrompt(
      id: 'suf_03',
      question: 'How do you comfort others who are suffering without offering cliches?',
      context: 'Job\'s friends started well: they sat with him in silence for seven days. Then they started talking, and everything went wrong. Sometimes the ministry of presence is more powerful than words.',
      category: 'suffering',
      relatedScripture: 'Praise be to the God and Father of our Lord Jesus Christ, the Father of compassion and the God of all comfort, who comforts us in all our troubles, so that we can comfort those in any trouble.',
      scriptureReference: '2 Corinthians 1:3-4',
      discussionStarters: [
        'What is the most comforting thing someone has done for you?',
        'What well-meaning phrases actually hurt more than help?',
        'How can your own pain equip you to comfort others?',
      ],
      date: DateTime(2025, 1, 18),
    ),
    FaithPrompt(
      id: 'suf_04',
      question: 'If God is good, why does He allow innocent people to suffer?',
      context: 'This is perhaps the oldest and hardest question in theology. There are no easy answers, but there is a God who entered into human suffering Himself. The cross does not explain suffering; it transforms it.',
      category: 'suffering',
      relatedScripture: 'He was despised and rejected by mankind, a man of suffering, and familiar with pain.',
      scriptureReference: 'Isaiah 53:3',
      discussionStarters: [
        'How do you hold this tension without losing faith?',
        'Does it help to know God Himself suffered?',
        'What would you say to someone angry at God over their suffering?',
      ],
      date: DateTime(2025, 1, 19),
    ),
    FaithPrompt(
      id: 'suf_05',
      question: 'How does the hope of eternity change the way you face trials today?',
      context: 'Paul described present sufferings as light and momentary compared to eternal glory. This is not dismissing pain but putting it in perspective. The story is not over. The best chapter is yet to come.',
      category: 'suffering',
      relatedScripture: 'For our light and momentary troubles are achieving for us an eternal glory that far outweighs them all.',
      scriptureReference: '2 Corinthians 4:17',
      discussionStarters: [
        'Does thinking about eternity help in the middle of pain?',
        'How do you balance living for now and hoping for then?',
        'What in eternity are you most looking forward to?',
      ],
      date: DateTime(2025, 1, 20),
    ),

    // ─── PURPOSE (5) ─────────────────────────────────────────────────
    FaithPrompt(
      id: 'pur_01',
      question: 'What do you believe you were created to do, and how are you pursuing it?',
      context: 'Every person is uniquely designed with gifts, passions, and experiences that point toward a purpose. Discovering that purpose often comes not from a single revelation but from faithful daily obedience.',
      category: 'purpose',
      relatedScripture: 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.',
      scriptureReference: 'Jeremiah 29:11',
      discussionStarters: [
        'What activities make you feel most alive?',
        'How do your gifts and passions intersect with the world\'s needs?',
        'What would you do if you knew you could not fail?',
      ],
      date: DateTime(2025, 1, 21),
    ),
    FaithPrompt(
      id: 'pur_02',
      question: 'How do you find meaning in seasons of waiting or insignificance?',
      context: 'Moses spent 40 years in the desert before leading Israel. David tended sheep before becoming king. Seasons of hiddenness are not wasted; they are preparation for what God has planned.',
      category: 'purpose',
      relatedScripture: 'But those who hope in the Lord will renew their strength.',
      scriptureReference: 'Isaiah 40:31',
      discussionStarters: [
        'Are you in a season of waiting? What is God teaching you?',
        'How do you measure significance in God\'s economy versus the world\'s?',
        'What small, faithful acts might be preparing you for something bigger?',
      ],
      date: DateTime(2025, 1, 22),
    ),
    FaithPrompt(
      id: 'pur_03',
      question: 'Is your work worship? How do you bring purpose to your job or daily responsibilities?',
      context: 'Colossians says to do everything as if working for the Lord. Whether you are a CEO or a stay-at-home parent, your work has dignity and purpose when offered to God.',
      category: 'purpose',
      relatedScripture: 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.',
      scriptureReference: 'Colossians 3:23',
      discussionStarters: [
        'How would your work change if you saw God as your primary audience?',
        'What aspect of your work feels meaningless? Can it be redeemed?',
        'How do you serve others through your daily work?',
      ],
      date: DateTime(2025, 1, 23),
    ),
    FaithPrompt(
      id: 'pur_04',
      question: 'What legacy do you want to leave, and what are you doing today to build it?',
      context: 'Legacy is not about fame; it is about faithfulness. The lives you touch, the character you build, and the faith you pass on outlast any material achievement.',
      category: 'purpose',
      relatedScripture: 'Remember your leaders, who spoke the word of God to you. Consider the outcome of their way of life and imitate their faith.',
      scriptureReference: 'Hebrews 13:7',
      discussionStarters: [
        'Who has left a meaningful spiritual legacy in your life?',
        'If your life ended today, what would people remember?',
        'What one change could you make to build a better legacy?',
      ],
      date: DateTime(2025, 1, 24),
    ),
    FaithPrompt(
      id: 'pur_05',
      question: 'How do you discern between your own ambitions and God\'s calling?',
      context: 'Not every desire is from God, and not every opportunity is a calling. Discernment requires humility, prayer, counsel from wise believers, and alignment with Scripture.',
      category: 'purpose',
      relatedScripture: 'Delight yourself in the Lord, and he will give you the desires of your heart.',
      scriptureReference: 'Psalm 37:4',
      discussionStarters: [
        'How do you test whether an ambition is from God or from ego?',
        'Who in your life helps you discern God\'s direction?',
        'What would you be willing to give up if God asked?',
      ],
      date: DateTime(2025, 1, 25),
    ),

    // ─── GROWTH (5) ──────────────────────────────────────────────────
    FaithPrompt(
      id: 'gro_01',
      question: 'What spiritual discipline has transformed your life the most, and why?',
      context: 'Spiritual disciplines like prayer, fasting, meditation, and service are not about earning God\'s favor. They are about positioning ourselves to receive what God freely gives. They create space for transformation.',
      category: 'growth',
      relatedScripture: 'Train yourself to be godly. For physical training is of some value, but godliness has value for all things.',
      scriptureReference: '1 Timothy 4:7-8',
      discussionStarters: [
        'Which discipline is easiest for you? Which is hardest?',
        'How do you maintain consistency without legalism?',
        'What new discipline could you try this month?',
      ],
      date: DateTime(2025, 1, 26),
    ),
    FaithPrompt(
      id: 'gro_02',
      question: 'How do you recognize the Holy Spirit\'s work in your life?',
      context: 'The fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, and self-control. When you see these growing in your life, you are seeing the Spirit at work.',
      category: 'growth',
      relatedScripture: 'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.',
      scriptureReference: 'Galatians 5:22-23',
      discussionStarters: [
        'Which fruit of the Spirit is most evident in your life?',
        'Which one do you need most right now?',
        'How is the Spirit\'s work different from self-improvement?',
      ],
      date: DateTime(2025, 1, 27),
    ),
    FaithPrompt(
      id: 'gro_03',
      question: 'What does it mean to "die to self" daily, and is this even possible?',
      context: 'Jesus said whoever wants to save their life must lose it. Dying to self means surrendering our ego, our plans, and our demands so that Christ lives through us. It is a daily, sometimes hourly, choice.',
      category: 'growth',
      relatedScripture: 'I have been crucified with Christ and I no longer live, but Christ lives in me.',
      scriptureReference: 'Galatians 2:20',
      discussionStarters: [
        'What part of "self" is hardest for you to surrender?',
        'How does dying to self actually lead to a fuller life?',
        'What does practical self-denial look like in modern life?',
      ],
      date: DateTime(2025, 1, 28),
    ),
    FaithPrompt(
      id: 'gro_04',
      question: 'How has failure shaped your faith more than success?',
      context: 'Peter denied Jesus three times and became the rock of the church. Failure is not final in God\'s kingdom. It is often the beginning of the deepest transformation.',
      category: 'growth',
      relatedScripture: 'The righteous may fall seven times but still get up, but the wicked will stumble into calamity.',
      scriptureReference: 'Proverbs 24:16',
      discussionStarters: [
        'Share a failure that became a turning point in your faith.',
        'How does God\'s response to failure differ from the world\'s?',
        'What are you afraid of failing at right now?',
      ],
      date: DateTime(2025, 1, 29),
    ),
    FaithPrompt(
      id: 'gro_05',
      question: 'If you could ask God one question and get an immediate answer, what would it be?',
      context: 'Our deepest questions often reveal our deepest needs. What we want to ask God reveals what we value, what we fear, and where we need to grow in trust.',
      category: 'growth',
      relatedScripture: 'Call to me and I will answer you and tell you great and unsearchable things you do not know.',
      scriptureReference: 'Jeremiah 33:3',
      discussionStarters: [
        'What does your question reveal about your current season?',
        'Are you willing to accept an answer you do not expect?',
        'How might silence itself be an answer?',
      ],
      date: DateTime(2025, 1, 30),
    ),
  ];

  static FaithPrompt getDailyPrompt() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return all[dayOfYear % all.length];
  }

  static List<FaithPrompt> byCategory(String category) {
    return all.where((p) => p.category == category).toList();
  }

  static FaithPrompt? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
