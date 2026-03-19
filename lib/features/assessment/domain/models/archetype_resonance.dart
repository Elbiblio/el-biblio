class ArchetypeResonance {
  final String tribe;
  final String bibleCharacter;

  const ArchetypeResonance({
    required this.tribe,
    required this.bibleCharacter,
  });
}

class ArchetypePersona {
  final String tribe;
  final String bibleCharacter;

  const ArchetypePersona({
    required this.tribe,
    required this.bibleCharacter,
  });
}

class ArchetypeResonances {
  static const Map<String, ArchetypeResonance> _primary = {
    'Artisan': ArchetypeResonance(
      tribe: 'Judah',
      bibleCharacter: 'Bezalel the Spirit-Filled Maker',
    ),
    'Watchman': ArchetypeResonance(
      tribe: 'Benjamin',
      bibleCharacter: 'Nehemiah the Wall Rebuilder',
    ),
    'Cultivator': ArchetypeResonance(
      tribe: 'Issachar',
      bibleCharacter: 'Joseph the Steady Steward',
    ),
    'Sower': ArchetypeResonance(
      tribe: 'Zebulun',
      bibleCharacter: 'Paul the Church Planter',
    ),
    'Welcomer': ArchetypeResonance(
      tribe: 'Asher',
      bibleCharacter: 'Lydia the Open-Home Leader',
    ),
    'Pillar': ArchetypeResonance(
      tribe: 'Naphtali',
      bibleCharacter: 'Barnabas the Encourager',
    ),
    'Sentinel': ArchetypeResonance(
      tribe: 'Levi',
      bibleCharacter: 'Daniel the Faithful Watcher',
    ),
    'Bridgebuilder': ArchetypeResonance(
      tribe: 'Ephraim',
      bibleCharacter: 'Abigail the Wise Peacemaker',
    ),
    'Healer': ArchetypeResonance(
      tribe: 'Manasseh',
      bibleCharacter: 'Luke the Compassionate Physician',
    ),
    'Harvester': ArchetypeResonance(
      tribe: 'Gad',
      bibleCharacter: 'Boaz the Generous Gatherer',
    ),
    'Reformer': ArchetypeResonance(
      tribe: 'Simeon',
      bibleCharacter: 'Moses the Covenant Reformer',
    ),
    'Architect': ArchetypeResonance(
      tribe: 'Dan',
      bibleCharacter: 'Solomon the Temple Builder',
    ),
  };

  // Gamified dual-archetype combinations for 2-archetype results
  static const Map<String, String> _dualCombinations = {
    'Artisan|Healer': 'David the Restoring Psalmist',
    'Artisan|Sower': 'Bezalel the Vision Craftsman',
    'Artisan|Welcomer': 'Miriam the Creative Leader',
    'Artisan|Bridgebuilder': 'Bezalel the Bridge-Builder',
    'Artisan|Pillar': 'David the Loyal King',
    'Artisan|Cultivator': 'Joseph the Dream Interpreter',
    'Artisan|Architect': 'Bezalel the Master Builder',
    'Artisan|Reformer': 'David the Kingdom Reformer',
    'Artisan|Watchman': 'Nehemiah the Creative Protector',
    'Artisan|Sentinel': 'Daniel the Visionary Prophet',
    'Artisan|Harvester': 'David the Bountiful King',
    'Watchman|Reformer': 'Deborah the Courageous Judge',
    'Watchman|Sentinel': 'Nehemiah the Prayerful Guard',
    'Watchman|Pillar': 'Nehemiah the Steady Protector',
    'Watchman|Architect': 'Nehemiah the Strategic Planner',
    'Watchman|Cultivator': 'Daniel the Wise Steward',
    'Watchman|Bridgebuilder': 'Nehemiah the Diplomatic Leader',
    'Watchman|Harvester': 'Nehemiah the Fruitful Protector',
    'Cultivator|Healer': 'Joseph the Compassionate Steward',
    'Cultivator|Pillar': 'Joseph the Patient Leader',
    'Cultivator|Architect': 'Joseph the Strategic Builder',
    'Cultivator|Sower': 'Joseph the Multiplying Sower',
    'Cultivator|Welcomer': 'Joseph the Hospitable Provider',
    'Cultivator|Bridgebuilder': 'Joseph the Reconciling Steward',
    'Sower|Harvester': 'Paul the Mission Multiplier',
    'Sower|Welcomer': 'Paul the Relational Evangelist',
    'Sower|Bridgebuilder': 'Paul the Cultural Bridge-Builder',
    'Sower|Reformer': 'Peter the Bold Church-Builder',
    'Sower|Pillar': 'Paul the Encouraging Mentor',
    'Welcomer|Healer': 'Lydia the Compassionate Host',
    'Welcomer|Bridgebuilder': 'Lydia the Community Connector',
    'Welcomer|Pillar': 'Lydia the Faithful Supporter',
    'Welcomer|Harvester': 'Lydia the Generous Gatherer',
    'Pillar|Sentinel': 'Anna the Prayerful Servant',
    'Pillar|Healer': 'Barnabas the Healing Encourager',
    'Pillar|Bridgebuilder': 'Barnabas the Community Builder',
    'Pillar|Architect': 'Barnabas the Foundation Builder',
    'Sentinel|Bridgebuilder': 'Daniel the Wise Negotiator',
    'Sentinel|Healer': 'Daniel the Faithful Healer',
    'Sentinel|Architect': 'Daniel the Kingdom Architect',
    'Bridgebuilder|Healer': 'Abigail the Compassionate Peacemaker',
    'Bridgebuilder|Architect': 'Abigail the Strategic Peacemaker',
    'Bridgebuilder|Reformer': 'Esther the Courageous Intercessor',
    'Healer|Harvester': 'Luke the Gathering Physician',
    'Healer|Architect': 'Luke the Kingdom Builder',
    'Healer|Reformer': 'Luke the Transforming Healer',
    'Harvester|Architect': 'Boaz the Strategic Provider',
    'Harvester|Reformer': 'Boaz the Generous Reformer',
    'Architect|Reformer': 'Ezra the Covenant Restorer',
  };

