// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'current_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurrentAccount {

 String get userId; bool get isAnonymous; String get status;
/// Create a copy of CurrentAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrentAccountCopyWith<CurrentAccount> get copyWith => _$CurrentAccountCopyWithImpl<CurrentAccount>(this as CurrentAccount, _$identity);

  /// Serializes this CurrentAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CurrentAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrentAccount&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.isAnonymous, _this.isAnonymous) || other.isAnonymous == _this.isAnonymous)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CurrentAccount;
  return Object.hash(runtimeType,_this.userId,_this.isAnonymous,_this.status);
}

@override
String toString() {
  final _this = this as CurrentAccount;
  return 'CurrentAccount(userId: ${_this.userId}, isAnonymous: ${_this.isAnonymous}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $CurrentAccountCopyWith<$Res>  {
  factory $CurrentAccountCopyWith(CurrentAccount value, $Res Function(CurrentAccount) _then) = _$CurrentAccountCopyWithImpl;
@useResult
$Res call({
 String userId, bool isAnonymous, String status
});




}
/// @nodoc
class _$CurrentAccountCopyWithImpl<$Res>
    implements $CurrentAccountCopyWith<$Res> {
  _$CurrentAccountCopyWithImpl(this._self, this._then);

  final CurrentAccount _self;
  final $Res Function(CurrentAccount) _then;

/// Create a copy of CurrentAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? isAnonymous = null,Object? status = null,}) {
  return _then(CurrentAccount(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrentAccount].
extension CurrentAccountPatterns on CurrentAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrentAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrentAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrentAccount value)  $default,){
final _that = this;
switch (_that) {
case _CurrentAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrentAccount value)?  $default,){
final _that = this;
switch (_that) {
case _CurrentAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  bool isAnonymous,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrentAccount() when $default != null:
return $default(_that.userId,_that.isAnonymous,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  bool isAnonymous,  String status)  $default,) {final _that = this;
switch (_that) {
case _CurrentAccount():
return $default(_that.userId,_that.isAnonymous,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  bool isAnonymous,  String status)?  $default,) {final _that = this;
switch (_that) {
case _CurrentAccount() when $default != null:
return $default(_that.userId,_that.isAnonymous,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CurrentAccount implements CurrentAccount {
  const _CurrentAccount({required this.userId, required this.isAnonymous, required this.status});
  factory _CurrentAccount.fromJson(Map<String, dynamic> json) => _$CurrentAccountFromJson(json);

@override final  String userId;
@override final  bool isAnonymous;
@override final  String status;

/// Create a copy of CurrentAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrentAccountCopyWith<_CurrentAccount> get copyWith => __$CurrentAccountCopyWithImpl<_CurrentAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurrentAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrentAccount&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,isAnonymous,status);
}

@override
String toString() {
    return 'CurrentAccount(userId: $userId, isAnonymous: $isAnonymous, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CurrentAccountCopyWith<$Res> implements $CurrentAccountCopyWith<$Res> {
  factory _$CurrentAccountCopyWith(_CurrentAccount value, $Res Function(_CurrentAccount) _then) = __$CurrentAccountCopyWithImpl;
@override @useResult
$Res call({
 String userId, bool isAnonymous, String status
});




}
/// @nodoc
class __$CurrentAccountCopyWithImpl<$Res>
    implements _$CurrentAccountCopyWith<$Res> {
  __$CurrentAccountCopyWithImpl(this._self, this._then);

  final _CurrentAccount _self;
  final $Res Function(_CurrentAccount) _then;

/// Create a copy of CurrentAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? isAnonymous = null,Object? status = null,}) {
  return _then(_CurrentAccount(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
