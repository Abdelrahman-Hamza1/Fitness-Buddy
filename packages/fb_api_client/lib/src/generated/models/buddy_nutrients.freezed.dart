// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_nutrients.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyNutrients {

 double get kcal; double get proteinG; double get carbsG; double get fatG; double get fiberG;
/// Create a copy of BuddyNutrients
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyNutrientsCopyWith<BuddyNutrients> get copyWith => _$BuddyNutrientsCopyWithImpl<BuddyNutrients>(this as BuddyNutrients, _$identity);

  /// Serializes this BuddyNutrients to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyNutrients;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyNutrients&&(identical(other.kcal, _this.kcal) || other.kcal == _this.kcal)&&(identical(other.proteinG, _this.proteinG) || other.proteinG == _this.proteinG)&&(identical(other.carbsG, _this.carbsG) || other.carbsG == _this.carbsG)&&(identical(other.fatG, _this.fatG) || other.fatG == _this.fatG)&&(identical(other.fiberG, _this.fiberG) || other.fiberG == _this.fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyNutrients;
  return Object.hash(runtimeType,_this.kcal,_this.proteinG,_this.carbsG,_this.fatG,_this.fiberG);
}

@override
String toString() {
  final _this = this as BuddyNutrients;
  return 'BuddyNutrients(kcal: ${_this.kcal}, proteinG: ${_this.proteinG}, carbsG: ${_this.carbsG}, fatG: ${_this.fatG}, fiberG: ${_this.fiberG})';
}


}

/// @nodoc
abstract mixin class $BuddyNutrientsCopyWith<$Res>  {
  factory $BuddyNutrientsCopyWith(BuddyNutrients value, $Res Function(BuddyNutrients) _then) = _$BuddyNutrientsCopyWithImpl;
@useResult
$Res call({
 double kcal, double proteinG, double carbsG, double fatG, double fiberG
});




}
/// @nodoc
class _$BuddyNutrientsCopyWithImpl<$Res>
    implements $BuddyNutrientsCopyWith<$Res> {
  _$BuddyNutrientsCopyWithImpl(this._self, this._then);

  final BuddyNutrients _self;
  final $Res Function(BuddyNutrients) _then;

/// Create a copy of BuddyNutrients
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(BuddyNutrients(
kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as double,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as double,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as double,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyNutrients].
extension BuddyNutrientsPatterns on BuddyNutrients {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyNutrients value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyNutrients() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyNutrients value)  $default,){
final _that = this;
switch (_that) {
case _BuddyNutrients():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyNutrients value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyNutrients() when $default != null:
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
case _BuddyNutrients() when $default != null:
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
case _BuddyNutrients():
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
case _BuddyNutrients() when $default != null:
return $default(_that.kcal,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyNutrients implements BuddyNutrients {
  const _BuddyNutrients({required this.kcal, required this.proteinG, required this.carbsG, required this.fatG, required this.fiberG});
  factory _BuddyNutrients.fromJson(Map<String, dynamic> json) => _$BuddyNutrientsFromJson(json);

@override final  double kcal;
@override final  double proteinG;
@override final  double carbsG;
@override final  double fatG;
@override final  double fiberG;

/// Create a copy of BuddyNutrients
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyNutrientsCopyWith<_BuddyNutrients> get copyWith => __$BuddyNutrientsCopyWithImpl<_BuddyNutrients>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyNutrientsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyNutrients&&(identical(other.kcal, kcal) || other.kcal == kcal)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kcal,proteinG,carbsG,fatG,fiberG);
}

@override
String toString() {
    return 'BuddyNutrients(kcal: $kcal, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG)';
}


}

/// @nodoc
abstract mixin class _$BuddyNutrientsCopyWith<$Res> implements $BuddyNutrientsCopyWith<$Res> {
  factory _$BuddyNutrientsCopyWith(_BuddyNutrients value, $Res Function(_BuddyNutrients) _then) = __$BuddyNutrientsCopyWithImpl;
@override @useResult
$Res call({
 double kcal, double proteinG, double carbsG, double fatG, double fiberG
});




}
/// @nodoc
class __$BuddyNutrientsCopyWithImpl<$Res>
    implements _$BuddyNutrientsCopyWith<$Res> {
  __$BuddyNutrientsCopyWithImpl(this._self, this._then);

  final _BuddyNutrients _self;
  final $Res Function(_BuddyNutrients) _then;

/// Create a copy of BuddyNutrients
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kcal = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,}) {
  return _then(_BuddyNutrients(
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
