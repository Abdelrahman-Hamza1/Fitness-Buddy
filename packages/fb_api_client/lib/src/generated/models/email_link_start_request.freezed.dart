// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'email_link_start_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmailLinkStartRequest {

 String get email;
/// Create a copy of EmailLinkStartRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailLinkStartRequestCopyWith<EmailLinkStartRequest> get copyWith => _$EmailLinkStartRequestCopyWithImpl<EmailLinkStartRequest>(this as EmailLinkStartRequest, _$identity);

  /// Serializes this EmailLinkStartRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmailLinkStartRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailLinkStartRequest&&(identical(other.email, _this.email) || other.email == _this.email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmailLinkStartRequest;
  return Object.hash(runtimeType,_this.email);
}

@override
String toString() {
  final _this = this as EmailLinkStartRequest;
  return 'EmailLinkStartRequest(email: ${_this.email})';
}


}

/// @nodoc
abstract mixin class $EmailLinkStartRequestCopyWith<$Res>  {
  factory $EmailLinkStartRequestCopyWith(EmailLinkStartRequest value, $Res Function(EmailLinkStartRequest) _then) = _$EmailLinkStartRequestCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$EmailLinkStartRequestCopyWithImpl<$Res>
    implements $EmailLinkStartRequestCopyWith<$Res> {
  _$EmailLinkStartRequestCopyWithImpl(this._self, this._then);

  final EmailLinkStartRequest _self;
  final $Res Function(EmailLinkStartRequest) _then;

/// Create a copy of EmailLinkStartRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,}) {
  return _then(EmailLinkStartRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmailLinkStartRequest].
extension EmailLinkStartRequestPatterns on EmailLinkStartRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmailLinkStartRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmailLinkStartRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmailLinkStartRequest value)  $default,){
final _that = this;
switch (_that) {
case _EmailLinkStartRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmailLinkStartRequest value)?  $default,){
final _that = this;
switch (_that) {
case _EmailLinkStartRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmailLinkStartRequest() when $default != null:
return $default(_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email)  $default,) {final _that = this;
switch (_that) {
case _EmailLinkStartRequest():
return $default(_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email)?  $default,) {final _that = this;
switch (_that) {
case _EmailLinkStartRequest() when $default != null:
return $default(_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmailLinkStartRequest implements EmailLinkStartRequest {
  const _EmailLinkStartRequest({required this.email});
  factory _EmailLinkStartRequest.fromJson(Map<String, dynamic> json) => _$EmailLinkStartRequestFromJson(json);

@override final  String email;

/// Create a copy of EmailLinkStartRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmailLinkStartRequestCopyWith<_EmailLinkStartRequest> get copyWith => __$EmailLinkStartRequestCopyWithImpl<_EmailLinkStartRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmailLinkStartRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailLinkStartRequest&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,email);
}

@override
String toString() {
    return 'EmailLinkStartRequest(email: $email)';
}


}

/// @nodoc
abstract mixin class _$EmailLinkStartRequestCopyWith<$Res> implements $EmailLinkStartRequestCopyWith<$Res> {
  factory _$EmailLinkStartRequestCopyWith(_EmailLinkStartRequest value, $Res Function(_EmailLinkStartRequest) _then) = __$EmailLinkStartRequestCopyWithImpl;
@override @useResult
$Res call({
 String email
});




}
/// @nodoc
class __$EmailLinkStartRequestCopyWithImpl<$Res>
    implements _$EmailLinkStartRequestCopyWith<$Res> {
  __$EmailLinkStartRequestCopyWithImpl(this._self, this._then);

  final _EmailLinkStartRequest _self;
  final $Res Function(_EmailLinkStartRequest) _then;

/// Create a copy of EmailLinkStartRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_EmailLinkStartRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
