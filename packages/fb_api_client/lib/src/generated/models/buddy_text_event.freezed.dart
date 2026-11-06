// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_text_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTextEvent {

 BuddyTextEventType get type; String get text;
/// Create a copy of BuddyTextEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTextEventCopyWith<BuddyTextEvent> get copyWith => _$BuddyTextEventCopyWithImpl<BuddyTextEvent>(this as BuddyTextEvent, _$identity);

  /// Serializes this BuddyTextEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTextEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTextEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.text, _this.text) || other.text == _this.text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTextEvent;
  return Object.hash(runtimeType,_this.type,_this.text);
}

@override
String toString() {
  final _this = this as BuddyTextEvent;
  return 'BuddyTextEvent(type: ${_this.type}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $BuddyTextEventCopyWith<$Res>  {
  factory $BuddyTextEventCopyWith(BuddyTextEvent value, $Res Function(BuddyTextEvent) _then) = _$BuddyTextEventCopyWithImpl;
@useResult
$Res call({
 BuddyTextEventType type, String text
});




}
/// @nodoc
class _$BuddyTextEventCopyWithImpl<$Res>
    implements $BuddyTextEventCopyWith<$Res> {
  _$BuddyTextEventCopyWithImpl(this._self, this._then);

  final BuddyTextEvent _self;
  final $Res Function(BuddyTextEvent) _then;

/// Create a copy of BuddyTextEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = null,}) {
  return _then(BuddyTextEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyTextEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyTextEvent].
extension BuddyTextEventPatterns on BuddyTextEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTextEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTextEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTextEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTextEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTextEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTextEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyTextEventType type,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTextEvent() when $default != null:
return $default(_that.type,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyTextEventType type,  String text)  $default,) {final _that = this;
switch (_that) {
case _BuddyTextEvent():
return $default(_that.type,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyTextEventType type,  String text)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTextEvent() when $default != null:
return $default(_that.type,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTextEvent implements BuddyTextEvent {
  const _BuddyTextEvent({required this.type, required this.text});
  factory _BuddyTextEvent.fromJson(Map<String, dynamic> json) => _$BuddyTextEventFromJson(json);

@override final  BuddyTextEventType type;
@override final  String text;

/// Create a copy of BuddyTextEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTextEventCopyWith<_BuddyTextEvent> get copyWith => __$BuddyTextEventCopyWithImpl<_BuddyTextEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTextEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTextEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,text);
}

@override
String toString() {
    return 'BuddyTextEvent(type: $type, text: $text)';
}


}

/// @nodoc
abstract mixin class _$BuddyTextEventCopyWith<$Res> implements $BuddyTextEventCopyWith<$Res> {
  factory _$BuddyTextEventCopyWith(_BuddyTextEvent value, $Res Function(_BuddyTextEvent) _then) = __$BuddyTextEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyTextEventType type, String text
});




}
/// @nodoc
class __$BuddyTextEventCopyWithImpl<$Res>
    implements _$BuddyTextEventCopyWith<$Res> {
  __$BuddyTextEventCopyWithImpl(this._self, this._then);

  final _BuddyTextEvent _self;
  final $Res Function(_BuddyTextEvent) _then;

/// Create a copy of BuddyTextEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,}) {
  return _then(_BuddyTextEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyTextEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
