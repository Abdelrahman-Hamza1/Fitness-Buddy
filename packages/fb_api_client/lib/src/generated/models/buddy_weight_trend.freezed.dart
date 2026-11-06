// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_weight_trend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyWeightTrend {

 String get from; String get to; double get startKg; double get endKg; double get changeKg; double? get weeklyChangeKg; int get weighIns;
/// Create a copy of BuddyWeightTrend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyWeightTrendCopyWith<BuddyWeightTrend> get copyWith => _$BuddyWeightTrendCopyWithImpl<BuddyWeightTrend>(this as BuddyWeightTrend, _$identity);

  /// Serializes this BuddyWeightTrend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyWeightTrend;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyWeightTrend&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.startKg, _this.startKg) || other.startKg == _this.startKg)&&(identical(other.endKg, _this.endKg) || other.endKg == _this.endKg)&&(identical(other.changeKg, _this.changeKg) || other.changeKg == _this.changeKg)&&(identical(other.weeklyChangeKg, _this.weeklyChangeKg) || other.weeklyChangeKg == _this.weeklyChangeKg)&&(identical(other.weighIns, _this.weighIns) || other.weighIns == _this.weighIns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyWeightTrend;
  return Object.hash(runtimeType,_this.from,_this.to,_this.startKg,_this.endKg,_this.changeKg,_this.weeklyChangeKg,_this.weighIns);
}

@override
String toString() {
  final _this = this as BuddyWeightTrend;
  return 'BuddyWeightTrend(from: ${_this.from}, to: ${_this.to}, startKg: ${_this.startKg}, endKg: ${_this.endKg}, changeKg: ${_this.changeKg}, weeklyChangeKg: ${_this.weeklyChangeKg}, weighIns: ${_this.weighIns})';
}


}

