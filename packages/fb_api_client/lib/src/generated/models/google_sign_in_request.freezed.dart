// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'google_sign_in_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoogleSignInRequest {

 String get idToken;
/// Create a copy of GoogleSignInRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoogleSignInRequestCopyWith<GoogleSignInRequest> get copyWith => _$GoogleSignInRequestCopyWithImpl<GoogleSignInRequest>(this as GoogleSignInRequest, _$identity);

  /// Serializes this GoogleSignInRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GoogleSignInRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoogleSignInRequest&&(identical(other.idToken, _this.idToken) || other.idToken == _this.idToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GoogleSignInRequest;
  return Object.hash(runtimeType,_this.idToken);
}

@override
String toString() {
  final _this = this as GoogleSignInRequest;
  return 'GoogleSignInRequest(idToken: ${_this.idToken})';
}


}

/// @nodoc
abstract mixin class $GoogleSignInRequestCopyWith<$Res>  {
  factory $GoogleSignInRequestCopyWith(GoogleSignInRequest value, $Res Function(GoogleSignInRequest) _then) = _$GoogleSignInRequestCopyWithImpl;
@useResult
$Res call({
 String idToken
});




}
/// @nodoc
class _$GoogleSignInRequestCopyWithImpl<$Res>
    implements $GoogleSignInRequestCopyWith<$Res> {
  _$GoogleSignInRequestCopyWithImpl(this._self, this._then);

  final GoogleSignInRequest _self;
  final $Res Function(GoogleSignInRequest) _then;

/// Create a copy of GoogleSignInRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idToken = null,}) {
  return _then(GoogleSignInRequest(
idToken: null == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GoogleSignInRequest].
extension GoogleSignInRequestPatterns on GoogleSignInRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoogleSignInRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoogleSignInRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoogleSignInRequest value)  $default,){
final _that = this;
switch (_that) {
case _GoogleSignInRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoogleSignInRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GoogleSignInRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String idToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoogleSignInRequest() when $default != null:
return $default(_that.idToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String idToken)  $default,) {final _that = this;
switch (_that) {
case _GoogleSignInRequest():
return $default(_that.idToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String idToken)?  $default,) {final _that = this;
switch (_that) {
case _GoogleSignInRequest() when $default != null:
return $default(_that.idToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoogleSignInRequest implements GoogleSignInRequest {
  const _GoogleSignInRequest({required this.idToken});
  factory _GoogleSignInRequest.fromJson(Map<String, dynamic> json) => _$GoogleSignInRequestFromJson(json);

@override final  String idToken;

/// Create a copy of GoogleSignInRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoogleSignInRequestCopyWith<_GoogleSignInRequest> get copyWith => __$GoogleSignInRequestCopyWithImpl<_GoogleSignInRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoogleSignInRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoogleSignInRequest&&(identical(other.idToken, idToken) || other.idToken == idToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,idToken);
}

@override
String toString() {
    return 'GoogleSignInRequest(idToken: $idToken)';
}


}

/// @nodoc
abstract mixin class _$GoogleSignInRequestCopyWith<$Res> implements $GoogleSignInRequestCopyWith<$Res> {
  factory _$GoogleSignInRequestCopyWith(_GoogleSignInRequest value, $Res Function(_GoogleSignInRequest) _then) = __$GoogleSignInRequestCopyWithImpl;
@override @useResult
$Res call({
 String idToken
});




}
/// @nodoc
class __$GoogleSignInRequestCopyWithImpl<$Res>
    implements _$GoogleSignInRequestCopyWith<$Res> {
  __$GoogleSignInRequestCopyWithImpl(this._self, this._then);

  final _GoogleSignInRequest _self;
  final $Res Function(_GoogleSignInRequest) _then;

/// Create a copy of GoogleSignInRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idToken = null,}) {
  return _then(_GoogleSignInRequest(
idToken: null == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
