import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../domain/models/companion_character.dart';
import '../domain/models/companion_conversation.dart';

/// Bridges the companion feature to the backend and to on-device persistence.
///
/// The backend endpoints (`/companion/*`) may not yet exist in every
/// environment. Every API call degrades gracefully into a templated local
/// response so the UX never collapses while backend work catches up.
class CompanionRepository {
  CompanionRepository(this._dio, this._logger);

  final DioClient _dio;
  final Logger _logger;

  static const _conversationsKey = 'companion_conversations_v1';

  Future<void> selectCharacter(CompanionCharacter character) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/companion/select',
        data: {'character_code': character.code},
      );
    } catch (e) {
      _logger.w('[Companion] select backend call failed (non-fatal): $e');
      // Local selection still persists via settings; backend sync retries later.
    }
  }

  /// One-shot, non-streaming chat call. Client renders the assistant reply
  /// once the full payload arrives. Streaming upgrade (SSE) is Phase 2.
  Future<String> chat({
    required String threadKey,
    required CompanionCharacter character,
    required String message,
    String mode = 'default',
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/companion/chat',
        data: {
          'thread_key': threadKey,
          'character_code': character.code,
          'message': message,
          'mode': mode,
          if (context != null) 'context': context,
          if (history != null) 'history': history,
        },
      );
      final data = response.data;
      if (data == null) return _fallbackReply(character, mode);

      // Laravel convention: `{ success, data: { reply }, message }`
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
      final reply = payload['reply'] as String?;
      if (reply != null && reply.trim().isNotEmpty) return reply;
      return _fallbackReply(character, mode);
    } catch (e) {
      _logger.w('[Companion] chat failed, using local fallback: $e');
      return _fallbackReply(character, mode);
    }
  }

  /// Streams the assistant reply token-chunk at a time. Emits an initial empty
  /// string so the UI can flip to `speaking` mood on first-token. Falls back
  /// to the templated one-shot reply if SSE is unavailable.
  ///
  /// Expected SSE event format (per backend contract):
  ///   data: {"delta": "Hi "}
  ///   data: {"delta": "there"}
  ///   data: {"done": true}
  Stream<String> chatStream({
    required String threadKey,
    required CompanionCharacter character,
    required String message,
    String mode = 'default',
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async* {
    try {
      final response = await _dio.raw.post<ResponseBody>(
        '/companion/chat/stream',
        data: {
          'thread_key': threadKey,
          'character_code': character.code,
          'message': message,
          'mode': mode,
          if (context != null) 'context': context,
          if (history != null) 'history': history,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final body = response.data;
      if (body == null || (response.statusCode ?? 500) >= 400) {
        yield await chat(
          threadKey: threadKey,
          character: character,
          message: message,
          mode: mode,
          context: context,
          history: history,
        );
        return;
      }

      final buffer = StringBuffer();
      var emittedAny = false;
      await for (final chunk
          in body.stream.cast<List<int>>().transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final payload = trimmed.startsWith('data:')
              ? trimmed.substring(5).trim()
              : trimmed;
          if (payload == '[DONE]' || payload.isEmpty) continue;
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) {
              if (decoded['done'] == true) {
                return;
              }
              final delta = decoded['delta'] as String?;
              if (delta != null && delta.isNotEmpty) {
                buffer.write(delta);
                emittedAny = true;
                yield buffer.toString();
              }
            }
          } catch (_) {
            // Malformed frame — skip quietly; continue accumulating.
          }
        }
      }

      if (!emittedAny) {
        yield await chat(
          threadKey: threadKey,
          character: character,
          message: message,
          mode: mode,
          context: context,
          history: history,
        );
      }
    } catch (e) {
      _logger.w('[Companion] chatStream failed, falling back: $e');
      yield await chat(
        threadKey: threadKey,
        character: character,
        message: message,
        mode: mode,
        context: context,
      );
    }
  }

  /// Short proactive line for the Today-screen bubble.
  Future<String> todayNudge({
    required CompanionCharacter character,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/companion/nudge/today',
        data: {
          'character_code': character.code,
          if (context != null) 'context': context,
        },
      );
      final data = response.data;
      if (data == null) return _fallbackNudge(character);
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
      final nudge = payload['nudge'] as String? ?? payload['reply'] as String?;
      if (nudge != null && nudge.trim().isNotEmpty) return nudge;
      return _fallbackNudge(character);
    } catch (e) {
      _logger.w('[Companion] todayNudge failed, using fallback: $e');
      return _fallbackNudge(character);
    }
  }

  Future<void> saveChristianLifeBaseline(Map<String, dynamic> payload) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/christian-life-baselines',
        data: payload,
      );
    } catch (e) {
      _logger.w('[Companion] baseline sync failed (non-fatal): $e');
    }
  }

  // ─── Local conversation persistence ────────────────────────────────

  Future<List<CompanionConversation>> loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_conversationsKey) ?? const <String>[];
      return raw
          .map(_decodeConversation)
          .whereType<CompanionConversation>()
          .toList();
    } catch (e) {
      _logger.w('[Companion] loadConversations failed: $e');
      return const [];
    }
  }

  Future<CompanionConversation?> loadConversation(String threadKey) async {
    final all = await loadConversations();
    try {
      return all.firstWhere((c) => c.threadKey == threadKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConversation(CompanionConversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await loadConversations();
      final filtered = existing
          .where((c) => c.threadKey != conversation.threadKey)
          .toList()
        ..add(conversation);
      final encoded = filtered.map(_encodeConversation).toList();
      await prefs.setStringList(_conversationsKey, encoded);
    } catch (e) {
      _logger.w('[Companion] saveConversation failed: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _encodeConversation(CompanionConversation c) =>
      jsonEncode(c.toMap());

  CompanionConversation? _decodeConversation(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CompanionConversation.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      _logger.w('[Companion] decode failed: $e');
      return null;
    }
  }

  String _fallbackReply(CompanionCharacter character, String mode) {
    if (mode == 'hard_questions') {
      return switch (character) {
        CompanionCharacter.raziel =>
          'That is a real question, and it deserves a real answer. My connection is thin right now — let\'s hold it together until I can bring you Scripture and tradition on it.',
        CompanionCharacter.naomi =>
          'I hear you. Hard questions are not the enemy of faith; avoiding them is. My voice is catching — try me again in a moment and we\'ll sit with this.',
        CompanionCharacter.james =>
          'Good question. I\'d rather give you a real answer than a filler one, and my signal is weak. Try again in a minute and we\'ll work through it.',
      };
    }
    return switch (character) {
      CompanionCharacter.raziel =>
        'I\'m with you — my voice is a little quiet right now. Sit for a moment; tell me again, and I\'ll listen.',
      CompanionCharacter.naomi =>
        'Take a breath — I\'m here. My signal is weak; try me again in a moment, and we\'ll continue.',
      CompanionCharacter.james =>
        'Hold that thought — signal\'s thin. Say it again in a minute and we\'ll keep going.',
    };
  }

  String _fallbackNudge(CompanionCharacter character) {
    return switch (character) {
      CompanionCharacter.raziel =>
        'What\'s one question the Word could sit beside today?',
      CompanionCharacter.naomi =>
        'Three minutes with a Psalm is enough. Want to open one together?',
      CompanionCharacter.james =>
        'One small, doable step. What\'s today\'s?',
    };
  }
}
