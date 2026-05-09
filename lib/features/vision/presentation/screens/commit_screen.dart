import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../domain/vision_models.dart';
import '../widgets/reflection_feed_widgets.dart';
import '../widgets/vision_panel.dart';

class CommitScreen extends ConsumerStatefulWidget {
  const CommitScreen({super.key});

  @override
  ConsumerState<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends ConsumerState<CommitScreen> {
  final _reflectionController = TextEditingController();
  int _selectedNudges = 3;
  String _selectedCategory = 'all';
  final Set<int> _pinnedReflectionIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commit'),
        actions: [
          if (active != null)
            IconButton(
              tooltip: 'Browse commitments',
              onPressed: () =>
                  _showCommitmentLibrary(state.recommendedCommitments, active),
              icon: const Icon(LucideIcons.layoutGrid),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visionProvider.notifier).load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _CommitHeader(active: active),
            const SizedBox(height: 16),
            if (active != null) ...[
              _ActiveCommitment(active: active, showCheckInAction: false),
              const SizedBox(height: 16),
              VisionReflectionComposer(controller: _reflectionController),
              const SizedBox(height: 16),
              VisionReflectionFeed(
                title: 'Your commitment feed',
                pinnedIds: _pinnedReflectionIds,
                onTogglePinned: _togglePinnedReflection,
              ),
              const SizedBox(height: 16),
              _AccountabilityAssistantPanel(active: active),
            ] else ...[
              _NudgeEducationPanel(onLearnMore: _showNudgeHelp),
              const SizedBox(height: 16),
              _CategoryRail(
                categories: _categoriesFor(state.recommendedCommitments),
                selected: _selectedCategory,
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
              const SizedBox(height: 16),
              ..._visibleCommitments(
                state.recommendedCommitments,
              ).map(_buildCommitmentOption),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentOption(CommitmentPlan plan) {
    final theme = Theme.of(context);
    final min = plan.nudgeMin;
    final max = plan.nudgeMax;
    final nudges = _selectedNudges.clamp(min, max);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIcon(category: plan.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: LucideIcons.calendarDays,
                          label: '${plan.durationDays} days',
                        ),
                        _MetaPill(
                          icon: LucideIcons.bell,
                          label: '${plan.nudgeMin}-${plan.nudgeMax} nudges',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(plan.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plan.dailyAction,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _NudgeSelectorHeader(nudges: nudges, onHelp: _showNudgeHelp),
          Slider(
            value: nudges.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min).clamp(1, 10),
            label: '$nudges',
            onChanged: (value) =>
                setState(() => _selectedNudges = value.round()),
          ),
          FilledButton.icon(
            onPressed: ref.watch(visionProvider).isLoading
                ? null
                : () => _showCommitmentWalkthrough(plan, nudges),
            icon: const Icon(LucideIcons.compass, size: 18),
            label: const Text('Review and begin'),
          ),
        ],
      ),
    );
  }

  List<String> _categoriesFor(List<CommitmentPlan> plans) {
    return ['all', ...plans.map((plan) => plan.category).toSet()];
  }

  List<CommitmentPlan> _visibleCommitments(List<CommitmentPlan> plans) {
    if (_selectedCategory == 'all') return plans;
    return plans
        .where((plan) => plan.category == _selectedCategory)
        .toList(growable: false);
  }

  void _showNudgeHelp() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _NudgeHelpSheet(),
    );
  }

  void _togglePinnedReflection(CommitmentReflection reflection) {
    setState(() {
      if (_pinnedReflectionIds.contains(reflection.id)) {
        _pinnedReflectionIds.remove(reflection.id);
      } else {
        _pinnedReflectionIds.add(reflection.id);
      }
    });
  }

  void _showCommitmentLibrary(
    List<CommitmentPlan> commitments,
    CommitmentSeason active,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _CommitmentLibrarySheet(commitments: commitments, active: active),
    );
  }

  Future<void> _showCommitmentWalkthrough(
    CommitmentPlan plan,
    int initialNudges,
  ) async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CommitmentWalkthroughSheet(
        plan: plan,
        initialNudges: initialNudges,
        onJoin: (nudges) async {
          final joined = await ref
              .read(visionProvider.notifier)
              .joinCommitment(plan, nudges);
          if (context.mounted) {
            Navigator.of(context).pop(joined);
          }
        },
      ),
    );

    if (!mounted || joined == null) return;
    if (!joined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not start this commitment. Please try again.',
          ),
        ),
      );
      return;
    }
    await PremiumSuccessDialog.show(
      context,
      title: 'Commitment joined',
      message:
          'Your digital accountability assistant is ready. The nudge is a hand on your shoulder, not a verdict on your soul.',
      primaryActionText: 'Continue',
    );
  }
}

class _CommitHeader extends StatelessWidget {
  const _CommitHeader({required this.active});

