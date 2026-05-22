import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/safe_bottom_padding.dart';
import '../../../../shared/widgets/premium_success_dialog.dart';
import '../../../../shared/widgets/vision_illustration.dart';
import '../../../onboarding/domain/compass_discovery_catalog.dart';
import '../../application/vision_state.dart';
import '../../domain/vision_models.dart';
import '../widgets/vision_action_tile.dart';
import '../widgets/visibility_mode_picker.dart';
import '../widgets/vision_panel.dart';
import 'hangout_room_screen.dart';

class TribeScreen extends ConsumerStatefulWidget {
  const TribeScreen({super.key});

  @override
  ConsumerState<TribeScreen> createState() => _TribeScreenState();
}

class _TribeScreenState extends ConsumerState<TribeScreen> {
  final _aliasController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _hangoutKey = GlobalKey();
  final _weeklyKey = GlobalKey();
  VisibilityMode _mode = VisibilityMode.anonymous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _syncVisibilityFields(ref.read(visionProvider));
      await ref.read(visionProvider.notifier).load();
      if (!mounted) return;
      _syncVisibilityFields(ref.read(visionProvider));
    });
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _weeklyController.dispose();
    super.dispose();
  }

  void _syncVisibilityFields(VisionState state) {
    final alias = state.visibilityAlias == 'Anonymous'
        ? ''
        : state.visibilityAlias;
    setState(() {
      _mode = state.visibilityMode;
      if (_aliasController.text != alias) {
        _aliasController.text = alias;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final hasTribe = state.primaryTribe != null;

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
              bottomPadding: 150,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _TribeHero(
                  state: state,
                  onVisibilityPressed: _openVisibilitySettings,
                ),
                if (state.error?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  VisionPanel(
                    icon: LucideIcons.wifiOff,
                    title: state.isReadOnly
                        ? 'Reconnect to join a tribe'
                        : 'Tribe needs a retry',
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _CompassContextPanel(),
                if (!hasTribe) ...[
                  const SizedBox(height: 14),
                  _RecommendedTribesList(),
                  const SizedBox(height: 14),
                  const _TribeFeaturePreview(),
                ] else ...[
                  const SizedBox(height: 14),
                  _TribeActionTiles(
                    hangoutKey: _hangoutKey,
                    weeklyKey: _weeklyKey,
                  ),
                  const SizedBox(height: 14),
                  _PulsePanel(),
                  const SizedBox(height: 14),
                  _TribeGamesPanel(),
                  const SizedBox(height: 14),
                  _TribeHangoutPanel(key: _hangoutKey),
                  const SizedBox(height: 14),
                  _WeeklyReflectionHub(
                    key: _weeklyKey,
                    controller: _weeklyController,
                  ),
                  if (state.recommendedTribes.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _OtherTribesEntryPanel(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVisibilitySettings() {
    var localMode = _mode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'How I appear',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the name people see in your tribe and commitment feed.',
                  ),
                  const SizedBox(height: 16),
                  VisibilityModePicker(
                    value: localMode,
                    onChanged: (mode) => setModalState(() => localMode = mode),
                  ),
                  if (localMode == VisibilityMode.nickname ||
                      localMode == VisibilityMode.public) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aliasController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() => _mode = localMode);
                      final saved = await ref
                          .read(visionProvider.notifier)
                          .setVisibility(
                            localMode,
                            alias: _aliasController.text,
                          );
                      if (!mounted || !context.mounted) return;
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            saved
                                ? 'Visibility updated.'
                                : 'We could not save visibility. Please try again.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TribeHero extends StatelessWidget {
  const _TribeHero({required this.state, required this.onVisibilityPressed});

  final VisionState state;
  final VoidCallback onVisibilityPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final tribe = state.primaryTribe;
    final hasTribe = tribe != null;

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
                      hasTribe ? tribe.tribe.displayName : 'Find your tribe',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasTribe
                          ? 'Posting as ${tribe.displayAlias}. Belonging gives your commitment a place to be witnessed.'
                          : 'Belonging before performance. Choose the circle that matches your formation season.',
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
                asset: VisionIllustrationAsset.belonging,
                size: 86,
                semanticLabel: 'Belonging',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TribePill(
                icon: hasTribe ? LucideIcons.users : LucideIcons.compass,
                label: hasTribe ? 'Primary tribe' : 'Recommendations',
              ),
              _TribePill(
                icon: LucideIcons.eye,
                label: state.visibilityMode.label,
              ),
              if (hasTribe)
                _TribePill(icon: LucideIcons.user, label: tribe.displayAlias),
              IconButton.filledTonal(
                tooltip: 'How I appear',
                onPressed: onVisibilityPressed,
                icon: const Icon(LucideIcons.settings2, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TribePill extends StatelessWidget {
  const _TribePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _TribeActionTiles extends ConsumerWidget {
  const _TribeActionTiles({required this.hangoutKey, required this.weeklyKey});

  final GlobalKey hangoutKey;
  final GlobalKey weeklyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribeId = state.primaryTribe?.tribe.id;
    return VisionPanel(
      icon: LucideIcons.sparkles,
      title: 'Tribe actions',
      child: VisionActionTileColumn(
        children: [
          VisionActionTile(
            icon: LucideIcons.send,
            title: 'Invite',
            subtitle: state.primaryTribe?.tribe.displayName ?? 'Tribe',
            onTap: () => context.push(
              tribeId == null
                  ? AppRoutes.invite
                  : '${AppRoutes.invite}?source=tribe&tribe_id=$tribeId',
            ),
            dense: true,
          ),
          VisionActionTile(
            icon: LucideIcons.gamepad2,
            title: 'Play together',
            subtitle: '${state.gameScores.length} scores this week',
            onTap: () => context.push(AppRoutes.games),
            dense: true,
          ),
          VisionActionTile(
            icon: LucideIcons.radio,
            title: 'Hangout',
            subtitle: '${state.hangouts.length} rooms visible',
            onTap: () => _scrollTo(hangoutKey),
            dense: true,
          ),
          VisionActionTile(
            icon: LucideIcons.calendarHeart,
            title: 'Weekly reflection',
            subtitle: '${state.weeklyReflections.length} posted',
            onTap: () => _scrollTo(weeklyKey),
            dense: true,
          ),
        ],
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

class _RecommendedTribesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final currentTribeId = state.primaryTribe?.tribe.id;
    final tribes = state.recommendedTribes
        .where((tribe) => tribe.id != currentTribeId)
        .toList(growable: false);

    if (tribes.isEmpty) {
      if (state.primaryTribe != null) return const SizedBox.shrink();
      return VisionPanel(
        icon: LucideIcons.users,
        title: 'Tribe recommendations',
        child: Text(
          state.isReadOnly
              ? 'Reconnect to see real tribe recommendations.'
              : 'No tribe recommendations are available yet.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.primaryTribe == null ? 'Recommended tribes' : 'Other tribes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...tribes.map((tribe) => _RecommendedTribeCard(tribe: tribe)),
      ],
    );
  }
}

class _OtherTribesEntryPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final currentTribeId = state.primaryTribe?.tribe.id;
    final tribes = state.recommendedTribes
        .where((tribe) => tribe.id != currentTribeId)
        .toList(growable: false);
    if (tribes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return VisionPanel(
      icon: LucideIcons.map,
      title: 'Explore another tribe',
      trailing: Text('${tribes.length} available'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your current tribe stays primary. Open this only when you are intentionally reassessing where you belong this season.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showOtherTribesSheet(context, tribes),
            icon: const Icon(LucideIcons.compass, size: 18),
            label: const Text('View tribe guide'),
          ),
        ],
      ),
    );
  }

  void _showOtherTribesSheet(BuildContext context, List<TribeIdentity> tribes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OtherTribesSheet(tribes: tribes),
    );
  }
}

class _OtherTribesSheet extends StatelessWidget {
  const _OtherTribesSheet({required this.tribes});

  final List<TribeIdentity> tribes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Tribe guide',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A different tribe should feel like a real reassessment, not casual browsing. Read the fit note, then join only if this season has changed.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            const SizedBox(height: 16),
            ...tribes.map((tribe) => _OtherTribeTile(tribe: tribe)),
          ],
        );
      },
    );
  }
}

class _OtherTribeTile extends ConsumerWidget {
  const _OtherTribeTile({required this.tribe});

  final TribeIdentity tribe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.tokens.palette.paper.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.78 : 0.9,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconForTribe(tribe),
                  color: theme.colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tribe.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _whoShouldJoin(tribe),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.tokens.palette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tribe.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (tribe.matchReason?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _MiniTribeNote(icon: LucideIcons.compass, text: tribe.matchReason!),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: state.isLoading
                ? null
                : () async {
                    final joined = await ref
                        .read(visionProvider.notifier)
                        .joinTribe(tribe);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    if (!joined) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'We could not join this tribe. Please try again.',
                          ),
                        ),
                      );
                      return;
                    }
                    await PremiumSuccessDialog.show(
                      context,
                      title: 'You joined ${tribe.displayName}',
                      message:
                          'Your tribe has been updated for this season of formation.',
                      primaryActionText: 'Continue',
                    );
                  },
            icon: const Icon(LucideIcons.users, size: 18),
            label: const Text('Join this tribe'),
          ),
        ],
      ),
    );
  }
}

