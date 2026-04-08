// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accountability_check_in.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AccountabilityCheckIn _$AccountabilityCheckInFromJson(
    Map<String, dynamic> json) {
  return _AccountabilityCheckIn.fromJson(json);
}

/// @nodoc
mixin _$AccountabilityCheckIn {
  String get id => throw _privateConstructorUsedError;
  String get requesterUserId => throw _privateConstructorUsedError;
  String get partnerUserId => throw _privateConstructorUsedError;
  DateTime get weekStartDate => throw _privateConstructorUsedError;
  String? get requesterNote => throw _privateConstructorUsedError;
  List<String>? get verifiedCommitmentIds => throw _privateConstructorUsedError;
  DateTime get requestedAt => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;
  String? get confirmationNote => throw _privateConstructorUsedError;
  List<String>? get partnerVerifiedCommitments =>
      throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get weekStreak => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // Nested user info (populated when fetching)
  Map<String, dynamic>? get requester => throw _privateConstructorUsedError;
  Map<String, dynamic>? get partner => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AccountabilityCheckInCopyWith<AccountabilityCheckIn> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountabilityCheckInCopyWith<$Res> {
  factory $AccountabilityCheckInCopyWith(AccountabilityCheckIn value,
          $Res Function(AccountabilityCheckIn) then) =
      _$AccountabilityCheckInCopyWithImpl<$Res, AccountabilityCheckIn>;
  @useResult
  $Res call(
      {String id,
      String requesterUserId,
      String partnerUserId,
      DateTime weekStartDate,
      String? requesterNote,
      List<String>? verifiedCommitmentIds,
      DateTime requestedAt,
      DateTime? confirmedAt,
      String? confirmationNote,
      List<String>? partnerVerifiedCommitments,
      String status,
      int weekStreak,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt,
      Map<String, dynamic>? requester,
      Map<String, dynamic>? partner});
}

/// @nodoc
class _$AccountabilityCheckInCopyWithImpl<$Res,
        $Val extends AccountabilityCheckIn>
    implements $AccountabilityCheckInCopyWith<$Res> {
  _$AccountabilityCheckInCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requesterUserId = null,
    Object? partnerUserId = null,
    Object? weekStartDate = null,
    Object? requesterNote = freezed,
    Object? verifiedCommitmentIds = freezed,
    Object? requestedAt = null,
    Object? confirmedAt = freezed,
    Object? confirmationNote = freezed,
    Object? partnerVerifiedCommitments = freezed,
    Object? status = null,
    Object? weekStreak = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? requester = freezed,
    Object? partner = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      requesterUserId: null == requesterUserId
          ? _value.requesterUserId
          : requesterUserId // ignore: cast_nullable_to_non_nullable
              as String,
      partnerUserId: null == partnerUserId
          ? _value.partnerUserId
          : partnerUserId // ignore: cast_nullable_to_non_nullable
              as String,
      weekStartDate: null == weekStartDate
          ? _value.weekStartDate
          : weekStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requesterNote: freezed == requesterNote
          ? _value.requesterNote
          : requesterNote // ignore: cast_nullable_to_non_nullable
              as String?,
      verifiedCommitmentIds: freezed == verifiedCommitmentIds
          ? _value.verifiedCommitmentIds
          : verifiedCommitmentIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmationNote: freezed == confirmationNote
          ? _value.confirmationNote
          : confirmationNote // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerVerifiedCommitments: freezed == partnerVerifiedCommitments
          ? _value.partnerVerifiedCommitments
          : partnerVerifiedCommitments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      weekStreak: null == weekStreak
          ? _value.weekStreak
          : weekStreak // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      requester: freezed == requester
          ? _value.requester
          : requester // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      partner: freezed == partner
          ? _value.partner
          : partner // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AccountabilityCheckInImplCopyWith<$Res>
    implements $AccountabilityCheckInCopyWith<$Res> {
  factory _$$AccountabilityCheckInImplCopyWith(
          _$AccountabilityCheckInImpl value,
          $Res Function(_$AccountabilityCheckInImpl) then) =
      __$$AccountabilityCheckInImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String requesterUserId,
      String partnerUserId,
      DateTime weekStartDate,
      String? requesterNote,
      List<String>? verifiedCommitmentIds,
      DateTime requestedAt,
      DateTime? confirmedAt,
      String? confirmationNote,
      List<String>? partnerVerifiedCommitments,
      String status,
      int weekStreak,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt,
      Map<String, dynamic>? requester,
      Map<String, dynamic>? partner});
}

