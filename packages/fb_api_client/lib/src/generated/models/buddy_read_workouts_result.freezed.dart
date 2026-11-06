// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_workouts_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadWorkoutsResult {

 BuddyReadWorkoutsResultName get name; String get callId; bool get ok; BuddyPhoneToolError? get error; BuddyReadWorkoutsData? get data;
/// Create a copy of BuddyReadWorkoutsResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsResultCopyWith<BuddyReadWorkoutsResult> get copyWith => _$BuddyReadWorkoutsResultCopyWithImpl<BuddyReadWorkoutsResult>(this as BuddyReadWorkoutsResult, _$identity);

  /// Serializes this BuddyReadWorkoutsResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadWorkoutsResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadWorkoutsResult&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.error, _this.error) || other.error == _this.error)&&(identical(other.data, _this.data) || other.data == _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadWorkoutsResult;
  return Object.hash(runtimeType,_this.name,_this.callId,_this.ok,_this.error,_this.data);
}

@override
String toString() {
  final _this = this as BuddyReadWorkoutsResult;
  return 'BuddyReadWorkoutsResult(name: ${_this.name}, callId: ${_this.callId}, ok: ${_this.ok}, error: ${_this.error}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $BuddyReadWorkoutsResultCopyWith<$Res>  {
  factory $BuddyReadWorkoutsResultCopyWith(BuddyReadWorkoutsResult value, $Res Function(BuddyReadWorkoutsResult) _then) = _$BuddyReadWorkoutsResultCopyWithImpl;
@useResult
$Res call({
 BuddyReadWorkoutsResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadWorkoutsData? data
});


$BuddyReadWorkoutsDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$BuddyReadWorkoutsResultCopyWithImpl<$Res>
    implements $BuddyReadWorkoutsResultCopyWith<$Res> {
  _$BuddyReadWorkoutsResultCopyWithImpl(this._self, this._then);

  final BuddyReadWorkoutsResult _self;
  final $Res Function(BuddyReadWorkoutsResult) _then;

/// Create a copy of BuddyReadWorkoutsResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(BuddyReadWorkoutsResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsData?,
  ));
}
/// Create a copy of BuddyReadWorkoutsResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadWorkoutsDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyReadWorkoutsResult].
extension BuddyReadWorkoutsResultPatterns on BuddyReadWorkoutsResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadWorkoutsResult value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadWorkoutsResult value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadWorkoutsResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyReadWorkoutsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadWorkoutsData? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsResult() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyReadWorkoutsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadWorkoutsData? data)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsResult():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyReadWorkoutsResultName name,  String callId,  bool ok,  BuddyPhoneToolError? error,  BuddyReadWorkoutsData? data)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadWorkoutsResult() when $default != null:
return $default(_that.name,_that.callId,_that.ok,_that.error,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadWorkoutsResult implements BuddyReadWorkoutsResult {
  const _BuddyReadWorkoutsResult({required this.name, required this.callId, required this.ok, required this.error, required this.data});
  factory _BuddyReadWorkoutsResult.fromJson(Map<String, dynamic> json) => _$BuddyReadWorkoutsResultFromJson(json);

@override final  BuddyReadWorkoutsResultName name;
@override final  String callId;
@override final  bool ok;
@override final  BuddyPhoneToolError? error;
@override final  BuddyReadWorkoutsData? data;

/// Create a copy of BuddyReadWorkoutsResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadWorkoutsResultCopyWith<_BuddyReadWorkoutsResult> get copyWith => __$BuddyReadWorkoutsResultCopyWithImpl<_BuddyReadWorkoutsResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadWorkoutsResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadWorkoutsResult&&(identical(other.name, name) || other.name == name)&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,callId,ok,error,data);
}

@override
String toString() {
    return 'BuddyReadWorkoutsResult(name: $name, callId: $callId, ok: $ok, error: $error, data: $data)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadWorkoutsResultCopyWith<$Res> implements $BuddyReadWorkoutsResultCopyWith<$Res> {
  factory _$BuddyReadWorkoutsResultCopyWith(_BuddyReadWorkoutsResult value, $Res Function(_BuddyReadWorkoutsResult) _then) = __$BuddyReadWorkoutsResultCopyWithImpl;
@override @useResult
$Res call({
 BuddyReadWorkoutsResultName name, String callId, bool ok, BuddyPhoneToolError? error, BuddyReadWorkoutsData? data
});


@override $BuddyReadWorkoutsDataCopyWith<$Res>? get data;

}
/// @nodoc
class __$BuddyReadWorkoutsResultCopyWithImpl<$Res>
    implements _$BuddyReadWorkoutsResultCopyWith<$Res> {
  __$BuddyReadWorkoutsResultCopyWithImpl(this._self, this._then);

  final _BuddyReadWorkoutsResult _self;
  final $Res Function(_BuddyReadWorkoutsResult) _then;

/// Create a copy of BuddyReadWorkoutsResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? callId = null,Object? ok = null,Object? error = freezed,Object? data = freezed,}) {
  return _then(_BuddyReadWorkoutsResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsResultName,callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolError?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BuddyReadWorkoutsData?,
  ));
}

/// Create a copy of BuddyReadWorkoutsResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyReadWorkoutsDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $BuddyReadWorkoutsDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

// dart format on