  static const Map<String, String> _pairCharacters = {
    'Architect|Harvester': 'Joseph the Strategic Multiplier',
    'Architect|Cultivator': 'Noah the Long-Obedience Builder',
    'Architect|Reformer': 'Ezra the Covenant Restorer',
    'Artisan|Healer': 'David the Restoring Psalmist',
    'Artisan|Sower': 'Bezalel the Vision Craftsman',
    'Artisan|Welcomer': 'Miriam the Creative Leader',
    'Bridgebuilder|Pillar': 'Barnabas the Community Builder',
    'Bridgebuilder|Reformer': 'Esther the Courageous Intercessor',
    'Bridgebuilder|Sentinel': 'Daniel the Wise Negotiator',
    'Bridgebuilder|Welcomer': 'Lydia the Relational Connector',
    'Cultivator|Healer': 'Ruth the Loyal Restorer',
    'Cultivator|Pillar': 'Joseph the Patient Steward',
    'Harvester|Sower': 'Paul the Mission Multiplier',
    'Harvester|Welcomer': 'Boaz the Protective Provider',
    'Healer|Welcomer': 'Tabitha the Compassion Organizer',
    'Pillar|Sentinel': 'Anna the Prayerful Servant',
    'Pillar|Welcomer': 'Martha the Faithful Host',
    'Reformer|Sower': 'Peter the Bold Activator',
    'Reformer|Watchman': 'Deborah the Courageous Judge',
    'Sentinel|Watchman': 'Nehemiah the Prayerful Guard',
  };

  static ArchetypeResonance? forArchetype(String archetypeName) =>
      _primary[archetypeName];

  static String? getDualCombination(String archetype1, String archetype2) {
    final key1 = '$archetype1|$archetype2';
    final key2 = '$archetype2|$archetype1';
    return _dualCombinations[key1] ?? _dualCombinations[key2];
  }

  static ArchetypePersona resolveFromOrderedNames(List<String> orderedNames) {
    if (orderedNames.isEmpty) {
      return const ArchetypePersona(
        tribe: 'Unknown Tribe',
        bibleCharacter: 'Barnabas the Encourager',
      );
    }

    final primaryName = orderedNames.first;
    final primaryResonance = _primary[primaryName];
    final tribe = primaryResonance?.tribe ?? 'Unknown Tribe';

    String bibleCharacter =
        primaryResonance?.bibleCharacter ?? 'Barnabas the Encourager';

    if (orderedNames.length > 1) {
      final pairKey = _normalizedPairKey(primaryName, orderedNames[1]);
      bibleCharacter = _pairCharacters[pairKey] ?? bibleCharacter;
    }

    return ArchetypePersona(
      tribe: tribe,
      bibleCharacter: bibleCharacter,
    );
  }

  static String _normalizedPairKey(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}|${pair[1]}';
  }
}
