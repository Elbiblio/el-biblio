import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/di/app_providers.dart';
import '../../../core/services/analytics/app_analytics_service.dart';
import '../../../core/theme/app_theme_tokens.dart';

class CallingProfileScreen extends ConsumerStatefulWidget {
  const CallingProfileScreen({super.key});

  @override
  ConsumerState<CallingProfileScreen> createState() => _CallingProfileScreenState();
}

class _CallingProfileScreenState extends ConsumerState<CallingProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Track profile view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider).track(AppAnalyticsEvent.callingProfileViewed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final profile = settings.callingProfile;
    final weeklyPlan = settings.currentWeeklyPlan;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Calling'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.compass_calibration_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Discover Your Calling',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete the assessment to unlock your\npersonalized calling profile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.assessment),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Start Assessment'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Your Calling'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: tokens.pageGradient,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Product Spine Progress Indicator
                _ProductSpineProgress(
                  hasProfile: true,
                  hasWeeklyPlan: weeklyPlan != null,
                ),

                const SizedBox(height: 16),

                // Identity Card
                _IdentityCard(
                  archetypeIdentity: profile.archetypeIdentity,
                  archetypeId: profile.archetypeId,
                  missionFocus: profile.missionFocus,
                  commitmentCategory: profile.commitmentCategory,
                ),

                const SizedBox(height: 24),

                // Action Prompts Section
                _ActionPromptsSection(
                  serviceTendencies: profile.burdensAndServiceTendencies,
                  relationalFocus: profile.relationalFocus,
                  onActTap: () => _navigateToAct(context),
                  onReflectTap: () => _navigateToReflect(context),
                  onTogetherTap: () => _navigateToTogether(context),
                ),
                
                const SizedBox(height: 24),
                
                // Weekly Priorities
                _SectionCard(
                  title: 'Weekly Priorities',
                  icon: Icons.track_changes_rounded,
                  children: profile.weeklyPriorities.isEmpty
                      ? [
                          _EmptyStateMessage(
                            message: 'Set your weekly priorities to align your days with your calling.',
                            actionLabel: 'Set Priorities',
                            onAction: () => _showSetPrioritiesDialog(context),
                          ),
                        ]
                      : profile.weeklyPriorities
                          .map(
                            (priority) => _BulletBlock(
                              title: priority.area,
                              subtitle: priority.focus,
                              items: priority.suggestedActions,
                            ),
                          )
                          .toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Service Tendencies
                _SectionCard(
                  title: 'Service Tendencies',
                  icon: Icons.volunteer_activism_rounded,
                  children: [
                    _StringList(items: profile.burdensAndServiceTendencies),
                    if (profile.burdensAndServiceTendencies.isNotEmpty)
                      _ActionButton(
                        label: 'Find Service Opportunities',
                        icon: Icons.search_rounded,
                        onTap: () => context.push(AppRoutes.actOpportunities),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Relational Focus
                _SectionCard(
                  title: 'Relational Focus',
                  icon: Icons.favorite_rounded,
                  children: [
                    _StringList(items: profile.relationalFocus),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Growth Risks with Action
                _SectionCard(
                  title: 'Growth Risks',
                  icon: Icons.trending_up_rounded,
                  children: [
                    _StringList(items: profile.growthRisks),
                    if (profile.growthRisks.isNotEmpty)
                      _ActionButton(
                        label: 'Open Soul Care',
                        icon: Icons.support_rounded,
                        onTap: () => context.push(AppRoutes.spiritualAid),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Recommended Practices
                _SectionCard(
                  title: 'Recommended Practices',
                  icon: Icons.self_improvement_rounded,
                  children: profile.recommendedPractices
                      .map(
                        (practice) => _PracticeCard(
                          name: practice.name,
                          description: practice.description,
                          frequency: practice.frequency,
                          onTap: () => _startPractice(context, practice.name),
                        ),
                      )
                      .toList(),
                ),
                
                if (profile.personalDistractions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Watch For',
                    icon: Icons.visibility_rounded,
                    children: [
                      _StringList(items: profile.personalDistractions),
                    ],
                  ),
                ],
                
                if (weeklyPlan != null) ...[
                  const SizedBox(height: 16),
                  _WeeklyPlanCard(weeklyPlan: weeklyPlan),
                ],
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAct(BuildContext context) {
    ref.read(analyticsProvider).track(
      AppAnalyticsEvent.quickActionTapped,
      properties: {'action': 'act', 'source': 'calling_profile'},
    );
    context.push(AppRoutes.act);
  }

  void _navigateToReflect(BuildContext context) {
    ref.read(analyticsProvider).track(
      AppAnalyticsEvent.quickActionTapped,
      properties: {'action': 'reflect', 'source': 'calling_profile'},
    );
    context.push(AppRoutes.journal);
  }

  void _navigateToTogether(BuildContext context) {
    ref.read(analyticsProvider).track(
      AppAnalyticsEvent.quickActionTapped,
      properties: {'action': 'together', 'source': 'calling_profile'},
    );
    context.push(AppRoutes.growTogether);
  }

  void _showSetPrioritiesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Weekly Priorities'),
        content: const Text(
          'Priorities help you focus your week on what matters most for your calling.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.alignment);
            },
            child: const Text('Go to Alignment'),
          ),
        ],
      ),
    );
  }

  void _startPractice(BuildContext context, String practiceName) {
    ref.read(analyticsProvider).track(
      AppAnalyticsEvent.soulCareToolUsed,
      properties: {'tool': practiceName, 'source': 'calling_profile'},
    );
    
    // Navigate based on practice type
    if (practiceName.toLowerCase().contains('meditation') ||
        practiceName.toLowerCase().contains('prayer')) {
      context.push(AppRoutes.meditation);
    } else if (practiceName.toLowerCase().contains('journal') ||
               practiceName.toLowerCase().contains('reflect')) {
      context.push(AppRoutes.journal);
    } else {
      context.push(AppRoutes.home);
    }
  }
}

// ==================== WIDGETS ====================

class _IdentityCard extends StatelessWidget {
  final String archetypeIdentity;
  final String archetypeId;
  final String missionFocus;
  final String commitmentCategory;

  const _IdentityCard({
    required this.archetypeIdentity,
    required this.archetypeId,
    required this.missionFocus,
    required this.commitmentCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.palette.identityColor.withValues(alpha: 0.15),
            tokens.palette.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.palette.identityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.palette.identityColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: tokens.palette.identityColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      archetypeIdentity,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      archetypeId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _IdentityRow(
            icon: Icons.flag_rounded,
            label: 'Mission Focus',
            value: missionFocus,
            color: tokens.palette.success,
          ),
          const SizedBox(height: 8),
          _IdentityRow(
            icon: Icons.commit_rounded,
            label: 'Commitment Style',
            value: commitmentCategory,
            color: tokens.palette.growthColor,
          ),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IdentityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionPromptsSection extends StatelessWidget {
  final List<String> serviceTendencies;
  final List<String> relationalFocus;
  final VoidCallback onActTap;
  final VoidCallback onReflectTap;
  final VoidCallback onTogetherTap;

  const _ActionPromptsSection({
    required this.serviceTendencies,
    required this.relationalFocus,
    required this.onActTap,
    required this.onReflectTap,
    required this.onTogetherTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn Identity Into Action',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionPromptCard(
                icon: Icons.volunteer_activism_rounded,
                label: 'Act',
                subtitle: 'Serve others',
                color: theme.colorScheme.primary,
                onTap: onActTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPromptCard(
                icon: Icons.edit_note_rounded,
                label: 'Reflect',
                subtitle: 'Journal & pray',
                color: theme.colorScheme.secondary,
                onTap: onReflectTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionPromptCard(
                icon: Icons.people_alt_rounded,
                label: 'Together',
                subtitle: 'Grow with others',
                color: theme.colorScheme.tertiary,
                onTap: onTogetherTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPromptCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionPromptCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String name;
  final String description;
  final String frequency;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.name,
    required this.description,
    required this.frequency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                frequency,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPlanCard extends StatelessWidget {
  final dynamic weeklyPlan;

  const _WeeklyPlanCard({required this.weeklyPlan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'This Week',
      icon: Icons.calendar_view_week_rounded,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            weeklyPlan.reflectionPrompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...weeklyPlan.weeklyCommitments.map(
          (commitment) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: commitment.currentCount >= commitment.targetCount
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                commitment.currentCount >= commitment.targetCount
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                size: 16,
                color: commitment.currentCount >= commitment.targetCount
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            title: Text(
              commitment.title,
              style: TextStyle(
                decoration: commitment.currentCount >= commitment.targetCount
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(commitment.description),
            trailing: Text(
              '${commitment.currentCount}/${commitment.targetCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: commitment.currentCount >= commitment.targetCount
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyStateMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;

  const _SectionCard({
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StringList extends StatelessWidget {
  final List<String> items;

  const _StringList({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Text(
        'Not specified yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BulletBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> items;

  const _BulletBlock({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          _StringList(items: items),
        ],
      ),
    );
  }
}

class _ProductSpineProgress extends StatelessWidget {
  final bool hasProfile;
  final bool hasWeeklyPlan;

  const _ProductSpineProgress({
    required this.hasProfile,
    required this.hasWeeklyPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _ProgressStep(
                icon: Icons.compass_calibration,
                label: 'Assessment',
                completed: true,
              ),
              const _ProgressConnector(completed: true),
              _ProgressStep(
                icon: Icons.person,
                label: 'Profile',
                completed: hasProfile,
              ),
              _ProgressConnector(completed: hasProfile),
              _ProgressStep(
                icon: Icons.calendar_view_week,
                label: 'Weekly Plan',
                completed: hasWeeklyPlan,
              ),
              _ProgressConnector(completed: hasWeeklyPlan),
              const _ProgressStep(
                icon: Icons.today,
                label: 'Daily Action',
                completed: false,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool completed;
  final bool isLast;

  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.completed,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            border: Border.all(
              color: completed
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: completed
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: completed
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ProgressConnector extends StatelessWidget {
  final bool completed;

  const _ProgressConnector({required this.completed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: completed
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
