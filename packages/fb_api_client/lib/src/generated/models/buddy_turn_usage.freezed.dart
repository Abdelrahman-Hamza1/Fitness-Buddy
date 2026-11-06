// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_usage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnUsage {

 int get sends; int get inputTokens; int get outputTokens;
/// Create a copy of BuddyTurnUsage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnUsageCopyWith<BuddyTurnUsage> get copyWith => _$BuddyTurnUsageCopyWithImpl<BuddyTurnUsage>(this as BuddyTurnUsage, _$identity);

  /// Serializes this BuddyTurnUsage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnUsage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnUsage&&(identical(other.sends, _this.sends) || other.sends == _this.sends)&&(identical(other.inputTokens, _this.inputTokens) || other.inputTokens == _this.inputTokens)&&(identical(other.outputTokens, _this.outputTokens) || other.outputTokens == _this.outputTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnUsage;
  return Object.hash(runtimeType,_this.sends,_this.inputTokens,_this.outputTokens);
}

@override
String toString() {
  final _this = this as BuddyTurnUsage;
  return 'BuddyTurnUsage(sends: ${_this.sends}, inputTokens: ${_this.inputTokens}, outputTokens: ${_this.outputTokens})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnUsageCopyWith<$Res>  {
  factory $BuddyTurnUsageCopyWith(BuddyTurnUsage value, $Res Function(BuddyTurnUsage) _then) = _$BuddyTurnUsageCopyWithImpl;
@useResult
$Res call({
 int sends, int inputTokens, int outputTokens
});




}
/// @nodoc
class _$BuddyTurnUsageCopyWithImpl<$Res>
    implements $BuddyTurnUsageCopyWith<$Res> {
  _$BuddyTurnUsageCopyWithImpl(this._self, this._then);

  final BuddyTurnUsage _self;
  final $Res Function(BuddyTurnUsage) _then;

/// Create a copy of BuddyTurnUsage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sends = null,Object? inputTokens = null,Object? outputTokens = null,}) {
  return _then(BuddyTurnUsage(
sends: null == sends ? _self.sends : sends // ignore: cast_nullable_to_non_nullable
as int,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyTurnUsage].
extension BuddyTurnUsagePatterns on BuddyTurnUsage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnUsage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnUsage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnUsage value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnUsage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnUsage value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnUsage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int sends,  int inputTokens,  int outputTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnUsage() when $default != null:
return $default(_that.sends,_that.inputTokens,_that.outputTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int sends,  int inputTokens,  int outputTokens)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnUsage():
return $default(_that.sends,_that.inputTokens,_that.outputTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int sends,  int inputTokens,  int outputTokens)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnUsage() when $default != null:
return $default(_that.sends,_that.inputTokens,_that.outputTokens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnUsage implements BuddyTurnUsage {
  const _BuddyTurnUsage({required this.sends, required this.inputTokens, required this.outputTokens});
  factory _BuddyTurnUsage.fromJson(Map<String, dynamic> json) => _$BuddyTurnUsageFromJson(json);

@override final  int sends;
@override final  int inputTokens;
@override final  int outputTokens;

/// Create a copy of BuddyTurnUsage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnUsageCopyWith<_BuddyTurnUsage> get copyWith => __$BuddyTurnUsageCopyWithImpl<_BuddyTurnUsage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnUsageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnUsage&&(identical(other.sends, sends) || other.sends == sends)&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sends,inputTokens,outputTokens);
}

@override
String toString() {
    return 'BuddyTurnUsage(sends: $sends, inputTokens: $inputTokens, outputTokens: $outputTokens)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnUsageCopyWith<$Res> implements $BuddyTurnUsageCopyWith<$Res> {
  factory _$BuddyTurnUsageCopyWith(_BuddyTurnUsage value, $Res Function(_BuddyTurnUsage) _then) = __$BuddyTurnUsageCopyWithImpl;
@override @useResult
$Res call({
 int sends, int inputTokens, int outputTokens
});




}
/// @nodoc
class __$BuddyTurnUsageCopyWithImpl<$Res>
    implements _$BuddyTurnUsageCopyWith<$Res> {
  __$BuddyTurnUsageCopyWithImpl(this._self, this._then);

  final _BuddyTurnUsage _self;
  final $Res Function(_BuddyTurnUsage) _then;

/// Create a copy of BuddyTurnUsage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sends = null,Object? inputTokens = null,Object? outputTokens = null,}) {
  return _then(_BuddyTurnUsage(
sends: null == sends ? _self.sends : sends // ignore: cast_nullable_to_non_nullable
as int,inputTokens: null == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int,outputTokens: null == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
