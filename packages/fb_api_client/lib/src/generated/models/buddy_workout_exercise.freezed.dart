// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_workout_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWorkoutExercise {

 String get mention;/// A library exercise code or a custom exercise UUID; null when nothing matched (the app asks, WO-033).
 String? get exerciseRef; List<BuddyWorkoutSet> get sets; List<String> get assumptions;
/// Create a copy of BuddyWorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWorkoutExerciseCopyWith<BuddyWorkoutExercise> get copyWith => _$BuddyWorkoutExerciseCopyWithImpl<BuddyWorkoutExercise>(this as BuddyWorkoutExercise, _$identity);

  /// Serializes this BuddyWorkoutExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWorkoutExercise;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWorkoutExercise&&(identical(other.mention, _this.mention) || other.mention == _this.mention)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef)&&const DeepCollectionEquality().equals(other.sets, _this.sets)&&const DeepCollectionEquality().equals(other.assumptions, _this.assumptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWorkoutExercise;
  return Object.hash(runtimeType,_this.mention,_this.exerciseRef,const DeepCollectionEquality().hash(_this.sets),const DeepCollectionEquality().hash(_this.assumptions));
}

@override
String toString() {
  final _this = this as BuddyWorkoutExercise;
  return 'BuddyWorkoutExercise(mention: ${_this.mention}, exerciseRef: ${_this.exerciseRef}, sets: ${_this.sets}, assumptions: ${_this.assumptions})';
}


}

/// @nodoc
abstract mixin class $BuddyWorkoutExerciseCopyWith<$Res>  {
  factory $BuddyWorkoutExerciseCopyWith(BuddyWorkoutExercise value, $Res Function(BuddyWorkoutExercise) _then) = _$BuddyWorkoutExerciseCopyWithImpl;
@useResult
$Res call({
 String mention, String? exerciseRef, List<BuddyWorkoutSet> sets, List<String> assumptions
});




}
/// @nodoc
class _$BuddyWorkoutExerciseCopyWithImpl<$Res>
    implements $BuddyWorkoutExerciseCopyWith<$Res> {
  _$BuddyWorkoutExerciseCopyWithImpl(this._self, this._then);

  final BuddyWorkoutExercise _self;
  final $Res Function(BuddyWorkoutExercise) _then;

/// Create a copy of BuddyWorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mention = null,Object? exerciseRef = freezed,Object? sets = null,Object? assumptions = null,}) {
  return _then(BuddyWorkoutExercise(
mention: null == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as String,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutSet>,assumptions: null == assumptions ? _self.assumptions : assumptions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWorkoutExercise].
extension BuddyWorkoutExercisePatterns on BuddyWorkoutExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWorkoutExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWorkoutExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWorkoutExercise value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWorkoutExercise value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String mention,  String? exerciseRef,  List<BuddyWorkoutSet> sets,  List<String> assumptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWorkoutExercise() when $default != null:
return $default(_that.mention,_that.exerciseRef,_that.sets,_that.assumptions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String mention,  String? exerciseRef,  List<BuddyWorkoutSet> sets,  List<String> assumptions)  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutExercise():
return $default(_that.mention,_that.exerciseRef,_that.sets,_that.assumptions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String mention,  String? exerciseRef,  List<BuddyWorkoutSet> sets,  List<String> assumptions)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutExercise() when $default != null:
return $default(_that.mention,_that.exerciseRef,_that.sets,_that.assumptions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWorkoutExercise implements BuddyWorkoutExercise {
  const _BuddyWorkoutExercise({required this.mention, required this.exerciseRef, required  List<BuddyWorkoutSet> sets, required  List<String> assumptions}): _sets = sets,_assumptions = assumptions;
  factory _BuddyWorkoutExercise.fromJson(Map<String, dynamic> json) => _$BuddyWorkoutExerciseFromJson(json);

@override final  String mention;
/// A library exercise code or a custom exercise UUID; null when nothing matched (the app asks, WO-033).
@override final  String? exerciseRef;
 final  List<BuddyWorkoutSet> _sets;
@override List<BuddyWorkoutSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

 final  List<String> _assumptions;
@override List<String> get assumptions {
  if (_assumptions is EqualUnmodifiableListView) return _assumptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assumptions);
}


/// Create a copy of BuddyWorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWorkoutExerciseCopyWith<_BuddyWorkoutExercise> get copyWith => __$BuddyWorkoutExerciseCopyWithImpl<_BuddyWorkoutExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWorkoutExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWorkoutExercise&&(identical(other.mention, mention) || other.mention == mention)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef)&&const DeepCollectionEquality().equals(other.sets, _sets)&&const DeepCollectionEquality().equals(other.assumptions, _assumptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mention,exerciseRef,const DeepCollectionEquality().hash(_sets),const DeepCollectionEquality().hash(_assumptions));
}

@override
String toString() {
    return 'BuddyWorkoutExercise(mention: $mention, exerciseRef: $exerciseRef, sets: $sets, assumptions: $assumptions)';
}


}

/// @nodoc
abstract mixin class _$BuddyWorkoutExerciseCopyWith<$Res> implements $BuddyWorkoutExerciseCopyWith<$Res> {
  factory _$BuddyWorkoutExerciseCopyWith(_BuddyWorkoutExercise value, $Res Function(_BuddyWorkoutExercise) _then) = __$BuddyWorkoutExerciseCopyWithImpl;
@override @useResult
$Res call({
 String mention, String? exerciseRef, List<BuddyWorkoutSet> sets, List<String> assumptions
});




}
/// @nodoc
class __$BuddyWorkoutExerciseCopyWithImpl<$Res>
    implements _$BuddyWorkoutExerciseCopyWith<$Res> {
  __$BuddyWorkoutExerciseCopyWithImpl(this._self, this._then);

  final _BuddyWorkoutExercise _self;
  final $Res Function(_BuddyWorkoutExercise) _then;

/// Create a copy of BuddyWorkoutExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mention = null,Object? exerciseRef = freezed,Object? sets = null,Object? assumptions = null,}) {
  return _then(_BuddyWorkoutExercise(
mention: null == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as String,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutSet>,assumptions: null == assumptions ? _self._assumptions : assumptions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
