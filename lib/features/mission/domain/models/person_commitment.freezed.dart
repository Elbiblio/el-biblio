// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'person_commitment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PersonCommitment _$PersonCommitmentFromJson(Map<String, dynamic> json) {
  return _PersonCommitment.fromJson(json);
}

/// @nodoc
mixin _$PersonCommitment {
  String get id => throw _privateConstructorUsedError;
  String get personProfileId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get relationship => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get needs => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get lastContactAt => throw _privateConstructorUsedError;
  DateTime? get nextFollowUpAt => throw _privateConstructorUsedError;
  List<String>? get committedActionIds => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PersonCommitmentCopyWith<PersonCommitment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonCommitmentCopyWith<$Res> {
  factory $PersonCommitmentCopyWith(
          PersonCommitment value, $Res Function(PersonCommitment) then) =
      _$PersonCommitmentCopyWithImpl<$Res, PersonCommitment>;
  @useResult
  $Res call(
      {String id,
      String personProfileId,
      String name,
      String relationship,
      String? notes,
      String? needs,
      List<String>? tags,
      bool isActive,
      DateTime? lastContactAt,
      DateTime? nextFollowUpAt,
      List<String>? committedActionIds,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$PersonCommitmentCopyWithImpl<$Res, $Val extends PersonCommitment>
    implements $PersonCommitmentCopyWith<$Res> {
  _$PersonCommitmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? personProfileId = null,
    Object? name = null,
    Object? relationship = null,
    Object? notes = freezed,
    Object? needs = freezed,
    Object? tags = freezed,
    Object? isActive = null,
    Object? lastContactAt = freezed,
    Object? nextFollowUpAt = freezed,
    Object? committedActionIds = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      personProfileId: null == personProfileId
          ? _value.personProfileId
          : personProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relationship: null == relationship
          ? _value.relationship
          : relationship // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      needs: freezed == needs
          ? _value.needs
          : needs // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      lastContactAt: freezed == lastContactAt
          ? _value.lastContactAt
          : lastContactAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextFollowUpAt: freezed == nextFollowUpAt
          ? _value.nextFollowUpAt
          : nextFollowUpAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      committedActionIds: freezed == committedActionIds
          ? _value.committedActionIds
          : committedActionIds // ignore: cast_nullable_to_non_nullable
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
abstract class _$$PersonCommitmentImplCopyWith<$Res>
    implements $PersonCommitmentCopyWith<$Res> {
  factory _$$PersonCommitmentImplCopyWith(_$PersonCommitmentImpl value,
          $Res Function(_$PersonCommitmentImpl) then) =
      __$$PersonCommitmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String personProfileId,
      String name,
      String relationship,
      String? notes,
      String? needs,
      List<String>? tags,
      bool isActive,
      DateTime? lastContactAt,
      DateTime? nextFollowUpAt,
      List<String>? committedActionIds,
      Map<String, dynamic>? metadata,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$PersonCommitmentImplCopyWithImpl<$Res>
    extends _$PersonCommitmentCopyWithImpl<$Res, _$PersonCommitmentImpl>
    implements _$$PersonCommitmentImplCopyWith<$Res> {
  __$$PersonCommitmentImplCopyWithImpl(_$PersonCommitmentImpl _value,
      $Res Function(_$PersonCommitmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? personProfileId = null,
    Object? name = null,
    Object? relationship = null,
    Object? notes = freezed,
    Object? needs = freezed,
    Object? tags = freezed,
    Object? isActive = null,
    Object? lastContactAt = freezed,
    Object? nextFollowUpAt = freezed,
    Object? committedActionIds = freezed,
    Object? metadata = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PersonCommitmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      personProfileId: null == personProfileId
          ? _value.personProfileId
          : personProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relationship: null == relationship
          ? _value.relationship
          : relationship // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      needs: freezed == needs
          ? _value.needs
          : needs // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      lastContactAt: freezed == lastContactAt
          ? _value.lastContactAt
          : lastContactAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      nextFollowUpAt: freezed == nextFollowUpAt
          ? _value.nextFollowUpAt
          : nextFollowUpAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      committedActionIds: freezed == committedActionIds
          ? _value._committedActionIds
          : committedActionIds // ignore: cast_nullable_to_non_nullable
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
class _$PersonCommitmentImpl implements _PersonCommitment {
  const _$PersonCommitmentImpl(
      {required this.id,
      required this.personProfileId,
      required this.name,
      required this.relationship,
      this.notes,
      this.needs,
      final List<String>? tags,
      this.isActive = true,
      this.lastContactAt,
      this.nextFollowUpAt,
      final List<String>? committedActionIds,
      final Map<String, dynamic>? metadata,
      this.createdAt,
      this.updatedAt})
      : _tags = tags,
        _committedActionIds = committedActionIds,
        _metadata = metadata;

  factory _$PersonCommitmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonCommitmentImplFromJson(json);

  @override
  final String id;
  @override
  final String personProfileId;
  @override
  final String name;
  @override
  final String relationship;
  @override
  final String? notes;
  @override
  final String? needs;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool isActive;
  @override
  final DateTime? lastContactAt;
  @override
  final DateTime? nextFollowUpAt;
  final List<String>? _committedActionIds;
  @override
  List<String>? get committedActionIds {
    final value = _committedActionIds;
    if (value == null) return null;
    if (_committedActionIds is EqualUnmodifiableListView)
      return _committedActionIds;
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
    return 'PersonCommitment(id: $id, personProfileId: $personProfileId, name: $name, relationship: $relationship, notes: $notes, needs: $needs, tags: $tags, isActive: $isActive, lastContactAt: $lastContactAt, nextFollowUpAt: $nextFollowUpAt, committedActionIds: $committedActionIds, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonCommitmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.personProfileId, personProfileId) ||
                other.personProfileId == personProfileId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relationship, relationship) ||
                other.relationship == relationship) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.needs, needs) || other.needs == needs) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.lastContactAt, lastContactAt) ||
                other.lastContactAt == lastContactAt) &&
            (identical(other.nextFollowUpAt, nextFollowUpAt) ||
                other.nextFollowUpAt == nextFollowUpAt) &&
            const DeepCollectionEquality()
                .equals(other._committedActionIds, _committedActionIds) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      personProfileId,
      name,
      relationship,
      notes,
      needs,
      const DeepCollectionEquality().hash(_tags),
      isActive,
      lastContactAt,
      nextFollowUpAt,
      const DeepCollectionEquality().hash(_committedActionIds),
      const DeepCollectionEquality().hash(_metadata),
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonCommitmentImplCopyWith<_$PersonCommitmentImpl> get copyWith =>
      __$$PersonCommitmentImplCopyWithImpl<_$PersonCommitmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonCommitmentImplToJson(
      this,
    );
  }
}

abstract class _PersonCommitment implements PersonCommitment {
  const factory _PersonCommitment(
      {required final String id,
      required final String personProfileId,
      required final String name,
      required final String relationship,
      final String? notes,
      final String? needs,
      final List<String>? tags,
      final bool isActive,
      final DateTime? lastContactAt,
      final DateTime? nextFollowUpAt,
      final List<String>? committedActionIds,
      final Map<String, dynamic>? metadata,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$PersonCommitmentImpl;

  factory _PersonCommitment.fromJson(Map<String, dynamic> json) =
      _$PersonCommitmentImpl.fromJson;

  @override
  String get id;
  @override
  String get personProfileId;
  @override
  String get name;
  @override
  String get relationship;
  @override
  String? get notes;
  @override
  String? get needs;
  @override
  List<String>? get tags;
  @override
  bool get isActive;
  @override
  DateTime? get lastContactAt;
  @override
  DateTime? get nextFollowUpAt;
  @override
  List<String>? get committedActionIds;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PersonCommitmentImplCopyWith<_$PersonCommitmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
