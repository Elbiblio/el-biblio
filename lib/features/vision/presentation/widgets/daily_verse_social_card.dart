import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../shared/widgets/light_rays_reveal.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../auth/domain/models/auth_models.dart';
import '../../domain/daily_verse_social_models.dart';
import '../../../bible/domain/models/verse.dart';
import '../../../bible/presentation/helpers/verse_reader_navigation.dart';
import 'vision_panel.dart';

class DailyVerseSocialCard extends ConsumerStatefulWidget {
  const DailyVerseSocialCard({super.key});

  @override
  ConsumerState<DailyVerseSocialCard> createState() =>
      _DailyVerseSocialCardState();
}

class _DailyVerseSocialCardState extends ConsumerState<DailyVerseSocialCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dailyVerseSocialProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyVerseSocialProvider);
    final auth = ref.watch(authProvider);
    final verse = state.verse;

    if (state.isLoading && verse == null) {
      return const _DailyVerseSocialSkeleton();
    }

    if (verse == null) {
      return VisionPanel(
        icon: LucideIcons.sun,
        title: state.error == null
            ? 'Community verse is preparing'
            : 'Community verse needs a retry',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.error ??
                  'Today\'s shared Scripture space will appear here soon.',
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  ref.read(dailyVerseSocialProvider.notifier).refresh(),
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _DailyVerseSocialSurface(
      verse: verse,
      canUseSocial: _canUseSocial(auth),
      isGuest: auth.isGuest,
      isVoting: state.isVoting,
      isLiking: state.isLiking,
      responseCount: state.responseCount,
      previews: state.previewReflections,
      onOpenSheet: () => _openSheet(context),
      onRead: () => _openReader(context, verse),
      onVote: () => _vote(context),
      onLike: () => _toggleLike(context),
      onShare: () => _share(context, verse),
    );
  }

  void _openSheet(BuildContext context) {
    HapticService.light();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => _DailyVerseSocialSheet(hostContext: context),
    );
  }

  void _openReader(BuildContext context, Verse verse) {
    HapticService.selection();
    final opened = openVerseInReader(context, verse);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not open this passage.')),
      );
    }
  }

  Future<void> _vote(BuildContext context) async {
    final auth = ref.read(authProvider);
    final verse = ref.read(dailyVerseSocialProvider).verse;
    if (!_canUseSocial(auth)) {
      _showSocialGate(context);
      return;
    }
    if (verse?.isVoted == true) {
      HapticService.selection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amen already added for today.')),
      );
      return;
    }

    HapticService.selection();
    final ok = await ref.read(dailyVerseSocialProvider.notifier).vote();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Amen added.'
              : ref.read(dailyVerseSocialProvider).actionError ??
                    'We could not add your amen.',
        ),
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context) async {
    final auth = ref.read(authProvider);
    if (!_canUseSocial(auth)) {
      _showSocialGate(context);
      return;
    }

    HapticService.selection();
    final ok = await ref.read(dailyVerseSocialProvider.notifier).toggleLike();
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(dailyVerseSocialProvider).actionError ??
              'We could not update this verse.',
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, Verse verse) async {
    HapticService.selection();
    final message = _shareText(verse);
    if (_canUseSocial(ref.read(authProvider))) {
      unawaited(
        ref.read(dailyVerseSocialProvider.notifier).trackShare(message),
      );
    }
    await Share.share(message);
  }
}

class _DailyVerseSocialSurface extends StatelessWidget {
  const _DailyVerseSocialSurface({
    required this.verse,
    required this.canUseSocial,
    required this.isGuest,
    required this.isVoting,
    required this.isLiking,
    required this.responseCount,
    required this.previews,
    required this.onOpenSheet,
    required this.onRead,
    required this.onVote,
    required this.onLike,
    required this.onShare,
  });

