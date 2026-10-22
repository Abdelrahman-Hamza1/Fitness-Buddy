// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_estimate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyEstimate {

/// AI-estimated nutrient range per 100 grams; never overrides a real food match.
 BuddyRange get range; String get reason;
/// Create a copy of BuddyEstimate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyEstimateCopyWith<BuddyEstimate> get copyWith => _$BuddyEstimateCopyWithImpl<BuddyEstimate>(this as BuddyEstimate, _$identity);

  /// Serializes this BuddyEstimate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyEstimate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyEstimate&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyEstimate;
  return Object.hash(runtimeType,_this.range,_this.reason);
}

@override
String toString() {
  final _this = this as BuddyEstimate;
  return 'BuddyEstimate(range: ${_this.range}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $BuddyEstimateCopyWith<$Res>  {
  factory $BuddyEstimateCopyWith(BuddyEstimate value, $Res Function(BuddyEstimate) _then) = _$BuddyEstimateCopyWithImpl;
@useResult
$Res call({
 BuddyRange range, String reason
});


$BuddyRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$BuddyEstimateCopyWithImpl<$Res>
    implements $BuddyEstimateCopyWith<$Res> {
  _$BuddyEstimateCopyWithImpl(this._self, this._then);

  final BuddyEstimate _self;
  final $Res Function(BuddyEstimate) _then;

/// Create a copy of BuddyEstimate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? reason = null,}) {
  return _then(BuddyEstimate(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyRange,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of BuddyEstimate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRangeCopyWith<$Res> get range {
  
  return $BuddyRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyEstimate].
extension BuddyEstimatePatterns on BuddyEstimate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyEstimate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyEstimate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyEstimate value)  $default,){
final _that = this;
switch (_that) {
case _BuddyEstimate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyEstimate value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyEstimate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyRange range,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyEstimate() when $default != null:
return $default(_that.range,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyRange range,  String reason)  $default,) {final _that = this;
switch (_that) {
case _BuddyEstimate():
return $default(_that.range,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyRange range,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _BuddyEstimate() when $default != null:
return $default(_that.range,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyEstimate implements BuddyEstimate {
  const _BuddyEstimate({required this.range, required this.reason});
  factory _BuddyEstimate.fromJson(Map<String, dynamic> json) => _$BuddyEstimateFromJson(json);

/// AI-estimated nutrient range per 100 grams; never overrides a real food match.
@override final  BuddyRange range;
@override final  String reason;

/// Create a copy of BuddyEstimate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyEstimateCopyWith<_BuddyEstimate> get copyWith => __$BuddyEstimateCopyWithImpl<_BuddyEstimate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyEstimateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyEstimate&&(identical(other.range, range) || other.range == range)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,range,reason);
}

@override
String toString() {
    return 'BuddyEstimate(range: $range, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$BuddyEstimateCopyWith<$Res> implements $BuddyEstimateCopyWith<$Res> {
  factory _$BuddyEstimateCopyWith(_BuddyEstimate value, $Res Function(_BuddyEstimate) _then) = __$BuddyEstimateCopyWithImpl;
@override @useResult
$Res call({
 BuddyRange range, String reason
});


@override $BuddyRangeCopyWith<$Res> get range;

}
/// @nodoc
class __$BuddyEstimateCopyWithImpl<$Res>
    implements _$BuddyEstimateCopyWith<$Res> {
  __$BuddyEstimateCopyWithImpl(this._self, this._then);

  final _BuddyEstimate _self;
  final $Res Function(_BuddyEstimate) _then;

/// Create a copy of BuddyEstimate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? reason = null,}) {
  return _then(_BuddyEstimate(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as BuddyRange,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of BuddyEstimate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyRangeCopyWith<$Res> get range {
  
  return $BuddyRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
