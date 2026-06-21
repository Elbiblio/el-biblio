import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../features/commit/application/failure_protocol_service.dart';

class RecalibrationSuggestionDialog {
  static Future<void> show(
    BuildContext context, {
    required int missedDays,
    required FailureState failureState,
    required String habitName,
    required List<AdmissionOption> admissionOptions,
    required void Function(String admittedTo) onRecordAdmission,
    required VoidCallback onOpenTimeDiagnose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final protocol = FailureProtocolService();
        final message = failureState.level == FailureLevel.none
            ? (missedDays == 1
                ? 'You missed a day. Receive grace, then choose a reminder you can keep.'
                : 'You\'ve had a $missedDays-day break. Receive grace, then choose a simpler way to return.')
            : protocol.messageForLevel(failureState.level, habitName);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        failureState.level == FailureLevel.none
                            ? 'Begin again with grace'
                            : 'You missed $habitName',
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
                const SizedBox(height: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
                if (failureState.level != FailureLevel.none) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reach out',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...admissionOptions.map((option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_iconForOption(option.key)),
                    title: Text(option.label),
                    subtitle: Text(option.description),
                    onTap: () {
                      onRecordAdmission(option.key);
                      Navigator.of(context).pop();
                      _routeForOption(context, option.key);
                    },
                  )),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.reminders);
                  },
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: const Text('Adjust reminders'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenTimeDiagnose();
                  },
                  icon: const Icon(Icons.insights_rounded, size: 18),
                  label: const Text('Open Time Diagnose'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _iconForOption(String key) {
    return switch (key) {
      'companion' => Icons.chat_bubble_outline,
      'partner' => Icons.people_outline,
      'circle' => Icons.groups_outlined,
      'prayer' => Icons.book_outlined,
      _ => Icons.arrow_forward,
    };
  }

  static void _routeForOption(BuildContext context, String key) {
    switch (key) {
      case 'companion':
        context.push(AppRoutes.companionChat);
      case 'partner':
        context.push(AppRoutes.growTogether);
      case 'circle':
        context.push(AppRoutes.tribe);
      case 'prayer':
        context.push('${AppRoutes.spiritualAid}/prayers');
      default:
        context.push(AppRoutes.home);
    }
  }
}
