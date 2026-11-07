// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_unsupported_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyUnsupportedResult {

 BuddyUnsupportedResultName get name; String get callId; bool get ok; BuddyPhoneToolError? get error;
/// Create a copy of BuddyUnsupportedResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyUnsupportedResultCopyWith<BuddyUnsupportedResult> get copyWith => _$BuddyUnsupportedResultCopyWithImpl<BuddyUnsupportedResult>(this as BuddyUnsupportedResult, _$identity);

  /// Serializes this BuddyUnsupportedResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyUnsupportedResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyUnsupportedResult&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyUnsupportedResult;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.ok,_this.error);
}

@override
String toString() {
  final _this = this as BuddyUnsupportedResult;
  return 'BuddyUnsupportedResult(name: ${_this.name}, callId: ${_this.callId}, ok: ${_this.ok}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $BuddyUnsupportedResultCopyWith<$Res>  {
  factory $BuddyUnsupportedResultCopyWith(BuddyUnsupportedResult value, $Res Function(BuddyUnsupportedResult) _then) = _$BuddyUnsupportedResultCopyWithImpl;
@useResult
$Res call({
 BuddyUnsupportedResultName name, String callId, bool ok, BuddyPhoneToolError? error
});




}
/// @nodoc
class _$BuddyUnsupportedResultCopyWithImpl<$Res>
    implements $BuddyUnsupportedResultCopyWith<$Res> {
  _$BuddyUnsupportedResultCopyWithImpl(this._self, this._then);

  final BuddyUnsupportedResult _self;
  final $Res Function(BuddyUnsupportedResult) _then;

/// Create a copy of BuddyUnsupportedResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,}) {
  return _then(BuddyUnsupportedResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyUnsupportedResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyUnsupportedResult].
extension BuddyUnsupportedResultPatterns on BuddyUnsupportedResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyUnsupportedResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyUnsupportedResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyUnsupportedResult value)  $default,){
final _that = this;
switch (_that) {
case _BuddyUnsupportedResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyUnsupportedResult value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyUnsupportedResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyUnsupportedResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyUnsupportedResult() when $default != null:
return $default(_that.name,_that.callId,_that.ok,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyUnsupportedResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error)  $default,) {final _that = this;
switch (_that) {
case _BuddyUnsupportedResult():
return $default(_that.name,_that.callId,_that.ok,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyUnsupportedResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error)?  $default,) {final _that = this;
switch (_that) {
case _BuddyUnsupportedResult() when $default != null:
return $default(_that.name,_that.callId,_that.ok,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyUnsupportedResult implements BuddyUnsupportedResult {
  const _BuddyUnsupportedResult({required this.name, required this.callId, required this.ok, required this.error});
  factory _BuddyUnsupportedResult.fromJson(Map<String, dynamic> json) => _$BuddyUnsupportedResultFromJson(json);

@override final  BuddyUnsupportedResultName name;
@override final  String callId;
@override final  bool ok;
@override final  BuddyPhoneToolError? error;

/// Create a copy of BuddyUnsupportedResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyUnsupportedResultCopyWith<_BuddyUnsupportedResult> get copyWith => __$BuddyUnsupportedResultCopyWithImpl<_BuddyUnsupportedResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyUnsupportedResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyUnsupportedResult&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error);
}

@override
String toString() {
    return 'BuddyUnsupportedResult(name: $name, callId: $callId, ok: $ok, error: $error)';
}


}

/// @nodoc
abstract mixin class _$BuddyUnsupportedResultCopyWith<$Res> implements $BuddyUnsupportedResultCopyWith<$Res> {
  factory _$BuddyUnsupportedResultCopyWith(_BuddyUnsupportedResult value, $Res Function(_BuddyUnsupportedResult) _then) = __$BuddyUnsupportedResultCopyWithImpl;
@override @useResult
$Res call({
 BuddyUnsupportedResultName name, String callId, bool ok, BuddyPhoneToolError? error
});




}
/// @nodoc
class __$BuddyUnsupportedResultCopyWithImpl<$Res>
    implements _$BuddyUnsupportedResultCopyWith<$Res> {
  __$BuddyUnsupportedResultCopyWithImpl(this._self, this._then);

  final _BuddyUnsupportedResult _self;
  final $Res Function(_BuddyUnsupportedResult) _then;

/// Create a copy of BuddyUnsupportedResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,}) {
  return _then(_BuddyUnsupportedResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyUnsupportedResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,
  ));
}


}

// dart format on
