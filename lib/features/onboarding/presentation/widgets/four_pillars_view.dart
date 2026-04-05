import 'package:flutter/material.dart';

/// Step 5: The Four Pillars — animated sequential reveal of Elbiblio's 4 pillars.
class FourPillarsView extends StatefulWidget {
  const FourPillarsView({super.key});

  @override
  State<FourPillarsView> createState() => _FourPillarsViewState();
}

class _FourPillarsViewState extends State<FourPillarsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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

    final pillars = [
      const _PillarData(
        icon: Icons.person_search_outlined,
        title: 'Spiritual Career Alignment',
        subtitle: 'Know your God-given identity and align your life\'s work with it.',
        color: Color(0xFF7B68EE),
        interval: Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
      const _PillarData(
        icon: Icons.trending_up_rounded,
        title: 'Spiritual Growth',
        subtitle: 'Daily commitments tailored to your strengths, weaknesses, and temptations.',
        color: Color(0xFF4CAF50),
        interval: Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
      const _PillarData(
        icon: Icons.shield_outlined,
        title: 'Distraction Blocking',
        subtitle: 'Guard your attention. Less noise, more clarity.',
        color: Color(0xFF2196F3),
        interval: Interval(0.30, 0.70, curve: Curves.easeOutCubic),
      ),
      const _PillarData(
        icon: Icons.auto_stories_outlined,
        title: 'Bible Games, Faith & Prayer',
        subtitle: 'Learn the Word through play. Answer tough questions. Claim sanity through prayer.',
        color: Color(0xFFFF9800),
        interval: Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Your four pillars\nof clarity.',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Each one works together to cut through the noise.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
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
                padding: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: pillar.color.withValues(alpha: 0.15),
        ),
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
