// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_workouts_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadWorkoutsArgs {

 BuddyDateRange get range; String? get exerciseRef;
/// Create a copy of BuddyReadWorkoutsArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsArgsCopyWith<BuddyReadWorkoutsArgs> get copyWith => _$BuddyReadWorkoutsArgsCopyWithImpl<BuddyReadWorkoutsArgs>(this as BuddyReadWorkoutsArgs, _$identity);

  /// Serializes this BuddyReadWorkoutsArgs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadWorkoutsArgs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadWorkoutsArgs&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadWorkoutsArgs;
  return Object.hash(runtimeType,_this.range,_this.exerciseRef);
}

@override
String toString() {
  final _this = this as BuddyReadWorkoutsArgs;
  return 'BuddyReadWorkoutsArgs(range: ${_this.range}, exerciseRef: ${_this.exerciseRef})';
}


}

/// @nodoc
abstract mixin class $BuddyReadWorkoutsArgsCopyWith<$Res>  {
  factory $BuddyReadWorkoutsArgsCopyWith(BuddyReadWorkoutsArgs value, $Res Function(BuddyReadWorkoutsArgs) _then) = _$BuddyReadWorkoutsArgsCopyWithImpl;
@useResult
$Res call({
 BuddyDateRange range, String? exerciseRef
});


$BuddyDateRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$BuddyReadWorkoutsArgsCopyWithImpl<$Res>
    implements $BuddyReadWorkoutsArgsCopyWith<$Res> {
  _$BuddyReadWorkoutsArgsCopyWithImpl(this._self, this._then);

  final BuddyReadWorkoutsArgs _self;
  final $Res Function(BuddyReadWorkoutsArgs) _then;

/// Create a copy of BuddyReadWorkoutsArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? exerciseRef = freezed,}) {
  return _then(BuddyReadWorkoutsArgs(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyDateRange,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of BuddyReadWorkoutsArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<$Res> get range {
  
  return $BuddyDateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadWorkoutsArgs].
extension BuddyReadWorkoutsArgsPatterns on BuddyReadWorkoutsArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsArgs value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadWorkoutsArgs value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyDateRange range,  String? exerciseRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsArgs() when $default != null:
return $default(_that.range,_that.exerciseRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyDateRange range,  String? exerciseRef)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsArgs():
return $default(_that.range,_that.exerciseRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyDateRange range,  String? exerciseRef)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsArgs() when $default != null:
return $default(_that.range,_that.exerciseRef);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadWorkoutsArgs implements BuddyReadWorkoutsArgs {
  const _BuddyReadWorkoutsArgs({required this.range, required this.exerciseRef});
  factory _BuddyReadWorkoutsArgs.fromJson(Map<String, dynamic> json) => _$BuddyReadWorkoutsArgsFromJson(json);

@override final  BuddyDateRange range;
@override final  String? exerciseRef;

/// Create a copy of BuddyReadWorkoutsArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadWorkoutsArgsCopyWith<_BuddyReadWorkoutsArgs> get copyWith => __$BuddyReadWorkoutsArgsCopyWithImpl<_BuddyReadWorkoutsArgs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadWorkoutsArgsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadWorkoutsArgs&&(identical(other.range, range) || other.range == range)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,range,exerciseRef);
}

@override
String toString() {
    return 'BuddyReadWorkoutsArgs(range: $range, exerciseRef: $exerciseRef)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadWorkoutsArgsCopyWith<$Res> implements $BuddyReadWorkoutsArgsCopyWith<$Res> {
  factory _$BuddyReadWorkoutsArgsCopyWith(_BuddyReadWorkoutsArgs value, $Res Function(_BuddyReadWorkoutsArgs) _then) = __$BuddyReadWorkoutsArgsCopyWithImpl;
@override @useResult
$Res call({
 BuddyDateRange range, String? exerciseRef
});


@override $BuddyDateRangeCopyWith<$Res> get range;

}
/// @nodoc
class __$BuddyReadWorkoutsArgsCopyWithImpl<$Res>
    implements _$BuddyReadWorkoutsArgsCopyWith<$Res> {
  __$BuddyReadWorkoutsArgsCopyWithImpl(this._self, this._then);

  final _BuddyReadWorkoutsArgs _self;
  final $Res Function(_BuddyReadWorkoutsArgs) _then;

/// Create a copy of BuddyReadWorkoutsArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? exerciseRef = freezed,}) {
  return _then(_BuddyReadWorkoutsArgs(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyDateRange,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyReadWorkoutsArgs
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<$Res> get range {
  
  return $BuddyDateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
