// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_workout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWorkout {

 BuddyWorkoutKind get kind; String? get name; String get language; String get script; String? get timeHint; String? get dateHint; List<BuddyWorkoutExercise> get exercises;
/// Create a copy of BuddyWorkout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWorkoutCopyWith<BuddyWorkout> get copyWith => _$BuddyWorkoutCopyWithImpl<BuddyWorkout>(this as BuddyWorkout, _$identity);

  /// Serializes this BuddyWorkout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWorkout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWorkout&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint)&&const DeepCollectionEquality().equals(other.exercises, _this.exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWorkout;
  return Object.hash(runtimeType,_this.kind,_this.name,_this.language,_this.script,_this.timeHint,_this.dateHint,const DeepCollectionEquality().hash(_this.exercises));
}

@override
String toString() {
  final _this = this as BuddyWorkout;
  return 'BuddyWorkout(kind: ${_this.kind}, name: ${_this.name}, language: ${_this.language}, script: ${_this.script}, timeHint: ${_this.timeHint}, dateHint: ${_this.dateHint}, exercises: ${_this.exercises})';
}


}

/// @nodoc
abstract mixin class $BuddyWorkoutCopyWith<$Res>  {
  factory $BuddyWorkoutCopyWith(BuddyWorkout value, $Res Function(BuddyWorkout) _then) = _$BuddyWorkoutCopyWithImpl;
@useResult
$Res call({
 BuddyWorkoutKind kind, String? name, String language, String script, String? timeHint, String? dateHint, List<BuddyWorkoutExercise> exercises
});




}
/// @nodoc
class _$BuddyWorkoutCopyWithImpl<$Res>
    implements $BuddyWorkoutCopyWith<$Res> {
  _$BuddyWorkoutCopyWithImpl(this._self, this._then);

  final BuddyWorkout _self;
  final $Res Function(BuddyWorkout) _then;

/// Create a copy of BuddyWorkout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? name = freezed,Object? language = null,Object? script = null,Object? timeHint = freezed,Object? dateHint = freezed,Object? exercises = null,}) {
  return _then(BuddyWorkout(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyWorkoutKind,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutExercise>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWorkout].
extension BuddyWorkoutPatterns on BuddyWorkout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWorkout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWorkout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWorkout value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWorkout value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWorkout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyWorkoutKind kind,  String? name,  String language,  String script,  String? timeHint,  String? dateHint,  List<BuddyWorkoutExercise> exercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWorkout() when $default != null:
return $default(_that.kind,_that.name,_that.language,_that.script,_that.timeHint,_that.dateHint,_that.exercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyWorkoutKind kind,  String? name,  String language,  String script,  String? timeHint,  String? dateHint,  List<BuddyWorkoutExercise> exercises)  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkout():
return $default(_that.kind,_that.name,_that.language,_that.script,_that.timeHint,_that.dateHint,_that.exercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyWorkoutKind kind,  String? name,  String language,  String script,  String? timeHint,  String? dateHint,  List<BuddyWorkoutExercise> exercises)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWorkout() when $default != null:
return $default(_that.kind,_that.name,_that.language,_that.script,_that.timeHint,_that.dateHint,_that.exercises);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWorkout implements BuddyWorkout {
  const _BuddyWorkout({required this.kind, required this.name, required this.language, required this.script, required this.timeHint, required this.dateHint, required  List<BuddyWorkoutExercise> exercises}): _exercises = exercises;
  factory _BuddyWorkout.fromJson(Map<String, dynamic> json) => _$BuddyWorkoutFromJson(json);

@override final  BuddyWorkoutKind kind;
@override final  String? name;
@override final  String language;
@override final  String script;
@override final  String? timeHint;
@override final  String? dateHint;
 final  List<BuddyWorkoutExercise> _exercises;
@override List<BuddyWorkoutExercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of BuddyWorkout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWorkoutCopyWith<_BuddyWorkout> get copyWith => __$BuddyWorkoutCopyWithImpl<_BuddyWorkout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWorkoutToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWorkout&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&const DeepCollectionEquality().equals(other.exercises, _exercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,name,language,script,timeHint,dateHint,const DeepCollectionEquality().hash(_exercises));
}

@override
String toString() {
    return 'BuddyWorkout(kind: $kind, name: $name, language: $language, script: $script, timeHint: $timeHint, dateHint: $dateHint, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class _$BuddyWorkoutCopyWith<$Res> implements $BuddyWorkoutCopyWith<$Res> {
  factory _$BuddyWorkoutCopyWith(_BuddyWorkout value, $Res Function(_BuddyWorkout) _then) = __$BuddyWorkoutCopyWithImpl;
@override @useResult
$Res call({
 BuddyWorkoutKind kind, String? name, String language, String script, String? timeHint, String? dateHint, List<BuddyWorkoutExercise> exercises
});




}
/// @nodoc
class __$BuddyWorkoutCopyWithImpl<$Res>
    implements _$BuddyWorkoutCopyWith<$Res> {
  __$BuddyWorkoutCopyWithImpl(this._self, this._then);

  final _BuddyWorkout _self;
  final $Res Function(_BuddyWorkout) _then;

/// Create a copy of BuddyWorkout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? name = freezed,Object? language = null,Object? script = null,Object? timeHint = freezed,Object? dateHint = freezed,Object? exercises = null,}) {
  return _then(_BuddyWorkout(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyWorkoutKind,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<BuddyWorkoutExercise>,
  ));
}


}

// dart format on
