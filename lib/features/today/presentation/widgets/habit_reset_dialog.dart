import 'package:flutter/material.dart';

class HabitResetDialog {
  const HabitResetDialog._();

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onReset,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Color(0xFF7A8471),
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Reset Habit?'),
          ],
        ),
        content: const Text(
          'This habit is in an unexpected state. Would you like to reset it and start over?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onReset();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A8471),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
