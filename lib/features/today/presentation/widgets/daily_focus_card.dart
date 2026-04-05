import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/daily_anchors.dart';

/// A single premium card that replaces ArchetypeIdentityBadge +
/// DailyProgressCard + CommitmentSummaryCard on the home screen.
class DailyFocusCard extends ConsumerWidget {
  const DailyFocusCard({
    super.key,
    required this.anchors,
    this.onProgressTap,
  });

  final DailyAnchors anchors;
  final VoidCallback? onProgressTap;

  int _completedCount() {
    int count = 0;
    if (anchors.coreVirtue.isCompleted) count++;
    if (anchors.habit.isCompleted) count++;
    if (anchors.energyAction.isCompleted) count++;
    return count;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final gcState = ref.watch(graduatedCommitmentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completed = _completedCount();
    final progress = completed / 3.0;

    final archetypeName = settings.primaryArchetypeId;
    final categoryName = settings.commitmentCategory;
    final hasArchetype = archetypeName != null && archetypeName.isNotEmpty;

    // Build identity line: "Artisan · Charity"
    String? identityLine;
    if (hasArchetype && categoryName != null && categoryName.isNotEmpty) {
      final catLabel = categoryName[0].toUpperCase() + categoryName.substring(1);
      identityLine = '$archetypeName · $catLabel';
    } else if (hasArchetype) {
      identityLine = archetypeName;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: GestureDetector(
        onTap: onProgressTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                theme.colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.02),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
            ),
          ),
          child: Row(
            children: [
              // Circular progress
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    completed == 3
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green.shade600,
                            size: 28,
                          )
                        : Text(
                            '$completed/3',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (identityLine != null)
                      Text(
                        identityLine,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    if (identityLine != null) const SizedBox(height: 4),
                    Text(
                      completed == 3
                          ? 'All done! Read your verse of the day'
                          : completed == 0
                              ? 'Begin your daily clarity'
                              : '${3 - completed} step${3 - completed > 1 ? 's' : ''} remaining',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    // Show active commitment if any
                    if (gcState.activeCommitment != null) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.commitmentActive),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                gcState.activeCommitment!.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black45,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
