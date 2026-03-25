import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';

class MotivationalOverlay extends StatelessWidget {
  const MotivationalOverlay({
    super.key,
    required this.appName,
    required this.usedMinutes,
    required this.onDismiss,
    required this.onExtend,
    required this.canExtend,
    required this.extensionsRemaining,
    required this.streakDays,
  });

  final String appName;
  final int usedMinutes;
  final VoidCallback onDismiss;
  final VoidCallback onExtend;
  final bool canExtend;
  final int extensionsRemaining;
  final int streakDays;

  static const List<Map<String, String>> _verses = [
    {
      'verse':
          'Be very careful, then, how you live - not as unwise but as wise, making the most of every opportunity.',
      'reference': 'Ephesians 5:15-16',
    },
    {
      'verse':
          'For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.',
      'reference': '2 Timothy 1:7',
    },
    {
      'verse':
          'No discipline seems pleasant at the time, but painful. Later on, however, it produces a harvest of righteousness and peace.',
      'reference': 'Hebrews 12:11',
    },
    {
      'verse':
          'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.',
      'reference': 'Galatians 5:22-23',
    },
    {
      'verse':
          'I can do all this through him who gives me strength.',
      'reference': 'Philippians 4:13',
    },
    {
      'verse':
          'Do you not know that your bodies are temples of the Holy Spirit? Therefore honor God with your bodies.',
      'reference': '1 Corinthians 6:19-20',
    },
    {
      'verse':
          'Set your minds on things above, not on earthly things.',
      'reference': 'Colossians 3:2',
    },
    {
      'verse':
          'Be still, and know that I am God.',
      'reference': 'Psalm 46:10',
    },
  ];

  static const List<Map<String, dynamic>> _suggestions = [
    {'icon': Icons.menu_book_rounded, 'text': 'Read a chapter of the Bible'},
    {'icon': Icons.self_improvement_rounded, 'text': 'Spend 5 minutes in prayer'},
    {'icon': Icons.nature_rounded, 'text': 'Take a walk outside'},
    {'icon': Icons.edit_note_rounded, 'text': 'Write in your journal'},
    {'icon': Icons.favorite_rounded, 'text': 'Call someone you love'},
    {'icon': Icons.spa_rounded, 'text': 'Practice deep breathing'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final random = Random();
    final verse = _verses[random.nextInt(_verses.length)];
    final suggestions = List.of(_suggestions)..shuffle(random);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tokens.palette.primaryDark.withValues(alpha: 0.95),
              tokens.palette.primary.withValues(alpha: 0.92),
              tokens.palette.primaryLight.withValues(alpha: 0.90),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Lock icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Time\'s Up for $appName',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ve used ${usedMinutes}m today',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 32),

                // Bible verse
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        verse['verse']!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '- ${verse['reference']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Suggestions
                Text(
                  'Instead, you could...',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...suggestions.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            s['icon'] as IconData,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s['text'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    )),

                if (streakDays > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$streakDays day streak - keep it going!',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // Actions
                if (canExtend)
                  TextButton(
                    onPressed: onExtend,
                    child: Text(
                      'Extend by 5 minutes ($extensionsRemaining left today)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: tokens.palette.primaryDark,
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Take a Break'),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
