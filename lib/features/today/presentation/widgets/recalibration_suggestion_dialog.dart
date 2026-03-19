import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

class RecalibrationSuggestionDialog {
  static Future<void> show(
    BuildContext context, {
    required int missedDays,
    required VoidCallback onOpenTimeDiagnose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);

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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reset your rhythm',
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
                  missedDays == 1
                      ? 'Looks like you missed a day. Want to adjust your reminders so it fits your schedule?'
                      : 'Looks like you missed $missedDays days. Let\'s make it easier to return without pressure.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.reminders);
                  },
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
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
}
