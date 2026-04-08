// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReadingPlan _$ReadingPlanFromJson(Map<String, dynamic> json) {
  return _ReadingPlan.fromJson(json);
}

/// @nodoc
mixin _$ReadingPlan {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_days')
  int get durationDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'theme_id')
  String? get themeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_featured')
  bool get isFeatured => throw _privateConstructorUsedError;
  List<ReadingPlanDay> get days => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReadingPlanCopyWith<ReadingPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingPlanCopyWith<$Res> {
  factory $ReadingPlanCopyWith(
          ReadingPlan value, $Res Function(ReadingPlan) then) =
      _$ReadingPlanCopyWithImpl<$Res, ReadingPlan>;
  @useResult
  $Res call(
      {int id,
      String title,
      String? description,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'duration_days') int durationDays,
      @JsonKey(name: 'theme_id') String? themeId,
      @JsonKey(name: 'is_featured') bool isFeatured,
      List<ReadingPlanDay> days});
}

/// @nodoc
class _$ReadingPlanCopyWithImpl<$Res, $Val extends ReadingPlan>
    implements $ReadingPlanCopyWith<$Res> {
  _$ReadingPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? thumbnailUrl = freezed,
    Object? durationDays = null,
    Object? themeId = freezed,
    Object? isFeatured = null,
    Object? days = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      durationDays: null == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      isFeatured: null == isFeatured
          ? _value.isFeatured
          : isFeatured // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _value.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<ReadingPlanDay>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReadingPlanImplCopyWith<$Res>
    implements $ReadingPlanCopyWith<$Res> {
  factory _$$ReadingPlanImplCopyWith(
          _$ReadingPlanImpl value, $Res Function(_$ReadingPlanImpl) then) =
      __$$ReadingPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      String? description,
      @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
      @JsonKey(name: 'duration_days') int durationDays,
      @JsonKey(name: 'theme_id') String? themeId,
      @JsonKey(name: 'is_featured') bool isFeatured,
      List<ReadingPlanDay> days});
}

/// @nodoc
class __$$ReadingPlanImplCopyWithImpl<$Res>
    extends _$ReadingPlanCopyWithImpl<$Res, _$ReadingPlanImpl>
    implements _$$ReadingPlanImplCopyWith<$Res> {
  __$$ReadingPlanImplCopyWithImpl(
      _$ReadingPlanImpl _value, $Res Function(_$ReadingPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? thumbnailUrl = freezed,
    Object? durationDays = null,
    Object? themeId = freezed,
    Object? isFeatured = null,
    Object? days = null,
  }) {
    return _then(_$ReadingPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      durationDays: null == durationDays
          ? _value.durationDays
          : durationDays // ignore: cast_nullable_to_non_nullable
              as int,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      isFeatured: null == isFeatured
          ? _value.isFeatured
          : isFeatured // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _value._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<ReadingPlanDay>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReadingPlanImpl implements _ReadingPlan {
  const _$ReadingPlanImpl(
      {required this.id,
      required this.title,
      this.description,
      @JsonKey(name: 'thumbnail_url') this.thumbnailUrl,
      @JsonKey(name: 'duration_days') required this.durationDays,
      @JsonKey(name: 'theme_id') this.themeId,
      @JsonKey(name: 'is_featured') this.isFeatured = false,
      final List<ReadingPlanDay> days = const []})
      : _days = days;

  factory _$ReadingPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadingPlanImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'thumbnail_url')
  final String? thumbnailUrl;
  @override
  @JsonKey(name: 'duration_days')
  final int durationDays;
  @override
  @JsonKey(name: 'theme_id')
  final String? themeId;
  @override
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  final List<ReadingPlanDay> _days;
  @override
  @JsonKey()
  List<ReadingPlanDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  String toString() {
    return 'ReadingPlan(id: $id, title: $title, description: $description, thumbnailUrl: $thumbnailUrl, durationDays: $durationDays, themeId: $themeId, isFeatured: $isFeatured, days: $days)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.themeId, themeId) || other.themeId == themeId) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      thumbnailUrl,
      durationDays,
      themeId,
      isFeatured,
      const DeepCollectionEquality().hash(_days));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingPlanImplCopyWith<_$ReadingPlanImpl> get copyWith =>
      __$$ReadingPlanImplCopyWithImpl<_$ReadingPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadingPlanImplToJson(
      this,
    );
  }
}

