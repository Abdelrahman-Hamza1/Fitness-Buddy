// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_label_other.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyLabelOther {

 String get name; double get value; String get unit; BuddyLabelConfidence get confidence;
/// Create a copy of BuddyLabelOther
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyLabelOtherCopyWith<BuddyLabelOther> get copyWith => _$BuddyLabelOtherCopyWithImpl<BuddyLabelOther>(this as BuddyLabelOther, _$identity);

  /// Serializes this BuddyLabelOther to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyLabelOther;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyLabelOther&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyLabelOther;
  return Object.hash(runtimeType,_this.name,_this.value,_this.unit,_this.confidence);
}

@override
String toString() {
  final _this = this as BuddyLabelOther;
  return 'BuddyLabelOther(name: ${_this.name}, value: ${_this.value}, unit: ${_this.unit}, confidence: ${_this.confidence})';
}


}

/// @nodoc
abstract mixin class $BuddyLabelOtherCopyWith<$Res>  {
  factory $BuddyLabelOtherCopyWith(BuddyLabelOther value, $Res Function(BuddyLabelOther) _then) = _$BuddyLabelOtherCopyWithImpl;
@useResult
$Res call({
 String name, double value, String unit, BuddyLabelConfidence confidence
});




}
/// @nodoc
class _$BuddyLabelOtherCopyWithImpl<$Res>
    implements $BuddyLabelOtherCopyWith<$Res> {
  _$BuddyLabelOtherCopyWithImpl(this._self, this._then);

  final BuddyLabelOther _self;
  final $Res Function(BuddyLabelOther) _then;

/// Create a copy of BuddyLabelOther
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? value = null,Object? unit = null,Object? confidence = null,}) {
  return _then(BuddyLabelOther(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyLabelOther].
extension BuddyLabelOtherPatterns on BuddyLabelOther {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyLabelOther value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyLabelOther() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyLabelOther value)  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelOther():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyLabelOther value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelOther() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  double value,  String unit,  BuddyLabelConfidence confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyLabelOther() when $default != null:
return $default(_that.name,_that.value,_that.unit,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  double value,  String unit,  BuddyLabelConfidence confidence)  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelOther():
return $default(_that.name,_that.value,_that.unit,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  double value,  String unit,  BuddyLabelConfidence confidence)?  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelOther() when $default != null:
return $default(_that.name,_that.value,_that.unit,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyLabelOther implements BuddyLabelOther {
  const _BuddyLabelOther({required this.name, required this.value, required this.unit, required this.confidence});
  factory _BuddyLabelOther.fromJson(Map<String, dynamic> json) => _$BuddyLabelOtherFromJson(json);

@override final  String name;
@override final  double value;
@override final  String unit;
@override final  BuddyLabelConfidence confidence;

/// Create a copy of BuddyLabelOther
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyLabelOtherCopyWith<_BuddyLabelOther> get copyWith => __$BuddyLabelOtherCopyWithImpl<_BuddyLabelOther>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyLabelOtherToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyLabelOther&&(identical(other.name, name) || other.name == name)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,value,unit,confidence);
}

@override
String toString() {
    return 'BuddyLabelOther(name: $name, value: $value, unit: $unit, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$BuddyLabelOtherCopyWith<$Res> implements $BuddyLabelOtherCopyWith<$Res> {
  factory _$BuddyLabelOtherCopyWith(_BuddyLabelOther value, $Res Function(_BuddyLabelOther) _then) = __$BuddyLabelOtherCopyWithImpl;
@override @useResult
$Res call({
 String name, double value, String unit, BuddyLabelConfidence confidence
});




}
/// @nodoc
class __$BuddyLabelOtherCopyWithImpl<$Res>
    implements _$BuddyLabelOtherCopyWith<$Res> {
  __$BuddyLabelOtherCopyWithImpl(this._self, this._then);

  final _BuddyLabelOther _self;
  final $Res Function(_BuddyLabelOther) _then;

/// Create a copy of BuddyLabelOther
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? value = null,Object? unit = null,Object? confidence = null,}) {
  return _then(_BuddyLabelOther(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}


}

// dart format on
