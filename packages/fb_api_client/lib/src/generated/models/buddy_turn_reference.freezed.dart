// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_reference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnReference {

 String get turnId;
/// Create a copy of BuddyTurnReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnReferenceCopyWith<BuddyTurnReference> get copyWith => _$BuddyTurnReferenceCopyWithImpl<BuddyTurnReference>(this as BuddyTurnReference, _$identity);

  /// Serializes this BuddyTurnReference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnReference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnReference&&(identical(other.turnId, _this.turnId) || other.turnId == _this.turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnReference;
  return Object.hash(runtimeType,_this.turnId);
}

@override
String toString() {
  final _this = this as BuddyTurnReference;
  return 'BuddyTurnReference(turnId: ${_this.turnId})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnReferenceCopyWith<$Res>  {
  factory $BuddyTurnReferenceCopyWith(BuddyTurnReference value, $Res Function(BuddyTurnReference) _then) = _$BuddyTurnReferenceCopyWithImpl;
@useResult
$Res call({
 String turnId
});




}
/// @nodoc
class _$BuddyTurnReferenceCopyWithImpl<$Res>
    implements $BuddyTurnReferenceCopyWith<$Res> {
  _$BuddyTurnReferenceCopyWithImpl(this._self, this._then);

  final BuddyTurnReference _self;
  final $Res Function(BuddyTurnReference) _then;

/// Create a copy of BuddyTurnReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? turnId = null,}) {
  return _then(BuddyTurnReference(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyTurnReference].
extension BuddyTurnReferencePatterns on BuddyTurnReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnReference value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnReference value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String turnId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnReference() when $default != null:
return $default(_that.turnId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String turnId)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnReference():
return $default(_that.turnId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String turnId)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnReference() when $default != null:
return $default(_that.turnId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnReference implements BuddyTurnReference {
  const _BuddyTurnReference({required this.turnId});
  factory _BuddyTurnReference.fromJson(Map<String, dynamic> json) => _$BuddyTurnReferenceFromJson(json);

@override final  String turnId;

/// Create a copy of BuddyTurnReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnReferenceCopyWith<_BuddyTurnReference> get copyWith => __$BuddyTurnReferenceCopyWithImpl<_BuddyTurnReference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnReferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnReference&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId);
}

@override
String toString() {
    return 'BuddyTurnReference(turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnReferenceCopyWith<$Res> implements $BuddyTurnReferenceCopyWith<$Res> {
  factory _$BuddyTurnReferenceCopyWith(_BuddyTurnReference value, $Res Function(_BuddyTurnReference) _then) = __$BuddyTurnReferenceCopyWithImpl;
@override @useResult
$Res call({
 String turnId
});




}
/// @nodoc
class __$BuddyTurnReferenceCopyWithImpl<$Res>
    implements _$BuddyTurnReferenceCopyWith<$Res> {
  __$BuddyTurnReferenceCopyWithImpl(this._self, this._then);

  final _BuddyTurnReference _self;
  final $Res Function(_BuddyTurnReference) _then;

/// Create a copy of BuddyTurnReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? turnId = null,}) {
  return _then(_BuddyTurnReference(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
