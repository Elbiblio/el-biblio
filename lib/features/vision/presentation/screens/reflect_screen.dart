import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../application/vision_state.dart';
import '../widgets/daily_verse_social_card.dart';
import '../widgets/reflection_feed_widgets.dart';
import '../widgets/vision_panel.dart';

class ReflectScreen extends ConsumerStatefulWidget {
  const ReflectScreen({super.key});

  @override
  ConsumerState<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends ConsumerState<ReflectScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(visionProvider.notifier).load();
      ref.read(dailyVerseSocialProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final active = state.activeCommitment;
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
            onRefresh: () async {
              await Future.wait([
                ref.read(visionProvider.notifier).load(force: true),
                ref.read(dailyVerseSocialProvider.notifier).refresh(),
              ]);
            },
            child: SafeListView(
              bottomPadding: shellChromeBottomPadding,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _ReflectHeader(state: state),
                const SizedBox(height: 14),
                if (state.error?.isNotEmpty == true) ...[
                  VisionPanel(
                    icon: LucideIcons.wifiOff,
                    title: 'Reflection feed needs a retry',
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (active == null)
                  VisionPanel(
                    icon: LucideIcons.lock,
                    title: 'Choose a commitment first',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: VisionIllustration(
                            asset: VisionIllustrationAsset.protection,
                            size: 86,
                            semanticLabel: 'Commitment required',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Open the room for one commitment. Share with people walking the same practice.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.palette.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.commit),
                          icon: const Icon(LucideIcons.flag, size: 18),
                          label: const Text('Choose commitment'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  VisionReflectionComposer(controller: _controller),
                  const SizedBox(height: 16),
                  const VisionReflectionFeed(),
                  const SizedBox(height: 16),
                  const DailyVerseSocialCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectHeader extends StatelessWidget {
  const _ReflectHeader({required this.state});

  final VisionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final active = state.activeCommitment;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
      decoration: BoxDecoration(
        color: tokens.palette.paper.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.82 : 0.9,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reflect',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      active == null
                          ? 'Choose a commitment to open its room.'
                          : '${active.plan.title} feed. Check in, then post.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.palette.textSecondary,
                        height: 1.42,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const VisionIllustration(
                asset: VisionIllustrationAsset.growth,
                size: 84,
                semanticLabel: 'Reflect',
              ),
            ],
          ),
          if (active != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReflectStat(
                  icon: LucideIcons.checkCircle,
                  label: active.checkedInToday
                      ? 'Checked in today'
                      : 'Check-in needed',
                ),
                _ReflectStat(
                  icon: LucideIcons.messageCircle,
                  label: state.reflectionPostedToday
                      ? 'Shared today'
                      : 'Post open',
                ),
                _ReflectStat(
                  icon: LucideIcons.heartHandshake,
                  label: '${state.feed.length} reflections',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectStat extends StatelessWidget {
  const _ReflectStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
