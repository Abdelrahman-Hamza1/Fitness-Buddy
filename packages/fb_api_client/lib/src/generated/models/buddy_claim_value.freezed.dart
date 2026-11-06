// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_claim_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyClaimValue {

 BuddyQueryMetric get metric; BuddyQueryOp get operation; double? get value; String? get date; BuddyClaimUnit get unit;/// For op last: the session found (mapped to a handle).
 String? get workoutId; String? get exerciseRef; String? get muscleGroup;
/// Create a copy of BuddyClaimValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyClaimValueCopyWith<BuddyClaimValue> get copyWith => _$BuddyClaimValueCopyWithImpl<BuddyClaimValue>(this as BuddyClaimValue, _$identity);

  /// Serializes this BuddyClaimValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyClaimValue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyClaimValue&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.workoutId, _this.workoutId) || other.workoutId == _this.workoutId)&&(identical(other.exerciseRef, _this.exerciseRef) || other.exerciseRef == _this.exerciseRef)&&(identical(other.muscleGroup, _this.muscleGroup) || other.muscleGroup == _this.muscleGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyClaimValue;
  return Object.hash(runtimeType,_this.metric,_this.operation,_this.value,_this.date,_this.unit,_this.workoutId,_this.exerciseRef,_this.muscleGroup);
}

@override
String toString() {
  final _this = this as BuddyClaimValue;
  return 'BuddyClaimValue(metric: ${_this.metric}, operation: ${_this.operation}, value: ${_this.value}, date: ${_this.date}, unit: ${_this.unit}, workoutId: ${_this.workoutId}, exerciseRef: ${_this.exerciseRef}, muscleGroup: ${_this.muscleGroup})';
}


}

/// @nodoc
abstract mixin class $BuddyClaimValueCopyWith<$Res>  {
  factory $BuddyClaimValueCopyWith(BuddyClaimValue value, $Res Function(BuddyClaimValue) _then) = _$BuddyClaimValueCopyWithImpl;
@useResult
$Res call({
 BuddyQueryMetric metric, BuddyQueryOp operation, double? value, String? date, BuddyClaimUnit unit, String? workoutId, String? exerciseRef, String? muscleGroup
});




}
/// @nodoc
class _$BuddyClaimValueCopyWithImpl<$Res>
    implements $BuddyClaimValueCopyWith<$Res> {
  _$BuddyClaimValueCopyWithImpl(this._self, this._then);

  final BuddyClaimValue _self;
  final $Res Function(BuddyClaimValue) _then;

/// Create a copy of BuddyClaimValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metric = null,Object? operation = null,Object? value = freezed,Object? date = freezed,Object? unit = null,Object? workoutId = freezed,Object? exerciseRef = freezed,Object? muscleGroup = freezed,}) {
  return _then(BuddyClaimValue(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as BuddyQueryMetric,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyQueryOp,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyClaimUnit,workoutId: freezed == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String?,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,muscleGroup: freezed == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyClaimValue].
extension BuddyClaimValuePatterns on BuddyClaimValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyClaimValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyClaimValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyClaimValue value)  $default,){
final _that = this;
switch (_that) {
case _BuddyClaimValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyClaimValue value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyClaimValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyQueryMetric metric,  BuddyQueryOp operation,  double? value,  String? date,  BuddyClaimUnit unit,  String? workoutId,  String? exerciseRef,  String? muscleGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyClaimValue() when $default != null:
return $default(_that.metric,_that.operation,_that.value,_that.date,_that.unit,_that.workoutId,_that.exerciseRef,_that.muscleGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyQueryMetric metric,  BuddyQueryOp operation,  double? value,  String? date,  BuddyClaimUnit unit,  String? workoutId,  String? exerciseRef,  String? muscleGroup)  $default,) {final _that = this;
switch (_that) {
case _BuddyClaimValue():
return $default(_that.metric,_that.operation,_that.value,_that.date,_that.unit,_that.workoutId,_that.exerciseRef,_that.muscleGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyQueryMetric metric,  BuddyQueryOp operation,  double? value,  String? date,  BuddyClaimUnit unit,  String? workoutId,  String? exerciseRef,  String? muscleGroup)?  $default,) {final _that = this;
switch (_that) {
case _BuddyClaimValue() when $default != null:
return $default(_that.metric,_that.operation,_that.value,_that.date,_that.unit,_that.workoutId,_that.exerciseRef,_that.muscleGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyClaimValue implements BuddyClaimValue {
  const _BuddyClaimValue({required this.metric, required this.operation, required this.value, required this.date, required this.unit, required this.workoutId, required this.exerciseRef, required this.muscleGroup});
  factory _BuddyClaimValue.fromJson(Map<String, dynamic> json) => _$BuddyClaimValueFromJson(json);

@override final  BuddyQueryMetric metric;
@override final  BuddyQueryOp operation;
@override final  double? value;
@override final  String? date;
@override final  BuddyClaimUnit unit;
/// For op last: the session found (mapped to a handle).
@override final  String? workoutId;
@override final  String? exerciseRef;
@override final  String? muscleGroup;

/// Create a copy of BuddyClaimValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyClaimValueCopyWith<_BuddyClaimValue> get copyWith => __$BuddyClaimValueCopyWithImpl<_BuddyClaimValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyClaimValueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyClaimValue&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.value, value) || other.value == value)&&(identical(other.date, date) || other.date == date)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.workoutId, workoutId) || other.workoutId == workoutId)&&(identical(other.exerciseRef, exerciseRef) || other.exerciseRef == exerciseRef)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,metric,operation,value,date,unit,workoutId,exerciseRef,muscleGroup);
}

@override
String toString() {
    return 'BuddyClaimValue(metric: $metric, operation: $operation, value: $value, date: $date, unit: $unit, workoutId: $workoutId, exerciseRef: $exerciseRef, muscleGroup: $muscleGroup)';
}


}

/// @nodoc
abstract mixin class _$BuddyClaimValueCopyWith<$Res> implements $BuddyClaimValueCopyWith<$Res> {
  factory _$BuddyClaimValueCopyWith(_BuddyClaimValue value, $Res Function(_BuddyClaimValue) _then) = __$BuddyClaimValueCopyWithImpl;
@override @useResult
$Res call({
 BuddyQueryMetric metric, BuddyQueryOp operation, double? value, String? date, BuddyClaimUnit unit, String? workoutId, String? exerciseRef, String? muscleGroup
});




}
/// @nodoc
class __$BuddyClaimValueCopyWithImpl<$Res>
    implements _$BuddyClaimValueCopyWith<$Res> {
  __$BuddyClaimValueCopyWithImpl(this._self, this._then);

  final _BuddyClaimValue _self;
  final $Res Function(_BuddyClaimValue) _then;

/// Create a copy of BuddyClaimValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metric = null,Object? operation = null,Object? value = freezed,Object? date = freezed,Object? unit = null,Object? workoutId = freezed,Object? exerciseRef = freezed,Object? muscleGroup = freezed,}) {
  return _then(_BuddyClaimValue(
metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as BuddyQueryMetric,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyQueryOp,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyClaimUnit,workoutId: freezed == workoutId ? _self.workoutId : workoutId // ignore: cast_nullable_to_non_nullable
as String?,exerciseRef: freezed == exerciseRef ? _self.exerciseRef : exerciseRef // ignore: cast_nullable_to_non_nullable
as String?,muscleGroup: freezed == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
