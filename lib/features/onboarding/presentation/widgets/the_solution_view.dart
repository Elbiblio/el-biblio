import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/light_rays_reveal.dart';

/// Step 2: The Solution — merges clarity promise and four pillars into one view.
class TheSolutionView extends StatefulWidget {
  const TheSolutionView({super.key});

  @override
  State<TheSolutionView> createState() => _TheSolutionViewState();
}

class _TheSolutionViewState extends State<TheSolutionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _headerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final palette = AppColorPaletteExtension.of(context).palette;

    final pillars = [
      _PillarData(
        icon: Icons.explore_outlined,
        title: 'Spiritual compass',
        subtitle: 'Name the season you are beginning from.',
        color: palette.identityColor,
        interval: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
      ),
      _PillarData(
        icon: Icons.groups_outlined,
        title: 'Tribe belonging',
        subtitle: 'Join a circle shaped by your growth path.',
        color: palette.commitmentColor,
        interval: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
      _PillarData(
        icon: Icons.flag_outlined,
        title: 'One commitment',
        subtitle: 'Keep a concrete daily action for a time-bound season.',
        color: palette.growthColor,
        interval: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
      _PillarData(
        icon: Icons.chat_bubble_outline,
        title: 'Shared reflection',
        subtitle: 'Post one honest reflection with people on the same path.',
        color: palette.primary,
        interval: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Header section from clarity promise
          FadeTransition(
            opacity: _headerFade,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.light_mode_outlined,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                LightRaysReveal(
                  delay: const Duration(milliseconds: 200),
                  maxOpacity: 0.42,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'There is a quieter\nway to grow.',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                LightRaysReveal(
                  delay: const Duration(milliseconds: 900),
                  maxOpacity: 0.3,
                  rayCount: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Identity leads to belonging. Belonging supports commitment. Commitment creates reflection. Reflection deepens growth.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Four pillars with sequential reveal
          ...pillars.map((pillar) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = pillar.interval.transform(_controller.value);
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildPillarCard(context, pillar),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPillarCard(BuildContext context, _PillarData pillar) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pillar.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pillar.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pillar.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(pillar.icon, color: pillar.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pillar.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pillar.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pillar.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarData {
  const _PillarData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.interval,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Interval interval;
}