  final CommitmentSeason? active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActive = active != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VisionIllustration(
            asset: VisionIllustrationAsset.commitment,
            size: 86,
            semanticLabel: 'Commitment',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActive ? 'Keep the path' : 'Choose one path',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasActive
                      ? 'One return today is enough. The app should support your faithfulness, not crowd it.'
                      : 'Commitments are the center of ElBiblio: a concrete practice, a gentle nudge rhythm, and a private reflection circle.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NudgeEducationPanel extends StatelessWidget {
  const _NudgeEducationPanel({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VisionPanel(
      icon: LucideIcons.bellRing,
      title: 'Nudges are accountability, not pressure',
      trailing: IconButton(
        tooltip: 'Learn about nudges',
        onPressed: onLearnMore,
        icon: const Icon(LucideIcons.helpCircle, size: 20),
      ),
      child: Text(
        'Pick the rhythm you can respect. If three nudges are not enough, increase support and use the faith walkthrough to name what this practice is forming in you.',
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selected == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(_categoryLabel(category)),
              avatar: Icon(_categoryIcon(category), size: 16),
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_categoryIcon(category), color: theme.colorScheme.primary),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _NudgeSelectorHeader extends StatelessWidget {
  const _NudgeSelectorHeader({required this.nudges, required this.onHelp});

  final int nudges;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$nudges gentle nudges per day',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'How nudges work',
          onPressed: onHelp,
          icon: const Icon(LucideIcons.helpCircle, size: 20),
        ),
      ],
    );
  }
}

class _NudgeHelpSheet extends StatelessWidget {
  const _NudgeHelpSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How nudges work',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const _ExpectationRow(
            icon: LucideIcons.bell,
            title: 'They interrupt forgetfulness',
            body:
                'A nudge is a small return point. Tap it, do the action, then check in.',
          ),
          const _ExpectationRow(
            icon: LucideIcons.heartHandshake,
            title: 'They are not shame',
            body:
                'Missing a nudge is information, not condemnation. Increase support when your season needs more structure.',
          ),
          const _ExpectationRow(
            icon: LucideIcons.sprout,
            title: 'They can teach',
            body:
                'The faith walkthrough names the virtue being formed and the vice being weakened.',
          ),
        ],
      ),
    );
  }
}

class _CommitmentLibrarySheet extends StatelessWidget {
  const _CommitmentLibrarySheet({
    required this.commitments,
    required this.active,
  });

  final List<CommitmentPlan> commitments;
  final CommitmentSeason active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.74,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Commitment paths',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay with one path at a time. Keep this library close for your next season.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            const SizedBox(height: 16),
            ...commitments.map(
              (plan) => _CommitmentLibraryCard(
                plan: plan,
                isActive: plan.id == active.plan.id,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommitmentLibraryCard extends StatelessWidget {
  const _CommitmentLibraryCard({required this.plan, required this.isActive});

  final CommitmentPlan plan;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
            : theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.28)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryIcon(category: plan.category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isActive) const Icon(LucideIcons.checkCircle, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  plan.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: LucideIcons.calendarDays,
                      label: '${plan.durationDays} days',
                    ),
                    _MetaPill(
                      icon: LucideIcons.bell,
                      label: '${plan.nudgeMin}-${plan.nudgeMax} nudges',
                    ),
                    if (isActive)
                      const _MetaPill(
                        icon: LucideIcons.flag,
                        label: 'Current path',
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
}

class _CommitmentWalkthroughSheet extends StatefulWidget {
  const _CommitmentWalkthroughSheet({
    required this.plan,
    required this.initialNudges,
    required this.onJoin,
  });

  final CommitmentPlan plan;
  final int initialNudges;
  final Future<void> Function(int nudges) onJoin;

  @override
  State<_CommitmentWalkthroughSheet> createState() =>
      _CommitmentWalkthroughSheetState();
}

class _CommitmentWalkthroughSheetState
    extends State<_CommitmentWalkthroughSheet> {
  late int _nudges;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _nudges = widget.initialNudges.clamp(
      widget.plan.nudgeMin,
      widget.plan.nudgeMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Before you begin',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is not a pressure machine. It is a gentle accountability assistant for the person you already want to become.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          _SampleNudgeCard(plan: widget.plan),
          const SizedBox(height: 16),
          _ExpectationRow(
            icon: LucideIcons.checkCircle,
            title: 'What you do',
            body: widget.plan.dailyAction,
          ),
          const _ExpectationRow(
            icon: LucideIcons.bell,
            title: 'What nudges do',
            body:
                'They interrupt forgetfulness and help you check in. They are not a scorecard.',
          ),
          const _ExpectationRow(
            icon: LucideIcons.messageCircle,
            title: 'What happens after',
            body:
                'Once you return, you can share one short reflection with people on the same path.',
          ),
          const SizedBox(height: 8),
          Text(
            'Nudge rhythm',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start with $_nudges per day. If three still cannot catch the pattern, ElBiblio can invite you into a stronger rhythm and a faith walkthrough.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          Slider(
            value: _nudges.toDouble(),
            min: widget.plan.nudgeMin.toDouble(),
            max: widget.plan.nudgeMax.toDouble(),
            divisions: (widget.plan.nudgeMax - widget.plan.nudgeMin).clamp(
              1,
              10,
            ),
            label: '$_nudges',
            onChanged: _joining
                ? null
                : (value) => setState(() => _nudges = value.round()),
          ),
          _FaithWalkthroughPreview(plan: widget.plan),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _joining
                ? null
                : () async {
                    setState(() => _joining = true);
                    await widget.onJoin(_nudges);
                    if (mounted) {
                      setState(() => _joining = false);
                    }
                  },
            icon: _joining
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.flag, size: 18),
            label: Text('Begin ${widget.plan.durationDays}-day commitment'),
          ),
        ],
      ),
    );
  }
}

