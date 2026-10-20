// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_food.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogFood {

 String get kind; String get source; String? get sourceRef; String get nameEn; String? get nameAr; String get state; bool get verified; int get catalogVersion; CatalogNutrients get nutrients; CatalogNutrientRange? get ranges; Map<String, double>? get extras; double? get densityGPerMl; String? get yieldGroup; List<CatalogServing> get servings; String get catalogKey;
/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogFoodCopyWith<CatalogFood> get copyWith => _$CatalogFoodCopyWithImpl<CatalogFood>(this as CatalogFood, _$identity);

  /// Serializes this CatalogFood to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatalogFood;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogFood&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.sourceRef, _this.sourceRef) || other.sourceRef == _this.sourceRef)&&(identical(other.nameEn, _this.nameEn) || other.nameEn == _this.nameEn)&&(identical(other.nameAr, _this.nameAr) || other.nameAr == _this.nameAr)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.verified, _this.verified) || other.verified == _this.verified)&&(identical(other.catalogVersion, _this.catalogVersion) || other.catalogVersion == _this.catalogVersion)&&(identical(other.nutrients, _this.nutrients) || other.nutrients == _this.nutrients)&&(identical(other.ranges, _this.ranges) || other.ranges == _this.ranges)&&const DeepCollectionEquality().equals(other.extras, _this.extras)&&(identical(other.densityGPerMl, _this.densityGPerMl) || other.densityGPerMl == _this.densityGPerMl)&&(identical(other.yieldGroup, _this.yieldGroup) || other.yieldGroup == _this.yieldGroup)&&const DeepCollectionEquality().equals(other.servings, _this.servings)&&(identical(other.catalogKey, _this.catalogKey) || other.catalogKey == _this.catalogKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatalogFood;
  return Object.hash(runtimeType,_this.kind,_this.source,_this.sourceRef,_this.nameEn,_this.nameAr,_this.state,_this.verified,_this.catalogVersion,_this.nutrients,_this.ranges,const DeepCollectionEquality().hash(_this.extras),_this.densityGPerMl,_this.yieldGroup,const DeepCollectionEquality().hash(_this.servings),_this.catalogKey);
}

@override
String toString() {
  final _this = this as CatalogFood;
  return 'CatalogFood(kind: ${_this.kind}, source: ${_this.source}, sourceRef: ${_this.sourceRef}, nameEn: ${_this.nameEn}, nameAr: ${_this.nameAr}, state: ${_this.state}, verified: ${_this.verified}, catalogVersion: ${_this.catalogVersion}, nutrients: ${_this.nutrients}, ranges: ${_this.ranges}, extras: ${_this.extras}, densityGPerMl: ${_this.densityGPerMl}, yieldGroup: ${_this.yieldGroup}, servings: ${_this.servings}, catalogKey: ${_this.catalogKey})';
}


}

