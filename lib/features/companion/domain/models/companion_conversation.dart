import 'companion_message.dart';

class CompanionConversation {
  const CompanionConversation({
    required this.threadKey,
    required this.characterCode,
    required this.messages,
    required this.updatedAt,
    this.mode = 'default',
  });

  final String threadKey;
  final String characterCode;
  final List<CompanionMessage> messages;
  final DateTime updatedAt;

  /// `default` | `hard_questions` | `accountability` — controls backend prompt branch.
  final String mode;

  CompanionConversation copyWith({
    List<CompanionMessage>? messages,
    DateTime? updatedAt,
    String? mode,
  }) {
    return CompanionConversation(
      threadKey: threadKey,
      characterCode: characterCode,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toMap() => {
        'threadKey': threadKey,
        'characterCode': characterCode,
        'messages': messages.map((m) => m.toMap()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
        'mode': mode,
      };

  factory CompanionConversation.fromMap(Map<String, dynamic> map) {
    final rawMessages = map['messages'] as List<dynamic>? ?? const [];
    return CompanionConversation(
      threadKey: map['threadKey'] as String,
      characterCode: map['characterCode'] as String,
      messages: rawMessages
          .whereType<Map>()
          .map((m) => CompanionMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      mode: map['mode'] as String? ?? 'default',
    );
  }
}
