import 'package:json_annotation/json_annotation.dart';

part 'social_models.g.dart';

enum ContactStatus {
  pending,
  connected,
  declined,
  blocked,
  unknown,
}

@JsonSerializable()
class Contact {
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'contact_user_id')
  final int? contactUserId;
  @JsonKey(name: 'contact_hash')
  final String? contactHash;
  @JsonKey(name: 'display_name')
  final String displayName;
  final ContactStatus status;
  @JsonKey(name: 'is_anonymous')
  final bool isAnonymous;
  @JsonKey(name: 'share_presence')
  final bool sharePresence;
  @JsonKey(name: 'can_see_presence')
  final bool canSeePresence;
  @JsonKey(name: 'last_active_at')
  final DateTime? lastActiveAt;

  // Local-only fields for device contacts
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? deviceId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? phoneNumber;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? email;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<int>? avatar;

  const Contact({
    this.id,
    this.userId,
    this.contactUserId,
    this.contactHash,
    required this.displayName,
    this.status = ContactStatus.unknown,
    this.isAnonymous = true,
    this.sharePresence = true,
    this.canSeePresence = true,
    this.lastActiveAt,
    this.deviceId,
    this.phoneNumber,
    this.email,
    this.avatar,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => _$ContactFromJson(json);
  Map<String, dynamic> toJson() => _$ContactToJson(this);

  Contact copyWith({
    int? id,
    int? userId,
    int? contactUserId,
    String? contactHash,
    String? displayName,
    ContactStatus? status,
    bool? isAnonymous,
    bool? sharePresence,
    bool? canSeePresence,
    DateTime? lastActiveAt,
    String? deviceId,
    String? phoneNumber,
    String? email,
    List<int>? avatar,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUserId: contactUserId ?? this.contactUserId,
      contactHash: contactHash ?? this.contactHash,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      sharePresence: sharePresence ?? this.sharePresence,
      canSeePresence: canSeePresence ?? this.canSeePresence,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      deviceId: deviceId ?? this.deviceId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }
}

@JsonSerializable()
class ContactInvitation {
  final int id;
  @JsonKey(name: 'invited_email')
  final String? invitedEmail;
  @JsonKey(name: 'invited_phone')
  final String? invitedPhone;
  final String status;
  @JsonKey(name: 'invitation_url')
  final String? invitationUrl;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  const ContactInvitation({
    required this.id,
    this.invitedEmail,
    this.invitedPhone,
    required this.status,
    this.invitationUrl,
    required this.expiresAt,
  });

  factory ContactInvitation.fromJson(Map<String, dynamic> json) =>
      _$ContactInvitationFromJson(json);
  Map<String, dynamic> toJson() => _$ContactInvitationToJson(this);
}
