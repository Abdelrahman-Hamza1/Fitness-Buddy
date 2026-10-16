// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_push_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncPushResult {

 String get entity; String get id; String get hlc; String get status; String? get reason;
/// Create a copy of SyncPushResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPushResultCopyWith<SyncPushResult> get copyWith => _$SyncPushResultCopyWithImpl<SyncPushResult>(this as SyncPushResult, _$identity);

  /// Serializes this SyncPushResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPushResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPushResult&&(identical(other.entity, _this.entity) || other.entity == _this.entity)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.hlc, _this.hlc) || other.hlc == _this.hlc)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPushResult;
  return Object.hash(runtimeType,_this.entity,_this.id,_this.hlc,_this.status,_this.reason);
}

@override
String toString() {
  final _this = this as SyncPushResult;
  return 'SyncPushResult(entity: ${_this.entity}, id: ${_this.id}, hlc: ${_this.hlc}, status: ${_this.status}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $SyncPushResultCopyWith<$Res>  {
  factory $SyncPushResultCopyWith(SyncPushResult value, $Res Function(SyncPushResult) _then) = _$SyncPushResultCopyWithImpl;
@useResult
$Res call({
 String entity, String id, String hlc, String status, String? reason
});




}
/// @nodoc
class _$SyncPushResultCopyWithImpl<$Res>
    implements $SyncPushResultCopyWith<$Res> {
  _$SyncPushResultCopyWithImpl(this._self, this._then);

  final SyncPushResult _self;
  final $Res Function(SyncPushResult) _then;

/// Create a copy of SyncPushResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entity = null,Object? id = null,Object? hlc = null,Object? status = null,Object? reason = freezed,}) {
  return _then(SyncPushResult(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hlc: null == hlc ? _self.hlc : hlc // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPushResult].
extension SyncPushResultPatterns on SyncPushResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPushResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPushResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPushResult value)  $default,){
final _that = this;
switch (_that) {
case _SyncPushResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPushResult value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPushResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entity,  String id,  String hlc,  String status,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPushResult() when $default != null:
return $default(_that.entity,_that.id,_that.hlc,_that.status,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entity,  String id,  String hlc,  String status,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _SyncPushResult():
return $default(_that.entity,_that.id,_that.hlc,_that.status,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entity,  String id,  String hlc,  String status,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _SyncPushResult() when $default != null:
return $default(_that.entity,_that.id,_that.hlc,_that.status,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPushResult implements SyncPushResult {
  const _SyncPushResult({required this.entity, required this.id, required this.hlc, required this.status, required this.reason});
  factory _SyncPushResult.fromJson(Map<String, dynamic> json) => _$SyncPushResultFromJson(json);

@override final  String entity;
@override final  String id;
@override final  String hlc;
@override final  String status;
@override final  String? reason;

/// Create a copy of SyncPushResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPushResultCopyWith<_SyncPushResult> get copyWith => __$SyncPushResultCopyWithImpl<_SyncPushResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPushResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPushResult&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.id, id) || other.id == id)&&(identical(other.hlc, hlc) || other.hlc == hlc)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,entity,id,hlc,status,reason);
}

@override
String toString() {
    return 'SyncPushResult(entity: $entity, id: $id, hlc: $hlc, status: $status, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$SyncPushResultCopyWith<$Res> implements $SyncPushResultCopyWith<$Res> {
  factory _$SyncPushResultCopyWith(_SyncPushResult value, $Res Function(_SyncPushResult) _then) = __$SyncPushResultCopyWithImpl;
@override @useResult
$Res call({
 String entity, String id, String hlc, String status, String? reason
});




}
/// @nodoc
class __$SyncPushResultCopyWithImpl<$Res>
    implements _$SyncPushResultCopyWith<$Res> {
  __$SyncPushResultCopyWithImpl(this._self, this._then);

  final _SyncPushResult _self;
  final $Res Function(_SyncPushResult) _then;

/// Create a copy of SyncPushResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entity = null,Object? id = null,Object? hlc = null,Object? status = null,Object? reason = freezed,}) {
  return _then(_SyncPushResult(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hlc: null == hlc ? _self.hlc : hlc // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
