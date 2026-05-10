import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../application/vision_state.dart';
import '../../domain/vision_models.dart';
import '../widgets/visibility_mode_picker.dart';

class VisionOnboardingFlowScreen extends ConsumerStatefulWidget {
  const VisionOnboardingFlowScreen({super.key});

  @override
  ConsumerState<VisionOnboardingFlowScreen> createState() =>
      _VisionOnboardingFlowScreenState();
}

class _VisionOnboardingFlowScreenState
    extends ConsumerState<VisionOnboardingFlowScreen> {
  final _controller = PageController();
  final _aliasController = TextEditingController();
  final _whenController = TextEditingController();
  final _obstacleController = TextEditingController();
  VisibilityMode _mode = VisibilityMode.anonymous;
  TribeIdentity? _tribe;
  CommitmentPlan? _commitment;
  int _nudges = 3;
  int _identityIndex = 0;
  int _page = 0;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _controller.dispose();
    _aliasController.dispose();
    _whenController.dispose();
    _obstacleController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await ref.read(visionProvider.notifier).load(force: true);
    if (!mounted) return;

    final state = ref.read(visionProvider);
    setState(() {
      _mode = state.visibilityMode;
      _aliasController.text = state.visibilityAlias == 'Anonymous'
          ? ''
          : state.visibilityAlias;
      _tribe =
          state.primaryTribe?.tribe ??
          (state.recommendedTribes.isNotEmpty
              ? state.recommendedTribes.first
              : null);
      _commitment =
          state.activeCommitment?.plan ??
          (state.recommendedCommitments.isNotEmpty
              ? state.recommendedCommitments.first
              : null);
      _nudges = (_commitment?.nudgeMin ?? 3).clamp(3, 10);
      _identityIndex = _tribe == null
          ? 0
          : state.recommendedTribes.indexWhere((item) => item.id == _tribe!.id);
      if (_identityIndex < 0) _identityIndex = 0;
    });
  }

  Future<void> _finish() async {
    if (_tribe == null) {
      _showIssue('Choose a tribe before beginning.');
      return;
    }
    if (_commitment == null) {
      _showIssue('Choose a commitment before beginning.');
      return;
    }

    setState(() => _isFinishing = true);
    final notifier = ref.read(visionProvider.notifier);
    final visibilitySaved = await notifier.setVisibility(
      _mode,
      alias: _aliasController.text,
    );
    if (!visibilitySaved) {
      if (mounted) setState(() => _isFinishing = false);
      _showIssue('We could not save your visibility. Please try again.');
      return;
    }

    final tribeJoined = await notifier.joinTribe(_tribe!);
    if (!tribeJoined) {
      if (mounted) setState(() => _isFinishing = false);
      _showIssue('We could not join your tribe. Please try again.');
      return;
    }

    final commitmentJoined = await notifier.joinCommitment(
      _commitment!,
      _nudges,
      planWhen: _whenController.text,
      planObstacle: _obstacleController.text,
    );
    if (!commitmentJoined) {
      if (mounted) setState(() => _isFinishing = false);
      _showIssue('We could not start your commitment. Please try again.');
      return;
    }

    await ref.read(settingsProvider.notifier).markPostOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.today);
  }

  void _showIssue(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canContinue {
    if (_isFinishing) return false;
    if (_page == 2) return _tribe != null;
    if (_page == 3) return _commitment != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_page + 1) / 5),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Page(
                    icon: LucideIcons.eye,
                    title: 'Choose how you appear',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your reflections are only visible inside the commitment you join. Choose the name others will see there.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        VisibilityModePicker(
                          value: _mode,
                          onChanged: (mode) => setState(() => _mode = mode),
                        ),
                        if (_mode == VisibilityMode.nickname ||
                            _mode == VisibilityMode.public) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _aliasController,
                            maxLength: 50,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.compass,
                    title: 'Your spiritual compass',
                    child: _OnboardingRecoveryGate(
                      state: state,
                      child: _CompassChoice(
                        selectedIndex: _identityIndex,
                        archetypeId: settings.primaryArchetypeId,
                        tribes: state.recommendedTribes,
                        onSelected: (index, tribe) {
                          setState(() {
                            _identityIndex = index;
                            _tribe = tribe;
                          });
                        },
                      ),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.users,
                    title: 'Join a tribe',
                    child: _OnboardingRecoveryGate(
                      state: state,
                      emptyMessage:
                          'We could not load real tribe recommendations. Reconnect and try again before beginning.',
                      child: RadioGroup<TribeIdentity>(
                        groupValue: _tribe,
                        onChanged: (value) => setState(() => _tribe = value),
                        child: Column(
                          children: state.recommendedTribes.map((tribe) {
                            return RadioListTile<TribeIdentity>(
                              value: tribe,
                              title: Text(tribe.displayName),
                              subtitle: Text(tribe.description),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.flag,
                    title: 'Choose a commitment',
                    child: _OnboardingRecoveryGate(
                      state: state,
                      emptyMessage:
                          'We could not load the real commitment catalog. Reconnect and try again before beginning.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick one concrete practice for this season. You can keep the rest for later.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          ...state.recommendedCommitments.map(
                            (commitment) => _OnboardingCommitmentCard(
                              commitment: commitment,
                              selected: _commitment?.id == commitment.id,
                              onTap: () {
                                setState(() {
                                  _commitment = commitment;
                                  _nudges = commitment.nudgeMin.clamp(3, 10);
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          _OnboardingNudgePanel(
                            commitment: _commitment,
                            nudges: _nudges,
                            onChanged: (value) =>
                                setState(() => _nudges = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.clock3,
                    title: 'Plan your first check-in',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A rough plan is enough. You are not promising a perfect day; you are making the next check-in easier to notice.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _whenController,
                          decoration: const InputDecoration(
                            labelText: 'When will you usually do this?',
                            hintText: 'After morning prayer, lunch, or work',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _obstacleController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'What might get in the way?',
                            hintText: 'Tiredness, scrolling, rushing, doubt',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _ImplementationCue(commitment: _commitment),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: !_canContinue
                          ? null
                          : _page == 4
                          ? _finish
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                            ),
                      child: _isFinishing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_page == 4 ? 'Begin' : 'Continue'),
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
}

class _OnboardingRecoveryGate extends StatelessWidget {
  const _OnboardingRecoveryGate({
    required this.state,
    required this.child,
    this.emptyMessage,
  });

  final VisionState state;
  final Widget child;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    final isReadOnly = state.isReadOnly;
    final hasAnyRecommendation =
        state.recommendedTribes.isNotEmpty ||
        state.recommendedCommitments.isNotEmpty;
    if (error?.isNotEmpty == true || (isReadOnly && !hasAnyRecommendation)) {
      return _OnboardingIssue(
        message:
            error ??
            emptyMessage ??
            'Reconnect before continuing. This launch flow needs real tribe and commitment data.',
      );
    }
    return child;
  }
}

class _OnboardingIssue extends StatelessWidget {
  const _OnboardingIssue({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.wifiOff, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _OnboardingCommitmentCard extends StatelessWidget {
  const _OnboardingCommitmentCard({
    required this.commitment,
    required this.selected,
    required this.onTap,
  });

  final CommitmentPlan commitment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.24)
                : theme.colorScheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outline.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _commitmentIcon(commitment.category),
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      commitment.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    selected ? LucideIcons.checkCircle : LucideIcons.circle,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                commitment.description,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CommitmentPill(
                    icon: LucideIcons.calendarDays,
                    label: '${commitment.durationDays} days',
                  ),
                  _CommitmentPill(
                    icon: LucideIcons.bell,
                    label:
                        '${commitment.nudgeMin}-${commitment.nudgeMax} nudges',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingNudgePanel extends StatelessWidget {
  const _OnboardingNudgePanel({
    required this.commitment,
    required this.nudges,
    required this.onChanged,
  });

  final CommitmentPlan? commitment;
  final int nudges;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final plan = commitment;
    if (plan == null) {
      return const Text('Choose a commitment to set your nudge rhythm.');
    }
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$nudges gentle nudges per day',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nudges are check-in points, not pressure. Start with a rhythm you can respect.',
            style: theme.textTheme.bodySmall,
          ),
          Slider(
            value: nudges.toDouble(),
            min: plan.nudgeMin.toDouble(),
            max: plan.nudgeMax.toDouble(),
            divisions: (plan.nudgeMax - plan.nudgeMin).clamp(1, 10),
            label: '$nudges',
            onChanged: (value) => onChanged(value.round()),
          ),
        ],
      ),
    );
  }
}

class _ImplementationCue extends StatelessWidget {
  const _ImplementationCue({required this.commitment});

  final CommitmentPlan? commitment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.bell, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              commitment == null
                  ? 'Your first nudge will simply help you notice the next check-in.'
                  : 'When the nudge comes, do this one thing: ${commitment!.dailyAction}',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentPill extends StatelessWidget {
  const _CommitmentPill({required this.icon, required this.label});

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

class _CompassChoice extends StatelessWidget {
  const _CompassChoice({
    required this.selectedIndex,
    required this.archetypeId,
    required this.tribes,
    required this.onSelected,
  });

  final int selectedIndex;
  final String? archetypeId;
  final List<TribeIdentity> tribes;
  final void Function(int index, TribeIdentity tribe) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tribes.isEmpty) {
      return const Text(
        'Your spiritual compass helps connect your current season with a tribe and commitment that can support real growth.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          archetypeId == null
              ? 'Choose the current season that feels closest to you. This helps shape your first tribe recommendation.'
              : 'Your compass points toward $archetypeId. Next you will confirm the tribe that fits this season.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (archetypeId != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.compass, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$archetypeId is your starting signal, not a permanent label.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...tribes.take(3).indexed.map((entry) {
            final index = entry.$1;
            final tribe = entry.$2;
            final selected = index == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelected(index, tribe),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        GrowthJourneyEvent.iconForKey(tribe.iconKey),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tribe.displayName,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tribe.description,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Icon(icon, size: 42, color: theme.colorScheme.primary),
        const SizedBox(height: 20),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        child,
      ],
    );
  }
}

IconData _commitmentIcon(String category) {
  return switch (category.toLowerCase()) {
    'discipline' => LucideIcons.shield,
    'prayer' => LucideIcons.flame,
    'gratitude' => LucideIcons.sparkles,
    'forgiveness' => LucideIcons.heartHandshake,
    _ => LucideIcons.sprout,
  };
}
