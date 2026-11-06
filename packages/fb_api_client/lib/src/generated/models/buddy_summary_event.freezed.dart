// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_summary_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddySummaryEvent {

 BuddySummaryEventType get type; String get text; int get revision; String get watermark;
/// Create a copy of BuddySummaryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddySummaryEventCopyWith<BuddySummaryEvent> get copyWith => _$BuddySummaryEventCopyWithImpl<BuddySummaryEvent>(this as BuddySummaryEvent, _$identity);

  /// Serializes this BuddySummaryEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddySummaryEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddySummaryEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.watermark, _this.watermark) || other.watermark == _this.watermark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddySummaryEvent;
  return Object.hash(runtimeType,_this.type,_this.text,_this.revision,_this.watermark);
}

@override
String toString() {
  final _this = this as BuddySummaryEvent;
  return 'BuddySummaryEvent(type: ${_this.type}, text: ${_this.text}, revision: ${_this.revision}, watermark: ${_this.watermark})';
}


}

/// @nodoc
abstract mixin class $BuddySummaryEventCopyWith<$Res>  {
  factory $BuddySummaryEventCopyWith(BuddySummaryEvent value, $Res Function(BuddySummaryEvent) _then) = _$BuddySummaryEventCopyWithImpl;
@useResult
$Res call({
 BuddySummaryEventType type, String text, int revision, String watermark
});




}
/// @nodoc
class _$BuddySummaryEventCopyWithImpl<$Res>
    implements $BuddySummaryEventCopyWith<$Res> {
  _$BuddySummaryEventCopyWithImpl(this._self, this._then);

  final BuddySummaryEvent _self;
  final $Res Function(BuddySummaryEvent) _then;

/// Create a copy of BuddySummaryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = null,Object? revision = null,Object? watermark = null,}) {
  return _then(BuddySummaryEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddySummaryEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,watermark: null == watermark ? _self.watermark : watermark // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddySummaryEvent].
extension BuddySummaryEventPatterns on BuddySummaryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddySummaryEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddySummaryEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddySummaryEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddySummaryEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddySummaryEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddySummaryEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddySummaryEventType type,  String text,  int revision,  String watermark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddySummaryEvent() when $default != null:
return $default(_that.type,_that.text,_that.revision,_that.watermark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddySummaryEventType type,  String text,  int revision,  String watermark)  $default,) {final _that = this;
switch (_that) {
case _BuddySummaryEvent():
return $default(_that.type,_that.text,_that.revision,_that.watermark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddySummaryEventType type,  String text,  int revision,  String watermark)?  $default,) {final _that = this;
switch (_that) {
case _BuddySummaryEvent() when $default != null:
return $default(_that.type,_that.text,_that.revision,_that.watermark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddySummaryEvent implements BuddySummaryEvent {
  const _BuddySummaryEvent({required this.type, required this.text, required this.revision, required this.watermark});
  factory _BuddySummaryEvent.fromJson(Map<String, dynamic> json) => _$BuddySummaryEventFromJson(json);

@override final  BuddySummaryEventType type;
@override final  String text;
@override final  int revision;
@override final  String watermark;

/// Create a copy of BuddySummaryEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddySummaryEventCopyWith<_BuddySummaryEvent> get copyWith => __$BuddySummaryEventCopyWithImpl<_BuddySummaryEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddySummaryEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddySummaryEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.watermark, watermark) || other.watermark == watermark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,text,revision,watermark);
}

@override
String toString() {
    return 'BuddySummaryEvent(type: $type, text: $text, revision: $revision, watermark: $watermark)';
}


}

/// @nodoc
abstract mixin class _$BuddySummaryEventCopyWith<$Res> implements $BuddySummaryEventCopyWith<$Res> {
  factory _$BuddySummaryEventCopyWith(_BuddySummaryEvent value, $Res Function(_BuddySummaryEvent) _then) = __$BuddySummaryEventCopyWithImpl;
@override @useResult
$Res call({
 BuddySummaryEventType type, String text, int revision, String watermark
});




}
/// @nodoc
class __$BuddySummaryEventCopyWithImpl<$Res>
    implements _$BuddySummaryEventCopyWith<$Res> {
  __$BuddySummaryEventCopyWithImpl(this._self, this._then);

  final _BuddySummaryEvent _self;
  final $Res Function(_BuddySummaryEvent) _then;

/// Create a copy of BuddySummaryEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,Object? revision = null,Object? watermark = null,}) {
  return _then(_BuddySummaryEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddySummaryEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,watermark: null == watermark ? _self.watermark : watermark // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
