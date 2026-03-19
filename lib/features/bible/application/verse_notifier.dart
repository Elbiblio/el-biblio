import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/verse_repository.dart';
import '../domain/models/verse.dart';

class DailyVersesState {
  const DailyVersesState({
    this.todayVerse,
    this.tomorrowVerse,
    this.isLoading = false,
    this.error,
  });

  final Verse? todayVerse;
  final Verse? tomorrowVerse;
  final bool isLoading;
  final String? error;

  DailyVersesState copyWith({
    Verse? todayVerse,
    Verse? tomorrowVerse,
    bool? isLoading,
    String? error,
  }) {
    return DailyVersesState(
      todayVerse: todayVerse ?? this.todayVerse,
      tomorrowVerse: tomorrowVerse ?? this.tomorrowVerse,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class VerseNotifier extends StateNotifier<DailyVersesState> {
  VerseNotifier(this._repository) : super(const DailyVersesState()) {
    loadDailyVerses();
  }

  final VerseRepository _repository;

  Future<void> loadDailyVerses() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final verses = await _repository.getDailyVerses();
      
      // Logic to separate today and tomorrow matches the TS implementation roughly
      // But for simplicity, let's just take the first one as today if available
      // The API returns them sorted by date usually or we can check the date field
      
      Verse? today;
      Verse? tomorrow;

      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      for (final verse in verses) {
        // If date matches today
        if (verse.date != null) {
          final vDate = verse.date!;
          final vDateStr = "${vDate.year}-${vDate.month.toString().padLeft(2, '0')}-${vDate.day.toString().padLeft(2, '0')}";
          if (vDateStr == todayStr) {
            today = verse;
          } else if (vDate.isAfter(now)) {
            tomorrow = verse;
          }
        }
      }

      // Fallback if date matching fails or is empty, just take the first ones
      if (today == null && verses.isNotEmpty) {
        today = verses.first;
      }
      if (tomorrow == null && verses.length > 1) {
        tomorrow = verses[1];
      }

      state = state.copyWith(
        todayVerse: today,
        tomorrowVerse: tomorrow,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> explainVerse({
    required String verseId,
    required String reference,
    required String text,
    String? version,
    String? prompt,
  }) async {
    try {
      return await _repository.explainVerse(
        verseId: verseId,
        reference: reference,
        text: text,
        version: version,
        prompt: prompt,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> voteVerse(int id) async {
    try {
      final success = await _repository.voteVerse(id);
      if (success) {
        // Optimistically update or reload
        // For now, let's reload to get the fresh vote count
        await loadDailyVerses();
      }
    } catch (e) {
      // Handle error silently or show snackbar in UI
    }
  }
}
