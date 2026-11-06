// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_phone_tools_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPhoneToolsEvent {

 BuddyPhoneToolsEventType get type; int get round; String get continuation; List<BuddyPhoneToolCall> get calls;
/// Create a copy of BuddyPhoneToolsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPhoneToolsEventCopyWith<BuddyPhoneToolsEvent> get copyWith => _$BuddyPhoneToolsEventCopyWithImpl<BuddyPhoneToolsEvent>(this as BuddyPhoneToolsEvent, _$identity);

  /// Serializes this BuddyPhoneToolsEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPhoneToolsEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPhoneToolsEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.round, _this.round) || other.round == _this.round)&&(identical(other.continuation, _this.continuation) || other.continuation == _this.continuation)&&const DeepCollectionEquality().equals(other.calls, _this.calls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPhoneToolsEvent;
  return Object.hash(runtimeType,_this.type,_this.round,_this.continuation,const DeepCollectionEquality().hash(_this.calls));
}

@override
String toString() {
  final _this = this as BuddyPhoneToolsEvent;
  return 'BuddyPhoneToolsEvent(type: ${_this.type}, round: ${_this.round}, continuation: ${_this.continuation}, calls: ${_this.calls})';
}


}

/// @nodoc
abstract mixin class $BuddyPhoneToolsEventCopyWith<$Res>  {
  factory $BuddyPhoneToolsEventCopyWith(BuddyPhoneToolsEvent value, $Res Function(BuddyPhoneToolsEvent) _then) = _$BuddyPhoneToolsEventCopyWithImpl;
@useResult
$Res call({
 BuddyPhoneToolsEventType type, int round, String continuation, List<BuddyPhoneToolCall> calls
});




}
/// @nodoc
class _$BuddyPhoneToolsEventCopyWithImpl<$Res>
    implements $BuddyPhoneToolsEventCopyWith<$Res> {
  _$BuddyPhoneToolsEventCopyWithImpl(this._self, this._then);

  final BuddyPhoneToolsEvent _self;
  final $Res Function(BuddyPhoneToolsEvent) _then;

/// Create a copy of BuddyPhoneToolsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? round = null,Object? continuation = null,Object? calls = null,}) {
  return _then(BuddyPhoneToolsEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolsEventType,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,continuation: null == continuation ? _self.continuation : continuation // ignore: cast_nullable_to_non_nullable
as String,calls: null == calls ? _self.calls : calls // ignore: cast_nullable_to_non_nullable
as List<BuddyPhoneToolCall>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyPhoneToolsEvent].
extension BuddyPhoneToolsEventPatterns on BuddyPhoneToolsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPhoneToolsEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPhoneToolsEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPhoneToolsEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPhoneToolsEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPhoneToolsEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPhoneToolsEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyPhoneToolsEventType type,  int round,  String continuation,  List<BuddyPhoneToolCall> calls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPhoneToolsEvent() when $default != null:
return $default(_that.type,_that.round,_that.continuation,_that.calls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyPhoneToolsEventType type,  int round,  String continuation,  List<BuddyPhoneToolCall> calls)  $default,) {final _that = this;
switch (_that) {
case _BuddyPhoneToolsEvent():
return $default(_that.type,_that.round,_that.continuation,_that.calls);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyPhoneToolsEventType type,  int round,  String continuation,  List<BuddyPhoneToolCall> calls)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPhoneToolsEvent() when $default != null:
return $default(_that.type,_that.round,_that.continuation,_that.calls);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPhoneToolsEvent implements BuddyPhoneToolsEvent {
  const _BuddyPhoneToolsEvent({required this.type, required this.round, required this.continuation, required  List<BuddyPhoneToolCall> calls}): _calls = calls;
  factory _BuddyPhoneToolsEvent.fromJson(Map<String, dynamic> json) => _$BuddyPhoneToolsEventFromJson(json);

@override final  BuddyPhoneToolsEventType type;
@override final  int round;
@override final  String continuation;
 final  List<BuddyPhoneToolCall> _calls;
@override List<BuddyPhoneToolCall> get calls {
  if (_calls is EqualUnmodifiableListView) return _calls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_calls);
}


/// Create a copy of BuddyPhoneToolsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPhoneToolsEventCopyWith<_BuddyPhoneToolsEvent> get copyWith => __$BuddyPhoneToolsEventCopyWithImpl<_BuddyPhoneToolsEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPhoneToolsEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPhoneToolsEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.round, round) || other.round == round)&&(identical(other.continuation, continuation) || other.continuation == continuation)&&const DeepCollectionEquality().equals(other.calls, _calls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,round,continuation,const DeepCollectionEquality().hash(_calls));
}

@override
String toString() {
    return 'BuddyPhoneToolsEvent(type: $type, round: $round, continuation: $continuation, calls: $calls)';
}


}

/// @nodoc
abstract mixin class _$BuddyPhoneToolsEventCopyWith<$Res> implements $BuddyPhoneToolsEventCopyWith<$Res> {
  factory _$BuddyPhoneToolsEventCopyWith(_BuddyPhoneToolsEvent value, $Res Function(_BuddyPhoneToolsEvent) _then) = __$BuddyPhoneToolsEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyPhoneToolsEventType type, int round, String continuation, List<BuddyPhoneToolCall> calls
});




}
/// @nodoc
class __$BuddyPhoneToolsEventCopyWithImpl<$Res>
    implements _$BuddyPhoneToolsEventCopyWith<$Res> {
  __$BuddyPhoneToolsEventCopyWithImpl(this._self, this._then);

  final _BuddyPhoneToolsEvent _self;
  final $Res Function(_BuddyPhoneToolsEvent) _then;

/// Create a copy of BuddyPhoneToolsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? round = null,Object? continuation = null,Object? calls = null,}) {
  return _then(_BuddyPhoneToolsEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolsEventType,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,continuation: null == continuation ? _self.continuation : continuation // ignore: cast_nullable_to_non_nullable
as String,calls: null == calls ? _self._calls : calls // ignore: cast_nullable_to_non_nullable
as List<BuddyPhoneToolCall>,
  ));
}


}

// dart format on
