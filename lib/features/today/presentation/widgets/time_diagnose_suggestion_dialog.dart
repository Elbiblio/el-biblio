import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TimeDiagnoseSuggestionDialog {
  const TimeDiagnoseSuggestionDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              color: Color(0xFF7A8471),
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Time Management Check-in'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You\'ve taken a break from check-ins. Life happens. Would a quick time audit help you find a rhythm that works better?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7A8471).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7A8471).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF7A8471),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The Time Audit helps you analyze how you\'re spending your 24 hours.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/time-diagnose');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A8471),
              foregroundColor: Colors.white,
            ),
            child: const Text('Analyze My Time'),
          ),
        ],
      ),
    );
  }
}
