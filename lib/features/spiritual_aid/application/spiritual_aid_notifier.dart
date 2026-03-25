import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../data/spiritual_aid_repository.dart';
import '../domain/models/quick_prayer.dart';
import '../domain/models/faith_prompt.dart';
import '../domain/models/verse_moment.dart';
import '../domain/models/evangelism_content.dart';

// ─── Providers ───────────────────────────────────────────────────────

final spiritualAidRepositoryProvider = Provider<SpiritualAidRepository>((ref) {
  return SpiritualAidRepository(
    ref.watch(dioClientProvider),
    ref.watch(loggerProvider),
    ref.watch(bibleRepositoryProvider),
  );
});

final spiritualAidProvider =
    StateNotifierProvider<SpiritualAidNotifier, SpiritualAidState>((ref) {
  final notifier = SpiritualAidNotifier(ref.watch(spiritualAidRepositoryProvider));
  notifier.initialize();
  return notifier;
});

class SpiritualAidState {
  const SpiritualAidState({
    this.prayers = const [],
    this.favoritePrayers = const [],
    this.prayerHistory = const [],
    this.dailyPrompt,
    this.allPrompts = const [],
    this.currentVerse,
    this.verseHistory = const [],
    this.evangelismContent = const [],
    this.isLoading = false,
    this.isVerseLoading = false,
    this.isExplanationLoading = false,
    this.error,
    this.activeCategory,
    this.activePrayerCategory,
    this.activePromptCategory,
    this.activeEvangelismType,
  });

  final List<QuickPrayer> prayers;
  final List<QuickPrayer> favoritePrayers;
  final List<QuickPrayer> prayerHistory;
  final FaithPrompt? dailyPrompt;
  final List<FaithPrompt> allPrompts;
  final VerseMoment? currentVerse;
  final List<VerseMoment> verseHistory;
  final List<EvangelismContent> evangelismContent;
  final bool isLoading;
  final bool isVerseLoading;
  final bool isExplanationLoading;
  final String? error;
  final String? activeCategory;
  final String? activePrayerCategory;
  final String? activePromptCategory;
  final String? activeEvangelismType;

  SpiritualAidState copyWith({
    List<QuickPrayer>? prayers,
    List<QuickPrayer>? favoritePrayers,
    List<QuickPrayer>? prayerHistory,
    FaithPrompt? dailyPrompt,
    List<FaithPrompt>? allPrompts,
    VerseMoment? currentVerse,
    List<VerseMoment>? verseHistory,
    List<EvangelismContent>? evangelismContent,
    bool? isLoading,
    bool? isVerseLoading,
    bool? isExplanationLoading,
    String? error,
    String? activeCategory,
    String? activePrayerCategory,
    String? activePromptCategory,
    String? activeEvangelismType,
  }) {
    return SpiritualAidState(
      prayers: prayers ?? this.prayers,
      favoritePrayers: favoritePrayers ?? this.favoritePrayers,
      prayerHistory: prayerHistory ?? this.prayerHistory,
      dailyPrompt: dailyPrompt ?? this.dailyPrompt,
      allPrompts: allPrompts ?? this.allPrompts,
      currentVerse: currentVerse ?? this.currentVerse,
      verseHistory: verseHistory ?? this.verseHistory,
      evangelismContent: evangelismContent ?? this.evangelismContent,
      isLoading: isLoading ?? this.isLoading,
      isVerseLoading: isVerseLoading ?? this.isVerseLoading,
      isExplanationLoading: isExplanationLoading ?? this.isExplanationLoading,
      error: error,
      activeCategory: activeCategory ?? this.activeCategory,
      activePrayerCategory: activePrayerCategory ?? this.activePrayerCategory,
      activePromptCategory: activePromptCategory ?? this.activePromptCategory,
      activeEvangelismType: activeEvangelismType ?? this.activeEvangelismType,
    );
  }
}

class SpiritualAidNotifier extends StateNotifier<SpiritualAidState> {
  SpiritualAidNotifier(this._repository) : super(const SpiritualAidState());

  final SpiritualAidRepository _repository;

  // ─── Initialization ────────────────────────────────────────────────

  void initialize() {
    loadPrayers();
    loadDailyPrompt();
    loadVerseHistory();
    loadEvangelismContent();
  }

  // ─── Quick Prayers ─────────────────────────────────────────────────

  void loadPrayers({String? category}) {
    final prayers = _repository.getQuickPrayers(category: category);
    final favorites = _repository.getFavoritePrayers();
    final history = _repository.getPrayerHistory();
    state = state.copyWith(
      prayers: prayers,
      favoritePrayers: favorites,
      prayerHistory: history,
      activePrayerCategory: category,
    );
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    loadPrayers(category: state.activePrayerCategory);
  }

  Future<void> addPrayerToHistory(String prayerId) async {
    await _repository.addPrayerToHistory(prayerId);
    state = state.copyWith(prayerHistory: _repository.getPrayerHistory());
  }

  void filterPrayersByCategory(String? category) {
    loadPrayers(category: category);
  }

  // ─── Faith Prompts ─────────────────────────────────────────────────

  void loadDailyPrompt() {
    final prompt = _repository.getDailyPrompt();
    final allPrompts = _repository.getAllPrompts();
    state = state.copyWith(
      dailyPrompt: prompt,
      allPrompts: allPrompts,
    );
  }

  void filterPromptsByCategory(String? category) {
    state = state.copyWith(activePromptCategory: category);
    if (category != null) {
      state = state.copyWith(
        allPrompts: _repository.getPromptsByCategory(category),
      );
    } else {
      state = state.copyWith(
        allPrompts: _repository.getAllPrompts(),
      );
    }
  }

  // ─── Speak to Me ──────────────────────────────────────────────────

  Future<void> generateRandomVerse() async {
    state = state.copyWith(isVerseLoading: true, error: null);
    try {
      final verse = await _repository.getRandomVerse();
      state = state.copyWith(
        currentVerse: verse,
        isVerseLoading: false,
        verseHistory: _repository.getVerseHistory(),
      );
    } catch (e) {
      state = state.copyWith(
        isVerseLoading: false,
        error: 'Failed to generate verse: $e',
      );
    }
  }

  Future<void> explainCurrentVerse() async {
    final verse = state.currentVerse;
    if (verse == null) return;

    state = state.copyWith(isExplanationLoading: true);
    try {
      final explanation = await _repository.getVerseExplanation(
        verse.reference,
        verse.verseText,
      );
      if (explanation != null) {
        state = state.copyWith(
          currentVerse: verse.copyWith(explanation: explanation),
          isExplanationLoading: false,
        );
      } else {
        state = state.copyWith(isExplanationLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isExplanationLoading: false,
        error: 'Failed to explain verse: $e',
      );
    }
  }

  void loadVerseHistory() {
    state = state.copyWith(verseHistory: _repository.getVerseHistory());
  }

  Future<void> toggleVerseBookmark(int index) async {
    await _repository.toggleVerseBookmark(index);
    loadVerseHistory();
  }

  // ─── Evangelism Content ────────────────────────────────────────────

  void loadEvangelismContent({String? type, String? category}) {
    final content = _repository.getEvangelismContent(type: type, category: category);
    state = state.copyWith(
      evangelismContent: content,
      activeEvangelismType: type,
    );
  }

  void filterEvangelismByType(String? type) {
    loadEvangelismContent(type: type);
  }
}