class _MiniTribeNote extends StatelessWidget {
  const _MiniTribeNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _RecommendedTribeCard extends ConsumerWidget {
  const _RecommendedTribeCard({required this.tribe});

  final TribeIdentity tribe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final joined = state.primaryTribe?.tribe.id == tribe.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.tokens.palette.paper.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.78 : 0.9,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconForTribe(tribe),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tribe.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (tribe.matchScore > 0)
                Text(
                  '${tribe.matchScore}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tribe.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
          ),
          if (tribe.matchReason?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.compass,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tribe.matchReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.tokens.palette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: joined || state.isLoading
                ? null
                : () async {
                    final joined = await ref
                        .read(visionProvider.notifier)
                        .joinTribe(tribe);
                    if (!context.mounted) return;
                    if (!joined) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'We could not join this tribe. Please try again.',
                          ),
                        ),
                      );
                      return;
                    }
                    await PremiumSuccessDialog.show(
                      context,
                      title: 'You joined ${tribe.displayName}',
                      message:
                          'Your commitment and reflections now have a place of belonging.',
                      primaryActionText: 'Continue',
                    );
                  },
            icon: Icon(
              joined ? LucideIcons.checkCircle : LucideIcons.users,
              size: 18,
            ),
            label: Text(joined ? 'Joined' : 'Join tribe'),
          ),
        ],
      ),
    );
  }
}

