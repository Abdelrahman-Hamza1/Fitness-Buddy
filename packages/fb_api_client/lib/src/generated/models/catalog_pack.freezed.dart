// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogPack {

 int get version; String get url; String get sha256; int get sizeBytes; int get schemaVersion;
/// Create a copy of CatalogPack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogPackCopyWith<CatalogPack> get copyWith => _$CatalogPackCopyWithImpl<CatalogPack>(this as CatalogPack, _$identity);

  /// Serializes this CatalogPack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatalogPack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogPack&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatalogPack;
  return Object.hash(runtimeType,_this.version,_this.url,_this.sha256,_this.sizeBytes,_this.schemaVersion);
}

@override
String toString() {
  final _this = this as CatalogPack;
  return 'CatalogPack(version: ${_this.version}, url: ${_this.url}, sha256: ${_this.sha256}, sizeBytes: ${_this.sizeBytes}, schemaVersion: ${_this.schemaVersion})';
}


}

/// @nodoc
abstract mixin class $CatalogPackCopyWith<$Res>  {
  factory $CatalogPackCopyWith(CatalogPack value, $Res Function(CatalogPack) _then) = _$CatalogPackCopyWithImpl;
@useResult
$Res call({
 int version, String url, String sha256, int sizeBytes, int schemaVersion
});




}
/// @nodoc
class _$CatalogPackCopyWithImpl<$Res>
    implements $CatalogPackCopyWith<$Res> {
  _$CatalogPackCopyWithImpl(this._self, this._then);

  final CatalogPack _self;
  final $Res Function(CatalogPack) _then;

/// Create a copy of CatalogPack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? url = null,Object? sha256 = null,Object? sizeBytes = null,Object? schemaVersion = null,}) {
  return _then(CatalogPack(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogPack].
extension CatalogPackPatterns on CatalogPack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogPack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogPack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogPack value)  $default,){
final _that = this;
switch (_that) {
case _CatalogPack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogPack value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogPack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  String url,  String sha256,  int sizeBytes,  int schemaVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogPack() when $default != null:
return $default(_that.version,_that.url,_that.sha256,_that.sizeBytes,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  String url,  String sha256,  int sizeBytes,  int schemaVersion)  $default,) {final _that = this;
switch (_that) {
case _CatalogPack():
return $default(_that.version,_that.url,_that.sha256,_that.sizeBytes,_that.schemaVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  String url,  String sha256,  int sizeBytes,  int schemaVersion)?  $default,) {final _that = this;
switch (_that) {
case _CatalogPack() when $default != null:
return $default(_that.version,_that.url,_that.sha256,_that.sizeBytes,_that.schemaVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogPack implements CatalogPack {
  const _CatalogPack({required this.version, required this.url, required this.sha256, required this.sizeBytes, required this.schemaVersion});
  factory _CatalogPack.fromJson(Map<String, dynamic> json) => _$CatalogPackFromJson(json);

@override final  int version;
@override final  String url;
@override final  String sha256;
@override final  int sizeBytes;
@override final  int schemaVersion;

/// Create a copy of CatalogPack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogPackCopyWith<_CatalogPack> get copyWith => __$CatalogPackCopyWithImpl<_CatalogPack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogPackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogPack&&(identical(other.version, version) || other.version == version)&&(identical(other.url, url) || other.url == url)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,url,sha256,sizeBytes,schemaVersion);
}

@override
String toString() {
    return 'CatalogPack(version: $version, url: $url, sha256: $sha256, sizeBytes: $sizeBytes, schemaVersion: $schemaVersion)';
}


}

/// @nodoc
abstract mixin class _$CatalogPackCopyWith<$Res> implements $CatalogPackCopyWith<$Res> {
  factory _$CatalogPackCopyWith(_CatalogPack value, $Res Function(_CatalogPack) _then) = __$CatalogPackCopyWithImpl;
@override @useResult
$Res call({
 int version, String url, String sha256, int sizeBytes, int schemaVersion
});




}
/// @nodoc
class __$CatalogPackCopyWithImpl<$Res>
    implements _$CatalogPackCopyWith<$Res> {
  __$CatalogPackCopyWithImpl(this._self, this._then);

  final _CatalogPack _self;
  final $Res Function(_CatalogPack) _then;

/// Create a copy of CatalogPack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? url = null,Object? sha256 = null,Object? sizeBytes = null,Object? schemaVersion = null,}) {
  return _then(_CatalogPack(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
