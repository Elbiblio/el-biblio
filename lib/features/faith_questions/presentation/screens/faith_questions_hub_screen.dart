import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../application/faith_questions_notifier.dart';
import '../../../companion/application/companion_notifier.dart';
import '../../../companion/domain/models/companion_character.dart';
import '../../../games/presentation/widgets/game_hub_card.dart';

String _entryLineFor(CompanionCharacter c) => switch (c) {
      CompanionCharacter.raziel => 'I\'d rather sit with a real question',
      CompanionCharacter.naomi => 'Doubt is not the enemy of faith',
      CompanionCharacter.james => 'We work through it, not around it',
    };

class FaithQuestionsHubScreen extends ConsumerWidget {
  const FaithQuestionsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faithQuestionsProvider);
    final progress = state.progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completedCount = progress.completedLevels.length;
    final accuracyPct = (progress.accuracy * 100).toStringAsFixed(0);

    return AmbientScope(
      asset: SoundService.ambientReflectionAsset,
      volume: 0.06,
      child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faith Questions',
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
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  'Explore, learn, and test your knowledge',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Ask the companion — hard-questions mode. Only shown once a
              // companion has been selected; routes into a dedicated chat
              // thread whose backend prompt mode is tuned for doubt, honest
              // questions, and nuance over platitudes.
              Consumer(builder: (context, ref, _) {
                final character = ref.watch(
                  companionProvider.select((s) => s.activeCharacter),
                );
                if (character == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GameHubCard(
                    title: 'Ask ${character.displayName}',
                    subtitle:
                        'Bring your hard questions — nuance over platitudes',
                    icon: LucideIcons.messageCircle,
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      ref.read(soundServiceProvider).playTap();
                      final uri =
                          '${AppRoutes.companionChat}?thread=hard-questions&mode=hard_questions&title=${Uri.encodeQueryComponent('Hard questions')}';
                      context.push(uri);
                    },
                    trailing: Text(
                      _entryLineFor(character),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                );
              }),

              // Explore Questions card
              GameHubCard(
                title: 'Explore Questions',
                subtitle: 'Search tough questions Christians ask',
                icon: LucideIcons.helpCircle,
                color: const Color(0xFF6366F1),
                onTap: () {
                  ref.read(soundServiceProvider).playTap();
                  context.push('/faith-questions/faq');
                },
                trailing: Row(
                  children: [
                    const Icon(LucideIcons.search,
                        size: 14, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Text(
                      '30 questions across 6 categories',
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

              // Faith Quiz card
              GameHubCard(
                title: 'Faith Quiz',
                subtitle: '10-level progressive knowledge challenge',
                icon: LucideIcons.trophy,
                color: const Color(0xFFD97706),
                onTap: () {
                  ref.read(soundServiceProvider).playTap();
                  context.push('/faith-questions/quiz');
                },
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: completedCount / 10.0,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFD97706)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completedCount/10',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (completedCount >= 10) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'All Levels Complete!',
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
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: 'Answered',
                    value: '${progress.totalQuestionsAnswered}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    icon: Icons.gps_fixed,
                    color: Colors.orange,
                    label: 'Accuracy',
                    value: '$accuracyPct%',
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
