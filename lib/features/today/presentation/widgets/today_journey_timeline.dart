import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_tokens.dart';

/// Visual timeline showing the three phases of the daily spiritual journey.
/// 
/// Displays: Morning (sun) → Midday (compass) → Evening (moon)
/// with clear visual indication of completed, current, and upcoming phases.
class TodayJourneyTimeline extends StatelessWidget {
  const TodayJourneyTimeline({
    super.key,
    required this.completedPhases,
    required this.currentPhase,
    this.onPhaseTap,
  });

  /// Number of completed phases (0-3)
  final int completedPhases;

  /// Current active phase index (0 = morning, 1 = midday, 2 = evening, -1 if all done)
  final int currentPhase;

  /// Called when user taps on a phase circle. Only fires for incomplete phases.
  final void Function(int phaseIndex)? onPhaseTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surface.withValues(alpha: 0.5)
            : tokens.palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Journey",
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPhaseIndicator(
                context,
                index: 0,
                icon: Icons.wb_sunny_outlined,
                label: 'Morning',
                subtitle: 'Connect',
                tokens: tokens,
              ),
              _buildConnector(context, 0, tokens),
              _buildPhaseIndicator(
                context,
                index: 1,
                icon: Icons.explore_outlined,
                label: 'Midday',
                subtitle: 'Practice',
                tokens: tokens,
              ),
              _buildConnector(context, 1, tokens),
              _buildPhaseIndicator(
                context,
                index: 2,
                icon: Icons.nightlight_outlined,
                label: 'Evening',
                subtitle: 'Reflect',
                tokens: tokens,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
    required AppThemeTokens tokens,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final isCompleted = index < completedPhases;
    final isCurrent = index == currentPhase;
    final isUpcoming = index > currentPhase && currentPhase >= 0;
    
    Color iconColor;
    Color bgColor;
    Color borderColor;
    
    if (isCompleted) {
      iconColor = tokens.palette.success;
      bgColor = tokens.palette.success.withValues(alpha: isDark ? 0.15 : 0.1);
      borderColor = tokens.palette.success.withValues(alpha: 0.4);
    } else if (isCurrent) {
      iconColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1);
      borderColor = theme.colorScheme.primary;
    } else {
      iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
      bgColor = isDark 
          ? theme.colorScheme.surface.withValues(alpha: 0.3)
          : tokens.palette.paper.withValues(alpha: 0.5);
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    }

    final isTappable = !isCompleted && isCurrent && onPhaseTap != null;

    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: isTappable ? () => onPhaseTap!(index) : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        color: iconColor,
                        size: 24,
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                        size: 22,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: isUpcoming ? 0.4 : 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, int index, AppThemeTokens tokens) {
    final theme = Theme.of(context);
    final isCompleted = index < completedPhases;
    
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: isCompleted
            ? tokens.palette.success.withValues(alpha: 0.5)
            : theme.colorScheme.outline.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
