import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/companion_repository.dart';
import '../domain/models/companion_character.dart';
import '../domain/models/companion_conversation.dart';
import '../domain/models/companion_message.dart';
import '../domain/models/companion_mood.dart';
import 'companion_notifier.dart';

class CompanionChatState {
  const CompanionChatState({
    required this.threadKey,
    required this.messages,
    required this.mood,
    required this.mode,
    this.isSending = false,
    this.error,
  });

  final String threadKey;
  final List<CompanionMessage> messages;
  final CompanionMood mood;
  final String mode;
  final bool isSending;
  final String? error;

  CompanionChatState copyWith({
    List<CompanionMessage>? messages,
    CompanionMood? mood,
    String? mode,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return CompanionChatState(
      threadKey: threadKey,
      messages: messages ?? this.messages,
      mood: mood ?? this.mood,
      mode: mode ?? this.mode,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  factory CompanionChatState.empty(String threadKey, String mode) {
    return CompanionChatState(
      threadKey: threadKey,
      messages: const [],
      mood: CompanionMood.idle,
      mode: mode,
    );
  }
}

class CompanionChatNotifier extends StateNotifier<CompanionChatState> {
  CompanionChatNotifier({
    required String threadKey,
    required String mode,
    required this.repository,
    required this.character,
  }) : super(CompanionChatState.empty(threadKey, mode));

  final CompanionRepository repository;
  final CompanionCharacter character;
  final _uuid = const Uuid();

  Future<void> load() async {
    final convo = await repository.loadConversation(state.threadKey);
    if (convo != null) {
      state = state.copyWith(
        messages: convo.messages,
        mood: CompanionMood.idle,
      );
    }
  }

  /// Ambient mood setter for UI-driven transitions (e.g. input focus).
  /// No-ops while an assistant reply is in-flight to avoid overriding
  /// `thinking`/`speaking`.
  void setAmbientMood(CompanionMood mood) {
    if (state.mood == CompanionMood.thinking ||
        state.mood == CompanionMood.speaking) {
      return;
    }
    if (state.mood == mood) return;
    state = state.copyWith(mood: mood);
  }

  /// Appends an assistant message directly without hitting the backend —
  /// used for pre-scripted openers (e.g. warm greeting after onboarding).
  Future<void> seedAssistantOpener(String content) async {
    final msg = CompanionMessage(
      id: _uuid.v4(),
      role: CompanionMessageRole.assistant,
      content: content,
      createdAt: DateTime.now(),
      characterCode: character.code,
    );
    final next = [...state.messages, msg];
    state = state.copyWith(messages: next, mood: CompanionMood.warm);
    await _persist();
  }

  /// Seed a failure admission conversation opener.
  /// Called when user missed a stop-bad-habit commitment.
  Future<void> seedFailureAdmissionOpener({
    required String habitName,
    required int missedDays,
    required int totalDays,
    required String commitmentTitle,
  }) async {
    state = state.copyWith(mode: 'failure_admission');

    final opener = _buildAdmissionOpener(habitName, missedDays);
    await seedAssistantOpener(opener);
  }

  String _buildAdmissionOpener(String habitName, int missedDays) {
    final openers = [
      'I see you missed your commitment regarding $habitName. '
          'That takes courage to admit. What happened?',
      'Thank you for being honest about $habitName. '
          'Every saint has a past. Tell me about it.',
      'I noticed you slipped on $habitName. '
          'That\'s okay — this is part of the journey. What\'s on your heart?',
      'You showed up to admit something about $habitName. '
          'That\'s already a victory. Talk to me.',
    ];
    return openers[missedDays % openers.length];
  }

  Future<void> sendUserMessage(String text, {Map<String, dynamic>? context}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMsg = CompanionMessage(
      id: _uuid.v4(),
      role: CompanionMessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
      characterCode: character.code,
    );

    final pendingId = _uuid.v4();
    final pendingAssistant = CompanionMessage(
      id: pendingId,
      role: CompanionMessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      characterCode: character.code,
      pending: true,
    );

    if (!mounted) return;
    state = state.copyWith(
      messages: [...state.messages, userMsg, pendingAssistant],
      mood: CompanionMood.thinking,
      isSending: true,
      clearError: true,
    );

    var firstTokenSeen = false;
    var finalContent = '';
    var streamCompleted = false;
    Object? streamError;

    // Cap history sent to the backend so payloads don't balloon on long
    // threads. Server-side summarisation (Phase 4) replaces this later.
    const maxHistoryMessages = 20;
    final history = state.messages
        .where((m) => !m.pending && m.content.isNotEmpty)
        .where((m) => m.id != userMsg.id && m.id != pendingId)
        .toList();
    final truncated = history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;
    final historyPayload = truncated
        .map((m) => {
              'role': m.role.storageValue,
              'content': m.content,
            })
        .toList();

    try {
      final stream = repository.chatStream(
        threadKey: state.threadKey,
        character: character,
        message: trimmed,
        mode: state.mode,
        context: context,
        history: historyPayload,
      );

      await for (final partial in stream) {
        if (!mounted) return;
        finalContent = partial;
        // Flip to speaking on first observed token.
        final nextMood = firstTokenSeen
            ? state.mood
            : CompanionMood.speaking;
        firstTokenSeen = true;

        final updated = [...state.messages];
        final idx = updated.indexWhere((m) => m.id == pendingId);
        if (idx != -1) {
          updated[idx] = updated[idx].copyWith(
            content: partial,
            pending: true,
          );
        }
        state = state.copyWith(messages: updated, mood: nextMood);
      }
      streamCompleted = true;
    } catch (e) {
      streamError = e;
    } finally {
      // Always resolve the pending bubble — a stream that errored or was
      // cancelled mid-flight must not leave `pending: true` on disk.
      if (mounted) {
        final resolved = [...state.messages];
        final idx = resolved.indexWhere((m) => m.id == pendingId);
        if (idx != -1) {
          if (streamCompleted && finalContent.isNotEmpty) {
            resolved[idx] = resolved[idx].copyWith(
              content: finalContent,
              pending: false,
            );
          } else if (finalContent.isNotEmpty) {
            // Partial content — keep what arrived, mark interrupted.
            resolved[idx] = resolved[idx].copyWith(
              content: '$finalContent\n\n_(interrupted)_',
              pending: false,
            );
          } else {
            // Nothing arrived — drop the empty placeholder.
            resolved.removeAt(idx);
          }
        }

        state = state.copyWith(
          messages: resolved,
          mood: streamCompleted
              ? CompanionMood.speaking
              : CompanionMood.idle,
          isSending: false,
          error: streamError == null
              ? null
              : 'Something got in the way — try again in a moment.',
          clearError: streamError == null,
        );
        await _persist();

        if (streamCompleted) {
          // Settle back to idle shortly after delivery.
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (!mounted) return;
            if (state.mood == CompanionMood.speaking) {
              state = state.copyWith(mood: CompanionMood.idle);
            }
          });
        }
      }
    }
  }

  Future<void> _persist() async {
    final conversation = CompanionConversation(
      threadKey: state.threadKey,
      characterCode: character.code,
      messages: state.messages.where((m) => !m.pending).toList(),
      updatedAt: DateTime.now(),
      mode: state.mode,
    );
    await repository.saveConversation(conversation);
  }
}

class CompanionChatKey {
  const CompanionChatKey({required this.threadKey, this.mode = 'default'});

  final String threadKey;
  final String mode;

  @override
  bool operator ==(Object other) {
    return other is CompanionChatKey &&
        other.threadKey == threadKey &&
        other.mode == mode;
  }

  @override
  int get hashCode => Object.hash(threadKey, mode);
}

final companionChatProvider = StateNotifierProvider.family<
    CompanionChatNotifier, CompanionChatState, CompanionChatKey>((ref, key) {
  final character = ref.watch(
    companionProvider.select((s) => s.activeCharacter ?? CompanionCharacter.naomi),
  );
  final notifier = CompanionChatNotifier(
    threadKey: key.threadKey,
    mode: key.mode,
    repository: ref.watch(companionRepositoryProvider),
    character: character,
  );
  notifier.load();
  return notifier;
});
