import 'dart:math';
import '../models/meditation_enums.dart';
import '../models/meditation_guide.dart';
import '../models/meditation_templates.dart';

class _VerseSelection {
  const _VerseSelection({
    required this.reference,
    required this.text,
    required this.focus,
  });

  final String reference;
  final String text;
  final String focus;
}

// Verse pools for each Bible template
const List<_VerseSelection> _parableVerses = [
  _VerseSelection(
    reference: 'Matthew 13:31-32',
    text:
        'The kingdom of heaven is like a mustard seed, which a man took and planted in his field. Though it is the smallest of all seeds, yet when it grows, it is the largest of garden plants.',
    focus:
        'Notice how God\'s kingdom starts small but grows beyond expectation.',
  ),
  _VerseSelection(
    reference: 'Luke 15:11-24',
    text:
        'But while he was still a long way off, his father saw him and was filled with compassion for him; he ran to his son, threw his arms around him and kissed him.',
    focus: 'Picture the Father running to welcome you home.',
  ),
  _VerseSelection(
    reference: 'Matthew 25:14-30',
    text:
        'His master replied, "Well done, good and faithful servant! You have been faithful with a few things; I will put you in charge of many things."',
    focus: 'Consider what gifts God has entrusted to you.',
  ),
  _VerseSelection(
    reference: 'Luke 10:25-37',
    text:
        'But a Samaritan, as he traveled, came where the man was; and when he saw him, he took pity on him.',
    focus: 'Who in your life needs your compassionate care today?',
  ),
  _VerseSelection(
    reference: 'Matthew 13:44-46',
    text:
        'The kingdom of heaven is like treasure hidden in a field. When a man found it, he hid it again, and then in his joy went and sold all he had and bought that field.',
    focus: 'What treasure of God\'s kingdom have you discovered?',
  ),
];

const List<_VerseSelection> _profoundVerses = [
  _VerseSelection(
    reference: 'Hebrews 4:12',
    text:
        'For the word of God is alive and active. Sharper than any double-edged sword, it penetrates even to dividing soul and spirit, joints and marrow.',
    focus: 'Let God\'s word discern the thoughts of your heart.',
  ),
  _VerseSelection(
    reference: 'Romans 8:28',
    text:
        'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
    focus: 'Trust God\'s sovereign work in your current situation.',
  ),
  _VerseSelection(
    reference: 'John 3:16',
    text:
        'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
    focus: 'Rest in the magnitude of God\'s love for you.',
  ),
  _VerseSelection(
    reference: 'Philippians 4:13',
    text: 'I can do all this through him who gives me strength.',
    focus: 'Draw strength from Christ for today\'s challenges.',
  ),
  _VerseSelection(
    reference: 'Jeremiah 29:11',
    text:
        'For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future.',
    focus: 'Hold onto God\'s good plans for your life.',
  ),
];

const List<_VerseSelection> _proverbVerses = [
  _VerseSelection(
    reference: 'Proverbs 3:5-6',
    text:
        'Trust in the LORD with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
    focus: 'Release control and trust God\'s direction today.',
  ),
  _VerseSelection(
    reference: 'Proverbs 16:3',
    text:
        'Commit to the LORD whatever you do, and he will establish your plans.',
    focus: 'Offer your work and plans to God\'s guidance.',
  ),
  _VerseSelection(
    reference: 'Proverbs 17:17',
    text:
        'A friend loves at all times, and a brother is born for a time of adversity.',
    focus: 'Thank God for the friends who stand with you.',
  ),
  _VerseSelection(
    reference: 'Proverbs 31:25',
    text:
        'She is clothed with strength and dignity; she can laugh at the days to come.',
    focus: 'Receive God\'s strength and dignity for today.',
  ),
  _VerseSelection(
    reference: 'Proverbs 4:23',
    text:
        'Above all else, guard your heart, for everything you do flows from it.',
    focus: 'Notice what is occupying your heart and mind today.',
  ),
];

