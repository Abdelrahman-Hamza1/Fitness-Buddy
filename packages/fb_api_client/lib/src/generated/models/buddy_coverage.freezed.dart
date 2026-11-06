// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_coverage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyCoverage {

 int get days; int get loggedDays;
/// Create a copy of BuddyCoverage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyCoverageCopyWith<BuddyCoverage> get copyWith => _$BuddyCoverageCopyWithImpl<BuddyCoverage>(this as BuddyCoverage, _$identity);

  /// Serializes this BuddyCoverage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyCoverage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyCoverage&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.loggedDays, _this.loggedDays) || other.loggedDays == _this.loggedDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyCoverage;
  return Object.hash(runtimeType,_this.days,_this.loggedDays);
}

@override
String toString() {
  final _this = this as BuddyCoverage;
  return 'BuddyCoverage(days: ${_this.days}, loggedDays: ${_this.loggedDays})';
}


}

/// @nodoc
abstract mixin class $BuddyCoverageCopyWith<$Res>  {
  factory $BuddyCoverageCopyWith(BuddyCoverage value, $Res Function(BuddyCoverage) _then) = _$BuddyCoverageCopyWithImpl;
@useResult
$Res call({
 int days, int loggedDays
});




}
/// @nodoc
class _$BuddyCoverageCopyWithImpl<$Res>
    implements $BuddyCoverageCopyWith<$Res> {
  _$BuddyCoverageCopyWithImpl(this._self, this._then);

  final BuddyCoverage _self;
  final $Res Function(BuddyCoverage) _then;

/// Create a copy of BuddyCoverage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? loggedDays = null,}) {
  return _then(BuddyCoverage(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,loggedDays: null == loggedDays ? _self.loggedDays : loggedDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyCoverage].
extension BuddyCoveragePatterns on BuddyCoverage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyCoverage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyCoverage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyCoverage value)  $default,){
final _that = this;
switch (_that) {
case _BuddyCoverage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyCoverage value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyCoverage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int days,  int loggedDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyCoverage() when $default != null:
return $default(_that.days,_that.loggedDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int days,  int loggedDays)  $default,) {final _that = this;
switch (_that) {
case _BuddyCoverage():
return $default(_that.days,_that.loggedDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int days,  int loggedDays)?  $default,) {final _that = this;
switch (_that) {
case _BuddyCoverage() when $default != null:
return $default(_that.days,_that.loggedDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyCoverage implements BuddyCoverage {
  const _BuddyCoverage({required this.days, required this.loggedDays});
  factory _BuddyCoverage.fromJson(Map<String, dynamic> json) => _$BuddyCoverageFromJson(json);

@override final  int days;
@override final  int loggedDays;

/// Create a copy of BuddyCoverage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyCoverageCopyWith<_BuddyCoverage> get copyWith => __$BuddyCoverageCopyWithImpl<_BuddyCoverage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyCoverageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyCoverage&&(identical(other.days, days) || other.days == days)&&(identical(other.loggedDays, loggedDays) || other.loggedDays == loggedDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,days,loggedDays);
}

@override
String toString() {
    return 'BuddyCoverage(days: $days, loggedDays: $loggedDays)';
}


}

/// @nodoc
abstract mixin class _$BuddyCoverageCopyWith<$Res> implements $BuddyCoverageCopyWith<$Res> {
  factory _$BuddyCoverageCopyWith(_BuddyCoverage value, $Res Function(_BuddyCoverage) _then) = __$BuddyCoverageCopyWithImpl;
@override @useResult
$Res call({
 int days, int loggedDays
});




}
/// @nodoc
class __$BuddyCoverageCopyWithImpl<$Res>
    implements _$BuddyCoverageCopyWith<$Res> {
  __$BuddyCoverageCopyWithImpl(this._self, this._then);

  final _BuddyCoverage _self;
  final $Res Function(_BuddyCoverage) _then;

/// Create a copy of BuddyCoverage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? loggedDays = null,}) {
  return _then(_BuddyCoverage(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,loggedDays: null == loggedDays ? _self.loggedDays : loggedDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
