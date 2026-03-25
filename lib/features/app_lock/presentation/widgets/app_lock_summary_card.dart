import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../application/app_lock_state.dart';
import 'usage_progress_bar.dart';

class AppLockSummaryCard extends StatelessWidget {
  const AppLockSummaryCard({
    super.key,
    required this.state,
  });

  final AppLockState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    if (state.configs.isEmpty) {
      return _buildSetupPrompt(context, theme, tokens);
    }

    return _buildSummary(context, theme, tokens);
  }

  Widget _buildSetupPrompt(
      BuildContext context, ThemeData theme, AppThemeTokens tokens) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.appLockSetup),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          color: theme.colorScheme.surface.withValues(alpha: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SCREEN TIME',
              style: theme.textTheme.sectionHeader.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.secondary.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_clock_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Guard your time wisely',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set daily limits on distracting apps and reclaim time for what matters most.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.appLockSetup),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Set Up App Limits'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
      BuildContext context, ThemeData theme, AppThemeTokens tokens) {
    final totalUsed = state.totalUsedMinutesToday;
    final totalLimit = state.totalLimitMinutesToday;
    final overallPercentage =
        totalLimit > 0 ? (totalUsed / totalLimit).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.appLockDashboard),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCREEN TIME',
                      style: theme.textTheme.sectionHeader.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.totalMonitoredApps} apps monitored',
                      style: theme.textTheme.cardTitle,
                    ),
                  ],
                ),
                UsageProgressBar(
                  percentage: overallPercentage,
                  size: 48,
                  strokeWidth: 4,
                ),
              ],
            ),
            if (state.todayUsage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMiniStat(
                    context,
                    icon: Icons.timer_rounded,
                    label: '${totalUsed}m used',
                    color: tokens.palette.primary,
                  ),
                  const SizedBox(width: 16),
                  if (state.appsAtLimit > 0)
                    _buildMiniStat(
                      context,
                      icon: Icons.block_rounded,
                      label: '${state.appsAtLimit} at limit',
                      color: tokens.palette.error,
                    )
                  else if (state.isDoingWell)
                    _buildMiniStat(
                      context,
                      icon: Icons.check_circle_rounded,
                      label: 'On track',
                      color: tokens.palette.success,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
