import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_notifier.dart';
import '../../application/onboarding_state.dart';
import '../../../assessment/domain/models/archetype.dart';
import '../../../connect/domain/models/christian_tradition.dart';
import 'discover_identity_view.dart';

class ConnectView extends ConsumerStatefulWidget {
  const ConnectView({super.key});

  @override
  ConsumerState<ConnectView> createState() => _ConnectViewState();
}

enum _ConnectPhase { compass, tradition, prayerStyle, summary }

class _ConnectViewState extends ConsumerState<ConnectView> {
  _ConnectPhase _phase = _ConnectPhase.compass;

  @override
  Widget build(BuildContext context) {
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
          _phase == _ConnectPhase.compass
              ? const DiscoverIdentityView()
              : _buildAfterCompass(theme, textTheme, state, notifier, primary),
        ],
      ),
    );
  }

  Widget _buildAfterCompass(
    ThemeData theme,
    TextTheme textTheme,
    OnboardingState state,
    OnboardingNotifier notifier,
    Archetype? primary,
  ) {
    if (primary == null) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Complete your compass first.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() => _phase = _ConnectPhase.compass),
            child: const Text('Back to compass'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Compass complete: ${primary.identity}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _phase == _ConnectPhase.tradition
            ? _TraditionSelector(
                value: state.tradition,
                onChanged: (v) {
                  notifier.setTradition(v);
                  setState(() => _phase = _ConnectPhase.prayerStyle);
                },
              )
            : _phase == _ConnectPhase.prayerStyle
                ? _PrayerStyleSelector(
                    value: state.prayerStyle,
                    onChanged: (v) {
                      notifier.setPrayerStyle(v);
                      setState(() => _phase = _ConnectPhase.summary);
                    },
                  )
                : _IdentitySummary(
                    state: state,
                    primary: primary,
                    onEditTradition: () => setState(
                      () => _phase = _ConnectPhase.tradition,
                    ),
                    onEditPrayerStyle: () => setState(
                      () => _phase = _ConnectPhase.prayerStyle,
                    ),
                    onRevisitCompass: () => setState(
                      () => _phase = _ConnectPhase.compass,
                    ),
                  ),
      ],
    );
  }
}

class _TraditionSelector extends StatelessWidget {
  const _TraditionSelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Christian Tradition',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Optional. Helps us suggest content that fits.',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...ChristianTradition.values.map((tradition) {
          final selected = value == tradition.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onChanged(tradition.name),
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
                            tradition.label,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: selected ? FontWeight.w800 : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tradition.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.58,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Skip — I\'ll set this later'),
          ),
        ),
      ],
    );
  }
}

class _PrayerStyleSelector extends StatelessWidget {
  const _PrayerStyleSelector({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _styles = [
    ('contemplative', 'Contemplative', 'Silence, meditation, listening prayer'),
    ('liturgical', 'Liturgical', 'Structured prayers, liturgy, written forms'),
    ('spontaneous', 'Spontaneous', 'Free-flowing, conversational prayer'),
    ('varied', 'Varied', 'Different styles depending on the day'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prayer Style',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'How do you usually pray?',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        ..._styles.map((entry) {
          final id = entry.$1;
          final label = entry.$2;
          final description = entry.$3;
          final selected = value == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onChanged(id),
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
                            label,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: selected ? FontWeight.w800 : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: textTheme.bodySmall?.copyWith(
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
        }),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Not sure yet'),
          ),
        ),
      ],
    );
  }
}

class _IdentitySummary extends StatelessWidget {
  const _IdentitySummary({
    required this.state,
    required this.primary,
    required this.onEditTradition,
    required this.onEditPrayerStyle,
    required this.onRevisitCompass,
  });

  final OnboardingState state;
  final Archetype primary;
  final VoidCallback onEditTradition;
  final VoidCallback onEditPrayerStyle;
  final VoidCallback onRevisitCompass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final traditionLabel = state.tradition != null
        ? ChristianTradition.fromString(state.tradition!).label
        : null;

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
            'Your Spiritual Identity',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _IdentityRow(
            label: 'Archetype',
            value: primary.identity,
            onEdit: onRevisitCompass,
          ),
          const SizedBox(height: 8),
          _IdentityRow(
            label: 'Tradition',
            value: traditionLabel ?? 'Not set',
            onEdit: onEditTradition,
          ),
          const SizedBox(height: 8),
          _IdentityRow(
            label: 'Prayer Style',
            value: state.prayerStyle != null
                ? state.prayerStyle!
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((w) => w.isNotEmpty
                        ? '${w[0].toUpperCase()}${w.substring(1)}'
                        : '')
                    .join(' ')
                : 'Not set',
            onEdit: onEditPrayerStyle,
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re a ${primary.identity}. This is who you are — your strengths, your struggles, your way of connecting with God.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
      ],
    );
  }
}
