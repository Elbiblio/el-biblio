import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/light_rays_reveal.dart';
import '../../../assessment/domain/models/archetype.dart';
import '../../application/onboarding_notifier.dart';
import '../../application/onboarding_state.dart';

/// Step 3: Full spiritual compass. The exact age is private and only used
/// to derive an age band for age-aware questions after signup.
class DiscoverIdentityView extends ConsumerWidget {
  const DiscoverIdentityView({super.key});

  static const _instanceOptions = <int, String>{
    0: 'Not yet',
    3: 'A few times',
    10: 'Often',
    40: 'A practiced pattern',
    90: 'A deep pattern',
  };

  static const _fearOptions = <String, String>{
    'none': 'I am just noticing this',
    'some': 'I have wrestled with it',
    'many': 'It has shaped a season',
    'overcome': 'I have grown through it',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final selected = state.selectedArchetypeIds;
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
                'Your spirit grows in seasons.',
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
            'Start with your age privately, then name the ways God has already been forming you. We only store the age band.',
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
          Text(
            'Choose up to three compass markers',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick what feels recognizable, not impressive.',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          ...Archetype.allArchetypes.map(
            (archetype) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ArchetypeTile(
                archetype: archetype,
                selected: selected.contains(archetype.name),
                onTap: () {
                  HapticService.selection();
                  notifier.toggleCompassArchetype(archetype.name);
                },
              ),
            ),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Calibrate your spiritual age',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For each marker, tell the truth about practice and struggle. Growth is measured by formation, not years.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            ...selected.map((name) {
              final archetype = Archetype.allArchetypes.firstWhere(
                (item) => item.name == name,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CompassCalibrationCard(
                  archetype: archetype,
                  data: state.compassAssessmentData[name],
                  onChanged: (instances, fears) => notifier
                      .saveCompassArchetypeAssessment(name, instances, fears),
                ),
              );
            }),
          ],
          if (state.hasFullCompassResult && primary != null) ...[
            const SizedBox(height: 20),
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
    final theme = Theme.of(context);
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: 'Age',
        helperText: 'Private. Used only to derive your question age band.',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (value) {
        final age = int.tryParse(value);
        widget.onChanged(age);
      },
      validator: (value) {
        final age = int.tryParse(value ?? '');
        if (age == null || age < 13 || age > 120) {
          return 'Enter an age between 13 and 120';
        }
        return null;
      },
      style: theme.textTheme.titleMedium,
    );
  }
}

class _ArchetypeTile extends StatelessWidget {
  const _ArchetypeTile({
    required this.archetype,
    required this.selected,
    required this.onTap,
  });

  final Archetype archetype;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : theme.colorScheme.onSurface.withValues(alpha: 0.025),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.42)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${archetype.name} - ${archetype.identity}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      archetype.strengths.split(',').first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
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

class _CompassCalibrationCard extends StatelessWidget {
  const _CompassCalibrationCard({
    required this.archetype,
    required this.data,
    required this.onChanged,
  });

  final Archetype archetype;
  final OnboardingCompassData? data;
  final void Function(int instances, String fears) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instances = data?.instances ?? 0;
    final fears = data?.fears ?? 'none';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            archetype.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: instances,
            decoration: const InputDecoration(
              labelText: 'How often has this shown up?',
              border: OutlineInputBorder(),
            ),
            items: DiscoverIdentityView._instanceOptions.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => onChanged(value ?? instances, fears),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: fears,
            decoration: const InputDecoration(
              labelText: 'How have you met its struggle?',
              border: OutlineInputBorder(),
            ),
            items: DiscoverIdentityView._fearOptions.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => onChanged(instances, value ?? fears),
          ),
          if (data != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: data!.maturity / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
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
            'Your compass points toward ${primary.name}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spiritual age: ${state.spiritualAgeStage}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Everyone grows in spirit like a child learning to become mature. The soul struggles on that journey: physical pressure, mental heaviness, addiction, money strain, relational wounds, and hidden spiritual battles can all become part of formation. When the Holy Spirit is received, the heart is like soil with a planted seed. Some seasons are quiet roots, some are pruning, and some bear fruit in due season.',
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