class _TribeFeaturePreview extends StatelessWidget {
  const _TribeFeaturePreview();

  @override
  Widget build(BuildContext context) {
    return const VisionPanel(
      icon: LucideIcons.sparkles,
      title: 'What opens after joining',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeaturePreviewRow(
            icon: LucideIcons.activity,
            title: 'Daily pulse',
            body: 'See check-ins and small signs of life in your circle.',
          ),
          _FeaturePreviewRow(
            icon: LucideIcons.calendarHeart,
            title: 'Weekend reflection',
            body: 'Mark what the week formed and save what you want to carry.',
          ),
          _FeaturePreviewRow(
            icon: LucideIcons.radio,
            title: 'Live hangouts',
            body: 'Start or join voice rooms for prayer and encouragement.',
          ),
        ],
      ),
    );
  }
}

class _FeaturePreviewRow extends StatelessWidget {
  const _FeaturePreviewRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.tokens.palette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassContextPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (settings.spiritualAgeScore <= 0 &&
        settings.selectedArchetypeIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final archetypes = settings.selectedArchetypeIds.isNotEmpty
        ? settings.selectedArchetypeIds.take(2).join(' + ')
        : settings.primaryArchetypeId ?? 'your compass';
    final primary = settings.primaryArchetypeId;
    final calling = primary == null
        ? 'to practice steady faithfulness in this season'
        : CompassDiscoveryCatalog.callingFor(primary);
    final distortions = primary == null
        ? 'avoidance, distraction, and trying to grow alone'
        : CompassDiscoveryCatalog.distortionFor(primary);
    final maturity = CompassDiscoveryCatalog.maturitySentence(
      settings.spiritualAgeScore,
    );

    return VisionPanel(
      icon: LucideIcons.compass,
      title: 'Compass context',
      trailing: TextButton.icon(
        onPressed: () => context.push('${AppRoutes.assessment}/compass'),
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        label: const Text('Retake'),
      ),
      child: Text(
        'Your current compass is $archetypes. One calling we see is $calling. Detected maturity: ${settings.spiritualAgeStage}. $maturity Likely worldly distortions to watch: $distortions.',
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
      ),
    );
  }
}