abstract class _ReadingPlan implements ReadingPlan {
  const factory _ReadingPlan(
      {required final int id,
      required final String title,
      final String? description,
      @JsonKey(name: 'thumbnail_url') final String? thumbnailUrl,
      @JsonKey(name: 'duration_days') required final int durationDays,
      @JsonKey(name: 'theme_id') final String? themeId,
      @JsonKey(name: 'is_featured') final bool isFeatured,
      final List<ReadingPlanDay> days}) = _$ReadingPlanImpl;

  factory _ReadingPlan.fromJson(Map<String, dynamic> json) =
      _$ReadingPlanImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'thumbnail_url')
  String? get thumbnailUrl;
  @override
  @JsonKey(name: 'duration_days')
  int get durationDays;
  @override
  @JsonKey(name: 'theme_id')
  String? get themeId;
  @override
  @JsonKey(name: 'is_featured')
  bool get isFeatured;
  @override
  List<ReadingPlanDay> get days;
  @override
  @JsonKey(ignore: true)
  _$$ReadingPlanImplCopyWith<_$ReadingPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ReadingPlanDay _$ReadingPlanDayFromJson(Map<String, dynamic> json) {
  return _ReadingPlanDay.fromJson(json);
}

/// @nodoc
mixin _$ReadingPlanDay {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'day_number')
  int get dayNumber => throw _privateConstructorUsedError;
  List<String> get verses => throw _privateConstructorUsedError;
  @JsonKey(name: 'devotional_title')
  String? get devotionalTitle => throw _privateConstructorUsedError;
  @JsonKey(name: 'devotional_text')
  String? get devotionalText => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReadingPlanDayCopyWith<ReadingPlanDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingPlanDayCopyWith<$Res> {
  factory $ReadingPlanDayCopyWith(
          ReadingPlanDay value, $Res Function(ReadingPlanDay) then) =
      _$ReadingPlanDayCopyWithImpl<$Res, ReadingPlanDay>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'day_number') int dayNumber,
      List<String> verses,
      @JsonKey(name: 'devotional_title') String? devotionalTitle,
      @JsonKey(name: 'devotional_text') String? devotionalText});
}

/// @nodoc
class _$ReadingPlanDayCopyWithImpl<$Res, $Val extends ReadingPlanDay>
    implements $ReadingPlanDayCopyWith<$Res> {
  _$ReadingPlanDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayNumber = null,
    Object? verses = null,
    Object? devotionalTitle = freezed,
    Object? devotionalText = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      verses: null == verses
          ? _value.verses
          : verses // ignore: cast_nullable_to_non_nullable
              as List<String>,
      devotionalTitle: freezed == devotionalTitle
          ? _value.devotionalTitle
          : devotionalTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      devotionalText: freezed == devotionalText
          ? _value.devotionalText
          : devotionalText // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReadingPlanDayImplCopyWith<$Res>
    implements $ReadingPlanDayCopyWith<$Res> {
  factory _$$ReadingPlanDayImplCopyWith(_$ReadingPlanDayImpl value,
          $Res Function(_$ReadingPlanDayImpl) then) =
      __$$ReadingPlanDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'day_number') int dayNumber,
      List<String> verses,
      @JsonKey(name: 'devotional_title') String? devotionalTitle,
      @JsonKey(name: 'devotional_text') String? devotionalText});
}

