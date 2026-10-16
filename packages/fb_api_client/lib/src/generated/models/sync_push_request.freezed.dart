// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_push_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncPushRequest {

 List<SyncChange> get changes;
/// Create a copy of SyncPushRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncPushRequestCopyWith<SyncPushRequest> get copyWith => _$SyncPushRequestCopyWithImpl<SyncPushRequest>(this as SyncPushRequest, _$identity);

  /// Serializes this SyncPushRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncPushRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncPushRequest&&const DeepCollectionEquality().equals(other.changes, _this.changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncPushRequest;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.changes));
}

@override
String toString() {
  final _this = this as SyncPushRequest;
  return 'SyncPushRequest(changes: ${_this.changes})';
}


}

/// @nodoc
abstract mixin class $SyncPushRequestCopyWith<$Res>  {
  factory $SyncPushRequestCopyWith(SyncPushRequest value, $Res Function(SyncPushRequest) _then) = _$SyncPushRequestCopyWithImpl;
@useResult
$Res call({
 List<SyncChange> changes
});




}
/// @nodoc
class _$SyncPushRequestCopyWithImpl<$Res>
    implements $SyncPushRequestCopyWith<$Res> {
  _$SyncPushRequestCopyWithImpl(this._self, this._then);

  final SyncPushRequest _self;
  final $Res Function(SyncPushRequest) _then;

/// Create a copy of SyncPushRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? changes = null,}) {
  return _then(SyncPushRequest(
changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<SyncChange>,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncPushRequest].
extension SyncPushRequestPatterns on SyncPushRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncPushRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncPushRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncPushRequest value)  $default,){
final _that = this;
switch (_that) {
case _SyncPushRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncPushRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SyncPushRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SyncChange> changes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncPushRequest() when $default != null:
return $default(_that.changes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SyncChange> changes)  $default,) {final _that = this;
switch (_that) {
case _SyncPushRequest():
return $default(_that.changes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SyncChange> changes)?  $default,) {final _that = this;
switch (_that) {
case _SyncPushRequest() when $default != null:
return $default(_that.changes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncPushRequest implements SyncPushRequest {
  const _SyncPushRequest({required  List<SyncChange> changes}): _changes = changes;
  factory _SyncPushRequest.fromJson(Map<String, dynamic> json) => _$SyncPushRequestFromJson(json);

 final  List<SyncChange> _changes;
@override List<SyncChange> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}


/// Create a copy of SyncPushRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncPushRequestCopyWith<_SyncPushRequest> get copyWith => __$SyncPushRequestCopyWithImpl<_SyncPushRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncPushRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncPushRequest&&const DeepCollectionEquality().equals(other.changes, _changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_changes));
}

@override
String toString() {
    return 'SyncPushRequest(changes: $changes)';
}


}

/// @nodoc
abstract mixin class _$SyncPushRequestCopyWith<$Res> implements $SyncPushRequestCopyWith<$Res> {
  factory _$SyncPushRequestCopyWith(_SyncPushRequest value, $Res Function(_SyncPushRequest) _then) = __$SyncPushRequestCopyWithImpl;
@override @useResult
$Res call({
 List<SyncChange> changes
});




}
/// @nodoc
class __$SyncPushRequestCopyWithImpl<$Res>
    implements _$SyncPushRequestCopyWith<$Res> {
  __$SyncPushRequestCopyWithImpl(this._self, this._then);

  final _SyncPushRequest _self;
  final $Res Function(_SyncPushRequest) _then;

/// Create a copy of SyncPushRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? changes = null,}) {
  return _then(_SyncPushRequest(
changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<SyncChange>,
  ));
}


}

// dart format on
