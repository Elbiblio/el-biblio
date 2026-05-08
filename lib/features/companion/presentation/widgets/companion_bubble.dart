import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../application/companion_notifier.dart';
import '../../application/companion_nudge_provider.dart';
import '../../domain/models/companion_character.dart';
import '../../domain/models/companion_mood.dart';
import 'companion_haptics.dart';
import 'companion_orb.dart';

/// Today-screen presence — the companion's one-line nudge for the day.
/// Tap opens the chat with the nudge pre-seeded as the first assistant turn.
///
/// Silently renders nothing if no companion has been selected yet.
class CompanionBubble extends ConsumerWidget {
  const CompanionBubble({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final character = ref.watch(
      companionProvider.select((s) => s.activeCharacter),
    );
    if (character == null) return const SizedBox.shrink();

    final dayKey = companionTodayDayKey();
    final nudgeAsync = ref.watch(companionTodayNudgeProvider(dayKey));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openChat(context, ref, character, nudgeAsync.valueOrNull?.text),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CompanionOrb(
                  character: character,
                  mood: nudgeAsync.isLoading
                      ? CompanionMood.thinking
                      : CompanionMood.warm,
                  size: 48,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            character.displayName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            character.tagline,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      nudgeAsync.when(
                        data: (result) => Text(
                          result.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.78),
                            height: 1.45,
                          ),
                        ),
                        loading: () => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _loadingHint(character),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        error: (_, __) => Text(
                          _errorHint(character),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.68),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    CompanionCharacter character,
    String? seed,
  ) async {
    CompanionHaptics.acknowledge(character);
    if (!context.mounted) return;
    final dayKey = companionTodayDayKey();
    await context.push(
      '${AppRoutes.companionChat}?thread=today-$dayKey&title=${Uri.encodeQueryComponent(character.displayName)}',
      extra: seed == null ? null : {'seedAssistantOpener': seed},
    );
  }

  String _loadingHint(CompanionCharacter c) => switch (c) {
        CompanionCharacter.raziel => 'listening to today…',
        CompanionCharacter.naomi => 'taking a breath with you…',
        CompanionCharacter.james => 'picking today\'s next step…',
      };

  String _errorHint(CompanionCharacter c) => switch (c) {
        CompanionCharacter.raziel =>
          'Signal is thin — tap to sit with me anyway.',
        CompanionCharacter.naomi =>
          'My voice is quiet right now. Tap and we\'ll talk.',
        CompanionCharacter.james =>
          'Signal down. Tap — let\'s keep moving.',
      };
}
