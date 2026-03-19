import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/achievements/achievement_registry.dart';

class AchievementsDialog {
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const _AchievementsDialogBody(),
    );
  }
}

class _AchievementsDialogBody extends ConsumerWidget {
  const _AchievementsDialogBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final unlocked = settings.unlockedBadges;
    final unlockedIds = unlocked.keys.toSet();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Achievements',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${unlockedIds.length} unlocked',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final badge = AchievementRegistry.all[index];
                  final isUnlocked = unlockedIds.contains(badge.id);
                  final unlockedAt = unlocked[badge.id];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isUnlocked
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    title: Text(
                      badge.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          badge.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isUnlocked ? 0.75 : 0.45,
                            ),
                          ),
                        ),
                        if (isUnlocked && unlockedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Unlocked: ${_formatIso(unlockedAt)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isUnlocked
                        ? Icon(
                            Icons.verified_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : Icon(
                            Icons.lock_outline,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                  );
                },
                separatorBuilder: (_, __) => Divider(
                  height: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                itemCount: AchievementRegistry.all.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIso(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final normalized = DateTime(dt.year, dt.month, dt.day);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }
}
