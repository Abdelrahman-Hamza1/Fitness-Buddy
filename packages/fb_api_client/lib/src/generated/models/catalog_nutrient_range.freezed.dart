// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_nutrient_range.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogNutrientRange {

 CatalogNutrients get low; CatalogNutrients get high;
/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogNutrientRangeCopyWith<CatalogNutrientRange> get copyWith => _$CatalogNutrientRangeCopyWithImpl<CatalogNutrientRange>(this as CatalogNutrientRange, _$identity);

  /// Serializes this CatalogNutrientRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatalogNutrientRange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogNutrientRange&&(identical(other.low, _this.low) || other.low == _this.low)&&(identical(other.high, _this.high) || other.high == _this.high));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatalogNutrientRange;
  return Object.hash(runtimeType,_this.low,_this.high);
}

@override
String toString() {
  final _this = this as CatalogNutrientRange;
  return 'CatalogNutrientRange(low: ${_this.low}, high: ${_this.high})';
}


}

/// @nodoc
abstract mixin class $CatalogNutrientRangeCopyWith<$Res>  {
  factory $CatalogNutrientRangeCopyWith(CatalogNutrientRange value, $Res Function(CatalogNutrientRange) _then) = _$CatalogNutrientRangeCopyWithImpl;
@useResult
$Res call({
 CatalogNutrients low, CatalogNutrients high
});


$CatalogNutrientsCopyWith<$Res> get low;$CatalogNutrientsCopyWith<$Res> get high;

}
/// @nodoc
class _$CatalogNutrientRangeCopyWithImpl<$Res>
    implements $CatalogNutrientRangeCopyWith<$Res> {
  _$CatalogNutrientRangeCopyWithImpl(this._self, this._then);

  final CatalogNutrientRange _self;
  final $Res Function(CatalogNutrientRange) _then;

/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? low = null,Object? high = null,}) {
  return _then(CatalogNutrientRange(
low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as CatalogNutrients,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as CatalogNutrients,
  ));
}
/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<$Res> get low {
  
  return $CatalogNutrientsCopyWith<$Res>(_self.low, (value) {
    return _then(_self.copyWith(low: value));
  });
}/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<$Res> get high {
  
  return $CatalogNutrientsCopyWith<$Res>(_self.high, (value) {
    return _then(_self.copyWith(high: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatalogNutrientRange].
extension CatalogNutrientRangePatterns on CatalogNutrientRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogNutrientRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogNutrientRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogNutrientRange value)  $default,){
final _that = this;
switch (_that) {
case _CatalogNutrientRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogNutrientRange value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogNutrientRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogNutrients low,  CatalogNutrients high)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogNutrientRange() when $default != null:
return $default(_that.low,_that.high);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogNutrients low,  CatalogNutrients high)  $default,) {final _that = this;
switch (_that) {
case _CatalogNutrientRange():
return $default(_that.low,_that.high);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogNutrients low,  CatalogNutrients high)?  $default,) {final _that = this;
switch (_that) {
case _CatalogNutrientRange() when $default != null:
return $default(_that.low,_that.high);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogNutrientRange implements CatalogNutrientRange {
  const _CatalogNutrientRange({required this.low, required this.high});
  factory _CatalogNutrientRange.fromJson(Map<String, dynamic> json) => _$CatalogNutrientRangeFromJson(json);

@override final  CatalogNutrients low;
@override final  CatalogNutrients high;

/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogNutrientRangeCopyWith<_CatalogNutrientRange> get copyWith => __$CatalogNutrientRangeCopyWithImpl<_CatalogNutrientRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogNutrientRangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogNutrientRange&&(identical(other.low, low) || other.low == low)&&(identical(other.high, high) || other.high == high));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,low,high);
}

@override
String toString() {
    return 'CatalogNutrientRange(low: $low, high: $high)';
}


}

/// @nodoc
abstract mixin class _$CatalogNutrientRangeCopyWith<$Res> implements $CatalogNutrientRangeCopyWith<$Res> {
  factory _$CatalogNutrientRangeCopyWith(_CatalogNutrientRange value, $Res Function(_CatalogNutrientRange) _then) = __$CatalogNutrientRangeCopyWithImpl;
@override @useResult
$Res call({
 CatalogNutrients low, CatalogNutrients high
});


@override $CatalogNutrientsCopyWith<$Res> get low;@override $CatalogNutrientsCopyWith<$Res> get high;

}
/// @nodoc
class __$CatalogNutrientRangeCopyWithImpl<$Res>
    implements _$CatalogNutrientRangeCopyWith<$Res> {
  __$CatalogNutrientRangeCopyWithImpl(this._self, this._then);

  final _CatalogNutrientRange _self;
  final $Res Function(_CatalogNutrientRange) _then;

/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? low = null,Object? high = null,}) {
  return _then(_CatalogNutrientRange(
low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as CatalogNutrients,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as CatalogNutrients,
  ));
}

/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<$Res> get low {
  
  return $CatalogNutrientsCopyWith<$Res>(_self.low, (value) {
    return _then(_self.copyWith(low: value));
  });
}/// Create a copy of CatalogNutrientRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<$Res> get high {
  
  return $CatalogNutrientsCopyWith<$Res>(_self.high, (value) {
    return _then(_self.copyWith(high: value));
  });
}
}

// dart format on
