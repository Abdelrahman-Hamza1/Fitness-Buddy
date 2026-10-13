// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ask_question_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AskQuestionIntent {

 String get kind; String get question; String? get topic;
/// Create a copy of AskQuestionIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AskQuestionIntentCopyWith<AskQuestionIntent> get copyWith => _$AskQuestionIntentCopyWithImpl<AskQuestionIntent>(this as AskQuestionIntent, _$identity);

  /// Serializes this AskQuestionIntent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AskQuestionIntent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AskQuestionIntent&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.question, _this.question) || other.question == _this.question)&&(identical(other.topic, _this.topic) || other.topic == _this.topic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AskQuestionIntent;
  return Object.hash(runtimeType,_this.kind,_this.question,_this.topic);
}

@override
String toString() {
  final _this = this as AskQuestionIntent;
  return 'AskQuestionIntent(kind: ${_this.kind}, question: ${_this.question}, topic: ${_this.topic})';
}


}

/// @nodoc
abstract mixin class $AskQuestionIntentCopyWith<$Res>  {
  factory $AskQuestionIntentCopyWith(AskQuestionIntent value, $Res Function(AskQuestionIntent) _then) = _$AskQuestionIntentCopyWithImpl;
@useResult
$Res call({
 String kind, String question, String? topic
});




}
/// @nodoc
class _$AskQuestionIntentCopyWithImpl<$Res>
    implements $AskQuestionIntentCopyWith<$Res> {
  _$AskQuestionIntentCopyWithImpl(this._self, this._then);

  final AskQuestionIntent _self;
  final $Res Function(AskQuestionIntent) _then;

/// Create a copy of AskQuestionIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? question = null,Object? topic = freezed,}) {
  return _then(AskQuestionIntent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AskQuestionIntent].
extension AskQuestionIntentPatterns on AskQuestionIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AskQuestionIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AskQuestionIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AskQuestionIntent value)  $default,){
final _that = this;
switch (_that) {
case _AskQuestionIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AskQuestionIntent value)?  $default,){
final _that = this;
switch (_that) {
case _AskQuestionIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String question,  String? topic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AskQuestionIntent() when $default != null:
return $default(_that.kind,_that.question,_that.topic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String question,  String? topic)  $default,) {final _that = this;
switch (_that) {
case _AskQuestionIntent():
return $default(_that.kind,_that.question,_that.topic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String question,  String? topic)?  $default,) {final _that = this;
switch (_that) {
case _AskQuestionIntent() when $default != null:
return $default(_that.kind,_that.question,_that.topic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AskQuestionIntent implements AskQuestionIntent {
  const _AskQuestionIntent({required this.kind, required this.question, required this.topic});
  factory _AskQuestionIntent.fromJson(Map<String, dynamic> json) => _$AskQuestionIntentFromJson(json);

@override final  String kind;
@override final  String question;
@override final  String? topic;

/// Create a copy of AskQuestionIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AskQuestionIntentCopyWith<_AskQuestionIntent> get copyWith => __$AskQuestionIntentCopyWithImpl<_AskQuestionIntent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AskQuestionIntentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AskQuestionIntent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.question, question) || other.question == question)&&(identical(other.topic, topic) || other.topic == topic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,question,topic);
}

@override
String toString() {
    return 'AskQuestionIntent(kind: $kind, question: $question, topic: $topic)';
}


}

/// @nodoc
abstract mixin class _$AskQuestionIntentCopyWith<$Res> implements $AskQuestionIntentCopyWith<$Res> {
  factory _$AskQuestionIntentCopyWith(_AskQuestionIntent value, $Res Function(_AskQuestionIntent) _then) = __$AskQuestionIntentCopyWithImpl;
@override @useResult
$Res call({
 String kind, String question, String? topic
});




}
/// @nodoc
class __$AskQuestionIntentCopyWithImpl<$Res>
    implements _$AskQuestionIntentCopyWith<$Res> {
  __$AskQuestionIntentCopyWithImpl(this._self, this._then);

  final _AskQuestionIntent _self;
  final $Res Function(_AskQuestionIntent) _then;

/// Create a copy of AskQuestionIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? question = null,Object? topic = freezed,}) {
  return _then(_AskQuestionIntent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
