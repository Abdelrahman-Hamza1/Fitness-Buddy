// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncDocument {

 String get entity; String get id; int get schemaVersion; String get hlc; String get deviceId; DateTime? get deletedAt; Map<String, dynamic> get payload; String get serverSeq;
/// Create a copy of SyncDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncDocumentCopyWith<SyncDocument> get copyWith => _$SyncDocumentCopyWithImpl<SyncDocument>(this as SyncDocument, _$identity);

  /// Serializes this SyncDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncDocument&&(identical(other.entity, _this.entity) || other.entity == _this.entity)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&(identical(other.hlc, _this.hlc) || other.hlc == _this.hlc)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.serverSeq, _this.serverSeq) || other.serverSeq == _this.serverSeq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncDocument;
  return Object.hash(runtimeType,_this.entity,_this.id,_this.schemaVersion,_this.hlc,_this.deviceId,_this.deletedAt,const DeepCollectionEquality().hash(_this.payload),_this.serverSeq);
}

@override
String toString() {
  final _this = this as SyncDocument;
  return 'SyncDocument(entity: ${_this.entity}, id: ${_this.id}, schemaVersion: ${_this.schemaVersion}, hlc: ${_this.hlc}, deviceId: ${_this.deviceId}, deletedAt: ${_this.deletedAt}, payload: ${_this.payload}, serverSeq: ${_this.serverSeq})';
}


}

/// @nodoc
abstract mixin class $SyncDocumentCopyWith<$Res>  {
  factory $SyncDocumentCopyWith(SyncDocument value, $Res Function(SyncDocument) _then) = _$SyncDocumentCopyWithImpl;
@useResult
$Res call({
 String entity, String id, int schemaVersion, String hlc, String deviceId, DateTime? deletedAt, Map<String, dynamic> payload, String serverSeq
});




}
/// @nodoc
class _$SyncDocumentCopyWithImpl<$Res>
    implements $SyncDocumentCopyWith<$Res> {
  _$SyncDocumentCopyWithImpl(this._self, this._then);

  final SyncDocument _self;
  final $Res Function(SyncDocument) _then;

/// Create a copy of SyncDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entity = null,Object? id = null,Object? schemaVersion = null,Object? hlc = null,Object? deviceId = null,Object? deletedAt = freezed,Object? payload = null,Object? serverSeq = null,}) {
  return _then(SyncDocument(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,hlc: null == hlc ? _self.hlc : hlc // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncDocument].
extension SyncDocumentPatterns on SyncDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncDocument value)  $default,){
final _that = this;
switch (_that) {
case _SyncDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncDocument value)?  $default,){
final _that = this;
switch (_that) {
case _SyncDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entity,  String id,  int schemaVersion,  String hlc,  String deviceId,  DateTime? deletedAt,  Map<String, dynamic> payload,  String serverSeq)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncDocument() when $default != null:
return $default(_that.entity,_that.id,_that.schemaVersion,_that.hlc,_that.deviceId,_that.deletedAt,_that.payload,_that.serverSeq);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entity,  String id,  int schemaVersion,  String hlc,  String deviceId,  DateTime? deletedAt,  Map<String, dynamic> payload,  String serverSeq)  $default,) {final _that = this;
switch (_that) {
case _SyncDocument():
return $default(_that.entity,_that.id,_that.schemaVersion,_that.hlc,_that.deviceId,_that.deletedAt,_that.payload,_that.serverSeq);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entity,  String id,  int schemaVersion,  String hlc,  String deviceId,  DateTime? deletedAt,  Map<String, dynamic> payload,  String serverSeq)?  $default,) {final _that = this;
switch (_that) {
case _SyncDocument() when $default != null:
return $default(_that.entity,_that.id,_that.schemaVersion,_that.hlc,_that.deviceId,_that.deletedAt,_that.payload,_that.serverSeq);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncDocument implements SyncDocument {
  const _SyncDocument({required this.entity, required this.id, required this.schemaVersion, required this.hlc, required this.deviceId, required this.deletedAt, required  Map<String, dynamic> payload, required this.serverSeq}): _payload = payload;
  factory _SyncDocument.fromJson(Map<String, dynamic> json) => _$SyncDocumentFromJson(json);

@override final  String entity;
@override final  String id;
@override final  int schemaVersion;
@override final  String hlc;
@override final  String deviceId;
@override final  DateTime? deletedAt;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  String serverSeq;

/// Create a copy of SyncDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncDocumentCopyWith<_SyncDocument> get copyWith => __$SyncDocumentCopyWithImpl<_SyncDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncDocument&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.id, id) || other.id == id)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.hlc, hlc) || other.hlc == hlc)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&const DeepCollectionEquality().equals(other.payload, _payload)&&(identical(other.serverSeq, serverSeq) || other.serverSeq == serverSeq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,entity,id,schemaVersion,hlc,deviceId,deletedAt,const DeepCollectionEquality().hash(_payload),serverSeq);
}

@override
String toString() {
    return 'SyncDocument(entity: $entity, id: $id, schemaVersion: $schemaVersion, hlc: $hlc, deviceId: $deviceId, deletedAt: $deletedAt, payload: $payload, serverSeq: $serverSeq)';
}


}

/// @nodoc
abstract mixin class _$SyncDocumentCopyWith<$Res> implements $SyncDocumentCopyWith<$Res> {
  factory _$SyncDocumentCopyWith(_SyncDocument value, $Res Function(_SyncDocument) _then) = __$SyncDocumentCopyWithImpl;
@override @useResult
$Res call({
 String entity, String id, int schemaVersion, String hlc, String deviceId, DateTime? deletedAt, Map<String, dynamic> payload, String serverSeq
});




}
/// @nodoc
class __$SyncDocumentCopyWithImpl<$Res>
    implements _$SyncDocumentCopyWith<$Res> {
  __$SyncDocumentCopyWithImpl(this._self, this._then);

  final _SyncDocument _self;
  final $Res Function(_SyncDocument) _then;

/// Create a copy of SyncDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entity = null,Object? id = null,Object? schemaVersion = null,Object? hlc = null,Object? deviceId = null,Object? deletedAt = freezed,Object? payload = null,Object? serverSeq = null,}) {
  return _then(_SyncDocument(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,hlc: null == hlc ? _self.hlc : hlc // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