const List<_VerseSelection> _comfortPsalms = [
  _VerseSelection(
    reference: 'Psalm 23:1-3',
    text:
        'The LORD is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.',
    focus: 'Rest in the Shepherd\'s gentle care for you.',
  ),
  _VerseSelection(
    reference: 'Psalm 46:1-3',
    text:
        'God is our refuge and strength, an ever-present help in trouble. Therefore we will not fear, though the earth give way and the mountains fall into the heart of the sea.',
    focus: 'Find refuge in God\'s unchanging presence.',
  ),
  _VerseSelection(
    reference: 'Psalm 91:1-2',
    text:
        'Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty. I will say of the LORD, "He is my refuge and my fortress.',
    focus: 'Picture yourself resting under God\'s protective shadow.',
  ),
  _VerseSelection(
    reference: 'Psalm 139:23-24',
    text:
        'Search me, God, and know my heart; test me and know my anxious thoughts. See if there is any offensive way in me, and lead me in the way everlasting.',
    focus: 'Invite God to search and heal your heart.',
  ),
  _VerseSelection(
    reference: 'Psalm 34:18',
    text:
        'The LORD is close to the brokenhearted and saves those who are crushed in spirit.',
    focus: 'Draw near to God who draws near to the broken.',
  ),
];

const List<_VerseSelection> _hopePromises = [
  _VerseSelection(
    reference: 'Isaiah 43:1-3',
    text:
        'But now, this is what the LORD says— he who created you, Jacob, he who formed you, Israel: "Do not fear, for I have redeemed you; I have summoned you by name; you are mine.',
    focus: 'Hear God speaking your name in love.',
  ),
  _VerseSelection(
    reference: 'Romans 8:38-39',
    text:
        'For I am convinced that neither death nor life, neither angels nor demons, neither the present nor the future, nor any powers, will be able to separate us from the love of God.',
    focus: 'Rest in the unbreakable nature of God\'s love.',
  ),
  _VerseSelection(
    reference: 'Lamentations 3:22-23',
    text:
        'Because of the LORD\'s great love we are not consumed, for his compassions never fail. They are new every morning; great is your faithfulness.',
    focus: 'Receive God\'s fresh mercy for this new day.',
  ),
  _VerseSelection(
    reference: '2 Corinthians 4:16-18',
    text:
        'Therefore we do not lose heart. Though outwardly we are wasting away, yet inwardly we are being renewed day by day. For our light and momentary troubles are achieving for us an eternal glory.',
    focus: 'Look beyond temporary troubles to eternal glory.',
  ),
  _VerseSelection(
    reference: 'Jeremiah 31:3',
    text:
        'The LORD appeared to us in the past, saying: "I have loved you with an everlasting love; I have drawn you with unfailing kindness.',
    focus: 'Rest in God\'s everlasting, drawing love.',
  ),
];

const List<_VerseSelection> _miracleStories = [
  _VerseSelection(
    reference: 'Mark 5:25-34',
    text:
        'She said to herself, "If I can just touch his clothes, I will be healed." Immediately her bleeding stopped and she felt in her body that she was freed from her suffering.',
    focus: 'Reach out in faith to touch Jesus\' power.',
  ),
  _VerseSelection(
    reference: 'John 9:1-7',
    text:
        'He spit on the ground, made some mud with the saliva, and put it on the man\'s eyes. "Go," he told him, "wash in the Pool of Siloam." So the man went and washed, and came home seeing.',
    focus: 'Follow Jesus\' instructions for your healing.',
  ),
  _VerseSelection(
    reference: 'Luke 5:17-26',
    text:
        'Immediately he stood up in front of them, took what he had been lying on and went home praising God. Everyone was amazed and gave praise to God.',
    focus: 'Imagine the joy of being made whole by Jesus.',
  ),
  _VerseSelection(
    reference: 'Matthew 14:22-33',
    text:
        'Immediately Jesus reached out his hand and caught him. "You of little faith," he said, "why did you doubt?"',
    focus: 'Take Jesus\' hand when you begin to sink.',
  ),
  _VerseSelection(
    reference: 'Luke 7:11-17',
    text:
        'Then the dead man sat up and began to talk, and Jesus gave him back to his mother. A great sense of awe swept over all of them.',
    focus: 'Trust Jesus to bring life where there was death.',
  ),
];