  final Verse verse;
  final bool canUseSocial;
  final bool isGuest;
  final bool isVoting;
  final bool isLiking;
  final int responseCount;
  final List<DailyVerseReflection> previews;
  final VoidCallback onOpenSheet;
  final VoidCallback onRead;
  final VoidCallback onVote;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = _accentFor(verse, theme);
    final isDark = theme.brightness == Brightness.dark;
    final background = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.20 : 0.11),
      tokens.palette.paper,
    );
    final border = accent.withValues(alpha: isDark ? 0.42 : 0.24);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Community verse',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: tokens.palette.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: verse.isLiked ? 'Unlike verse' : 'Like verse',
                  onPressed: isLiking ? null : onLike,
                  color: verse.isLiked ? accent : tokens.palette.textSecondary,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      verse.isLiked ? Icons.favorite : LucideIcons.heart,
                      key: ValueKey(verse.isLiked),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: LucideIcons.calendarDays,
                  label: _dateLabel(verse),
                  accent: accent,
                ),
                if (verse.theme?.displayName?.isNotEmpty == true ||
                    verse.theme?.name.isNotEmpty == true)
                  _Pill(
                    icon: LucideIcons.flower2,
                    label: verse.theme?.displayName ?? verse.theme!.name,
                    accent: accent,
                  ),
                if (verse.translation.isNotEmpty)
                  _Pill(
                    icon: LucideIcons.languages,
                    label: verse.translation,
                    accent: accent,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onRead,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: LightRaysReveal(
                  delay: const Duration(milliseconds: 180),
                  rayColor: accent,
                  rayCount: 7,
                  maxOpacity: 0.18,
                  rotate: false,
                  child: Text(
                    '"${verse.text}"',
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: tokens.palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onRead,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.bookOpen, size: 16, color: accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        verse.displayReference,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(LucideIcons.arrowRight, size: 16, color: accent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: isVoting ? null : onVote,
                  icon: Icon(
                    verse.isVoted ? LucideIcons.check : LucideIcons.sparkle,
                    size: 17,
                  ),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      verse.isVoted
                          ? 'Amened'
                          : 'Amen ${verse.votes > 0 ? verse.votes : ''}',
                      key: ValueKey('${verse.isVoted}-${verse.votes}'),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenSheet,
                  icon: const Icon(LucideIcons.messageCircle, size: 17),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      responseCount == 0
                          ? 'Respond'
                          : '$responseCount responses',
                      key: ValueKey(responseCount),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRead,
                  icon: const Icon(LucideIcons.bookOpenCheck, size: 17),
                  label: const Text('Read full chapter'),
                ),
                IconButton(
                  tooltip: 'Share verse',
                  onPressed: onShare,
                  icon: const Icon(LucideIcons.share2, size: 20),
                ),
              ],
            ),
            if (previews.isNotEmpty) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: onOpenSheet,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: previews
                      .map(
                        (item) => _PreviewResponse(item: item, accent: accent),
                      )
                      .toList(),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                canUseSocial
                    ? 'Be the first to name what this verse is inviting today.'
                    : isGuest
                    ? 'Create a full account to join today\'s responses.'
                    : 'Sign in to join today\'s responses.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.palette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyVerseSocialSheet extends ConsumerStatefulWidget {
  const _DailyVerseSocialSheet({required this.hostContext});

  final BuildContext hostContext;

  @override
  ConsumerState<_DailyVerseSocialSheet> createState() =>
      _DailyVerseSocialSheetState();
}

