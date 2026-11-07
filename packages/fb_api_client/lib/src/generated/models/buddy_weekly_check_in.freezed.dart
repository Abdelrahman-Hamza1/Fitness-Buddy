// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_weekly_check_in.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWeeklyCheckIn {

 double get currentKcal; double get proposedKcal;
/// Create a copy of BuddyWeeklyCheckIn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWeeklyCheckInCopyWith<BuddyWeeklyCheckIn> get copyWith => _$BuddyWeeklyCheckInCopyWithImpl<BuddyWeeklyCheckIn>(this as BuddyWeeklyCheckIn, _$identity);

  /// Serializes this BuddyWeeklyCheckIn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWeeklyCheckIn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWeeklyCheckIn&&(identical(other.currentKcal, _this.currentKcal) || other.currentKcal == _this.currentKcal)&&(identical(other.proposedKcal, _this.proposedKcal) || other.proposedKcal == _this.proposedKcal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWeeklyCheckIn;
  return Object.hash(runtimeType,_this.currentKcal,_this.proposedKcal);
}

@override
String toString() {
  final _this = this as BuddyWeeklyCheckIn;
  return 'BuddyWeeklyCheckIn(currentKcal: ${_this.currentKcal}, proposedKcal: ${_this.proposedKcal})';
}


}

/// @nodoc
abstract mixin class $BuddyWeeklyCheckInCopyWith<$Res>  {
  factory $BuddyWeeklyCheckInCopyWith(BuddyWeeklyCheckIn value, $Res Function(BuddyWeeklyCheckIn) _then) = _$BuddyWeeklyCheckInCopyWithImpl;
@useResult
$Res call({
 double currentKcal, double proposedKcal
});




}
/// @nodoc
class _$BuddyWeeklyCheckInCopyWithImpl<$Res>
    implements $BuddyWeeklyCheckInCopyWith<$Res> {
  _$BuddyWeeklyCheckInCopyWithImpl(this._self, this._then);

  final BuddyWeeklyCheckIn _self;
  final $Res Function(BuddyWeeklyCheckIn) _then;

/// Create a copy of BuddyWeeklyCheckIn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentKcal = null,Object? proposedKcal = null,}) {
  return _then(BuddyWeeklyCheckIn(
currentKcal: null == currentKcal ? _self.currentKcal : currentKcal // ignore: cast_nullable_to_non_nullable
as double,proposedKcal: null == proposedKcal ? _self.proposedKcal : proposedKcal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWeeklyCheckIn].
extension BuddyWeeklyCheckInPatterns on BuddyWeeklyCheckIn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWeeklyCheckIn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWeeklyCheckIn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWeeklyCheckIn value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWeeklyCheckIn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWeeklyCheckIn value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWeeklyCheckIn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double currentKcal,  double proposedKcal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWeeklyCheckIn() when $default != null:
return $default(_that.currentKcal,_that.proposedKcal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double currentKcal,  double proposedKcal)  $default,) {final _that = this;
switch (_that) {
case _BuddyWeeklyCheckIn():
return $default(_that.currentKcal,_that.proposedKcal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double currentKcal,  double proposedKcal)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWeeklyCheckIn() when $default != null:
return $default(_that.currentKcal,_that.proposedKcal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWeeklyCheckIn implements BuddyWeeklyCheckIn {
  const _BuddyWeeklyCheckIn({required this.currentKcal, required this.proposedKcal});
  factory _BuddyWeeklyCheckIn.fromJson(Map<String, dynamic> json) => _$BuddyWeeklyCheckInFromJson(json);

@override final  double currentKcal;
@override final  double proposedKcal;

/// Create a copy of BuddyWeeklyCheckIn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWeeklyCheckInCopyWith<_BuddyWeeklyCheckIn> get copyWith => __$BuddyWeeklyCheckInCopyWithImpl<_BuddyWeeklyCheckIn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWeeklyCheckInToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWeeklyCheckIn&&(identical(other.currentKcal, currentKcal) || other.currentKcal == currentKcal)&&(identical(other.proposedKcal, proposedKcal) || other.proposedKcal == proposedKcal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,currentKcal,proposedKcal);
}

@override
String toString() {
    return 'BuddyWeeklyCheckIn(currentKcal: $currentKcal, proposedKcal: $proposedKcal)';
}


}

/// @nodoc
abstract mixin class _$BuddyWeeklyCheckInCopyWith<$Res> implements $BuddyWeeklyCheckInCopyWith<$Res> {
  factory _$BuddyWeeklyCheckInCopyWith(_BuddyWeeklyCheckIn value, $Res Function(_BuddyWeeklyCheckIn) _then) = __$BuddyWeeklyCheckInCopyWithImpl;
@override @useResult
$Res call({
 double currentKcal, double proposedKcal
});




}
/// @nodoc
class __$BuddyWeeklyCheckInCopyWithImpl<$Res>
    implements _$BuddyWeeklyCheckInCopyWith<$Res> {
  __$BuddyWeeklyCheckInCopyWithImpl(this._self, this._then);

  final _BuddyWeeklyCheckIn _self;
  final $Res Function(_BuddyWeeklyCheckIn) _then;

/// Create a copy of BuddyWeeklyCheckIn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentKcal = null,Object? proposedKcal = null,}) {
  return _then(_BuddyWeeklyCheckIn(
currentKcal: null == currentKcal ? _self.currentKcal : currentKcal // ignore: cast_nullable_to_non_nullable
as double,proposedKcal: null == proposedKcal ? _self.proposedKcal : proposedKcal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
