import 'package:flutter/material.dart';

/// Step 1: The Noise — hooks the user by showing the problem.
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildOpeningMark(context),
              const SizedBox(height: 34),
              Text(
                'A spiritual home for the season you are in.',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.14,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Know your spiritual age, join a tribe, keep one commitment, check in daily, and share the real struggle in a way that helps you grow.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'The goal is not more content. It is a faithful rhythm of identity, belonging, commitment, reflection, and growth.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningMark(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 168,
      height: 168,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.primary.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Icon(
            Icons.eco_outlined,
            color: theme.colorScheme.primary,
            size: 42,
          ),
        ),
      ),
    );
  }
}
