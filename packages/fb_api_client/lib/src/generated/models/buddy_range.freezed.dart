// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_range.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyRange {

 BuddyNutrients get low; BuddyNutrients get high;
/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyRangeCopyWith<BuddyRange> get copyWith => _$BuddyRangeCopyWithImpl<BuddyRange>(this as BuddyRange, _$identity);

  /// Serializes this BuddyRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyRange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyRange&&(identical(other.low, _this.low) || other.low == _this.low)&&(identical(other.high, _this.high) || other.high == _this.high));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyRange;
  return Object.hash(runtimeType,_this.low,_this.high);
}

@override
String toString() {
  final _this = this as BuddyRange;
  return 'BuddyRange(low: ${_this.low}, high: ${_this.high})';
}


}

/// @nodoc
abstract mixin class $BuddyRangeCopyWith<$Res>  {
  factory $BuddyRangeCopyWith(BuddyRange value, $Res Function(BuddyRange) _then) = _$BuddyRangeCopyWithImpl;
@useResult
$Res call({
 BuddyNutrients low, BuddyNutrients high
});


$BuddyNutrientsCopyWith<$Res> get low;$BuddyNutrientsCopyWith<$Res> get high;

}
/// @nodoc
class _$BuddyRangeCopyWithImpl<$Res>
    implements $BuddyRangeCopyWith<$Res> {
  _$BuddyRangeCopyWithImpl(this._self, this._then);

  final BuddyRange _self;
  final $Res Function(BuddyRange) _then;

/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? low = null,Object? high = null,}) {
  return _then(BuddyRange(
low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,
  ));
}
/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get low {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.low, (value) {
    return _then(_self.copyWith(low: value));
  });
}/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get high {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.high, (value) {
    return _then(_self.copyWith(high: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyRange].
extension BuddyRangePatterns on BuddyRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyRange value)  $default,){
final _that = this;
switch (_that) {
case _BuddyRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyRange value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyNutrients low,  BuddyNutrients high)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyRange() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyNutrients low,  BuddyNutrients high)  $default,) {final _that = this;
switch (_that) {
case _BuddyRange():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyNutrients low,  BuddyNutrients high)?  $default,) {final _that = this;
switch (_that) {
case _BuddyRange() when $default != null:
return $default(_that.low,_that.high);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyRange implements BuddyRange {
  const _BuddyRange({required this.low, required this.high});
  factory _BuddyRange.fromJson(Map<String, dynamic> json) => _$BuddyRangeFromJson(json);

@override final  BuddyNutrients low;
@override final  BuddyNutrients high;

/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyRangeCopyWith<_BuddyRange> get copyWith => __$BuddyRangeCopyWithImpl<_BuddyRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyRangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyRange&&(identical(other.low, low) || other.low == low)&&(identical(other.high, high) || other.high == high));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,low,high);
}

@override
String toString() {
    return 'BuddyRange(low: $low, high: $high)';
}


}

/// @nodoc
abstract mixin class _$BuddyRangeCopyWith<$Res> implements $BuddyRangeCopyWith<$Res> {
  factory _$BuddyRangeCopyWith(_BuddyRange value, $Res Function(_BuddyRange) _then) = __$BuddyRangeCopyWithImpl;
@override @useResult
$Res call({
 BuddyNutrients low, BuddyNutrients high
});


@override $BuddyNutrientsCopyWith<$Res> get low;@override $BuddyNutrientsCopyWith<$Res> get high;

}
/// @nodoc
class __$BuddyRangeCopyWithImpl<$Res>
    implements _$BuddyRangeCopyWith<$Res> {
  __$BuddyRangeCopyWithImpl(this._self, this._then);

  final _BuddyRange _self;
  final $Res Function(_BuddyRange) _then;

/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? low = null,Object? high = null,}) {
  return _then(_BuddyRange(
low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as BuddyNutrients,
  ));
}

/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get low {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.low, (value) {
    return _then(_self.copyWith(low: value));
  });
}/// Create a copy of BuddyRange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<$Res> get high {
  
  return $BuddyNutrientsCopyWith<$Res>(_self.high, (value) {
    return _then(_self.copyWith(high: value));
  });
}
}

// dart format on