const List<_VerseSelection> _kingdomTeachings = [
  _VerseSelection(
    reference: 'Matthew 5:3-12',
    text:
        'Blessed are the poor in spirit, for theirs is the kingdom of heaven. Blessed are those who mourn, for they will be comforted.',
    focus: 'Consider how God blesses the humble and hurting.',
  ),
  _VerseSelection(
    reference: 'Matthew 6:19-21',
    text:
        'Do not store up for yourselves treasures on earth... But store up for yourselves treasures in heaven... For where your treasure is, there your heart will be also.',
    focus: 'Examine where your heart truly invests itself.',
  ),
  _VerseSelection(
    reference: 'Matthew 7:24-27',
    text:
        'Therefore everyone who hears these words of mine and puts them into practice is like a wise man who built his house on the rock.',
    focus: 'Build your life on Jesus\' solid teaching.',
  ),
  _VerseSelection(
    reference: 'Matthew 5:43-48',
    text:
        'You have heard that it was said, "Love your neighbor and hate your enemy." But I tell you, love your enemies and pray for those who persecute you.',
    focus: 'Ask God to help you love someone difficult today.',
  ),
  _VerseSelection(
    reference: 'Matthew 6:33-34',
    text:
        'But seek first his kingdom and his righteousness, and all these things will be given to you as well. Therefore do not worry about tomorrow.',
    focus: 'Release tomorrow\'s worries and seek God today.',
  ),
];

const List<_VerseSelection> _encouragementLetters = [
  _VerseSelection(
    reference: 'Philippians 4:6-9',
    text:
        'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
    focus: 'Turn your anxieties into prayers with gratitude.',
  ),
  _VerseSelection(
    reference: 'Romans 15:13',
    text:
        'May the God of hope fill you with all joy and peace as you trust in him, so that you may overflow with hope by the power of the Holy Spirit.',
    focus: 'Receive God\'s joy, peace, and hope right now.',
  ),
  _VerseSelection(
    reference: '2 Timothy 1:7',
    text:
        'For God has not given us a spirit of fear, but of power and of love and of a sound mind.',
    focus: 'Reject fear and embrace God\'s power, love, and clarity.',
  ),
  _VerseSelection(
    reference: 'Ephesians 3:20-21',
    text:
        'Now to him who is able to do immeasurably more than all we ask or imagine, according to his power that is at work within us.',
    focus: 'Dream bigger dreams powered by God\'s ability.',
  ),
  _VerseSelection(
    reference: 'Colossians 3:12-14',
    text:
        'Therefore, as God\'s chosen people, holy and dearly loved, clothe yourselves with compassion, kindness, humility, gentleness and patience.',
    focus: 'Choose to wear God\'s virtues today.',
  ),
];

