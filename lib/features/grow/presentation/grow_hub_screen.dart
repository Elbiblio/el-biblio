import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

class GrowHubScreen extends ConsumerWidget {
  const GrowHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your spiritual growth journey',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _GrowCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Four Pillars of Clarity',
                    subtitle: 'Discover your spiritual foundation',
                    color: theme.colorScheme.primary,
                    onTap: () => context.push(AppRoutes.assessment),
                  ),
                  const SizedBox(height: 16),
                  _GrowCard(
                    icon: Icons.explore_rounded,
                    title: 'Spiritual Alignment',
                    subtitle: 'Align your life with purpose',
                    color: const Color(0xFF3B82C4),
                    onTap: () => context.push(AppRoutes.alignment),
                  ),
                  const SizedBox(height: 16),
                  _GrowCard(
                    icon: Icons.flag_rounded,
                    title: 'Commitments',
                    subtitle: 'Make and keep meaningful promises',
                    color: const Color(0xFFE57C23),
                    onTap: () => context.push(AppRoutes.commitmentJourney),
                  ),
                  const SizedBox(height: 16),
                  _GrowCard(
                    icon: Icons.quiz_rounded,
                    title: 'Faith Questions',
                    subtitle: 'Explore deep questions of faith',
                    color: const Color(0xFF7B68EE),
                    onTap: () => context.push(AppRoutes.faithQuestions),
                  ),
                  const SizedBox(height: 16),
                  _GrowCard(
                    icon: Icons.calendar_month_rounded,
                    title: '40-Day Goals',
                    subtitle: 'Transform habits over 40 days',
                    color: const Color(0xFF10B981),
                    onTap: () => context.push('/alignment/forty-day-progress'),
                  ),
                  const SizedBox(height: 16),
                  _GrowCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Journal',
                    subtitle: 'Reflect and write your story',
                    color: isDark ? Colors.teal.shade300 : Colors.teal.shade600,
                    onTap: () => context.push(AppRoutes.journal),
                  ),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowCard extends StatelessWidget {
  const _GrowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.15 : 0.08),
            color.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
