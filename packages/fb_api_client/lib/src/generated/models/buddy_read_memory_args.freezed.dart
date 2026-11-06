// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_read_memory_args.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyReadMemoryArgs {

 String? get topic;
/// Create a copy of BuddyReadMemoryArgs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyReadMemoryArgsCopyWith<BuddyReadMemoryArgs> get copyWith => _$BuddyReadMemoryArgsCopyWithImpl<BuddyReadMemoryArgs>(this as BuddyReadMemoryArgs, _$identity);

  /// Serializes this BuddyReadMemoryArgs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyReadMemoryArgs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyReadMemoryArgs&&(identical(other.topic, _this.topic) || other.topic == _this.topic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyReadMemoryArgs;
  return Object.hash(runtimeType,_this.topic);
}

@override
String toString() {
  final _this = this as BuddyReadMemoryArgs;
  return 'BuddyReadMemoryArgs(topic: ${_this.topic})';
}


}

/// @nodoc
abstract mixin class $BuddyReadMemoryArgsCopyWith<$Res>  {
  factory $BuddyReadMemoryArgsCopyWith(BuddyReadMemoryArgs value, $Res Function(BuddyReadMemoryArgs) _then) = _$BuddyReadMemoryArgsCopyWithImpl;
@useResult
$Res call({
 String? topic
});




}
/// @nodoc
class _$BuddyReadMemoryArgsCopyWithImpl<$Res>
    implements $BuddyReadMemoryArgsCopyWith<$Res> {
  _$BuddyReadMemoryArgsCopyWithImpl(this._self, this._then);

  final BuddyReadMemoryArgs _self;
  final $Res Function(BuddyReadMemoryArgs) _then;

/// Create a copy of BuddyReadMemoryArgs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topic = freezed,}) {
  return _then(BuddyReadMemoryArgs(
topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyReadMemoryArgs].
extension BuddyReadMemoryArgsPatterns on BuddyReadMemoryArgs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyReadMemoryArgs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyReadMemoryArgs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyReadMemoryArgs value)  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryArgs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyReadMemoryArgs value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyReadMemoryArgs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? topic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyReadMemoryArgs() when $default != null:
return $default(_that.topic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? topic)  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryArgs():
return $default(_that.topic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? topic)?  $default,) {final _that = this;
switch (_that) {
case _BuddyReadMemoryArgs() when $default != null:
return $default(_that.topic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyReadMemoryArgs implements BuddyReadMemoryArgs {
  const _BuddyReadMemoryArgs({required this.topic});
  factory _BuddyReadMemoryArgs.fromJson(Map<String, dynamic> json) => _$BuddyReadMemoryArgsFromJson(json);

@override final  String? topic;

/// Create a copy of BuddyReadMemoryArgs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyReadMemoryArgsCopyWith<_BuddyReadMemoryArgs> get copyWith => __$BuddyReadMemoryArgsCopyWithImpl<_BuddyReadMemoryArgs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyReadMemoryArgsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyReadMemoryArgs&&(identical(other.topic, topic) || other.topic == topic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,topic);
}

@override
String toString() {
    return 'BuddyReadMemoryArgs(topic: $topic)';
}


}

/// @nodoc
abstract mixin class _$BuddyReadMemoryArgsCopyWith<$Res> implements $BuddyReadMemoryArgsCopyWith<$Res> {
  factory _$BuddyReadMemoryArgsCopyWith(_BuddyReadMemoryArgs value, $Res Function(_BuddyReadMemoryArgs) _then) = __$BuddyReadMemoryArgsCopyWithImpl;
@override @useResult
$Res call({
 String? topic
});




}
/// @nodoc
class __$BuddyReadMemoryArgsCopyWithImpl<$Res>
    implements _$BuddyReadMemoryArgsCopyWith<$Res> {
  __$BuddyReadMemoryArgsCopyWithImpl(this._self, this._then);

  final _BuddyReadMemoryArgs _self;
  final $Res Function(_BuddyReadMemoryArgs) _then;

/// Create a copy of BuddyReadMemoryArgs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topic = freezed,}) {
  return _then(_BuddyReadMemoryArgs(
topic: freezed == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