/// @nodoc
class __$$AccountabilityCheckInImplCopyWithImpl<$Res>
    extends _$AccountabilityCheckInCopyWithImpl<$Res,
        _$AccountabilityCheckInImpl>
    implements _$$AccountabilityCheckInImplCopyWith<$Res> {
  __$$AccountabilityCheckInImplCopyWithImpl(_$AccountabilityCheckInImpl _value,
      $Res Function(_$AccountabilityCheckInImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requesterUserId = null,
    Object? partnerUserId = null,
    Object? weekStartDate = null,
    Object? requesterNote = freezed,
    Object? verifiedCommitmentIds = freezed,
    Object? requestedAt = null,
    Object? confirmedAt = freezed,
    Object? confirmationNote = freezed,
    Object? partnerVerifiedCommitments = freezed,
    Object? status = null,
    Object? weekStreak = null,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? requester = freezed,
    Object? partner = freezed,
  }) {
    return _then(_$AccountabilityCheckInImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      requesterUserId: null == requesterUserId
          ? _value.requesterUserId
          : requesterUserId // ignore: cast_nullable_to_non_nullable
              as String,
      partnerUserId: null == partnerUserId
          ? _value.partnerUserId
          : partnerUserId // ignore: cast_nullable_to_non_nullable
              as String,
      weekStartDate: null == weekStartDate
          ? _value.weekStartDate
          : weekStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requesterNote: freezed == requesterNote
          ? _value.requesterNote
          : requesterNote // ignore: cast_nullable_to_non_nullable
              as String?,
      verifiedCommitmentIds: freezed == verifiedCommitmentIds
          ? _value._verifiedCommitmentIds
          : verifiedCommitmentIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmationNote: freezed == confirmationNote
          ? _value.confirmationNote
          : confirmationNote // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerVerifiedCommitments: freezed == partnerVerifiedCommitments
          ? _value._partnerVerifiedCommitments
          : partnerVerifiedCommitments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      weekStreak: null == weekStreak
          ? _value.weekStreak
          : weekStreak // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      requester: freezed == requester
          ? _value._requester
          : requester // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      partner: freezed == partner
          ? _value._partner
          : partner // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AccountabilityCheckInImpl implements _AccountabilityCheckIn {
  const _$AccountabilityCheckInImpl(
      {required this.id,
      required this.requesterUserId,
      required this.partnerUserId,
      required this.weekStartDate,
      this.requesterNote,
      final List<String>? verifiedCommitmentIds,
      required this.requestedAt,
      this.confirmedAt,
      this.confirmationNote,
      final List<String>? partnerVerifiedCommitments,
      this.status = 'pending',
      this.weekStreak = 0,
      final Map<String, dynamic>? metadata,
      this.createdAt,
      this.updatedAt,
      final Map<String, dynamic>? requester,
      final Map<String, dynamic>? partner})
      : _verifiedCommitmentIds = verifiedCommitmentIds,
        _partnerVerifiedCommitments = partnerVerifiedCommitments,
        _metadata = metadata,
        _requester = requester,
        _partner = partner;

  factory _$AccountabilityCheckInImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountabilityCheckInImplFromJson(json);

  @override
  final String id;
  @override
  final String requesterUserId;
  @override
  final String partnerUserId;
  @override
  final DateTime weekStartDate;
  @override
  final String? requesterNote;
  final List<String>? _verifiedCommitmentIds;
  @override
  List<String>? get verifiedCommitmentIds {
    final value = _verifiedCommitmentIds;
    if (value == null) return null;
    if (_verifiedCommitmentIds is EqualUnmodifiableListView)
      return _verifiedCommitmentIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime requestedAt;
  @override
  final DateTime? confirmedAt;
  @override
  final String? confirmationNote;
  final List<String>? _partnerVerifiedCommitments;
  @override
  List<String>? get partnerVerifiedCommitments {
    final value = _partnerVerifiedCommitments;
    if (value == null) return null;
    if (_partnerVerifiedCommitments is EqualUnmodifiableListView)
      return _partnerVerifiedCommitments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final int weekStreak;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
// Nested user info (populated when fetching)
  final Map<String, dynamic>? _requester;
// Nested user info (populated when fetching)
  @override
  Map<String, dynamic>? get requester {
    final value = _requester;
    if (value == null) return null;
    if (_requester is EqualUnmodifiableMapView) return _requester;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _partner;
  @override
  Map<String, dynamic>? get partner {
    final value = _partner;
    if (value == null) return null;
    if (_partner is EqualUnmodifiableMapView) return _partner;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AccountabilityCheckIn(id: $id, requesterUserId: $requesterUserId, partnerUserId: $partnerUserId, weekStartDate: $weekStartDate, requesterNote: $requesterNote, verifiedCommitmentIds: $verifiedCommitmentIds, requestedAt: $requestedAt, confirmedAt: $confirmedAt, confirmationNote: $confirmationNote, partnerVerifiedCommitments: $partnerVerifiedCommitments, status: $status, weekStreak: $weekStreak, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt, requester: $requester, partner: $partner)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountabilityCheckInImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requesterUserId, requesterUserId) ||
                other.requesterUserId == requesterUserId) &&
            (identical(other.partnerUserId, partnerUserId) ||
                other.partnerUserId == partnerUserId) &&
            (identical(other.weekStartDate, weekStartDate) ||
                other.weekStartDate == weekStartDate) &&
            (identical(other.requesterNote, requesterNote) ||
                other.requesterNote == requesterNote) &&
            const DeepCollectionEquality()
                .equals(other._verifiedCommitmentIds, _verifiedCommitmentIds) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.confirmationNote, confirmationNote) ||
                other.confirmationNote == confirmationNote) &&
            const DeepCollectionEquality().equals(
                other._partnerVerifiedCommitments,
                _partnerVerifiedCommitments) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.weekStreak, weekStreak) ||
                other.weekStreak == weekStreak) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._requester, _requester) &&
            const DeepCollectionEquality().equals(other._partner, _partner));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      requesterUserId,
      partnerUserId,
      weekStartDate,
      requesterNote,
      const DeepCollectionEquality().hash(_verifiedCommitmentIds),
      requestedAt,
      confirmedAt,
      confirmationNote,
      const DeepCollectionEquality().hash(_partnerVerifiedCommitments),
      status,
      weekStreak,
      const DeepCollectionEquality().hash(_metadata),
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_requester),
      const DeepCollectionEquality().hash(_partner));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountabilityCheckInImplCopyWith<_$AccountabilityCheckInImpl>
      get copyWith => __$$AccountabilityCheckInImplCopyWithImpl<
          _$AccountabilityCheckInImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountabilityCheckInImplToJson(
      this,
    );
  }
}

