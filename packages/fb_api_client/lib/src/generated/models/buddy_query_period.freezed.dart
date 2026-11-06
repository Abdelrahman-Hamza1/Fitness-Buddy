// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_query_period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyQueryPeriod {

 BuddyPeriodKind get kind; int? get days; BuddySinceEvent? get since; String? get from; String? get to;
/// Create a copy of BuddyQueryPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyQueryPeriodCopyWith<BuddyQueryPeriod> get copyWith => _$BuddyQueryPeriodCopyWithImpl<BuddyQueryPeriod>(this as BuddyQueryPeriod, _$identity);

  /// Serializes this BuddyQueryPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyQueryPeriod;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyQueryPeriod&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.since, _this.since) || other.since == _this.since)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyQueryPeriod;
  return Object.hash(runtimeType,_this.kind,_this.days,_this.since,_this.from,_this.to);
}

@override
String toString() {
  final _this = this as BuddyQueryPeriod;
  return 'BuddyQueryPeriod(kind: ${_this.kind}, days: ${_this.days}, since: ${_this.since}, from: ${_this.from}, to: ${_this.to})';
}


}

/// @nodoc
abstract mixin class $BuddyQueryPeriodCopyWith<$Res>  {
  factory $BuddyQueryPeriodCopyWith(BuddyQueryPeriod value, $Res Function(BuddyQueryPeriod) _then) = _$BuddyQueryPeriodCopyWithImpl;
@useResult
$Res call({
 BuddyPeriodKind kind, int? days, BuddySinceEvent? since, String? from, String? to
});




}
/// @nodoc
class _$BuddyQueryPeriodCopyWithImpl<$Res>
    implements $BuddyQueryPeriodCopyWith<$Res> {
  _$BuddyQueryPeriodCopyWithImpl(this._self, this._then);

  final BuddyQueryPeriod _self;
  final $Res Function(BuddyQueryPeriod) _then;

/// Create a copy of BuddyQueryPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? days = freezed,Object? since = freezed,Object? from = freezed,Object? to = freezed,}) {
  return _then(BuddyQueryPeriod(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPeriodKind,days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as BuddySinceEvent?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyQueryPeriod].
extension BuddyQueryPeriodPatterns on BuddyQueryPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyQueryPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyQueryPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyQueryPeriod value)  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyQueryPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyQueryPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyPeriodKind kind,  int? days,  BuddySinceEvent? since,  String? from,  String? to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyQueryPeriod() when $default != null:
return $default(_that.kind,_that.days,_that.since,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyPeriodKind kind,  int? days,  BuddySinceEvent? since,  String? from,  String? to)  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryPeriod():
return $default(_that.kind,_that.days,_that.since,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyPeriodKind kind,  int? days,  BuddySinceEvent? since,  String? from,  String? to)?  $default,) {final _that = this;
switch (_that) {
case _BuddyQueryPeriod() when $default != null:
return $default(_that.kind,_that.days,_that.since,_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyQueryPeriod implements BuddyQueryPeriod {
  const _BuddyQueryPeriod({required this.kind, required this.days, required this.since, required this.from, required this.to});
  factory _BuddyQueryPeriod.fromJson(Map<String, dynamic> json) => _$BuddyQueryPeriodFromJson(json);

@override final  BuddyPeriodKind kind;
@override final  int? days;
@override final  BuddySinceEvent? since;
@override final  String? from;
@override final  String? to;

/// Create a copy of BuddyQueryPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyQueryPeriodCopyWith<_BuddyQueryPeriod> get copyWith => __$BuddyQueryPeriodCopyWithImpl<_BuddyQueryPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyQueryPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyQueryPeriod&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.days, days) || other.days == days)&&(identical(other.since, since) || other.since == since)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,days,since,from,to);
}

@override
String toString() {
    return 'BuddyQueryPeriod(kind: $kind, days: $days, since: $since, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$BuddyQueryPeriodCopyWith<$Res> implements $BuddyQueryPeriodCopyWith<$Res> {
  factory _$BuddyQueryPeriodCopyWith(_BuddyQueryPeriod value, $Res Function(_BuddyQueryPeriod) _then) = __$BuddyQueryPeriodCopyWithImpl;
@override @useResult
$Res call({
 BuddyPeriodKind kind, int? days, BuddySinceEvent? since, String? from, String? to
});




}
/// @nodoc
class __$BuddyQueryPeriodCopyWithImpl<$Res>
    implements _$BuddyQueryPeriodCopyWith<$Res> {
  __$BuddyQueryPeriodCopyWithImpl(this._self, this._then);

  final _BuddyQueryPeriod _self;
  final $Res Function(_BuddyQueryPeriod) _then;

/// Create a copy of BuddyQueryPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? days = freezed,Object? since = freezed,Object? from = freezed,Object? to = freezed,}) {
  return _then(_BuddyQueryPeriod(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPeriodKind,days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,since: freezed == since ? _self.since : since // ignore: cast_nullable_to_non_nullable
as BuddySinceEvent?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