class _DailyVerseSocialSheetState
    extends ConsumerState<_DailyVerseSocialSheet> {
  final _responseController = TextEditingController();
  final _replyControllers = <int, TextEditingController>{};
  final _replyCardKeys = <int, GlobalKey>{};
  final _replyOpenIds = <int>{};

  @override
  void dispose() {
    _responseController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyVerseSocialProvider);
    final auth = ref.watch(authProvider);
    final verse = state.verse;
    if (verse == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final accent = _accentFor(verse, theme);
    final canUseSocial = _canUseSocial(auth);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.58,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: tokens.palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + safeBottom),
                  children: [
                    _SheetVerseHeader(
                      verse: verse,
                      accent: accent,
                      onRead: () {
                        Navigator.of(context).pop();
                        HapticService.selection();
                        if (widget.hostContext.mounted) {
                          openVerseInReader(widget.hostContext, verse);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What is this verse inviting in you today?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (canUseSocial)
                      _ResponseComposer(
                        controller: _responseController,
                        isSubmitting: state.isSubmittingResponse,
                        accent: accent,
                        onSubmit: _submitResponse,
                      )
                    else
                      _SocialGatePanel(onOpenProfile: _openProfile),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.messagesSquare,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.responseCount == 0
                                ? 'Today\'s responses'
                                : '${state.responseCount} responses today',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (state.isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.reflections.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tokens.palette.surface.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.palette.border),
                        ),
                        child: Text(
                          'No responses yet. A quiet first sentence is enough.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.palette.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...state.reflections.map(
                        (item) => _ResponseCard(
                          key: _replyCardKeyFor(item.id),
                          item: item,
                          accent: accent,
                          isReplyOpen: _replyOpenIds.contains(item.id),
                          replyController: _controllerFor(item.id),
                          isSubmittingReply: state.replyingReflectionIds
                              .contains(item.id),
                          onToggleReply: () =>
                              _toggleReply(item.id, canUseSocial),
                          onSubmitReply: () => _submitReply(item.id),
                        ),
                      ),
                    if (state.actionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.actionError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  GlobalKey _replyCardKeyFor(int reflectionId) {
    return _replyCardKeys.putIfAbsent(
      reflectionId,
      () => GlobalKey(debugLabel: 'daily_verse_response_$reflectionId'),
    );
  }

  void _scrollReplyIntoView(int reflectionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _replyCardKeys[reflectionId]?.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.22,
      );
    });
  }

  TextEditingController _controllerFor(int reflectionId) {
    return _replyControllers.putIfAbsent(
      reflectionId,
      () => TextEditingController(),
    );
  }

  void _toggleReply(int reflectionId, bool canUseSocial) {
    if (!canUseSocial) {
      _showSocialGate(context);
      return;
    }
    HapticService.selection();
    final shouldOpen = !_replyOpenIds.contains(reflectionId);
    setState(() {
      if (!_replyOpenIds.remove(reflectionId)) {
        _replyOpenIds.add(reflectionId);
      }
    });
    if (shouldOpen) {
      _scrollReplyIntoView(reflectionId);
    }
  }

  void _openProfile() {
    final hostContext = widget.hostContext;
    Navigator.of(context).pop();
    if (hostContext.mounted) {
      hostContext.go(AppRoutes.profile);
    }
  }

  Future<void> _submitResponse() async {
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (!_canUseSocial(auth) || user == null) {
      _showSocialGate(context);
      return;
    }
    final posted = await ref
        .read(dailyVerseSocialProvider.notifier)
        .postResponse(user: user, content: _responseController.text);
    if (!mounted) return;
    if (posted) {
      _responseController.clear();
      HapticService.success();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Response shared.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(dailyVerseSocialProvider).actionError ??
              'We could not share this response.',
        ),
      ),
    );
  }

  Future<void> _submitReply(int reflectionId) async {
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (!_canUseSocial(auth) || user == null) {
      _showSocialGate(context);
      return;
    }
    final controller = _controllerFor(reflectionId);
    final posted = await ref
        .read(dailyVerseSocialProvider.notifier)
        .postReply(
          user: user,
          reflectionId: reflectionId,
          content: controller.text,
        );
    if (!mounted) return;
    if (posted) {
      controller.clear();
      HapticService.success();
      setState(() => _replyOpenIds.remove(reflectionId));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(dailyVerseSocialProvider).actionError ??
              'We could not add this reply.',
        ),
      ),
    );
  }
}

class _SheetVerseHeader extends StatelessWidget {
  const _SheetVerseHeader({
    required this.verse,
    required this.accent,
    required this.onRead,
  });

