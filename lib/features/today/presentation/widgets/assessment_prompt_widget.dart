import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_theme_tokens.dart';

/// Minimal "Discover Calling" prompt — a compact, single-tap card.
///
/// Shown once on the Today screen when the user hasn't taken the full
/// calling assessment. Tapping opens the assessment; after that it never
/// appears again. Can also be accessed from the Alignment hub.
class AssessmentPromptWidget extends ConsumerStatefulWidget {
  const AssessmentPromptWidget({super.key});

  @override
  ConsumerState<AssessmentPromptWidget> createState() =>
      _AssessmentPromptWidgetState();
}

class _AssessmentPromptWidgetState
    extends ConsumerState<AssessmentPromptWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.fadeCurve,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = theme.tokens;
    final identityColor = tokens.palette.identityColor;

    return SlideTransition(
      position: _slideIn,
      child: FadeTransition(
        opacity: _fadeIn,
        child: GestureDetector(
          onTap: () => _startAssessment(context, ref),
          child: Container(
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  identityColor.withValues(alpha: 0.1),
                  identityColor.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: identityColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: identityColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: identityColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Calling',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tailor your daily rhythm and growth path',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: identityColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startAssessment(BuildContext context, WidgetRef ref) async {
    HapticService.selection();
    // Mark as seen so it never shows again on the Today screen
    await ref.read(settingsProvider.notifier).markAssessmentPromptSeen();
    if (context.mounted) {
      context.push(AppRoutes.assessment);
    }
  }
}
