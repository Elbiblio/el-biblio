import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../application/companion_notifier.dart';
import '../../domain/models/companion_character.dart';
import '../../domain/models/companion_mood.dart';
import '../widgets/companion_haptics.dart';
import '../widgets/companion_orb.dart';

/// Post-onboarding page where the user picks a companion. Recommended character
/// (based on archetype + commitment category) is pre-highlighted.
///
/// Skipping → Naomi is set as the default.
class CompanionSelectionScreen extends ConsumerStatefulWidget {
  const CompanionSelectionScreen({
    super.key,
    required this.onContinue,
    this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback? onSkip;

  @override
  ConsumerState<CompanionSelectionScreen> createState() =>
      _CompanionSelectionScreenState();
}

class _CompanionSelectionScreenState
    extends ConsumerState<CompanionSelectionScreen> {
  CompanionCharacter? _hovered;

  @override
  void initState() {
    super.initState();
    // Pre-select based on archetype / category.
    final settings = ref.read(settingsProvider);
    final recommended = CompanionRecommendation.forProfile(
      archetypeId: settings.primaryArchetypeId,
      commitmentCategory: settings.commitmentCategory,
    );
    _hovered = recommended;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companionState = ref.watch(companionProvider);
    final active = companionState.activeCharacter ?? _hovered;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Meet your companion',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Someone to walk with you — through Scripture, questions, and the ordinary weeks.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: CompanionOrb(
                key: ValueKey(active?.code ?? 'none'),
                character: active ?? CompanionCharacter.naomi,
                mood: CompanionMood.warm,
                size: 128,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            active?.displayName ?? 'Choose a companion',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (active != null) ...[
            Text(
              active.tagline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                active.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.55,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final c in CompanionCharacter.values) ...[
                _CharacterChoice(
                  character: c,
                  isSelected: (active ?? _hovered) == c,
                  onTap: () {
                    CompanionHaptics.acknowledge(c);
                    setState(() => _hovered = c);
                  },
                ),
                if (c != CompanionCharacter.values.last)
                  const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_hovered == null)
                  ? null
                  : () async {
                      await ref
                          .read(companionProvider.notifier)
                          .select(_hovered!);
                      if (!mounted) return;
                      widget.onContinue();
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Walk with ${(_hovered ?? CompanionCharacter.naomi).displayName}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await ref
                  .read(companionProvider.notifier)
                  .applyDefaultIfUnset();
              if (!mounted) return;
              (widget.onSkip ?? widget.onContinue)();
            },
            child: Text(
              'Not sure — Naomi will walk with me',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CharacterChoice extends StatelessWidget {
  const _CharacterChoice({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  final CompanionCharacter character;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.25),
            width: isSelected ? 2.2 : 1.2,
          ),
        ),
        child: CompanionOrb(
          character: character,
          mood: isSelected ? CompanionMood.attentive : CompanionMood.idle,
          size: 56,
        ),
      ),
    );
  }
}
