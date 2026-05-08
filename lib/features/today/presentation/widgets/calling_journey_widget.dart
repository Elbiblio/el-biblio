import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/daily_anchors.dart';

/// Calling Journey Widget - A narrative-driven widget that shows where the user
/// is in their purpose discovery journey, connecting daily actions to their calling.
/// 
/// States:
/// - Discovery Phase: No archetype/assessment complete
/// - Alignment Phase: Has archetype, daily anchors not started
/// - Action Phase: Active commitment or mission in progress
/// - Growth Phase: Daily anchors complete, showing reflection
class CallingJourneyWidget extends ConsumerWidget {
  const CallingJourneyWidget({
    super.key,
    required this.anchors,
    this.onActionTap,
  });

  final DailyAnchors anchors;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final gcState = ref.watch(graduatedCommitmentProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    final archetypeName = settings.primaryArchetypeId;
    final hasArchetype = archetypeName != null && archetypeName.isNotEmpty;

    // Determine journey state
    final completedCount = _completedCount(anchors);
    final state = _determineState(
      hasArchetype: hasArchetype,
      completedCount: completedCount,
      hasActiveCommitment: gcState.activeCommitment != null,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(tokens.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surface.withValues(alpha: 0.5),
                  theme.colorScheme.surface.withValues(alpha: 0.2),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStateContent(state, context, ref, settings, anchors, theme, tokens),
          if (onActionTap != null) ...[
            SizedBox(height: tokens.spacingMd),
            _buildActionButton(state, context, theme, tokens, onActionTap),
          ],
        ],
      ),
    );
  }

  Widget _buildStateContent(
    CallingJourneyState state,
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    DailyAnchors anchors,
    ThemeData theme,
    AppThemeTokens tokens,
  ) {
    switch (state) {
      case CallingJourneyState.discovery:
        return _DiscoveryContent(theme: theme, tokens: tokens);
      case CallingJourneyState.alignment:
        return _AlignmentContent(
          archetypeName: settings.primaryArchetypeId,
          theme: theme,
          tokens: tokens,
        );
      case CallingJourneyState.action:
        return _ActionContent(
          anchors: anchors,
          activeCommitment: ref.watch(graduatedCommitmentProvider).activeCommitment,
          theme: theme,
          tokens: tokens,
        );
      case CallingJourneyState.growth:
        return _GrowthContent(
          anchors: anchors,
          theme: theme,
          tokens: tokens,
        );
    }
  }

  Widget _buildActionButton(
    CallingJourneyState state,
    BuildContext context,
    ThemeData theme,
    AppThemeTokens tokens,
    VoidCallback? onActionTap,
  ) {
    String label;
    Color color;
    
    switch (state) {
      case CallingJourneyState.discovery:
        label = 'Start Assessment';
        color = tokens.palette.identityColor;
        break;
      case CallingJourneyState.alignment:
        label = 'Start Prayer';
        color = theme.colorScheme.primary;
        break;
      case CallingJourneyState.action:
        label = 'Continue';
        color = theme.colorScheme.primary;
        break;
      case CallingJourneyState.growth:
        label = 'Reflect';
        color = tokens.palette.growthColor;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onActionTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMedium),
          ),
          elevation: 2,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  int _completedCount(DailyAnchors anchors) {
    int count = 0;
    if (anchors.coreVirtue.isCompleted) count++;
    if (anchors.habit.isCompleted) count++;
    if (anchors.energyAction.isCompleted) count++;
    return count;
  }

  CallingJourneyState _determineState({
    required bool hasArchetype,
    required int completedCount,
    required bool hasActiveCommitment,
  }) {
    if (!hasArchetype) return CallingJourneyState.discovery;
    if (hasActiveCommitment) return CallingJourneyState.action;
    if (completedCount == 3) return CallingJourneyState.growth;
    return CallingJourneyState.alignment;
  }
}

enum CallingJourneyState {
  discovery,
  alignment,
  action,
  growth,
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({required this.theme, required this.tokens});

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.palette.identityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_rounded,
                color: tokens.palette.identityColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover your calling pattern',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your calling has a pattern.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'A short assessment reveals how God wired you for purpose.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AlignmentContent extends StatelessWidget {
  const _AlignmentContent({
    required this.archetypeName,
    required this.theme,
    required this.tokens,
  });

  final String? archetypeName;
  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live into your ${archetypeName ?? ''} calling',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your journey begins',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Your $archetypeName calling becomes real through daily practice.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ActionContent extends StatelessWidget {
  const _ActionContent({
    required this.anchors,
    required this.activeCommitment,
    required this.theme,
    required this.tokens,
  });

  final DailyAnchors anchors;
  final dynamic activeCommitment;
  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.palette.growthColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_rounded,
                color: tokens.palette.growthColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your calling in action',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeCommitment?.title ?? 'Building character',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'This commitment builds your character.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GrowthContent extends StatelessWidget {
  const _GrowthContent({
    required this.anchors,
    required this.theme,
    required this.tokens,
  });

  final DailyAnchors anchors;
  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.palette.growthColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: tokens.palette.growthColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reflect on your journey',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily anchors complete',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Growth happens in reflection. How is God speaking?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
