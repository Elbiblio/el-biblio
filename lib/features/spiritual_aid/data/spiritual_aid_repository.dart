import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/repository/base_repository.dart';
import '../../bible/data/bible_repository.dart';
import '../domain/models/quick_prayer.dart';
import '../domain/models/faith_prompt.dart';
import '../domain/models/verse_moment.dart';
import '../domain/models/evangelism_content.dart';
import 'prayer_catalog.dart';
import 'faith_prompt_catalog.dart';
import 'evangelism_catalog.dart';

class SpiritualAidRepository extends BaseRepository {
  SpiritualAidRepository(
    this._client,
    Logger logger,
    this._bibleRepository,
  ) : super(logger);

  final DioClient _client;
  final BibleRepository _bibleRepository;

  static const _favoritesBoxName = 'spiritual_aid_favorites';
  static const _verseHistoryBoxName = 'spiritual_aid_verse_history';
  static const _prayerHistoryBoxName = 'spiritual_aid_prayer_history';

  // ─── Quick Prayers ─────────────────────────────────────────────────

  List<QuickPrayer> getQuickPrayers({String? category}) {
    final favorites = _getFavoriteIds();
    var prayers = PrayerCatalog.all;
    if (category != null) {
      prayers = PrayerCatalog.byCategory(category);
    }
    return prayers.map((p) => p.copyWith(
      isFavorite: favorites.contains(p.id),
    )).toList();
  }

  List<QuickPrayer> getFavoritePrayers() {
    final favorites = _getFavoriteIds();
    return PrayerCatalog.all
        .where((p) => favorites.contains(p.id))
        .map((p) => p.copyWith(isFavorite: true))
        .toList();
  }

  Future<void> toggleFavorite(String id) async {
    final box = await Hive.openBox<String>(_favoritesBoxName);
    final favorites = Set<String>.from(
      box.get('prayer_favorites', defaultValue: '')!.split(',').where((s) => s.isNotEmpty),
    );

    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }

