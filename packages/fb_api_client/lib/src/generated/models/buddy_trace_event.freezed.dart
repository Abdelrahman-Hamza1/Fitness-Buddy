// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_trace_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTraceEvent {

 BuddyTraceEventType get type; List<BuddyTraceStep> get steps;
/// Create a copy of BuddyTraceEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTraceEventCopyWith<BuddyTraceEvent> get copyWith => _$BuddyTraceEventCopyWithImpl<BuddyTraceEvent>(this as BuddyTraceEvent, _$identity);

  /// Serializes this BuddyTraceEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTraceEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTraceEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.steps, _this.steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTraceEvent;
  return Object.hash(runtimeType,_this.type,const DeepCollectionEquality().hash(_this.steps));
}

@override
String toString() {
  final _this = this as BuddyTraceEvent;
  return 'BuddyTraceEvent(type: ${_this.type}, steps: ${_this.steps})';
}


}

/// @nodoc
abstract mixin class $BuddyTraceEventCopyWith<$Res>  {
  factory $BuddyTraceEventCopyWith(BuddyTraceEvent value, $Res Function(BuddyTraceEvent) _then) = _$BuddyTraceEventCopyWithImpl;
@useResult
$Res call({
 BuddyTraceEventType type, List<BuddyTraceStep> steps
});




}
/// @nodoc
class _$BuddyTraceEventCopyWithImpl<$Res>
    implements $BuddyTraceEventCopyWith<$Res> {
  _$BuddyTraceEventCopyWithImpl(this._self, this._then);

  final BuddyTraceEvent _self;
  final $Res Function(BuddyTraceEvent) _then;

/// Create a copy of BuddyTraceEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? steps = null,}) {
  return _then(BuddyTraceEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyTraceEventType,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<BuddyTraceStep>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyTraceEvent].
extension BuddyTraceEventPatterns on BuddyTraceEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTraceEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTraceEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTraceEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTraceEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTraceEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTraceEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyTraceEventType type,  List<BuddyTraceStep> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTraceEvent() when $default != null:
return $default(_that.type,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyTraceEventType type,  List<BuddyTraceStep> steps)  $default,) {final _that = this;
switch (_that) {
case _BuddyTraceEvent():
return $default(_that.type,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyTraceEventType type,  List<BuddyTraceStep> steps)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTraceEvent() when $default != null:
return $default(_that.type,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTraceEvent implements BuddyTraceEvent {
  const _BuddyTraceEvent({required this.type, required  List<BuddyTraceStep> steps}): _steps = steps;
  factory _BuddyTraceEvent.fromJson(Map<String, dynamic> json) => _$BuddyTraceEventFromJson(json);

@override final  BuddyTraceEventType type;
 final  List<BuddyTraceStep> _steps;
@override List<BuddyTraceStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of BuddyTraceEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTraceEventCopyWith<_BuddyTraceEvent> get copyWith => __$BuddyTraceEventCopyWithImpl<_BuddyTraceEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTraceEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTraceEvent&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_steps));
}

@override
String toString() {
    return 'BuddyTraceEvent(type: $type, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$BuddyTraceEventCopyWith<$Res> implements $BuddyTraceEventCopyWith<$Res> {
  factory _$BuddyTraceEventCopyWith(_BuddyTraceEvent value, $Res Function(_BuddyTraceEvent) _then) = __$BuddyTraceEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyTraceEventType type, List<BuddyTraceStep> steps
});




}
/// @nodoc
class __$BuddyTraceEventCopyWithImpl<$Res>
    implements _$BuddyTraceEventCopyWith<$Res> {
  __$BuddyTraceEventCopyWithImpl(this._self, this._then);

  final _BuddyTraceEvent _self;
  final $Res Function(_BuddyTraceEvent) _then;

/// Create a copy of BuddyTraceEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? steps = null,}) {
  return _then(_BuddyTraceEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyTraceEventType,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<BuddyTraceStep>,
  ));
}


}

// dart format on
