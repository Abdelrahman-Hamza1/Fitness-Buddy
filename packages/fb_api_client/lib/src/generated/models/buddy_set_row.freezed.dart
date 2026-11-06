// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_set_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySetRow {

 int? get reps; double? get kg; int? get durationSeconds; double? get distanceMeters;
/// Create a copy of BuddySetRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySetRowCopyWith<BuddySetRow> get copyWith => _$BuddySetRowCopyWithImpl<BuddySetRow>(this as BuddySetRow, _$identity);

  /// Serializes this BuddySetRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySetRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySetRow&&(identical(other.reps, _this.reps) || other.reps == _this.reps)&&(identical(other.kg, _this.kg) || other.kg == _this.kg)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds)&&(identical(other.distanceMeters, _this.distanceMeters) || other.distanceMeters == _this.distanceMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySetRow;
  return Object.hash(runtimeType,_this.reps,_this.kg,_this.durationSeconds,_this.distanceMeters);
}

@override
String toString() {
  final _this = this as BuddySetRow;
  return 'BuddySetRow(reps: ${_this.reps}, kg: ${_this.kg}, durationSeconds: ${_this.durationSeconds}, distanceMeters: ${_this.distanceMeters})';
}


}

/// @nodoc
abstract mixin class $BuddySetRowCopyWith<$Res>  {
  factory $BuddySetRowCopyWith(BuddySetRow value, $Res Function(BuddySetRow) _then) = _$BuddySetRowCopyWithImpl;
@useResult
$Res call({
 int? reps, double? kg, int? durationSeconds, double? distanceMeters
});




}
/// @nodoc
class _$BuddySetRowCopyWithImpl<$Res>
    implements $BuddySetRowCopyWith<$Res> {
  _$BuddySetRowCopyWithImpl(this._self, this._then);

  final BuddySetRow _self;
  final $Res Function(BuddySetRow) _then;

/// Create a copy of BuddySetRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reps = freezed,Object? kg = freezed,Object? durationSeconds = freezed,Object? distanceMeters = freezed,}) {
  return _then(BuddySetRow(
reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,kg: freezed == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddySetRow].
extension BuddySetRowPatterns on BuddySetRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySetRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySetRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySetRow value)  $default,){
final _that = this;
switch (_that) {
case _BuddySetRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySetRow value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySetRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? reps,  double? kg,  int? durationSeconds,  double? distanceMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySetRow() when $default != null:
return $default(_that.reps,_that.kg,_that.durationSeconds,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? reps,  double? kg,  int? durationSeconds,  double? distanceMeters)  $default,) {final _that = this;
switch (_that) {
case _BuddySetRow():
return $default(_that.reps,_that.kg,_that.durationSeconds,_that.distanceMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? reps,  double? kg,  int? durationSeconds,  double? distanceMeters)?  $default,) {final _that = this;
switch (_that) {
case _BuddySetRow() when $default != null:
return $default(_that.reps,_that.kg,_that.durationSeconds,_that.distanceMeters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySetRow implements BuddySetRow {
  const _BuddySetRow({required this.reps, required this.kg, required this.durationSeconds, required this.distanceMeters});
  factory _BuddySetRow.fromJson(Map<String, dynamic> json) => _$BuddySetRowFromJson(json);

@override final  int? reps;
@override final  double? kg;
@override final  int? durationSeconds;
@override final  double? distanceMeters;

/// Create a copy of BuddySetRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySetRowCopyWith<_BuddySetRow> get copyWith => __$BuddySetRowCopyWithImpl<_BuddySetRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySetRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySetRow&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.kg, kg) || other.kg == kg)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reps,kg,durationSeconds,distanceMeters);
}

@override
String toString() {
    return 'BuddySetRow(reps: $reps, kg: $kg, durationSeconds: $durationSeconds, distanceMeters: $distanceMeters)';
}


}

/// @nodoc
abstract mixin class _$BuddySetRowCopyWith<$Res> implements $BuddySetRowCopyWith<$Res> {
  factory _$BuddySetRowCopyWith(_BuddySetRow value, $Res Function(_BuddySetRow) _then) = __$BuddySetRowCopyWithImpl;
@override @useResult
$Res call({
 int? reps, double? kg, int? durationSeconds, double? distanceMeters
});




}
/// @nodoc
class __$BuddySetRowCopyWithImpl<$Res>
    implements _$BuddySetRowCopyWith<$Res> {
  __$BuddySetRowCopyWithImpl(this._self, this._then);

  final _BuddySetRow _self;
  final $Res Function(_BuddySetRow) _then;

/// Create a copy of BuddySetRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reps = freezed,Object? kg = freezed,Object? durationSeconds = freezed,Object? distanceMeters = freezed,}) {
  return _then(_BuddySetRow(
reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,kg: freezed == kg ? _self.kg : kg // ignore: cast_nullable_to_non_nullable
as double?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
