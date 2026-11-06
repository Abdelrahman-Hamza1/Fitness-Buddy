// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_memory_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadMemoryResult {

 BuddyReadMemoryResultName get name; String get callId; bool get ok; BuddyPhoneToolError? get error; BuddyReadMemoryData? get data;
/// Create a copy of BuddyReadMemoryResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadMemoryResultCopyWith<BuddyReadMemoryResult> get copyWith => _$BuddyReadMemoryResultCopyWithImpl<BuddyReadMemoryResult>(this as BuddyReadMemoryResult, _$identity);

  /// Serializes this BuddyReadMemoryResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadMemoryResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadMemoryResult&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.data, _this.data) || other.data == _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadMemoryResult;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.ok,_this.error,_this.data);
}

@override
String toString() {
  final _this = this as BuddyReadMemoryResult;
  return 'BuddyReadMemoryResult(name: ${_this.name}, callId: ${_this.callId}, ok: ${_this.ok}, error: ${_this.error}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $BuddyReadMemoryResultCopyWith<$Res>  {
  factory $BuddyReadMemoryResultCopyWith(BuddyReadMemoryResult value, $Res Function(BuddyReadMemoryResult) _then) = _$BuddyReadMemoryResultCopyWithImpl;
@useResult
$Res call({
 BuddyReadMemoryResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadMemoryData? data
});


$BuddyReadMemoryDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyReadMemoryResultCopyWithImpl<$Res>
    implements $BuddyReadMemoryResultCopyWith<$Res> {
  _$BuddyReadMemoryResultCopyWithImpl(this._self, this._then);

  final BuddyReadMemoryResult _self;
  final $Res Function(BuddyReadMemoryResult) _then;

/// Create a copy of BuddyReadMemoryResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyReadMemoryResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryData?,
  ));
}
/// Create a copy of BuddyReadMemoryResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadMemoryDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadMemoryDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadMemoryResult].
extension BuddyReadMemoryResultPatterns on BuddyReadMemoryResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadMemoryResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadMemoryResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadMemoryResult value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadMemoryResult value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyReadMemoryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadMemoryData? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadMemoryResult() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyReadMemoryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadMemoryData? data)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryResult():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyReadMemoryResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadMemoryData? data)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryResult() when $default != null:
return $default(_that.name,_that.callId,_that.ok,_that.error,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadMemoryResult implements BuddyReadMemoryResult {
  const _BuddyReadMemoryResult({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory _BuddyReadMemoryResult.fromJson(Map<String, dynamic> json) => _$BuddyReadMemoryResultFromJson(json);

@override final  BuddyReadMemoryResultName name;
@override final  String callId;
@override final  bool ok;
@override final  BuddyPhoneToolError? error;
@override final  BuddyReadMemoryData? data;

/// Create a copy of BuddyReadMemoryResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadMemoryResultCopyWith<_BuddyReadMemoryResult> get copyWith => __$BuddyReadMemoryResultCopyWithImpl<_BuddyReadMemoryResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadMemoryResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadMemoryResult&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyReadMemoryResult(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadMemoryResultCopyWith<$Res> implements $BuddyReadMemoryResultCopyWith<$Res> {
  factory _$BuddyReadMemoryResultCopyWith(_BuddyReadMemoryResult value, $Res Function(_BuddyReadMemoryResult) _then) = __$BuddyReadMemoryResultCopyWithImpl;
@override @useResult
$Res call({
 BuddyReadMemoryResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadMemoryData? data
});


@override $BuddyReadMemoryDataCopyWith<$Res>? get data;

}
/// @nodoc
class __$BuddyReadMemoryResultCopyWithImpl<$Res>
    implements _$BuddyReadMemoryResultCopyWith<$Res> {
  __$BuddyReadMemoryResultCopyWithImpl(this._self, this._then);

  final _BuddyReadMemoryResult _self;
  final $Res Function(_BuddyReadMemoryResult) _then;

/// Create a copy of BuddyReadMemoryResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(_BuddyReadMemoryResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadMemoryData?,
  ));
}

/// Create a copy of BuddyReadMemoryResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadMemoryDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadMemoryDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
