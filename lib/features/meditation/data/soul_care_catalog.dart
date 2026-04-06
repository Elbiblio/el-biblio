import '../domain/models/soul_care_session.dart';

/// A curated catalog of soul care reset sessions.
///
/// Each session pairs a breathing pattern with scripture for a spiritual reset.
class SoulCareCatalog {
  const SoulCareCatalog._();

  static const List<SoulCareSession> sessions = [
    SoulCareSession(
      id: 'qs_peace_storm',
      title: 'Peace in the Storm',
      description: 'Find calm when life feels chaotic.',
      scriptureText:
          'Peace I leave with you; my peace I give you. I do not give to you '
          'as the world gives. Do not let your hearts be troubled and do not '
          'be afraid.',
      scriptureReference: 'John 14:27',
      breathingPattern: '4-4-6',
      durationSeconds: 150,
      closingPrayer:
          'Lord, thank You for Your peace that surpasses understanding. '
          'Guard my heart and mind as I return to my day. Amen.',
    ),
    SoulCareSession(
      id: 'qs_still_waters',
      title: 'Still Waters',
      description: 'Rest beside quiet streams with the Shepherd.',
      scriptureText:
          'The Lord is my shepherd, I lack nothing. He makes me lie down in '
          'green pastures, he leads me beside quiet waters, he refreshes my soul.',
      scriptureReference: 'Psalm 23:1-3',
      breathingPattern: '4-4-6',
      durationSeconds: 150,
      closingPrayer:
          'Good Shepherd, refresh my soul in this moment. Lead me in the '
          'paths You have prepared for me. Amen.',
    ),
    SoulCareSession(
      id: 'qs_breath_of_life',
      title: 'Breath of Life',
      description: 'Remember the breath God breathed into you.',
      scriptureText:
          'Then the Lord God formed a man from the dust of the ground and '
          'breathed into his nostrils the breath of life, and the man became '
          'a living being.',
      scriptureReference: 'Genesis 2:7',
      breathingPattern: '5-3-7',
      durationSeconds: 180,
      closingPrayer:
          'Father, every breath I take is a gift from You. Fill me with '
          'Your Spirit as I breathe. Amen.',
    ),
    SoulCareSession(
      id: 'qs_be_still',
      title: 'Be Still and Know',
      description: 'Surrender control and trust God.',
      scriptureText:
          'Be still, and know that I am God; I will be exalted among the '
          'nations, I will be exalted in the earth.',
      scriptureReference: 'Psalm 46:10',
      breathingPattern: '4-7-8',
      durationSeconds: 120,
      closingPrayer:
          'Lord, I release my need to control. You are God and I am not. '
          'I trust You with this day. Amen.',
    ),
    SoulCareSession(
      id: 'qs_cast_anxiety',
      title: 'Cast Your Cares',
      description: 'Hand your anxieties over to God.',
      scriptureText:
          'Cast all your anxiety on him because he cares for you. Be alert '
          'and of sober mind.',
      scriptureReference: '1 Peter 5:7-8',
      breathingPattern: '4-4-6',
      durationSeconds: 150,
      closingPrayer:
          'Father, I give You every worry, every care, every anxious thought. '
          'You carry what I cannot. Thank You. Amen.',
    ),
    SoulCareSession(
      id: 'qs_strength_renewed',
      title: 'Strength Renewed',
      description: 'Wait on the Lord and find new energy.',
      scriptureText:
          'But those who hope in the Lord will renew their strength. They will '
          'soar on wings like eagles; they will run and not grow weary, they '
          'will walk and not be faint.',
      scriptureReference: 'Isaiah 40:31',
      breathingPattern: '4-4-6',
      durationSeconds: 150,
      closingPrayer:
          'Lord, renew my strength right now. I choose to hope in You even '
          'when I feel tired. Carry me through this day. Amen.',
    ),
    SoulCareSession(
      id: 'qs_do_not_fear',
      title: 'Do Not Fear',
      description: 'Remember God is with you wherever you go.',
      scriptureText:
          'Have I not commanded you? Be strong and courageous. Do not be '
          'afraid; do not be discouraged, for the Lord your God will be with '
          'you wherever you go.',
      scriptureReference: 'Joshua 1:9',
      breathingPattern: '4-4-6',
      durationSeconds: 120,
      closingPrayer:
          'God of courage, You go before me and beside me. I will not fear '
          'because You are with me. Amen.',
    ),
    SoulCareSession(
      id: 'qs_perfect_love',
      title: 'Perfect Love',
      description: 'Let God\'s love drive out fear.',
      scriptureText:
          'There is no fear in love. But perfect love drives out fear, because '
          'fear has to do with punishment. The one who fears is not made '
          'perfect in love.',
      scriptureReference: '1 John 4:18',
      breathingPattern: '5-3-7',
      durationSeconds: 150,
      closingPrayer:
          'Father, let Your perfect love fill every part of me, driving '
          'out every fear. I rest in Your love. Amen.',
    ),
    SoulCareSession(
      id: 'qs_present_moment',
      title: 'This Present Moment',
      description: 'Stop worrying about tomorrow.',
      scriptureText:
          'Therefore do not worry about tomorrow, for tomorrow will worry '
          'about itself. Each day has enough trouble of its own.',
      scriptureReference: 'Matthew 6:34',
      breathingPattern: '4-4-6',
      durationSeconds: 120,
      closingPrayer:
          'Jesus, help me stay in this present moment with You. I release '
          'tomorrow into Your hands. Amen.',
    ),
    SoulCareSession(
      id: 'qs_refuge',
      title: 'God My Refuge',
      description: 'Find shelter under God\'s wings.',
      scriptureText:
          'God is our refuge and strength, an ever-present help in trouble. '
          'Therefore we will not fear, though the earth give way and the '
          'mountains fall into the heart of the sea.',
      scriptureReference: 'Psalm 46:1-2',
      breathingPattern: '4-7-8',
      durationSeconds: 150,
      closingPrayer:
          'Lord, You are my refuge. I run to You in this moment and find '
          'safety in Your presence. Amen.',
    ),
    SoulCareSession(
      id: 'qs_joy_morning',
      title: 'Joy Comes',
      description: 'Hold on -- joy is coming.',
      scriptureText:
          'For his anger lasts only a moment, but his favor lasts a lifetime; '
          'weeping may stay for the night, but rejoicing comes in the morning.',
      scriptureReference: 'Psalm 30:5',
      breathingPattern: '4-4-6',
      durationSeconds: 120,
      closingPrayer:
          'Father, even when things are hard, I trust that joy is coming. '
          'Thank You for Your faithfulness. Amen.',
    ),
    SoulCareSession(
      id: 'qs_living_water',
      title: 'Living Water',
      description: 'Drink deeply from the well that never runs dry.',
      scriptureText:
          'Jesus answered, "Everyone who drinks this water will be thirsty '
          'again, but whoever drinks the water I give them will never thirst. '
          'Indeed, the water I give them will become in them a spring of '
          'water welling up to eternal life."',
      scriptureReference: 'John 4:13-14',
      breathingPattern: '5-3-7',
      durationSeconds: 180,
      closingPrayer:
          'Jesus, I drink from Your living water right now. Satisfy my '
          'deepest thirst and fill me with life. Amen.',
    ),
  ];

  /// Returns a random session from the catalog.
  static SoulCareSession get random {
    final index = DateTime.now().millisecondsSinceEpoch % sessions.length;
    return sessions[index];
  }
}
