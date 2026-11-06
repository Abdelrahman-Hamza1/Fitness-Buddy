// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_day_totals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDayTotals {

 double get kcal; double get proteinG; double get carbsG; double get fatG; double get fiberG; BuddyDayTargets? get targets;
/// Create a copy of BuddyDayTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDayTotalsCopyWith<BuddyDayTotals> get copyWith => _$BuddyDayTotalsCopyWithImpl<BuddyDayTotals>(this as BuddyDayTotals, _$identity);

  /// Serializes this BuddyDayTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDayTotals;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDayTotals&&(identical(other.kcal, _this.kcal) || other.kcal == _this.kcal)&&(identical(other.proteinG, _this.proteinG) || other.proteinG == _this.proteinG)&&(identical(other.carbsG, _this.carbsG) || other.carbsG == _this.carbsG)&&(identical(other.fatG, _this.fatG) || other.fatG == _this.fatG)&&(identical(other.fiberG, _this.fiberG) || other.fiberG == _this.fiberG)&&(identical(other.targets, _this.targets) || other.targets == _this.targets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDayTotals;
  return Object.hash(runtimeType,_this.kcal,_this.proteinG,_this.carbsG,_this.fatG,_this.fiberG,_this.targets);
}

@override
String toString() {
  final _this = this as BuddyDayTotals;
  return 'BuddyDayTotals(kcal: ${_this.kcal}, proteinG: ${_this.proteinG}, carbsG: ${_this.carbsG}, fatG: ${_this.fatG}, fiberG: ${_this.fiberG}, targets: ${_this.targets})';
}


}

/// @nodoc
abstract mixin class $BuddyDayTotalsCopyWith<$Res>  {
  factory $BuddyDayTotalsCopyWith(BuddyDayTotals value, $Res Function(BuddyDayTotals) _then) = _$BuddyDayTotalsCopyWithImpl;
@useResult
$Res call({
 double kcal, double proteinG, double carbsG, double fatG, double fiberG, BuddyDayTargets? targets
});


$BuddyDayTargetsCopyWith<$Res>? get targets;

}
/// @nodoc
class _$BuddyDayTotalsCopyWithImpl<$Res>
    implements $BuddyDayTotalsCopyWith<$Res> {
  _$BuddyDayTotalsCopyWithImpl(this._self, this._then);

  final BuddyDayTotals _self;
  final $Res Function(BuddyDayTotals) _then;

/// Create a copy of BuddyDayTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,Object? targets = freezed,}) {
  return _then(BuddyDayTotals(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,targets: freezed == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as BuddyDayTargets?,
  ));
}
/// Create a copy of BuddyDayTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayTargetsCopyWith<$Res>? get targets {
    if (_self.targets == null) {
    return null;
  }

  return $BuddyDayTargetsCopyWith<$Res>(_self.targets!, (value) {
    return _then(_self.copyWith(targets: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDayTotals].
extension BuddyDayTotalsPatterns on BuddyDayTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDayTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDayTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDayTotals value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDayTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDayTotals value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDayTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double kcal,  double proteinG,  double carbsG,  double fatG,  double fiberG,  BuddyDayTargets? targets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDayTotals() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.targets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double kcal,  double proteinG,  double carbsG,  double fatG,  double fiberG,  BuddyDayTargets? targets)  $default,) {final _that = this;
switch (_that) {
case _BuddyDayTotals():
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.targets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double kcal,  double proteinG,  double carbsG,  double fatG,  double fiberG,  BuddyDayTargets? targets)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDayTotals() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.targets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDayTotals implements BuddyDayTotals {
  const _BuddyDayTotals({required this.kcal, required this.proteinG, required this.carbsG, required this.fatG, required this.fiberG, required this.targets});
  factory _BuddyDayTotals.fromJson(Map<String, dynamic> json) => _$BuddyDayTotalsFromJson(json);

@override final  double kcal;
@override final  double proteinG;
@override final  double carbsG;
@override final  double fatG;
@override final  double fiberG;
@override final  BuddyDayTargets? targets;

/// Create a copy of BuddyDayTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDayTotalsCopyWith<_BuddyDayTotals> get copyWith => __$BuddyDayTotalsCopyWithImpl<_BuddyDayTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDayTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDayTotals&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.targets, targets) || other.targets == targets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kcal,proteinG,carbsG,fatG,fiberG,targets);
}

@override
String toString() {
    return 'BuddyDayTotals(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, targets: $targets)';
}


}

/// @nodoc
abstract mixin class _$BuddyDayTotalsCopyWith<$Res> implements $BuddyDayTotalsCopyWith<$Res> {
  factory _$BuddyDayTotalsCopyWith(_BuddyDayTotals value, $Res Function(_BuddyDayTotals) _then) = __$BuddyDayTotalsCopyWithImpl;
@override @useResult
$Res call({
 double kcal, double proteinG, double carbsG, double fatG, double fiberG, BuddyDayTargets? targets
});


@override $BuddyDayTargetsCopyWith<$Res>? get targets;

}
/// @nodoc
class __$BuddyDayTotalsCopyWithImpl<$Res>
    implements _$BuddyDayTotalsCopyWith<$Res> {
  __$BuddyDayTotalsCopyWithImpl(this._self, this._then);

  final _BuddyDayTotals _self;
  final $Res Function(_BuddyDayTotals) _then;

/// Create a copy of BuddyDayTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,Object? targets = freezed,}) {
  return _then(_BuddyDayTotals(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,targets: freezed == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as BuddyDayTargets?,
  ));
}

/// Create a copy of BuddyDayTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayTargetsCopyWith<$Res>? get targets {
    if (_self.targets == null) {
    return null;
  }

  return $BuddyDayTargetsCopyWith<$Res>(_self.targets!, (value) {
    return _then(_self.copyWith(targets: value));
  });
}
}

// dart format on