/// Builds a [MeditationGuide] for the simplified meditation modes.
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
    BibleTemplate? bibleTemplate,
    AffirmationCategory? affirmationCategory,
    VirtueAffirmation? virtueAffirmation,
    HabitAffirmation? habitAffirmation,
    String? customBibleVerses,
  }) {
    switch (style) {
      case MeditationStyle.quietReflection:
        return _buildQuietReflection(selectedMinutes);
      case MeditationStyle.bible:
        return _buildBible(bibleTemplate, customBibleVerses);
      case MeditationStyle.affirmation:
        return _buildAffirmation(
          affirmationCategory,
          virtueAffirmation,
          habitAffirmation,
          sessionCount,
          selectedMinutes,
        );
      case MeditationStyle.chant:
        return _buildChant();
    }
  }

  static MeditationGuide _buildQuietReflection(int? selectedMinutes) {
    final level = determineLevel(
      sessionCount: 0,
      selectedMinutes: selectedMinutes,
    );
    final stageNote = switch (level) {
      MeditationLevel.foundation =>
        'Begin exactly where you are. God meets you in your raw, unedited reality.',
      MeditationLevel.growth =>
        'Notice the thoughts and feelings that arise. Can you hold them with gentle curiosity instead of judgment?',
      MeditationLevel.deep =>
        'Let the silence become a sanctuary. Listen for the still, small voice beneath the noise of your mind.',
    };

    return MeditationGuide(
      title: 'Quiet Reflection',
      imagery:
          'Create space for God to speak in the quiet places of your heart.',
      scripture: 'Psalm 46:10',
      prompts: [
        'What part of you needs permission to rest right now?',
        'Where do you feel God\'s presence most strongly in your body?',
        'What burden can you consciously release into His hands?',
        'What truth about God feels most alive in this moment?',
      ],
      declaration: 'In stillness, I am held by God\'s loving presence.',
      leadIn:
          'Take three deep breaths. With each exhale, release the need to do or fix anything.',
      focus: 'Rest in the awareness that you are already in God\'s presence.',
      closingReminder:
          'Carry this peace forward. You can return to this stillness anytime.',
      stageNote: stageNote,
      openReflection:
          'What invitation did you sense in the silence? How might you respond today?',
      guidanceTips: [
        'If your mind wanders, gently return to your breath without judgment.',
        'Place a hand on your heart as a physical reminder of God\'s presence.',
        'Let this practice be about being, not achieving.',
      ],
    );
  }

  static MeditationGuide _buildBible(
    BibleTemplate? template,
    String? customBibleVerses,
  ) {
    final resolvedTemplate = template ?? BibleTemplate.parables;
    if (resolvedTemplate == BibleTemplate.custom) {
      final text =
          (customBibleVerses ?? 'Write or paste the verses on your heart.')
              .trim();
      return MeditationGuide(
        title: 'Custom Scripture Meditation',
        imagery: 'Stay with the words you selected until they become prayer.',
        scripture: text,
        prompts: const [
          'Read slowly. Which phrase glows with life for you?',
          'Let the verse become a conversation with God.',
          'Ask the Spirit how to live this truth today.',
          'Who needs to hear this truth from you?',
        ],
        declaration: 'Your word is life to me, God.',
        leadIn:
            'Breathe deeply and invite the Spirit to speak through these verses.',
        focus: 'Rest inside the scripture you chose.',
        closingReminder:
            'Return to this passage later and notice what has shifted.',
        openReflection: text,
        guidanceTips: const [
          'Read the passage aloud to let it settle more deeply.',
          'Pause between phrases to notice emotions or images.',
          'End by thanking God for speaking through your chosen text.',
        ],
      );
    }

    final verseSelection = _getRandomVerseForTemplate(resolvedTemplate);
    final details = _BibleTemplateDetails.forTemplate(
      resolvedTemplate,
      verseSelection,
    );

    // For Bible meditation, include the verse text in the imagery for display
    final displayImagery = '${details.imagery}\n\n${verseSelection.text}';

    return MeditationGuide(
      title: details.title,
      imagery: displayImagery,
      scripture: details.scripture,
      prompts: details.prompts,
      declaration: details.declaration,
      leadIn: 'Read the passage slowly. Picture yourself inside the scene.',
      focus: details.focus,
      closingReminder: 'Carry one phrase with you throughout the day.',
      openReflection: verseSelection.text,
      guidanceTips: const [
        'Read aloud if possible. Let the words resonate.',
        'Pause between phrases to notice emotions or images.',
        'End by thanking God for speaking through Scripture.',
      ],
    );
  }

  static _VerseSelection _getRandomVerseForTemplate(BibleTemplate template) {
    final random = Random();
    List<_VerseSelection> verses;

    switch (template) {
      case BibleTemplate.parables:
        verses = _parableVerses;
        break;
      case BibleTemplate.profoundVerses:
        verses = _profoundVerses;
        break;
      case BibleTemplate.blessedProverbs:
        verses = _proverbVerses;
        break;
      case BibleTemplate.psalmsOfComfort:
        verses = _comfortPsalms;
        break;
      case BibleTemplate.promisesOfHope:
        verses = _hopePromises;
        break;
      case BibleTemplate.miraclesOfJesus:
        verses = _miracleStories;
        break;
      case BibleTemplate.kingdomEthics:
        verses = _kingdomTeachings;
        break;
      case BibleTemplate.lettersOfEncouragement:
        verses = _encouragementLetters;
        break;
      case BibleTemplate.custom:
        // Should not reach here for custom template
        verses = [];
        break;
    }

    return verses[random.nextInt(verses.length)];
  }

  static MeditationGuide _buildAffirmation(
    AffirmationCategory? category,
    VirtueAffirmation? virtueAffirmation,
    HabitAffirmation? habitAffirmation,
    int sessionCount,
    int? selectedMinutes,
  ) {
    final resolvedCategory = category ?? AffirmationCategory.growVirtue;
    final level = determineLevel(
      sessionCount: sessionCount,
      selectedMinutes: selectedMinutes,
    );
    final stageNote = switch (level) {
      MeditationLevel.foundation =>
        'Let the words sink in slowly until they feel familiar and true.',
      MeditationLevel.growth =>
        'Picture one specific situation where you will live this truth today.',
      MeditationLevel.deep =>
        'Ask the Spirit to expose competing narratives and replace them with this truth.',
    };

    if (resolvedCategory == AffirmationCategory.stopHabit) {
      final affirmation = habitAffirmation ?? HabitAffirmation.lust;
      return MeditationGuide(
        title: 'Freedom From ${affirmation.title}',
        imagery:
            'Name the struggle, then invite grace to rewrite your response.',
        scripture: 'Romans 12:2',
        prompts: [
          'When does ${affirmation.title.toLowerCase()} feel strongest? What triggers it?',
          'How does God\'s love reframe this temptation and offer you dignity?',
          'What specific new response will you practice when the urge arises?',
          'Who can support you in this journey toward freedom?',
        ],
        declaration: affirmation.text,
        leadIn:
            'Breathe in mercy. Exhale the pull of ${affirmation.title.toLowerCase()}.',
        focus:
            'Let this affirmation become louder than the voice of temptation.',
        closingReminder:
            'Grace empowers you to choose differently moment by moment.',
        stageNote: stageNote,
        guidanceTips: [
          'When temptation strikes, pause and take three deep breaths first.',
          'Memorize this affirmation and repeat it during weak moments.',
          'Celebrate small victories – each choice matters to God.',
        ],
      );
    }

    final affirmation = virtueAffirmation ?? VirtueAffirmation.selfControl;
    return MeditationGuide(
      title: 'Grow in ${affirmation.title}',
      imagery:
          'Picture this virtue taking root in you like a seed becoming a mighty tree.',
      scripture: 'Galatians 5:22-23',
      prompts: [
        'Where in your life do you need ${affirmation.title.toLowerCase()} most urgently today?',
        'How might others experience Jesus\' love through this virtue in you?',
        'What one courageous choice could you make that embodies this virtue?',
        'How does growing in this virtue bring glory to God?',
      ],
      declaration: affirmation.text,
      leadIn: 'Place a hand over your heart and welcome the Spirit\'s shaping.',
      focus:
          'Let this affirmation become your steady inner soundtrack throughout the day.',
      closingReminder:
          'Look for a small opportunity to express this virtue in the next few hours.',
      stageNote: stageNote,
      guidanceTips: [
        'Write this affirmation where you\'ll see it multiple times today.',
        'Practice this virtue in low-stakes situations first.',
        'Ask God to show you one person who needs this virtue from you today.',
      ],
    );
  }

  static MeditationGuide _buildChant() {
    return const MeditationGuide(
      title: 'Chant Meditation',
      imagery:
          'Let repetitive melody carry your heart beyond words into divine presence.',
      scripture: 'Psalm 96:1',
      prompts: [
        'Notice how the chant affects your body and breathing.',
        'Let the chant become a simple prayer of love.',
        'When the music fades, what remains in the silence?',
        'How does your heart feel different from when you began?',
      ],
      declaration: 'My voice joins creation\'s song to God.',
      leadIn:
          'Settle your body, find a comfortable posture, and let your breath settle.',
      focus:
          'Allow the chant to become a vehicle for prayer, not a performance.',
      guidanceTips: [
        'Sing softly – this is intimacy, not performance.',
        'If words feel distant, hum or simply repeat "Jesus" with your breath.',
        'Let the chant continue even when your mind wanders – return gently.',
        'After chanting, rest in silence for at least two minutes.',
        'Notice any shift in your heart\'s posture toward God.',
      ],
      closingReminder:
          'Carry the melody in your heart as a prayer throughout the day.',
    );
  }
}

