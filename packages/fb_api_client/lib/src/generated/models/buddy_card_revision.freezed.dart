// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_card_revision.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyCardRevision {

 String get proposalId; int get expectedRevision;
/// Create a copy of BuddyCardRevision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyCardRevisionCopyWith<BuddyCardRevision> get copyWith => _$BuddyCardRevisionCopyWithImpl<BuddyCardRevision>(this as BuddyCardRevision, _$identity);

  /// Serializes this BuddyCardRevision to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyCardRevision;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyCardRevision&&(identical(other.proposalId, _this.proposalId) || other.proposalId == _this.proposalId)&&(identical(other.expectedRevision, _this.expectedRevision) || other.expectedRevision == _this.expectedRevision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyCardRevision;
  return Object.hash(runtimeType,_this.proposalId,_this.expectedRevision);
}

@override
String toString() {
  final _this = this as BuddyCardRevision;
  return 'BuddyCardRevision(proposalId: ${_this.proposalId}, expectedRevision: ${_this.expectedRevision})';
}


}

/// @nodoc
abstract mixin class $BuddyCardRevisionCopyWith<$Res>  {
  factory $BuddyCardRevisionCopyWith(BuddyCardRevision value, $Res Function(BuddyCardRevision) _then) = _$BuddyCardRevisionCopyWithImpl;
@useResult
$Res call({
 String proposalId, int expectedRevision
});




}
/// @nodoc
class _$BuddyCardRevisionCopyWithImpl<$Res>
    implements $BuddyCardRevisionCopyWith<$Res> {
  _$BuddyCardRevisionCopyWithImpl(this._self, this._then);

  final BuddyCardRevision _self;
  final $Res Function(BuddyCardRevision) _then;

/// Create a copy of BuddyCardRevision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? proposalId = null,Object? expectedRevision = null,}) {
  return _then(BuddyCardRevision(
proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,expectedRevision: null == expectedRevision ? _self.expectedRevision : expectedRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyCardRevision].
extension BuddyCardRevisionPatterns on BuddyCardRevision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyCardRevision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyCardRevision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyCardRevision value)  $default,){
final _that = this;
switch (_that) {
case _BuddyCardRevision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyCardRevision value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyCardRevision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String proposalId,  int expectedRevision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyCardRevision() when $default != null:
return $default(_that.proposalId,_that.expectedRevision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String proposalId,  int expectedRevision)  $default,) {final _that = this;
switch (_that) {
case _BuddyCardRevision():
return $default(_that.proposalId,_that.expectedRevision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String proposalId,  int expectedRevision)?  $default,) {final _that = this;
switch (_that) {
case _BuddyCardRevision() when $default != null:
return $default(_that.proposalId,_that.expectedRevision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyCardRevision implements BuddyCardRevision {
  const _BuddyCardRevision({required this.proposalId, required this.expectedRevision});
  factory _BuddyCardRevision.fromJson(Map<String, dynamic> json) => _$BuddyCardRevisionFromJson(json);

@override final  String proposalId;
@override final  int expectedRevision;

/// Create a copy of BuddyCardRevision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyCardRevisionCopyWith<_BuddyCardRevision> get copyWith => __$BuddyCardRevisionCopyWithImpl<_BuddyCardRevision>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyCardRevisionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyCardRevision&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.expectedRevision, expectedRevision) || other.expectedRevision == expectedRevision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,proposalId,expectedRevision);
}

@override
String toString() {
    return 'BuddyCardRevision(proposalId: $proposalId, expectedRevision: $expectedRevision)';
}


}

/// @nodoc
abstract mixin class _$BuddyCardRevisionCopyWith<$Res> implements $BuddyCardRevisionCopyWith<$Res> {
  factory _$BuddyCardRevisionCopyWith(_BuddyCardRevision value, $Res Function(_BuddyCardRevision) _then) = __$BuddyCardRevisionCopyWithImpl;
@override @useResult
$Res call({
 String proposalId, int expectedRevision
});




}
/// @nodoc
class __$BuddyCardRevisionCopyWithImpl<$Res>
    implements _$BuddyCardRevisionCopyWith<$Res> {
  __$BuddyCardRevisionCopyWithImpl(this._self, this._then);

  final _BuddyCardRevision _self;
  final $Res Function(_BuddyCardRevision) _then;

/// Create a copy of BuddyCardRevision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? proposalId = null,Object? expectedRevision = null,}) {
  return _then(_BuddyCardRevision(
proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,expectedRevision: null == expectedRevision ? _self.expectedRevision : expectedRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
