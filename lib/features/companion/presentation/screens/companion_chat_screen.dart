import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/app_providers.dart';
import '../../application/companion_chat_notifier.dart';
import '../../application/companion_notifier.dart';
import '../../domain/models/companion_character.dart';
import '../../domain/models/companion_message.dart';
import '../../domain/models/companion_mood.dart';
import '../widgets/companion_haptics.dart';
import '../widgets/companion_orb.dart';

/// Full companion chat surface. Orb sits above the scrollback; input docks
/// at the bottom. Non-streaming in Phase 1 — orb shows thinking shimmer
/// until the assistant reply lands.
class CompanionChatScreen extends ConsumerStatefulWidget {
  const CompanionChatScreen({
    super.key,
    this.threadKey = 'default',
    this.mode = 'default',
    this.title,
    this.seedAssistantOpener,
  });

  final String threadKey;
  final String mode;
  final String? title;

  /// Optional first-contact message seeded as an assistant reply on first open.
  /// Used when routing in from onboarding so the first interaction feels warm.
  final String? seedAssistantOpener;

  @override
  ConsumerState<CompanionChatScreen> createState() =>
      _CompanionChatScreenState();
}

class _CompanionChatScreenState extends ConsumerState<CompanionChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _seedApplied = false;

  CompanionChatKey get _chatKey =>
      CompanionChatKey(threadKey: widget.threadKey, mode: widget.mode);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeSeedOpener();
    });
  }

  Future<void> _maybeSeedOpener() async {
    if (_seedApplied) return;
    _seedApplied = true;

    // Wait one frame so the StateNotifier has finished loading from storage.
    await Future.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    final notifier = ref.read(companionChatProvider(_chatKey).notifier);
    final state = ref.read(companionChatProvider(_chatKey));
    if (state.messages.isNotEmpty) return;

    final character = ref.read(companionProvider).activeCharacter ??
        CompanionCharacter.naomi;

    // Explicit seed passed by caller takes precedence.
    if (widget.seedAssistantOpener != null &&
        widget.seedAssistantOpener!.isNotEmpty) {
      await notifier.seedAssistantOpener(widget.seedAssistantOpener!);
      _scrollToBottom();
      return;
    }

    // Mode-driven openers — used when a fresh thread is opened from a
    // notification or deep-link without a custom seed.
    final modeSeed = _openerForMode(widget.mode, character);
    if (modeSeed != null) {
      await notifier.seedAssistantOpener(modeSeed);
      _scrollToBottom();
    }
  }

  String? _openerForMode(String mode, CompanionCharacter character) {
    switch (mode) {
      case 'accountability':
        return _accountabilityOpener(character);
      case 'hard_questions':
        return _hardQuestionsOpener(character);
      default:
        return null;
    }
  }

  String _accountabilityOpener(CompanionCharacter c) {
    final salutation = switch (c) {
      CompanionCharacter.raziel => 'Friday.',
      CompanionCharacter.naomi => 'Dear one — it\'s Friday.',
      CompanionCharacter.james => 'Alright — Friday.',
    };
    return '$salutation Let\'s sit for three questions, nothing more.\n\n'
        '1. What was a win this week — however small?\n'
        '2. Where did you struggle, and what held you up?\n'
        '3. What\'s the one thing you want next week to look different?';
  }

  String _hardQuestionsOpener(CompanionCharacter c) {
    return switch (c) {
      CompanionCharacter.raziel =>
        'Ask it plainly. I\'d rather sit with a real question than offer a tidy answer.',
      CompanionCharacter.naomi =>
        'You can ask me anything — doubt is not the enemy of faith. What\'s been weighing on you?',
      CompanionCharacter.james =>
        'Give me the hard question. We\'ll work through it, not around it.',
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Quick actions render only on early turns of a default thread — they're
  /// onboarding rails for the first few interactions, not permanent chrome.
  bool _showQuickActions(CompanionChatState state) {
    if (widget.mode != 'default') return false;
    if (state.isSending) return false;
    return state.messages.length <= 2;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final character =
        ref.read(companionProvider).activeCharacter ?? CompanionCharacter.naomi;
    CompanionHaptics.acknowledge(character);
    ref.read(soundServiceProvider).playTap();
    _controller.clear();
    final notifier = ref.read(companionChatProvider(_chatKey).notifier);
    await notifier.sendUserMessage(text);
    CompanionHaptics.replyLanded(character);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companionState = ref.watch(companionProvider);
    final character =
        companionState.activeCharacter ?? CompanionCharacter.naomi;
    final chatState = ref.watch(companionChatProvider(_chatKey));

    ref.listen<CompanionChatState>(companionChatProvider(_chatKey),
        (prev, next) {
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? character.displayName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_outlined),
            tooltip: 'Voice call',
            onPressed: () => context.push(
              '${AppRoutes.companionCall}?thread=${widget.threadKey}',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Column(
                children: [
                  CompanionOrb(
                    character: character,
                    mood: chatState.mood,
                    size: 88,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    character.tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                itemCount: chatState.messages.length +
                    (_showQuickActions(chatState) ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showQuickActions(chatState) &&
                      index == chatState.messages.length) {
                    return _QuickActions(mode: widget.mode);
                  }
                  final msg = chatState.messages[index];
                  return _MessageBubble(message: msg, character: character);
                },
              ),
            ),
            if (chatState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  chatState.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            _InputBar(
              controller: _controller,
              isSending: chatState.isSending,
              onSend: _send,
              onChanged: (text) {
                final mood = text.isEmpty
                    ? CompanionMood.idle
                    : CompanionMood.attentive;
                ref
                    .read(companionChatProvider(_chatKey).notifier)
                    .setAmbientMood(mood);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(
            icon: Icons.location_on_outlined,
            label: 'Find a church near me',
            onTap: () => context.push(AppRoutes.churchesNearby),
          ),
          _Chip(
            icon: Icons.help_outline_rounded,
            label: 'Ask a hard question',
            onTap: () {
              final uri =
                  '${AppRoutes.companionChat}?thread=hard-questions&mode=hard_questions&title=${Uri.encodeQueryComponent('Hard questions')}';
              context.push(uri);
            },
          ),
          _Chip(
            icon: Icons.menu_book_rounded,
            label: 'Read with me',
            onTap: () => context.push(AppRoutes.bible),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.character});

  final CompanionMessage message;
  final CompanionCharacter character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    final bgColor = isUser
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fgColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.86);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: message.pending
            ? _PendingDots(color: fgColor.withValues(alpha: 0.5))
            : Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  height: 1.5,
                ),
              ),
      ),
    );
  }
}

class _PendingDots extends StatefulWidget {
  const _PendingDots({required this.color});

  final Color color;

  @override
  State<_PendingDots> createState() => _PendingDotsState();
}

class _PendingDotsState extends State<_PendingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i * 0.2) % 1.0;
            final opacity = 0.3 + 0.7 * (1 - (phase - 0.5).abs() * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.25, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Say anything…',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            icon: const Icon(Icons.arrow_upward_rounded),
          ),
        ],
      ),
    );
  }
}