abstract class _AccountabilityCheckIn implements AccountabilityCheckIn {
  const factory _AccountabilityCheckIn(
      {required final String id,
      required final String requesterUserId,
      required final String partnerUserId,
      required final DateTime weekStartDate,
      final String? requesterNote,
      final List<String>? verifiedCommitmentIds,
      required final DateTime requestedAt,
      final DateTime? confirmedAt,
      final String? confirmationNote,
      final List<String>? partnerVerifiedCommitments,
      final String status,
      final int weekStreak,
      final Map<String, dynamic>? metadata,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final Map<String, dynamic>? requester,
      final Map<String, dynamic>? partner}) = _$AccountabilityCheckInImpl;

  factory _AccountabilityCheckIn.fromJson(Map<String, dynamic> json) =
      _$AccountabilityCheckInImpl.fromJson;

  @override
  String get id;
  @override
  String get requesterUserId;
  @override
  String get partnerUserId;
  @override
  DateTime get weekStartDate;
  @override
  String? get requesterNote;
  @override
  List<String>? get verifiedCommitmentIds;
  @override
  DateTime get requestedAt;
  @override
  DateTime? get confirmedAt;
  @override
  String? get confirmationNote;
  @override
  List<String>? get partnerVerifiedCommitments;
  @override
  String get status;
  @override
  int get weekStreak;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override // Nested user info (populated when fetching)
  Map<String, dynamic>? get requester;
  @override
  Map<String, dynamic>? get partner;
  @override
  @JsonKey(ignore: true)
  _$$AccountabilityCheckInImplCopyWith<_$AccountabilityCheckInImpl>
      get copyWith => throw _privateConstructorUsedError;
}
