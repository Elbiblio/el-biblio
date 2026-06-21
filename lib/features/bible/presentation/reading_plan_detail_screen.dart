import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/services/sound_service.dart';
import '../../../shared/widgets/ambient_scope.dart';
import '../../../shared/widgets/premium_success_dialog.dart';
import '../domain/models/reading_plan.dart';

class ReadingPlanDetailScreen extends ConsumerWidget {
  const ReadingPlanDetailScreen({
    required this.planId,
    super.key,
  });

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final planState = ref.watch(readingPlanProvider);

    final selectedPlan = planState.selectedPlan;
    final planFromList = planState.plans
        .where((p) => p.id == planId)
        .cast<ReadingPlan?>()
        .firstWhere((p) => p != null, orElse: () => null);

    final plan = (selectedPlan?.id == planId) ? selectedPlan : planFromList;

    if (plan == null && !planState.isLoading) {
      Future.microtask(() {
        ref.read(readingPlanProvider.notifier).loadPlanDetails(planId);
      });
    }

    return AmbientScope(
      asset: SoundService.ambientBibleAsset,
      volume: 0.06,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Reading Plan'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan == null) ...[
                if (planState.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 44,
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load plan details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please check your connection and try again.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: () {
                              ref
                                  .read(readingPlanProvider.notifier)
                                  .loadPlanDetails(planId);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ] else ...[
                Text(
                  plan.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description ?? '${plan.durationDays} day reading plan',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${plan.durationDays} days',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${plan.days.length} sessions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: plan.days.length.clamp(0, 7),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final day = plan.days[index];
                      final title = day.devotionalTitle?.trim().isNotEmpty == true
                          ? day.devotionalTitle!
                          : 'Day ${day.dayNumber}';

                      final subtitle = (day.verses.isNotEmpty)
                          ? day.verses.take(2).join(', ')
                          : 'Scripture reading';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                        onTap: () => ref.read(soundServiceProvider).playPageTurn(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: planState.isLoading
                        ? null
                        : () async {
                            ref.read(soundServiceProvider).playChimeGentle();
                            final success = await ref
                                .read(readingPlanProvider.notifier)
                                .startPlan(plan.id);

                            if (!success) {
                              if (!context.mounted) return;
                              await PremiumSuccessDialog.show(
                                context,
                                title: 'Could not start plan',
                                message:
                                    'Please check your connection and try again.',
                                primaryActionText: 'OK',
                              );
                              return;
                            }

                            if (!context.mounted) return;

                            await PremiumSuccessDialog.show(
                              context,
                              title: 'Plan Started',
                              message: '"${plan.title}" is now active.\nReady to stay consistent?',
                              primaryActionText: 'Continue',
                            );

                            if (!context.mounted) return;

                            final settings = ref.read(settingsProvider);
                            if (!settings.morningReminderEnabled) {
                              final shouldSetup = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Set reminders now?'),
                                    content: const Text(
                                      'A daily reminder can help you stay on track with your plan.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Not now'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Set reminder'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldSetup == true && context.mounted) {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                                );

                                if (picked != null && context.mounted) {
                                  final morningTimeString =
                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

                                  await ref
                                      .read(settingsProvider.notifier)
                                      .updateReminderPreferences(
                                        morningTime: morningTimeString,
                                        morningReminderEnabled: true,
                                      );

                                  if (!context.mounted) return;

                                  await PremiumSuccessDialog.show(
                                    context,
                                    title: 'Reminder Set',
                                    message:
                                        'Daily reminder scheduled for ${picked.format(context)}.',
                                    primaryActionText: 'Done',
                                  );
                                }
                              }
                            }

                            if (!context.mounted) return;

                            context.push(AppRoutes.bible);
                          },
                    child: Text(planState.isLoading ? 'Starting…' : 'Start this plan'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}
