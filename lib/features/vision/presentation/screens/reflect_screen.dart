import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../application/vision_state.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(visionProvider.notifier).load(),
    );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Reflect')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visionProvider.notifier).load(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _ReflectHeader(state: state),
            const SizedBox(height: 16),
            if (active == null)
              VisionPanel(
                icon: LucideIcons.lock,
                title: 'Join a commitment to open the room',
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
                    const Text(
                      'Reflect is intentionally scoped. You share with people walking the same commitment, not a public crowd.',
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
            ],
          ],
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
    final active = state.activeCommitment;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messagesSquare,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reflect together',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            active == null
                ? 'A quieter reflection space opens after you choose a commitment.'
                : 'A private feed for ${active.plan.title}. Check in first, then share one honest sentence if it helps.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
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
                      : 'Check-in open',
                ),
                _ReflectStat(
                  icon: LucideIcons.messageCircle,
                  label: state.reflectionPostedToday
                      ? 'Shared today'
                      : 'One reflection',
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
