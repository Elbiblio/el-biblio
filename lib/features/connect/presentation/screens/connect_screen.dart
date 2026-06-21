import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/ambient_scope.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../assessment/domain/models/archetype.dart';
import '../../../vision/domain/vision_models.dart';
import '../../../vision/presentation/widgets/vision_panel.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visionProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final settings = ref.watch(settingsProvider);
    final archetypeId = settings.primaryArchetypeId;
    final archetype = archetypeId != null
        ? Archetype.allArchetypes.where((a) => a.name == archetypeId).firstOrNull
        : null;

    return AmbientScope(
      asset: SoundService.ambientCommunityAsset,
      volume: 0.07,
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: tokens.pageGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(visionProvider.notifier).load(force: true),
            child: SafeListView(
              bottomPadding: shellChromeBottomPadding,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  'Connect',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Who you are and who you walk with.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _IdentityCard(
                  archetype: archetype,
                  onReassess: () => context.push(AppRoutes.assessment),
                ),
                const SizedBox(height: 16),
                _TribeCard(
                  tribe: state.primaryTribe,
                  pulse: state.tribePulse,
                  onOpenTribe: () => context.push(AppRoutes.tribe),
                  onFindTribe: () => context.push(AppRoutes.tribe),
                ),
                const SizedBox(height: 16),
                _GrowthJourneyCard(
                  onWeeklyAssessment: () =>
                      context.push(AppRoutes.weeklyAssessment),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.archetype,
    required this.onReassess,
  });

  final Archetype? archetype;
  final VoidCallback onReassess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.compass,
      title: 'Your Identity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (archetype != null) ...[
            Text(
              archetype!.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              archetype!.identity,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              archetype!.strengths,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ] else ...[
            Text(
              'Discover your spiritual archetype',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReassess,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reassess'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TribeCard extends StatelessWidget {
  const _TribeCard({
    required this.tribe,
    required this.pulse,
    required this.onOpenTribe,
    required this.onFindTribe,
  });

  final TribeMembership? tribe;
  final TribePulse pulse;
  final VoidCallback onOpenTribe;
  final VoidCallback onFindTribe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.users,
      title: 'Your Tribe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe != null) ...[
            Text(
              tribe!.tribe.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${pulse.activeMembersCount} active today',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            if (pulse.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final item in pulse.items.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        GrowthJourneyEvent.iconForKey(item.iconKey),
                        size: 16,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenTribe,
                icon: const Icon(LucideIcons.eye, size: 16),
                label: const Text('View Tribe'),
              ),
            ),
          ] else ...[
            Text(
              'Join a tribe to grow together.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onFindTribe,
                icon: const Icon(LucideIcons.search, size: 16),
                label: const Text('Find a Tribe'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrowthJourneyCard extends StatelessWidget {
  const _GrowthJourneyCard({
    required this.onWeeklyAssessment,
  });

  final VoidCallback onWeeklyAssessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.trendingUp,
      title: 'Growth Journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track your spiritual growth with weekly check-ins.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onWeeklyAssessment,
              icon: const Icon(LucideIcons.calendar, size: 16),
              label: const Text('Weekly Assessment'),
            ),
          ),
        ],
      ),
    );
  }
}
