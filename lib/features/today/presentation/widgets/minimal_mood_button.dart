import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/mood_notifier.dart';
import '../../domain/models/mood.dart';
import 'mood_selection_dialog.dart';

class MinimalMoodButton extends ConsumerWidget {
  const MinimalMoodButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodState = ref.watch(moodProvider);
    final currentMood = moodState.currentMood;

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (context) => const MoodSelectionDialog(),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentMood?.type.emoji ?? '❓',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              currentMood?.type.displayName ?? 'Mood',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
