import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/ambient_scope.dart';
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
      ),
    );
  }

  void _openVisibilitySettings() {
    var localMode = _mode;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
        final safeBottom = MediaQuery.paddingOf(sheetContext).bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24 + safeBottom),
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
                          ? 'Posting as ${tribe.displayAlias}.'
                          : 'Choose a circle for this season.',
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
      title: 'Actions',
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
            'Your current tribe stays primary.',
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
      useRootNavigator: true,
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
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
          children: [
            Text(
              'Tribe guide',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Read the fit note before switching.',
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
            _tribeCardDescription(tribe),
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
                      message: '${tribe.displayName} is now your tribe.',
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
            _tribeCardDescription(tribe),
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
                      message: '${tribe.displayName} is now your tribe.',
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
      title: 'After joining',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeaturePreviewRow(
            icon: LucideIcons.activity,
            title: 'Daily pulse',
            body: 'Check-ins from your tribe.',
          ),
          _FeaturePreviewRow(
            icon: LucideIcons.calendarHeart,
            title: 'Weekend reflection',
            body: 'Post or save a weekly note.',
          ),
          _FeaturePreviewRow(
            icon: LucideIcons.radio,
            title: 'Live hangouts',
            body: 'Open voice rooms for prayer.',
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
                  ? 'Post this week\'s note for ${tribe.tribe.displayName}.'
                  : 'Open Saturday and Sunday.',
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
      useRootNavigator: true,
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
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
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
                  : 'Post or save notes from ${tribe.tribe.displayName}.',
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
              const Text(
                'No weekend notes yet. Your first note can set the rhythm.',
              )
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
            const Text('Join a tribe to see check-ins.')
          else if (pulse.items.isEmpty)
            Text(
              pulse.returnedCount > 0
                  ? '${pulse.returnedCount} people checked in today.'
                  : 'Your check-in can be today\'s first signal.',
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
    return 'Creativity, focus, humility.';
  }
  if (key.contains('watchman') || key.contains('benjamin')) {
    return 'Attention, vigilance, courage.';
  }
  if (key.contains('cultivator') || key.contains('issachar')) {
    return 'Patience, rest, tending.';
  }
  if (key.contains('sower') || key.contains('zebulun')) {
    return 'Courage to begin and stay rooted.';
  }
  if (key.contains('welcomer') || key.contains('asher')) {
    return 'Hospitality, belonging, boundaries.';
  }
  if (key.contains('pillar') || key.contains('naphtali')) {
    return 'Faithful service with clear limits.';
  }
  if (key.contains('sentinel') || key.contains('levi')) {
    return 'Prayer and insight into action.';
  }
  if (key.contains('bridgebuilder') || key.contains('ephraim')) {
    return 'Repair connection with conviction.';
  }
  if (key.contains('healer') || key.contains('manasseh')) {
    return 'Compassion with healthy limits.';
  }
  if (key.contains('harvester') || key.contains('gad')) {
    return 'Fruitfulness without metric pressure.';
  }
  if (key.contains('reformer') || key.contains('simeon')) {
    return 'Holy frustration into repair.';
  }
  if (key.contains('architect') || key.contains('dan')) {
    return 'Order with open hands.';
  }
  return 'A fit for this season.';
}

String _tribeCardDescription(TribeIdentity tribe) {
  final key = '${tribe.slug} ${tribe.name}'.toLowerCase();
  if (key.contains('artisan') || key.contains('judah')) {
    return 'Create from worship, not comparison.';
  }
  if (key.contains('watchman') || key.contains('benjamin')) {
    return 'Rebuild attention, discernment, and self-control.';
  }
  if (key.contains('cultivator') || key.contains('issachar')) {
    return 'Practice patience and steady care.';
  }
  if (key.contains('sower') || key.contains('zebulun')) {
    return 'Begin with courage. Stay rooted.';
  }
  if (key.contains('welcomer') || key.contains('asher')) {
    return 'Practice belonging and boundaries.';
  }
  if (key.contains('pillar') || key.contains('naphtali')) {
    return 'Serve without losing your calling.';
  }
  if (key.contains('sentinel') || key.contains('levi')) {
    return 'Turn prayer and insight into action.';
  }
  if (key.contains('bridgebuilder') || key.contains('ephraim')) {
    return 'Repair connection with conviction.';
  }
  if (key.contains('healer') || key.contains('manasseh')) {
    return 'Care deeply. Keep healthy limits.';
  }
  if (key.contains('harvester') || key.contains('gad')) {
    return 'Build fruitfully without chasing metrics.';
  }
  if (key.contains('reformer') || key.contains('simeon')) {
    return 'Turn frustration into repair.';
  }
  if (key.contains('architect') || key.contains('dan')) {
    return 'Build order without control.';
  }

  final description = tribe.description.trim();
  if (description.isEmpty) return 'A tribe for this season.';
  final firstSentence = description.split(RegExp(r'(?<=[.!?])\s+')).first;
  return firstSentence.replaceFirst(
    RegExp(r'^For people (who|whose)\s+', caseSensitive: false),
    '',
  );
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
            const Text('Join a tribe to start live rooms.')
          else if (hangouts.isEmpty)
            const Text('No live rooms yet. Start a short prayer check-in.')
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
