import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/models/accountability_tone.dart';
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
  AccountabilityTone _tone = AccountabilityTone.balanced;
  TribeIdentity? _tribe;
  CommitmentPlan? _commitment;
  int _nudges = 3;
  int _identityIndex = 0;
  int _page = 0;
  bool _isFinishing = false;
  String? _currentSeason;
  String? _pressurePattern;
  String? _postponedPattern;
  String? _peopleNeedPattern;
  String? _formationPattern;

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
      _tone = ref.read(settingsProvider).accountabilityTone;
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
    final signal = _compassSignal;
    await ref
        .read(settingsProvider.notifier)
        .setCompassSeasonSignal(
          archetype: signal.archetype,
          supportScore: signal.supportScore,
          accountabilityTone: _tone,
        );
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
    if (_page == 0) return _currentSeason != null;
    if (_page == 1) {
      return _pressurePattern != null &&
          _postponedPattern != null &&
          _peopleNeedPattern != null &&
          _formationPattern != null;
    }
    if (_page == 3) return _tribe != null;
    if (_page == 4) return _commitment != null;
    return true;
  }

  _CompassSignal get _compassSignal {
    const archetypeOrder = [
      'Artisan',
      'Watchman',
      'Cultivator',
      'Sower',
      'Welcomer',
      'Pillar',
      'Sentinel',
      'Bridgebuilder',
      'Healer',
      'Harvester',
      'Reformer',
      'Architect',
    ];
    final scores = {for (final archetype in archetypeOrder) archetype: 0};

    void addScore(String? archetype, int score) {
      if (archetype == null || !scores.containsKey(archetype)) return;
      scores[archetype] = scores[archetype]! + score;
    }

    addScore(_currentSeason, 5);
    addScore(_pressurePattern, 3);
    addScore(_postponedPattern, 3);
    addScore(_peopleNeedPattern, 2);
    addScore(_formationPattern, 4);

    final ranked = List<String>.from(archetypeOrder)
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        if (byScore != 0) return byScore;
        return archetypeOrder.indexOf(a).compareTo(archetypeOrder.indexOf(b));
      });
    final primary = ranked.first;
    final primaryScore = scores[primary] ?? 0;

    return _CompassSignal(
      archetype: primary,
      topArchetypes: ranked.take(3).where((name) => scores[name]! > 0).toList(),
      season: _seasonNameFor(primary),
      supportScore: (42 + (primaryScore * 4)).clamp(42, 92).toInt(),
      suggestedTone: _toneFor(primary, primaryScore),
    );
  }

  String _seasonNameFor(String archetype) {
    return switch (archetype) {
      'Artisan' => 'Creative devotion',
      'Watchman' => 'Guarded attention',
      'Cultivator' => 'Patient formation',
      'Sower' => 'Courageous beginning',
      'Welcomer' => 'Honest hospitality',
      'Pillar' => 'Hidden faithfulness',
      'Sentinel' => 'Prayer into action',
      'Bridgebuilder' => 'Relational repair',
      'Healer' => 'Restorative presence',
      'Harvester' => 'Fruitful stewardship',
      'Reformer' => 'Constructive justice',
      'Architect' => 'Open-handed order',
      _ => 'Steady formation',
    };
  }

  AccountabilityTone _toneFor(String archetype, int score) {
    if (score >= 10 &&
        const {
          'Watchman',
          'Reformer',
          'Architect',
          'Harvester',
        }.contains(archetype)) {
      return AccountabilityTone.firm;
    }
    if (const {'Healer', 'Welcomer', 'Pillar'}.contains(archetype)) {
      return AccountabilityTone.gentle;
    }
    return AccountabilityTone.balanced;
  }

  Future<void> _goNext(AccountabilityTone originalTone) async {
    if (_page == 1 && _tone == originalTone) {
      setState(() => _tone = _compassSignal.suggestedTone);
    }
    if (_page == 1) {
      final signal = _compassSignal;
      await ref.read(visionProvider.notifier).loadRecommendationsForArchetypes([
        signal.archetype,
      ]);
      if (!mounted) return;
      final recommendations = ref.read(visionProvider).recommendedTribes;
      if (recommendations.isNotEmpty) {
        setState(() {
          _tribe = recommendations.first;
          _identityIndex = 0;
        });
      }
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
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
            LinearProgressIndicator(value: (_page + 1) / 6),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Page(
                    icon: LucideIcons.sprout,
                    title: 'Name this season',
                    child: _SeasonQuestionView(
                      value: _currentSeason,
                      onChanged: (value) =>
                          setState(() => _currentSeason = value),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.compass,
                    title: 'Find your compass',
                    child: _CompassPatternView(
                      signal: _compassSignal,
                      pressurePattern: _pressurePattern,
                      postponedPattern: _postponedPattern,
                      peopleNeedPattern: _peopleNeedPattern,
                      formationPattern: _formationPattern,
                      onPressureChanged: (value) => setState(() {
                        _pressurePattern = value;
                        if (_tone == settings.accountabilityTone) {
                          _tone = _compassSignal.suggestedTone;
                        }
                      }),
                      onPostponedChanged: (value) =>
                          setState(() => _postponedPattern = value),
                      onPeopleNeedChanged: (value) =>
                          setState(() => _peopleNeedPattern = value),
                      onFormationChanged: (value) =>
                          setState(() => _formationPattern = value),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.slidersHorizontal,
                    title: 'Choose your support tone',
                    child: _ToneChoiceView(
                      value: _tone,
                      suggested: _compassSignal.suggestedTone,
                      signal: _compassSignal,
                      onChanged: (tone) => setState(() => _tone = tone),
                    ),
                  ),
                  _Page(
                    icon: LucideIcons.users,
                    title: 'Join a tribe',
                    child: _OnboardingRecoveryGate(
                      state: state,
                      emptyMessage:
                          'We could not load real tribe recommendations. Reconnect and try again before beginning.',
                      child: _TribeRecommendationCards(
                        tribes: state.recommendedTribes,
                        selected: _tribe,
                        signal: _compassSignal,
                        visibilityMode: _mode,
                        aliasController: _aliasController,
                        onVisibilityChanged: (mode) =>
                            setState(() => _mode = mode),
                        onSelected: (tribe) => setState(() => _tribe = tribe),
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
                            'Pick one concrete practice for this month. You can review, deepen, or switch when the season closes.',
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
                        const SizedBox(height: 14),
                        _MonthlyReviewCue(tone: _tone),
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
                          : _page == 5
                          ? _finish
                          : () => _goNext(settings.accountabilityTone),
                      child: _isFinishing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_page == 5 ? 'Begin' : 'Continue'),
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

class _CompassSignal {
  const _CompassSignal({
    required this.archetype,
    required this.season,
    required this.supportScore,
    required this.suggestedTone,
    this.topArchetypes = const [],
  });

  final String archetype;
  final List<String> topArchetypes;
  final String season;
  final int supportScore;
  final AccountabilityTone suggestedTone;
}

class _SeasonQuestionView extends StatelessWidget {
  const _SeasonQuestionView({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('Artisan', 'I need my creativity to become worship, not comparison'),
    ('Watchman', 'I need to rebuild attention, vigilance, and quiet'),
    ('Cultivator', 'I need patience, rest, and ordinary faithfulness'),
    ('Sower', 'I need courage to begin what I keep delaying'),
    ('Welcomer', 'I need warmer belonging with better boundaries'),
    ('Pillar', 'I need to serve faithfully without disappearing'),
    ('Sentinel', 'I need to turn insight and prayer into action'),
    ('Bridgebuilder', 'I need repair, peace, and honest connection'),
    ('Healer', 'I need healing, forgiveness, or supported hope'),
    ('Harvester', 'I need fruitfulness without metrics becoming my master'),
    ('Reformer', 'I need holy frustration to become constructive change'),
    ('Architect', 'I need order without control or perfectionism'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ChoiceStack(
      intro:
          'Start with what is actually happening. This helps ElBiblio recommend belonging and commitment without asking you to perform a label.',
      options: _options,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _CompassPatternView extends StatelessWidget {
  const _CompassPatternView({
    required this.signal,
    required this.pressurePattern,
    required this.postponedPattern,
    required this.peopleNeedPattern,
    required this.formationPattern,
    required this.onPressureChanged,
    required this.onPostponedChanged,
    required this.onPeopleNeedChanged,
    required this.onFormationChanged,
  });

  final _CompassSignal signal;
  final String? pressurePattern;
  final String? postponedPattern;
  final String? peopleNeedPattern;
  final String? formationPattern;
  final ValueChanged<String> onPressureChanged;
  final ValueChanged<String> onPostponedChanged;
  final ValueChanged<String> onPeopleNeedChanged;
  final ValueChanged<String> onFormationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer from lived experience. Your compass is a starting signal, not a permanent identity.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 18),
        _QuestionBlock(
          title: 'When pressure rises, I usually...',
          value: pressurePattern,
          options: const [
            ('Sentinel', 'Withdraw, observe, and process alone'),
            ('Architect', 'Try to control every variable'),
            ('Healer', 'Absorb everyone else\'s pain'),
            ('Watchman', 'Protect attention and boundaries'),
          ],
          onChanged: onPressureChanged,
        ),
        _QuestionBlock(
          title: 'The thing I keep postponing is...',
          value: postponedPattern,
          options: const [
            ('Sower', 'Beginning the thing I know matters'),
            ('Artisan', 'Finishing one creation before chasing novelty'),
            ('Bridgebuilder', 'Having an honest conversation'),
            ('Pillar', 'Taking a step for my own calling'),
          ],
          onChanged: onPostponedChanged,
        ),
        _QuestionBlock(
          title: 'People often come to me when they need...',
          value: peopleNeedPattern,
          options: const [
            ('Cultivator', 'Patient care and steady encouragement'),
            ('Welcomer', 'Warmth, welcome, and belonging'),
            ('Reformer', 'Courage to name what must change'),
            ('Harvester', 'Momentum, mobilizing, and celebration'),
          ],
          onChanged: onPeopleNeedChanged,
        ),
        _QuestionBlock(
          title: 'The distortion I most want God to interrupt is...',
          value: formationPattern,
          options: const [
            ('Welcomer', 'People-pleasing and avoiding truth'),
            ('Harvester', 'Measuring my worth by output or results'),
            ('Reformer', 'Outrage, bitterness, or tearing down'),
            ('Architect', 'Perfectionism and control disguised as order'),
          ],
          onChanged: onFormationChanged,
        ),
        const SizedBox(height: 14),
        _SignalCard(signal: signal),
      ],
    );
  }
}

class _ToneChoiceView extends StatelessWidget {
  const _ToneChoiceView({
    required this.value,
    required this.suggested,
    required this.signal,
    required this.onChanged,
  });

  final AccountabilityTone value;
  final AccountabilityTone suggested;
  final _CompassSignal signal;
  final ValueChanged<AccountabilityTone> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SignalCard(signal: signal),
        const SizedBox(height: 16),
        Text(
          'Suggested: ${suggested.label}. You can override it; this only controls how firm the app is with nudges, misses, and recommitment.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        ...AccountabilityTone.values.map((tone) {
          final selected = tone == value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(tone),
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
                      selected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tone.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(tone.description),
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

class _TribeRecommendationCards extends StatelessWidget {
  const _TribeRecommendationCards({
    required this.tribes,
    required this.selected,
    required this.signal,
    required this.visibilityMode,
    required this.aliasController,
    required this.onVisibilityChanged,
    required this.onSelected,
  });

  final List<TribeIdentity> tribes;
  final TribeIdentity? selected;
  final _CompassSignal signal;
  final VisibilityMode visibilityMode;
  final TextEditingController aliasController;
  final ValueChanged<VisibilityMode> onVisibilityChanged;
  final ValueChanged<TribeIdentity> onSelected;

  @override
  Widget build(BuildContext context) {
    if (tribes.isEmpty) {
      return const Text(
        'Your tribe recommendations will appear here once ElBiblio can read your compass and commitment catalog.',
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Belonging gives the commitment a place to be witnessed. This is your strongest match for this season; you can reassess later.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        ...tribes.take(1).map((tribe) {
          final isSelected = selected?.id == tribe.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelected(tribe),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          GrowthJourneyEvent.iconForKey(tribe.iconKey),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tribe.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected
                              ? LucideIcons.checkCircle
                              : LucideIcons.circle,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(tribe.description),
                    const SizedBox(height: 12),
                    _MiniInfoRow(
                      icon: LucideIcons.compass,
                      title: 'Why this fits',
                      body:
                          'Your ${signal.season.toLowerCase()} season points toward ${tribe.matchReason?.isNotEmpty == true ? tribe.matchReason! : tribe.displayName}.',
                    ),
                    const _MiniInfoRow(
                      icon: LucideIcons.calendarHeart,
                      title: 'Weekly rhythm',
                      body:
                          'Weekend reflection, daily pulse, and room to ask for support.',
                    ),
                    const _MiniInfoRow(
                      icon: LucideIcons.sprout,
                      title: 'Practice together',
                      body:
                          'One concrete commitment, one honest check-in, one shared reflection.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => onSelected(tribe),
                      icon: Icon(
                        isSelected
                            ? LucideIcons.checkCircle
                            : LucideIcons.users,
                        size: 18,
                      ),
                      label: Text(
                        isSelected ? 'Selected tribe' : 'Join this tribe',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        Text(
          'Privacy preview',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        VisibilityModePicker(
          value: visibilityMode,
          onChanged: onVisibilityChanged,
        ),
        if (visibilityMode == VisibilityMode.nickname ||
            visibilityMode == VisibilityMode.public) ...[
          const SizedBox(height: 12),
          TextField(
            controller: aliasController,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _ChoiceStack(
            options: options,
            value: value,
            onChanged: onChanged,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _ChoiceStack extends StatelessWidget {
  const _ChoiceStack({
    required this.options,
    required this.value,
    required this.onChanged,
    this.intro,
    this.compact = false,
  });

  final String? intro;
  final List<(String, String)> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro != null) ...[
          Text(
            intro!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
        ],
        ...options.map((option) {
          final selected = value == option.$1;
          return Padding(
            padding: EdgeInsets.only(bottom: compact ? 8 : 10),
            child: InkWell(
              onTap: () => onChanged(option.$1),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 12 : 14),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? LucideIcons.checkCircle : LucideIcons.circle,
                      size: 18,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(option.$2)),
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

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal});

  final _CompassSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            signal.season,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Compass signal: ${signal.archetype}. Support level: ${signal.supportScore}/100.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: body),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
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

class _MonthlyReviewCue extends StatelessWidget {
  const _MonthlyReviewCue({required this.tone});

  final AccountabilityTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final review = DateTime(now.year, now.month + 1, now.day);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.calendarClock, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Monthly review set for ${review.month}/${review.day}. You will choose whether to continue, deepen, or switch focus. Tone: ${tone.label}.',
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
