// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_error_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyErrorEvent {

 BuddyErrorEventType get type; BuddyTurnErrorCode get code;
/// Create a copy of BuddyErrorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyErrorEventCopyWith<BuddyErrorEvent> get copyWith => _$BuddyErrorEventCopyWithImpl<BuddyErrorEvent>(this as BuddyErrorEvent, _$identity);

  /// Serializes this BuddyErrorEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyErrorEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyErrorEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyErrorEvent;
  return Object.hash(runtimeType,_this.type,_this.code);
}

@override
String toString() {
  final _this = this as BuddyErrorEvent;
  return 'BuddyErrorEvent(type: ${_this.type}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $BuddyErrorEventCopyWith<$Res>  {
  factory $BuddyErrorEventCopyWith(BuddyErrorEvent value, $Res Function(BuddyErrorEvent) _then) = _$BuddyErrorEventCopyWithImpl;
@useResult
$Res call({
 BuddyErrorEventType type, BuddyTurnErrorCode code
});




}
/// @nodoc
class _$BuddyErrorEventCopyWithImpl<$Res>
    implements $BuddyErrorEventCopyWith<$Res> {
  _$BuddyErrorEventCopyWithImpl(this._self, this._then);

  final BuddyErrorEvent _self;
  final $Res Function(BuddyErrorEvent) _then;

/// Create a copy of BuddyErrorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? code = null,}) {
  return _then(BuddyErrorEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyErrorEventType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as BuddyTurnErrorCode,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyErrorEvent].
extension BuddyErrorEventPatterns on BuddyErrorEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyErrorEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyErrorEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyErrorEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyErrorEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyErrorEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyErrorEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyErrorEventType type,  BuddyTurnErrorCode code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyErrorEvent() when $default != null:
return $default(_that.type,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyErrorEventType type,  BuddyTurnErrorCode code)  $default,) {final _that = this;
switch (_that) {
case _BuddyErrorEvent():
return $default(_that.type,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyErrorEventType type,  BuddyTurnErrorCode code)?  $default,) {final _that = this;
switch (_that) {
case _BuddyErrorEvent() when $default != null:
return $default(_that.type,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyErrorEvent implements BuddyErrorEvent {
  const _BuddyErrorEvent({required this.type, required this.code});
  factory _BuddyErrorEvent.fromJson(Map<String, dynamic> json) => _$BuddyErrorEventFromJson(json);

@override final  BuddyErrorEventType type;
@override final  BuddyTurnErrorCode code;

/// Create a copy of BuddyErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyErrorEventCopyWith<_BuddyErrorEvent> get copyWith => __$BuddyErrorEventCopyWithImpl<_BuddyErrorEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyErrorEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyErrorEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,code);
}

@override
String toString() {
    return 'BuddyErrorEvent(type: $type, code: $code)';
}


}

/// @nodoc
abstract mixin class _$BuddyErrorEventCopyWith<$Res> implements $BuddyErrorEventCopyWith<$Res> {
  factory _$BuddyErrorEventCopyWith(_BuddyErrorEvent value, $Res Function(_BuddyErrorEvent) _then) = __$BuddyErrorEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyErrorEventType type, BuddyTurnErrorCode code
});




}
/// @nodoc
class __$BuddyErrorEventCopyWithImpl<$Res>
    implements _$BuddyErrorEventCopyWith<$Res> {
  __$BuddyErrorEventCopyWithImpl(this._self, this._then);

  final _BuddyErrorEvent _self;
  final $Res Function(_BuddyErrorEvent) _then;

/// Create a copy of BuddyErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? code = null,}) {
  return _then(_BuddyErrorEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyErrorEventType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as BuddyTurnErrorCode,
  ));
}


}

// dart format on
