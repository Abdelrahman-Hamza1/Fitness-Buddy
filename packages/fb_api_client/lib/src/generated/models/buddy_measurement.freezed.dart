// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_measurement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyMeasurement {

 BuddyMeasurementKind get kind; String get language; String get script; BuddyBodyMeasurementKind get measurementKind; String? get customTypeId; double get value; BuddyMeasurementUnit get unit; String? get timeHint; String? get dateHint;
/// Create a copy of BuddyMeasurement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyMeasurementCopyWith<BuddyMeasurement> get copyWith => _$BuddyMeasurementCopyWithImpl<BuddyMeasurement>(this as BuddyMeasurement, _$identity);

  /// Serializes this BuddyMeasurement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyMeasurement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyMeasurement&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.language, _this.language) || other.language == _this.language)&&(identical(other.script, _this.script) || other.script == _this.script)&&(identical(other.measurementKind, _this.measurementKind) || other.measurementKind == _this.measurementKind)&&(identical(other.customTypeId, _this.customTypeId) || other.customTypeId == _this.customTypeId)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.timeHint, _this.timeHint) || other.timeHint == _this.timeHint)&&(identical(other.dateHint, _this.dateHint) || other.dateHint == _this.dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyMeasurement;
  return Object.hash(runtimeType,_this.kind,_this.language,_this.script,_this.measurementKind,_this.customTypeId,_this.value,_this.unit,_this.timeHint,_this.dateHint);
}

@override
String toString() {
  final _this = this as BuddyMeasurement;
  return 'BuddyMeasurement(kind: ${_this.kind}, language: ${_this.language}, script: ${_this.script}, measurementKind: ${_this.measurementKind}, customTypeId: ${_this.customTypeId}, value: ${_this.value}, unit: ${_this.unit}, timeHint: ${_this.timeHint}, dateHint: ${_this.dateHint})';
}


}

/// @nodoc
abstract mixin class $BuddyMeasurementCopyWith<$Res>  {
  factory $BuddyMeasurementCopyWith(BuddyMeasurement value, $Res Function(BuddyMeasurement) _then) = _$BuddyMeasurementCopyWithImpl;
@useResult
$Res call({
 BuddyMeasurementKind kind, String language, String script, BuddyBodyMeasurementKind measurementKind, String? customTypeId, double value, BuddyMeasurementUnit unit, String? timeHint, String? dateHint
});




}
/// @nodoc
class _$BuddyMeasurementCopyWithImpl<$Res>
    implements $BuddyMeasurementCopyWith<$Res> {
  _$BuddyMeasurementCopyWithImpl(this._self, this._then);

  final BuddyMeasurement _self;
  final $Res Function(BuddyMeasurement) _then;

/// Create a copy of BuddyMeasurement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? measurementKind = null,Object? customTypeId = freezed,Object? value = null,Object? unit = null,Object? timeHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyMeasurement(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMeasurementKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,measurementKind: null == measurementKind ? _self.measurementKind : measurementKind // ignore: cast_nullable_to_non_nullable
as BuddyBodyMeasurementKind,customTypeId: freezed == customTypeId ? _self.customTypeId : customTypeId // ignore: cast_nullable_to_non_nullable
as String?,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyMeasurementUnit,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyMeasurement].
extension BuddyMeasurementPatterns on BuddyMeasurement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyMeasurement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyMeasurement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyMeasurement value)  $default,){
final _that = this;
switch (_that) {
case _BuddyMeasurement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyMeasurement value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyMeasurement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyMeasurementKind kind,  String language,  String script,  BuddyBodyMeasurementKind measurementKind,  String? customTypeId,  double value,  BuddyMeasurementUnit unit,  String? timeHint,  String? dateHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyMeasurement() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.measurementKind,_that.customTypeId,_that.value,_that.unit,_that.timeHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyMeasurementKind kind,  String language,  String script,  BuddyBodyMeasurementKind measurementKind,  String? customTypeId,  double value,  BuddyMeasurementUnit unit,  String? timeHint,  String? dateHint)  $default,) {final _that = this;
switch (_that) {
case _BuddyMeasurement():
return $default(_that.kind,_that.language,_that.script,_that.measurementKind,_that.customTypeId,_that.value,_that.unit,_that.timeHint,_that.dateHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyMeasurementKind kind,  String language,  String script,  BuddyBodyMeasurementKind measurementKind,  String? customTypeId,  double value,  BuddyMeasurementUnit unit,  String? timeHint,  String? dateHint)?  $default,) {final _that = this;
switch (_that) {
case _BuddyMeasurement() when $default != null:
return $default(_that.kind,_that.language,_that.script,_that.measurementKind,_that.customTypeId,_that.value,_that.unit,_that.timeHint,_that.dateHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyMeasurement implements BuddyMeasurement {
  const _BuddyMeasurement({required this.kind, required this.language, required this.script, required this.measurementKind, required this.customTypeId, required this.value, required this.unit, required this.timeHint, required this.dateHint});
  factory _BuddyMeasurement.fromJson(Map<String, dynamic> json) => _$BuddyMeasurementFromJson(json);

@override final  BuddyMeasurementKind kind;
@override final  String language;
@override final  String script;
@override final  BuddyBodyMeasurementKind measurementKind;
@override final  String? customTypeId;
@override final  double value;
@override final  BuddyMeasurementUnit unit;
@override final  String? timeHint;
@override final  String? dateHint;

/// Create a copy of BuddyMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyMeasurementCopyWith<_BuddyMeasurement> get copyWith => __$BuddyMeasurementCopyWithImpl<_BuddyMeasurement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyMeasurementToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyMeasurement&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.measurementKind, measurementKind) || other.measurementKind == measurementKind)&&(identical(other.customTypeId, customTypeId) || other.customTypeId == customTypeId)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,measurementKind,customTypeId,value,unit,timeHint,dateHint);
}

@override
String toString() {
    return 'BuddyMeasurement(kind: $kind, language: $language, script: $script, measurementKind: $measurementKind, customTypeId: $customTypeId, value: $value, unit: $unit, timeHint: $timeHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class _$BuddyMeasurementCopyWith<$Res> implements $BuddyMeasurementCopyWith<$Res> {
  factory _$BuddyMeasurementCopyWith(_BuddyMeasurement value, $Res Function(_BuddyMeasurement) _then) = __$BuddyMeasurementCopyWithImpl;
@override @useResult
$Res call({
 BuddyMeasurementKind kind, String language, String script, BuddyBodyMeasurementKind measurementKind, String? customTypeId, double value, BuddyMeasurementUnit unit, String? timeHint, String? dateHint
});




}
/// @nodoc
class __$BuddyMeasurementCopyWithImpl<$Res>
    implements _$BuddyMeasurementCopyWith<$Res> {
  __$BuddyMeasurementCopyWithImpl(this._self, this._then);

  final _BuddyMeasurement _self;
  final $Res Function(_BuddyMeasurement) _then;

/// Create a copy of BuddyMeasurement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? measurementKind = null,Object? customTypeId = freezed,Object? value = null,Object? unit = null,Object? timeHint = freezed,Object? dateHint = freezed,}) {
  return _then(_BuddyMeasurement(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMeasurementKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,measurementKind: null == measurementKind ? _self.measurementKind : measurementKind // ignore: cast_nullable_to_non_nullable
as BuddyBodyMeasurementKind,customTypeId: freezed == customTypeId ? _self.customTypeId : customTypeId // ignore: cast_nullable_to_non_nullable
as String?,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyMeasurementUnit,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
