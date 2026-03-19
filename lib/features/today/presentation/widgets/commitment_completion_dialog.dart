import 'package:flutter/material.dart';

import '../../domain/models/daily_anchors.dart';

class CommitmentCompletionDialog {
  const CommitmentCompletionDialog._();

  static Future<void> show(
    BuildContext context, {
    required Habit habit,
    required VoidCallback onSucceeded,
    required VoidCallback onFailed,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commitment Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your commitment is complete. How did it go?'),
            const SizedBox(height: 16),
            Text(
              'You committed to: ${habit.description}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onFailed();
            },
            child: const Text('Will try again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSucceeded();
            },
            child: const Text('I did this!'),
          ),
        ],
      ),
    );
  }
}
