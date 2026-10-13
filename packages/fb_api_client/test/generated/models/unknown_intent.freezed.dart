// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unknown_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnknownIntent {

 String get kind; String? get reason;
/// Create a copy of UnknownIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownIntentCopyWith<UnknownIntent> get copyWith => _$UnknownIntentCopyWithImpl<UnknownIntent>(this as UnknownIntent, _$identity);

  /// Serializes this UnknownIntent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UnknownIntent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownIntent&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UnknownIntent;
  return Object.hash(runtimeType,_this.kind,_this.reason);
}

@override
String toString() {
  final _this = this as UnknownIntent;
  return 'UnknownIntent(kind: ${_this.kind}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $UnknownIntentCopyWith<$Res>  {
  factory $UnknownIntentCopyWith(UnknownIntent value, $Res Function(UnknownIntent) _then) = _$UnknownIntentCopyWithImpl;
@useResult
$Res call({
 String kind, String? reason
});




}
/// @nodoc
class _$UnknownIntentCopyWithImpl<$Res>
    implements $UnknownIntentCopyWith<$Res> {
  _$UnknownIntentCopyWithImpl(this._self, this._then);

  final UnknownIntent _self;
  final $Res Function(UnknownIntent) _then;

/// Create a copy of UnknownIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? reason = freezed,}) {
  return _then(UnknownIntent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UnknownIntent].
extension UnknownIntentPatterns on UnknownIntent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnknownIntent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnknownIntent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnknownIntent value)  $default,){
final _that = this;
switch (_that) {
case _UnknownIntent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnknownIntent value)?  $default,){
final _that = this;
switch (_that) {
case _UnknownIntent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnknownIntent() when $default != null:
return $default(_that.kind,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _UnknownIntent():
return $default(_that.kind,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _UnknownIntent() when $default != null:
return $default(_that.kind,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnknownIntent implements UnknownIntent {
  const _UnknownIntent({required this.kind, required this.reason});
  factory _UnknownIntent.fromJson(Map<String, dynamic> json) => _$UnknownIntentFromJson(json);

@override final  String kind;
@override final  String? reason;

/// Create a copy of UnknownIntent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnknownIntentCopyWith<_UnknownIntent> get copyWith => __$UnknownIntentCopyWithImpl<_UnknownIntent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnknownIntentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnknownIntent&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,reason);
}

@override
String toString() {
    return 'UnknownIntent(kind: $kind, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$UnknownIntentCopyWith<$Res> implements $UnknownIntentCopyWith<$Res> {
  factory _$UnknownIntentCopyWith(_UnknownIntent value, $Res Function(_UnknownIntent) _then) = __$UnknownIntentCopyWithImpl;
@override @useResult
$Res call({
 String kind, String? reason
});




}
/// @nodoc
class __$UnknownIntentCopyWithImpl<$Res>
    implements _$UnknownIntentCopyWith<$Res> {
  __$UnknownIntentCopyWithImpl(this._self, this._then);

  final _UnknownIntent _self;
  final $Res Function(_UnknownIntent) _then;

/// Create a copy of UnknownIntent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? reason = freezed,}) {
  return _then(_UnknownIntent(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
