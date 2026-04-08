// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_opportunity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ServiceOpportunity _$ServiceOpportunityFromJson(Map<String, dynamic> json) {
  return _ServiceOpportunity.fromJson(json);
}

/// @nodoc
mixin _$ServiceOpportunity {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get timeCommitment => throw _privateConstructorUsedError;
  String? get organization => throw _privateConstructorUsedError;
  String? get contactInfo => throw _privateConstructorUsedError;
  List<String>? get requiredSkills => throw _privateConstructorUsedError;
  List<String>? get burdenTags => throw _privateConstructorUsedError;
  List<String>? get tendencyTags => throw _privateConstructorUsedError;
  String get locationType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get volunteerCount => throw _privateConstructorUsedError;
  int? get maxVolunteers => throw _privateConstructorUsedError;
  DateTime? get startsAt => throw _privateConstructorUsedError;
  DateTime? get endsAt => throw _privateConstructorUsedError;
  String? get userMatchStatus => throw _privateConstructorUsedError;
  double? get matchScore => throw _privateConstructorUsedError;
  List<String>? get matchReasons => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ServiceOpportunityCopyWith<ServiceOpportunity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceOpportunityCopyWith<$Res> {
  factory $ServiceOpportunityCopyWith(
          ServiceOpportunity value, $Res Function(ServiceOpportunity) then) =
      _$ServiceOpportunityCopyWithImpl<$Res, ServiceOpportunity>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String category,
      String timeCommitment,
      String? organization,
      String? contactInfo,
      List<String>? requiredSkills,
      List<String>? burdenTags,
      List<String>? tendencyTags,
      String locationType,
      String status,
      int volunteerCount,
      int? maxVolunteers,
      DateTime? startsAt,
      DateTime? endsAt,
      String? userMatchStatus,
      double? matchScore,
      List<String>? matchReasons,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ServiceOpportunityCopyWithImpl<$Res, $Val extends ServiceOpportunity>
    implements $ServiceOpportunityCopyWith<$Res> {
  _$ServiceOpportunityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? category = null,
    Object? timeCommitment = null,
    Object? organization = freezed,
    Object? contactInfo = freezed,
    Object? requiredSkills = freezed,
    Object? burdenTags = freezed,
    Object? tendencyTags = freezed,
    Object? locationType = null,
    Object? status = null,
    Object? volunteerCount = null,
    Object? maxVolunteers = freezed,
    Object? startsAt = freezed,
    Object? endsAt = freezed,
    Object? userMatchStatus = freezed,
    Object? matchScore = freezed,
    Object? matchReasons = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      timeCommitment: null == timeCommitment
          ? _value.timeCommitment
          : timeCommitment // ignore: cast_nullable_to_non_nullable
              as String,
      organization: freezed == organization
          ? _value.organization
          : organization // ignore: cast_nullable_to_non_nullable
              as String?,
      contactInfo: freezed == contactInfo
          ? _value.contactInfo
          : contactInfo // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredSkills: freezed == requiredSkills
          ? _value.requiredSkills
          : requiredSkills // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      burdenTags: freezed == burdenTags
          ? _value.burdenTags
          : burdenTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tendencyTags: freezed == tendencyTags
          ? _value.tendencyTags
          : tendencyTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      locationType: null == locationType
          ? _value.locationType
          : locationType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      volunteerCount: null == volunteerCount
          ? _value.volunteerCount
          : volunteerCount // ignore: cast_nullable_to_non_nullable
              as int,
      maxVolunteers: freezed == maxVolunteers
          ? _value.maxVolunteers
          : maxVolunteers // ignore: cast_nullable_to_non_nullable
              as int?,
      startsAt: freezed == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userMatchStatus: freezed == userMatchStatus
          ? _value.userMatchStatus
          : userMatchStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      matchScore: freezed == matchScore
          ? _value.matchScore
          : matchScore // ignore: cast_nullable_to_non_nullable
              as double?,
      matchReasons: freezed == matchReasons
          ? _value.matchReasons
          : matchReasons // ignore: cast_nullable_to_non_nullable
              as List<String>?,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ServiceOpportunityImplCopyWith<$Res>
    implements $ServiceOpportunityCopyWith<$Res> {
  factory _$$ServiceOpportunityImplCopyWith(_$ServiceOpportunityImpl value,
          $Res Function(_$ServiceOpportunityImpl) then) =
      __$$ServiceOpportunityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String category,
      String timeCommitment,
      String? organization,
      String? contactInfo,
      List<String>? requiredSkills,
      List<String>? burdenTags,
      List<String>? tendencyTags,
      String locationType,
      String status,
      int volunteerCount,
      int? maxVolunteers,
      DateTime? startsAt,
      DateTime? endsAt,
      String? userMatchStatus,
      double? matchScore,
      List<String>? matchReasons,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ServiceOpportunityImplCopyWithImpl<$Res>
    extends _$ServiceOpportunityCopyWithImpl<$Res, _$ServiceOpportunityImpl>
    implements _$$ServiceOpportunityImplCopyWith<$Res> {
  __$$ServiceOpportunityImplCopyWithImpl(_$ServiceOpportunityImpl _value,
      $Res Function(_$ServiceOpportunityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? category = null,
    Object? timeCommitment = null,
    Object? organization = freezed,
    Object? contactInfo = freezed,
    Object? requiredSkills = freezed,
    Object? burdenTags = freezed,
    Object? tendencyTags = freezed,
    Object? locationType = null,
    Object? status = null,
    Object? volunteerCount = null,
    Object? maxVolunteers = freezed,
    Object? startsAt = freezed,
    Object? endsAt = freezed,
    Object? userMatchStatus = freezed,
    Object? matchScore = freezed,
    Object? matchReasons = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ServiceOpportunityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      timeCommitment: null == timeCommitment
          ? _value.timeCommitment
          : timeCommitment // ignore: cast_nullable_to_non_nullable
              as String,
      organization: freezed == organization
          ? _value.organization
          : organization // ignore: cast_nullable_to_non_nullable
              as String?,
      contactInfo: freezed == contactInfo
          ? _value.contactInfo
          : contactInfo // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredSkills: freezed == requiredSkills
          ? _value._requiredSkills
          : requiredSkills // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      burdenTags: freezed == burdenTags
          ? _value._burdenTags
          : burdenTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tendencyTags: freezed == tendencyTags
          ? _value._tendencyTags
          : tendencyTags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      locationType: null == locationType
          ? _value.locationType
          : locationType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      volunteerCount: null == volunteerCount
          ? _value.volunteerCount
          : volunteerCount // ignore: cast_nullable_to_non_nullable
              as int,
      maxVolunteers: freezed == maxVolunteers
          ? _value.maxVolunteers
          : maxVolunteers // ignore: cast_nullable_to_non_nullable
              as int?,
      startsAt: freezed == startsAt
          ? _value.startsAt
          : startsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endsAt: freezed == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      userMatchStatus: freezed == userMatchStatus
          ? _value.userMatchStatus
          : userMatchStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      matchScore: freezed == matchScore
          ? _value.matchScore
          : matchScore // ignore: cast_nullable_to_non_nullable
              as double?,
      matchReasons: freezed == matchReasons
          ? _value._matchReasons
          : matchReasons // ignore: cast_nullable_to_non_nullable
              as List<String>?,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ServiceOpportunityImpl implements _ServiceOpportunity {
  const _$ServiceOpportunityImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.category,
      required this.timeCommitment,
      this.organization,
      this.contactInfo,
      final List<String>? requiredSkills,
      final List<String>? burdenTags,
      final List<String>? tendencyTags,
      this.locationType = 'local',
      this.status = 'active',
      this.volunteerCount = 0,
      this.maxVolunteers,
      this.startsAt,
      this.endsAt,
      this.userMatchStatus,
      this.matchScore,
      final List<String>? matchReasons,
      final Map<String, dynamic>? metadata,
      this.createdAt,
      this.updatedAt})
      : _requiredSkills = requiredSkills,
        _burdenTags = burdenTags,
        _tendencyTags = tendencyTags,
        _matchReasons = matchReasons,
        _metadata = metadata;

  factory _$ServiceOpportunityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ServiceOpportunityImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String category;
  @override
  final String timeCommitment;
  @override
  final String? organization;
  @override
  final String? contactInfo;
  final List<String>? _requiredSkills;
  @override
  List<String>? get requiredSkills {
    final value = _requiredSkills;
    if (value == null) return null;
    if (_requiredSkills is EqualUnmodifiableListView) return _requiredSkills;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _burdenTags;
  @override
  List<String>? get burdenTags {
    final value = _burdenTags;
    if (value == null) return null;
    if (_burdenTags is EqualUnmodifiableListView) return _burdenTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _tendencyTags;
  @override
  List<String>? get tendencyTags {
    final value = _tendencyTags;
    if (value == null) return null;
    if (_tendencyTags is EqualUnmodifiableListView) return _tendencyTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final String locationType;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final int volunteerCount;
  @override
  final int? maxVolunteers;
  @override
  final DateTime? startsAt;
  @override
  final DateTime? endsAt;
  @override
  final String? userMatchStatus;
  @override
  final double? matchScore;
  final List<String>? _matchReasons;
  @override
  List<String>? get matchReasons {
    final value = _matchReasons;
    if (value == null) return null;
    if (_matchReasons is EqualUnmodifiableListView) return _matchReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

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

  @override
  String toString() {
    return 'ServiceOpportunity(id: $id, title: $title, description: $description, category: $category, timeCommitment: $timeCommitment, organization: $organization, contactInfo: $contactInfo, requiredSkills: $requiredSkills, burdenTags: $burdenTags, tendencyTags: $tendencyTags, locationType: $locationType, status: $status, volunteerCount: $volunteerCount, maxVolunteers: $maxVolunteers, startsAt: $startsAt, endsAt: $endsAt, userMatchStatus: $userMatchStatus, matchScore: $matchScore, matchReasons: $matchReasons, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceOpportunityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.timeCommitment, timeCommitment) ||
                other.timeCommitment == timeCommitment) &&
            (identical(other.organization, organization) ||
                other.organization == organization) &&
            (identical(other.contactInfo, contactInfo) ||
                other.contactInfo == contactInfo) &&
            const DeepCollectionEquality()
                .equals(other._requiredSkills, _requiredSkills) &&
            const DeepCollectionEquality()
                .equals(other._burdenTags, _burdenTags) &&
            const DeepCollectionEquality()
                .equals(other._tendencyTags, _tendencyTags) &&
            (identical(other.locationType, locationType) ||
                other.locationType == locationType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.volunteerCount, volunteerCount) ||
                other.volunteerCount == volunteerCount) &&
            (identical(other.maxVolunteers, maxVolunteers) ||
                other.maxVolunteers == maxVolunteers) &&
            (identical(other.startsAt, startsAt) ||
                other.startsAt == startsAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.userMatchStatus, userMatchStatus) ||
                other.userMatchStatus == userMatchStatus) &&
            (identical(other.matchScore, matchScore) ||
                other.matchScore == matchScore) &&
            const DeepCollectionEquality()
                .equals(other._matchReasons, _matchReasons) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        title,
        description,
        category,
        timeCommitment,
        organization,
        contactInfo,
        const DeepCollectionEquality().hash(_requiredSkills),
        const DeepCollectionEquality().hash(_burdenTags),
        const DeepCollectionEquality().hash(_tendencyTags),
        locationType,
        status,
        volunteerCount,
        maxVolunteers,
        startsAt,
        endsAt,
        userMatchStatus,
        matchScore,
        const DeepCollectionEquality().hash(_matchReasons),
        const DeepCollectionEquality().hash(_metadata),
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceOpportunityImplCopyWith<_$ServiceOpportunityImpl> get copyWith =>
      __$$ServiceOpportunityImplCopyWithImpl<_$ServiceOpportunityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ServiceOpportunityImplToJson(
      this,
    );
  }
}

abstract class _ServiceOpportunity implements ServiceOpportunity {
  const factory _ServiceOpportunity(
      {required final String id,
      required final String title,
      required final String description,
      required final String category,
      required final String timeCommitment,
      final String? organization,
      final String? contactInfo,
      final List<String>? requiredSkills,
      final List<String>? burdenTags,
      final List<String>? tendencyTags,
      final String locationType,
      final String status,
      final int volunteerCount,
      final int? maxVolunteers,
      final DateTime? startsAt,
      final DateTime? endsAt,
      final String? userMatchStatus,
      final double? matchScore,
      final List<String>? matchReasons,
      final Map<String, dynamic>? metadata,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ServiceOpportunityImpl;

  factory _ServiceOpportunity.fromJson(Map<String, dynamic> json) =
      _$ServiceOpportunityImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get category;
  @override
  String get timeCommitment;
  @override
  String? get organization;
  @override
  String? get contactInfo;
  @override
  List<String>? get requiredSkills;
  @override
  List<String>? get burdenTags;
  @override
  List<String>? get tendencyTags;
  @override
  String get locationType;
  @override
  String get status;
  @override
  int get volunteerCount;
  @override
  int? get maxVolunteers;
  @override
  DateTime? get startsAt;
  @override
  DateTime? get endsAt;
  @override
  String? get userMatchStatus;
  @override
  double? get matchScore;
  @override
  List<String>? get matchReasons;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ServiceOpportunityImplCopyWith<_$ServiceOpportunityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
