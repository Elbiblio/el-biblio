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
  });

  final String name;
  final String relationship;
  final String contact;
  final DateTime? lastCheckInAt;
  final String? lastCheckInNote;
  final PartnerType partnerType;
  final CheckInRequest? pendingCheckInRequest;
  final int weeklyStreak;

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
    );
  }
}
