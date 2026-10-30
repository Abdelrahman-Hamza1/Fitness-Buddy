// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'barcode_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BarcodeProduct {

 String get code; String get source; bool get complete; String? get name; String? get nameAr; String? get brand; String get basis; BarcodeNutrients get per100; double? get servingQuantity; String? get servingLabel; String? get ingredientsText; List<String> get labels;
/// Create a copy of BarcodeProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BarcodeProductCopyWith<BarcodeProduct> get copyWith => _$BarcodeProductCopyWithImpl<BarcodeProduct>(this as BarcodeProduct, _$identity);

  /// Serializes this BarcodeProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BarcodeProduct;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BarcodeProduct&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.complete, _this.complete) || other.complete == _this.complete)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.nameAr, _this.nameAr) || other.nameAr == _this.nameAr)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.basis, _this.basis) || other.basis == _this.basis)&&(identical(other.per100, _this.per100) || other.per100 == _this.per100)&&(identical(other.servingQuantity, _this.servingQuantity) || other.servingQuantity == _this.servingQuantity)&&(identical(other.servingLabel, _this.servingLabel) || other.servingLabel == _this.servingLabel)&&(identical(other.ingredientsText, _this.ingredientsText) || other.ingredientsText == _this.ingredientsText)&&const DeepCollectionEquality().equals(other.labels, _this.labels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BarcodeProduct;
  return Object.hash(runtimeType,_this.code,_this.source,_this.complete,_this.name,_this.nameAr,_this.brand,_this.basis,_this.per100,_this.servingQuantity,_this.servingLabel,_this.ingredientsText,const DeepCollectionEquality().hash(_this.labels));
}

@override
String toString() {
  final _this = this as BarcodeProduct;
  return 'BarcodeProduct(code: ${_this.code}, source: ${_this.source}, complete: ${_this.complete}, name: ${_this.name}, nameAr: ${_this.nameAr}, brand: ${_this.brand}, basis: ${_this.basis}, per100: ${_this.per100}, servingQuantity: ${_this.servingQuantity}, servingLabel: ${_this.servingLabel}, ingredientsText: ${_this.ingredientsText}, labels: ${_this.labels})';
}


}

