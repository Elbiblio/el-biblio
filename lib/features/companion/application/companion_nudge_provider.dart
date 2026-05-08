import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../domain/models/companion_character.dart';
import 'companion_notifier.dart';

class TodayNudgeResult {
  const TodayNudgeResult({required this.text, required this.characterCode});
  final String text;
  final String characterCode;
}

/// Daily nudge for the Today-screen bubble. Auto-invalidates at midnight-local
/// because the family key is the ISO-day string of `DateTime.now()`.
final companionTodayNudgeProvider = FutureProvider.autoDispose
    .family<TodayNudgeResult, String>((ref, dayKey) async {
  final character = ref.watch(
    companionProvider.select((s) => s.activeCharacter),
  );
  final effective = character ?? CompanionCharacter.naomi;
  final repo = ref.watch(companionRepositoryProvider);
  final settings = ref.watch(settingsProvider);

  final weakest = settings.christianLifeBaseline?.weakestDimension;

  final text = await repo.todayNudge(
    character: effective,
    context: {
      if (settings.primaryArchetypeId != null)
        'archetype': settings.primaryArchetypeId,
      if (settings.commitmentCategory != null)
        'commitment_category': settings.commitmentCategory,
      if (settings.primaryVirtue.name.isNotEmpty)
        'daily_virtue': settings.primaryVirtue.name,
      if (weakest != null) 'weakest_dimension': weakest.name,
      'streak': settings.streakCount,
      'day_key': dayKey,
    },
  );

  return TodayNudgeResult(text: text, characterCode: effective.code);
});

String companionTodayDayKey([DateTime? now]) {
  final n = now ?? DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}
