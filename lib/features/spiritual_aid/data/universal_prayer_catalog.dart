import '../domain/models/quick_prayer.dart';

/// Denomination-neutral universal prayer catalog.
///
/// These prayers are beloved across all Christian traditions. Every prayer
/// here is available without any content pack. Tradition-specific prayers
/// should be in downloadable content packs instead.
class UniversalPrayerCatalog {
  const UniversalPrayerCatalog._();

  static const List<QuickPrayer> all = [
    // ─── LORD'S PRAYER ───────────────────────────────────────────────
    QuickPrayer(
      id: 'uni_01',
      title: 'The Lord\'s Prayer',
      body:
          'Our Father, who art in heaven, hallowed be Thy name. '
          'Thy kingdom come, Thy will be done, on earth as it is in heaven. '
          'Give us this day our daily bread, and forgive us our trespasses, '
          'as we forgive those who trespass against us. '
          'And lead us not into temptation, but deliver us from evil. '
          'For Thine is the kingdom, and the power, and the glory, '
          'forever and ever. Amen.',
      category: 'foundation',
      relatedVerse: 'Pray then like this: "Our Father in heaven, hallowed be your name."',
      relatedVerseReference: 'Matthew 6:9',
      estimatedSeconds: 30,
    ),

    // ─── SERENITY PRAYER ──────────────────────────────────────────────
    QuickPrayer(
      id: 'uni_02',
      title: 'Serenity Prayer',
      body:
          'God, grant me the serenity to accept the things I cannot change, '
          'courage to change the things I can, '
          'and wisdom to know the difference. '
          'Living one day at a time, enjoying one moment at a time, '
          'accepting hardships as the pathway to peace. '
          'Amen.',
      category: 'peace',
      relatedVerse: 'Be still before the Lord and wait patiently for him.',
      relatedVerseReference: 'Psalm 37:7',
      estimatedSeconds: 25,
    ),

    // ─── MORNING OFFERING ─────────────────────────────────────────────
    QuickPrayer(
      id: 'uni_03',
      title: 'Morning Offering',
      body:
          'Heavenly Father, I offer You this day — '
          'all my thoughts, words, actions, joys, and sufferings. '
          'May everything I do begin in You and end in You. '
          'Bless my work, my rest, and my relationships. '
          'Use me as an instrument of Your peace today. Amen.',
      category: 'morning',
      relatedVerse: 'This is the day that the Lord has made; let us rejoice and be glad in it.',
      relatedVerseReference: 'Psalm 118:24',
      estimatedSeconds: 20,
    ),

    // ─── EVENING THANKSGIVING ─────────────────────────────────────────
    QuickPrayer(
      id: 'uni_04',
      title: 'Evening Thanksgiving',
      body:
          'Lord, I thank You for this day and for every blessing it held. '
          'For the moments of joy, for the challenges that grew me, '
          'and for Your presence through it all. '
          'I release the burdens of this day into Your hands. '
          'Grant me restful sleep and the grace to begin again tomorrow. '
          'Amen.',
      category: 'evening',
      relatedVerse: 'In peace I will both lie down and sleep; for you alone, O Lord, make me dwell in safety.',
      relatedVerseReference: 'Psalm 4:8',
      estimatedSeconds: 25,
    ),

    // ─── PRAYER OF CONFESSION ─────────────────────────────────────────
    QuickPrayer(
      id: 'uni_05',
      title: 'Prayer of Confession',
      body:
          'Merciful God, I confess that I have sinned against You '
          'in thought, word, and deed — by what I have done and by what I have left undone. '
          'I have not loved You with my whole heart, '
          'nor have I loved my neighbor as myself. '
          'Forgive me, restore me, and lead me in Your way. '
          'Create in me a clean heart, O God. Amen.',
      category: 'repentance',
      relatedVerse: 'If we confess our sins, he is faithful and just to forgive us our sins.',
      relatedVerseReference: '1 John 1:9',
      estimatedSeconds: 25,
    ),

    // ─── PRAYER FOR STRENGTH ──────────────────────────────────────────
    QuickPrayer(
      id: 'uni_06',
      title: 'Prayer for Strength',
      body:
          'Lord, I am weak, but You are strong. '
          'When I feel I cannot go on, be my strength. '
          'When I am tempted to give up, renew my resolve. '
          'I can do all things through Christ who strengthens me. '
          'Hold me steady, and carry me through. Amen.',
      category: 'strength',
      relatedVerse: 'I can do all things through him who strengthens me.',
      relatedVerseReference: 'Philippians 4:13',
      estimatedSeconds: 20,
    ),

    // ─── PRAYER FOR OTHERS ────────────────────────────────────────────
    QuickPrayer(
      id: 'uni_07',
      title: 'Prayer for Others',
      body:
          'Father, I lift up those You have placed on my heart today. '
          'Bless them, protect them, and meet their needs — '
          'physical, emotional, and spiritual. '
          'Use me to be a blessing in their lives. '
          'Help me to love them as You love them. Amen.',
      category: 'intercession',
      relatedVerse: 'Carry each other\'s burdens, and in this way you will fulfill the law of Christ.',
      relatedVerseReference: 'Galatians 6:2',
      estimatedSeconds: 25,
    ),

    // ─── PRAYER FOR FORGIVENESS (GRANTING) ────────────────────────────
    QuickPrayer(
      id: 'uni_08',
      title: 'Prayer to Forgive',
      body:
          'Lord, forgiveness is hard, but You command it. '
          'I release [name] into Your hands. '
          'I give up my right to hold this hurt. '
          'Help me to see them through Your eyes. '
          'As I have been forgiven much, let me forgive freely. '
          'Heal the wound they caused. Set me free. Amen.',
      category: 'forgiveness',
      relatedVerse: 'Forgive, and you will be forgiven.',
      relatedVerseReference: 'Luke 6:37',
      estimatedSeconds: 25,
    ),

    // ─── PRAYER FOR GUIDANCE ──────────────────────────────────────────
    QuickPrayer(
      id: 'uni_09',
      title: 'Prayer for Guidance',
      body:
          'Lord, I don\'t know the way forward, but You do. '
          'Guide my steps, open doors only You can open, '
          'and close those that would lead me astray. '
          'Give me wisdom to discern Your voice '
          'and courage to follow wherever You lead. Amen.',
      category: 'guidance',
      relatedVerse: 'Trust in the Lord with all your heart, and do not lean on your own understanding.',
      relatedVerseReference: 'Proverbs 3:5',
      estimatedSeconds: 25,
    ),

    // ─── PRAYER OF THANKSGIVING ───────────────────────────────────────
    QuickPrayer(
      id: 'uni_10',
      title: 'Prayer of Thanksgiving',
      body:
          'Thank You, Lord, for Your unfailing love and faithfulness. '
          'For the breath in my lungs, the food on my table, '
          'and the people who fill my life with joy. '
          'Thank You for never leaving me, never giving up on me, '
          'and for working all things for my good. '
          'I give You all the praise. Amen.',
      category: 'gratitude',
      relatedVerse: 'Give thanks in all circumstances; for this is the will of God in Christ Jesus for you.',
      relatedVerseReference: '1 Thessalonians 5:18',
      estimatedSeconds: 25,
    ),
  ];

  static List<QuickPrayer> byCategory(String category) =>
      all.where((p) => p.category == category).toList();

  static QuickPrayer? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<String> get categories =>
      all.map((p) => p.category).toSet().toList();
}
