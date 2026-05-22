import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/light_rays_reveal.dart';
import '../../../assessment/domain/models/archetype.dart';
import '../../../assessment/domain/models/archetype_resonance.dart';
import '../../application/onboarding_notifier.dart';
import '../../application/onboarding_state.dart';
import '../../domain/compass_discovery_catalog.dart';

/// Step 3: situational compass discovery.
///
/// The user should not have to know their archetype before the app helps them
/// notice patterns. We derive the strongest tribe signal from ordinary
/// scenarios plus a fear/distortion selector.
enum _DiscoveryStep {
  age,
  seasonCluster,
  seasonDetail,
  pressure,
  postponed,
  peopleNeed,
  distortion,
  result,
}

class DiscoverIdentityView extends ConsumerStatefulWidget {
  const DiscoverIdentityView({super.key});

  @override
  ConsumerState<DiscoverIdentityView> createState() =>
      _DiscoverIdentityViewState();
}

class _DiscoverIdentityViewState extends ConsumerState<DiscoverIdentityView> {
  _DiscoveryStep _step = _DiscoveryStep.age;
  String? _seasonClusterId;
  bool _bootstrapped = false;

  void _bootstrap(OnboardingState state) {
    if (_bootstrapped) return;
    _step = _firstIncompleteStep(state);
    _seasonClusterId = CompassDiscoveryCatalog.clusterFor(
      state.compassSeasonArchetype,
    )?.id;
    _bootstrapped = true;
  }

  _DiscoveryStep _firstIncompleteStep(OnboardingState state) {
    if (state.exactAge == null) return _DiscoveryStep.age;
    if (state.compassSeasonArchetype == null) {
      return _DiscoveryStep.seasonCluster;
    }
    if (state.compassPressureArchetype == null) return _DiscoveryStep.pressure;
    if (state.compassPostponedArchetype == null) {
      return _DiscoveryStep.postponed;
    }
    if (state.compassPeopleNeedArchetype == null) {
      return _DiscoveryStep.peopleNeed;
    }
    if (state.compassDistortionFearArchetype == null) {
      return _DiscoveryStep.distortion;
    }
    return _DiscoveryStep.result;
  }

  void _back() {
    final index = _DiscoveryStep.values.indexOf(_step);
    if (index <= 0) return;
    setState(() => _step = _DiscoveryStep.values[index - 1]);
  }

  void _next() {
    final index = _DiscoveryStep.values.indexOf(_step);
    if (index >= _DiscoveryStep.values.length - 1) return;
    setState(() => _step = _DiscoveryStep.values[index + 1]);
  }

  void _selectOption(String archetype, ValueChanged<String> onChanged) {
    HapticService.selection();
    onChanged(archetype);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final primary = notifier.primaryArchetype;
    _bootstrap(state);

    final currentIndex = _DiscoveryStep.values.indexOf(_step);
    final questionCount = _DiscoveryStep.values.length - 1;
    final visibleIndex = currentIndex < questionCount
        ? currentIndex
        : questionCount - 1;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: LightRaysReveal(
              rotate: false,
              maxOpacity: 0.28,
              rayCount: 9,
              child: Text(
                'Find your compass.',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose the closest answer.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.48,
            ),
          ),
          const SizedBox(height: 24),
          _WizardFrame(
            current: visibleIndex + 1,
            total: questionCount,
            canGoBack: _step != _DiscoveryStep.age,
            onBack: _back,
            child: _buildStep(context, state, notifier, primary),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    OnboardingState state,
    OnboardingNotifier notifier,
    Archetype? primary,
  ) {
    final selectedCluster = CompassDiscoveryCatalog.clusterById(
      _seasonClusterId,
    );

    return switch (_step) {
      _DiscoveryStep.age => _AgeQuestion(
        initialAge: state.exactAge,
        onChanged: notifier.setExactAge,
        onContinue: state.exactAge == null ? null : _next,
      ),
      _DiscoveryStep.seasonCluster => _ClusterQuestion(
        title: 'What needs attention?',
        subtitle: 'Choose the closest area.',
        value: _seasonClusterId,
        clusters: CompassDiscoveryCatalog.seasonClusters,
        onChanged: (cluster) {
          HapticService.selection();
          setState(() {
            _seasonClusterId = cluster.id;
            _step = _DiscoveryStep.seasonDetail;
          });
        },
      ),
      _DiscoveryStep.seasonDetail => _OptionQuestion(
        title: 'Which sentence fits?',
        subtitle: selectedCluster?.description,
        value: state.compassSeasonArchetype,
        options: selectedCluster?.options ?? const [],
        onChanged: (value) =>
            _selectOption(value, notifier.setCompassSeasonArchetype),
      ),
      _DiscoveryStep.pressure => _OptionQuestion(
        title: 'When stress rises, what do you usually do first?',
        subtitle: 'Choose what happens first.',
        value: state.compassPressureArchetype,
        options: CompassDiscoveryCatalog.pressureOptionsFor([
          state.compassSeasonArchetype,
          state.compassPressureArchetype,
        ]),
        onChanged: (value) =>
            _selectOption(value, notifier.setCompassPressureArchetype),
      ),
      _DiscoveryStep.postponed => _OptionQuestion(
        title: 'What faithful step do you keep delaying?',
        subtitle: 'Delayed steps show the support you need.',
        value: state.compassPostponedArchetype,
        options: CompassDiscoveryCatalog.postponedOptionsFor([
          state.compassSeasonArchetype,
          state.compassPressureArchetype,
          state.compassPostponedArchetype,
        ]),
        onChanged: (value) =>
            _selectOption(value, notifier.setCompassPostponedArchetype),
      ),
      _DiscoveryStep.peopleNeed => _OptionQuestion(
        title: 'What do people tend to trust you with?',
        subtitle: 'Think about what people bring to you.',
        value: state.compassPeopleNeedArchetype,
        options: CompassDiscoveryCatalog.peopleNeedOptionsFor([
          state.compassSeasonArchetype,
          state.compassPressureArchetype,
          state.compassPostponedArchetype,
          state.compassPeopleNeedArchetype,
        ]),
        onChanged: (value) =>
            _selectOption(value, notifier.setCompassPeopleNeedArchetype),
      ),
      _DiscoveryStep.distortion => _OptionQuestion(
        title: 'What can twist this gift?',
        subtitle: 'This shapes your first commitment.',
        value: state.compassDistortionFearArchetype,
        options: CompassDiscoveryCatalog.distortionOptionsFor([
          state.compassSeasonArchetype,
          state.compassPressureArchetype,
          state.compassPostponedArchetype,
          state.compassPeopleNeedArchetype,
          state.compassDistortionFearArchetype,
        ]),
        onChanged: (value) =>
            _selectOption(value, notifier.setCompassDistortionFearArchetype),
      ),
      _DiscoveryStep.result =>
        primary == null
            ? _OptionQuestion(
                title: 'One more answer is needed',
                subtitle: 'Answer the previous question.',
                value: null,
                options: const [],
                onChanged: (_) {},
              )
            : _CompassResultStory(primary: primary, state: state),
    };
  }
}

class _AgeField extends StatefulWidget {
  const _AgeField({required this.initialAge, required this.onChanged});

