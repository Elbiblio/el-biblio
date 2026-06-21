import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../data/soul_care_catalog.dart';
import '../../domain/models/soul_care_session.dart';

/// Phases of the soul care session.
enum _Phase { intro, breathing, scripture, prayer, complete }

/// A guided 2-3 minute soul care reset session screen.
///
/// Walks the user through: intro -> breathing -> scripture -> prayer -> done.
class SoulCareResetScreen extends ConsumerStatefulWidget {
  const SoulCareResetScreen({super.key, this.session});

  /// If null, a random session is chosen.
  final SoulCareSession? session;

  @override
  ConsumerState<SoulCareResetScreen> createState() => _SoulCareResetScreenState();
}

class _SoulCareResetScreenState extends ConsumerState<SoulCareResetScreen>
    with TickerProviderStateMixin {
  late SoulCareSession _session;
  _Phase _phase = _Phase.intro;
  Timer? _timer;
  int _breathCycle = 0;
  String _breathLabel = 'Breathe In';
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? SoulCareCatalog.random;
    _breathController = AnimationController(vsync: this);
    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Auto-advance from intro after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _phase == _Phase.intro) {
        _startBreathing();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() => _phase = _Phase.breathing);
    _breathCycle = 0;
    _runBreathCycle();
  }

  void _runBreathCycle() {
    final b = _session.breathComponents;
    final totalCycleSeconds = b.inhale + b.hold + b.exhale;
    // Calculate how many breath cycles fit in ~60% of the session
    final breathDuration = (_session.durationSeconds * 0.55).round();
    final maxCycles = (breathDuration / totalCycleSeconds).floor().clamp(3, 8);

    if (_breathCycle >= maxCycles) {
      _moveToScripture();
      return;
    }

    // Inhale
    setState(() => _breathLabel = 'Breathe In');
    _breathController.duration = Duration(seconds: b.inhale);
    _breathController.forward(from: 0.0);

    _timer = Timer(Duration(seconds: b.inhale), () {
      if (!mounted) return;
      // Hold
      setState(() => _breathLabel = 'Hold');
      _timer = Timer(Duration(seconds: b.hold), () {
        if (!mounted) return;
        // Exhale
        setState(() => _breathLabel = 'Breathe Out');
        _breathController.duration = Duration(seconds: b.exhale);
        _breathController.reverse();

        _timer = Timer(Duration(seconds: b.exhale), () {
          if (!mounted) return;
          _breathCycle++;
          _runBreathCycle();
        });
      });
    });
  }

  void _moveToScripture() {
    setState(() => _phase = _Phase.scripture);
    // Show scripture for ~30% of duration
    final scriptureDuration =
        (_session.durationSeconds * 0.3).round().clamp(15, 40);
    _timer = Timer(Duration(seconds: scriptureDuration), () {
      if (mounted) _moveToPrayer();
    });
  }

  void _moveToPrayer() {
    setState(() => _phase = _Phase.prayer);
    // Show prayer for remaining time, then complete
    _timer = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.complete);
      ref.read(soundServiceProvider).playChimeGentle();
    });
  }

  void _skip() {
    _timer?.cancel();
    switch (_phase) {
      case _Phase.intro:
        _startBreathing();
      case _Phase.breathing:
        _moveToScripture();
      case _Phase.scripture:
        _moveToPrayer();
      case _Phase.prayer:
        setState(() => _phase = _Phase.complete);
      case _Phase.complete:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return AmbientScope(
      asset: SoundService.ambientSoulCareAsset,
      volume: 0.09,
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFF5F0EB),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    _session.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _phase == _Phase.complete ? null : _skip,
                    child: Text(
                      _phase == _Phase.complete ? '' : 'Skip',
                      style: TextStyle(
                        color: primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildPhaseContent(theme, primary, isDark),
              ),
            ),

            // Bottom action
            if (_phase == _Phase.complete)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Done'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPhaseContent(ThemeData theme, Color primary, bool isDark) {
    switch (_phase) {
      case _Phase.intro:
        return _IntroContent(
          key: const ValueKey('intro'),
          session: _session,
          theme: theme,
          primary: primary,
        );
      case _Phase.breathing:
        return _BreathingContent(
          key: const ValueKey('breathing'),
          label: _breathLabel,
          animation: _breathAnimation,
          theme: theme,
          primary: primary,
          isDark: isDark,
        );
      case _Phase.scripture:
        return _ScriptureContent(
          key: const ValueKey('scripture'),
          session: _session,
          theme: theme,
          primary: primary,
        );
      case _Phase.prayer:
        return _PrayerContent(
          key: const ValueKey('prayer'),
          session: _session,
          theme: theme,
          primary: primary,
        );
      case _Phase.complete:
        return _CompleteContent(
          key: const ValueKey('complete'),
          theme: theme,
          primary: primary,
        );
    }
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent({
    super.key,
    required this.session,
    required this.theme,
    required this.primary,
  });

  final SoulCareSession session;
  final ThemeData theme;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.spa_rounded, color: primary, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              session.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (session.description != null) ...[
              const SizedBox(height: 8),
              Text(
                session.description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              session.durationLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingContent extends StatelessWidget {
  const _BreathingContent({
    super.key,
    required this.label,
    required this.animation,
    required this.theme,
    required this.primary,
    required this.isDark,
  });

  final String label;
  final Animation<double> animation;
  final ThemeData theme;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Container(
                width: 160 * animation.value,
                height: 160 * animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.3),
                      primary.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 60 * animation.value,
                    height: 60 * animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              label,
              key: ValueKey(label),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScriptureContent extends StatelessWidget {
  const _ScriptureContent({
    super.key,
    required this.session,
    required this.theme,
    required this.primary,
  });

  final SoulCareSession session;
  final ThemeData theme;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: primary, size: 32),
            const SizedBox(height: 24),
            Text(
              session.scriptureText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.7,
                fontSize: 17,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              session.scriptureReference,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerContent extends StatelessWidget {
  const _PrayerContent({
    super.key,
    required this.session,
    required this.theme,
    required this.primary,
  });

  final SoulCareSession session;
  final ThemeData theme;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism_rounded, color: primary, size: 32),
            const SizedBox(height: 24),
            Text(
              session.closingPrayer,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteContent extends StatelessWidget {
  const _CompleteContent({
    super.key,
    required this.theme,
    required this.primary,
  });

  final ThemeData theme;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, theme.colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'You did it.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Carry this peace with you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
