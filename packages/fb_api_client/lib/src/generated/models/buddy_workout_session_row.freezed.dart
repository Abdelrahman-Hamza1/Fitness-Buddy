// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_workout_session_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWorkoutSessionRow {

 String? get name; String get id; String get date; List<BuddyWorkoutExerciseRow> get exercises;
/// Create a copy of BuddyWorkoutSessionRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWorkoutSessionRowCopyWith<BuddyWorkoutSessionRow> get copyWith => _$BuddyWorkoutSessionRowCopyWithImpl<BuddyWorkoutSessionRow>(this as BuddyWorkoutSessionRow, _$identity);

  /// Serializes this BuddyWorkoutSessionRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWorkoutSessionRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWorkoutSessionRow&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&const DeepCollectionEquality().equals(other.exercises, _this.exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWorkoutSessionRow;
  return Object.hash(runtimeType,_this.name,_this.id,_this.date,const DeepCollectionEquality().hash(_this.exercises));
}

@override
String toString() {
  final _this = this as BuddyWorkoutSessionRow;
  return 'BuddyWorkoutSessionRow(name: ${_this.name}, id: ${_this.id}, date: ${_this.date}, exercises: ${_this.exercises})';
}


}

/// @nodoc
abstract mixin class $BuddyWorkoutSessionRowCopyWith<$Res>  {
  factory $BuddyWorkoutSessionRowCopyWith(BuddyWorkoutSessionRow value, $Res Function(BuddyWorkoutSessionRow) _then) = _$BuddyWorkoutSessionRowCopyWithImpl;
@useResult
$Res call({
 String? name, String id, String date, List<BuddyWorkoutExerciseRow> exercises
});




}
/// @nodoc
class _$BuddyWorkoutSessionRowCopyWithImpl<$Res>
    implements $BuddyWorkoutSessionRowCopyWith<$Res> {
  _$BuddyWorkoutSessionRowCopyWithImpl(this._self, this._then);

  final BuddyWorkoutSessionRow _self;
  final $Res Function(BuddyWorkoutSessionRow) _then;

/// Create a copy of BuddyWorkoutSessionRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? id = null,Object? date = null,Object? exercises = null,}) {
  return _then(BuddyWorkoutSessionRow(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutExerciseRow>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWorkoutSessionRow].
extension BuddyWorkoutSessionRowPatterns on BuddyWorkoutSessionRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWorkoutSessionRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWorkoutSessionRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWorkoutSessionRow value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutSessionRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWorkoutSessionRow value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkoutSessionRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String id,  String date,  List<BuddyWorkoutExerciseRow> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWorkoutSessionRow() when $default != null:
return $default(_that.name,_that.id,_that.date,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String id,  String date,  List<BuddyWorkoutExerciseRow> exercises)  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutSessionRow():
return $default(_that.name,_that.id,_that.date,_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String id,  String date,  List<BuddyWorkoutExerciseRow> exercises)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkoutSessionRow() when $default != null:
return $default(_that.name,_that.id,_that.date,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWorkoutSessionRow implements BuddyWorkoutSessionRow {
  const _BuddyWorkoutSessionRow({required this.name, required this.id, required this.date, required  List<BuddyWorkoutExerciseRow> exercises}): _exercises = exercises;
  factory _BuddyWorkoutSessionRow.fromJson(Map<String, dynamic> json) => _$BuddyWorkoutSessionRowFromJson(json);

@override final  String? name;
@override final  String id;
@override final  String date;
 final  List<BuddyWorkoutExerciseRow> _exercises;
@override List<BuddyWorkoutExerciseRow> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of BuddyWorkoutSessionRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWorkoutSessionRowCopyWith<_BuddyWorkoutSessionRow> get copyWith => __$BuddyWorkoutSessionRowCopyWithImpl<_BuddyWorkoutSessionRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWorkoutSessionRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWorkoutSessionRow&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.exercises, _exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,id,date,const DeepCollectionEquality().hash(_exercises));
}

@override
String toString() {
    return 'BuddyWorkoutSessionRow(name: $name, id: $id, date: $date, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$BuddyWorkoutSessionRowCopyWith<$Res> implements $BuddyWorkoutSessionRowCopyWith<$Res> {
  factory _$BuddyWorkoutSessionRowCopyWith(_BuddyWorkoutSessionRow value, $Res Function(_BuddyWorkoutSessionRow) _then) = __$BuddyWorkoutSessionRowCopyWithImpl;
@override @useResult
$Res call({
 String? name, String id, String date, List<BuddyWorkoutExerciseRow> exercises
});




}
/// @nodoc
class __$BuddyWorkoutSessionRowCopyWithImpl<$Res>
    implements _$BuddyWorkoutSessionRowCopyWith<$Res> {
  __$BuddyWorkoutSessionRowCopyWithImpl(this._self, this._then);

  final _BuddyWorkoutSessionRow _self;
  final $Res Function(_BuddyWorkoutSessionRow) _then;

/// Create a copy of BuddyWorkoutSessionRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? id = null,Object? date = null,Object? exercises = null,}) {
  return _then(_BuddyWorkoutSessionRow(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutExerciseRow>,
  ));
}


}

// dart format on
