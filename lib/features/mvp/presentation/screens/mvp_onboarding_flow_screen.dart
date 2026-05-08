import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/mvp_models.dart';

class MvpOnboardingFlowScreen extends ConsumerStatefulWidget {
  const MvpOnboardingFlowScreen({super.key});

  @override
  ConsumerState<MvpOnboardingFlowScreen> createState() =>
      _MvpOnboardingFlowScreenState();
}

class _MvpOnboardingFlowScreenState
    extends ConsumerState<MvpOnboardingFlowScreen> {
  final _controller = PageController();
  final _aliasController = TextEditingController();
  MvpVisibilityMode _mode = MvpVisibilityMode.anonymous;
  MvpTribe? _tribe;
  MvpCommitmentChallenge? _commitment;
  int _nudges = 3;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(mvpProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final notifier = ref.read(mvpProvider.notifier);
    await notifier.setVisibility(_mode, alias: _aliasController.text);
    if (_tribe != null) {
      await notifier.joinTribe(_tribe!);
    }
    if (_commitment != null) {
      await notifier.joinCommitment(_commitment!, _nudges);
    }
    await ref.read(settingsProvider.notifier).markPostOnboardingComplete();
    if (!mounted) return;
    context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mvpProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_page + 1) / 4),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Page(
                    icon: LucideIcons.eye,
                    title: 'Choose visibility',
                    child: Column(
                      children: [
                        SegmentedButton<MvpVisibilityMode>(
                          segments: MvpVisibilityMode.values
                              .map(
                                (item) => ButtonSegment(
                                  value: item,
                                  label: Text(item.label),
                                ),
                              )
                              .toList(),
                          selected: {_mode},
                          onSelectionChanged: (selection) =>
                              setState(() => _mode = selection.first),
                        ),
                        if (_mode == MvpVisibilityMode.nickname ||
                            _mode == MvpVisibilityMode.public) ...[
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
                  const _Page(
                    icon: LucideIcons.compass,
                    title: 'Spiritual compass',
                    child: Text(
                      'For the MVP, your compass begins with a simple direction: belonging, commitment, and daily return.',
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.users,
                    title: 'Join a tribe',
                    child: RadioGroup<MvpTribe>(
                      groupValue: _tribe,
                      onChanged: (value) => setState(() => _tribe = value),
                      child: Column(
                        children: state.recommendedTribes.map((tribe) {
                          final selected = _tribe?.id == tribe.id;
                          return RadioListTile<MvpTribe>(
                            value: tribe,
                            title: Text(tribe.name),
                            subtitle: Text(tribe.description),
                            selected: selected,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.flag,
                    title: 'Choose a commitment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioGroup<MvpCommitmentChallenge>(
                          groupValue: _commitment,
                          onChanged: (value) {
                            setState(() {
                              _commitment = value;
                              _nudges = (_commitment?.nudgeMin ?? 3).clamp(
                                3,
                                10,
                              );
                            });
                          },
                          child: Column(
                            children: state.recommendedCommitments.map((
                              commitment,
                            ) {
                              return RadioListTile<MvpCommitmentChallenge>(
                                value: commitment,
                                title: Text(commitment.title),
                                subtitle: Text(
                                  '${commitment.durationDays} days',
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daily nudges: $_nudges',
                          style: theme.textTheme.titleSmall,
                        ),
                        Slider(
                          value: _nudges.toDouble(),
                          min: (_commitment?.nudgeMin ?? 3).toDouble(),
                          max: (_commitment?.nudgeMax ?? 10).toDouble(),
                          divisions:
                              ((_commitment?.nudgeMax ?? 10) -
                                      (_commitment?.nudgeMin ?? 3))
                                  .clamp(1, 10),
                          onChanged: _commitment == null
                              ? null
                              : (value) =>
                                    setState(() => _nudges = value.round()),
                        ),
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
                      onPressed: _page == 3
                          ? _finish
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                            ),
                      child: Text(_page == 3 ? 'Begin' : 'Continue'),
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
