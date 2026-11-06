// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_done_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyDoneEvent {

 BuddyDoneEventType get type; BuddyDoneReason get reason; BuddyTurnUsage get usage;
/// Create a copy of BuddyDoneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyDoneEventCopyWith<BuddyDoneEvent> get copyWith => _$BuddyDoneEventCopyWithImpl<BuddyDoneEvent>(this as BuddyDoneEvent, _$identity);

  /// Serializes this BuddyDoneEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyDoneEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyDoneEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.usage, _this.usage) || other.usage == _this.usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyDoneEvent;
  return Object.hash(runtimeType,_this.type,_this.reason,_this.usage);
}

@override
String toString() {
  final _this = this as BuddyDoneEvent;
  return 'BuddyDoneEvent(type: ${_this.type}, reason: ${_this.reason}, usage: ${_this.usage})';
}


}

/// @nodoc
abstract mixin class $BuddyDoneEventCopyWith<$Res>  {
  factory $BuddyDoneEventCopyWith(BuddyDoneEvent value, $Res Function(BuddyDoneEvent) _then) = _$BuddyDoneEventCopyWithImpl;
@useResult
$Res call({
 BuddyDoneEventType type, BuddyDoneReason reason, BuddyTurnUsage usage
});


$BuddyTurnUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$BuddyDoneEventCopyWithImpl<$Res>
    implements $BuddyDoneEventCopyWith<$Res> {
  _$BuddyDoneEventCopyWithImpl(this._self, this._then);

  final BuddyDoneEvent _self;
  final $Res Function(BuddyDoneEvent) _then;

/// Create a copy of BuddyDoneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? reason = null,Object? usage = null,}) {
  return _then(BuddyDoneEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyDoneEventType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BuddyDoneReason,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as BuddyTurnUsage,
  ));
}
/// Create a copy of BuddyDoneEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnUsageCopyWith<$Res> get usage {
  
  return $BuddyTurnUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyDoneEvent].
extension BuddyDoneEventPatterns on BuddyDoneEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyDoneEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyDoneEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyDoneEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyDoneEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyDoneEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyDoneEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyDoneEventType type,  BuddyDoneReason reason,  BuddyTurnUsage usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyDoneEvent() when $default != null:
return $default(_that.type,_that.reason,_that.usage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyDoneEventType type,  BuddyDoneReason reason,  BuddyTurnUsage usage)  $default,) {final _that = this;
switch (_that) {
case _BuddyDoneEvent():
return $default(_that.type,_that.reason,_that.usage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyDoneEventType type,  BuddyDoneReason reason,  BuddyTurnUsage usage)?  $default,) {final _that = this;
switch (_that) {
case _BuddyDoneEvent() when $default != null:
return $default(_that.type,_that.reason,_that.usage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyDoneEvent implements BuddyDoneEvent {
  const _BuddyDoneEvent({required this.type, required this.reason, required this.usage});
  factory _BuddyDoneEvent.fromJson(Map<String, dynamic> json) => _$BuddyDoneEventFromJson(json);

@override final  BuddyDoneEventType type;
@override final  BuddyDoneReason reason;
@override final  BuddyTurnUsage usage;

/// Create a copy of BuddyDoneEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyDoneEventCopyWith<_BuddyDoneEvent> get copyWith => __$BuddyDoneEventCopyWithImpl<_BuddyDoneEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyDoneEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyDoneEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,reason,usage);
}

@override
String toString() {
    return 'BuddyDoneEvent(type: $type, reason: $reason, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$BuddyDoneEventCopyWith<$Res> implements $BuddyDoneEventCopyWith<$Res> {
  factory _$BuddyDoneEventCopyWith(_BuddyDoneEvent value, $Res Function(_BuddyDoneEvent) _then) = __$BuddyDoneEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyDoneEventType type, BuddyDoneReason reason, BuddyTurnUsage usage
});


@override $BuddyTurnUsageCopyWith<$Res> get usage;

}
/// @nodoc
class __$BuddyDoneEventCopyWithImpl<$Res>
    implements _$BuddyDoneEventCopyWith<$Res> {
  __$BuddyDoneEventCopyWithImpl(this._self, this._then);

  final _BuddyDoneEvent _self;
  final $Res Function(_BuddyDoneEvent) _then;

/// Create a copy of BuddyDoneEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? reason = null,Object? usage = null,}) {
  return _then(_BuddyDoneEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyDoneEventType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BuddyDoneReason,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as BuddyTurnUsage,
  ));
}

/// Create a copy of BuddyDoneEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnUsageCopyWith<$Res> get usage {
  
  return $BuddyTurnUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

// dart format on
