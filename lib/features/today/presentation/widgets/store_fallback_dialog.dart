import 'package:flutter/material.dart';

class StoreFallbackDialog {
  const StoreFallbackDialog._();

  static Future<void> show(
    BuildContext context, {
    required String url,
    required String platform,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Visit $platform'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Visit our $platform to leave a review:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
