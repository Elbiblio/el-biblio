import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/application/xp_notifier.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import 'widgets/tts_settings_widget.dart';
import 'widgets/achievements_dialog.dart';
import 'widgets/weekly_progress_chart.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile data when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileForCurrentUser();
    });
  }

  Widget _buildAchievementsLink({
    required BuildContext context,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    final unlockedCount = ref.watch(settingsProvider).unlockedBadges.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACHIEVEMENTS',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            title: Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              unlockedCount == 0
                  ? 'No badges unlocked yet'
                  : '$unlockedCount badges unlocked',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              AchievementsDialog.show(context);
            },
          ),
        ],
      ),
    );
  }

  void _loadProfileForCurrentUser() {
    final authState = ref.read(authProvider);
    if (authState.user != null && authState.isAuthenticated) {
      // Load current user profile using the proper /auth/me endpoint
      ref.read(profileProvider.notifier).loadCurrentUserProfile();
    }
  }

  Future<void> _showEditProfileDialog() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    final nameController = TextEditingController(
      text: authState.user!.fullName,
    );
    final emailController = TextEditingController(text: authState.user!.email);
    final phoneController = TextEditingController(
      text: authState.user!.phone ?? '',
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF142111) : Colors.white,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1a2418),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF1a2418).withValues(alpha: 0.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF1a2418).withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF638B6C)),
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1a2418),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF1a2418).withValues(alpha: 0.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF1a2418).withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF638B6C)),
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1a2418),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF1a2418).withValues(alpha: 0.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF1a2418).withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF638B6C)),
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1a2418),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF1a2418).withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();

                final nameParts = nameController.text.trim().split(' ');
                final firstName = nameParts.first;
                final lastName = nameParts.length > 1
                    ? nameParts.sublist(1).join(' ')
                    : '';

                final success = await ref
                    .read(authProvider.notifier)
                    .updateUserProfile(
                      firstName: firstName.isNotEmpty ? firstName : null,
                      lastName: lastName.isNotEmpty ? lastName : null,
                      email: emailController.text.trim().isNotEmpty
                          ? emailController.text.trim()
                          : null,
                      phone: phoneController.text.trim().isNotEmpty
                          ? phoneController.text.trim()
                          : null,
                    );

                if (success && mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                    ),
                  );
                } else if (mounted) {
                  final authState = ref.read(authProvider);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        authState.error ?? 'Failed to update profile',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF638B6C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Computes daily XP totals for the current week (Mon-Sun) from activity data.
  List<int> _computeWeeklyDailyXP(XPState xpState) {
    final now = DateTime.now();
    // Find Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStart = DateTime(monday.year, monday.month, monday.day);

    final dailyXP = List<int>.filled(7, 0);
    for (final activity in xpState.activities) {
      final daysSinceMonday = activity.timestamp.difference(mondayStart).inDays;
      if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
        dailyXP[daysSinceMonday] += activity.xpAmount;
      }
    }
    return dailyXP;
  }

  Widget _buildThisWeekSection({
    required BuildContext context,
    required XPState xpState,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color accentColor,
    required Color successColor,
    required int streakCount,
  }) {
    final theme = Theme.of(context);
    final xpNotifier = ref.read(xpProvider.notifier);
    final monthlyChange = xpNotifier.getMonthlyXPChange();
    final changePercent = (monthlyChange * 100).toInt();
    final isPositive = changePercent >= 0;
    final weeklyDailyXP = _computeWeeklyDailyXP(xpState);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: mutedTextColor,
            ),
          ),
          const SizedBox(height: 16),
          WeeklyProgressChart(dailyXP: weeklyDailyXP),
          const SizedBox(height: 20),
          // Growth stat
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 18,
                color: isPositive ? successColor : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Growth',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${isPositive ? '+' : ''}$changePercent%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isPositive ? successColor : theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'this month',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Streak row - 7 day indicators
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ...List.generate(7, (i) {
                final isActive = i < streakCount.clamp(0, 7);
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? accentColor.withValues(alpha: 0.2)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isActive
                            ? accentColor
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.12,
                              ),
                        width: 1.5,
                      ),
                    ),
                    child: isActive
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: accentColor,
                          )
                        : null,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsSection({
    required BuildContext context,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color surfaceColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK SETTINGS',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(
              'App Lock',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Manage app usage limits',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push(AppRoutes.appLockDashboard);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Version, review, and support',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push(AppRoutes.about);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedGrowthSection({
    required BuildContext context,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color surfaceColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADVANCED GROWTH',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82C4).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: Color(0xFF3B82C4),
                size: 20,
              ),
            ),
            title: Text(
              'Spiritual Alignment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Align your life with purpose',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push(AppRoutes.alignment);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE57C23).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFFE57C23),
                size: 20,
              ),
            ),
            title: Text(
              'Commitments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Make and keep meaningful promises',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push(AppRoutes.commitmentJourney);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF7B68EE).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Color(0xFF7B68EE),
                size: 20,
              ),
            ),
            title: Text(
              'Faith Questions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Bring honest questions to Scripture',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push(AppRoutes.faithQuestions);
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            title: Text(
              '40-Day Goals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Transform habits over 40 days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push('/alignment/forty-day-progress');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSettingsLink({
    required BuildContext context,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color surfaceColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY RHYTHM',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(
              'Reminder Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Configure your morning and evening reminders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push('/profile/reminders');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentLink({
    required BuildContext context,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color surfaceColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPIRITUAL ASSESSMENT',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4B925).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: Color(0xFFF4B925),
                size: 20,
              ),
            ),
            title: Text(
              'Calling Assessment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Take an assessment to discover your spiritual archetype',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push('/assessment');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDiagnoseLink({
    required BuildContext context,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color surfaceColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIME MANAGEMENT',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF7A8471).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF7A8471),
                size: 20,
              ),
            ),
            title: Text(
              'Time Audit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            subtitle: Text(
              'Analyze and optimize your 24-hour time allocation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primaryTextColor.withValues(alpha: 0.7),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
            onTap: () {
              GoRouter.of(context).push('/time-diagnose');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection({
    required BuildContext context,
    required AppThemeMode mode,
    required Brightness brightness,
    required Color borderColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required ValueChanged<AppThemeMode> onModeChanged,
    required ValueChanged<Brightness> onBrightnessChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPEARANCE',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Theme Mode',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: primaryTextColor),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment<AppThemeMode>(
                value: AppThemeMode.adaptive,
                label: Text('Adaptive'),
                icon: Icon(Icons.schedule_rounded),
              ),
              ButtonSegment<AppThemeMode>(
                value: AppThemeMode.afternoon,
                label: Text('Afternoon'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
            ],
            selected: <AppThemeMode>{mode},
            onSelectionChanged: (values) {
              if (values.isNotEmpty) {
                onModeChanged(values.first);
              }
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Brightness',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: primaryTextColor),
          ),
          const SizedBox(height: 8),
          SegmentedButton<Brightness>(
            segments: const [
              ButtonSegment<Brightness>(
                value: Brightness.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<Brightness>(
                value: Brightness.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: <Brightness>{brightness},
            onSelectionChanged: (values) {
              if (values.isNotEmpty) {
                onBrightnessChanged(values.first);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final appTheme = ref.watch(themeProvider);
    final xpState = ref.watch(xpProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final isDark = theme.brightness == Brightness.dark;

    // Listen to auth state changes and reload profile when user authenticates
    ref.listen(authProvider, (previous, next) {
      if (next.user != null &&
          next.isAuthenticated &&
          (previous?.user?.id != next.user?.id ||
              previous?.isAuthenticated != true)) {
        _loadProfileForCurrentUser();
      }
    });

    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.colorScheme.surface;
    final primaryTextColor = theme.colorScheme.onSurface;
    final mutedTextColor = tokens.palette.textSecondary;
    final borderColor = tokens.palette.border;
    final successColor = tokens.palette.success;
    final accentColor = theme.colorScheme.primary;

    if (profileState.isLoading &&
        profileState.profile == null &&
        authState.user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const SafeArea(
          child: SkeletonLoader(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonCircle(size: 64),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonText(width: 180, height: 20),
                            SizedBox(height: 8),
                            SkeletonText(width: 120, height: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  SkeletonCard(height: 96, borderRadius: 16),
                  SkeletonCard(height: 120, borderRadius: 16),
                  SkeletonCard(height: 160, borderRadius: 16),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (profileState.error != null &&
        profileState.profile == null &&
        authState.user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadProfileForCurrentUser,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Use auth user data if available, otherwise fall back to profile data
    final user = authState.user;
    final profile = profileState.profile;
    final stats = profileState.stats;

    final name = user?.fullName ?? profile?.name ?? 'Guest User';
    final role = user?.role ?? profile?.role ?? 'Disciple';
    final memberSinceYear =
        profile?.memberSince?.year ?? user?.createdAt?.year ?? 2021;

    // Use XP tracking data for points
    final points = xpState.totalXP;

    // Stats - use real data when available, otherwise use sensible defaults
    final activeHours = stats?.totalActiveTime ?? user?.totalActiveTime ?? 0;
    final meditationHours = (stats?.totalMeditationSessions ?? 0) > 0
        ? ((stats?.totalMeditationSessions ?? 0) * 15) ~/ 60
        : 0;
    final chapters = stats?.totalVersesRead ?? 0;
    final streak = stats?.currentStreak ?? profile?.currentStreak ?? 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(
                  context: context,
                  name: name,
                  role: role,
                  year: memberSinceYear,
                  primaryTextColor: primaryTextColor,
                  mutedTextColor: mutedTextColor,
                  borderColor: borderColor,
                  surfaceColor: surfaceColor,
                  isGuest: authState.isGuest,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 120,
                      ), // Space for fab and nav
                      child: Column(
                        children: [
                          // Points Section
                          _buildPointsSection(
                            context: context,
                            points: points,
                            primaryTextColor: primaryTextColor,
                            mutedTextColor: mutedTextColor,
                            borderColor: borderColor,
                            successColor: successColor,
                          ),

                          // Stats Grid
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        context: context,
                                        label: 'TIME ANCHORED',
                                        value: '${activeHours}h',
                                        unit: 'total',
                                        primaryTextColor: primaryTextColor,
                                        mutedTextColor: mutedTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildStatItem(
                                        context: context,
                                        label: 'MEDITATION',
                                        value: '${meditationHours}h',
                                        unit: 'depth',
                                        primaryTextColor: primaryTextColor,
                                        mutedTextColor: mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        context: context,
                                        label: 'SCRIPTURE',
                                        value: chapters.toString(),
                                        unit: 'Chapters',
                                        primaryTextColor: primaryTextColor,
                                        mutedTextColor: mutedTextColor,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildStatItem(
                                        context: context,
                                        label: 'CONSISTENCY',
                                        value: streak.toString(),
                                        unit: 'Day Streak',
                                        primaryTextColor: primaryTextColor,
                                        mutedTextColor: mutedTextColor,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // Quote/Description
                                Container(
                                  padding: const EdgeInsets.only(top: 24),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: borderColor),
                                    ),
                                  ),
                                  child: Text(
                                    'Read. Pray. Reflect. This record updates as you show up.',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          height: 1.6,
                                          color: isDark
                                              ? const Color(0xFF888888)
                                              : const Color(0xFF78716C),
                                          fontWeight: FontWeight.w300,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 40),
                                _buildThisWeekSection(
                                  context: context,
                                  xpState: xpState,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  accentColor: accentColor,
                                  successColor: successColor,
                                  streakCount: streak,
                                ),

                                const SizedBox(height: 40),
                                _buildQuickSettingsSection(
                                  context: context,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: surfaceColor,
                                ),

                                const SizedBox(height: 40),
                                _buildReminderSettingsLink(
                                  context: context,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: surfaceColor,
                                ),

                                const SizedBox(height: 40),
                                const TTSSettingsWidget(),

                                const SizedBox(height: 40),
                                _buildAssessmentLink(
                                  context: context,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: surfaceColor,
                                ),

                                const SizedBox(height: 40),
                                _buildTimeDiagnoseLink(
                                  context: context,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: surfaceColor,
                                ),

                                const SizedBox(height: 40),
                                _buildAdvancedGrowthSection(
                                  context: context,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  surfaceColor: surfaceColor,
                                ),

                                const SizedBox(height: 40),
                                _buildAchievementsLink(
                                  context: context,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                ),

                                const SizedBox(height: 40),
                                _buildAppearanceSection(
                                  context: context,
                                  mode: appTheme.mode,
                                  brightness: appTheme.brightness,
                                  borderColor: borderColor,
                                  primaryTextColor: primaryTextColor,
                                  mutedTextColor: mutedTextColor,
                                  onModeChanged: themeNotifier.setMode,
                                  onBrightnessChanged:
                                      themeNotifier.setBrightness,
                                ),
                                const SizedBox(height: 20),
                                if (ref
                                    .watch(settingsProvider)
                                    .onboardingCompleted)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(settingsProvider.notifier)
                                          .resetOnboarding();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Onboarding reset. Restart app to test again.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.restart_alt,
                                      size: 16,
                                    ),
                                    label: const Text('Reset Onboarding'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: surfaceColor,
                                      foregroundColor: primaryTextColor,
                                      elevation: 0,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String name,
    required String role,
    required int year,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color borderColor,
    required Color surfaceColor,
    required bool isGuest,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surfaceColor,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: mutedTextColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 0,
                child: GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF638B6C),
                      border: Border.all(color: surfaceColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Name
          Text(
            name,
            style: Theme.of(context).textTheme.profileName.copyWith(
              color: primaryTextColor,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // Role & Year
          Text(
            '$role • Since $year'.toUpperCase(),
            style: Theme.of(context).textTheme.metadata.copyWith(
              color: mutedTextColor,
              letterSpacing: 3.0,
            ),
            textAlign: TextAlign.center,
          ),

          if (isGuest) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF638B6C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF638B6C).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'GUEST ACCOUNT',
                style: Theme.of(context).textTheme.metadata.copyWith(
                  color: const Color(0xFF638B6C),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointsSection({
    required BuildContext context,
    required int points,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required Color borderColor,
    required Color successColor,
  }) {
    final xpNotifier = ref.read(xpProvider.notifier);
    final monthlyChange = xpNotifier.getMonthlyXPChange();
    final changeText = monthlyChange > 0
        ? '+${(monthlyChange * 100).toStringAsFixed(0)}%'
        : '${(monthlyChange * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Text(
            'INTEGRITY POINTS',
            style: Theme.of(
              context,
            ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
          ),
          const SizedBox(height: 16),
          Text(
            _formatNumber(points),
            style: Theme.of(
              context,
            ).textTheme.displayNumber.copyWith(color: primaryTextColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                monthlyChange > 0
                    ? Icons.north_east_rounded
                    : Icons.south_east_rounded,
                size: 14,
                color: monthlyChange > 0
                    ? const Color(0xFF047857)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 4),
              Text(
                '$changeText THIS MONTH',
                style: Theme.of(context).textTheme.metadata.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: monthlyChange > 0
                      ? successColor
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.sectionHeader.copyWith(color: mutedTextColor),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: Theme.of(
                  context,
                ).textTheme.mediumNumber.copyWith(color: primaryTextColor),
              ),
              TextSpan(
                text: unit,
                style: Theme.of(context).textTheme.mediumNumber.copyWith(
                  fontSize: 20,
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final value = number / 1000;
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}k';
    }
    return number.toString();
  }
}