  final Verse verse;
  final Color accent;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.10),
          tokens.palette.paper,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${verse.text}"',
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.45,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.bookOpen, size: 16, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  verse.displayReference,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRead,
                icon: const Icon(LucideIcons.arrowRight, size: 16),
                label: const Text('Read'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseComposer extends StatelessWidget {
  const _ResponseComposer({
    required this.controller,
    required this.isSubmitting,
    required this.accent,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Color accent;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final canSubmit = value.text.trim().isNotEmpty && !isSubmitting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              maxLength: 600,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                hintText: 'Name one honest response, prayer, or next step.',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: accent, width: 1.4),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: canSubmit ? onSubmit : null,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send, size: 17),
                label: const Text('Share response'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    super.key,
    required this.item,
    required this.accent,
    required this.isReplyOpen,
    required this.replyController,
    required this.isSubmittingReply,
    required this.onToggleReply,
    required this.onSubmitReply,
  });

  final DailyVerseReflection item;
  final Color accent;
  final bool isReplyOpen;
  final TextEditingController replyController;
  final bool isSubmittingReply;
  final VoidCallback onToggleReply;
  final VoidCallback onSubmitReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: item.isPending ? 0.64 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.palette.paper.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(author: item.author, createdAt: item.createdAt),
            const SizedBox(height: 10),
            Text(
              item.content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            if (item.comments.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...item.comments.map(
                (comment) => _CommentRow(comment: comment, accent: accent),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: item.isPending ? null : onToggleReply,
                  icon: const Icon(LucideIcons.reply, size: 16),
                  label: Text(isReplyOpen ? 'Cancel reply' : 'Reply'),
                ),
                if (item.isPending)
                  Text(
                    'Sending...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.palette.textTertiary,
                    ),
                  ),
              ],
            ),
            if (isReplyOpen) ...[
              const SizedBox(height: 6),
              _ReplyComposer(
                controller: replyController,
                isSubmitting: isSubmittingReply,
                onSubmit: onSubmitReply,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final canSubmit = value.text.trim().isNotEmpty && !isSubmitting;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                maxLength: 300,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  hintText: 'Reply with care',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send reply',
              onPressed: canSubmit ? onSubmit : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.send, size: 18),
            ),
          ],
        );
      },
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment, required this.accent});

  final DailyVerseComment comment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: tokens.palette.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(
            author: comment.author,
            createdAt: comment.createdAt,
            compact: true,
          ),
          const SizedBox(height: 6),
          Text(
            comment.content,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.author,
    required this.createdAt,
    this.compact = false,
  });

  final DailyVerseAuthor author;
  final DateTime? createdAt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 11 : 15,
          child: Text(
            author.initial,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            author.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelLarge)
                    ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (createdAt != null)
          Text(
            timeago.format(createdAt!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.palette.textTertiary,
            ),
          ),
      ],
    );
  }
}

class _PreviewResponse extends StatelessWidget {
  const _PreviewResponse({required this.item, required this.accent});

  final DailyVerseReflection item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tokens.palette.paper.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 12, child: Text(item.author.initial)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialGatePanel extends StatelessWidget {
  const _SocialGatePanel({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.palette.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a full account to respond with the community.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenProfile,
            icon: const Icon(LucideIcons.userCircle, size: 17),
            label: const Text('Open profile'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.accent});

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyVerseSocialSkeleton extends StatelessWidget {
  const _DailyVerseSocialSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(
      child: SkeletonCard(height: 260, borderRadius: 8),
    );
  }
}

bool _canUseSocial(AuthState auth) {
  return auth.isAuthenticated == true &&
      auth.isGuest != true &&
      auth.user != null;
}

void _showSocialGate(BuildContext context) {
  HapticService.selection();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Create a full account to join the community verse.'),
    ),
  );
}

Color _accentFor(Verse verse, ThemeData theme) {
  return _parseHexColor(verse.theme?.colorCode) ??
      (theme.brightness == Brightness.dark
          ? const Color(0xFFE0B05C)
          : const Color(0xFFB66B28));
}

Color? _parseHexColor(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final hex = raw.replaceFirst('#', '');
  if (hex.length == 6) {
    return Color(int.tryParse('FF$hex', radix: 16) ?? 0xFFB66B28);
  }
  if (hex.length == 8) {
    return Color(int.tryParse(hex, radix: 16) ?? 0xFFB66B28);
  }
  return null;
}

String _dateLabel(Verse verse) {
  final date = verse.date ?? verse.createdAt;
  return DateFormat('MMM d').format(date);
}

String _shareText(Verse verse) {
  return '"${verse.text}" - ${verse.displayReference}\n\nShared from El-Biblio';
}
