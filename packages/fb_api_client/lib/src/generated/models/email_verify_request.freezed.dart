// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'email_verify_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmailVerifyRequest {

 String get challengeId; String get code;
/// Create a copy of EmailVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailVerifyRequestCopyWith<EmailVerifyRequest> get copyWith => _$EmailVerifyRequestCopyWithImpl<EmailVerifyRequest>(this as EmailVerifyRequest, _$identity);

  /// Serializes this EmailVerifyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmailVerifyRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailVerifyRequest&&(identical(other.challengeId, _this.challengeId) || other.challengeId == _this.challengeId)&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmailVerifyRequest;
  return Object.hash(runtimeType,_this.challengeId,_this.code);
}

@override
String toString() {
  final _this = this as EmailVerifyRequest;
  return 'EmailVerifyRequest(challengeId: ${_this.challengeId}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $EmailVerifyRequestCopyWith<$Res>  {
  factory $EmailVerifyRequestCopyWith(EmailVerifyRequest value, $Res Function(EmailVerifyRequest) _then) = _$EmailVerifyRequestCopyWithImpl;
@useResult
$Res call({
 String challengeId, String code
});




}
/// @nodoc
class _$EmailVerifyRequestCopyWithImpl<$Res>
    implements $EmailVerifyRequestCopyWith<$Res> {
  _$EmailVerifyRequestCopyWithImpl(this._self, this._then);

  final EmailVerifyRequest _self;
  final $Res Function(EmailVerifyRequest) _then;

/// Create a copy of EmailVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeId = null,Object? code = null,}) {
  return _then(EmailVerifyRequest(
challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmailVerifyRequest].
extension EmailVerifyRequestPatterns on EmailVerifyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmailVerifyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmailVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmailVerifyRequest value)  $default,){
final _that = this;
switch (_that) {
case _EmailVerifyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmailVerifyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EmailVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String challengeId,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmailVerifyRequest() when $default != null:
return $default(_that.challengeId,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String challengeId,  String code)  $default,) {final _that = this;
switch (_that) {
case _EmailVerifyRequest():
return $default(_that.challengeId,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String challengeId,  String code)?  $default,) {final _that = this;
switch (_that) {
case _EmailVerifyRequest() when $default != null:
return $default(_that.challengeId,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmailVerifyRequest implements EmailVerifyRequest {
  const _EmailVerifyRequest({required this.challengeId, required this.code});
  factory _EmailVerifyRequest.fromJson(Map<String, dynamic> json) => _$EmailVerifyRequestFromJson(json);

@override final  String challengeId;
@override final  String code;

/// Create a copy of EmailVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmailVerifyRequestCopyWith<_EmailVerifyRequest> get copyWith => __$EmailVerifyRequestCopyWithImpl<_EmailVerifyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmailVerifyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailVerifyRequest&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,challengeId,code);
}

@override
String toString() {
    return 'EmailVerifyRequest(challengeId: $challengeId, code: $code)';
}


}

/// @nodoc
abstract mixin class _$EmailVerifyRequestCopyWith<$Res> implements $EmailVerifyRequestCopyWith<$Res> {
  factory _$EmailVerifyRequestCopyWith(_EmailVerifyRequest value, $Res Function(_EmailVerifyRequest) _then) = __$EmailVerifyRequestCopyWithImpl;
@override @useResult
$Res call({
 String challengeId, String code
});




}
/// @nodoc
class __$EmailVerifyRequestCopyWithImpl<$Res>
    implements _$EmailVerifyRequestCopyWith<$Res> {
  __$EmailVerifyRequestCopyWithImpl(this._self, this._then);

  final _EmailVerifyRequest _self;
  final $Res Function(_EmailVerifyRequest) _then;

/// Create a copy of EmailVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeId = null,Object? code = null,}) {
  return _then(_EmailVerifyRequest(
challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
