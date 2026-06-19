import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../vision/domain/vision_models.dart';
import '../../../vision/presentation/widgets/vision_panel.dart';

class SpeakScreen extends ConsumerStatefulWidget {
  const SpeakScreen({super.key});

  @override
  ConsumerState<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends ConsumerState<SpeakScreen> {
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

    return Scaffold(
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
                  'Speak',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'People, prayer, and presence.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                _CompanionCard(
                  onOpenCompanion: () => context.go(AppRoutes.companionChat),
                ),
                const SizedBox(height: 16),
                _TribeFeedCard(
                  tribe: state.primaryTribe,
                  pulse: state.tribePulse,
                  onOpenTribe: () => context.go(AppRoutes.tribe),
                ),
                const SizedBox(height: 16),
                _PrayerCard(
                  onOpenPrayer: () =>
                      context.go('${AppRoutes.spiritualAid}/prayers'),
                  onOpenSpiritualAid: () => context.go(AppRoutes.spiritualAid),
                ),
                const SizedBox(height: 16),
                _AccountabilityCard(
                  onOpenMission: () => context.go(AppRoutes.act),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.onOpenCompanion});

  final VoidCallback onOpenCompanion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.messageCircle,
      title: 'Your Companion',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your AI companion walks with you daily. Talk, reflect, and grow together.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenCompanion,
              icon: const Icon(LucideIcons.messageCircle, size: 16),
              label: const Text('Talk Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TribeFeedCard extends StatelessWidget {
  const _TribeFeedCard({
    required this.tribe,
    required this.pulse,
    required this.onOpenTribe,
  });

  final TribeMembership? tribe;
  final TribePulse pulse;
  final VoidCallback onOpenTribe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.users,
      title: 'Community',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe != null) ...[
            Text(
              '${pulse.activeMembersCount} active members today',
              style: theme.textTheme.bodyMedium?.copyWith(
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
          ] else ...[
            Text(
              'Connect with a tribe to share your journey.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenTribe,
              icon: const Icon(LucideIcons.eye, size: 16),
              label: const Text('Open Tribe'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.onOpenPrayer,
    required this.onOpenSpiritualAid,
  });

  final VoidCallback onOpenPrayer;
  final VoidCallback onOpenSpiritualAid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.bookOpen,
      title: 'Prayer & Reflection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick prayers, scripture, and guided reflection.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenPrayer,
                  icon: const Icon(LucideIcons.bookOpen, size: 16),
                  label: const Text('Prayers'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenSpiritualAid,
                  icon: const Icon(LucideIcons.sparkles, size: 16),
                  label: const Text('Soul Care'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountabilityCard extends StatelessWidget {
  const _AccountabilityCard({required this.onOpenMission});

  final VoidCallback onOpenMission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return VisionPanel(
      icon: LucideIcons.heartHandshake,
      title: 'Accountability',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partners, circles, and mission opportunities.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenMission,
              icon: const Icon(LucideIcons.target, size: 16),
              label: const Text('Mission & Service'),
            ),
          ),
        ],
      ),
    );
  }
}
