// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'link_identity_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinkIdentityRequest {

 String? get idToken; String? get challengeId; String? get code;
/// Create a copy of LinkIdentityRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkIdentityRequestCopyWith<LinkIdentityRequest> get copyWith => _$LinkIdentityRequestCopyWithImpl<LinkIdentityRequest>(this as LinkIdentityRequest, _$identity);

  /// Serializes this LinkIdentityRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LinkIdentityRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkIdentityRequest&&(identical(other.idToken, _this.idToken) || other.idToken == _this.idToken)&&(identical(other.challengeId, _this.challengeId) || other.challengeId == _this.challengeId)&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LinkIdentityRequest;
  return Object.hash(runtimeType,_this.idToken,_this.challengeId,_this.code);
}

@override
String toString() {
  final _this = this as LinkIdentityRequest;
  return 'LinkIdentityRequest(idToken: ${_this.idToken}, challengeId: ${_this.challengeId}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $LinkIdentityRequestCopyWith<$Res>  {
  factory $LinkIdentityRequestCopyWith(LinkIdentityRequest value, $Res Function(LinkIdentityRequest) _then) = _$LinkIdentityRequestCopyWithImpl;
@useResult
$Res call({
 String? idToken, String? challengeId, String? code
});




}
/// @nodoc
class _$LinkIdentityRequestCopyWithImpl<$Res>
    implements $LinkIdentityRequestCopyWith<$Res> {
  _$LinkIdentityRequestCopyWithImpl(this._self, this._then);

  final LinkIdentityRequest _self;
  final $Res Function(LinkIdentityRequest) _then;

/// Create a copy of LinkIdentityRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idToken = freezed,Object? challengeId = freezed,Object? code = freezed,}) {
  return _then(LinkIdentityRequest(
idToken: freezed == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String?,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkIdentityRequest].
extension LinkIdentityRequestPatterns on LinkIdentityRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkIdentityRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkIdentityRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkIdentityRequest value)  $default,){
final _that = this;
switch (_that) {
case _LinkIdentityRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkIdentityRequest value)?  $default,){
final _that = this;
switch (_that) {
case _LinkIdentityRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? idToken,  String? challengeId,  String? code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkIdentityRequest() when $default != null:
return $default(_that.idToken,_that.challengeId,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? idToken,  String? challengeId,  String? code)  $default,) {final _that = this;
switch (_that) {
case _LinkIdentityRequest():
return $default(_that.idToken,_that.challengeId,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? idToken,  String? challengeId,  String? code)?  $default,) {final _that = this;
switch (_that) {
case _LinkIdentityRequest() when $default != null:
return $default(_that.idToken,_that.challengeId,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkIdentityRequest implements LinkIdentityRequest {
  const _LinkIdentityRequest({required this.idToken, required this.challengeId, required this.code});
  factory _LinkIdentityRequest.fromJson(Map<String, dynamic> json) => _$LinkIdentityRequestFromJson(json);

@override final  String? idToken;
@override final  String? challengeId;
@override final  String? code;

/// Create a copy of LinkIdentityRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkIdentityRequestCopyWith<_LinkIdentityRequest> get copyWith => __$LinkIdentityRequestCopyWithImpl<_LinkIdentityRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkIdentityRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkIdentityRequest&&(identical(other.idToken, idToken) || other.idToken == idToken)&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,idToken,challengeId,code);
}

@override
String toString() {
    return 'LinkIdentityRequest(idToken: $idToken, challengeId: $challengeId, code: $code)';
}


}

/// @nodoc
abstract mixin class _$LinkIdentityRequestCopyWith<$Res> implements $LinkIdentityRequestCopyWith<$Res> {
  factory _$LinkIdentityRequestCopyWith(_LinkIdentityRequest value, $Res Function(_LinkIdentityRequest) _then) = __$LinkIdentityRequestCopyWithImpl;
@override @useResult
$Res call({
 String? idToken, String? challengeId, String? code
});




}
/// @nodoc
class __$LinkIdentityRequestCopyWithImpl<$Res>
    implements _$LinkIdentityRequestCopyWith<$Res> {
  __$LinkIdentityRequestCopyWithImpl(this._self, this._then);

  final _LinkIdentityRequest _self;
  final $Res Function(_LinkIdentityRequest) _then;

/// Create a copy of LinkIdentityRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idToken = freezed,Object? challengeId = freezed,Object? code = freezed,}) {
  return _then(_LinkIdentityRequest(
idToken: freezed == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String?,challengeId: freezed == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
