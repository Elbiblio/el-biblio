import 'package:flutter/material.dart';

import '../../domain/models/daily_anchors.dart';

class CommitmentWaitingDialog {
  const CommitmentWaitingDialog._();

  static Future<void> show(BuildContext context, Habit habit) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.lock_clock_rounded,
              color: Color(0xFF7A8471),
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Commitment Locked In'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your commitment has been locked in and will start automatically at the scheduled time.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (habit.commitmentTitle != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A8471).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.commitmentTitle!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (habit.commitmentDescription != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.commitmentDescription!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
