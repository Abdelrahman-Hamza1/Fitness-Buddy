// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_prior_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyPriorCard {

 String get proposalId; BuddyPriorCardStatus get status;/// The card's compact summary.
 String get line;
/// Create a copy of BuddyPriorCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyPriorCardCopyWith<BuddyPriorCard> get copyWith => _$BuddyPriorCardCopyWithImpl<BuddyPriorCard>(this as BuddyPriorCard, _$identity);

  /// Serializes this BuddyPriorCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyPriorCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyPriorCard&&(identical(other.proposalId, _this.proposalId) || other.proposalId == _this.proposalId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.line, _this.line) || other.line == _this.line));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyPriorCard;
  return Object.hash(runtimeType,_this.proposalId,_this.status,_this.line);
}

@override
String toString() {
  final _this = this as BuddyPriorCard;
  return 'BuddyPriorCard(proposalId: ${_this.proposalId}, status: ${_this.status}, line: ${_this.line})';
}


}

/// @nodoc
abstract mixin class $BuddyPriorCardCopyWith<$Res>  {
  factory $BuddyPriorCardCopyWith(BuddyPriorCard value, $Res Function(BuddyPriorCard) _then) = _$BuddyPriorCardCopyWithImpl;
@useResult
$Res call({
 String proposalId, BuddyPriorCardStatus status, String line
});




}
/// @nodoc
class _$BuddyPriorCardCopyWithImpl<$Res>
    implements $BuddyPriorCardCopyWith<$Res> {
  _$BuddyPriorCardCopyWithImpl(this._self, this._then);

  final BuddyPriorCard _self;
  final $Res Function(BuddyPriorCard) _then;

/// Create a copy of BuddyPriorCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? proposalId = null,Object? status = null,Object? line = null,}) {
  return _then(BuddyPriorCard(
proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuddyPriorCardStatus,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyPriorCard].
extension BuddyPriorCardPatterns on BuddyPriorCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyPriorCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyPriorCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyPriorCard value)  $default,){
final _that = this;
switch (_that) {
case _BuddyPriorCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyPriorCard value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyPriorCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String proposalId,  BuddyPriorCardStatus status,  String line)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyPriorCard() when $default != null:
return $default(_that.proposalId,_that.status,_that.line);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String proposalId,  BuddyPriorCardStatus status,  String line)  $default,) {final _that = this;
switch (_that) {
case _BuddyPriorCard():
return $default(_that.proposalId,_that.status,_that.line);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String proposalId,  BuddyPriorCardStatus status,  String line)?  $default,) {final _that = this;
switch (_that) {
case _BuddyPriorCard() when $default != null:
return $default(_that.proposalId,_that.status,_that.line);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyPriorCard implements BuddyPriorCard {
  const _BuddyPriorCard({required this.proposalId, required this.status, required this.line});
  factory _BuddyPriorCard.fromJson(Map<String, dynamic> json) => _$BuddyPriorCardFromJson(json);

@override final  String proposalId;
@override final  BuddyPriorCardStatus status;
/// The card's compact summary.
@override final  String line;

/// Create a copy of BuddyPriorCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyPriorCardCopyWith<_BuddyPriorCard> get copyWith => __$BuddyPriorCardCopyWithImpl<_BuddyPriorCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyPriorCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyPriorCard&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.status, status) || other.status == status)&&(identical(other.line, line) || other.line == line));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,proposalId,status,line);
}

@override
String toString() {
    return 'BuddyPriorCard(proposalId: $proposalId, status: $status, line: $line)';
}


}

/// @nodoc
abstract mixin class _$BuddyPriorCardCopyWith<$Res> implements $BuddyPriorCardCopyWith<$Res> {
  factory _$BuddyPriorCardCopyWith(_BuddyPriorCard value, $Res Function(_BuddyPriorCard) _then) = __$BuddyPriorCardCopyWithImpl;
@override @useResult
$Res call({
 String proposalId, BuddyPriorCardStatus status, String line
});




}
/// @nodoc
class __$BuddyPriorCardCopyWithImpl<$Res>
    implements _$BuddyPriorCardCopyWith<$Res> {
  __$BuddyPriorCardCopyWithImpl(this._self, this._then);

  final _BuddyPriorCard _self;
  final $Res Function(_BuddyPriorCard) _then;

/// Create a copy of BuddyPriorCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? proposalId = null,Object? status = null,Object? line = null,}) {
  return _then(_BuddyPriorCard(
proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuddyPriorCardStatus,line: null == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
