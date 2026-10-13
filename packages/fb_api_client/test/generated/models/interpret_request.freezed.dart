// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interpret_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InterpretRequest {

 Id get messageId; String get text; Instant get sentAt; LocalDate get localDate;
/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterpretRequestCopyWith<InterpretRequest> get copyWith => _$InterpretRequestCopyWithImpl<InterpretRequest>(this as InterpretRequest, _$identity);

  /// Serializes this InterpretRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InterpretRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterpretRequest&&(identical(other.messageId, _this.messageId) || other.messageId == _this.messageId)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt)&&(identical(other.localDate, _this.localDate) || other.localDate == _this.localDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InterpretRequest;
  return Object.hash(runtimeType,_this.messageId,_this.text,_this.sentAt,_this.localDate);
}

@override
String toString() {
  final _this = this as InterpretRequest;
  return 'InterpretRequest(messageId: ${_this.messageId}, text: ${_this.text}, sentAt: ${_this.sentAt}, localDate: ${_this.localDate})';
}


}

/// @nodoc
abstract mixin class $InterpretRequestCopyWith<$Res>  {
  factory $InterpretRequestCopyWith(InterpretRequest value, $Res Function(InterpretRequest) _then) = _$InterpretRequestCopyWithImpl;
@useResult
$Res call({
 Id messageId, String text, Instant sentAt, LocalDate localDate
});




}
/// @nodoc
class _$InterpretRequestCopyWithImpl<$Res>
    implements $InterpretRequestCopyWith<$Res> {
  _$InterpretRequestCopyWithImpl(this._self, this._then);

  final InterpretRequest _self;
  final $Res Function(InterpretRequest) _then;

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? text = null,Object? sentAt = null,Object? localDate = null,}) {
  return _then(InterpretRequest(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as Id,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as Instant,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as LocalDate,
  ));
}

}


/// Adds pattern-matching-related methods to [InterpretRequest].
extension InterpretRequestPatterns on InterpretRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterpretRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterpretRequest value)  $default,){
final _that = this;
switch (_that) {
case _InterpretRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterpretRequest value)?  $default,){
final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Id messageId,  String text,  Instant sentAt,  LocalDate localDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
return $default(_that.messageId,_that.text,_that.sentAt,_that.localDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Id messageId,  String text,  Instant sentAt,  LocalDate localDate)  $default,) {final _that = this;
switch (_that) {
case _InterpretRequest():
return $default(_that.messageId,_that.text,_that.sentAt,_that.localDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Id messageId,  String text,  Instant sentAt,  LocalDate localDate)?  $default,) {final _that = this;
switch (_that) {
case _InterpretRequest() when $default != null:
return $default(_that.messageId,_that.text,_that.sentAt,_that.localDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InterpretRequest implements InterpretRequest {
  const _InterpretRequest({required this.messageId, required this.text, required this.sentAt, required this.localDate});
  factory _InterpretRequest.fromJson(Map<String, dynamic> json) => _$InterpretRequestFromJson(json);

@override final  Id messageId;
@override final  String text;
@override final  Instant sentAt;
@override final  LocalDate localDate;

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterpretRequestCopyWith<_InterpretRequest> get copyWith => __$InterpretRequestCopyWithImpl<_InterpretRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InterpretRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterpretRequest&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.text, text) || other.text == text)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.localDate, localDate) || other.localDate == localDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,messageId,text,sentAt,localDate);
}

@override
String toString() {
    return 'InterpretRequest(messageId: $messageId, text: $text, sentAt: $sentAt, localDate: $localDate)';
}


}

/// @nodoc
abstract mixin class _$InterpretRequestCopyWith<$Res> implements $InterpretRequestCopyWith<$Res> {
  factory _$InterpretRequestCopyWith(_InterpretRequest value, $Res Function(_InterpretRequest) _then) = __$InterpretRequestCopyWithImpl;
@override @useResult
$Res call({
 Id messageId, String text, Instant sentAt, LocalDate localDate
});




}
/// @nodoc
class __$InterpretRequestCopyWithImpl<$Res>
    implements _$InterpretRequestCopyWith<$Res> {
  __$InterpretRequestCopyWithImpl(this._self, this._then);

  final _InterpretRequest _self;
  final $Res Function(_InterpretRequest) _then;

/// Create a copy of InterpretRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? text = null,Object? sentAt = null,Object? localDate = null,}) {
  return _then(_InterpretRequest(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as Id,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as Instant,localDate: null == localDate ? _self.localDate : localDate // ignore: cast_nullable_to_non_nullable
as LocalDate,
  ));
}


}

// dart format on
