import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/clarity_copy.dart';
import '../../application/journey_game_notifier.dart';
import '../widgets/game_hub_card.dart';

class GamesHubScreen extends ConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyState = ref.watch(journeyGameProvider);
    final progress = journeyState.progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = progress.overallProgress;
    final completed = progress.completedEvents.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ClarityCopy.gamesHubTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ClarityCopy.gamesHubSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 28),

              // Verse Scramble card
              GameHubCard(
                title: 'Verse Scramble',
                subtitle: 'Arrange and guess Bible verses',
                icon: LucideIcons.shuffle,
                color: const Color(0xFF5e7153),
                onTap: () => context.push('/games/verse-scramble'),
                trailing: Row(
                  children: [
                    Icon(Icons.bolt, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Quick play - 10 questions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Journey with Jesus card
              GameHubCard(
                title: 'Journey with Jesus',
                subtitle: 'Walk through the life of Christ',
                icon: LucideIcons.mapPin,
                color: const Color(0xFF3B82C4),
                onTap: () => context.push('/games/journey'),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF3B82C4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completed/30',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (progress.isComplete) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Journey Complete!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Faith Questions card
              GameHubCard(
                title: ClarityCopy.faithQuestionsTitle,
                subtitle: ClarityCopy.faithQuestionsSubtitle,
                icon: LucideIcons.helpCircle,
                color: const Color(0xFF7B68EE),
                onTap: () => context.push(AppRoutes.faithQuestions),
                trailing: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.purple.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bring honest questions to Scripture',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats section
              Text(
                'Your Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatTile(
                    icon: Icons.star,
                    color: Colors.amber,
                    label: 'Perfect',
                    value: '${progress.perfectAnswers}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                    label: 'Total Score',
                    value: '${progress.totalScore}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.bolt,
                    color: Colors.blue,
                    label: 'XP Earned',
                    value: '${progress.totalXpEarned}',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
