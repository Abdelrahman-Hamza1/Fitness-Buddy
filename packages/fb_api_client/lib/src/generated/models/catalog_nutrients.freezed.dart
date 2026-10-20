// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_nutrients.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogNutrients {

 double get kcal; double get proteinG; double get carbsG; double get fatG; double get fiberG;
/// Create a copy of CatalogNutrients
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<CatalogNutrients> get copyWith => _$CatalogNutrientsCopyWithImpl<CatalogNutrients>(this as CatalogNutrients, _$identity);

  /// Serializes this CatalogNutrients to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatalogNutrients;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogNutrients&&(identical(other.kcal, _this.kcal) || other.kcal == _this.kcal)&&(identical(other.proteinG, _this.proteinG) || other.proteinG == _this.proteinG)&&(identical(other.carbsG, _this.carbsG) || other.carbsG == _this.carbsG)&&(identical(other.fatG, _this.fatG) || other.fatG == _this.fatG)&&(identical(other.fiberG, _this.fiberG) || other.fiberG == _this.fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatalogNutrients;
  return Object.hash(runtimeType,_this.kcal,_this.proteinG,_this.carbsG,_this.fatG,_this.fiberG);
}

@override
String toString() {
  final _this = this as CatalogNutrients;
  return 'CatalogNutrients(kcal: ${_this.kcal}, proteinG: ${_this.proteinG}, carbsG: ${_this.carbsG}, fatG: ${_this.fatG}, fiberG: ${_this.fiberG})';
}


}

/// @nodoc
abstract mixin class $CatalogNutrientsCopyWith<$Res>  {
  factory $CatalogNutrientsCopyWith(CatalogNutrients value, $Res Function(CatalogNutrients) _then) = _$CatalogNutrientsCopyWithImpl;
@useResult
$Res call({
 double kcal, double proteinG, double carbsG, double fatG, double fiberG
});




}
/// @nodoc
class _$CatalogNutrientsCopyWithImpl<$Res>
    implements $CatalogNutrientsCopyWith<$Res> {
  _$CatalogNutrientsCopyWithImpl(this._self, this._then);

  final CatalogNutrients _self;
  final $Res Function(CatalogNutrients) _then;

/// Create a copy of CatalogNutrients
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(CatalogNutrients(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogNutrients].
extension CatalogNutrientsPatterns on CatalogNutrients {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogNutrients value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogNutrients() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogNutrients value)  $default,){
final _that = this;
switch (_that) {
case _CatalogNutrients():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogNutrients value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogNutrients() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double kcal,  double proteinG,  double carbsG,  double fatG,  double fiberG)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogNutrients() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double kcal,  double proteinG,  double carbsG,  double fatG,  double fiberG)  $default,) {final _that = this;
switch (_that) {
case _CatalogNutrients():
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double kcal,  double proteinG,  double carbsG,  double fatG,  double fiberG)?  $default,) {final _that = this;
switch (_that) {
case _CatalogNutrients() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogNutrients implements CatalogNutrients {
  const _CatalogNutrients({required this.kcal, required this.proteinG, required this.carbsG, required this.fatG, required this.fiberG});
  factory _CatalogNutrients.fromJson(Map<String, dynamic> json) => _$CatalogNutrientsFromJson(json);

@override final  double kcal;
@override final  double proteinG;
@override final  double carbsG;
@override final  double fatG;
@override final  double fiberG;

/// Create a copy of CatalogNutrients
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogNutrientsCopyWith<_CatalogNutrients> get copyWith => __$CatalogNutrientsCopyWithImpl<_CatalogNutrients>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogNutrientsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogNutrients&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kcal,proteinG,carbsG,fatG,fiberG);
}

@override
String toString() {
    return 'CatalogNutrients(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class _$CatalogNutrientsCopyWith<$Res> implements $CatalogNutrientsCopyWith<$Res> {
  factory _$CatalogNutrientsCopyWith(_CatalogNutrients value, $Res Function(_CatalogNutrients) _then) = __$CatalogNutrientsCopyWithImpl;
@override @useResult
$Res call({
 double kcal, double proteinG, double carbsG, double fatG, double fiberG
});




}
/// @nodoc
class __$CatalogNutrientsCopyWithImpl<$Res>
    implements _$CatalogNutrientsCopyWith<$Res> {
  __$CatalogNutrientsCopyWithImpl(this._self, this._then);

  final _CatalogNutrients _self;
  final $Res Function(_CatalogNutrients) _then;

/// Create a copy of CatalogNutrients
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(_CatalogNutrients(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
