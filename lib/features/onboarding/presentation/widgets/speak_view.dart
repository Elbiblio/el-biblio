import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/onboarding_notifier.dart';
import '../../../companion/domain/models/companion_character.dart';

class SpeakView extends ConsumerWidget {
  const SpeakView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Who walks with you?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a companion to journey alongside you.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 28),
          ...CompanionCharacter.values.map(
            (character) => _CompanionCard(
              character: character,
              isSelected: state.selectedCompanionId == character.code,
              onTap: () => notifier.setSelectedCompanionId(character.code),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Accountability',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'How supported do you want to be?',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          _AccountabilityChip(
            label: 'Solo',
            subtitle: 'Just me and my companion',
            icon: Icons.person_outline,
            isSelected: state.accountabilityLevel == 'solo',
            onTap: () => notifier.setAccountabilityLevel('solo'),
          ),
          const SizedBox(height: 8),
          _AccountabilityChip(
            label: 'Partner',
            subtitle: 'I have an accountability partner',
            icon: Icons.people_outline,
            isSelected: state.accountabilityLevel == 'partner',
            onTap: () => notifier.setAccountabilityLevel('partner'),
          ),
          const SizedBox(height: 8),
          _AccountabilityChip(
            label: 'Circle',
            subtitle: 'I want to join or start a prayer circle',
            icon: Icons.groups_outlined,
            isSelected: state.accountabilityLevel == 'circle',
            onTap: () => notifier.setAccountabilityLevel('circle'),
          ),
          if (state.selectedCompanionId != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You\'re not alone. ${_companionName(state.selectedCompanionId)} walks with you.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _companionName(String? id) {
    return switch (id) {
      'raziel' => 'Raziel',
      'naomi' => 'Naomi',
      'james' => 'James',
      _ => 'Your companion',
    };
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({
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
    final textTheme = theme.textTheme;
    final gradientColors = character.gradientStops;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? gradientColors.first.withValues(alpha: 0.08)
                : theme.colorScheme.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? gradientColors.first
                  : theme.colorScheme.outline.withValues(alpha: 0.14),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    character.displayName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.displayName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      character.tagline,
                      style: textTheme.labelSmall?.copyWith(
                        color: gradientColors.first,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      character.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: gradientColors.first,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountabilityChip extends StatelessWidget {
  const _AccountabilityChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