/// @nodoc
abstract mixin class $BuddyWeightTrendCopyWith<$Res>  {
  factory $BuddyWeightTrendCopyWith(BuddyWeightTrend value, $Res Function(BuddyWeightTrend) _then) = _$BuddyWeightTrendCopyWithImpl;
@useResult
$Res call({
 String from, String to, double startKg, double endKg, double changeKg, double? weeklyChangeKg, int weighIns
});




}
/// @nodoc
class _$BuddyWeightTrendCopyWithImpl<$Res>
    implements $BuddyWeightTrendCopyWith<$Res> {
  _$BuddyWeightTrendCopyWithImpl(this._self, this._then);

  final BuddyWeightTrend _self;
  final $Res Function(BuddyWeightTrend) _then;

/// Create a copy of BuddyWeightTrend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? startKg = null,Object? endKg = null,Object? changeKg = null,Object? weeklyChangeKg = freezed,Object? weighIns = null,}) {
  return _then(BuddyWeightTrend(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,startKg: null == startKg ? _self.startKg : startKg // ignore: cast_nullable_to_non_nullable
as double,endKg: null == endKg ? _self.endKg : endKg // ignore: cast_nullable_to_non_nullable
as double,changeKg: null == changeKg ? _self.changeKg : changeKg // ignore: cast_nullable_to_non_nullable
as double,weeklyChangeKg: freezed == weeklyChangeKg ? _self.weeklyChangeKg : weeklyChangeKg // ignore: cast_nullable_to_non_nullable
as double?,weighIns: null == weighIns ? _self.weighIns : weighIns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyWeightTrend].
extension BuddyWeightTrendPatterns on BuddyWeightTrend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyWeightTrend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyWeightTrend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyWeightTrend value)  $default,){
final _that = this;
switch (_that) {
case _BuddyWeightTrend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyWeightTrend value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyWeightTrend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String to,  double startKg,  double endKg,  double changeKg,  double? weeklyChangeKg,  int weighIns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyWeightTrend() when $default != null:
return $default(_that.from,_that.to,_that.startKg,_that.endKg,_that.changeKg,_that.weeklyChangeKg,_that.weighIns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String to,  double startKg,  double endKg,  double changeKg,  double? weeklyChangeKg,  int weighIns)  $default,) {final _that = this;
switch (_that) {
case _BuddyWeightTrend():
return $default(_that.from,_that.to,_that.startKg,_that.endKg,_that.changeKg,_that.weeklyChangeKg,_that.weighIns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String to,  double startKg,  double endKg,  double changeKg,  double? weeklyChangeKg,  int weighIns)?  $default,) {final _that = this;
switch (_that) {
case _BuddyWeightTrend() when $default != null:
return $default(_that.from,_that.to,_that.startKg,_that.endKg,_that.changeKg,_that.weeklyChangeKg,_that.weighIns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyWeightTrend implements BuddyWeightTrend {
  const _BuddyWeightTrend({required this.from, required this.to, required this.startKg, required this.endKg, required this.changeKg, required this.weeklyChangeKg, required this.weighIns});
  factory _BuddyWeightTrend.fromJson(Map<String, dynamic> json) => _$BuddyWeightTrendFromJson(json);

@override final  String from;
@override final  String to;
@override final  double startKg;
@override final  double endKg;
@override final  double changeKg;
@override final  double? weeklyChangeKg;
@override final  int weighIns;

/// Create a copy of BuddyWeightTrend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyWeightTrendCopyWith<_BuddyWeightTrend> get copyWith => __$BuddyWeightTrendCopyWithImpl<_BuddyWeightTrend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyWeightTrendToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyWeightTrend&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.startKg, startKg) || other.startKg == startKg)&&(identical(other.endKg, endKg) || other.endKg == endKg)&&(identical(other.changeKg, changeKg) || other.changeKg == changeKg)&&(identical(other.weeklyChangeKg, weeklyChangeKg) || other.weeklyChangeKg == weeklyChangeKg)&&(identical(other.weighIns, weighIns) || other.weighIns == weighIns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,to,startKg,endKg,changeKg,weeklyChangeKg,weighIns);
}

@override
String toString() {
    return 'BuddyWeightTrend(from: $from, to: $to, startKg: $startKg, endKg: $endKg, changeKg: $changeKg, weeklyChangeKg: $weeklyChangeKg, weighIns: $weighIns)';
}


}

/// @nodoc
abstract mixin class _$BuddyWeightTrendCopyWith<$Res> implements $BuddyWeightTrendCopyWith<$Res> {
  factory _$BuddyWeightTrendCopyWith(_BuddyWeightTrend value, $Res Function(_BuddyWeightTrend) _then) = __$BuddyWeightTrendCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, double startKg, double endKg, double changeKg, double? weeklyChangeKg, int weighIns
});




}
/// @nodoc
class __$BuddyWeightTrendCopyWithImpl<$Res>
    implements _$BuddyWeightTrendCopyWith<$Res> {
  __$BuddyWeightTrendCopyWithImpl(this._self, this._then);

  final _BuddyWeightTrend _self;
  final $Res Function(_BuddyWeightTrend) _then;

/// Create a copy of BuddyWeightTrend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? startKg = null,Object? endKg = null,Object? changeKg = null,Object? weeklyChangeKg = freezed,Object? weighIns = null,}) {
  return _then(_BuddyWeightTrend(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,startKg: null == startKg ? _self.startKg : startKg // ignore: cast_nullable_to_non_nullable
as double,endKg: null == endKg ? _self.endKg : endKg // ignore: cast_nullable_to_non_nullable
as double,changeKg: null == changeKg ? _self.changeKg : changeKg // ignore: cast_nullable_to_non_nullable
as double,weeklyChangeKg: freezed == weeklyChangeKg ? _self.weeklyChangeKg : weeklyChangeKg // ignore: cast_nullable_to_non_nullable
as double?,weighIns: null == weighIns ? _self.weighIns : weighIns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
