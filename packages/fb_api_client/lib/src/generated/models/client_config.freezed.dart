// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientConfig {

/// The oldest app version (`MAJOR.MINOR.PATCH`) the server still serves. Older apps are asked to update (426, S03).
 String get minimumAppVersion;/// Feature flags by name. A flag the app doesn't know is ignored; a missing flag means off.
 Map<String, bool> get featureFlags;/// Numeric client thresholds by name (for example the AI confidence minimum, AI-060). A missing threshold means the app's built-in default.
 Map<String, double> get thresholds;
/// Create a copy of ClientConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClientConfigCopyWith<ClientConfig> get copyWith => _$ClientConfigCopyWithImpl<ClientConfig>(this as ClientConfig, _$identity);

  /// Serializes this ClientConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ClientConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClientConfig&&(identical(other.minimumAppVersion, _this.minimumAppVersion) || other.minimumAppVersion == _this.minimumAppVersion)&&const DeepCollectionEquality().equals(other.featureFlags, _this.featureFlags)&&const DeepCollectionEquality().equals(other.thresholds, _this.thresholds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ClientConfig;
  return Object.hash(runtimeType,_this.minimumAppVersion,const DeepCollectionEquality().hash(_this.featureFlags),const DeepCollectionEquality().hash(_this.thresholds));
}

@override
String toString() {
  final _this = this as ClientConfig;
  return 'ClientConfig(minimumAppVersion: ${_this.minimumAppVersion}, featureFlags: ${_this.featureFlags}, thresholds: ${_this.thresholds})';
}


}

/// @nodoc
abstract mixin class $ClientConfigCopyWith<$Res>  {
  factory $ClientConfigCopyWith(ClientConfig value, $Res Function(ClientConfig) _then) = _$ClientConfigCopyWithImpl;
@useResult
$Res call({
 String minimumAppVersion, Map<String, bool> featureFlags, Map<String, double> thresholds
});




}
/// @nodoc
class _$ClientConfigCopyWithImpl<$Res>
    implements $ClientConfigCopyWith<$Res> {
  _$ClientConfigCopyWithImpl(this._self, this._then);

  final ClientConfig _self;
  final $Res Function(ClientConfig) _then;

/// Create a copy of ClientConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minimumAppVersion = null,Object? featureFlags = null,Object? thresholds = null,}) {
  return _then(ClientConfig(
minimumAppVersion: null == minimumAppVersion ? _self.minimumAppVersion : minimumAppVersion // ignore: cast_nullable_to_non_nullable
as String,featureFlags: null == featureFlags ? _self.featureFlags : featureFlags // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,thresholds: null == thresholds ? _self.thresholds : thresholds // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClientConfig].
extension ClientConfigPatterns on ClientConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClientConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClientConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClientConfig value)  $default,){
final _that = this;
switch (_that) {
case _ClientConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClientConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ClientConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String minimumAppVersion,  Map<String, bool> featureFlags,  Map<String, double> thresholds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClientConfig() when $default != null:
return $default(_that.minimumAppVersion,_that.featureFlags,_that.thresholds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String minimumAppVersion,  Map<String, bool> featureFlags,  Map<String, double> thresholds)  $default,) {final _that = this;
switch (_that) {
case _ClientConfig():
return $default(_that.minimumAppVersion,_that.featureFlags,_that.thresholds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String minimumAppVersion,  Map<String, bool> featureFlags,  Map<String, double> thresholds)?  $default,) {final _that = this;
switch (_that) {
case _ClientConfig() when $default != null:
return $default(_that.minimumAppVersion,_that.featureFlags,_that.thresholds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClientConfig implements ClientConfig {
  const _ClientConfig({required this.minimumAppVersion, required  Map<String, bool> featureFlags, required  Map<String, double> thresholds}): _featureFlags = featureFlags,_thresholds = thresholds;
  factory _ClientConfig.fromJson(Map<String, dynamic> json) => _$ClientConfigFromJson(json);

/// The oldest app version (`MAJOR.MINOR.PATCH`) the server still serves. Older apps are asked to update (426, S03).
@override final  String minimumAppVersion;
/// Feature flags by name. A flag the app doesn't know is ignored; a missing flag means off.
 final  Map<String, bool> _featureFlags;
/// Feature flags by name. A flag the app doesn't know is ignored; a missing flag means off.
@override Map<String, bool> get featureFlags {
  if (_featureFlags is EqualUnmodifiableMapView) return _featureFlags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_featureFlags);
}

/// Numeric client thresholds by name (for example the AI confidence minimum, AI-060). A missing threshold means the app's built-in default.
 final  Map<String, double> _thresholds;
/// Numeric client thresholds by name (for example the AI confidence minimum, AI-060). A missing threshold means the app's built-in default.
@override Map<String, double> get thresholds {
  if (_thresholds is EqualUnmodifiableMapView) return _thresholds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_thresholds);
}


/// Create a copy of ClientConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClientConfigCopyWith<_ClientConfig> get copyWith => __$ClientConfigCopyWithImpl<_ClientConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClientConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClientConfig&&(identical(other.minimumAppVersion, minimumAppVersion) || other.minimumAppVersion == minimumAppVersion)&&const DeepCollectionEquality().equals(other.featureFlags, _featureFlags)&&const DeepCollectionEquality().equals(other.thresholds, _thresholds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,minimumAppVersion,const DeepCollectionEquality().hash(_featureFlags),const DeepCollectionEquality().hash(_thresholds));
}

@override
String toString() {
    return 'ClientConfig(minimumAppVersion: $minimumAppVersion, featureFlags: $featureFlags, thresholds: $thresholds)';
}


}

/// @nodoc
abstract mixin class _$ClientConfigCopyWith<$Res> implements $ClientConfigCopyWith<$Res> {
  factory _$ClientConfigCopyWith(_ClientConfig value, $Res Function(_ClientConfig) _then) = __$ClientConfigCopyWithImpl;
@override @useResult
$Res call({
 String minimumAppVersion, Map<String, bool> featureFlags, Map<String, double> thresholds
});




}
/// @nodoc
class __$ClientConfigCopyWithImpl<$Res>
    implements _$ClientConfigCopyWith<$Res> {
  __$ClientConfigCopyWithImpl(this._self, this._then);

  final _ClientConfig _self;
  final $Res Function(_ClientConfig) _then;

/// Create a copy of ClientConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minimumAppVersion = null,Object? featureFlags = null,Object? thresholds = null,}) {
  return _then(_ClientConfig(
minimumAppVersion: null == minimumAppVersion ? _self.minimumAppVersion : minimumAppVersion // ignore: cast_nullable_to_non_nullable
as String,featureFlags: null == featureFlags ? _self._featureFlags : featureFlags // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,thresholds: null == thresholds ? _self._thresholds : thresholds // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}

// dart format on