class _SampleNudgeCard extends StatelessWidget {
  const _SampleNudgeCard({required this.plan});

  final CommitmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.bell, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A quiet return is still a return. ${plan.dailyAction}',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('I did this')),
                    Chip(label: Text('Open commitment')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectationRow extends StatelessWidget {
  const _ExpectationRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaithWalkthroughPreview extends StatelessWidget {
  const _FaithWalkthroughPreview({required this.plan});

  final CommitmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final insight = _faithInsightFor(plan.category);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.sprout, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${insight.$1}\n',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: insight.$2),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCommitment extends ConsumerWidget {
  const _ActiveCommitment({
    required this.active,
    this.showCheckInAction = true,
  });

  final CommitmentSeason active;
  final bool showCheckInAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VisionPanel(
      icon: LucideIcons.checkCircle,
      title: active.plan.title,
      trailing: Text('Day ${active.currentDay}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(active.plan.dailyAction),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: active.progress),
          const SizedBox(height: 12),
          if (active.checkedInToday)
            const Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 18),
                SizedBox(width: 8),
                Text('You returned today.'),
              ],
            )
          else if (!showCheckInAction)
            const Row(
              children: [
                Icon(LucideIcons.clock3, size: 18),
                SizedBox(width: 8),
                Text('Today is still open.'),
              ],
            )
          else
            FilledButton.icon(
              onPressed: () async {
                final completed = await ref
                    .read(visionProvider.notifier)
                    .checkIn();
                if (!context.mounted || completed) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'We could not complete today. Please try again.',
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.checkCircle, size: 18),
              label: const Text('Mark today\'s return'),
            ),
        ],
      ),
    );
  }
}

class _AccountabilityAssistantPanel extends ConsumerWidget {
  const _AccountabilityAssistantPanel({required this.active});

  final CommitmentSeason active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canIncrease = active.nudgeCountPerDay < active.plan.nudgeMax;
    final suggested = (active.nudgeCountPerDay + 2).clamp(
      active.plan.nudgeMin,
      active.plan.nudgeMax,
    );

    return VisionPanel(
      icon: LucideIcons.bellRing,
      title: 'Your accountability assistant',
      trailing: Text('${active.nudgeCountPerDay}/day'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.checkedInToday
                ? 'The nudge did its work today: it helped you return, then got out of the way.'
                : 'If the first nudges pass by, you are not failing. You may need clearer support for this season.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          _FaithWalkthroughPreview(plan: active.plan),
          if (!active.checkedInToday && canIncrease) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                final updated = await ref
                    .read(visionProvider.notifier)
                    .updateNudges(suggested);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      updated
                          ? 'Nudges increased to $suggested per day.'
                          : 'We could not update nudges. Please try again.',
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text('Increase to $suggested nudges'),
            ),
          ],
        ],
      ),
    );
  }
}

(String, String) _faithInsightFor(String category) {
  return switch (category.toLowerCase()) {
    'discipline' => (
      'Discipline protects attention.',
      'A fast is not contempt for desire. It trains the soul to notice what has been ruling it and return freely to God.',
    ),
    'prayer' => (
      'Prayer keeps the heart turned.',
      'Five honest minutes can loosen self-reliance and make space for dependence, confession, and trust.',
    ),
    'gratitude' => (
      'Gratitude heals spiritual blindness.',
      'Naming gifts does not deny pain. It teaches the soul to see grace without pretending life is easy.',
    ),
    'forgiveness' => (
      'Forgiveness releases the grip of resentment.',
      'It does not excuse harm. It opens a path where bitterness no longer gets to form your spirit.',
    ),
    _ => (
      'Faithfulness is formed through return.',
      'Small repeated acts tell the soul what matters and make growth possible without performance.',
    ),
  };
}

String _categoryLabel(String category) {
  return switch (category.toLowerCase()) {
    'all' => 'All paths',
    'discipline' => 'Discipline',
    'prayer' => 'Prayer',
    'gratitude' => 'Gratitude',
    'forgiveness' => 'Forgiveness',
    _ =>
      category.isEmpty
          ? 'Growth'
          : '${category[0].toUpperCase()}${category.substring(1)}',
  };
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'discipline' => LucideIcons.shield,
    'prayer' => LucideIcons.flame,
    'gratitude' => LucideIcons.sparkles,
    'forgiveness' => LucideIcons.heartHandshake,
    'all' => LucideIcons.layoutGrid,
    _ => LucideIcons.sprout,
  };
}
