/// Represents a check-in request between accountability partners
class CheckInRequest {
  const CheckInRequest({
    required this.id,
    required this.requestedAt,
    required this.requestedByUserId,
    required this.weekStartDate,
    this.note,
    this.confirmedAt,
    this.confirmedByUserId,
    this.confirmationNote,
    this.verifiedCommitments = const [],
  });

  final String id;
  final DateTime requestedAt;
  final String requestedByUserId;
  final DateTime weekStartDate;
  final String? note;
  final DateTime? confirmedAt;
  final String? confirmedByUserId;
  final String? confirmationNote;
  final List<String> verifiedCommitments;

  bool get isConfirmed => confirmedAt != null;
  bool get isPending => confirmedAt == null;

  factory CheckInRequest.fromMap(Map<String, dynamic> map) {
    return CheckInRequest(
      id: map['id'] as String,
      requestedAt: DateTime.tryParse(map['requestedAt']?.toString() ?? '') ?? DateTime.now(),
      requestedByUserId: map['requestedByUserId'] as String,
      weekStartDate: DateTime.tryParse(map['weekStartDate']?.toString() ?? '') ?? DateTime.now(),
      note: map['note'] as String?,
      confirmedAt: map['confirmedAt'] == null
          ? null
          : DateTime.parse(map['confirmedAt'] as String),
      confirmedByUserId: map['confirmedByUserId'] as String?,
      confirmationNote: map['confirmationNote'] as String?,
      verifiedCommitments: (map['verifiedCommitments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestedAt': requestedAt.toIso8601String(),
      'requestedByUserId': requestedByUserId,
      'weekStartDate': weekStartDate.toIso8601String(),
      'note': note,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'confirmedByUserId': confirmedByUserId,
      'confirmationNote': confirmationNote,
      'verifiedCommitments': verifiedCommitments,
    };
  }

  CheckInRequest copyWith({
    String? id,
    DateTime? requestedAt,
    String? requestedByUserId,
    DateTime? weekStartDate,
    String? note,
    DateTime? confirmedAt,
    String? confirmedByUserId,
    String? confirmationNote,
    List<String>? verifiedCommitments,
  }) {
    return CheckInRequest(
      id: id ?? this.id,
      requestedAt: requestedAt ?? this.requestedAt,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      note: note ?? this.note,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedByUserId: confirmedByUserId ?? this.confirmedByUserId,
      confirmationNote: confirmationNote ?? this.confirmationNote,
      verifiedCommitments: verifiedCommitments ?? this.verifiedCommitments,
    );
  }
}

/// Type of accountability partner relationship
enum PartnerType {
  peer,
  mentor,
  mentee,
  aiCompanion,
}

extension PartnerTypeX on PartnerType {
  String get label {
    switch (this) {
      case PartnerType.peer:
        return 'Peer';
      case PartnerType.mentor:
        return 'Mentor';
      case PartnerType.mentee:
        return 'Mentee';
      case PartnerType.aiCompanion:
        return 'AI companion';
    }
  }

  String get description {
    switch (this) {
      case PartnerType.peer:
        return 'Mutual accountability partner';
      case PartnerType.mentor:
        return 'Someone who guides and supports you';
      case PartnerType.mentee:
        return 'Someone you are mentoring';
      case PartnerType.aiCompanion:
        return 'Your chosen spiritual companion, walking with you until a human partner joins';
    }
  }

  static PartnerType fromStorage(String? value) {
    switch (value) {
      case 'mentor':
        return PartnerType.mentor;
      case 'mentee':
        return PartnerType.mentee;
      case 'aiCompanion':
      case 'ai_companion':
        return PartnerType.aiCompanion;
      case 'peer':
      default:
        return PartnerType.peer;
    }
  }
}
