// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_body_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadBodyResult {

 BuddyReadBodyResultName get name; String get callId; bool get ok; BuddyPhoneToolError? get error; BuddyReadBodyData? get data;
/// Create a copy of BuddyReadBodyResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadBodyResultCopyWith<BuddyReadBodyResult> get copyWith => _$BuddyReadBodyResultCopyWithImpl<BuddyReadBodyResult>(this as BuddyReadBodyResult, _$identity);

  /// Serializes this BuddyReadBodyResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadBodyResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadBodyResult&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.data, _this.data) || other.data == _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadBodyResult;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.ok,_this.error,_this.data);
}

@override
String toString() {
  final _this = this as BuddyReadBodyResult;
  return 'BuddyReadBodyResult(name: ${_this.name}, callId: ${_this.callId}, ok: ${_this.ok}, error: ${_this.error}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $BuddyReadBodyResultCopyWith<$Res>  {
  factory $BuddyReadBodyResultCopyWith(BuddyReadBodyResult value, $Res Function(BuddyReadBodyResult) _then) = _$BuddyReadBodyResultCopyWithImpl;
@useResult
$Res call({
 BuddyReadBodyResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadBodyData? data
});


$BuddyReadBodyDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyReadBodyResultCopyWithImpl<$Res>
    implements $BuddyReadBodyResultCopyWith<$Res> {
  _$BuddyReadBodyResultCopyWithImpl(this._self, this._then);

  final BuddyReadBodyResult _self;
  final $Res Function(BuddyReadBodyResult) _then;

/// Create a copy of BuddyReadBodyResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyReadBodyResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyData?,
  ));
}
/// Create a copy of BuddyReadBodyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadBodyDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadBodyDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadBodyResult].
extension BuddyReadBodyResultPatterns on BuddyReadBodyResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadBodyResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadBodyResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadBodyResult value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadBodyResult value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadBodyResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyReadBodyResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadBodyData? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadBodyResult() when $default != null:
return $default(_that.name,_that.callId,_that.ok,_that.error,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyReadBodyResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadBodyData? data)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyResult():
return $default(_that.name,_that.callId,_that.ok,_that.error,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyReadBodyResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadBodyData? data)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadBodyResult() when $default != null:
return $default(_that.name,_that.callId,_that.ok,_that.error,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadBodyResult implements BuddyReadBodyResult {
  const _BuddyReadBodyResult({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory _BuddyReadBodyResult.fromJson(Map<String, dynamic> json) => _$BuddyReadBodyResultFromJson(json);

@override final  BuddyReadBodyResultName name;
@override final  String callId;
@override final  bool ok;
@override final  BuddyPhoneToolError? error;
@override final  BuddyReadBodyData? data;

/// Create a copy of BuddyReadBodyResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadBodyResultCopyWith<_BuddyReadBodyResult> get copyWith => __$BuddyReadBodyResultCopyWithImpl<_BuddyReadBodyResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadBodyResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadBodyResult&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyReadBodyResult(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadBodyResultCopyWith<$Res> implements $BuddyReadBodyResultCopyWith<$Res> {
  factory _$BuddyReadBodyResultCopyWith(_BuddyReadBodyResult value, $Res Function(_BuddyReadBodyResult) _then) = __$BuddyReadBodyResultCopyWithImpl;
@override @useResult
$Res call({
 BuddyReadBodyResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadBodyData? data
});


@override $BuddyReadBodyDataCopyWith<$Res>? get data;

}
/// @nodoc
class __$BuddyReadBodyResultCopyWithImpl<$Res>
    implements _$BuddyReadBodyResultCopyWith<$Res> {
  __$BuddyReadBodyResultCopyWithImpl(this._self, this._then);

  final _BuddyReadBodyResult _self;
  final $Res Function(_BuddyReadBodyResult) _then;

/// Create a copy of BuddyReadBodyResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(_BuddyReadBodyResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadBodyData?,
  ));
}

/// Create a copy of BuddyReadBodyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadBodyDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadBodyDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
