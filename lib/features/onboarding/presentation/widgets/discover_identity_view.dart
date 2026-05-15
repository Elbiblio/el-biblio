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
class DiscoverIdentityView extends ConsumerWidget {
  const DiscoverIdentityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final primary = notifier.primaryArchetype;

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
                'Find your current season.',
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
            'Answer from lived experience. ElBiblio will derive your strongest tribe match; you can reassess later.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.48,
            ),
          ),
          const SizedBox(height: 24),
          _AgeField(
            initialAge: state.exactAge,
            onChanged: notifier.setExactAge,
          ),
          const SizedBox(height: 24),
          _QuestionBlock(
            title: 'The pattern I want God to form in me this season is...',
            value: state.compassSeasonArchetype,
            options: CompassDiscoveryCatalog.seasonOptions,
            onChanged: notifier.setCompassSeasonArchetype,
          ),
          _QuestionBlock(
            title: 'When pressure rises, I usually...',
            value: state.compassPressureArchetype,
            options: CompassDiscoveryCatalog.pressureOptions,
            onChanged: notifier.setCompassPressureArchetype,
          ),
          _QuestionBlock(
            title: 'The thing I keep postponing is...',
            value: state.compassPostponedArchetype,
            options: CompassDiscoveryCatalog.postponedOptions,
            onChanged: notifier.setCompassPostponedArchetype,
          ),
          _QuestionBlock(
            title: 'People often come to me when they need...',
            value: state.compassPeopleNeedArchetype,
            options: CompassDiscoveryCatalog.peopleNeedOptions,
            onChanged: notifier.setCompassPeopleNeedArchetype,
          ),
          _QuestionBlock(
            title: 'The fear or distortion I most want God to interrupt is...',
            value: state.compassDistortionFearArchetype,
            options: CompassDiscoveryCatalog.distortionFearOptions,
            onChanged: notifier.setCompassDistortionFearArchetype,
          ),
          if (primary != null) ...[
            const SizedBox(height: 6),
            _CompassResultStory(primary: primary, state: state),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
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
        helperText: 'Private. Only the age band is sent with your compass.',
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

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String? value;
  final List<CompassDiscoveryOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 10),
          ...options.map((option) {
            final selected = value == option.archetype;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  HapticService.selection();
                  onChanged(option.archetype);
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
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
                            fontWeight: selected ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
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
            'Strongest signal: ${primary.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tribe direction: ${persona.tribe}. Season: ${state.compassSeasonName ?? 'Steady formation'}.',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is a current season signal, not a permanent label. We use it to recommend belonging, commitment, and the right support tone.',
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
