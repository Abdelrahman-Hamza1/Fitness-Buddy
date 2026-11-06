// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_body_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyBodyValue {

 String get date;/// weight, a measurement kind, or a custom measurement name.
 String get metric; double get value; BuddyBodyUnit get unit;
/// Create a copy of BuddyBodyValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyBodyValueCopyWith<BuddyBodyValue> get copyWith => _$BuddyBodyValueCopyWithImpl<BuddyBodyValue>(this as BuddyBodyValue, _$identity);

  /// Serializes this BuddyBodyValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyBodyValue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyBodyValue&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyBodyValue;
  return Object.hash(runtimeType,_this.date,_this.metric,_this.value,_this.unit);
}

@override
String toString() {
  final _this = this as BuddyBodyValue;
  return 'BuddyBodyValue(date: ${_this.date}, metric: ${_this.metric}, value: ${_this.value}, unit: ${_this.unit})';
}


}

/// @nodoc
abstract mixin class $BuddyBodyValueCopyWith<$Res>  {
  factory $BuddyBodyValueCopyWith(BuddyBodyValue value, $Res Function(BuddyBodyValue) _then) = _$BuddyBodyValueCopyWithImpl;
@useResult
$Res call({
 String date, String metric, double value, BuddyBodyUnit unit
});




}
/// @nodoc
class _$BuddyBodyValueCopyWithImpl<$Res>
    implements $BuddyBodyValueCopyWith<$Res> {
  _$BuddyBodyValueCopyWithImpl(this._self, this._then);

  final BuddyBodyValue _self;
  final $Res Function(BuddyBodyValue) _then;

/// Create a copy of BuddyBodyValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? metric = null,Object? value = null,Object? unit = null,}) {
  return _then(BuddyBodyValue(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyBodyUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyBodyValue].
extension BuddyBodyValuePatterns on BuddyBodyValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyBodyValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyBodyValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyBodyValue value)  $default,){
final _that = this;
switch (_that) {
case _BuddyBodyValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyBodyValue value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyBodyValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String metric,  double value,  BuddyBodyUnit unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyBodyValue() when $default != null:
return $default(_that.date,_that.metric,_that.value,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String metric,  double value,  BuddyBodyUnit unit)  $default,) {final _that = this;
switch (_that) {
case _BuddyBodyValue():
return $default(_that.date,_that.metric,_that.value,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String metric,  double value,  BuddyBodyUnit unit)?  $default,) {final _that = this;
switch (_that) {
case _BuddyBodyValue() when $default != null:
return $default(_that.date,_that.metric,_that.value,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyBodyValue implements BuddyBodyValue {
  const _BuddyBodyValue({required this.date, required this.metric, required this.value, required this.unit});
  factory _BuddyBodyValue.fromJson(Map<String, dynamic> json) => _$BuddyBodyValueFromJson(json);

@override final  String date;
/// weight, a measurement kind, or a custom measurement name.
@override final  String metric;
@override final  double value;
@override final  BuddyBodyUnit unit;

/// Create a copy of BuddyBodyValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyBodyValueCopyWith<_BuddyBodyValue> get copyWith => __$BuddyBodyValueCopyWithImpl<_BuddyBodyValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyBodyValueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyBodyValue&&(identical(other.date, date) || other.date == date)&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,metric,value,unit);
}

@override
String toString() {
    return 'BuddyBodyValue(date: $date, metric: $metric, value: $value, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$BuddyBodyValueCopyWith<$Res> implements $BuddyBodyValueCopyWith<$Res> {
  factory _$BuddyBodyValueCopyWith(_BuddyBodyValue value, $Res Function(_BuddyBodyValue) _then) = __$BuddyBodyValueCopyWithImpl;
@override @useResult
$Res call({
 String date, String metric, double value, BuddyBodyUnit unit
});




}
/// @nodoc
class __$BuddyBodyValueCopyWithImpl<$Res>
    implements _$BuddyBodyValueCopyWith<$Res> {
  __$BuddyBodyValueCopyWithImpl(this._self, this._then);

  final _BuddyBodyValue _self;
  final $Res Function(_BuddyBodyValue) _then;

/// Create a copy of BuddyBodyValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? metric = null,Object? value = null,Object? unit = null,}) {
  return _then(_BuddyBodyValue(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as BuddyBodyUnit,
  ));
}


}

// dart format on
