// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_weekly_workouts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWeeklyWorkouts {

 int get sessions; int? get planned; int get prs;
/// Create a copy of BuddyWeeklyWorkouts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWeeklyWorkoutsCopyWith<BuddyWeeklyWorkouts> get copyWith => _$BuddyWeeklyWorkoutsCopyWithImpl<BuddyWeeklyWorkouts>(this as BuddyWeeklyWorkouts, _$identity);

  /// Serializes this BuddyWeeklyWorkouts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWeeklyWorkouts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWeeklyWorkouts&&(identical(other.sessions, _this.sessions) || other.sessions == _this.sessions)&&(identical(other.planned, _this.planned) || other.planned == _this.planned)&&(identical(other.prs, _this.prs) || other.prs == _this.prs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWeeklyWorkouts;
  return Object.hash(runtimeType,_this.sessions,_this.planned,_this.prs);
}

@override
String toString() {
  final _this = this as BuddyWeeklyWorkouts;
  return 'BuddyWeeklyWorkouts(sessions: ${_this.sessions}, planned: ${_this.planned}, prs: ${_this.prs})';
}


}

/// @nodoc
abstract mixin class $BuddyWeeklyWorkoutsCopyWith<$Res>  {
  factory $BuddyWeeklyWorkoutsCopyWith(BuddyWeeklyWorkouts value, $Res Function(BuddyWeeklyWorkouts) _then) = _$BuddyWeeklyWorkoutsCopyWithImpl;
@useResult
$Res call({
 int sessions, int? planned, int prs
});




}
/// @nodoc
class _$BuddyWeeklyWorkoutsCopyWithImpl<$Res>
    implements $BuddyWeeklyWorkoutsCopyWith<$Res> {
  _$BuddyWeeklyWorkoutsCopyWithImpl(this._self, this._then);

  final BuddyWeeklyWorkouts _self;
  final $Res Function(BuddyWeeklyWorkouts) _then;

/// Create a copy of BuddyWeeklyWorkouts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessions = null,Object? planned = freezed,Object? prs = null,}) {
  return _then(BuddyWeeklyWorkouts(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,planned: freezed == planned ? _self.planned : planned // ignore: cast_nullable_to_non_nullable
as int?,prs: null == prs ? _self.prs : prs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWeeklyWorkouts].
extension BuddyWeeklyWorkoutsPatterns on BuddyWeeklyWorkouts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWeeklyWorkouts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWeeklyWorkouts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWeeklyWorkouts value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWeeklyWorkouts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWeeklyWorkouts value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWeeklyWorkouts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sessions,  int? planned,  int prs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWeeklyWorkouts() when $default != null:
return $default(_that.sessions,_that.planned,_that.prs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sessions,  int? planned,  int prs)  $default,) {final _that = this;
switch (_that) {
case _BuddyWeeklyWorkouts():
return $default(_that.sessions,_that.planned,_that.prs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sessions,  int? planned,  int prs)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWeeklyWorkouts() when $default != null:
return $default(_that.sessions,_that.planned,_that.prs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWeeklyWorkouts implements BuddyWeeklyWorkouts {
  const _BuddyWeeklyWorkouts({required this.sessions, required this.planned, required this.prs});
  factory _BuddyWeeklyWorkouts.fromJson(Map<String, dynamic> json) => _$BuddyWeeklyWorkoutsFromJson(json);

@override final  int sessions;
@override final  int? planned;
@override final  int prs;

/// Create a copy of BuddyWeeklyWorkouts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWeeklyWorkoutsCopyWith<_BuddyWeeklyWorkouts> get copyWith => __$BuddyWeeklyWorkoutsCopyWithImpl<_BuddyWeeklyWorkouts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWeeklyWorkoutsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWeeklyWorkouts&&(identical(other.sessions, sessions) || other.sessions == sessions)&&(identical(other.planned, planned) || other.planned == planned)&&(identical(other.prs, prs) || other.prs == prs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sessions,planned,prs);
}

@override
String toString() {
    return 'BuddyWeeklyWorkouts(sessions: $sessions, planned: $planned, prs: $prs)';
}


}

/// @nodoc
abstract mixin class _$BuddyWeeklyWorkoutsCopyWith<$Res> implements $BuddyWeeklyWorkoutsCopyWith<$Res> {
  factory _$BuddyWeeklyWorkoutsCopyWith(_BuddyWeeklyWorkouts value, $Res Function(_BuddyWeeklyWorkouts) _then) = __$BuddyWeeklyWorkoutsCopyWithImpl;
@override @useResult
$Res call({
 int sessions, int? planned, int prs
});




}
/// @nodoc
class __$BuddyWeeklyWorkoutsCopyWithImpl<$Res>
    implements _$BuddyWeeklyWorkoutsCopyWith<$Res> {
  __$BuddyWeeklyWorkoutsCopyWithImpl(this._self, this._then);

  final _BuddyWeeklyWorkouts _self;
  final $Res Function(_BuddyWeeklyWorkouts) _then;

/// Create a copy of BuddyWeeklyWorkouts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessions = null,Object? planned = freezed,Object? prs = null,}) {
  return _then(_BuddyWeeklyWorkouts(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as int,planned: freezed == planned ? _self.planned : planned // ignore: cast_nullable_to_non_nullable
as int?,prs: null == prs ? _self.prs : prs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
