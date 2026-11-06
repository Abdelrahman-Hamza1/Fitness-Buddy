// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnMessage {

 String get text;/// Optional meal photo: a base64 JPEG, at most 1024 px on its long side. Never stored.
 String? get image;
/// Create a copy of BuddyTurnMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnMessageCopyWith<BuddyTurnMessage> get copyWith => _$BuddyTurnMessageCopyWithImpl<BuddyTurnMessage>(this as BuddyTurnMessage, _$identity);

  /// Serializes this BuddyTurnMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnMessage&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.image, _this.image) || other.image == _this.image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnMessage;
  return Object.hash(runtimeType,_this.text,_this.image);
}

@override
String toString() {
  final _this = this as BuddyTurnMessage;
  return 'BuddyTurnMessage(text: ${_this.text}, image: ${_this.image})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnMessageCopyWith<$Res>  {
  factory $BuddyTurnMessageCopyWith(BuddyTurnMessage value, $Res Function(BuddyTurnMessage) _then) = _$BuddyTurnMessageCopyWithImpl;
@useResult
$Res call({
 String text, String? image
});




}
/// @nodoc
class _$BuddyTurnMessageCopyWithImpl<$Res>
    implements $BuddyTurnMessageCopyWith<$Res> {
  _$BuddyTurnMessageCopyWithImpl(this._self, this._then);

  final BuddyTurnMessage _self;
  final $Res Function(BuddyTurnMessage) _then;

/// Create a copy of BuddyTurnMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? image = freezed,}) {
  return _then(BuddyTurnMessage(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyTurnMessage].
extension BuddyTurnMessagePatterns on BuddyTurnMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnMessage value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnMessage value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnMessage() when $default != null:
return $default(_that.text,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String? image)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnMessage():
return $default(_that.text,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String? image)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnMessage() when $default != null:
return $default(_that.text,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnMessage implements BuddyTurnMessage {
  const _BuddyTurnMessage({required this.text, required this.image});
  factory _BuddyTurnMessage.fromJson(Map<String, dynamic> json) => _$BuddyTurnMessageFromJson(json);

@override final  String text;
/// Optional meal photo: a base64 JPEG, at most 1024 px on its long side. Never stored.
@override final  String? image;

/// Create a copy of BuddyTurnMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnMessageCopyWith<_BuddyTurnMessage> get copyWith => __$BuddyTurnMessageCopyWithImpl<_BuddyTurnMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnMessage&&(identical(other.text, text) || other.text == text)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,image);
}

@override
String toString() {
    return 'BuddyTurnMessage(text: $text, image: $image)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnMessageCopyWith<$Res> implements $BuddyTurnMessageCopyWith<$Res> {
  factory _$BuddyTurnMessageCopyWith(_BuddyTurnMessage value, $Res Function(_BuddyTurnMessage) _then) = __$BuddyTurnMessageCopyWithImpl;
@override @useResult
$Res call({
 String text, String? image
});




}
/// @nodoc
class __$BuddyTurnMessageCopyWithImpl<$Res>
    implements _$BuddyTurnMessageCopyWith<$Res> {
  __$BuddyTurnMessageCopyWithImpl(this._self, this._then);

  final _BuddyTurnMessage _self;
  final $Res Function(_BuddyTurnMessage) _then;

/// Create a copy of BuddyTurnMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? image = freezed,}) {
  return _then(_BuddyTurnMessage(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
