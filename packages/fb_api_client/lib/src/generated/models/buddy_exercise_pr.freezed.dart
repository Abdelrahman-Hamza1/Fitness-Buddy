// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_exercise_pr.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyExercisePr {

 String get name; String get exerciseRef; double? get kg; int? get reps; String get date;
/// Create a copy of BuddyExercisePr
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyExercisePrCopyWith<BuddyExercisePr> get copyWith => _$BuddyExercisePrCopyWithImpl<BuddyExercisePr>(this as BuddyExercisePr, _$identity);

  /// Serializes this BuddyExercisePr to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyExercisePr;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyExercisePr&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef)&&(identical(other.kg, _this.kg) || other.kg == _this.kg)&&(identical(other.reps, _this.reps) || other.reps == _this.reps)&&(identical(other.date, _this.date) || other.date == _this.date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyExercisePr;
  return Object.hash(runtimeType,_this.name,_this.exerciseRef,_this.kg,_this.reps,_this.date);
}

@override
String toString() {
  final _this = this as BuddyExercisePr;
  return 'BuddyExercisePr(name: ${_this.name}, exerciseRef: ${_this.exerciseRef}, kg: ${_this.kg}, reps: ${_this.reps}, date: ${_this.date})';
}


}

/// @nodoc
abstract mixin class $BuddyExercisePrCopyWith<$Res>  {
  factory $BuddyExercisePrCopyWith(BuddyExercisePr value, $Res Function(BuddyExercisePr) _then) = _$BuddyExercisePrCopyWithImpl;
@useResult
$Res call({
 String name, String exerciseRef, double? kg, int? reps, String date
});




}
/// @nodoc
class _$BuddyExercisePrCopyWithImpl<$Res>
    implements $BuddyExercisePrCopyWith<$Res> {
  _$BuddyExercisePrCopyWithImpl(this._self, this._then);

  final BuddyExercisePr _self;
  final $Res Function(BuddyExercisePr) _then;

/// Create a copy of BuddyExercisePr
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? exerciseRef = null,Object? kg = freezed,Object? reps = freezed,Object? date = null,}) {
  return _then(BuddyExercisePr(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exerciseRef: null == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String,kg: freezed == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double?,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyExercisePr].
extension BuddyExercisePrPatterns on BuddyExercisePr {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyExercisePr value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyExercisePr() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyExercisePr value)  $default,){
final _that = this;
switch (_that) {
case _BuddyExercisePr():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyExercisePr value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyExercisePr() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String exerciseRef,  double? kg,  int? reps,  String date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyExercisePr() when $default != null:
return $default(_that.name,_that.exerciseRef,_that.kg,_that.reps,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String exerciseRef,  double? kg,  int? reps,  String date)  $default,) {final _that = this;
switch (_that) {
case _BuddyExercisePr():
return $default(_that.name,_that.exerciseRef,_that.kg,_that.reps,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String exerciseRef,  double? kg,  int? reps,  String date)?  $default,) {final _that = this;
switch (_that) {
case _BuddyExercisePr() when $default != null:
return $default(_that.name,_that.exerciseRef,_that.kg,_that.reps,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyExercisePr implements BuddyExercisePr {
  const _BuddyExercisePr({required this.name, required this.exerciseRef, required this.kg, required this.reps, required this.date});
  factory _BuddyExercisePr.fromJson(Map<String, dynamic> json) => _$BuddyExercisePrFromJson(json);

@override final  String name;
@override final  String exerciseRef;
@override final  double? kg;
@override final  int? reps;
@override final  String date;

/// Create a copy of BuddyExercisePr
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyExercisePrCopyWith<_BuddyExercisePr> get copyWith => __$BuddyExercisePrCopyWithImpl<_BuddyExercisePr>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyExercisePrToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyExercisePr&&(identical(other.name, name) || other.name == name)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef)&&(identical(other.kg, kg) || other.kg == kg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,exerciseRef,kg,reps,date);
}

@override
String toString() {
    return 'BuddyExercisePr(name: $name, exerciseRef: $exerciseRef, kg: $kg, reps: $reps, date: $date)';
}


}

/// @nodoc
abstract mixin class _$BuddyExercisePrCopyWith<$Res> implements $BuddyExercisePrCopyWith<$Res> {
  factory _$BuddyExercisePrCopyWith(_BuddyExercisePr value, $Res Function(_BuddyExercisePr) _then) = __$BuddyExercisePrCopyWithImpl;
@override @useResult
$Res call({
 String name, String exerciseRef, double? kg, int? reps, String date
});




}
/// @nodoc
class __$BuddyExercisePrCopyWithImpl<$Res>
    implements _$BuddyExercisePrCopyWith<$Res> {
  __$BuddyExercisePrCopyWithImpl(this._self, this._then);

  final _BuddyExercisePr _self;
  final $Res Function(_BuddyExercisePr) _then;

/// Create a copy of BuddyExercisePr
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? exerciseRef = null,Object? kg = freezed,Object? reps = freezed,Object? date = null,}) {
  return _then(_BuddyExercisePr(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,exerciseRef: null == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String,kg: freezed == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double?,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
