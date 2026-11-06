// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_body_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadBodyData {

/// Canonical units: kg for weight, cm or percent for measurements.
 List<BuddyBodyValue> get values; BuddyWeightTrend? get trend;
/// Create a copy of BuddyReadBodyData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadBodyDataCopyWith<BuddyReadBodyData> get copyWith => _$BuddyReadBodyDataCopyWithImpl<BuddyReadBodyData>(this as BuddyReadBodyData, _$identity);

  /// Serializes this BuddyReadBodyData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadBodyData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadBodyData&&const DeepCollectionEquality().equals(other.values, _this.values)&&(identical(other.trend, _this.trend) || other.trend == _this.trend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadBodyData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.values),_this.trend);
}

@override
String toString() {
  final _this = this as BuddyReadBodyData;
  return 'BuddyReadBodyData(values: ${_this.values}, trend: ${_this.trend})';
}


}

/// @nodoc
abstract mixin class $BuddyReadBodyDataCopyWith<$Res>  {
  factory $BuddyReadBodyDataCopyWith(BuddyReadBodyData value, $Res Function(BuddyReadBodyData) _then) = _$BuddyReadBodyDataCopyWithImpl;
@useResult
$Res call({
 List<BuddyBodyValue> values, BuddyWeightTrend? trend
});


$BuddyWeightTrendCopyWith<$Res>? get trend;

}
/// @nodoc
class _$BuddyReadBodyDataCopyWithImpl<$Res>
    implements $BuddyReadBodyDataCopyWith<$Res> {
  _$BuddyReadBodyDataCopyWithImpl(this._self, this._then);

  final BuddyReadBodyData _self;
  final $Res Function(BuddyReadBodyData) _then;

/// Create a copy of BuddyReadBodyData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? values = null,Object? trend = freezed,}) {
  return _then(BuddyReadBodyData(
values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as List<BuddyBodyValue>,trend: freezed == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as BuddyWeightTrend?,
  ));
}
/// Create a copy of BuddyReadBodyData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeightTrendCopyWith<$Res>? get trend {
    if (_self.trend == null) {
    return null;
  }

  return $BuddyWeightTrendCopyWith<$Res>(_self.trend!, (value) {
    return _then(_self.copyWith(trend: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadBodyData].
extension BuddyReadBodyDataPatterns on BuddyReadBodyData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadBodyData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadBodyData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadBodyData value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadBodyData value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyBodyValue> values,  BuddyWeightTrend? trend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadBodyData() when $default != null:
return $default(_that.values,_that.trend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyBodyValue> values,  BuddyWeightTrend? trend)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyData():
return $default(_that.values,_that.trend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyBodyValue> values,  BuddyWeightTrend? trend)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyData() when $default != null:
return $default(_that.values,_that.trend);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadBodyData implements BuddyReadBodyData {
  const _BuddyReadBodyData({required  List<BuddyBodyValue> values, required this.trend}): _values = values;
  factory _BuddyReadBodyData.fromJson(Map<String, dynamic> json) => _$BuddyReadBodyDataFromJson(json);

/// Canonical units: kg for weight, cm or percent for measurements.
 final  List<BuddyBodyValue> _values;
/// Canonical units: kg for weight, cm or percent for measurements.
@override List<BuddyBodyValue> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}

@override final  BuddyWeightTrend? trend;

/// Create a copy of BuddyReadBodyData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadBodyDataCopyWith<_BuddyReadBodyData> get copyWith => __$BuddyReadBodyDataCopyWithImpl<_BuddyReadBodyData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadBodyDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadBodyData&&const DeepCollectionEquality().equals(other.values, _values)&&(identical(other.trend, trend) || other.trend == trend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_values),trend);
}

@override
String toString() {
    return 'BuddyReadBodyData(values: $values, trend: $trend)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadBodyDataCopyWith<$Res> implements $BuddyReadBodyDataCopyWith<$Res> {
  factory _$BuddyReadBodyDataCopyWith(_BuddyReadBodyData value, $Res Function(_BuddyReadBodyData) _then) = __$BuddyReadBodyDataCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyBodyValue> values, BuddyWeightTrend? trend
});


@override $BuddyWeightTrendCopyWith<$Res>? get trend;

}
/// @nodoc
class __$BuddyReadBodyDataCopyWithImpl<$Res>
    implements _$BuddyReadBodyDataCopyWith<$Res> {
  __$BuddyReadBodyDataCopyWithImpl(this._self, this._then);

  final _BuddyReadBodyData _self;
  final $Res Function(_BuddyReadBodyData) _then;

/// Create a copy of BuddyReadBodyData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? values = null,Object? trend = freezed,}) {
  return _then(_BuddyReadBodyData(
values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<BuddyBodyValue>,trend: freezed == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as BuddyWeightTrend?,
  ));
}

/// Create a copy of BuddyReadBodyData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeightTrendCopyWith<$Res>? get trend {
    if (_self.trend == null) {
    return null;
  }

  return $BuddyWeightTrendCopyWith<$Res>(_self.trend!, (value) {
    return _then(_self.copyWith(trend: value));
  });
}
}

// dart format on
