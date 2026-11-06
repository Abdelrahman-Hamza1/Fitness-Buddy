// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_open_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyOpenCard {

 String get kind; String get proposalId; int get revision; String get summary;
/// Create a copy of BuddyOpenCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyOpenCardCopyWith<BuddyOpenCard> get copyWith => _$BuddyOpenCardCopyWithImpl<BuddyOpenCard>(this as BuddyOpenCard, _$identity);

  /// Serializes this BuddyOpenCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyOpenCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyOpenCard&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.proposalId, _this.proposalId) || other.proposalId == _this.proposalId)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.summary, _this.summary) || other.summary == _this.summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyOpenCard;
  return Object.hash(runtimeType,_this.kind,_this.proposalId,_this.revision,_this.summary);
}

@override
String toString() {
  final _this = this as BuddyOpenCard;
  return 'BuddyOpenCard(kind: ${_this.kind}, proposalId: ${_this.proposalId}, revision: ${_this.revision}, summary: ${_this.summary})';
}


}

/// @nodoc
abstract mixin class $BuddyOpenCardCopyWith<$Res>  {
  factory $BuddyOpenCardCopyWith(BuddyOpenCard value, $Res Function(BuddyOpenCard) _then) = _$BuddyOpenCardCopyWithImpl;
@useResult
$Res call({
 String kind, String proposalId, int revision, String summary
});




}
/// @nodoc
class _$BuddyOpenCardCopyWithImpl<$Res>
    implements $BuddyOpenCardCopyWith<$Res> {
  _$BuddyOpenCardCopyWithImpl(this._self, this._then);

  final BuddyOpenCard _self;
  final $Res Function(BuddyOpenCard) _then;

/// Create a copy of BuddyOpenCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? proposalId = null,Object? revision = null,Object? summary = null,}) {
  return _then(BuddyOpenCard(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyOpenCard].
extension BuddyOpenCardPatterns on BuddyOpenCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyOpenCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyOpenCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyOpenCard value)  $default,){
final _that = this;
switch (_that) {
case _BuddyOpenCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyOpenCard value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyOpenCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String proposalId,  int revision,  String summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyOpenCard() when $default != null:
return $default(_that.kind,_that.proposalId,_that.revision,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String proposalId,  int revision,  String summary)  $default,) {final _that = this;
switch (_that) {
case _BuddyOpenCard():
return $default(_that.kind,_that.proposalId,_that.revision,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String proposalId,  int revision,  String summary)?  $default,) {final _that = this;
switch (_that) {
case _BuddyOpenCard() when $default != null:
return $default(_that.kind,_that.proposalId,_that.revision,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyOpenCard implements BuddyOpenCard {
  const _BuddyOpenCard({required this.kind, required this.proposalId, required this.revision, required this.summary});
  factory _BuddyOpenCard.fromJson(Map<String, dynamic> json) => _$BuddyOpenCardFromJson(json);

@override final  String kind;
@override final  String proposalId;
@override final  int revision;
@override final  String summary;

/// Create a copy of BuddyOpenCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyOpenCardCopyWith<_BuddyOpenCard> get copyWith => __$BuddyOpenCardCopyWithImpl<_BuddyOpenCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyOpenCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyOpenCard&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,proposalId,revision,summary);
}

@override
String toString() {
    return 'BuddyOpenCard(kind: $kind, proposalId: $proposalId, revision: $revision, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$BuddyOpenCardCopyWith<$Res> implements $BuddyOpenCardCopyWith<$Res> {
  factory _$BuddyOpenCardCopyWith(_BuddyOpenCard value, $Res Function(_BuddyOpenCard) _then) = __$BuddyOpenCardCopyWithImpl;
@override @useResult
$Res call({
 String kind, String proposalId, int revision, String summary
});




}
/// @nodoc
class __$BuddyOpenCardCopyWithImpl<$Res>
    implements _$BuddyOpenCardCopyWith<$Res> {
  __$BuddyOpenCardCopyWithImpl(this._self, this._then);

  final _BuddyOpenCard _self;
  final $Res Function(_BuddyOpenCard) _then;

/// Create a copy of BuddyOpenCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? proposalId = null,Object? revision = null,Object? summary = null,}) {
  return _then(_BuddyOpenCard(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
