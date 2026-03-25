import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../widgets/motivational_overlay.dart';

class AppLockLimitReachedScreen extends ConsumerWidget {
  const AppLockLimitReachedScreen({
    super.key,
    required this.packageName,
  });

  final String packageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appLockProvider);
    final record = state.todayUsage.firstWhere(
      (r) => r.packageName == packageName,
      orElse: () => throw StateError('No record found'),
    );
    final config = state.configs.firstWhere(
      (c) => c.packageName == packageName,
      orElse: () => throw StateError('No config found'),
    );
    final extensionsRemaining = 3 - state.extensionsUsedToday;

    return MotivationalOverlay(
      appName: config.appName,
      usedMinutes: record.usedMinutesToday,
      canExtend: extensionsRemaining > 0,
      extensionsRemaining: extensionsRemaining,
      streakDays: state.goalStreakDays,
      onDismiss: () => context.pop(),
      onExtend: () async {
        final success = await ref
            .read(appLockProvider.notifier)
            .requestExtension(packageName);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Extended by 5 minutes. ${extensionsRemaining - 1} extensions remaining today.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      },
    );
  }
}
