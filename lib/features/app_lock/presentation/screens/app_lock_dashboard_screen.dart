import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../domain/models/app_category.dart';
import '../../domain/models/app_usage_record.dart';
import '../widgets/usage_progress_bar.dart';
import '../widgets/time_saved_counter.dart';

/// Whether the Android usage stats permission is granted.
/// Only meaningful on Android; always false on other platforms.
final _usagePermissionProvider = FutureProvider.autoDispose<bool>((ref) async {
  if (!Platform.isAndroid) return true; // non-Android doesn't need this
  return ref.watch(appUsageServiceProvider).hasPermission();
});

class AppLockDashboardScreen extends ConsumerWidget {
  const AppLockDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appLockProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // App bar
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => context.pop(),
                      ),
                      title: Text(
                        'Screen Time',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () => context.push(AppRoutes.appLockSetup),
                        ),
                      ],
                    ),

                    // Time saved counter
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: TimeSavedCounter(
                          minutesSaved: state.totalTimeSavedMinutes,
                          streakDays: state.goalStreakDays,
                        ),
                      ),
                    ),

                    // Usage stats permission banner (Android only)
                    if (Platform.isAndroid)
                      SliverToBoxAdapter(
                        child: _buildPermissionBanner(context, ref, theme, tokens),
                      ),

                    // Motivational message
                    if (state.isDoingWell && state.todayUsage.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: _buildMotivationalBanner(theme, tokens),
                        ),
                      ),

                    // Warning for approaching limits
                    if (state.appsApproachingLimit > 0)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: _buildWarningBanner(
                              theme, tokens, state.appsApproachingLimit),
                        ),
                      ),

                    // Section header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'APP USAGE TODAY',
                              style: theme.textTheme.sectionHeader.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '${state.totalMonitoredApps} apps',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: tokens.palette.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // App usage list
                    if (state.todayUsage.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: _buildEmptyState(context, theme, tokens),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = state.todayUsage[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 0, 24, 12),
                              child: _buildAppUsageCard(
                                context,
                                ref,
                                theme,
                                tokens,
                                record,
                              ),
                            );
                          },
                          childCount: state.todayUsage.length,
                        ),
                      ),

                    // Bottom spacing for nav bar
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppThemeTokens tokens,
  ) {
    final permissionAsync = ref.watch(_usagePermissionProvider);
    return permissionAsync.when(
      data: (hasPermission) {
        if (hasPermission) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Usage access permission required',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'To track real app usage, El-Biblio needs access to usage statistics. '
                  'Tap below to open settings and enable it for El-Biblio.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Primary: open the Android Usage Access settings page
                      // directly via the standard Settings action intent URI.
                      final usageSettingsUri = Uri.parse(
                        'intent:#Intent;action=android.settings.USAGE_ACCESS_SETTINGS;end',
                      );
                      try {
                        final launched = await launchUrl(
                          usageSettingsUri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched) {
                          // Fallback: open this app's own Android settings page.
                          // 'app-settings:' is iOS-only, so use permission_handler.
                          await openAppSettings();
                        }
                      } catch (_) {
                        await openAppSettings();
                      }
                    },
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Open Usage Settings'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMotivationalBanner(ThemeData theme, AppThemeTokens tokens) {
    const messages = [
      'Well done! You are using your time wisely today.',
      'Great self-discipline! Keep glorifying God with your time.',
      'You are making room for what truly matters.',
    ];
    final message = messages[DateTime.now().hour % messages.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: tokens.palette.success.withValues(alpha: 0.1),
        border:
            Border.all(color: tokens.palette.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              size: 20, color: tokens.palette.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.palette.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(
      ThemeData theme, AppThemeTokens tokens, int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFE8A838).withValues(alpha: 0.1),
        border: Border.all(
            color: const Color(0xFFE8A838).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: Color(0xFFE8A838)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count app${count == 1 ? '' : 's'} approaching daily limit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE8A838),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppThemeTokens tokens,
    AppUsageRecord record,
  ) {
    final config = ref.read(appLockProvider).configs.firstWhere(
          (c) => c.packageName == record.packageName,
          orElse: () => throw StateError('Config not found'),
        );
    final category = AppCategory.fromId(config.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: tokens.palette.border),
      ),
      child: Row(
        children: [
          // App icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: category.color.withValues(alpha: 0.15),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.appName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${record.usedMinutesToday}m / ${record.dailyLimitMinutes}m',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.palette.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearUsageBar(percentage: record.usagePercentage),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.isLimitReached
                          ? 'Limit reached'
                          : '${record.remainingMinutes}m remaining',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: record.isLimitReached
                            ? tokens.palette.error
                            : tokens.palette.textTertiary,
                        fontWeight: record.isLimitReached
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    // Toggle switch
                    SizedBox(
                      height: 20,
                      child: Switch(
                        value: config.isEnabled,
                        onChanged: (_) =>
                            ref.read(appLockProvider.notifier).toggleConfig(config.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ThemeData theme, AppThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shield_rounded,
            size: 48,
            color: tokens.palette.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No apps being monitored',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add apps to start tracking and managing your screen time.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.appLockSetup),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Apps'),
          ),
        ],
      ),
    );
  }

}
