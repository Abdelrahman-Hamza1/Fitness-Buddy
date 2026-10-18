// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'email_challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmailChallenge {

 String get challengeId; DateTime get expiresAt;
/// Create a copy of EmailChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailChallengeCopyWith<EmailChallenge> get copyWith => _$EmailChallengeCopyWithImpl<EmailChallenge>(this as EmailChallenge, _$identity);

  /// Serializes this EmailChallenge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmailChallenge;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailChallenge&&(identical(other.challengeId, _this.challengeId) || other.challengeId == _this.challengeId)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmailChallenge;
  return Object.hash(runtimeType,_this.challengeId,_this.expiresAt);
}

@override
String toString() {
  final _this = this as EmailChallenge;
  return 'EmailChallenge(challengeId: ${_this.challengeId}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $EmailChallengeCopyWith<$Res>  {
  factory $EmailChallengeCopyWith(EmailChallenge value, $Res Function(EmailChallenge) _then) = _$EmailChallengeCopyWithImpl;
@useResult
$Res call({
 String challengeId, DateTime expiresAt
});




}
/// @nodoc
class _$EmailChallengeCopyWithImpl<$Res>
    implements $EmailChallengeCopyWith<$Res> {
  _$EmailChallengeCopyWithImpl(this._self, this._then);

  final EmailChallenge _self;
  final $Res Function(EmailChallenge) _then;

/// Create a copy of EmailChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? challengeId = null,Object? expiresAt = null,}) {
  return _then(EmailChallenge(
challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EmailChallenge].
extension EmailChallengePatterns on EmailChallenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmailChallenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmailChallenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmailChallenge value)  $default,){
final _that = this;
switch (_that) {
case _EmailChallenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmailChallenge value)?  $default,){
final _that = this;
switch (_that) {
case _EmailChallenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String challengeId,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmailChallenge() when $default != null:
return $default(_that.challengeId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String challengeId,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _EmailChallenge():
return $default(_that.challengeId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String challengeId,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _EmailChallenge() when $default != null:
return $default(_that.challengeId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmailChallenge implements EmailChallenge {
  const _EmailChallenge({required this.challengeId, required this.expiresAt});
  factory _EmailChallenge.fromJson(Map<String, dynamic> json) => _$EmailChallengeFromJson(json);

@override final  String challengeId;
@override final  DateTime expiresAt;

/// Create a copy of EmailChallenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmailChallengeCopyWith<_EmailChallenge> get copyWith => __$EmailChallengeCopyWithImpl<_EmailChallenge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmailChallengeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmailChallenge&&(identical(other.challengeId, challengeId) || other.challengeId == challengeId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,challengeId,expiresAt);
}

@override
String toString() {
    return 'EmailChallenge(challengeId: $challengeId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$EmailChallengeCopyWith<$Res> implements $EmailChallengeCopyWith<$Res> {
  factory _$EmailChallengeCopyWith(_EmailChallenge value, $Res Function(_EmailChallenge) _then) = __$EmailChallengeCopyWithImpl;
@override @useResult
$Res call({
 String challengeId, DateTime expiresAt
});




}
/// @nodoc
class __$EmailChallengeCopyWithImpl<$Res>
    implements _$EmailChallengeCopyWith<$Res> {
  __$EmailChallengeCopyWithImpl(this._self, this._then);

  final _EmailChallenge _self;
  final $Res Function(_EmailChallenge) _then;

/// Create a copy of EmailChallenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? challengeId = null,Object? expiresAt = null,}) {
  return _then(_EmailChallenge(
challengeId: null == challengeId ? _self.challengeId : challengeId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
