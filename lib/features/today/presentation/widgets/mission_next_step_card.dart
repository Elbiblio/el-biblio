import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../mission/domain/models/mission_focus.dart';

class MissionNextStepCard extends ConsumerWidget {
  const MissionNextStepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mission = ref.watch(missionProvider);
    final settings = ref.watch(settingsProvider);
    final nextAction = mission.nextAction;
    final hasPartner = mission.accountabilityPartner != null;
    final archetype = settings.primaryArchetypeId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One obvious next step',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nextAction?.title ?? 'Choose one step for today',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nextAction?.description ?? _fallbackCopy(mission.focus.label, archetype),
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.act),
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: Text(nextAction == null ? 'Open Act' : 'Continue'),
                ),
                if (hasPartner)
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.growTogether),
                    icon: const Icon(Icons.people_alt_rounded),
                    label: const Text('Check in'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.growTogether),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add partner'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackCopy(String focusLabel, String? archetype) {
    if ((archetype ?? '').isNotEmpty) {
      return 'Your $archetype calling becomes real when it shows up in one $focusLabel step today.';
    }
    return 'Choose one practical step you can complete today, then bring someone in.';
  }
}
