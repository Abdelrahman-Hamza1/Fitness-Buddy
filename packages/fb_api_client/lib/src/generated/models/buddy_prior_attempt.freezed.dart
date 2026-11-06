// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_prior_attempt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPriorAttempt {

 int get attempt; List<BuddyPriorCard> get cards;
/// Create a copy of BuddyPriorAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPriorAttemptCopyWith<BuddyPriorAttempt> get copyWith => _$BuddyPriorAttemptCopyWithImpl<BuddyPriorAttempt>(this as BuddyPriorAttempt, _$identity);

  /// Serializes this BuddyPriorAttempt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPriorAttempt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPriorAttempt&&(identical(other.attempt, _this.attempt) || other.attempt == _this.attempt)&&const DeepCollectionEquality().equals(other.cards, _this.cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPriorAttempt;
  return Object.hash(runtimeType,_this.attempt,const DeepCollectionEquality().hash(_this.cards));
}

@override
String toString() {
  final _this = this as BuddyPriorAttempt;
  return 'BuddyPriorAttempt(attempt: ${_this.attempt}, cards: ${_this.cards})';
}


}

/// @nodoc
abstract mixin class $BuddyPriorAttemptCopyWith<$Res>  {
  factory $BuddyPriorAttemptCopyWith(BuddyPriorAttempt value, $Res Function(BuddyPriorAttempt) _then) = _$BuddyPriorAttemptCopyWithImpl;
@useResult
$Res call({
 int attempt, List<BuddyPriorCard> cards
});




}
/// @nodoc
class _$BuddyPriorAttemptCopyWithImpl<$Res>
    implements $BuddyPriorAttemptCopyWith<$Res> {
  _$BuddyPriorAttemptCopyWithImpl(this._self, this._then);

  final BuddyPriorAttempt _self;
  final $Res Function(BuddyPriorAttempt) _then;

/// Create a copy of BuddyPriorAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempt = null,Object? cards = null,}) {
  return _then(BuddyPriorAttempt(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<BuddyPriorCard>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyPriorAttempt].
extension BuddyPriorAttemptPatterns on BuddyPriorAttempt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPriorAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPriorAttempt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPriorAttempt value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPriorAttempt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPriorAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPriorAttempt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int attempt,  List<BuddyPriorCard> cards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPriorAttempt() when $default != null:
return $default(_that.attempt,_that.cards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int attempt,  List<BuddyPriorCard> cards)  $default,) {final _that = this;
switch (_that) {
case _BuddyPriorAttempt():
return $default(_that.attempt,_that.cards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int attempt,  List<BuddyPriorCard> cards)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPriorAttempt() when $default != null:
return $default(_that.attempt,_that.cards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPriorAttempt implements BuddyPriorAttempt {
  const _BuddyPriorAttempt({required this.attempt, required  List<BuddyPriorCard> cards}): _cards = cards;
  factory _BuddyPriorAttempt.fromJson(Map<String, dynamic> json) => _$BuddyPriorAttemptFromJson(json);

@override final  int attempt;
 final  List<BuddyPriorCard> _cards;
@override List<BuddyPriorCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}


/// Create a copy of BuddyPriorAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPriorAttemptCopyWith<_BuddyPriorAttempt> get copyWith => __$BuddyPriorAttemptCopyWithImpl<_BuddyPriorAttempt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPriorAttemptToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPriorAttempt&&(identical(other.attempt, attempt) || other.attempt == attempt)&&const DeepCollectionEquality().equals(other.cards, _cards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,attempt,const DeepCollectionEquality().hash(_cards));
}

@override
String toString() {
    return 'BuddyPriorAttempt(attempt: $attempt, cards: $cards)';
}


}

/// @nodoc
abstract mixin class _$BuddyPriorAttemptCopyWith<$Res> implements $BuddyPriorAttemptCopyWith<$Res> {
  factory _$BuddyPriorAttemptCopyWith(_BuddyPriorAttempt value, $Res Function(_BuddyPriorAttempt) _then) = __$BuddyPriorAttemptCopyWithImpl;
@override @useResult
$Res call({
 int attempt, List<BuddyPriorCard> cards
});




}
/// @nodoc
class __$BuddyPriorAttemptCopyWithImpl<$Res>
    implements _$BuddyPriorAttemptCopyWith<$Res> {
  __$BuddyPriorAttemptCopyWithImpl(this._self, this._then);

  final _BuddyPriorAttempt _self;
  final $Res Function(_BuddyPriorAttempt) _then;

/// Create a copy of BuddyPriorAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempt = null,Object? cards = null,}) {
  return _then(_BuddyPriorAttempt(
attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<BuddyPriorCard>,
  ));
}


}

// dart format on
