import 'package:flutter/material.dart';

/// Step 1: a clean first impression that frames the daily rhythm.
class TheNoiseView extends StatefulWidget {
  const TheNoiseView({super.key});

  @override
  State<TheNoiseView> createState() => _TheNoiseViewState();
}

class _TheNoiseViewState extends State<TheNoiseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 720;
        final verticalPadding = compact ? 18.0 : 28.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, verticalPadding, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - verticalPadding - 24,
            ),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandLockup(),
                    SizedBox(height: compact ? 28 : 40),
                    _RhythmHero(height: compact ? 166 : 202),
                    SizedBox(height: compact ? 26 : 34),
                    Text(
                      'Build one daily spiritual practice.',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Compass. Commitment. Tribe.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.68,
                        ),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: compact ? 20 : 28),
                    const _OutcomeStrip(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/penheart.png',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elbiblio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Daily spiritual practice',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RhythmHero extends StatelessWidget {
  const _RhythmHero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RhythmPathPainter(
                  color: primary.withValues(alpha: 0.58),
                  quietColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              bottom: 26,
              child: _SignalNode(icon: Icons.explore_outlined, color: primary),
            ),
            Positioned(
              right: 32,
              top: 28,
              child: _SignalNode(
                icon: Icons.groups_2_outlined,
                color: theme.colorScheme.secondary,
              ),
            ),
            Positioned(
              right: 42,
              bottom: 28,
              child: _SignalNode(
                icon: Icons.flag_outlined,
                color: theme.colorScheme.tertiary,
              ),
            ),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha: 0.18),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Image.asset('assets/images/penheart.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalNode extends StatelessWidget {
  const _SignalNode({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

class _OutcomeStrip extends StatelessWidget {
  const _OutcomeStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _OutcomeTile(icon: Icons.explore_outlined, label: 'Compass'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _OutcomeTile(icon: Icons.flag_outlined, label: 'Commit'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _OutcomeTile(icon: Icons.groups_2_outlined, label: 'Tribe'),
        ),
      ],
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RhythmPathPainter extends CustomPainter {
  const _RhythmPathPainter({required this.color, required this.quietColor});

  final Color color;
  final Color quietColor;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.56;
    final path = Path()
      ..moveTo(size.width * 0.1, baseline)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.2,
        size.width * 0.48,
        size.height * 0.86,
        size.width * 0.66,
        baseline,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.42,
        size.width * 0.84,
        size.height * 0.32,
        size.width * 0.92,
        size.height * 0.38,
      );

    final quietPaint = Paint()
      ..color = quietColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, quietPaint);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    final nodePaint = Paint()..color = color;
    for (final offset in [
      Offset(size.width * 0.1, baseline),
      Offset(size.width * 0.66, baseline),
      Offset(size.width * 0.92, size.height * 0.38),
    ]) {
      canvas.drawCircle(offset, 4.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPathPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.quietColor != quietColor;
  }
}
