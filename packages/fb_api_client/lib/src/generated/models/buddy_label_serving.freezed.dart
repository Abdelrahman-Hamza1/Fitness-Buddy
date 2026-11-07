// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_label_serving.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyLabelServing {

 double? get amount; String? get unit; double? get g; double? get ml; String? get label; BuddyLabelConfidence get confidence;
/// Create a copy of BuddyLabelServing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyLabelServingCopyWith<BuddyLabelServing> get copyWith => _$BuddyLabelServingCopyWithImpl<BuddyLabelServing>(this as BuddyLabelServing, _$identity);

  /// Serializes this BuddyLabelServing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyLabelServing;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyLabelServing&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.g, _this.g) || other.g == _this.g)&&(identical(other.ml, _this.ml) || other.ml == _this.ml)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.confidence, _this.confidence) || other.confidence == _this.confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyLabelServing;
  return Object.hash(runtimeType,_this.amount,_this.unit,_this.g,_this.ml,_this.label,_this.confidence);
}

@override
String toString() {
  final _this = this as BuddyLabelServing;
  return 'BuddyLabelServing(amount: ${_this.amount}, unit: ${_this.unit}, g: ${_this.g}, ml: ${_this.ml}, label: ${_this.label}, confidence: ${_this.confidence})';
}


}

/// @nodoc
abstract mixin class $BuddyLabelServingCopyWith<$Res>  {
  factory $BuddyLabelServingCopyWith(BuddyLabelServing value, $Res Function(BuddyLabelServing) _then) = _$BuddyLabelServingCopyWithImpl;
@useResult
$Res call({
 double? amount, String? unit, double? g, double? ml, String? label, BuddyLabelConfidence confidence
});




}
/// @nodoc
class _$BuddyLabelServingCopyWithImpl<$Res>
    implements $BuddyLabelServingCopyWith<$Res> {
  _$BuddyLabelServingCopyWithImpl(this._self, this._then);

  final BuddyLabelServing _self;
  final $Res Function(BuddyLabelServing) _then;

/// Create a copy of BuddyLabelServing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? unit = freezed,Object? g = freezed,Object? ml = freezed,Object? label = freezed,Object? confidence = null,}) {
  return _then(BuddyLabelServing(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,g: freezed == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as double?,ml: freezed == ml ? _self.ml : ml // ignore: cast_nullable_to_non_nullable
as double?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyLabelServing].
extension BuddyLabelServingPatterns on BuddyLabelServing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyLabelServing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyLabelServing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyLabelServing value)  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelServing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyLabelServing value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyLabelServing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? amount,  String? unit,  double? g,  double? ml,  String? label,  BuddyLabelConfidence confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyLabelServing() when $default != null:
return $default(_that.amount,_that.unit,_that.g,_that.ml,_that.label,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? amount,  String? unit,  double? g,  double? ml,  String? label,  BuddyLabelConfidence confidence)  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelServing():
return $default(_that.amount,_that.unit,_that.g,_that.ml,_that.label,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? amount,  String? unit,  double? g,  double? ml,  String? label,  BuddyLabelConfidence confidence)?  $default,) {final _that = this;
switch (_that) {
case _BuddyLabelServing() when $default != null:
return $default(_that.amount,_that.unit,_that.g,_that.ml,_that.label,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyLabelServing implements BuddyLabelServing {
  const _BuddyLabelServing({required this.amount, required this.unit, required this.g, required this.ml, required this.label, required this.confidence});
  factory _BuddyLabelServing.fromJson(Map<String, dynamic> json) => _$BuddyLabelServingFromJson(json);

@override final  double? amount;
@override final  String? unit;
@override final  double? g;
@override final  double? ml;
@override final  String? label;
@override final  BuddyLabelConfidence confidence;

/// Create a copy of BuddyLabelServing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyLabelServingCopyWith<_BuddyLabelServing> get copyWith => __$BuddyLabelServingCopyWithImpl<_BuddyLabelServing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyLabelServingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyLabelServing&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.g, g) || other.g == g)&&(identical(other.ml, ml) || other.ml == ml)&&(identical(other.label, label) || other.label == label)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,amount,unit,g,ml,label,confidence);
}

@override
String toString() {
    return 'BuddyLabelServing(amount: $amount, unit: $unit, g: $g, ml: $ml, label: $label, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$BuddyLabelServingCopyWith<$Res> implements $BuddyLabelServingCopyWith<$Res> {
  factory _$BuddyLabelServingCopyWith(_BuddyLabelServing value, $Res Function(_BuddyLabelServing) _then) = __$BuddyLabelServingCopyWithImpl;
@override @useResult
$Res call({
 double? amount, String? unit, double? g, double? ml, String? label, BuddyLabelConfidence confidence
});




}
/// @nodoc
class __$BuddyLabelServingCopyWithImpl<$Res>
    implements _$BuddyLabelServingCopyWith<$Res> {
  __$BuddyLabelServingCopyWithImpl(this._self, this._then);

  final _BuddyLabelServing _self;
  final $Res Function(_BuddyLabelServing) _then;

/// Create a copy of BuddyLabelServing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? unit = freezed,Object? g = freezed,Object? ml = freezed,Object? label = freezed,Object? confidence = null,}) {
  return _then(_BuddyLabelServing(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,g: freezed == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as double?,ml: freezed == ml ? _self.ml : ml // ignore: cast_nullable_to_non_nullable
as double?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BuddyLabelConfidence,
  ));
}


}

// dart format on
