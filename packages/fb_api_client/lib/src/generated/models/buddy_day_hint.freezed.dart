// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_day_hint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDayHint {

/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 String? get dateHint;/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 String? get slotHint;/// Literal time phrase as the user said it (B08); the app resolves it.
 String? get timeHint;
/// Create a copy of BuddyDayHint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<BuddyDayHint> get copyWith => _$BuddyDayHintCopyWithImpl<BuddyDayHint>(this as BuddyDayHint, _$identity);

  /// Serializes this BuddyDayHint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDayHint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDayHint&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint)&&(identical(other.slotHint, _this.slotHint) || other.slotHint == _this.slotHint)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDayHint;
  return Object.hash(runtimeType,_this.dateHint,_this.slotHint,_this.timeHint);
}

@override
String toString() {
  final _this = this as BuddyDayHint;
  return 'BuddyDayHint(dateHint: ${_this.dateHint}, slotHint: ${_this.slotHint}, timeHint: ${_this.timeHint})';
}


}

/// @nodoc
abstract mixin class $BuddyDayHintCopyWith<$Res>  {
  factory $BuddyDayHintCopyWith(BuddyDayHint value, $Res Function(BuddyDayHint) _then) = _$BuddyDayHintCopyWithImpl;
@useResult
$Res call({
 String? dateHint, String? slotHint, String? timeHint
});




}
/// @nodoc
class _$BuddyDayHintCopyWithImpl<$Res>
    implements $BuddyDayHintCopyWith<$Res> {
  _$BuddyDayHintCopyWithImpl(this._self, this._then);

  final BuddyDayHint _self;
  final $Res Function(BuddyDayHint) _then;

/// Create a copy of BuddyDayHint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dateHint = freezed,Object? slotHint = freezed,Object? timeHint = freezed,}) {
  return _then(BuddyDayHint(
dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyDayHint].
extension BuddyDayHintPatterns on BuddyDayHint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDayHint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDayHint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDayHint value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDayHint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDayHint value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDayHint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? dateHint,  String? slotHint,  String? timeHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDayHint() when $default != null:
return $default(_that.dateHint,_that.slotHint,_that.timeHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? dateHint,  String? slotHint,  String? timeHint)  $default,) {final _that = this;
switch (_that) {
case _BuddyDayHint():
return $default(_that.dateHint,_that.slotHint,_that.timeHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? dateHint,  String? slotHint,  String? timeHint)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDayHint() when $default != null:
return $default(_that.dateHint,_that.slotHint,_that.timeHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDayHint implements BuddyDayHint {
  const _BuddyDayHint({required this.dateHint, required this.slotHint, required this.timeHint});
  factory _BuddyDayHint.fromJson(Map<String, dynamic> json) => _$BuddyDayHintFromJson(json);

/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
@override final  String? dateHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
@override final  String? slotHint;
/// Literal time phrase as the user said it (B08); the app resolves it.
@override final  String? timeHint;

/// Create a copy of BuddyDayHint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDayHintCopyWith<_BuddyDayHint> get copyWith => __$BuddyDayHintCopyWithImpl<_BuddyDayHint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDayHintToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDayHint&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,dateHint,slotHint,timeHint);
}

@override
String toString() {
    return 'BuddyDayHint(dateHint: $dateHint, slotHint: $slotHint, timeHint: $timeHint)';
}


}

/// @nodoc
abstract mixin class _$BuddyDayHintCopyWith<$Res> implements $BuddyDayHintCopyWith<$Res> {
  factory _$BuddyDayHintCopyWith(_BuddyDayHint value, $Res Function(_BuddyDayHint) _then) = __$BuddyDayHintCopyWithImpl;
@override @useResult
$Res call({
 String? dateHint, String? slotHint, String? timeHint
});




}
/// @nodoc
class __$BuddyDayHintCopyWithImpl<$Res>
    implements _$BuddyDayHintCopyWith<$Res> {
  __$BuddyDayHintCopyWithImpl(this._self, this._then);

  final _BuddyDayHint _self;
  final $Res Function(_BuddyDayHint) _then;

/// Create a copy of BuddyDayHint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dateHint = freezed,Object? slotHint = freezed,Object? timeHint = freezed,}) {
  return _then(_BuddyDayHint(
dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
