// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_workout_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWorkoutSet {

 int? get reps; double? get weight; BuddyLoadUnit? get unit;/// The stated weight is per dumbbell.
 bool get perDumbbell; int? get durationSeconds; double? get distanceMeters;
/// Create a copy of BuddyWorkoutSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWorkoutSetCopyWith<BuddyWorkoutSet> get copyWith => _$BuddyWorkoutSetCopyWithImpl<BuddyWorkoutSet>(this as BuddyWorkoutSet, _$identity);

  /// Serializes this BuddyWorkoutSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWorkoutSet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWorkoutSet&&(identical(other.reps, _this.reps) || other.reps == _this.reps)&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.perDumbbell, _this.perDumbbell) || other.perDumbbell == _this.perDumbbell)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds)&&(identical(other.distanceMeters, _this.distanceMeters) || other.distanceMeters == _this.distanceMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWorkoutSet;
  return Object.hash(runtimeType,_this.reps,_this.weight,_this.unit,_this.perDumbbell,_this.durationSeconds,_this.distanceMeters);
}

@override
String toString() {
  final _this = this as BuddyWorkoutSet;
  return 'BuddyWorkoutSet(reps: ${_this.reps}, weight: ${_this.weight}, unit: ${_this.unit}, perDumbbell: ${_this.perDumbbell}, durationSeconds: ${_this.durationSeconds}, distanceMeters: ${_this.distanceMeters})';
}


}

/// @nodoc
abstract mixin class $BuddyWorkoutSetCopyWith<$Res>  {
  factory $BuddyWorkoutSetCopyWith(BuddyWorkoutSet value, $Res Function(BuddyWorkoutSet) _then) = _$BuddyWorkoutSetCopyWithImpl;
@useResult
$Res call({
 int? reps, double? weight, BuddyLoadUnit? unit, bool perDumbbell, int? durationSeconds, double? distanceMeters
});




}
/// @nodoc
class _$BuddyWorkoutSetCopyWithImpl<$Res>
    implements $BuddyWorkoutSetCopyWith<$Res> {
  _$BuddyWorkoutSetCopyWithImpl(this._self, this._then);

  final BuddyWorkoutSet _self;
  final $Res Function(BuddyWorkoutSet) _then;

/// Create a copy of BuddyWorkoutSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reps = freezed,Object? weight = freezed,Object? unit = freezed,Object? perDumbbell = null,Object? durationSeconds = freezed,Object? distanceMeters = freezed,}) {
  return _then(BuddyWorkoutSet(
reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyLoadUnit?,perDumbbell: null == perDumbbell ? _self.perDumbbell : perDumbbell // ignore: cast_nullable_to_non_nullable
as bool,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWorkoutSet].
extension BuddyWorkoutSetPatterns on BuddyWorkoutSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWorkoutSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWorkoutSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWorkoutSet value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWorkoutSet value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? reps,  double? weight,  BuddyLoadUnit? unit,  bool perDumbbell,  int? durationSeconds,  double? distanceMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWorkoutSet() when $default != null:
return $default(_that.reps,_that.weight,_that.unit,_that.perDumbbell,_that.durationSeconds,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? reps,  double? weight,  BuddyLoadUnit? unit,  bool perDumbbell,  int? durationSeconds,  double? distanceMeters)  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutSet():
return $default(_that.reps,_that.weight,_that.unit,_that.perDumbbell,_that.durationSeconds,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? reps,  double? weight,  BuddyLoadUnit? unit,  bool perDumbbell,  int? durationSeconds,  double? distanceMeters)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutSet() when $default != null:
return $default(_that.reps,_that.weight,_that.unit,_that.perDumbbell,_that.durationSeconds,_that.distanceMeters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWorkoutSet implements BuddyWorkoutSet {
  const _BuddyWorkoutSet({required this.reps, required this.weight, required this.unit, required this.perDumbbell, required this.durationSeconds, required this.distanceMeters});
  factory _BuddyWorkoutSet.fromJson(Map<String, dynamic> json) => _$BuddyWorkoutSetFromJson(json);

@override final  int? reps;
@override final  double? weight;
@override final  BuddyLoadUnit? unit;
/// The stated weight is per dumbbell.
@override final  bool perDumbbell;
@override final  int? durationSeconds;
@override final  double? distanceMeters;

/// Create a copy of BuddyWorkoutSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWorkoutSetCopyWith<_BuddyWorkoutSet> get copyWith => __$BuddyWorkoutSetCopyWithImpl<_BuddyWorkoutSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWorkoutSetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWorkoutSet&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.perDumbbell, perDumbbell) || other.perDumbbell == perDumbbell)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reps,weight,unit,perDumbbell,durationSeconds,distanceMeters);
}

@override
String toString() {
    return 'BuddyWorkoutSet(reps: $reps, weight: $weight, unit: $unit, perDumbbell: $perDumbbell, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters)';
}


}

/// @nodoc
abstract mixin class _$BuddyWorkoutSetCopyWith<$Res> implements $BuddyWorkoutSetCopyWith<$Res> {
  factory _$BuddyWorkoutSetCopyWith(_BuddyWorkoutSet value, $Res Function(_BuddyWorkoutSet) _then) = __$BuddyWorkoutSetCopyWithImpl;
@override @useResult
$Res call({
 int? reps, double? weight, BuddyLoadUnit? unit, bool perDumbbell, int? durationSeconds, double? distanceMeters
});




}
/// @nodoc
class __$BuddyWorkoutSetCopyWithImpl<$Res>
    implements _$BuddyWorkoutSetCopyWith<$Res> {
  __$BuddyWorkoutSetCopyWithImpl(this._self, this._then);

  final _BuddyWorkoutSet _self;
  final $Res Function(_BuddyWorkoutSet) _then;

/// Create a copy of BuddyWorkoutSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reps = freezed,Object? weight = freezed,Object? unit = freezed,Object? perDumbbell = null,Object? durationSeconds = freezed,Object? distanceMeters = freezed,}) {
  return _then(_BuddyWorkoutSet(
reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyLoadUnit?,perDumbbell: null == perDumbbell ? _self.perDumbbell : perDumbbell // ignore: cast_nullable_to_non_nullable
as bool,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