class _WeeklyReflectionHub extends ConsumerWidget {
  const _WeeklyReflectionHub({super.key, required this.controller});

  final TextEditingController controller;

  bool get _isWeekend {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    final theme = Theme.of(context);
    final bookmarkedCount = state.weeklyReflections
        .where((item) => item.bookmarkedByMe)
        .length;

    return VisionPanel(
      icon: LucideIcons.calendarHeart,
      title: 'Weekend reflection',
      trailing: tribe == null
          ? null
          : TextButton.icon(
              onPressed: () => _openHub(context),
              icon: const Icon(LucideIcons.arrowUpRight, size: 16),
              label: const Text('Open'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe == null)
            const Text('Join a tribe to share a weekend reflection.')
          else ...[
            Text(
              _isWeekend
                  ? 'A slower place for what this week formed in ${tribe.tribe.displayName}.'
                  : 'It opens Saturday and Sunday. Read or save anything you want to carry forward.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WeeklyPill(
                  icon: LucideIcons.messageCircle,
                  label: '${state.weeklyReflections.length} shared',
                ),
                _WeeklyPill(
                  icon: LucideIcons.bookmark,
                  label: '$bookmarkedCount saved',
                ),
                _WeeklyPill(
                  icon: _isWeekend ? LucideIcons.unlock : LucideIcons.lock,
                  label: _isWeekend ? 'Open now' : 'Weekend',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openHub(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _WeeklyReflectionSheet(controller: controller, isWeekend: _isWeekend),
    );
  }
}

class _WeeklyReflectionSheet extends ConsumerWidget {
  const _WeeklyReflectionSheet({
    required this.controller,
    required this.isWeekend,
  });

  final TextEditingController controller;
  final bool isWeekend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Weekend reflection',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tribe == null
                  ? 'Join a tribe to share a weekend reflection.'
                  : 'A weekly pause for ${tribe.tribe.displayName}. Save what you want to keep close.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            if (tribe != null && isWeekend) ...[
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  hintText: 'What did this week teach you?',
                  border: OutlineInputBorder(),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final posted = await ref
                      .read(visionProvider.notifier)
                      .postWeeklyReflection(controller.text);
                  if (!context.mounted) return;
                  if (!posted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'We could not post this weekly reflection.',
                        ),
                      ),
                    );
                    return;
                  }
                  controller.clear();
                },
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text('Post weekly reflection'),
              ),
            ],
            const SizedBox(height: 18),
            if (state.weeklyReflections.isEmpty)
              const Text('No weekly reflections yet.')
            else
              ...state.weeklyReflections.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(LucideIcons.user, size: 18),
                  ),
                  title: Text(item.alias),
                  subtitle: Text(item.content),
                  trailing: IconButton(
                    tooltip: item.bookmarkedByMe
                        ? 'Remove bookmark'
                        : 'Bookmark',
                    icon: Icon(
                      item.bookmarkedByMe
                          ? Icons.bookmark
                          : LucideIcons.bookmark,
                    ),
                    onPressed: () => ref
                        .read(visionProvider.notifier)
                        .setWeeklyBookmark(item, !item.bookmarkedByMe),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WeeklyPill extends StatelessWidget {
  const _WeeklyPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
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

class _PulsePanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final pulse = state.tribePulse;
    return VisionPanel(
      icon: LucideIcons.activity,
      title: 'Today in your tribe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.primaryTribe == null)
            const Text(
              'Join a tribe to see daily check-ins and shared reflections.',
            )
          else if (pulse.items.isEmpty)
            Text(
              pulse.returnedCount > 0
                  ? '${pulse.returnedCount} people checked in today.'
                  : 'Your tribe pulse will appear as people check in today.',
            )
          else
            ...pulse.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(GrowthJourneyEvent.iconForKey(item.iconKey)),
                title: Text(item.text),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final tribeId = state.primaryTribe?.tribe.id;
                  context.push(
                    tribeId == null
                        ? AppRoutes.invite
                        : '${AppRoutes.invite}?source=tribe&tribe_id=$tribeId',
                  );
                },
                icon: const Icon(LucideIcons.send, size: 18),
                label: const Text('Invite someone'),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('${AppRoutes.assessment}/compass'),
                icon: const Icon(LucideIcons.compass, size: 18),
                label: const Text('Retake compass'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TribeGamesPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final theme = Theme.of(context);
    final entries = state.gameScores.take(5).toList(growable: false);
    final roundsThisWeek = state.gameScores.length;

    return VisionPanel(
      icon: LucideIcons.gamepad2,
      title: 'Play together',
      trailing: Text('${entries.length} scores'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlayTogetherBanner(
            roundsThisWeek: roundsThisWeek,
            tribeName: state.primaryTribe?.tribe.displayName ?? 'Tribe',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeeklyPill(
                icon: LucideIcons.gamepad2,
                label: '$roundsThisWeek rounds this week',
              ),
              _WeeklyPill(
                icon: LucideIcons.users,
                label: state.primaryTribe?.tribe.displayName ?? 'Tribe',
              ),
            ],
          ),
          const SizedBox(height: 12),
          VisionActionTileColumn(
            children: [
              VisionActionTile(
                icon: LucideIcons.shuffle,
                title: 'Verse Scramble',
                subtitle: 'Scripture play',
                onTap: () => context.push(AppRoutes.gamesVerseScramble),
                dense: true,
              ),
              VisionActionTile(
                icon: LucideIcons.map,
                title: 'Journey with Jesus',
                subtitle: 'Story path',
                onTap: () => context.push(AppRoutes.gamesJourney),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'This week\'s scores',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              state.isReadOnly
                  ? 'Reconnect to see live tribe scores.'
                  : 'No scores yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.tokens.palette.textSecondary,
                height: 1.35,
              ),
            )
          else
            ...entries.map((entry) => _ScoreRow(entry: entry)),
        ],
      ),
    );
  }
}

