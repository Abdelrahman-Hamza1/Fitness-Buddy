// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_workout_exercise_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWorkoutExerciseRow {

 String get name; String get exerciseRef; List<BuddySetRow> get sets;
/// Create a copy of BuddyWorkoutExerciseRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWorkoutExerciseRowCopyWith<BuddyWorkoutExerciseRow> get copyWith => _$BuddyWorkoutExerciseRowCopyWithImpl<BuddyWorkoutExerciseRow>(this as BuddyWorkoutExerciseRow, _$identity);

  /// Serializes this BuddyWorkoutExerciseRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWorkoutExerciseRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWorkoutExerciseRow&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef)&&const DeepCollectionEquality().equals(other.sets, _this.sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWorkoutExerciseRow;
  return Object.hash(runtimeType,_this.name,_this.exerciseRef,const DeepCollectionEquality().hash(_this.sets));
}

@override
String toString() {
  final _this = this as BuddyWorkoutExerciseRow;
  return 'BuddyWorkoutExerciseRow(name: ${_this.name}, exerciseRef: ${_this.exerciseRef}, sets: ${_this.sets})';
}


}

/// @nodoc
abstract mixin class $BuddyWorkoutExerciseRowCopyWith<$Res>  {
  factory $BuddyWorkoutExerciseRowCopyWith(BuddyWorkoutExerciseRow value, $Res Function(BuddyWorkoutExerciseRow) _then) = _$BuddyWorkoutExerciseRowCopyWithImpl;
@useResult
$Res call({
 String name, String exerciseRef, List<BuddySetRow> sets
});




}
/// @nodoc
class _$BuddyWorkoutExerciseRowCopyWithImpl<$Res>
    implements $BuddyWorkoutExerciseRowCopyWith<$Res> {
  _$BuddyWorkoutExerciseRowCopyWithImpl(this._self, this._then);

  final BuddyWorkoutExerciseRow _self;
  final $Res Function(BuddyWorkoutExerciseRow) _then;

/// Create a copy of BuddyWorkoutExerciseRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? exerciseRef = null,Object? sets = null,}) {
  return _then(BuddyWorkoutExerciseRow(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exerciseRef: null == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<BuddySetRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWorkoutExerciseRow].
extension BuddyWorkoutExerciseRowPatterns on BuddyWorkoutExerciseRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWorkoutExerciseRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWorkoutExerciseRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWorkoutExerciseRow value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutExerciseRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWorkoutExerciseRow value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutExerciseRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String exerciseRef,  List<BuddySetRow> sets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWorkoutExerciseRow() when $default != null:
return $default(_that.name,_that.exerciseRef,_that.sets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String exerciseRef,  List<BuddySetRow> sets)  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutExerciseRow():
return $default(_that.name,_that.exerciseRef,_that.sets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String exerciseRef,  List<BuddySetRow> sets)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutExerciseRow() when $default != null:
return $default(_that.name,_that.exerciseRef,_that.sets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWorkoutExerciseRow implements BuddyWorkoutExerciseRow {
  const _BuddyWorkoutExerciseRow({required this.name, required this.exerciseRef, required  List<BuddySetRow> sets}): _sets = sets;
  factory _BuddyWorkoutExerciseRow.fromJson(Map<String, dynamic> json) => _$BuddyWorkoutExerciseRowFromJson(json);

@override final  String name;
@override final  String exerciseRef;
 final  List<BuddySetRow> _sets;
@override List<BuddySetRow> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}


/// Create a copy of BuddyWorkoutExerciseRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWorkoutExerciseRowCopyWith<_BuddyWorkoutExerciseRow> get copyWith => __$BuddyWorkoutExerciseRowCopyWithImpl<_BuddyWorkoutExerciseRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWorkoutExerciseRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWorkoutExerciseRow&&(identical(other.name, name) || other.name == name)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef)&&const DeepCollectionEquality().equals(other.sets, _sets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,exerciseRef,const DeepCollectionEquality().hash(_sets));
}

@override
String toString() {
    return 'BuddyWorkoutExerciseRow(name: $name, exerciseRef: $exerciseRef, sets: $sets)';
}


}

/// @nodoc
abstract mixin class _$BuddyWorkoutExerciseRowCopyWith<$Res> implements $BuddyWorkoutExerciseRowCopyWith<$Res> {
  factory _$BuddyWorkoutExerciseRowCopyWith(_BuddyWorkoutExerciseRow value, $Res Function(_BuddyWorkoutExerciseRow) _then) = __$BuddyWorkoutExerciseRowCopyWithImpl;
@override @useResult
$Res call({
 String name, String exerciseRef, List<BuddySetRow> sets
});




}
/// @nodoc
class __$BuddyWorkoutExerciseRowCopyWithImpl<$Res>
    implements _$BuddyWorkoutExerciseRowCopyWith<$Res> {
  __$BuddyWorkoutExerciseRowCopyWithImpl(this._self, this._then);

  final _BuddyWorkoutExerciseRow _self;
  final $Res Function(_BuddyWorkoutExerciseRow) _then;

/// Create a copy of BuddyWorkoutExerciseRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? exerciseRef = null,Object? sets = null,}) {
  return _then(_BuddyWorkoutExerciseRow(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exerciseRef: null == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<BuddySetRow>,
  ));
}


}

// dart format on
