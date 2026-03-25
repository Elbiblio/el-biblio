import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/alignment_notifier.dart';
import '../widgets/radar_chart.dart';
import '../widgets/profile_comparison.dart';

class SpiritualProfileScreen extends ConsumerStatefulWidget {
  const SpiritualProfileScreen({super.key});

  @override
  ConsumerState<SpiritualProfileScreen> createState() =>
      _SpiritualProfileScreenState();
}

class _SpiritualProfileScreenState
    extends ConsumerState<SpiritualProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alignmentProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;
    final state = ref.watch(alignmentProvider);
    final profile = state.currentProfile;

    return Scaffold(
      backgroundColor: tokens.palette.background,
      appBar: AppBar(
        title: const Text('Spiritual Profile'),
        backgroundColor: tokens.palette.background,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/assessment/compass'),
            icon: Icon(LucideIcons.refreshCw, size: 16, color: tokens.palette.primary),
            label: Text(
              'Re-Assess',
              style: TextStyle(
                color: tokens.palette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? _buildEmptyState(context, tokens)
              : _buildProfileContent(context, tokens, state),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.compass,
              size: 64,
              color: tokens.palette.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Discover Your Archetype',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.palette.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take the spiritual assessment to reveal your unique spiritual profile, strengths, and growth areas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.palette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push('/assessment/compass'),
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    AppThemeTokens tokens,
    AlignmentState state,
  ) {
    final profile = state.currentProfile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Archetype header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.palette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'YOUR ARCHETYPE',
                    style: Theme.of(context).textTheme.sectionHeader.copyWith(
                          color: tokens.palette.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The ${profile.archetypeName}',
                  style: Theme.of(context).textTheme.ceremonialHeading.copyWith(
                        color: tokens.palette.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.spiritualSubtitle.copyWith(
                        color: tokens.palette.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Radar chart - visual centerpiece
          Center(
            child: SpiritualRadarChart(
              dimensions: profile.dimensions,
              previousDimensions: state.previousProfiles.isNotEmpty
                  ? state.previousProfiles.first.dimensions
                  : null,
              size: 300,
              showLabels: true,
              showValues: true,
            ),
          ),
          const SizedBox(height: 24),

          // Strengths
          _SectionCard(
            icon: LucideIcons.shield,
            iconColor: tokens.palette.success,
            title: 'Your Strengths',
            children: profile.strengths.map((s) => _BulletPoint(
              text: s,
              color: tokens.palette.success,
            )).toList(),
          ),
          const SizedBox(height: 12),

          // Growth Areas (weaknesses reframed)
          _SectionCard(
            icon: LucideIcons.sprout,
            iconColor: const Color(0xFFA97A46),
            title: 'Growth Areas',
            children: profile.weaknesses.map((w) => _BulletPoint(
              text: w,
              color: const Color(0xFFA97A46),
            )).toList(),
          ),
          const SizedBox(height: 12),

          // Actionable suggestions
          _SectionCard(
            icon: LucideIcons.lightbulb,
            iconColor: tokens.palette.primary,
            title: 'Personalized Recommendations',
            children: profile.growthAreas.map((g) => _BulletPoint(
              text: g,
              color: tokens.palette.primary,
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Historical comparison
          if (state.previousProfiles.isNotEmpty) ...[
            Text(
              'GROWTH TRACKING',
              style: Theme.of(context).textTheme.sectionHeader.copyWith(
                    color: tokens.palette.textTertiary,
                  ),
            ),
            const SizedBox(height: 12),
            ProfileComparison(
              current: profile,
              previous: state.previousProfiles.first,
            ),
            const SizedBox(height: 24),
          ],

          // Profile insights
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tokens.pageGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, color: tokens.palette.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Profile Insights',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: tokens.palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your ${profile.archetypeName} archetype suggests a calling rooted in ${profile.strengths.isNotEmpty ? profile.strengths.first.toLowerCase() : "unique spiritual gifts"}. '
                  'Focus on developing your growth areas while leaning into your natural strengths.',
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.palette.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Assessed: ${_formatDate(profile.assessedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.palette.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: tokens.palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: tokens.palette.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
