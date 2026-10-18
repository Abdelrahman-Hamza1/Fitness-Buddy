// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'json_web_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JsonWebKey {

 String get kty; String get crv; String get kid; String get x; String get y; String get alg; String get use;
/// Create a copy of JsonWebKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JsonWebKeyCopyWith<JsonWebKey> get copyWith => _$JsonWebKeyCopyWithImpl<JsonWebKey>(this as JsonWebKey, _$identity);

  /// Serializes this JsonWebKey to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JsonWebKey;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JsonWebKey&&(identical(other.kty, _this.kty) || other.kty == _this.kty)&&(identical(other.crv, _this.crv) || other.crv == _this.crv)&&(identical(other.kid, _this.kid) || other.kid == _this.kid)&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y)&&(identical(other.alg, _this.alg) || other.alg == _this.alg)&&(identical(other.use, _this.use) || other.use == _this.use));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JsonWebKey;
  return Object.hash(runtimeType,_this.kty,_this.crv,_this.kid,_this.x,_this.y,_this.alg,_this.use);
}

@override
String toString() {
  final _this = this as JsonWebKey;
  return 'JsonWebKey(kty: ${_this.kty}, crv: ${_this.crv}, kid: ${_this.kid}, x: ${_this.x}, y: ${_this.y}, alg: ${_this.alg}, use: ${_this.use})';
}


}

/// @nodoc
abstract mixin class $JsonWebKeyCopyWith<$Res>  {
  factory $JsonWebKeyCopyWith(JsonWebKey value, $Res Function(JsonWebKey) _then) = _$JsonWebKeyCopyWithImpl;
@useResult
$Res call({
 String kty, String crv, String kid, String x, String y, String alg, String use
});




}
/// @nodoc
class _$JsonWebKeyCopyWithImpl<$Res>
    implements $JsonWebKeyCopyWith<$Res> {
  _$JsonWebKeyCopyWithImpl(this._self, this._then);

  final JsonWebKey _self;
  final $Res Function(JsonWebKey) _then;

/// Create a copy of JsonWebKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kty = null,Object? crv = null,Object? kid = null,Object? x = null,Object? y = null,Object? alg = null,Object? use = null,}) {
  return _then(JsonWebKey(
kty: null == kty ? _self.kty : kty // ignore: cast_nullable_to_non_nullable
as String,crv: null == crv ? _self.crv : crv // ignore: cast_nullable_to_non_nullable
as String,kid: null == kid ? _self.kid : kid // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as String,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as String,alg: null == alg ? _self.alg : alg // ignore: cast_nullable_to_non_nullable
as String,use: null == use ? _self.use : use // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JsonWebKey].
extension JsonWebKeyPatterns on JsonWebKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JsonWebKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JsonWebKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JsonWebKey value)  $default,){
final _that = this;
switch (_that) {
case _JsonWebKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JsonWebKey value)?  $default,){
final _that = this;
switch (_that) {
case _JsonWebKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kty,  String crv,  String kid,  String x,  String y,  String alg,  String use)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JsonWebKey() when $default != null:
return $default(_that.kty,_that.crv,_that.kid,_that.x,_that.y,_that.alg,_that.use);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kty,  String crv,  String kid,  String x,  String y,  String alg,  String use)  $default,) {final _that = this;
switch (_that) {
case _JsonWebKey():
return $default(_that.kty,_that.crv,_that.kid,_that.x,_that.y,_that.alg,_that.use);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kty,  String crv,  String kid,  String x,  String y,  String alg,  String use)?  $default,) {final _that = this;
switch (_that) {
case _JsonWebKey() when $default != null:
return $default(_that.kty,_that.crv,_that.kid,_that.x,_that.y,_that.alg,_that.use);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JsonWebKey implements JsonWebKey {
  const _JsonWebKey({required this.kty, required this.crv, required this.kid, required this.x, required this.y, required this.alg, required this.use});
  factory _JsonWebKey.fromJson(Map<String, dynamic> json) => _$JsonWebKeyFromJson(json);

@override final  String kty;
@override final  String crv;
@override final  String kid;
@override final  String x;
@override final  String y;
@override final  String alg;
@override final  String use;

/// Create a copy of JsonWebKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JsonWebKeyCopyWith<_JsonWebKey> get copyWith => __$JsonWebKeyCopyWithImpl<_JsonWebKey>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JsonWebKeyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JsonWebKey&&(identical(other.kty, kty) || other.kty == kty)&&(identical(other.crv, crv) || other.crv == crv)&&(identical(other.kid, kid) || other.kid == kid)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.alg, alg) || other.alg == alg)&&(identical(other.use, use) || other.use == use));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kty,crv,kid,x,y,alg,use);
}

@override
String toString() {
    return 'JsonWebKey(kty: $kty, crv: $crv, kid: $kid, x: $x, y: $y, alg: $alg, use: $use)';
}


}

/// @nodoc
abstract mixin class _$JsonWebKeyCopyWith<$Res> implements $JsonWebKeyCopyWith<$Res> {
  factory _$JsonWebKeyCopyWith(_JsonWebKey value, $Res Function(_JsonWebKey) _then) = __$JsonWebKeyCopyWithImpl;
@override @useResult
$Res call({
 String kty, String crv, String kid, String x, String y, String alg, String use
});




}
/// @nodoc
class __$JsonWebKeyCopyWithImpl<$Res>
    implements _$JsonWebKeyCopyWith<$Res> {
  __$JsonWebKeyCopyWithImpl(this._self, this._then);

  final _JsonWebKey _self;
  final $Res Function(_JsonWebKey) _then;

/// Create a copy of JsonWebKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kty = null,Object? crv = null,Object? kid = null,Object? x = null,Object? y = null,Object? alg = null,Object? use = null,}) {
  return _then(_JsonWebKey(
kty: null == kty ? _self.kty : kty // ignore: cast_nullable_to_non_nullable
as String,crv: null == crv ? _self.crv : crv // ignore: cast_nullable_to_non_nullable
as String,kid: null == kid ? _self.kid : kid // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as String,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as String,alg: null == alg ? _self.alg : alg // ignore: cast_nullable_to_non_nullable
as String,use: null == use ? _self.use : use // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