class _PlayTogetherBanner extends StatelessWidget {
  const _PlayTogetherBanner({
    required this.roundsThisWeek,
    required this.tribeName,
  });

  final int roundsThisWeek;
  final String tribeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.palette.growthColor.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.12,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tokens.palette.growthColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$roundsThisWeek rounds this week',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tribeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.palette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const VisionIllustration(
            asset: VisionIllustrationAsset.play,
            size: 94,
            semanticLabel: 'Play together',
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.entry});

  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              entry.rank > 0 ? '${entry.rank}' : '-',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.tribeDisplayName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.gameTitle} - ${entry.periodLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.tokens.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.score}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForTribe(TribeIdentity tribe) {
  final key = '${tribe.slug} ${tribe.name} ${tribe.iconKey}'.toLowerCase();
  if (key.contains('artisan') || key.contains('judah')) {
    return LucideIcons.palette;
  }
  if (key.contains('watchman') || key.contains('benjamin')) {
    return LucideIcons.shield;
  }
  if (key.contains('cultivator') || key.contains('issachar')) {
    return LucideIcons.sprout;
  }
  if (key.contains('sower') || key.contains('zebulun')) {
    return LucideIcons.sprout;
  }
  if (key.contains('welcomer') || key.contains('asher')) {
    return LucideIcons.home;
  }
  if (key.contains('pillar') || key.contains('naphtali')) {
    return LucideIcons.columns;
  }
  if (key.contains('sentinel') || key.contains('levi')) {
    return LucideIcons.eye;
  }
  if (key.contains('bridgebuilder') || key.contains('ephraim')) {
    return LucideIcons.gitMerge;
  }
  if (key.contains('healer') || key.contains('manasseh')) {
    return LucideIcons.heartPulse;
  }
  if (key.contains('harvester') || key.contains('gad')) {
    return LucideIcons.wheat;
  }
  if (key.contains('reformer') || key.contains('simeon')) {
    return LucideIcons.hammer;
  }
  if (key.contains('architect') || key.contains('dan')) {
    return LucideIcons.landmark;
  }
  return GrowthJourneyEvent.iconForKey(tribe.iconKey);
}

