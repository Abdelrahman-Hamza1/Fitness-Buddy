// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_step_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyStepEvent {

 BuddyStepEventType get type; BuddyStepCode get code;
/// Create a copy of BuddyStepEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyStepEventCopyWith<BuddyStepEvent> get copyWith => _$BuddyStepEventCopyWithImpl<BuddyStepEvent>(this as BuddyStepEvent, _$identity);

  /// Serializes this BuddyStepEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyStepEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyStepEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.code, _this.code) || other.code == _this.code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyStepEvent;
  return Object.hash(runtimeType,_this.type,_this.code);
}

@override
String toString() {
  final _this = this as BuddyStepEvent;
  return 'BuddyStepEvent(type: ${_this.type}, code: ${_this.code})';
}


}

/// @nodoc
abstract mixin class $BuddyStepEventCopyWith<$Res>  {
  factory $BuddyStepEventCopyWith(BuddyStepEvent value, $Res Function(BuddyStepEvent) _then) = _$BuddyStepEventCopyWithImpl;
@useResult
$Res call({
 BuddyStepEventType type, BuddyStepCode code
});




}
/// @nodoc
class _$BuddyStepEventCopyWithImpl<$Res>
    implements $BuddyStepEventCopyWith<$Res> {
  _$BuddyStepEventCopyWithImpl(this._self, this._then);

  final BuddyStepEvent _self;
  final $Res Function(BuddyStepEvent) _then;

/// Create a copy of BuddyStepEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? code = null,}) {
  return _then(BuddyStepEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyStepEventType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as BuddyStepCode,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyStepEvent].
extension BuddyStepEventPatterns on BuddyStepEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyStepEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyStepEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyStepEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyStepEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyStepEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyStepEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyStepEventType type,  BuddyStepCode code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyStepEvent() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyStepEventType type,  BuddyStepCode code)  $default,) {final _that = this;
switch (_that) {
case _BuddyStepEvent():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyStepEventType type,  BuddyStepCode code)?  $default,) {final _that = this;
switch (_that) {
case _BuddyStepEvent() when $default != null:
return $default(_that.type,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyStepEvent implements BuddyStepEvent {
  const _BuddyStepEvent({required this.type, required this.code});
  factory _BuddyStepEvent.fromJson(Map<String, dynamic> json) => _$BuddyStepEventFromJson(json);

@override final  BuddyStepEventType type;
@override final  BuddyStepCode code;

/// Create a copy of BuddyStepEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyStepEventCopyWith<_BuddyStepEvent> get copyWith => __$BuddyStepEventCopyWithImpl<_BuddyStepEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyStepEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyStepEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,code);
}

@override
String toString() {
    return 'BuddyStepEvent(type: $type, code: $code)';
}


}

/// @nodoc
abstract mixin class _$BuddyStepEventCopyWith<$Res> implements $BuddyStepEventCopyWith<$Res> {
  factory _$BuddyStepEventCopyWith(_BuddyStepEvent value, $Res Function(_BuddyStepEvent) _then) = __$BuddyStepEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyStepEventType type, BuddyStepCode code
});




}
/// @nodoc
class __$BuddyStepEventCopyWithImpl<$Res>
    implements _$BuddyStepEventCopyWith<$Res> {
  __$BuddyStepEventCopyWithImpl(this._self, this._then);

  final _BuddyStepEvent _self;
  final $Res Function(_BuddyStepEvent) _then;

/// Create a copy of BuddyStepEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? code = null,}) {
  return _then(_BuddyStepEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyStepEventType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as BuddyStepCode,
  ));
}


}

// dart format on
