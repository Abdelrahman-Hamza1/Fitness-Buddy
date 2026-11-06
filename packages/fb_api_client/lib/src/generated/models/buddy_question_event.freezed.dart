// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_question_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyQuestionEvent {

 BuddyQuestionEventType get type; String get text; List<String> get options;
/// Create a copy of BuddyQuestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyQuestionEventCopyWith<BuddyQuestionEvent> get copyWith => _$BuddyQuestionEventCopyWithImpl<BuddyQuestionEvent>(this as BuddyQuestionEvent, _$identity);

  /// Serializes this BuddyQuestionEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyQuestionEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyQuestionEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.text, _this.text) || other.text == _this.text)&&const DeepCollectionEquality().equals(other.options, _this.options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyQuestionEvent;
  return Object.hash(runtimeType,_this.type,_this.text,const DeepCollectionEquality().hash(_this.options));
}

@override
String toString() {
  final _this = this as BuddyQuestionEvent;
  return 'BuddyQuestionEvent(type: ${_this.type}, text: ${_this.text}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $BuddyQuestionEventCopyWith<$Res>  {
  factory $BuddyQuestionEventCopyWith(BuddyQuestionEvent value, $Res Function(BuddyQuestionEvent) _then) = _$BuddyQuestionEventCopyWithImpl;
@useResult
$Res call({
 BuddyQuestionEventType type, String text, List<String> options
});




}
/// @nodoc
class _$BuddyQuestionEventCopyWithImpl<$Res>
    implements $BuddyQuestionEventCopyWith<$Res> {
  _$BuddyQuestionEventCopyWithImpl(this._self, this._then);

  final BuddyQuestionEvent _self;
  final $Res Function(BuddyQuestionEvent) _then;

/// Create a copy of BuddyQuestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = null,Object? options = null,}) {
  return _then(BuddyQuestionEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyQuestionEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyQuestionEvent].
extension BuddyQuestionEventPatterns on BuddyQuestionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyQuestionEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyQuestionEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyQuestionEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyQuestionEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyQuestionEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyQuestionEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyQuestionEventType type,  String text,  List<String> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyQuestionEvent() when $default != null:
return $default(_that.type,_that.text,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyQuestionEventType type,  String text,  List<String> options)  $default,) {final _that = this;
switch (_that) {
case _BuddyQuestionEvent():
return $default(_that.type,_that.text,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyQuestionEventType type,  String text,  List<String> options)?  $default,) {final _that = this;
switch (_that) {
case _BuddyQuestionEvent() when $default != null:
return $default(_that.type,_that.text,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyQuestionEvent implements BuddyQuestionEvent {
  const _BuddyQuestionEvent({required this.type, required this.text, required  List<String> options}): _options = options;
  factory _BuddyQuestionEvent.fromJson(Map<String, dynamic> json) => _$BuddyQuestionEventFromJson(json);

@override final  BuddyQuestionEventType type;
@override final  String text;
 final  List<String> _options;
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of BuddyQuestionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyQuestionEventCopyWith<_BuddyQuestionEvent> get copyWith => __$BuddyQuestionEventCopyWithImpl<_BuddyQuestionEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyQuestionEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyQuestionEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,text,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'BuddyQuestionEvent(type: $type, text: $text, options: $options)';
}


}

/// @nodoc
abstract mixin class _$BuddyQuestionEventCopyWith<$Res> implements $BuddyQuestionEventCopyWith<$Res> {
  factory _$BuddyQuestionEventCopyWith(_BuddyQuestionEvent value, $Res Function(_BuddyQuestionEvent) _then) = __$BuddyQuestionEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyQuestionEventType type, String text, List<String> options
});




}
/// @nodoc
class __$BuddyQuestionEventCopyWithImpl<$Res>
    implements _$BuddyQuestionEventCopyWith<$Res> {
  __$BuddyQuestionEventCopyWithImpl(this._self, this._then);

  final _BuddyQuestionEvent _self;
  final $Res Function(_BuddyQuestionEvent) _then;

/// Create a copy of BuddyQuestionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,Object? options = null,}) {
  return _then(_BuddyQuestionEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyQuestionEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