String _whoShouldJoin(TribeIdentity tribe) {
  final key = '${tribe.slug} ${tribe.name}'.toLowerCase();
  if (key.contains('artisan') || key.contains('judah')) {
    return 'For people whose creativity needs worship, focus, and humility.';
  }
  if (key.contains('watchman') || key.contains('benjamin')) {
    return 'For people rebuilding attention, vigilance, and prayerful courage.';
  }
  if (key.contains('cultivator') || key.contains('issachar')) {
    return 'For people learning patience, rest, and faithful tending.';
  }
  if (key.contains('sower') || key.contains('zebulun')) {
    return 'For people who need courage to begin and stay rooted.';
  }
  if (key.contains('welcomer') || key.contains('asher')) {
    return 'For people practicing hospitality, belonging, and boundaries.';
  }
  if (key.contains('pillar') || key.contains('naphtali')) {
    return 'For people serving faithfully without losing their own calling.';
  }
  if (key.contains('sentinel') || key.contains('levi')) {
    return 'For people turning insight, solitude, and prayer into action.';
  }
  if (key.contains('bridgebuilder') || key.contains('ephraim')) {
    return 'For people repairing connection without losing conviction.';
  }
  if (key.contains('healer') || key.contains('manasseh')) {
    return 'For people carrying compassion while learning healthy limits.';
  }
  if (key.contains('harvester') || key.contains('gad')) {
    return 'For people pursuing fruitfulness without becoming ruled by metrics.';
  }
  if (key.contains('reformer') || key.contains('simeon')) {
    return 'For people turning holy frustration into constructive change.';
  }
  if (key.contains('architect') || key.contains('dan')) {
    return 'For people building order with open hands instead of control.';
  }
  return 'For people whose current season resonates with this formation path.';
}

class _TribeHangoutPanel extends ConsumerWidget {
  const _TribeHangoutPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final tribe = state.primaryTribe;
    final hangouts = tribe == null
        ? const <CommitmentHangout>[]
        : state.hangouts
              .where(
                (item) =>
                    item.scopeType == 'tribe' && item.scopeId == tribe.tribe.id,
              )
              .toList(growable: false);

