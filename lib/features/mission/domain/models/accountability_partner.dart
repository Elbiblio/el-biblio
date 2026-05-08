import 'check_in_request.dart';

class AccountabilityPartner {
  const AccountabilityPartner({
    required this.name,
    required this.relationship,
    required this.contact,
    this.lastCheckInAt,
    this.lastCheckInNote,
    this.partnerType = PartnerType.peer,
    this.pendingCheckInRequest,
    this.weeklyStreak = 0,
    this.companionCode,
  });

  final String name;
  final String relationship;
  final String contact;
  final DateTime? lastCheckInAt;
  final String? lastCheckInNote;
  final PartnerType partnerType;
  final CheckInRequest? pendingCheckInRequest;
  final int weeklyStreak;

  /// Set only for AI-companion partners. Maps to `CompanionCharacter.code`
  /// (`raziel` / `naomi` / `james`). Null for human partners.
  final String? companionCode;

  bool get isAiCompanion => partnerType == PartnerType.aiCompanion;

  /// Factory for an AI accountability partner. Contact is empty — the chat
  /// thread IS the contact surface.
  factory AccountabilityPartner.aiCompanion({
    required String companionCode,
    required String displayName,
  }) {
    return AccountabilityPartner(
      name: displayName,
      relationship: 'Companion',
      contact: '',
      partnerType: PartnerType.aiCompanion,
      companionCode: companionCode,
    );
  }

  factory AccountabilityPartner.fromMap(Map<String, dynamic> map) {
    return AccountabilityPartner(
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      lastCheckInAt: map['lastCheckInAt'] == null
          ? null
          : DateTime.tryParse(map['lastCheckInAt'] as String),
      lastCheckInNote: map['lastCheckInNote'] as String?,
      partnerType: PartnerTypeX.fromStorage(map['partnerType'] as String?),
      pendingCheckInRequest: map['pendingCheckInRequest'] == null
          ? null
          : CheckInRequest.fromMap(map['pendingCheckInRequest'] as Map<String, dynamic>),
      weeklyStreak: map['weeklyStreak'] as int? ?? 0,
      companionCode: map['companionCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'contact': contact,
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'lastCheckInNote': lastCheckInNote,
      'partnerType': partnerType.name,
      'pendingCheckInRequest': pendingCheckInRequest?.toMap(),
      'weeklyStreak': weeklyStreak,
      'companionCode': companionCode,
    };
  }

  AccountabilityPartner copyWith({
    String? name,
    String? relationship,
    String? contact,
    DateTime? lastCheckInAt,
    String? lastCheckInNote,
    PartnerType? partnerType,
    CheckInRequest? pendingCheckInRequest,
    int? weeklyStreak,
    String? companionCode,
  }) {
    return AccountabilityPartner(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      contact: contact ?? this.contact,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      lastCheckInNote: lastCheckInNote ?? this.lastCheckInNote,
      partnerType: partnerType ?? this.partnerType,
      pendingCheckInRequest: pendingCheckInRequest ?? this.pendingCheckInRequest,
      weeklyStreak: weeklyStreak ?? this.weeklyStreak,
      companionCode: companionCode ?? this.companionCode,
    );
  }
}
