// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_date_range.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDateRange {

 String get from; String get to;
/// Create a copy of BuddyDateRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDateRangeCopyWith<BuddyDateRange> get copyWith => _$BuddyDateRangeCopyWithImpl<BuddyDateRange>(this as BuddyDateRange, _$identity);

  /// Serializes this BuddyDateRange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDateRange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDateRange&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDateRange;
  return Object.hash(runtimeType,_this.from,_this.to);
}

@override
String toString() {
  final _this = this as BuddyDateRange;
  return 'BuddyDateRange(from: ${_this.from}, to: ${_this.to})';
}


}

/// @nodoc
abstract mixin class $BuddyDateRangeCopyWith<$Res>  {
  factory $BuddyDateRangeCopyWith(BuddyDateRange value, $Res Function(BuddyDateRange) _then) = _$BuddyDateRangeCopyWithImpl;
@useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class _$BuddyDateRangeCopyWithImpl<$Res>
    implements $BuddyDateRangeCopyWith<$Res> {
  _$BuddyDateRangeCopyWithImpl(this._self, this._then);

  final BuddyDateRange _self;
  final $Res Function(BuddyDateRange) _then;

/// Create a copy of BuddyDateRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,}) {
  return _then(BuddyDateRange(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyDateRange].
extension BuddyDateRangePatterns on BuddyDateRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDateRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDateRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDateRange value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDateRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDateRange value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDateRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDateRange() when $default != null:
return $default(_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String to)  $default,) {final _that = this;
switch (_that) {
case _BuddyDateRange():
return $default(_that.from,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String to)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDateRange() when $default != null:
return $default(_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDateRange implements BuddyDateRange {
  const _BuddyDateRange({required this.from, required this.to});
  factory _BuddyDateRange.fromJson(Map<String, dynamic> json) => _$BuddyDateRangeFromJson(json);

@override final  String from;
@override final  String to;

/// Create a copy of BuddyDateRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDateRangeCopyWith<_BuddyDateRange> get copyWith => __$BuddyDateRangeCopyWithImpl<_BuddyDateRange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDateRangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDateRange&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,to);
}

@override
String toString() {
    return 'BuddyDateRange(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$BuddyDateRangeCopyWith<$Res> implements $BuddyDateRangeCopyWith<$Res> {
  factory _$BuddyDateRangeCopyWith(_BuddyDateRange value, $Res Function(_BuddyDateRange) _then) = __$BuddyDateRangeCopyWithImpl;
@override @useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class __$BuddyDateRangeCopyWithImpl<$Res>
    implements _$BuddyDateRangeCopyWith<$Res> {
  __$BuddyDateRangeCopyWithImpl(this._self, this._then);

  final _BuddyDateRange _self;
  final $Res Function(_BuddyDateRange) _then;

/// Create a copy of BuddyDateRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(_BuddyDateRange(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