/// @nodoc
class __$$ReadingPlanDayImplCopyWithImpl<$Res>
    extends _$ReadingPlanDayCopyWithImpl<$Res, _$ReadingPlanDayImpl>
    implements _$$ReadingPlanDayImplCopyWith<$Res> {
  __$$ReadingPlanDayImplCopyWithImpl(
      _$ReadingPlanDayImpl _value, $Res Function(_$ReadingPlanDayImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayNumber = null,
    Object? verses = null,
    Object? devotionalTitle = freezed,
    Object? devotionalText = freezed,
  }) {
    return _then(_$ReadingPlanDayImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      verses: null == verses
          ? _value._verses
          : verses // ignore: cast_nullable_to_non_nullable
              as List<String>,
      devotionalTitle: freezed == devotionalTitle
          ? _value.devotionalTitle
          : devotionalTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      devotionalText: freezed == devotionalText
          ? _value.devotionalText
          : devotionalText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReadingPlanDayImpl implements _ReadingPlanDay {
  const _$ReadingPlanDayImpl(
      {required this.id,
      @JsonKey(name: 'day_number') required this.dayNumber,
      required final List<String> verses,
      @JsonKey(name: 'devotional_title') this.devotionalTitle,
      @JsonKey(name: 'devotional_text') this.devotionalText})
      : _verses = verses;

  factory _$ReadingPlanDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadingPlanDayImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'day_number')
  final int dayNumber;
  final List<String> _verses;
  @override
  List<String> get verses {
    if (_verses is EqualUnmodifiableListView) return _verses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_verses);
  }

  @override
  @JsonKey(name: 'devotional_title')
  final String? devotionalTitle;
  @override
  @JsonKey(name: 'devotional_text')
  final String? devotionalText;

  @override
  String toString() {
    return 'ReadingPlanDay(id: $id, dayNumber: $dayNumber, verses: $verses, devotionalTitle: $devotionalTitle, devotionalText: $devotionalText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingPlanDayImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            const DeepCollectionEquality().equals(other._verses, _verses) &&
            (identical(other.devotionalTitle, devotionalTitle) ||
                other.devotionalTitle == devotionalTitle) &&
            (identical(other.devotionalText, devotionalText) ||
                other.devotionalText == devotionalText));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      dayNumber,
      const DeepCollectionEquality().hash(_verses),
      devotionalTitle,
      devotionalText);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingPlanDayImplCopyWith<_$ReadingPlanDayImpl> get copyWith =>
      __$$ReadingPlanDayImplCopyWithImpl<_$ReadingPlanDayImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadingPlanDayImplToJson(
      this,
    );
  }
}

abstract class _ReadingPlanDay implements ReadingPlanDay {
  const factory _ReadingPlanDay(
          {required final int id,
          @JsonKey(name: 'day_number') required final int dayNumber,
          required final List<String> verses,
          @JsonKey(name: 'devotional_title') final String? devotionalTitle,
          @JsonKey(name: 'devotional_text') final String? devotionalText}) =
      _$ReadingPlanDayImpl;

  factory _ReadingPlanDay.fromJson(Map<String, dynamic> json) =
      _$ReadingPlanDayImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'day_number')
  int get dayNumber;
  @override
  List<String> get verses;
  @override
  @JsonKey(name: 'devotional_title')
  String? get devotionalTitle;
  @override
  @JsonKey(name: 'devotional_text')
  String? get devotionalText;
  @override
  @JsonKey(ignore: true)
  _$$ReadingPlanDayImplCopyWith<_$ReadingPlanDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserReadingPlan _$UserReadingPlanFromJson(Map<String, dynamic> json) {
  return _UserReadingPlan.fromJson(json);
}

/// @nodoc
mixin _$UserReadingPlan {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'reading_plan_id')
  int get readingPlanId => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_day')
  int get currentDay => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'started_at')
  DateTime? get startedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;
  ReadingPlan? get plan => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserReadingPlanCopyWith<UserReadingPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserReadingPlanCopyWith<$Res> {
  factory $UserReadingPlanCopyWith(
          UserReadingPlan value, $Res Function(UserReadingPlan) then) =
      _$UserReadingPlanCopyWithImpl<$Res, UserReadingPlan>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'reading_plan_id') int readingPlanId,
      @JsonKey(name: 'current_day') int currentDay,
      String status,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      ReadingPlan? plan});

  $ReadingPlanCopyWith<$Res>? get plan;
}