    return VisionPanel(
      icon: LucideIcons.radio,
      title: 'Tribe hangouts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tribe == null)
            const Text('Join a tribe to start or join live audio gatherings.')
          else if (hangouts.isEmpty)
            Text(
              'No live gatherings in ${tribe.tribe.displayName} yet. Start one when your tribe needs voice, prayer, or encouragement.',
            )
          else
            ...hangouts.map((hangout) => _TribeHangoutCard(hangout: hangout)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: tribe == null ? null : () => _showCreate(context, ref),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Start tribe hangout'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreate(BuildContext context, WidgetRef ref) async {
    final tribe = ref.read(visionProvider).primaryTribe;
    if (tribe == null) return;

    final request = await showDialog<_CreateHangoutRequest>(
      context: context,
      builder: (_) => const _CreateHangoutDialog(),
    );

    if (request == null || !context.mounted) return;

    final hangout = await ref
        .read(visionProvider.notifier)
        .createCommitmentHangout(
          title: request.title,
          scopeType: 'tribe',
          scopeId: tribe.tribe.id,
          maxParticipants: request.maxParticipants,
        );
    if (!context.mounted) return;
    if (hangout?.liveKit?.isValid == true) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HangoutRoomScreen(
            hangout: hangout!,
            credentials: hangout.liveKit!,
            onLeave: () =>
                ref.read(visionProvider.notifier).leaveHangout(hangout.id),
          ),
        ),
      );
      return;
    }
    if (hangout != null) {
      await ref.read(visionProvider.notifier).leaveHangout(hangout.id);
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hangout == null
              ? 'We could not start this tribe hangout.'
              : 'Tribe hangout started, but audio credentials were unavailable.',
        ),
      ),
    );
  }
}

class _CreateHangoutRequest {
  const _CreateHangoutRequest({
    required this.title,
    required this.maxParticipants,
  });

  final String title;
  final int maxParticipants;
}

class _CreateHangoutDialog extends StatefulWidget {
  const _CreateHangoutDialog();

  @override
  State<_CreateHangoutDialog> createState() => _CreateHangoutDialogState();
}

class _CreateHangoutDialogState extends State<_CreateHangoutDialog> {
  final _titleController = TextEditingController(text: 'Tribe check-in room');
  var _maxParticipants = 8.0;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  void _onTitleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final canStart = _titleController.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('Start tribe hangout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Max people: ${_maxParticipants.round()}'),
            Slider(
              value: _maxParticipants,
              min: 2,
              max: 50,
              divisions: 48,
              onChanged: (value) => setState(() => _maxParticipants = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canStart
              ? () {
                  Navigator.of(context).pop(
                    _CreateHangoutRequest(
                      title: _titleController.text.trim(),
                      maxParticipants: _maxParticipants.round(),
                    ),
                  );
                }
              : null,
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _TribeHangoutCard extends ConsumerWidget {
  const _TribeHangoutCard({required this.hangout});

  final CommitmentHangout hangout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final full = hangout.participantCount >= hangout.maxParticipants;
    final canEnter = hangout.canJoin || hangout.joinedByMe;
    final blockedBecauseFull = full && !hangout.joinedByMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hangout.status == 'live' ? LucideIcons.radio : LucideIcons.clock3,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hangout.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  blockedBecauseFull
                      ? 'Room is full'
                      : '${hangout.participantCount}/${hangout.maxParticipants} joined',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: canEnter
                ? () async {
                    final joined = await ref
                        .read(visionProvider.notifier)
                        .joinHangout(hangout);
                    if (!context.mounted) return;
                    if (joined?.liveKit?.isValid == true) {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HangoutRoomScreen(
                            hangout: joined!,
                            credentials: joined.liveKit!,
                            onLeave: () => ref
                                .read(visionProvider.notifier)
                                .leaveHangout(joined.id),
                          ),
                        ),
                      );
                      return;
                    }
                    if (joined != null) {
                      await ref
                          .read(visionProvider.notifier)
                          .leaveHangout(joined.id);
                      if (!context.mounted) return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          blockedBecauseFull
                              ? 'This tribe hangout is full.'
                              : 'We could not join this tribe hangout.',
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(hangout.joinedByMe ? 'Rejoin' : 'Join'),
          ),
        ],
      ),
    );
  }
}
