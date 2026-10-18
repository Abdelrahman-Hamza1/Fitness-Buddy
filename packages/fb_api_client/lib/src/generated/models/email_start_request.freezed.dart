// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'email_start_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmailStartRequest {

 String get email; String get purpose;
/// Create a copy of EmailStartRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailStartRequestCopyWith<EmailStartRequest> get copyWith => _$EmailStartRequestCopyWithImpl<EmailStartRequest>(this as EmailStartRequest, _$identity);

  /// Serializes this EmailStartRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmailStartRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailStartRequest&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.purpose, _this.purpose) || other.purpose == _this.purpose));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmailStartRequest;
  return Object.hash(runtimeType,_this.email,_this.purpose);
}

@override
String toString() {
  final _this = this as EmailStartRequest;
  return 'EmailStartRequest(email: ${_this.email}, purpose: ${_this.purpose})';
}


}

/// @nodoc
abstract mixin class $EmailStartRequestCopyWith<$Res>  {
  factory $EmailStartRequestCopyWith(EmailStartRequest value, $Res Function(EmailStartRequest) _then) = _$EmailStartRequestCopyWithImpl;
@useResult
$Res call({
 String email, String purpose
});




}
/// @nodoc
class _$EmailStartRequestCopyWithImpl<$Res>
    implements $EmailStartRequestCopyWith<$Res> {
  _$EmailStartRequestCopyWithImpl(this._self, this._then);

  final EmailStartRequest _self;
  final $Res Function(EmailStartRequest) _then;

/// Create a copy of EmailStartRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? purpose = null,}) {
  return _then(EmailStartRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmailStartRequest].
extension EmailStartRequestPatterns on EmailStartRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmailStartRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmailStartRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmailStartRequest value)  $default,){
final _that = this;
switch (_that) {
case _EmailStartRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmailStartRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EmailStartRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String purpose)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmailStartRequest() when $default != null:
return $default(_that.email,_that.purpose);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String purpose)  $default,) {final _that = this;
switch (_that) {
case _EmailStartRequest():
return $default(_that.email,_that.purpose);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String purpose)?  $default,) {final _that = this;
switch (_that) {
case _EmailStartRequest() when $default != null:
return $default(_that.email,_that.purpose);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmailStartRequest implements EmailStartRequest {
  const _EmailStartRequest({required this.email, required this.purpose});
  factory _EmailStartRequest.fromJson(Map<String, dynamic> json) => _$EmailStartRequestFromJson(json);

@override final  String email;
@override final  String purpose;

/// Create a copy of EmailStartRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmailStartRequestCopyWith<_EmailStartRequest> get copyWith => __$EmailStartRequestCopyWithImpl<_EmailStartRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmailStartRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailStartRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.purpose, purpose) || other.purpose == purpose));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,email,purpose);
}

@override
String toString() {
    return 'EmailStartRequest(email: $email, purpose: $purpose)';
}


}

/// @nodoc
abstract mixin class _$EmailStartRequestCopyWith<$Res> implements $EmailStartRequestCopyWith<$Res> {
  factory _$EmailStartRequestCopyWith(_EmailStartRequest value, $Res Function(_EmailStartRequest) _then) = __$EmailStartRequestCopyWithImpl;
@override @useResult
$Res call({
 String email, String purpose
});




}
/// @nodoc
class __$EmailStartRequestCopyWithImpl<$Res>
    implements _$EmailStartRequestCopyWith<$Res> {
  __$EmailStartRequestCopyWithImpl(this._self, this._then);

  final _EmailStartRequest _self;
  final $Res Function(_EmailStartRequest) _then;

/// Create a copy of EmailStartRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? purpose = null,}) {
  return _then(_EmailStartRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