/// @nodoc
abstract mixin class $BarcodeProductCopyWith<$Res>  {
  factory $BarcodeProductCopyWith(BarcodeProduct value, $Res Function(BarcodeProduct) _then) = _$BarcodeProductCopyWithImpl;
@useResult
$Res call({
 String code, String source, bool complete, String? name, String? nameAr, String? brand, String basis, BarcodeNutrients per100, double? servingQuantity, String? servingLabel, String? ingredientsText, List<String> labels
});


$BarcodeNutrientsCopyWith<$Res> get per100;

}
/// @nodoc
class _$BarcodeProductCopyWithImpl<$Res>
    implements $BarcodeProductCopyWith<$Res> {
  _$BarcodeProductCopyWithImpl(this._self, this._then);

  final BarcodeProduct _self;
  final $Res Function(BarcodeProduct) _then;

/// Create a copy of BarcodeProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? source = null,Object? complete = null,Object? name = freezed,Object? nameAr = freezed,Object? brand = freezed,Object? basis = null,Object? per100 = null,Object? servingQuantity = freezed,Object? servingLabel = freezed,Object? ingredientsText = freezed,Object? labels = null,}) {
  return _then(BarcodeProduct(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,complete: null == complete ? _self.complete : complete // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameAr: freezed == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String,per100: null == per100 ? _self.per100 : per100 // ignore: cast_nullable_to_non_nullable
as BarcodeNutrients,servingQuantity: freezed == servingQuantity ? _self.servingQuantity : servingQuantity // ignore: cast_nullable_to_non_nullable
as double?,servingLabel: freezed == servingLabel ? _self.servingLabel : servingLabel // ignore: cast_nullable_to_non_nullable
as String?,ingredientsText: freezed == ingredientsText ? _self.ingredientsText : ingredientsText // ignore: cast_nullable_to_non_nullable
as String?,labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of BarcodeProduct
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BarcodeNutrientsCopyWith<$Res> get per100 {
  
  return $BarcodeNutrientsCopyWith<$Res>(_self.per100, (value) {
    return _then(_self.copyWith(per100: value));
  });
}
}


/// Adds pattern-matching-related methods to [BarcodeProduct].
extension BarcodeProductPatterns on BarcodeProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BarcodeProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BarcodeProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BarcodeProduct value)  $default,){
final _that = this;
switch (_that) {
case _BarcodeProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BarcodeProduct value)?  $default,){
final _that = this;
switch (_that) {
case _BarcodeProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String source,  bool complete,  String? name,  String? nameAr,  String? brand,  String basis,  BarcodeNutrients per100,  double? servingQuantity,  String? servingLabel,  String? ingredientsText,  List<String> labels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BarcodeProduct() when $default != null:
return $default(_that.code,_that.source,_that.complete,_that.name,_that.nameAr,_that.brand,_that.basis,_that.per100,_that.servingQuantity,_that.servingLabel,_that.ingredientsText,_that.labels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String source,  bool complete,  String? name,  String? nameAr,  String? brand,  String basis,  BarcodeNutrients per100,  double? servingQuantity,  String? servingLabel,  String? ingredientsText,  List<String> labels)  $default,) {final _that = this;
switch (_that) {
case _BarcodeProduct():
return $default(_that.code,_that.source,_that.complete,_that.name,_that.nameAr,_that.brand,_that.basis,_that.per100,_that.servingQuantity,_that.servingLabel,_that.ingredientsText,_that.labels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String source,  bool complete,  String? name,  String? nameAr,  String? brand,  String basis,  BarcodeNutrients per100,  double? servingQuantity,  String? servingLabel,  String? ingredientsText,  List<String> labels)?  $default,) {final _that = this;
switch (_that) {
case _BarcodeProduct() when $default != null:
return $default(_that.code,_that.source,_that.complete,_that.name,_that.nameAr,_that.brand,_that.basis,_that.per100,_that.servingQuantity,_that.servingLabel,_that.ingredientsText,_that.labels);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BarcodeProduct implements BarcodeProduct {
  const _BarcodeProduct({required this.code, required this.source, required this.complete, required this.name, required this.nameAr, required this.brand, required this.basis, required this.per100, required this.servingQuantity, required this.servingLabel, required this.ingredientsText, required  List<String> labels}): _labels = labels;
  factory _BarcodeProduct.fromJson(Map<String, dynamic> json) => _$BarcodeProductFromJson(json);

@override final  String code;
@override final  String source;
@override final  bool complete;
@override final  String? name;
@override final  String? nameAr;
@override final  String? brand;
@override final  String basis;
@override final  BarcodeNutrients per100;
@override final  double? servingQuantity;
@override final  String? servingLabel;
@override final  String? ingredientsText;
 final  List<String> _labels;
@override List<String> get labels {
  if (_labels is EqualUnmodifiableListView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labels);
}


/// Create a copy of BarcodeProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BarcodeProductCopyWith<_BarcodeProduct> get copyWith => __$BarcodeProductCopyWithImpl<_BarcodeProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BarcodeProductToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BarcodeProduct&&(identical(other.code, code) || other.code == code)&&(identical(other.source, source) || other.source == source)&&(identical(other.complete, complete) || other.complete == complete)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.per100, per100) || other.per100 == per100)&&(identical(other.servingQuantity, servingQuantity) || other.servingQuantity == servingQuantity)&&(identical(other.servingLabel, servingLabel) || other.servingLabel == servingLabel)&&(identical(other.ingredientsText, ingredientsText) || other.ingredientsText == ingredientsText)&&const DeepCollectionEquality().equals(other.labels, _labels));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,source,complete,name,nameAr,brand,basis,per100,servingQuantity,servingLabel,ingredientsText,const DeepCollectionEquality().hash(_labels));
}

@override
String toString() {
    return 'BarcodeProduct(code: $code, source: $source, complete: $complete, name: $name, nameAr: $nameAr, brand: $brand, basis: $basis, per100: $per100, servingQuantity: $servingQuantity, servingLabel: $servingLabel, ingredientsText: $ingredientsText, labels: $labels)';
}


}

/// @nodoc
abstract mixin class _$BarcodeProductCopyWith<$Res> implements $BarcodeProductCopyWith<$Res> {
  factory _$BarcodeProductCopyWith(_BarcodeProduct value, $Res Function(_BarcodeProduct) _then) = __$BarcodeProductCopyWithImpl;
@override @useResult
$Res call({
 String code, String source, bool complete, String? name, String? nameAr, String? brand, String basis, BarcodeNutrients per100, double? servingQuantity, String? servingLabel, String? ingredientsText, List<String> labels
});


@override $BarcodeNutrientsCopyWith<$Res> get per100;

}
/// @nodoc
class __$BarcodeProductCopyWithImpl<$Res>
    implements _$BarcodeProductCopyWith<$Res> {
  __$BarcodeProductCopyWithImpl(this._self, this._then);

  final _BarcodeProduct _self;
  final $Res Function(_BarcodeProduct) _then;

/// Create a copy of BarcodeProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? source = null,Object? complete = null,Object? name = freezed,Object? nameAr = freezed,Object? brand = freezed,Object? basis = null,Object? per100 = null,Object? servingQuantity = freezed,Object? servingLabel = freezed,Object? ingredientsText = freezed,Object? labels = null,}) {
  return _then(_BarcodeProduct(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,complete: null == complete ? _self.complete : complete // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nameAr: freezed == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,basis: null == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String,per100: null == per100 ? _self.per100 : per100 // ignore: cast_nullable_to_non_nullable
as BarcodeNutrients,servingQuantity: freezed == servingQuantity ? _self.servingQuantity : servingQuantity // ignore: cast_nullable_to_non_nullable
as double?,servingLabel: freezed == servingLabel ? _self.servingLabel : servingLabel // ignore: cast_nullable_to_non_nullable
as String?,ingredientsText: freezed == ingredientsText ? _self.ingredientsText : ingredientsText // ignore: cast_nullable_to_non_nullable
as String?,labels: null == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of BarcodeProduct
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BarcodeNutrientsCopyWith<$Res> get per100 {
  
  return $BarcodeNutrientsCopyWith<$Res>(_self.per100, (value) {
    return _then(_self.copyWith(per100: value));
  });
}
}

// dart format on
