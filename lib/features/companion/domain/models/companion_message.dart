enum CompanionMessageRole { user, assistant, system, tool }

extension CompanionMessageRoleX on CompanionMessageRole {
  String get storageValue => switch (this) {
        CompanionMessageRole.user => 'user',
        CompanionMessageRole.assistant => 'assistant',
        CompanionMessageRole.system => 'system',
        CompanionMessageRole.tool => 'tool',
      };

  static CompanionMessageRole fromStorage(String? raw) {
    return CompanionMessageRole.values.firstWhere(
      (r) => r.storageValue == raw,
      orElse: () => CompanionMessageRole.assistant,
    );
  }
}

class CompanionMessage {
  const CompanionMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.characterCode,
    this.pending = false,
    this.error,
  });

  final String id;
  final CompanionMessageRole role;
  final String content;
  final DateTime createdAt;
  final String? characterCode;

  /// True while the assistant reply is still streaming/awaiting backend.
  final bool pending;
  final String? error;

  bool get isUser => role == CompanionMessageRole.user;
  bool get isAssistant => role == CompanionMessageRole.assistant;

  CompanionMessage copyWith({
    String? content,
    bool? pending,
    String? error,
  }) {
    return CompanionMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      characterCode: characterCode,
      pending: pending ?? this.pending,
      error: error,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.storageValue,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'characterCode': characterCode,
      };

  factory CompanionMessage.fromMap(Map<String, dynamic> map) {
    return CompanionMessage(
      id: map['id'] as String,
      role: CompanionMessageRoleX.fromStorage(map['role'] as String?),
      content: map['content'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      characterCode: map['characterCode'] as String?,
    );
  }
}