  final int? initialAge;
  final ValueChanged<int?> onChanged;

  @override
  State<_AgeField> createState() => _AgeFieldState();
}

class _AgeFieldState extends State<_AgeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAge?.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: 'Age',
        helperText: 'Private. Age band only.',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) => widget.onChanged(int.tryParse(value)),
      validator: (value) {
        final age = int.tryParse(value ?? '');
        if (age == null || age < 13 || age > 120) {
          return 'Enter an age between 13 and 120';
        }
        return null;
      },
    );
  }
}

class _WizardFrame extends StatelessWidget {
  const _WizardFrame({
    required this.current,
    required this.total,
    required this.canGoBack,
    required this.onBack,
    required this.child,
  });

  final int current;
  final int total;
  final bool canGoBack;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: Column(
        key: ValueKey(current),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (canGoBack)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: LinearProgressIndicator(
                  value: current / total,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: theme.colorScheme.outline.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Question $current of $total',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AgeQuestion extends StatelessWidget {
  const _AgeQuestion({
    required this.initialAge,
    required this.onChanged,
    required this.onContinue,
  });

  final int? initialAge;
  final ValueChanged<int?> onChanged;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QuestionHeader(
          title: 'How old are you?',
          subtitle: 'Used only for age-aware support.',
        ),
        const SizedBox(height: 14),
        _AgeField(initialAge: initialAge, onChanged: onChanged),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onContinue,
            child: Text(
              'Continue',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClusterQuestion extends StatelessWidget {
  const _ClusterQuestion({
    required this.title,
    required this.value,
    required this.clusters,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final List<CompassDiscoveryCluster> clusters;
  final ValueChanged<CompassDiscoveryCluster> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        ...clusters.map(
          (cluster) => _ClusterTile(
            cluster: cluster,
            selected: value == cluster.id,
            onTap: () => onChanged(cluster),
          ),
        ),
      ],
    );
  }
}

class _OptionQuestion extends StatelessWidget {
  const _OptionQuestion({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final List<CompassDiscoveryOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        ...options.map(
          (option) => _OptionTile(
            option: option,
            selected: value == option.archetype,
            onTap: () => onChanged(option.archetype),
          ),
        ),
      ],
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.14,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _ClusterTile extends StatelessWidget {
  const _ClusterTile({
    required this.cluster,
    required this.selected,
    required this.onTap,
  });

  final CompassDiscoveryCluster cluster;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface.withValues(alpha: 0.74),
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
                selected
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                size: 19,
                color: selected ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.32,
                        fontWeight: selected ? FontWeight.w800 : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cluster.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CompassDiscoveryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface.withValues(alpha: 0.74),
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
                selected
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                size: 19,
                color: selected ? theme.colorScheme.primary : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.32,
                    fontWeight: selected ? FontWeight.w800 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassResultStory extends StatelessWidget {
  const _CompassResultStory({required this.primary, required this.state});

  final Archetype primary;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final persona = ArchetypeResonances.resolveFromOrderedNames(
      state.selectedArchetypeIds,
    );
    final calling = CompassDiscoveryCatalog.callingFor(primary.name);
    final distortions = CompassDiscoveryCatalog.distortionFor(primary.name);
    final maturity = CompassDiscoveryCatalog.maturitySentence(
      state.spiritualAgeScore,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calling: ${primary.identity}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tribe: ${persona.tribe}. Focus: ${state.compassSeasonName ?? 'Steady formation'}.',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Called $calling.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Stage: ${state.spiritualAgeStage}. $maturity',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Watch for: $distortions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
