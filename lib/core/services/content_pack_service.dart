import '../../features/connect/domain/models/christian_tradition.dart';

/// Service for managing optional content packs.
///
/// Content packs provide tradition-specific prayers, commitments, and media.
/// The base app works fully without any pack installed. Packs are
/// downloadable expansions, not required content.
class ContentPackService {
  static ContentPackService? _instance;
  static ContentPackService get instance =>
      _instance ??= ContentPackService._();
  ContentPackService._();

  final List<ContentPack> _installed = [];

  bool get hasAnyPack => _installed.isNotEmpty;

  List<ContentPack> get installed => List.unmodifiable(_installed);

  bool isInstalled(String packId) =>
      _installed.any((p) => p.id == packId);

  void install(ContentPack pack) {
    if (!isInstalled(pack.id)) {
      _installed.add(pack);
    }
  }

  void uninstall(String packId) {
    _installed.removeWhere((p) => p.id == packId);
  }

  List<ContentPack> availableFor(ChristianTradition tradition) {
    return _allPacks.where((p) => p.tradition == tradition).toList();
  }

  static const List<ContentPack> _allPacks = [
    ContentPack(
      id: 'catholic_prayers',
      name: 'Catholic Prayer Collection',
      tradition: ChristianTradition.catholic,
      description: 'Rosary, Stations of the Cross, Novenas, and Catholic devotions.',
      size: 4,
    ),
    ContentPack(
      id: 'catholic_commitments',
      name: 'Catholic Commitment Plans',
      tradition: ChristianTradition.catholic,
      description: 'Liturgical season plans, saint-inspired growth goals.',
      size: 3,
    ),
    ContentPack(
      id: 'orthodox_prayers',
      name: 'Orthodox Prayer Collection',
      tradition: ChristianTradition.orthodox,
      description: 'Jesus Prayer, Akathists, and liturgical prayers.',
      size: 4,
    ),
    ContentPack(
      id: 'evangelical_study',
      name: 'Evangelical Bible Study Plans',
      tradition: ChristianTradition.protestantEvangelical,
      description: 'Book studies, topical plans, and SOAP journaling guides.',
      size: 3,
    ),
    ContentPack(
      id: 'mainline_devotional',
      name: 'Mainline Devotional Collection',
      tradition: ChristianTradition.protestantMainline,
      description: 'Lectionary-based reflections and social justice prayers.',
      size: 3,
    ),
    ContentPack(
      id: 'reformed_catechism',
      name: 'Reformed Catechism Studies',
      tradition: ChristianTradition.protestantReformed,
      description: 'Heidelberg, Westminster, and confessions study plans.',
      size: 3,
    ),
  ];
}

class ContentPack {
  final String id;
  final String name;
  final ChristianTradition tradition;
  final String description;
  final int size;

  const ContentPack({
    required this.id,
    required this.name,
    required this.tradition,
    required this.description,
    required this.size,
  });
}
