// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_push_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncPushResponse {

 List<SyncPushResult> get results; DateTime get serverTime; String get datasetId;
/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPushResponseCopyWith<SyncPushResponse> get copyWith => _$SyncPushResponseCopyWithImpl<SyncPushResponse>(this as SyncPushResponse, _$identity);

  /// Serializes this SyncPushResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPushResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPushResponse&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.serverTime, _this.serverTime) || other.serverTime == _this.serverTime)&&(identical(other.datasetId, _this.datasetId) || other.datasetId == _this.datasetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPushResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.results),_this.serverTime,_this.datasetId);
}

@override
String toString() {
  final _this = this as SyncPushResponse;
  return 'SyncPushResponse(results: ${_this.results}, serverTime: ${_this.serverTime}, datasetId: ${_this.datasetId})';
}


}

/// @nodoc
abstract mixin class $SyncPushResponseCopyWith<$Res>  {
  factory $SyncPushResponseCopyWith(SyncPushResponse value, $Res Function(SyncPushResponse) _then) = _$SyncPushResponseCopyWithImpl;
@useResult
$Res call({
 List<SyncPushResult> results, DateTime serverTime, String datasetId
});




}
/// @nodoc
class _$SyncPushResponseCopyWithImpl<$Res>
    implements $SyncPushResponseCopyWith<$Res> {
  _$SyncPushResponseCopyWithImpl(this._self, this._then);

  final SyncPushResponse _self;
  final $Res Function(SyncPushResponse) _then;

/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = null,Object? serverTime = null,Object? datasetId = null,}) {
  return _then(SyncPushResponse(
results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SyncPushResult>,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,datasetId: null == datasetId ? _self.datasetId : datasetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPushResponse].
extension SyncPushResponsePatterns on SyncPushResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPushResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPushResponse value)  $default,){
final _that = this;
switch (_that) {
case _SyncPushResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPushResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SyncPushResult> results,  DateTime serverTime,  String datasetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
return $default(_that.results,_that.serverTime,_that.datasetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SyncPushResult> results,  DateTime serverTime,  String datasetId)  $default,) {final _that = this;
switch (_that) {
case _SyncPushResponse():
return $default(_that.results,_that.serverTime,_that.datasetId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SyncPushResult> results,  DateTime serverTime,  String datasetId)?  $default,) {final _that = this;
switch (_that) {
case _SyncPushResponse() when $default != null:
return $default(_that.results,_that.serverTime,_that.datasetId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPushResponse implements SyncPushResponse {
  const _SyncPushResponse({required  List<SyncPushResult> results, required this.serverTime, required this.datasetId}): _results = results;
  factory _SyncPushResponse.fromJson(Map<String, dynamic> json) => _$SyncPushResponseFromJson(json);

 final  List<SyncPushResult> _results;
@override List<SyncPushResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  DateTime serverTime;
@override final  String datasetId;

/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPushResponseCopyWith<_SyncPushResponse> get copyWith => __$SyncPushResponseCopyWithImpl<_SyncPushResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPushResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPushResponse&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.datasetId, datasetId) || other.datasetId == datasetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_results),serverTime,datasetId);
}

@override
String toString() {
    return 'SyncPushResponse(results: $results, serverTime: $serverTime, datasetId: $datasetId)';
}


}

/// @nodoc
abstract mixin class _$SyncPushResponseCopyWith<$Res> implements $SyncPushResponseCopyWith<$Res> {
  factory _$SyncPushResponseCopyWith(_SyncPushResponse value, $Res Function(_SyncPushResponse) _then) = __$SyncPushResponseCopyWithImpl;
@override @useResult
$Res call({
 List<SyncPushResult> results, DateTime serverTime, String datasetId
});




}
/// @nodoc
class __$SyncPushResponseCopyWithImpl<$Res>
    implements _$SyncPushResponseCopyWith<$Res> {
  __$SyncPushResponseCopyWithImpl(this._self, this._then);

  final _SyncPushResponse _self;
  final $Res Function(_SyncPushResponse) _then;

/// Create a copy of SyncPushResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = null,Object? serverTime = null,Object? datasetId = null,}) {
  return _then(_SyncPushResponse(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SyncPushResult>,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,datasetId: null == datasetId ? _self.datasetId : datasetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
