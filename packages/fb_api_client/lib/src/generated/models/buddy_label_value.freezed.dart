// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_label_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyLabelValue {

 double? get value; BuddyLabelConfidence get confidence;
/// Create a copy of BuddyLabelValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyLabelValueCopyWith<BuddyLabelValue> get copyWith => _$BuddyLabelValueCopyWithImpl<BuddyLabelValue>(this as BuddyLabelValue, _$identity);

  /// Serializes this BuddyLabelValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyLabelValue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyLabelValue&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyLabelValue;
  return Object.hash(runtimeType,_this.value,_this.confidence);
}

@override
String toString() {
  final _this = this as BuddyLabelValue;
  return 'BuddyLabelValue(value: ${_this.value}, confidence: ${_this.confidence})';
}


}

/// @nodoc
abstract mixin class $BuddyLabelValueCopyWith<$Res>  {
  factory $BuddyLabelValueCopyWith(BuddyLabelValue value, $Res Function(BuddyLabelValue) _then) = _$BuddyLabelValueCopyWithImpl;
@useResult
$Res call({
 double? value, BuddyLabelConfidence confidence
});




}
/// @nodoc
class _$BuddyLabelValueCopyWithImpl<$Res>
    implements $BuddyLabelValueCopyWith<$Res> {
  _$BuddyLabelValueCopyWithImpl(this._self, this._then);

  final BuddyLabelValue _self;
  final $Res Function(BuddyLabelValue) _then;

/// Create a copy of BuddyLabelValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? confidence = null,}) {
  return _then(BuddyLabelValue(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyLabelValue].
extension BuddyLabelValuePatterns on BuddyLabelValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyLabelValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyLabelValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyLabelValue value)  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyLabelValue value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? value,  BuddyLabelConfidence confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyLabelValue() when $default != null:
return $default(_that.value,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? value,  BuddyLabelConfidence confidence)  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelValue():
return $default(_that.value,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? value,  BuddyLabelConfidence confidence)?  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelValue() when $default != null:
return $default(_that.value,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyLabelValue implements BuddyLabelValue {
  const _BuddyLabelValue({required this.value, required this.confidence});
  factory _BuddyLabelValue.fromJson(Map<String, dynamic> json) => _$BuddyLabelValueFromJson(json);

@override final  double? value;
@override final  BuddyLabelConfidence confidence;

/// Create a copy of BuddyLabelValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyLabelValueCopyWith<_BuddyLabelValue> get copyWith => __$BuddyLabelValueCopyWithImpl<_BuddyLabelValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyLabelValueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyLabelValue&&(identical(other.value, value) || other.value == value)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,confidence);
}

@override
String toString() {
    return 'BuddyLabelValue(value: $value, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$BuddyLabelValueCopyWith<$Res> implements $BuddyLabelValueCopyWith<$Res> {
  factory _$BuddyLabelValueCopyWith(_BuddyLabelValue value, $Res Function(_BuddyLabelValue) _then) = __$BuddyLabelValueCopyWithImpl;
@override @useResult
$Res call({
 double? value, BuddyLabelConfidence confidence
});




}
/// @nodoc
class __$BuddyLabelValueCopyWithImpl<$Res>
    implements _$BuddyLabelValueCopyWith<$Res> {
  __$BuddyLabelValueCopyWithImpl(this._self, this._then);

  final _BuddyLabelValue _self;
  final $Res Function(_BuddyLabelValue) _then;

/// Create a copy of BuddyLabelValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? confidence = null,}) {
  return _then(_BuddyLabelValue(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}


}

// dart format on