/// @nodoc
abstract mixin class $CatalogFoodCopyWith<$Res>  {
  factory $CatalogFoodCopyWith(CatalogFood value, $Res Function(CatalogFood) _then) = _$CatalogFoodCopyWithImpl;
@useResult
$Res call({
 String kind, String source, String? sourceRef, String nameEn, String? nameAr, String state, bool verified, int catalogVersion, CatalogNutrients nutrients, CatalogNutrientRange? ranges, Map<String, double>? extras, double? densityGPerMl, String? yieldGroup, List<CatalogServing> servings, String catalogKey
});


$CatalogNutrientsCopyWith<$Res> get nutrients;$CatalogNutrientRangeCopyWith<$Res>? get ranges;

}
/// @nodoc
class _$CatalogFoodCopyWithImpl<$Res>
    implements $CatalogFoodCopyWith<$Res> {
  _$CatalogFoodCopyWithImpl(this._self, this._then);

  final CatalogFood _self;
  final $Res Function(CatalogFood) _then;

/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? source = null,Object? sourceRef = freezed,Object? nameEn = null,Object? nameAr = freezed,Object? state = null,Object? verified = null,Object? catalogVersion = null,Object? nutrients = null,Object? ranges = freezed,Object? extras = freezed,Object? densityGPerMl = freezed,Object? yieldGroup = freezed,Object? servings = null,Object? catalogKey = null,}) {
  return _then(CatalogFood(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sourceRef: freezed == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String?,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameAr: freezed == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,catalogVersion: null == catalogVersion ? _self.catalogVersion : catalogVersion // ignore: cast_nullable_to_non_nullable
as int,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as CatalogNutrients,ranges: freezed == ranges ? _self.ranges : ranges // ignore: cast_nullable_to_non_nullable
as CatalogNutrientRange?,extras: freezed == extras ? _self.extras : extras // ignore: cast_nullable_to_non_nullable
as Map<String, double>?,densityGPerMl: freezed == densityGPerMl ? _self.densityGPerMl : densityGPerMl // ignore: cast_nullable_to_non_nullable
as double?,yieldGroup: freezed == yieldGroup ? _self.yieldGroup : yieldGroup // ignore: cast_nullable_to_non_nullable
as String?,servings: null == servings ? _self.servings : servings // ignore: cast_nullable_to_non_nullable
as List<CatalogServing>,catalogKey: null == catalogKey ? _self.catalogKey : catalogKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<$Res> get nutrients {
  
  return $CatalogNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientRangeCopyWith<$Res>? get ranges {
    if (_self.ranges == null) {
    return null;
  }

  return $CatalogNutrientRangeCopyWith<$Res>(_self.ranges!, (value) {
    return _then(_self.copyWith(ranges: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatalogFood].
extension CatalogFoodPatterns on CatalogFood {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogFood value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogFood() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogFood value)  $default,){
final _that = this;
switch (_that) {
case _CatalogFood():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogFood value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogFood() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String source,  String? sourceRef,  String nameEn,  String? nameAr,  String state,  bool verified,  int catalogVersion,  CatalogNutrients nutrients,  CatalogNutrientRange? ranges,  Map<String, double>? extras,  double? densityGPerMl,  String? yieldGroup,  List<CatalogServing> servings,  String catalogKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogFood() when $default != null:
return $default(_that.kind,_that.source,_that.sourceRef,_that.nameEn,_that.nameAr,_that.state,_that.verified,_that.catalogVersion,_that.nutrients,_that.ranges,_that.extras,_that.densityGPerMl,_that.yieldGroup,_that.servings,_that.catalogKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String source,  String? sourceRef,  String nameEn,  String? nameAr,  String state,  bool verified,  int catalogVersion,  CatalogNutrients nutrients,  CatalogNutrientRange? ranges,  Map<String, double>? extras,  double? densityGPerMl,  String? yieldGroup,  List<CatalogServing> servings,  String catalogKey)  $default,) {final _that = this;
switch (_that) {
case _CatalogFood():
return $default(_that.kind,_that.source,_that.sourceRef,_that.nameEn,_that.nameAr,_that.state,_that.verified,_that.catalogVersion,_that.nutrients,_that.ranges,_that.extras,_that.densityGPerMl,_that.yieldGroup,_that.servings,_that.catalogKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String source,  String? sourceRef,  String nameEn,  String? nameAr,  String state,  bool verified,  int catalogVersion,  CatalogNutrients nutrients,  CatalogNutrientRange? ranges,  Map<String, double>? extras,  double? densityGPerMl,  String? yieldGroup,  List<CatalogServing> servings,  String catalogKey)?  $default,) {final _that = this;
switch (_that) {
case _CatalogFood() when $default != null:
return $default(_that.kind,_that.source,_that.sourceRef,_that.nameEn,_that.nameAr,_that.state,_that.verified,_that.catalogVersion,_that.nutrients,_that.ranges,_that.extras,_that.densityGPerMl,_that.yieldGroup,_that.servings,_that.catalogKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogFood implements CatalogFood {
  const _CatalogFood({required this.kind, required this.source, required this.sourceRef, required this.nameEn, required this.nameAr, required this.state, required this.verified, required this.catalogVersion, required this.nutrients, required this.ranges, required  Map<String, double>? extras, required this.densityGPerMl, required this.yieldGroup, required  List<CatalogServing> servings, required this.catalogKey}): _extras = extras,_servings = servings;
  factory _CatalogFood.fromJson(Map<String, dynamic> json) => _$CatalogFoodFromJson(json);

@override final  String kind;
@override final  String source;
@override final  String? sourceRef;
@override final  String nameEn;
@override final  String? nameAr;
@override final  String state;
@override final  bool verified;
@override final  int catalogVersion;
@override final  CatalogNutrients nutrients;
@override final  CatalogNutrientRange? ranges;
 final  Map<String, double>? _extras;
@override Map<String, double>? get extras {
  final value = _extras;
  if (value == null) return null;
  if (_extras is EqualUnmodifiableMapView) return _extras;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  double? densityGPerMl;
@override final  String? yieldGroup;
 final  List<CatalogServing> _servings;
@override List<CatalogServing> get servings {
  if (_servings is EqualUnmodifiableListView) return _servings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_servings);
}

@override final  String catalogKey;

/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogFoodCopyWith<_CatalogFood> get copyWith => __$CatalogFoodCopyWithImpl<_CatalogFood>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogFoodToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogFood&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceRef, sourceRef) || other.sourceRef == sourceRef)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameAr, nameAr) || other.nameAr == nameAr)&&(identical(other.state, state) || other.state == state)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.catalogVersion, catalogVersion) || other.catalogVersion == catalogVersion)&&(identical(other.nutrients, nutrients) || other.nutrients == nutrients)&&(identical(other.ranges, ranges) || other.ranges == ranges)&&const DeepCollectionEquality().equals(other.extras, _extras)&&(identical(other.densityGPerMl, densityGPerMl) || other.densityGPerMl == densityGPerMl)&&(identical(other.yieldGroup, yieldGroup) || other.yieldGroup == yieldGroup)&&const DeepCollectionEquality().equals(other.servings, _servings)&&(identical(other.catalogKey, catalogKey) || other.catalogKey == catalogKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,source,sourceRef,nameEn,nameAr,state,verified,catalogVersion,nutrients,ranges,const DeepCollectionEquality().hash(_extras),densityGPerMl,yieldGroup,const DeepCollectionEquality().hash(_servings),catalogKey);
}

@override
String toString() {
    return 'CatalogFood(kind: $kind, source: $source, sourceRef: $sourceRef, nameEn: $nameEn, nameAr: $nameAr, state: $state, verified: $verified, catalogVersion: $catalogVersion, nutrients: $nutrients, ranges: $ranges, extras: $extras, densityGPerMl: $densityGPerMl, yieldGroup: $yieldGroup, servings: $servings, catalogKey: $catalogKey)';
}


}

/// @nodoc
abstract mixin class _$CatalogFoodCopyWith<$Res> implements $CatalogFoodCopyWith<$Res> {
  factory _$CatalogFoodCopyWith(_CatalogFood value, $Res Function(_CatalogFood) _then) = __$CatalogFoodCopyWithImpl;
@override @useResult
$Res call({
 String kind, String source, String? sourceRef, String nameEn, String? nameAr, String state, bool verified, int catalogVersion, CatalogNutrients nutrients, CatalogNutrientRange? ranges, Map<String, double>? extras, double? densityGPerMl, String? yieldGroup, List<CatalogServing> servings, String catalogKey
});


@override $CatalogNutrientsCopyWith<$Res> get nutrients;@override $CatalogNutrientRangeCopyWith<$Res>? get ranges;

}
/// @nodoc
class __$CatalogFoodCopyWithImpl<$Res>
    implements _$CatalogFoodCopyWith<$Res> {
  __$CatalogFoodCopyWithImpl(this._self, this._then);

  final _CatalogFood _self;
  final $Res Function(_CatalogFood) _then;

/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? source = null,Object? sourceRef = freezed,Object? nameEn = null,Object? nameAr = freezed,Object? state = null,Object? verified = null,Object? catalogVersion = null,Object? nutrients = null,Object? ranges = freezed,Object? extras = freezed,Object? densityGPerMl = freezed,Object? yieldGroup = freezed,Object? servings = null,Object? catalogKey = null,}) {
  return _then(_CatalogFood(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sourceRef: freezed == sourceRef ? _self.sourceRef : sourceRef // ignore: cast_nullable_to_non_nullable
as String?,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameAr: freezed == nameAr ? _self.nameAr : nameAr // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,catalogVersion: null == catalogVersion ? _self.catalogVersion : catalogVersion // ignore: cast_nullable_to_non_nullable
as int,nutrients: null == nutrients ? _self.nutrients : nutrients // ignore: cast_nullable_to_non_nullable
as CatalogNutrients,ranges: freezed == ranges ? _self.ranges : ranges // ignore: cast_nullable_to_non_nullable
as CatalogNutrientRange?,extras: freezed == extras ? _self._extras : extras // ignore: cast_nullable_to_non_nullable
as Map<String, double>?,densityGPerMl: freezed == densityGPerMl ? _self.densityGPerMl : densityGPerMl // ignore: cast_nullable_to_non_nullable
as double?,yieldGroup: freezed == yieldGroup ? _self.yieldGroup : yieldGroup // ignore: cast_nullable_to_non_nullable
as String?,servings: null == servings ? _self._servings : servings // ignore: cast_nullable_to_non_nullable
as List<CatalogServing>,catalogKey: null == catalogKey ? _self.catalogKey : catalogKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientsCopyWith<$Res> get nutrients {
  
  return $CatalogNutrientsCopyWith<$Res>(_self.nutrients, (value) {
    return _then(_self.copyWith(nutrients: value));
  });
}/// Create a copy of CatalogFood
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogNutrientRangeCopyWith<$Res>? get ranges {
    if (_self.ranges == null) {
    return null;
  }

  return $CatalogNutrientRangeCopyWith<$Res>(_self.ranges!, (value) {
    return _then(_self.copyWith(ranges: value));
  });
}
}

// dart format on
