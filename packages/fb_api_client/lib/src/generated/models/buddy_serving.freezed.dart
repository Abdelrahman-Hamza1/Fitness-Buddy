// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_serving.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyServing {

 String get unitCode; double? get g; double? get ml; double? get rangeLo; double? get rangeHi; String get source;
/// Create a copy of BuddyServing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyServingCopyWith<BuddyServing> get copyWith => _$BuddyServingCopyWithImpl<BuddyServing>(this as BuddyServing, _$identity);

  /// Serializes this BuddyServing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyServing;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyServing&&(identical(other.unitCode, _this.unitCode) || other.unitCode == _this.unitCode)&&(identical(other.g, _this.g) || other.g == _this.g)&&(identical(other.ml, _this.ml) || other.ml == _this.ml)&&(identical(other.rangeLo, _this.rangeLo) || other.rangeLo == _this.rangeLo)&&(identical(other.rangeHi, _this.rangeHi) || other.rangeHi == _this.rangeHi)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyServing;
  return Object.hash(runtimeType,_this.unitCode,_this.g,_this.ml,_this.rangeLo,_this.rangeHi,_this.source);
}

@override
String toString() {
  final _this = this as BuddyServing;
  return 'BuddyServing(unitCode: ${_this.unitCode}, g: ${_this.g}, ml: ${_this.ml}, rangeLo: ${_this.rangeLo}, rangeHi: ${_this.rangeHi}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $BuddyServingCopyWith<$Res>  {
  factory $BuddyServingCopyWith(BuddyServing value, $Res Function(BuddyServing) _then) = _$BuddyServingCopyWithImpl;
@useResult
$Res call({
 String unitCode, double? g, double? ml, double? rangeLo, double? rangeHi, String source
});




}
/// @nodoc
class _$BuddyServingCopyWithImpl<$Res>
    implements $BuddyServingCopyWith<$Res> {
  _$BuddyServingCopyWithImpl(this._self, this._then);

  final BuddyServing _self;
  final $Res Function(BuddyServing) _then;

/// Create a copy of BuddyServing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unitCode = null,Object? g = freezed,Object? ml = freezed,Object? rangeLo = freezed,Object? rangeHi = freezed,Object? source = null,}) {
  return _then(BuddyServing(
unitCode: null == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String,g: freezed == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as double?,ml: freezed == ml ? _self.ml : ml // ignore: cast_nullable_to_non_nullable
as double?,rangeLo: freezed == rangeLo ? _self.rangeLo : rangeLo // ignore: cast_nullable_to_non_nullable
as double?,rangeHi: freezed == rangeHi ? _self.rangeHi : rangeHi // ignore: cast_nullable_to_non_nullable
as double?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyServing].
extension BuddyServingPatterns on BuddyServing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyServing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyServing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyServing value)  $default,){
final _that = this;
switch (_that) {
case _BuddyServing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyServing value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyServing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String unitCode,  double? g,  double? ml,  double? rangeLo,  double? rangeHi,  String source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyServing() when $default != null:
return $default(_that.unitCode,_that.g,_that.ml,_that.rangeLo,_that.rangeHi,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String unitCode,  double? g,  double? ml,  double? rangeLo,  double? rangeHi,  String source)  $default,) {final _that = this;
switch (_that) {
case _BuddyServing():
return $default(_that.unitCode,_that.g,_that.ml,_that.rangeLo,_that.rangeHi,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String unitCode,  double? g,  double? ml,  double? rangeLo,  double? rangeHi,  String source)?  $default,) {final _that = this;
switch (_that) {
case _BuddyServing() when $default != null:
return $default(_that.unitCode,_that.g,_that.ml,_that.rangeLo,_that.rangeHi,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyServing implements BuddyServing {
  const _BuddyServing({required this.unitCode, required this.g, required this.ml, required this.rangeLo, required this.rangeHi, required this.source});
  factory _BuddyServing.fromJson(Map<String, dynamic> json) => _$BuddyServingFromJson(json);

@override final  String unitCode;
@override final  double? g;
@override final  double? ml;
@override final  double? rangeLo;
@override final  double? rangeHi;
@override final  String source;

/// Create a copy of BuddyServing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyServingCopyWith<_BuddyServing> get copyWith => __$BuddyServingCopyWithImpl<_BuddyServing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyServingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyServing&&(identical(other.unitCode, unitCode) || other.unitCode == unitCode)&&(identical(other.g, g) || other.g == g)&&(identical(other.ml, ml) || other.ml == ml)&&(identical(other.rangeLo, rangeLo) || other.rangeLo == rangeLo)&&(identical(other.rangeHi, rangeHi) || other.rangeHi == rangeHi)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,unitCode,g,ml,rangeLo,rangeHi,source);
}

@override
String toString() {
    return 'BuddyServing(unitCode: $unitCode, g: $g, ml: $ml, rangeLo: $rangeLo, rangeHi: $rangeHi, source: $source)';
}


}

/// @nodoc
abstract mixin class _$BuddyServingCopyWith<$Res> implements $BuddyServingCopyWith<$Res> {
  factory _$BuddyServingCopyWith(_BuddyServing value, $Res Function(_BuddyServing) _then) = __$BuddyServingCopyWithImpl;
@override @useResult
$Res call({
 String unitCode, double? g, double? ml, double? rangeLo, double? rangeHi, String source
});




}
/// @nodoc
class __$BuddyServingCopyWithImpl<$Res>
    implements _$BuddyServingCopyWith<$Res> {
  __$BuddyServingCopyWithImpl(this._self, this._then);

  final _BuddyServing _self;
  final $Res Function(_BuddyServing) _then;

/// Create a copy of BuddyServing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unitCode = null,Object? g = freezed,Object? ml = freezed,Object? rangeLo = freezed,Object? rangeHi = freezed,Object? source = null,}) {
  return _then(_BuddyServing(
unitCode: null == unitCode ? _self.unitCode : unitCode // ignore: cast_nullable_to_non_nullable
as String,g: freezed == g ? _self.g : g // ignore: cast_nullable_to_non_nullable
as double?,ml: freezed == ml ? _self.ml : ml // ignore: cast_nullable_to_non_nullable
as double?,rangeLo: freezed == rangeLo ? _self.rangeLo : rangeLo // ignore: cast_nullable_to_non_nullable
as double?,rangeHi: freezed == rangeHi ? _self.rangeHi : rangeHi // ignore: cast_nullable_to_non_nullable
as double?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