class _BibleTemplateDetails {
  const _BibleTemplateDetails({
    required this.title,
    required this.imagery,
    required this.scripture,
    required this.prompts,
    required this.declaration,
    required this.focus,
  });

  final String title;
  final String imagery;
  final String scripture;
  final List<String> prompts;
  final String declaration;
  final String focus;

  static _BibleTemplateDetails forTemplate(
    BibleTemplate template,
    _VerseSelection verseSelection,
  ) {
    switch (template) {
      case BibleTemplate.parables:
        return _BibleTemplateDetails(
          title: 'Sit With A Parable',
          imagery:
              'Enter Jesus\' stories as if you were there – what role do you play?',
          scripture: verseSelection.reference,
          prompts: [
            'Which character in this story feels most like you right now?',
            'What surprises you about Jesus\' teaching in this parable?',
            'If Jesus told this story today, what modern elements would He include?',
            'How does this story challenge your current way of thinking or living?',
          ],
          declaration: 'Lord, let Your story read me and rewrite my heart.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.profoundVerses:
        return _BibleTemplateDetails(
          title: 'Daily Nuggets',
          imagery:
              'Let one sentence of Scripture become a lens through which you see everything.',
          scripture: verseSelection.reference,
          prompts: [
            'Read the verse aloud slowly. Which words carry the most weight?',
            'What lie in your life does this truth confront and replace?',
            'How would your day look different if you fully believed this?',
            'Who in your life needs to hear this truth right now?',
          ],
          declaration: 'This single verse becomes my anchor today.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.blessedProverbs:
        return _BibleTemplateDetails(
          title: 'Wisdom & Rewards',
          imagery:
              'Let Proverbs illuminate the path between choice and consequence.',
          scripture: verseSelection.reference,
          prompts: [
            'What decision are you facing where you need divine wisdom?',
            'Where are you relying on your own understanding instead of trusting God?',
            'What practical step can you take today to "acknowledge Him in all your ways"?',
            'How has God made your paths straight in the past?',
          ],
          declaration: 'I choose wisdom\'s path and trust God\'s direction.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.psalmsOfComfort:
        return _BibleTemplateDetails(
          title: 'Psalms of Comfort',
          imagery:
              'Let the psalmist\'s words become a balm for your weary soul.',
          scripture: verseSelection.reference,
          prompts: [
            'What part of you feels like it\'s "walking through the valley" right now?',
            'How does knowing God is with you change how you view your current struggles?',
            'What "green pastures" or "still waters" has God provided recently?',
            'Who in your life needs to hear they are not alone?',
          ],
          declaration:
              'God\'s goodness and mercy follow me even in dark valleys.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.promisesOfHope:
        return _BibleTemplateDetails(
          title: 'Promises of Hope',
          imagery:
              'Stand on God\'s unshakeable promises when everything else feels uncertain.',
          scripture: verseSelection.reference,
          prompts: [
            'What fear is trying to overwhelm you right now?',
            'How has God proven faithful in your past trials?',
            'What would it look like to trust this promise today instead of your circumstances?',
            'Who needs to hear that God hasn\'t forgotten them?',
          ],
          declaration: 'God\'s promises are more real than my fears.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.miraclesOfJesus:
        return _BibleTemplateDetails(
          title: 'Miracles of Jesus',
          imagery:
              'Watch Jesus meet impossible situations with compassionate power.',
          scripture: verseSelection.reference,
          prompts: [
            'What area of your life feels beyond human help right now?',
            'How does Jesus respond to the person\'s faith in this story?',
            'What does this miracle reveal about Jesus\' heart toward your suffering?',
            'What step of faith can you take even if it feels small?',
          ],
          declaration: 'Jesus meets my impossibility with His power.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.kingdomEthics:
        return _BibleTemplateDetails(
          title: 'Kingdom Ethics',
          imagery:
              'Let Jesus\' upside-down Kingdom transform how you love and live.',
          scripture: verseSelection.reference,
          prompts: [
            'Which teaching feels most radical and counter-cultural to you?',
            'How would your relationships change if you lived this teaching?',
            'What worldly value does this Kingdom teaching challenge in you?',
            'How can you practice this specific command today?',
          ],
          declaration: 'Your Kingdom values become my life\'s compass.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.lettersOfEncouragement:
        return _BibleTemplateDetails(
          title: 'Letters of Encouragement',
          imagery:
              'Receive the apostles\' words as personal strength for your journey.',
          scripture: verseSelection.reference,
          prompts: [
            'What anxiety or fear is trying to dominate your thoughts?',
            'How does this passage invite you to reframe your perspective?',
            'What "excellent, praiseworthy" thing can you focus on today?',
            'Who needs the encouragement you\'re receiving from this passage?',
          ],
          declaration: 'God\'s peace guards my heart and mind in Christ.',
          focus: verseSelection.focus,
        );
      case BibleTemplate.custom:
        // Handled earlier.
        return const _BibleTemplateDetails(
          title: '',
          imagery: '',
          scripture: '',
          prompts: [],
          declaration: '',
          focus: '',
        );
    }
  }
}
