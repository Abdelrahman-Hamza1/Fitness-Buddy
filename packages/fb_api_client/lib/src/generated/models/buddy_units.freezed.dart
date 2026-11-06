// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_units.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyUnits {

 BuddyMassUnit get mass; BuddyLengthUnit get length; BuddyEnergyUnit get energy;
/// Create a copy of BuddyUnits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyUnitsCopyWith<BuddyUnits> get copyWith => _$BuddyUnitsCopyWithImpl<BuddyUnits>(this as BuddyUnits, _$identity);

  /// Serializes this BuddyUnits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyUnits;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyUnits&&(identical(other.mass, _this.mass) || other.mass == _this.mass)&&(identical(other.length, _this.length) || other.length == _this.length)&&(identical(other.energy, _this.energy) || other.energy == _this.energy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyUnits;
  return Object.hash(runtimeType,_this.mass,_this.length,_this.energy);
}

@override
String toString() {
  final _this = this as BuddyUnits;
  return 'BuddyUnits(mass: ${_this.mass}, length: ${_this.length}, energy: ${_this.energy})';
}


}

/// @nodoc
abstract mixin class $BuddyUnitsCopyWith<$Res>  {
  factory $BuddyUnitsCopyWith(BuddyUnits value, $Res Function(BuddyUnits) _then) = _$BuddyUnitsCopyWithImpl;
@useResult
$Res call({
 BuddyMassUnit mass, BuddyLengthUnit length, BuddyEnergyUnit energy
});




}
/// @nodoc
class _$BuddyUnitsCopyWithImpl<$Res>
    implements $BuddyUnitsCopyWith<$Res> {
  _$BuddyUnitsCopyWithImpl(this._self, this._then);

  final BuddyUnits _self;
  final $Res Function(BuddyUnits) _then;

/// Create a copy of BuddyUnits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mass = null,Object? length = null,Object? energy = null,}) {
  return _then(BuddyUnits(
mass: null == mass ? _self.mass : mass // ignore: cast_nullable_to_non_nullable
as BuddyMassUnit,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as BuddyLengthUnit,energy: null == energy ? _self.energy : energy // ignore: cast_nullable_to_non_nullable
as BuddyEnergyUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyUnits].
extension BuddyUnitsPatterns on BuddyUnits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyUnits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyUnits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyUnits value)  $default,){
final _that = this;
switch (_that) {
case _BuddyUnits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyUnits value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyUnits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyMassUnit mass,  BuddyLengthUnit length,  BuddyEnergyUnit energy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyUnits() when $default != null:
return $default(_that.mass,_that.length,_that.energy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyMassUnit mass,  BuddyLengthUnit length,  BuddyEnergyUnit energy)  $default,) {final _that = this;
switch (_that) {
case _BuddyUnits():
return $default(_that.mass,_that.length,_that.energy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyMassUnit mass,  BuddyLengthUnit length,  BuddyEnergyUnit energy)?  $default,) {final _that = this;
switch (_that) {
case _BuddyUnits() when $default != null:
return $default(_that.mass,_that.length,_that.energy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyUnits implements BuddyUnits {
  const _BuddyUnits({required this.mass, required this.length, required this.energy});
  factory _BuddyUnits.fromJson(Map<String, dynamic> json) => _$BuddyUnitsFromJson(json);

@override final  BuddyMassUnit mass;
@override final  BuddyLengthUnit length;
@override final  BuddyEnergyUnit energy;

/// Create a copy of BuddyUnits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyUnitsCopyWith<_BuddyUnits> get copyWith => __$BuddyUnitsCopyWithImpl<_BuddyUnits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyUnitsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyUnits&&(identical(other.mass, mass) || other.mass == mass)&&(identical(other.length, length) || other.length == length)&&(identical(other.energy, energy) || other.energy == energy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mass,length,energy);
}

@override
String toString() {
    return 'BuddyUnits(mass: $mass, length: $length, energy: $energy)';
}


}

/// @nodoc
abstract mixin class _$BuddyUnitsCopyWith<$Res> implements $BuddyUnitsCopyWith<$Res> {
  factory _$BuddyUnitsCopyWith(_BuddyUnits value, $Res Function(_BuddyUnits) _then) = __$BuddyUnitsCopyWithImpl;
@override @useResult
$Res call({
 BuddyMassUnit mass, BuddyLengthUnit length, BuddyEnergyUnit energy
});




}
/// @nodoc
class __$BuddyUnitsCopyWithImpl<$Res>
    implements _$BuddyUnitsCopyWith<$Res> {
  __$BuddyUnitsCopyWithImpl(this._self, this._then);

  final _BuddyUnits _self;
  final $Res Function(_BuddyUnits) _then;

/// Create a copy of BuddyUnits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mass = null,Object? length = null,Object? energy = null,}) {
  return _then(_BuddyUnits(
mass: null == mass ? _self.mass : mass // ignore: cast_nullable_to_non_nullable
as BuddyMassUnit,length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as BuddyLengthUnit,energy: null == energy ? _self.energy : energy // ignore: cast_nullable_to_non_nullable
as BuddyEnergyUnit,
  ));
}


}

// dart format on
