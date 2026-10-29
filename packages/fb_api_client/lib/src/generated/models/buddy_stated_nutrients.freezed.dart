// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_stated_nutrients.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyStatedNutrients {

 BuddyNutrientBasis get basis; double? get servingG; double? get servingMl; double? get kcal; double? get proteinG; double? get carbsG; double? get fatG; double? get fiberG;
/// Create a copy of BuddyStatedNutrients
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyStatedNutrientsCopyWith<BuddyStatedNutrients> get copyWith => _$BuddyStatedNutrientsCopyWithImpl<BuddyStatedNutrients>(this as BuddyStatedNutrients, _$identity);

  /// Serializes this BuddyStatedNutrients to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyStatedNutrients;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyStatedNutrients&&(identical(other.basis, _this.basis) || other.basis == _this.basis)&&(identical(other.servingG, _this.servingG) || other.servingG == _this.servingG)&&(identical(other.servingMl, _this.servingMl) || other.servingMl == _this.servingMl)&&(identical(other.kcal, _this.kcal) || other.kcal == _this.kcal)&&(identical(other.proteinG, _this.proteinG) || other.proteinG == _this.proteinG)&&(identical(other.carbsG, _this.carbsG) || other.carbsG == _this.carbsG)&&(identical(other.fatG, _this.fatG) || other.fatG == _this.fatG)&&(identical(other.fiberG, _this.fiberG) || other.fiberG == _this.fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyStatedNutrients;
  return Object.hash(runtimeType,_this.basis,_this.servingG,_this.servingMl,_this.kcal,_this.proteinG,_this.carbsG,_this.fatG,_this.fiberG);
}

@override
String toString() {
  final _this = this as BuddyStatedNutrients;
  return 'BuddyStatedNutrients(basis: ${_this.basis}, servingG: ${_this.servingG}, servingMl: ${_this.servingMl}, kcal: ${_this.kcal}, proteinG: ${_this.proteinG}, carbsG: ${_this.carbsG}, fatG: ${_this.fatG}, fiberG: ${_this.fiberG})';
}


}

/// @nodoc
abstract mixin class $BuddyStatedNutrientsCopyWith<$Res>  {
  factory $BuddyStatedNutrientsCopyWith(BuddyStatedNutrients value, $Res Function(BuddyStatedNutrients) _then) = _$BuddyStatedNutrientsCopyWithImpl;
@useResult
$Res call({
 BuddyNutrientBasis basis, double? servingG, double? servingMl, double? kcal, double? proteinG, double? carbsG, double? fatG, double? fiberG
});




}
/// @nodoc
class _$BuddyStatedNutrientsCopyWithImpl<$Res>
    implements $BuddyStatedNutrientsCopyWith<$Res> {
  _$BuddyStatedNutrientsCopyWithImpl(this._self, this._then);

  final BuddyStatedNutrients _self;
  final $Res Function(BuddyStatedNutrients) _then;

/// Create a copy of BuddyStatedNutrients
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? basis = null,Object? servingG = freezed,Object? servingMl = freezed,Object? kcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,}) {
  return _then(BuddyStatedNutrients(
basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as BuddyNutrientBasis,servingG: freezed == servingG ? _self.servingG : servingG // ignore: cast_nullable_to_non_nullable
as double?,servingMl: freezed == servingMl ? _self.servingMl : servingMl // ignore: cast_nullable_to_non_nullable
as double?,kcal: freezed == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double?,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbsG: freezed == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,fiberG: freezed == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyStatedNutrients].
extension BuddyStatedNutrientsPatterns on BuddyStatedNutrients {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyStatedNutrients value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyStatedNutrients() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyStatedNutrients value)  $default,){
final _that = this;
switch (_that) {
case _BuddyStatedNutrients():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyStatedNutrients value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyStatedNutrients() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyNutrientBasis basis,  double? servingG,  double? servingMl,  double? kcal,  double? proteinG,  double? carbsG,  double? fatG,  double? fiberG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyStatedNutrients() when $default != null:
return $default(_that.basis,_that.servingG,_that.servingMl,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyNutrientBasis basis,  double? servingG,  double? servingMl,  double? kcal,  double? proteinG,  double? carbsG,  double? fatG,  double? fiberG)  $default,) {final _that = this;
switch (_that) {
case _BuddyStatedNutrients():
return $default(_that.basis,_that.servingG,_that.servingMl,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyNutrientBasis basis,  double? servingG,  double? servingMl,  double? kcal,  double? proteinG,  double? carbsG,  double? fatG,  double? fiberG)?  $default,) {final _that = this;
switch (_that) {
case _BuddyStatedNutrients() when $default != null:
return $default(_that.basis,_that.servingG,_that.servingMl,_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyStatedNutrients implements BuddyStatedNutrients {
  const _BuddyStatedNutrients({required this.basis, required this.servingG, required this.servingMl, required this.kcal, required this.proteinG, required this.carbsG, required this.fatG, required this.fiberG});
  factory _BuddyStatedNutrients.fromJson(Map<String, dynamic> json) => _$BuddyStatedNutrientsFromJson(json);

@override final  BuddyNutrientBasis basis;
@override final  double? servingG;
@override final  double? servingMl;
@override final  double? kcal;
@override final  double? proteinG;
@override final  double? carbsG;
@override final  double? fatG;
@override final  double? fiberG;

/// Create a copy of BuddyStatedNutrients
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyStatedNutrientsCopyWith<_BuddyStatedNutrients> get copyWith => __$BuddyStatedNutrientsCopyWithImpl<_BuddyStatedNutrients>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyStatedNutrientsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyStatedNutrients&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.servingG, servingG) || other.servingG == servingG)&&(identical(other.servingMl, servingMl) || other.servingMl == servingMl)&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,basis,servingG,servingMl,kcal,proteinG,carbsG,fatG,fiberG);
}

@override
String toString() {
    return 'BuddyStatedNutrients(basis: $basis, servingG: $servingG, servingMl: $servingMl, kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class _$BuddyStatedNutrientsCopyWith<$Res> implements $BuddyStatedNutrientsCopyWith<$Res> {
  factory _$BuddyStatedNutrientsCopyWith(_BuddyStatedNutrients value, $Res Function(_BuddyStatedNutrients) _then) = __$BuddyStatedNutrientsCopyWithImpl;
@override @useResult
$Res call({
 BuddyNutrientBasis basis, double? servingG, double? servingMl, double? kcal, double? proteinG, double? carbsG, double? fatG, double? fiberG
});




}
/// @nodoc
class __$BuddyStatedNutrientsCopyWithImpl<$Res>
    implements _$BuddyStatedNutrientsCopyWith<$Res> {
  __$BuddyStatedNutrientsCopyWithImpl(this._self, this._then);

  final _BuddyStatedNutrients _self;
  final $Res Function(_BuddyStatedNutrients) _then;

/// Create a copy of BuddyStatedNutrients
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? basis = null,Object? servingG = freezed,Object? servingMl = freezed,Object? kcal = freezed,Object? proteinG = freezed,Object? carbsG = freezed,Object? fatG = freezed,Object? fiberG = freezed,}) {
  return _then(_BuddyStatedNutrients(
basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as BuddyNutrientBasis,servingG: freezed == servingG ? _self.servingG : servingG // ignore: cast_nullable_to_non_nullable
as double?,servingMl: freezed == servingMl ? _self.servingMl : servingMl // ignore: cast_nullable_to_non_nullable
as double?,kcal: freezed == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double?,proteinG: freezed == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double?,carbsG: freezed == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double?,fatG: freezed == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double?,fiberG: freezed == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