/// @nodoc
class _$UserReadingPlanCopyWithImpl<$Res, $Val extends UserReadingPlan>
    implements $UserReadingPlanCopyWith<$Res> {
  _$UserReadingPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? readingPlanId = null,
    Object? currentDay = null,
    Object? status = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? plan = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      readingPlanId: null == readingPlanId
          ? _value.readingPlanId
          : readingPlanId // ignore: cast_nullable_to_non_nullable
              as int,
      currentDay: null == currentDay
          ? _value.currentDay
          : currentDay // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      plan: freezed == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as ReadingPlan?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ReadingPlanCopyWith<$Res>? get plan {
    if (_value.plan == null) {
      return null;
    }

    return $ReadingPlanCopyWith<$Res>(_value.plan!, (value) {
      return _then(_value.copyWith(plan: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserReadingPlanImplCopyWith<$Res>
    implements $UserReadingPlanCopyWith<$Res> {
  factory _$$UserReadingPlanImplCopyWith(_$UserReadingPlanImpl value,
          $Res Function(_$UserReadingPlanImpl) then) =
      __$$UserReadingPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'reading_plan_id') int readingPlanId,
      @JsonKey(name: 'current_day') int currentDay,
      String status,
      @JsonKey(name: 'started_at') DateTime? startedAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      ReadingPlan? plan});

  @override
  $ReadingPlanCopyWith<$Res>? get plan;
}

/// @nodoc
class __$$UserReadingPlanImplCopyWithImpl<$Res>
    extends _$UserReadingPlanCopyWithImpl<$Res, _$UserReadingPlanImpl>
    implements _$$UserReadingPlanImplCopyWith<$Res> {
  __$$UserReadingPlanImplCopyWithImpl(
      _$UserReadingPlanImpl _value, $Res Function(_$UserReadingPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? readingPlanId = null,
    Object? currentDay = null,
    Object? status = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? plan = freezed,
  }) {
    return _then(_$UserReadingPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      readingPlanId: null == readingPlanId
          ? _value.readingPlanId
          : readingPlanId // ignore: cast_nullable_to_non_nullable
              as int,
      currentDay: null == currentDay
          ? _value.currentDay
          : currentDay // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      plan: freezed == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as ReadingPlan?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserReadingPlanImpl implements _UserReadingPlan {
  const _$UserReadingPlanImpl(
      {required this.id,
      @JsonKey(name: 'reading_plan_id') required this.readingPlanId,
      @JsonKey(name: 'current_day') this.currentDay = 1,
      this.status = 'active',
      @JsonKey(name: 'started_at') this.startedAt,
      @JsonKey(name: 'completed_at') this.completedAt,
      this.plan});

  factory _$UserReadingPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserReadingPlanImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'reading_plan_id')
  final int readingPlanId;
  @override
  @JsonKey(name: 'current_day')
  final int currentDay;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @override
  final ReadingPlan? plan;

  @override
  String toString() {
    return 'UserReadingPlan(id: $id, readingPlanId: $readingPlanId, currentDay: $currentDay, status: $status, startedAt: $startedAt, completedAt: $completedAt, plan: $plan)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserReadingPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.readingPlanId, readingPlanId) ||
                other.readingPlanId == readingPlanId) &&
            (identical(other.currentDay, currentDay) ||
                other.currentDay == currentDay) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.plan, plan) || other.plan == plan));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, readingPlanId, currentDay,
      status, startedAt, completedAt, plan);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserReadingPlanImplCopyWith<_$UserReadingPlanImpl> get copyWith =>
      __$$UserReadingPlanImplCopyWithImpl<_$UserReadingPlanImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserReadingPlanImplToJson(
      this,
    );
  }
}

abstract class _UserReadingPlan implements UserReadingPlan {
  const factory _UserReadingPlan(
      {required final int id,
      @JsonKey(name: 'reading_plan_id') required final int readingPlanId,
      @JsonKey(name: 'current_day') final int currentDay,
      final String status,
      @JsonKey(name: 'started_at') final DateTime? startedAt,
      @JsonKey(name: 'completed_at') final DateTime? completedAt,
      final ReadingPlan? plan}) = _$UserReadingPlanImpl;

  factory _UserReadingPlan.fromJson(Map<String, dynamic> json) =
      _$UserReadingPlanImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'reading_plan_id')
  int get readingPlanId;
  @override
  @JsonKey(name: 'current_day')
  int get currentDay;
  @override
  String get status;
  @override
  @JsonKey(name: 'started_at')
  DateTime? get startedAt;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  ReadingPlan? get plan;
  @override
  @JsonKey(ignore: true)
  _$$UserReadingPlanImplCopyWith<_$UserReadingPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
