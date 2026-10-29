// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_saved_meal_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySavedMealLog {

 BuddySavedMealLogKind get kind; String get language; String get script;/// A request savedMeals ID.
 String get savedMealId;/// Literal time phrase as the user said it (B08); the app resolves it.
 String? get timeHint;/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 String? get slotHint;/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint; BuddyShare? get share;
/// Create a copy of BuddySavedMealLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySavedMealLogCopyWith<BuddySavedMealLog> get copyWith => _$BuddySavedMealLogCopyWithImpl<BuddySavedMealLog>(this as BuddySavedMealLog, _$identity);

  /// Serializes this BuddySavedMealLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySavedMealLog;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySavedMealLog&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.savedMealId, _this.savedMealId) || other.savedMealId == _this.savedMealId)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint)&&(identical(other.share, _this.share) || other.share == _this.share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySavedMealLog;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.savedMealId,_this.timeHint,_this.slotHint,_this.dateHint,_this.share);
}

@override
String toString() {
  final _this = this as BuddySavedMealLog;
  return 'BuddySavedMealLog(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, savedMealId: ${_this.savedMealId}, timeHint: ${_this.timeHint}, slotHint: ${_this.slotHint}, dateHint: ${_this.dateHint}, share: ${_this.share})';
}


}

/// @nodoc
abstract mixin class $BuddySavedMealLogCopyWith<$Res>  {
  factory $BuddySavedMealLogCopyWith(BuddySavedMealLog value, $Res Function(BuddySavedMealLog) _then) = _$BuddySavedMealLogCopyWithImpl;
@useResult
$Res call({
 BuddySavedMealLogKind kind, String language, String script, String savedMealId, String? timeHint, String? slotHint, String? dateHint, BuddyShare? share
});


$BuddyShareCopyWith<$Res>? get share;

}
/// @nodoc
class _$BuddySavedMealLogCopyWithImpl<$Res>
    implements $BuddySavedMealLogCopyWith<$Res> {
  _$BuddySavedMealLogCopyWithImpl(this._self, this._then);

  final BuddySavedMealLog _self;
  final $Res Function(BuddySavedMealLog) _then;

/// Create a copy of BuddySavedMealLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? savedMealId = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,Object? share = freezed,}) {
  return _then(BuddySavedMealLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySavedMealLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,savedMealId: null == savedMealId ? _self.savedMealId : savedMealId // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,
  ));
}
/// Create a copy of BuddySavedMealLog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddySavedMealLog].
extension BuddySavedMealLogPatterns on BuddySavedMealLog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySavedMealLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySavedMealLog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySavedMealLog value)  $default,){
final _that = this;
switch (_that) {
case _BuddySavedMealLog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySavedMealLog value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySavedMealLog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddySavedMealLogKind kind,  String language,  String script,  String savedMealId,  String? timeHint,  String? slotHint,  String? dateHint,  BuddyShare? share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySavedMealLog() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.savedMealId,_that.timeHint,_that.slotHint,_that.dateHint,_that.share);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddySavedMealLogKind kind,  String language,  String script,  String savedMealId,  String? timeHint,  String? slotHint,  String? dateHint,  BuddyShare? share)  $default,) {final _that = this;
switch (_that) {
case _BuddySavedMealLog():
return $default(_that.kind,_that.language,_that.script,_that.savedMealId,_that.timeHint,_that.slotHint,_that.dateHint,_that.share);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddySavedMealLogKind kind,  String language,  String script,  String savedMealId,  String? timeHint,  String? slotHint,  String? dateHint,  BuddyShare? share)?  $default,) {final _that = this;
switch (_that) {
case _BuddySavedMealLog() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.savedMealId,_that.timeHint,_that.slotHint,_that.dateHint,_that.share);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySavedMealLog implements BuddySavedMealLog {
  const _BuddySavedMealLog({required this.kind, required this.language, required this.script, required this.savedMealId, required this.timeHint, required this.slotHint, required this.dateHint, required this.share});
  factory _BuddySavedMealLog.fromJson(Map<String, dynamic> json) => _$BuddySavedMealLogFromJson(json);

@override final  BuddySavedMealLogKind kind;
@override final  String language;
@override final  String script;
/// A request savedMeals ID.
@override final  String savedMealId;
/// Literal time phrase as the user said it (B08); the app resolves it.
@override final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
@override final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;
@override final  BuddyShare? share;

/// Create a copy of BuddySavedMealLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySavedMealLogCopyWith<_BuddySavedMealLog> get copyWith => __$BuddySavedMealLogCopyWithImpl<_BuddySavedMealLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySavedMealLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySavedMealLog&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.savedMealId, savedMealId) || other.savedMealId == savedMealId)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,savedMealId,timeHint,slotHint,dateHint,share);
}

@override
String toString() {
    return 'BuddySavedMealLog(kind: $kind, language: $language, script: $script, savedMealId: $savedMealId, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint, share: $share)';
}


}

/// @nodoc
abstract mixin class _$BuddySavedMealLogCopyWith<$Res> implements $BuddySavedMealLogCopyWith<$Res> {
  factory _$BuddySavedMealLogCopyWith(_BuddySavedMealLog value, $Res Function(_BuddySavedMealLog) _then) = __$BuddySavedMealLogCopyWithImpl;
@override @useResult
$Res call({
 BuddySavedMealLogKind kind, String language, String script, String savedMealId, String? timeHint, String? slotHint, String? dateHint, BuddyShare? share
});


@override $BuddyShareCopyWith<$Res>? get share;

}
/// @nodoc
class __$BuddySavedMealLogCopyWithImpl<$Res>
    implements _$BuddySavedMealLogCopyWith<$Res> {
  __$BuddySavedMealLogCopyWithImpl(this._self, this._then);

  final _BuddySavedMealLog _self;
  final $Res Function(_BuddySavedMealLog) _then;

/// Create a copy of BuddySavedMealLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? savedMealId = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,Object? share = freezed,}) {
  return _then(_BuddySavedMealLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySavedMealLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,savedMealId: null == savedMealId ? _self.savedMealId : savedMealId // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,
  ));
}

/// Create a copy of BuddySavedMealLog
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}

// dart format on
