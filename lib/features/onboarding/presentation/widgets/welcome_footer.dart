import 'package:flutter/material.dart';

/// The bottom section with footer text only (button moved to bottom navigation)
class WelcomeFooter extends StatelessWidget {
  const WelcomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Footer text
          Text(
            'A simple path to spiritual growth',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF5C6363), // --text-secondary
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16), // Reduced from 32
        ],
      ),
    );
  }
}
