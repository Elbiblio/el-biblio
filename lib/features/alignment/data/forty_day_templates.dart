import '../domain/models/forty_day_goal.dart';

/// Pre-built 40-day goal templates for different categories.
class FortyDayTemplates {
  const FortyDayTemplates._();

  static List<FortyDayGoal> get allTemplates => [
        _prayerLifeTemplate,
        _scriptureStudyTemplate,
        _serviceTemplate,
        _gratitudeTemplate,
        _forgivenessTemplate,
        _fastingTemplate,
      ];

  // ── 1. PRAYER LIFE ──────────────────────────────────────────────────
  static FortyDayGoal get _prayerLifeTemplate => FortyDayGoal(
        id: 'tpl_prayer',
        title: 'Deepening Your Prayer Life',
        category: 'Prayer Life',
        description:
            'Transform your prayer life over 40 days, moving from routine to intimate communion with God. Each week builds on the last, gradually expanding your capacity for deeper prayer.',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 40)),
        dailyTasks: _buildPrayerTasks(),
      );

  static List<DailyGoalTask> _buildPrayerTasks() {
    return [
      // Week 1: Foundation (5 min)
      const DailyGoalTask(dayNumber: 1, title: 'The First Word', description: 'Begin your day by speaking to God before anything else. Simply say "Good morning, Lord" and sit in silence for 5 minutes.', durationMinutes: 5, reflectionPrompt: 'What did you notice when you paused to be still?', relatedVerse: 'Psalm 46:10'),
      const DailyGoalTask(dayNumber: 2, title: 'Gratitude Prayer', description: 'Pray by listing 5 things you are truly grateful for. Speak each one aloud.', durationMinutes: 5, reflectionPrompt: 'Which blessing surprised you as you named it?', relatedVerse: '1 Thessalonians 5:18'),
      const DailyGoalTask(dayNumber: 3, title: 'Confession Prayer', description: 'Humbly bring to God something you have been carrying. Ask for forgiveness and receive it.', durationMinutes: 5, reflectionPrompt: 'How do you feel after releasing this burden?', relatedVerse: '1 John 1:9'),
      const DailyGoalTask(dayNumber: 4, title: 'Intercession', description: 'Pray specifically for three people by name. Ask God to show you what they need.', durationMinutes: 5, reflectionPrompt: 'Did any specific prayer feel urgent to you?', relatedVerse: 'James 5:16'),
      const DailyGoalTask(dayNumber: 5, title: 'Listening Prayer', description: 'After praying, sit in silence for 3 minutes. Simply listen.', durationMinutes: 8, reflectionPrompt: 'Did you sense anything during the silence?', relatedVerse: '1 Samuel 3:10'),
      const DailyGoalTask(dayNumber: 6, title: 'Prayer Walk', description: 'Take a short walk and pray as you go. Let creation inspire your worship.', durationMinutes: 10, reflectionPrompt: 'How did movement change your prayer experience?', relatedVerse: 'Psalm 19:1'),
      const DailyGoalTask(dayNumber: 7, title: 'Sabbath Prayer', description: 'Rest and review the week. Thank God for each day and what you learned.', durationMinutes: 10, reflectionPrompt: 'What was the highlight of your prayer journey this week?', relatedVerse: 'Genesis 2:3'),

      // Week 2: Deepening (10 min)
      const DailyGoalTask(dayNumber: 8, title: 'ACTS Model', description: 'Pray using the ACTS framework: Adoration, Confession, Thanksgiving, Supplication.', durationMinutes: 10, reflectionPrompt: 'Which part of ACTS came most naturally?', relatedVerse: 'Matthew 6:9-13'),
      const DailyGoalTask(dayNumber: 9, title: 'Praying Scripture', description: 'Read Psalm 23 slowly, turning each verse into a personal prayer.', durationMinutes: 10, reflectionPrompt: 'Which verse resonated most deeply?', relatedVerse: 'Psalm 23:1'),
      const DailyGoalTask(dayNumber: 10, title: 'Surrender Prayer', description: 'Identify one area of your life you have been controlling. Surrender it to God.', durationMinutes: 10, reflectionPrompt: 'What is hardest to surrender and why?', relatedVerse: 'Proverbs 3:5-6'),
      const DailyGoalTask(dayNumber: 11, title: 'Worship Prayer', description: 'Play worship music and let it become your prayer. Sing or hum along.', durationMinutes: 10, reflectionPrompt: 'How did music open your heart differently?', relatedVerse: 'Psalm 100:1-2'),
      const DailyGoalTask(dayNumber: 12, title: 'Lament Prayer', description: 'Bring a real pain or frustration to God honestly. He can handle it.', durationMinutes: 10, reflectionPrompt: 'Did honesty with God feel freeing or frightening?', relatedVerse: 'Psalm 13:1-2'),
      const DailyGoalTask(dayNumber: 13, title: 'Forgiveness Prayer', description: 'Pray for someone who has hurt you. Ask God to bless them.', durationMinutes: 10, reflectionPrompt: 'How did it feel to bless someone who hurt you?', relatedVerse: 'Matthew 5:44'),
      const DailyGoalTask(dayNumber: 14, title: 'Weekly Rest', description: 'Reflect on two weeks of prayer. Journal what has changed in your spirit.', durationMinutes: 10, reflectionPrompt: 'How has your relationship with God shifted?', relatedVerse: 'Psalm 27:4'),

      // Week 3: Expanding (15 min)
      const DailyGoalTask(dayNumber: 15, title: 'Extended Silence', description: 'Spend 15 minutes in silence before God. Let thoughts pass without clinging to them.', durationMinutes: 15, reflectionPrompt: 'What did you notice about your inner world?', relatedVerse: 'Habakkuk 2:20'),
      const DailyGoalTask(dayNumber: 16, title: 'Journaling Prayer', description: 'Write a letter to God. Be completely honest about where you are.', durationMinutes: 15, reflectionPrompt: 'What truth emerged as you wrote?', relatedVerse: 'Psalm 62:8'),
      const DailyGoalTask(dayNumber: 17, title: 'Neighborhood Prayer', description: 'Walk through your neighborhood and pray for each home you pass.', durationMinutes: 15, reflectionPrompt: 'How did praying for strangers change your perspective?', relatedVerse: 'Jeremiah 29:7'),
      const DailyGoalTask(dayNumber: 18, title: 'Fasting Prayer', description: 'Skip one meal today and use that time to pray instead.', durationMinutes: 15, reflectionPrompt: 'How did physical hunger sharpen your spiritual hunger?', relatedVerse: 'Matthew 6:16-18'),
      const DailyGoalTask(dayNumber: 19, title: 'Body Prayer', description: 'Pray in different physical postures: kneeling, standing with hands raised, lying prostrate.', durationMinutes: 15, reflectionPrompt: 'Which posture felt most meaningful?', relatedVerse: 'Psalm 95:6'),
      const DailyGoalTask(dayNumber: 20, title: 'Examen Prayer', description: 'Review your day with God. Where did you see Him? Where did you resist Him?', durationMinutes: 15, reflectionPrompt: 'Where was God most present today?', relatedVerse: 'Psalm 139:23-24'),
      const DailyGoalTask(dayNumber: 21, title: 'Halfway Celebration', description: 'You are halfway there. Spend time thanking God for your persistence and His faithfulness.', durationMinutes: 15, reflectionPrompt: 'How has 21 days of prayer changed you?', relatedVerse: 'Philippians 1:6'),

      // Week 4: Maturing (15 min)
      const DailyGoalTask(dayNumber: 22, title: 'Lectio Divina', description: 'Practice sacred reading: Read Romans 8:28-39 slowly four times, listening for God\'s word to you.', durationMinutes: 15, reflectionPrompt: 'What word or phrase did God highlight for you?', relatedVerse: 'Romans 8:28'),
      const DailyGoalTask(dayNumber: 23, title: 'Spiritual Warfare Prayer', description: 'Put on the full armor of God (Ephesians 6). Pray through each piece.', durationMinutes: 15, reflectionPrompt: 'Which piece of armor do you need most today?', relatedVerse: 'Ephesians 6:10-18'),
      const DailyGoalTask(dayNumber: 24, title: 'Family Blessing', description: 'Pray a specific blessing over each member of your family or household.', durationMinutes: 15, reflectionPrompt: 'What blessing felt most important to declare?', relatedVerse: 'Numbers 6:24-26'),
      const DailyGoalTask(dayNumber: 25, title: 'Community Prayer', description: 'Pray with or for your church community. Intercede for your pastor and leaders.', durationMinutes: 15, reflectionPrompt: 'How does praying for leaders change your perspective on them?', relatedVerse: '1 Timothy 2:1-2'),
      const DailyGoalTask(dayNumber: 26, title: 'Contemplative Prayer', description: 'Choose one name of God and meditate on it for the full time.', durationMinutes: 15, reflectionPrompt: 'Which name of God spoke to your current situation?', relatedVerse: 'Exodus 3:14'),
      const DailyGoalTask(dayNumber: 27, title: 'Declaration Prayer', description: 'Speak 10 declarations over your life based on Scripture.', durationMinutes: 15, reflectionPrompt: 'Which declaration felt most powerful?', relatedVerse: 'Romans 8:37'),
      const DailyGoalTask(dayNumber: 28, title: 'Gratitude Overflow', description: 'List 28 things you are grateful for: one for each day of this journey so far.', durationMinutes: 15, reflectionPrompt: 'Did gratitude come easier than it did on Day 2?', relatedVerse: 'Psalm 103:1-5'),

      // Week 5: Sustaining (20 min)
      const DailyGoalTask(dayNumber: 29, title: 'Extended Intercession', description: 'Pray for 20 minutes for people beyond your immediate circle: the nations, the persecuted church.', durationMinutes: 20, reflectionPrompt: 'How has your prayer circle expanded?', relatedVerse: 'Psalm 2:8'),
      const DailyGoalTask(dayNumber: 30, title: 'Milestone Reflection', description: 'You have prayed for 30 days. Write a letter from God to yourself, reflecting what you think He would say.', durationMinutes: 20, reflectionPrompt: 'What did God\'s letter to you reveal?', relatedVerse: 'Jeremiah 31:3'),
      const DailyGoalTask(dayNumber: 31, title: 'Prayer for Enemies', description: 'Pray genuinely for someone you struggle with. Ask God to change your heart toward them.', durationMinutes: 20, reflectionPrompt: 'How has your heart softened through this journey?', relatedVerse: 'Luke 6:27-28'),
      const DailyGoalTask(dayNumber: 32, title: 'Covenant Prayer', description: 'Write a prayer covenant: what you commit to God and what you are trusting Him for.', durationMinutes: 20, reflectionPrompt: 'What commitment are you making to God?', relatedVerse: 'Joshua 24:15'),
      const DailyGoalTask(dayNumber: 33, title: 'Breath Prayer', description: 'Choose a short phrase and pray it with each breath throughout the day.', durationMinutes: 20, reflectionPrompt: 'How did continuous prayer change your day?', relatedVerse: '1 Thessalonians 5:17'),
      const DailyGoalTask(dayNumber: 34, title: 'Creative Prayer', description: 'Express your prayer through art, music, or poetry. Let creativity meet devotion.', durationMinutes: 20, reflectionPrompt: 'What did creating as prayer unlock in you?', relatedVerse: 'Psalm 150:6'),
      const DailyGoalTask(dayNumber: 35, title: 'Generosity Prayer', description: 'Ask God to show you someone to bless today. Pray, then act on it.', durationMinutes: 20, reflectionPrompt: 'What happened when prayer became action?', relatedVerse: 'Acts 20:35'),

      // Week 6: Finishing Strong (20 min)
      const DailyGoalTask(dayNumber: 36, title: 'Legacy Prayer', description: 'Pray for the next generation. Ask God what you are called to pass on.', durationMinutes: 20, reflectionPrompt: 'What spiritual legacy do you want to leave?', relatedVerse: 'Psalm 78:4'),
      const DailyGoalTask(dayNumber: 37, title: 'Prophetic Prayer', description: 'Ask God to reveal His vision for your next season. Listen and write what comes.', durationMinutes: 20, reflectionPrompt: 'What is God saying about your future?', relatedVerse: 'Jeremiah 29:11'),
      const DailyGoalTask(dayNumber: 38, title: 'Unity Prayer', description: 'Pray for unity in your family, church, and community.', durationMinutes: 20, reflectionPrompt: 'Where is God calling you to be a peacemaker?', relatedVerse: 'John 17:21'),
      const DailyGoalTask(dayNumber: 39, title: 'Consecration', description: 'Dedicate yourself afresh to God. Lay down everything and pick up only what He gives back.', durationMinutes: 20, reflectionPrompt: 'What are you laying down? What is He giving back?', relatedVerse: 'Romans 12:1'),
      const DailyGoalTask(dayNumber: 40, title: 'Celebration and Commission', description: 'Celebrate 40 days of faithful prayer. Write your prayer mission statement going forward.', durationMinutes: 20, reflectionPrompt: 'Who have you become through these 40 days?', relatedVerse: 'Hebrews 12:1-2'),
    ];
  }

  // ── 2. SCRIPTURE STUDY ──────────────────────────────────────────────
  static FortyDayGoal get _scriptureStudyTemplate => FortyDayGoal(
        id: 'tpl_scripture',
        title: 'Immersed in the Word',
        category: 'Scripture Study',
        description:
            'A 40-day journey through key passages of Scripture, building a foundation of biblical literacy and personal encounter with God\'s word.',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 40)),
        dailyTasks: _buildScriptureTasks(),
      );

  static List<DailyGoalTask> _buildScriptureTasks() {
    const passages = [
      ('Genesis 1', 'The Creator God', 'What does creation reveal about God\'s character?'),
      ('Genesis 12:1-9', 'The Call of Abraham', 'Where is God calling you to step out in faith?'),
      ('Exodus 3:1-15', 'The Burning Bush', 'Where have you encountered God in unexpected places?'),
      ('Psalm 1', 'The Blessed Life', 'What does it mean to delight in God\'s law?'),
      ('Psalm 23', 'The Good Shepherd', 'Where do you need the Shepherd to lead you?'),
      ('Psalm 51', 'A Contrite Heart', 'What do you need to confess before God?'),
      ('Psalm 139', 'Known Completely', 'How does being fully known by God make you feel?'),
      ('Proverbs 3:1-12', 'Trust in the Lord', 'In what area do you need to lean not on your own understanding?'),
      ('Isaiah 40:28-31', 'Renewed Strength', 'Where do you feel weary and need renewal?'),
      ('Isaiah 53', 'The Suffering Servant', 'How does Christ\'s suffering change your perspective on pain?'),
      ('Jeremiah 29:11-14', 'Plans for Hope', 'What hopes do you have for your future with God?'),
      ('Matthew 5:1-12', 'The Beatitudes', 'Which beatitude challenges you most?'),
      ('Matthew 6:25-34', 'Do Not Worry', 'What are you anxious about that you can release?'),
      ('Matthew 7:24-29', 'Rock or Sand', 'How are you building your life on the rock?'),
      ('Mark 4:1-20', 'The Sower', 'What kind of soil represents your heart right now?'),
      ('Luke 10:38-42', 'Mary and Martha', 'Are you more Mary or Martha in this season?'),
      ('Luke 15:11-32', 'The Prodigal Son', 'Which character in this story are you most like?'),
      ('John 1:1-18', 'The Word Became Flesh', 'What does it mean that God became human for you?'),
      ('John 3:1-21', 'Born Again', 'How has your life been transformed by new birth?'),
      ('John 10:1-18', 'The Good Shepherd', 'How do you recognize the Shepherd\'s voice?'),
      ('John 15:1-17', 'The Vine and Branches', 'Are you abiding or striving?'),
      ('Acts 2:1-21', 'Pentecost', 'Where do you need the Holy Spirit\'s power?'),
      ('Romans 5:1-11', 'Peace with God', 'How has suffering produced character in your life?'),
      ('Romans 8:1-17', 'No Condemnation', 'Where do you still carry condemnation?'),
      ('Romans 8:28-39', 'More Than Conquerors', 'What can separate you from God\'s love? Nothing!'),
      ('Romans 12:1-8', 'Living Sacrifice', 'How can you present your body as a living sacrifice today?'),
      ('1 Corinthians 13', 'The Love Chapter', 'Where does your love fall short?'),
      ('2 Corinthians 4:7-18', 'Treasure in Jars of Clay', 'How does weakness reveal God\'s power?'),
      ('Galatians 5:16-26', 'Fruit of the Spirit', 'Which fruit needs the most cultivation in your life?'),
      ('Ephesians 2:1-10', 'Saved by Grace', 'How does grace change your approach to life?'),
      ('Ephesians 6:10-20', 'The Armor of God', 'Which piece of armor do you need most?'),
      ('Philippians 2:1-11', 'The Mind of Christ', 'Where can you take on a servant posture?'),
      ('Philippians 4:4-9', 'Rejoice Always', 'What is worthy of your thought-life?'),
      ('Colossians 3:1-17', 'Set Your Mind Above', 'What old self do you need to put off?'),
      ('Hebrews 11:1-16', 'The Hall of Faith', 'What are you believing God for by faith?'),
      ('Hebrews 12:1-3', 'Run the Race', 'What weight do you need to lay aside?'),
      ('James 1:2-18', 'Trials and Temptation', 'How is God using a current trial for your good?'),
      ('1 Peter 2:4-10', 'A Chosen People', 'How does your identity as chosen change your daily life?'),
      ('1 John 4:7-21', 'God Is Love', 'How can you love more boldly this week?'),
      ('Revelation 21:1-7', 'All Things New', 'What gives you hope about eternity?'),
    ];

    return List.generate(40, (i) {
      final (ref, title, prompt) = passages[i];
      return DailyGoalTask(
        dayNumber: i + 1,
        title: 'Day ${i + 1}: $title',
        description: 'Read $ref slowly. Read it twice. Journal your observations, questions, and one personal application.',
        durationMinutes: i < 7 ? 10 : (i < 21 ? 15 : 20),
        reflectionPrompt: prompt,
        relatedVerse: ref,
      );
    });
  }

  // ── 3. SERVICE ──────────────────────────────────────────────────────
  static FortyDayGoal get _serviceTemplate => FortyDayGoal(
        id: 'tpl_service',
        title: 'Hands and Feet of Christ',
        category: 'Service',
        description:
            'Discover the joy of serving others over 40 days. Start with small acts of kindness and grow into a lifestyle of generosity and love.',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 40)),
        dailyTasks: _buildServiceTasks(),
      );

  static List<DailyGoalTask> _buildServiceTasks() {
    const tasks = [
      ('Pray for Eyes to See', 'Ask God to show you one need around you today. Simply notice.', 'What need did you see?'),
      ('Smile and Greet', 'Genuinely greet five people today with warmth and eye contact.', 'How did intentional greeting change your interactions?'),
      ('Encouragement Note', 'Write an encouraging message to someone who needs it.', 'How did it feel to encourage someone?'),
      ('Listen Deeply', 'Give someone your full, undivided attention today.', 'What did you learn by truly listening?'),
      ('Small Act of Kindness', 'Do one small unexpected kindness for a stranger.', 'How did the stranger respond?'),
      ('Thank Someone', 'Thank someone who usually goes unnoticed: a janitor, server, or bus driver.', 'What did gratitude unlock in you?'),
      ('Sabbath Rest', 'Rest and reflect on your first week of intentional service.', 'What surprised you this week?'),
      ('Serve at Home', 'Do a household chore that is usually someone else\'s responsibility.', 'How did serving at home feel different?'),
      ('Feed Someone', 'Buy coffee or a meal for someone today.', 'What did you notice about giving?'),
      ('Phone Call of Love', 'Call someone you have not spoken to in a while. Check on them.', 'What did reconnecting teach you?'),
      ('Volunteer Research', 'Research one local organization where you could volunteer.', 'What drew you to that organization?'),
      ('Pray for a Stranger', 'Choose a stranger you see today and silently pray for them.', 'How did praying for a stranger change your perspective?'),
      ('Gift of Time', 'Give 30 minutes of your time to help someone with their task.', 'How did helping with their burden affect you?'),
      ('Reflect on Serving', 'Journal about how service is changing your heart.', 'How is serving transforming you?'),
      ('Teach Something', 'Share a skill or knowledge with someone who could benefit.', 'What was it like to teach?'),
      ('Care Package', 'Put together a small care package for someone going through difficulty.', 'How did preparing the gift change your heart?'),
      ('Forgive Someone', 'Extend grace to someone who has wronged you, even silently.', 'How did forgiveness free you?'),
      ('Neighborhood Service', 'Do something for your neighborhood: pick up litter, water a plant, greet a neighbor.', 'How does your neighborhood look different?'),
      ('Service at Church', 'Arrive early or stay late at church to help with setup or cleanup.', 'How did behind-the-scenes service feel?'),
      ('Halfway Celebration', 'Celebrate 20 days of service. How has it changed you?', 'What is the biggest change you have noticed?'),
      ('Mentoring Moment', 'Share something you have learned with someone younger in faith.', 'What was it like to mentor?'),
      ('Anonymous Gift', 'Give something anonymously to someone in need.', 'How did giving without recognition feel?'),
      ('Hospital or Care Visit', 'Visit or call someone who is sick or homebound.', 'What did presence mean to them?'),
      ('Children\'s Ministry', 'Spend time serving or playing with children.', 'What did children teach you about faith?'),
      ('Write a Recommendation', 'Write a genuine recommendation or review for someone\'s work or character.', 'How did affirming someone change your view of them?'),
      ('Environmental Care', 'Spend time caring for creation: garden, plant, or clean up nature.', 'How does caring for creation honor God?'),
      ('Financial Generosity', 'Give financially above your norm to a person or cause.', 'What did generous giving stir in you?'),
      ('Cook for Someone', 'Prepare a meal for someone who could use the blessing.', 'What did the act of cooking for another mean?'),
      ('Bridge-Building', 'Reach out to someone outside your usual circle.', 'How did stepping outside your comfort zone feel?'),
      ('Serving Leaders', 'Do something to support and encourage a leader in your life.', 'How does serving leaders differ from other service?'),
      ('Advocate for Justice', 'Learn about one injustice issue and pray about your role in it.', 'What injustice stirred your heart?'),
      ('Host Someone', 'Invite someone into your home for a meal or conversation.', 'What did hospitality open up?'),
      ('Workplace Service', 'Go above and beyond at work specifically to bless a colleague.', 'How did service at work change the atmosphere?'),
      ('Digital Kindness', 'Leave three positive comments online or send encouraging messages.', 'How can you be a light in digital spaces?'),
      ('Sacrifice Comfort', 'Give up something comfortable today to serve someone else.', 'What did sacrifice teach you?'),
      ('Family Service Day', 'Serve alongside family members together.', 'How did serving together strengthen your bond?'),
      ('Share Your Story', 'Share how God has changed you with someone who needs hope.', 'What happened when you shared your story?'),
      ('Create Something', 'Make something with your hands to bless someone: a card, craft, or note.', 'How did creating for others feel?'),
      ('Pray for the World', 'Spend extended time praying for global needs and missions.', 'How has your view of the world changed through 40 days of service?'),
      ('Commission and Celebration', 'Commit to a lifestyle of service. Write your service mission statement.', 'Who have you become through serving?'),
    ];

    return List.generate(40, (i) {
      final (title, desc, prompt) = tasks[i];
      return DailyGoalTask(
        dayNumber: i + 1,
        title: 'Day ${i + 1}: $title',
        description: desc,
        durationMinutes: i < 7 ? 10 : (i < 21 ? 15 : 20),
        reflectionPrompt: prompt,
        relatedVerse: _serviceVerses[i],
      );
    });
  }

  static const List<String> _serviceVerses = [
    'Matthew 25:35', 'Proverbs 15:13', 'Hebrews 3:13', 'James 1:19',
    'Galatians 6:2', 'Colossians 3:17', 'Hebrews 4:9-10', 'Galatians 5:13',
    'Proverbs 22:9', 'Philippians 2:4', 'Isaiah 58:10', 'Ephesians 6:18',
    'Ecclesiastes 4:9-10', 'Mark 10:45', 'Proverbs 27:17', 'Romans 12:13',
    'Ephesians 4:32', 'Jeremiah 29:7', '1 Peter 4:10', 'Philippians 1:6',
    'Titus 2:7-8', 'Matthew 6:3-4', 'Matthew 25:36', 'Matthew 18:3',
    'Proverbs 31:26', 'Genesis 1:28', '2 Corinthians 9:7', 'Romans 12:10',
    'John 13:34', '1 Timothy 5:17', 'Micah 6:8', 'Romans 12:13',
    'Colossians 3:23', 'Proverbs 16:24', 'Luke 9:23', 'Joshua 24:15',
    '2 Timothy 1:8', 'Colossians 3:23-24', 'Psalm 2:8', '1 Peter 2:9',
  ];

  // ── 4. GRATITUDE ────────────────────────────────────────────────────
  static FortyDayGoal get _gratitudeTemplate => FortyDayGoal(
        id: 'tpl_gratitude',
        title: 'A Grateful Heart',
        category: 'Gratitude',
        description:
            'Rewire your heart toward thankfulness over 40 days. Discover how gratitude transforms every area of life.',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 40)),
        dailyTasks: List.generate(40, (i) {
          final day = i + 1;
          final data = _gratitudeTasks[i];
          return DailyGoalTask(
            dayNumber: day,
            title: 'Day $day: ${data.$1}',
            description: data.$2,
            durationMinutes: day <= 7 ? 5 : (day <= 21 ? 10 : 15),
            reflectionPrompt: data.$3,
            relatedVerse: data.$4,
          );
        }),
      );

  static const List<(String, String, String, String)> _gratitudeTasks = [
    ('Awakening Gratitude', 'Before getting out of bed, name 3 things you are grateful for.', 'What are you most thankful for today?', 'Psalm 118:24'),
    ('Grateful for People', 'Name 3 people you are grateful for and why.', 'Who has shaped your life most?', 'Philippians 1:3'),
    ('Grateful for Provision', 'Thank God for specific material blessings: home, food, clothing.', 'What provision do you take for granted?', 'Matthew 6:11'),
    ('Grateful in Difficulty', 'Find something to be thankful for in a current struggle.', 'What is the hidden gift in your trial?', 'James 1:2-4'),
    ('Grateful for Creation', 'Spend time outdoors noticing the beauty of God\'s creation.', 'What in nature fills you with awe?', 'Psalm 19:1'),
    ('Gratitude Letter', 'Write a letter of thanks to someone who changed your life.', 'How did expressing gratitude feel?', '2 Corinthians 9:15'),
    ('Sabbath Gratitude', 'Compile a gratitude list from the entire week.', 'What patterns of blessing did you notice?', 'Psalm 136:1'),
    ('Grateful for Your Body', 'Thank God for specific physical abilities and senses.', 'What physical blessing do you overlook?', 'Psalm 139:14'),
    ('Grateful for Forgiveness', 'Reflect on the gift of grace and forgiveness in your life.', 'How has forgiveness changed your story?', 'Ephesians 1:7'),
    ('Grateful for Community', 'Thank God for your church, friends, and spiritual family.', 'Who in your community blesses you most?', 'Hebrews 10:24-25'),
    ('Grateful for Growth', 'Look at how far you have come spiritually in the past year.', 'What growth surprises you?', 'Philippians 1:6'),
    ('Grateful for Work', 'Thank God for the ability and opportunity to work.', 'What about your work brings meaning?', 'Colossians 3:23'),
    ('Grateful for Scripture', 'Thank God for a specific Bible verse that has carried you.', 'Which verse has been your anchor?', 'Psalm 119:105'),
    ('Midweek Reflection', 'Journal 14 things you are grateful for: one for each day so far.', 'How is gratitude reshaping your perspective?', '1 Thessalonians 5:18'),
    ('Grateful for Memories', 'Thank God for a specific beautiful memory.', 'What memory fills you with joy?', 'Psalm 77:11'),
    ('Grateful for Music', 'Listen to a worship song and express gratitude through it.', 'How does music unlock worship?', 'Psalm 100:1-2'),
    ('Grateful for Seasons', 'Thank God for the season of life you are in, even if it is hard.', 'What is this season teaching you?', 'Ecclesiastes 3:1'),
    ('Grateful for Challenges', 'Name a challenge that ultimately grew your character.', 'How did hardship build you?', 'Romans 5:3-5'),
    ('Grateful for Home', 'Walk through your home and thank God for each room and its purpose.', 'What makes your home a sanctuary?', 'Joshua 24:15'),
    ('Halfway Gratitude', 'Write a prayer of thanksgiving for 20 days of gratitude.', 'How is your default mindset shifting?', 'Psalm 103:1-5'),
    ('Grateful for Failure', 'Thank God for a failure that taught you something valuable.', 'What did failure teach you that success could not?', '2 Corinthians 12:9'),
    ('Grateful for Silence', 'Sit in silence and let gratitude rise naturally.', 'What bubbled up in the silence?', 'Psalm 46:10'),
    ('Grateful for Strangers', 'Thank God for kind strangers you have encountered.', 'When did a stranger bless you?', 'Hebrews 13:2'),
    ('Grateful for Technology', 'Thank God for tools that connect and empower you.', 'How can you use technology for good?', 'Proverbs 22:29'),
    ('Grateful for Rest', 'Thank God for the gift of sleep and renewal.', 'How does rest restore you?', 'Psalm 4:8'),
    ('Grateful for Future', 'Express gratitude for promises yet to be fulfilled.', 'What are you trusting God for?', 'Jeremiah 29:11'),
    ('Grateful for Sacrifice', 'Reflect on the ultimate sacrifice of Christ.', 'How does the cross redefine gratitude?', 'John 3:16'),
    ('Grateful for Freedom', 'Thank God for spiritual and physical freedom.', 'What freedom do you cherish most?', 'Galatians 5:1'),
    ('Grateful for Children', 'Thank God for the children in your life or the childlike spirit.', 'What do children teach you?', 'Matthew 18:3'),
    ('30 Days of Thanks', 'Celebrate 30 days of gratitude. Share your journey with someone.', 'What has changed most in your heart?', 'Psalm 107:1'),
    ('Grateful for Wisdom', 'Thank God for wisdom you have gained through experience.', 'What is the wisest lesson you have learned?', 'Proverbs 4:7'),
    ('Grateful for Tears', 'Thank God for times of sorrow that deepened your faith.', 'How did tears draw you closer to God?', 'Psalm 56:8'),
    ('Grateful for Laughter', 'Thank God for joy and laughter in your life.', 'When did you last laugh freely?', 'Psalm 126:2'),
    ('Grateful for Mentors', 'Thank God for spiritual mentors and teachers.', 'What mentor shaped your faith most?', '2 Timothy 1:5'),
    ('Grateful for Grace', 'Reflect deeply on undeserved grace in your life.', 'Where has grace covered you?', 'Ephesians 2:8-9'),
    ('Grateful for the Journey', 'Thank God for the path He has led you on.', 'How do you see God\'s hand in your journey?', 'Psalm 37:23'),
    ('Grateful for the Church', 'Thank God for the global body of Christ.', 'How has the Church blessed you?', '1 Corinthians 12:27'),
    ('Grateful for Hope', 'Express gratitude for the hope you carry.', 'What gives you hope today?', 'Romans 15:13'),
    ('Grateful for Eternity', 'Thank God for the promise of eternal life.', 'How does eternity change today?', 'John 14:2-3'),
    ('Celebration of Gratitude', 'Compile your 40-day gratitude journey into a personal Psalm of Thanksgiving.', 'Who have you become through 40 days of gratitude?', 'Psalm 150:6'),
  ];

  // ── 5. FORGIVENESS ──────────────────────────────────────────────────
  static FortyDayGoal get _forgivenessTemplate => FortyDayGoal(
        id: 'tpl_forgiveness',
        title: 'The Freedom of Forgiveness',
        category: 'Forgiveness',
        description:
            'A 40-day journey of releasing bitterness, receiving grace, and walking in freedom through the power of forgiveness.',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 40)),
        dailyTasks: List.generate(40, (i) {
          final day = i + 1;
          final data = _forgivenessTasks[i];
          return DailyGoalTask(
            dayNumber: day,
            title: 'Day $day: ${data.$1}',
            description: data.$2,
            durationMinutes: day <= 7 ? 10 : (day <= 21 ? 15 : 20),
            reflectionPrompt: data.$3,
            relatedVerse: data.$4,
          );
        }),
      );

  static const List<(String, String, String, String)> _forgivenessTasks = [
    ('Understanding Forgiveness', 'Read Matthew 18:21-35. Journal what forgiveness means to you.', 'What does forgiveness cost?', 'Matthew 18:21-22'),
    ('Receiving God\'s Forgiveness', 'Read 1 John 1:9 and confess anything you have been carrying.', 'What burden are you releasing?', '1 John 1:9'),
    ('Forgiving Yourself', 'Write down things you have not forgiven yourself for. Release them to God.', 'What would self-forgiveness look like?', 'Romans 8:1'),
    ('Identifying Wounds', 'Ask the Holy Spirit to reveal hidden hurts that need healing.', 'What wound surfaced today?', 'Psalm 147:3'),
    ('Praying for Offenders', 'Pray genuinely for someone who has hurt you.', 'How did praying for them change you?', 'Matthew 5:44'),
    ('The Cost of Unforgiveness', 'Journal about how unforgiveness has affected your life.', 'What has unforgiveness stolen from you?', 'Hebrews 12:15'),
    ('Sabbath Rest', 'Rest and let God minister to your heart about forgiveness.', 'What is God healing in you?', 'Matthew 11:28-30'),
    ('Childhood Wounds', 'Bring a childhood hurt to God. Let Him comfort the younger you.', 'What does the child in you need to hear?', 'Psalm 27:10'),
    ('Family Forgiveness', 'Identify family patterns of unforgiveness. Begin to break them.', 'What cycle are you breaking?', 'Ezekiel 18:20'),
    ('Writing a Forgiveness Letter', 'Write a letter of forgiveness (you do not have to send it).', 'What freedom came from writing?', 'Colossians 3:13'),
    ('Empathy Exercise', 'Try to see the situation from the offender\'s perspective.', 'Did understanding shift anything?', 'Philippians 2:3-4'),
    ('Boundary and Forgiveness', 'Learn that forgiveness and boundaries can coexist.', 'What healthy boundary do you need?', 'Proverbs 4:23'),
    ('Grieving the Loss', 'Allow yourself to grieve what the offense cost you.', 'What are you mourning?', 'Psalm 34:18'),
    ('Midpoint Reflection', 'Reflect on your forgiveness journey so far.', 'What has surprised you about this process?', 'Lamentations 3:22-23'),
    ('Forgiving in Stages', 'Forgiveness is often a process. Give yourself permission for it to take time.', 'What stage are you in?', 'Philippians 3:13-14'),
    ('Releasing Bitterness', 'Name any bitterness and consciously release it to God.', 'What bitterness are you letting go?', 'Ephesians 4:31-32'),
    ('The Cross and Forgiveness', 'Meditate on Christ\'s forgiveness from the cross.', 'How does the cross change your view of forgiveness?', 'Luke 23:34'),
    ('Forgiving Institutions', 'Consider if you need to forgive a church, organization, or system.', 'What institution hurt you?', 'Romans 12:19'),
    ('Reconciliation Prayer', 'Pray about whether reconciliation is appropriate.', 'Is God leading you toward reconciliation?', 'Matthew 5:23-24'),
    ('Halfway Freedom', 'Celebrate the freedom you have found so far.', 'How do you feel lighter?', 'John 8:36'),
    ('Generational Healing', 'Pray for healing of generational wounds in your family line.', 'What generational pattern is God breaking?', 'Exodus 34:6-7'),
    ('Forgiving God', 'Be honest about any anger toward God. He can handle it.', 'What are you disappointed with God about?', 'Psalm 22:1-2'),
    ('Physical Release', 'Tension often hides in the body. Stretch, breathe, and release.', 'Where did your body hold unforgiveness?', '3 John 1:2'),
    ('Testimony of Forgiveness', 'Write your story of forgiveness as a testimony.', 'Who could your story help?', 'Revelation 12:11'),
    ('Daily Forgiveness Practice', 'Practice forgiving small offenses immediately today.', 'What small offense did you release quickly?', 'Proverbs 19:11'),
    ('Replacing Offense with Prayer', 'Each time an old hurt surfaces, pray instead of replaying it.', 'How did prayer redirect your thoughts?', 'Philippians 4:6-7'),
    ('Extending Grace', 'Extend grace to three people today, expecting nothing in return.', 'How did grace flow through you?', 'Ephesians 4:7'),
    ('Rewriting the Narrative', 'Rewrite your painful story as one of redemption.', 'How does God redeem your story?', 'Romans 8:28'),
    ('Forgiving in Advance', 'Prepare your heart to forgive future offenses quickly.', 'How can you protect your heart going forward?', 'Proverbs 4:23'),
    ('30 Days of Freedom', 'Celebrate 30 days of intentional forgiveness.', 'Who are you becoming through forgiveness?', 'Psalm 32:1-2'),
    ('Compassion for the Broken', 'Remember that those who hurt you are also broken.', 'How does compassion change things?', 'Matthew 9:36'),
    ('Unforgiveness Inventory', 'Check if any unforgiveness has crept back. Release it again.', 'Did anything resurface?', 'Mark 11:25'),
    ('Freedom in Relationships', 'Notice how forgiveness has improved your relationships.', 'Which relationship has changed most?', '1 Peter 4:8'),
    ('Mentoring Forgiveness', 'Share what you have learned about forgiveness with someone who needs it.', 'What wisdom can you share?', 'Galatians 6:1'),
    ('Joy After Forgiveness', 'Notice the joy and peace that has entered your life.', 'Where do you feel joy that was not there before?', 'Nehemiah 8:10'),
    ('Strengthened by Struggle', 'Thank God for the growth that came through the pain.', 'How has pain produced strength?', '2 Corinthians 1:3-4'),
    ('Forgiveness as Lifestyle', 'Commit to making forgiveness a daily practice.', 'What will your daily forgiveness practice look like?', 'Colossians 3:13'),
    ('Legacy of Forgiveness', 'What legacy of forgiveness will you leave for others?', 'What do you want to be remembered for?', 'Psalm 78:4'),
    ('Final Release', 'Bring any remaining hurt to God. Release it completely.', 'Is there anything left to release?', 'Isaiah 43:18-19'),
    ('Celebration of Freedom', 'You have completed 40 days of forgiveness. Write your freedom declaration.', 'Who have you become through forgiveness?', 'Galatians 5:1'),
  ];

  // ── 6. FASTING ──────────────────────────────────────────────────────
  static FortyDayGoal get _fastingTemplate => FortyDayGoal(
        id: 'tpl_fasting',
        title: 'The Discipline of Fasting',
        category: 'Fasting',
        description:
            'A 40-day progressive fasting journey that begins gently and builds spiritual muscle. Combines food fasting, media fasting, and spiritual disciplines.',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 40)),
        dailyTasks: List.generate(40, (i) {
          final day = i + 1;
          final data = _fastingTasks[i];
          return DailyGoalTask(
            dayNumber: day,
            title: 'Day $day: ${data.$1}',
            description: data.$2,
            durationMinutes: day <= 7 ? 10 : (day <= 21 ? 15 : 20),
            reflectionPrompt: data.$3,
            relatedVerse: data.$4,
          );
        }),
      );

  static const List<(String, String, String, String)> _fastingTasks = [
    ('Why Fast?', 'Study Matthew 6:16-18. Journal your motivation for this fast.', 'Why are you drawn to fasting?', 'Matthew 6:16-18'),
    ('Social Media Fast', 'Stay off all social media for 24 hours. Replace scroll time with prayer.', 'What did you notice without social media?', 'Psalm 119:37'),
    ('Dessert Fast', 'Abstain from sweets and desserts today. Offer your craving as prayer.', 'What did physical craving teach you about spiritual hunger?', 'Matthew 4:4'),
    ('Complaint Fast', 'Go the entire day without complaining. Replace complaints with gratitude.', 'How hard was it not to complain?', 'Philippians 2:14-15'),
    ('Skip One Meal', 'Fast from one meal today. Use the time to pray.', 'How did hunger sharpen your prayers?', 'Joel 2:12'),
    ('Music Fast', 'Listen only to worship music or silence today.', 'How did your media diet change your mood?', 'Psalm 40:3'),
    ('Sabbath Rest', 'Rest and reflect on your first week of fasting discipline.', 'What have you learned about self-denial?', 'Isaiah 58:13-14'),
    ('Two-Meal Fast', 'Fast from two meals today. Stay hydrated with water only.', 'How did extended fasting feel physically and spiritually?', 'Daniel 10:3'),
    ('News Fast', 'Avoid all news media today. Focus on eternal truths instead.', 'How did your anxiety level change?', 'Isaiah 26:3'),
    ('Entertainment Fast', 'No TV, movies, or streaming today. Fill the time with God.', 'What did you do with the extra time?', 'Ecclesiastes 3:1'),
    ('Spending Fast', 'Do not spend money on non-essentials today.', 'What do you truly need versus want?', 'Matthew 6:19-21'),
    ('Gossip Fast', 'Speak only kind, necessary, and true words today.', 'How did guarding your tongue change interactions?', 'Proverbs 21:23'),
    ('Coffee or Caffeine Fast', 'Abstain from caffeine today. Rely on God\'s strength.', 'What crutch was caffeine replacing?', 'Isaiah 40:31'),
    ('Midweek Check-In', 'Journal about how fasting is affecting your spiritual sensitivity.', 'Are you hearing God more clearly?', 'Isaiah 58:6-9'),
    ('Full-Day Food Fast', 'Fast from all food for 24 hours (sunset to sunset). Water only.', 'What did a full day of fasting reveal?', 'Esther 4:16'),
    ('Digital Fast', 'No screens except for essential work today.', 'What happened when you unplugged?', 'Psalm 46:10'),
    ('Opinion Fast', 'Listen without offering your opinion today. Practice humility.', 'What did you learn by not speaking?', 'James 1:19'),
    ('Comfort Fast', 'Choose something uncomfortable today: cold shower, hard floor, early wake.', 'How did discomfort wake you up spiritually?', '2 Corinthians 12:9-10'),
    ('Worry Fast', 'Each time worry arises, immediately pray instead. Count the redirections.', 'How many times did you redirect worry to prayer?', 'Philippians 4:6-7'),
    ('Halfway Celebration', 'You are halfway. Celebrate growth and recommit for the next 20 days.', 'How has fasting changed your relationship with God?', 'Matthew 9:15'),
    ('Two-Day Prep', 'Eat lightly today in preparation for a longer fast.', 'How does preparation change your approach?', 'Luke 14:28'),
    ('36-Hour Fast', 'Begin a 36-hour food fast. Water, prayer, and Scripture only.', 'What did extended fasting surface in your heart?', 'Matthew 17:21'),
    ('Breaking the Fast', 'Break your fast gently. Thank God for provision.', 'How did food taste after fasting?', 'Psalm 34:8'),
    ('Technology Sabbath', 'Take a full technology sabbath. No phone, computer, or screens.', 'What did you discover without technology?', 'Exodus 20:8'),
    ('Silence Fast', 'Speak as little as possible today. Practice sacred silence.', 'What did silence teach you?', 'Ecclesiastes 5:2'),
    ('Judgment Fast', 'Do not judge anyone today: internally or externally.', 'How often do you judge without realizing?', 'Matthew 7:1-2'),
    ('Comparison Fast', 'Refuse all comparison today. Celebrate your unique journey.', 'How did freedom from comparison feel?', 'Galatians 6:4-5'),
    ('Pleasure Fast', 'Deny yourself a regular pleasure today. Offer it as worship.', 'What did denial reveal about dependency?', 'Luke 9:23'),
    ('Extended Prayer Fast', 'Replace all screens with prayer for the entire evening.', 'How did an evening of prayer feel?', 'Luke 6:12'),
    ('30-Day Milestone', 'Reflect on 30 days of discipline and growth.', 'How has self-denial become self-discovery?', 'Galatians 2:20'),
    ('Community Fast', 'Fast with a friend or small group today for mutual encouragement.', 'How did fasting together strengthen your bond?', 'Matthew 18:19-20'),
    ('Fasting for Others', 'Choose someone in need and fast specifically for them.', 'How did intercessory fasting feel different?', 'Isaiah 58:6-7'),
    ('Senses Fast', 'Pick one sense to limit today. What do you notice about the others?', 'What did limiting one sense teach you?', 'Mark 8:18'),
    ('Fasting and Giving', 'Give away the money you would have spent on meals.', 'How did fasting and giving work together?', 'Isaiah 58:10'),
    ('Fear Fast', 'Identify one fear and refuse to give it power today.', 'What fear did you conquer?', '2 Timothy 1:7'),
    ('Busyness Fast', 'Clear your schedule of everything non-essential. Be still.', 'What happened when you stopped being busy?', 'Psalm 23:2'),
    ('Three-Day Prep', 'Begin preparing for a final extended fast.', 'How do you feel about the finish line?', 'Hebrews 12:1'),
    ('Final Extended Fast', 'Complete your longest fast of the journey. Let it be a culminating offering.', 'What is God saying in the depths of your fast?', 'Psalm 63:1'),
    ('Breaking Bread', 'Break your fast with a meal shared in community.', 'How has fasting changed your relationship with food and God?', 'Acts 2:42'),
    ('Commission of Discipline', 'Write your fasting commitment going forward. Celebrate 40 days of growth.', 'Who have you become through this discipline?', '1 Corinthians 9:27'),
  ];
}