    await box.put('prayer_favorites', favorites.join(','));
  }

  Set<String> _getFavoriteIds() {
    try {
      final box = Hive.box<String>(_favoritesBoxName);
      final raw = box.get('prayer_favorites', defaultValue: '') ?? '';
      return Set<String>.from(raw.split(',').where((s) => s.isNotEmpty));
    } catch (_) {
      return {};
    }
  }

  Future<void> addPrayerToHistory(String prayerId) async {
    final box = await Hive.openBox<String>(_prayerHistoryBoxName);
    final history = List<String>.from(
      (box.get('history', defaultValue: '') ?? '').split(',').where((s) => s.isNotEmpty),
    );

    history.remove(prayerId);
    history.insert(0, prayerId);

    // Keep last 50
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    await box.put('history', history.join(','));
  }

  List<QuickPrayer> getPrayerHistory() {
    try {
      final box = Hive.box<String>(_prayerHistoryBoxName);
      final raw = box.get('history', defaultValue: '') ?? '';
      final ids = raw.split(',').where((s) => s.isNotEmpty).toList();
      final favorites = _getFavoriteIds();
      return ids
          .map((id) => PrayerCatalog.byId(id))
          .whereType<QuickPrayer>()
          .map((p) => p.copyWith(isFavorite: favorites.contains(p.id)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Faith Prompts ─────────────────────────────────────────────────

  FaithPrompt getDailyPrompt() {
    return FaithPromptCatalog.getDailyPrompt();
  }

  List<FaithPrompt> getPromptsByCategory(String category) {
    return FaithPromptCatalog.byCategory(category);
  }

  List<FaithPrompt> getAllPrompts() {
    return FaithPromptCatalog.all;
  }

  // ─── Speak to Me (Random Verse) ───────────────────────────────────

  Future<VerseMoment> getRandomVerse() async {
    try {
      // Try getting from local Bible DB
      final verses = await _bibleRepository.getRandomVerses(1);
      if (verses.isNotEmpty) {
        final verse = verses.first;
        final moment = VerseMoment(
          verseText: verse.text,
          reference: verse.reference ?? 'Verse ${verse.chapter}:${verse.verse}',
          bookContext: null,
          generatedAt: DateTime.now(),
        );
        await _saveVerseToHistory(moment);
        return moment;
      }
    } catch (e) {
      logger.w('Failed to get verse from local DB: $e');
    }

    // Fallback: try API
    try {
      final response = await _client.get('/bible/random-verses', queryParameters: {'count': 1});
      final data = response.data['data'] as List?;
      if (data != null && data.isNotEmpty) {
        final v = data.first;
        final moment = VerseMoment(
          verseText: v['text'] as String,
          reference: v['reference'] as String? ?? '',
          bookContext: v['book'] as String?,
          generatedAt: DateTime.now(),
        );
        await _saveVerseToHistory(moment);
        return moment;
      }
    } catch (e) {
      logger.w('Failed to get verse from API: $e');
    }

    // Final fallback: static verse
    final now = DateTime.now();
    final fallbacks = [
      VerseMoment(
        verseText: 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
        reference: 'John 3:16',
        bookContext: 'John',
        generatedAt: now,
      ),
      VerseMoment(
        verseText: 'The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.',
        reference: 'Psalm 23:1-3',
        bookContext: 'Psalms',
        generatedAt: now,
      ),
      VerseMoment(
        verseText: 'I can do all this through him who gives me strength.',
        reference: 'Philippians 4:13',
        bookContext: 'Philippians',
        generatedAt: now,
      ),
      VerseMoment(
        verseText: 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
        reference: 'Proverbs 3:5-6',
        bookContext: 'Proverbs',
        generatedAt: now,
      ),
    ];
    final moment = fallbacks[Random().nextInt(fallbacks.length)];
    await _saveVerseToHistory(moment);
    return moment;
  }

  Future<String?> getVerseExplanation(String reference, String text) async {
    try {
      final response = await _client.post(
        '/bible/verses/0/explain',
        data: {
          'reference': reference,
          'text': text,
          'version': 'eng_rv_vpl',
        },
      );

      final data = response.data['data'] ?? response.data;
      return data['explanation'] as String?;
    } catch (e) {
      logger.w('Failed to get verse explanation: $e');
      return null;
    }
  }

  Future<void> _saveVerseToHistory(VerseMoment verse) async {
    try {
      final box = await Hive.openBox<String>(_verseHistoryBoxName);
      final rawList = box.get('history', defaultValue: '[]') ?? '[]';
      final List<dynamic> history = jsonDecode(rawList);

      history.insert(0, verse.toJson());

      // Keep last 100
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }

      await box.put('history', jsonEncode(history));
    } catch (e) {
      logger.w('Failed to save verse to history: $e');
    }
  }

  List<VerseMoment> getVerseHistory() {
    try {
      final box = Hive.box<String>(_verseHistoryBoxName);
      final rawList = box.get('history', defaultValue: '[]') ?? '[]';
      final List<dynamic> history = jsonDecode(rawList);
      return history
          .map((json) => VerseMoment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleVerseBookmark(int index) async {
    try {
      final box = await Hive.openBox<String>(_verseHistoryBoxName);
      final rawList = box.get('history', defaultValue: '[]') ?? '[]';
      final List<dynamic> history = jsonDecode(rawList);

      if (index >= 0 && index < history.length) {
        final verse = VerseMoment.fromJson(history[index] as Map<String, dynamic>);
        history[index] = verse.copyWith(isBookmarked: !verse.isBookmarked).toJson();
        await box.put('history', jsonEncode(history));
      }
    } catch (e) {
      logger.w('Failed to toggle bookmark: $e');
    }
  }

  // ─── Evangelism Content ────────────────────────────────────────────

  List<EvangelismContent> getEvangelismContent({String? type, String? category}) {
    var content = EvangelismCatalog.all;
    if (type != null) {
      content = EvangelismCatalog.byType(type);
    }
    if (category != null) {
      content = content.where((c) => c.category == category).toList();
    }
    return content;
  }

  // ─── Hive Box Initialization ───────────────────────────────────────

  static Future<void> initializeBoxes() async {
    await Hive.openBox<String>(_favoritesBoxName);
    await Hive.openBox<String>(_verseHistoryBoxName);
    await Hive.openBox<String>(_prayerHistoryBoxName);
  }
}
