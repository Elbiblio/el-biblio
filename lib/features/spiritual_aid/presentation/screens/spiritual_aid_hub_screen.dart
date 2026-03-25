import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../widgets/spiritual_aid_hub_card.dart';

class SpiritualAidHubScreen extends ConsumerWidget {
  const SpiritualAidHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.shade200.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Icon(
                              Icons.medical_services_rounded,
                              color: Colors.red.shade400,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Spiritual\nFirst Aid Kit',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Immediate spiritual care for your soul. '
                        'Choose what you need right now.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Hub cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SpiritualAidHubCard(
                      icon: Icons.church_rounded,
                      title: 'Quick Prayers',
                      description: 'Pre-written prayers for every moment. '
                          'Read, listen, or pray along word by word.',
                      gradient: const [Color(0xFF4B82C3), Color(0xFF6BA3E0)],
                      badge: '40+ prayers',
                      onTap: () => context.push('${AppRoutes.spiritualAid}/prayers'),
                    ),
                    const SizedBox(height: 16),

                    SpiritualAidHubCard(
                      icon: Icons.forum_rounded,
                      title: 'Faith Discuss',
                      description: 'Daily prompts to deepen your faith. '
                          'Reflect, journal, and share.',
                      gradient: const [Color(0xFF5A8E67), Color(0xFF7BB58B)],
                      badge: 'Daily prompt',
                      onTap: () => context.push('${AppRoutes.spiritualAid}/discuss'),
                    ),
                    const SizedBox(height: 16),

                    SpiritualAidHubCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Speak to Me',
                      description: 'Let God speak through His Word. '
                          'Tap to receive a verse just for this moment.',
                      gradient: const [Color(0xFF7B3D9E), Color(0xFFA064C4)],
                      onTap: () => context.push('${AppRoutes.spiritualAid}/speak'),
                    ),
                    const SizedBox(height: 16),

                    SpiritualAidHubCard(
                      icon: Icons.share_rounded,
                      title: 'Evangelism Helper',
                      description: 'Beautiful content to share your faith. '
                          'Verse cards, guides, and conversation starters.',
                      gradient: const [Color(0xFFA97A46), Color(0xFFC49762)],
                      badge: '30+ resources',
                      onTap: () => context.push('${AppRoutes.spiritualAid}/evangelism'),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
