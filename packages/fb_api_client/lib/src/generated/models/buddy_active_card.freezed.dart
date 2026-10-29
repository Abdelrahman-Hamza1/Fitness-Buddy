// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_active_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyActiveCard {

/// The card's slot name.
 String? get slot;/// The card's local time, HH:mm.
 String? get time;/// At most 30 lines.
 List<BuddyActiveCardLine> get lines;
/// Create a copy of BuddyActiveCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyActiveCardCopyWith<BuddyActiveCard> get copyWith => _$BuddyActiveCardCopyWithImpl<BuddyActiveCard>(this as BuddyActiveCard, _$identity);

  /// Serializes this BuddyActiveCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyActiveCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyActiveCard&&(identical(other.slot, _this.slot) || other.slot == _this.slot)&&(identical(other.time, _this.time) || other.time == _this.time)&&const DeepCollectionEquality().equals(other.lines, _this.lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyActiveCard;
  return Object.hash(runtimeType,_this.slot,_this.time,const DeepCollectionEquality().hash(_this.lines));
}

@override
String toString() {
  final _this = this as BuddyActiveCard;
  return 'BuddyActiveCard(slot: ${_this.slot}, time: ${_this.time}, lines: ${_this.lines})';
}


}

/// @nodoc
abstract mixin class $BuddyActiveCardCopyWith<$Res>  {
  factory $BuddyActiveCardCopyWith(BuddyActiveCard value, $Res Function(BuddyActiveCard) _then) = _$BuddyActiveCardCopyWithImpl;
@useResult
$Res call({
 String? slot, String? time, List<BuddyActiveCardLine> lines
});




}
/// @nodoc
class _$BuddyActiveCardCopyWithImpl<$Res>
    implements $BuddyActiveCardCopyWith<$Res> {
  _$BuddyActiveCardCopyWithImpl(this._self, this._then);

  final BuddyActiveCard _self;
  final $Res Function(BuddyActiveCard) _then;

/// Create a copy of BuddyActiveCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slot = freezed,Object? time = freezed,Object? lines = null,}) {
  return _then(BuddyActiveCard(
slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String?,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<BuddyActiveCardLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyActiveCard].
extension BuddyActiveCardPatterns on BuddyActiveCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyActiveCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyActiveCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyActiveCard value)  $default,){
final _that = this;
switch (_that) {
case _BuddyActiveCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyActiveCard value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyActiveCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? slot,  String? time,  List<BuddyActiveCardLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyActiveCard() when $default != null:
return $default(_that.slot,_that.time,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? slot,  String? time,  List<BuddyActiveCardLine> lines)  $default,) {final _that = this;
switch (_that) {
case _BuddyActiveCard():
return $default(_that.slot,_that.time,_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? slot,  String? time,  List<BuddyActiveCardLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _BuddyActiveCard() when $default != null:
return $default(_that.slot,_that.time,_that.lines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyActiveCard implements BuddyActiveCard {
  const _BuddyActiveCard({required this.slot, required this.time, required  List<BuddyActiveCardLine> lines}): _lines = lines;
  factory _BuddyActiveCard.fromJson(Map<String, dynamic> json) => _$BuddyActiveCardFromJson(json);

/// The card's slot name.
@override final  String? slot;
/// The card's local time, HH:mm.
@override final  String? time;
/// At most 30 lines.
 final  List<BuddyActiveCardLine> _lines;
/// At most 30 lines.
@override List<BuddyActiveCardLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of BuddyActiveCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyActiveCardCopyWith<_BuddyActiveCard> get copyWith => __$BuddyActiveCardCopyWithImpl<_BuddyActiveCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyActiveCardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyActiveCard&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other.lines, _lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,slot,time,const DeepCollectionEquality().hash(_lines));
}

@override
String toString() {
    return 'BuddyActiveCard(slot: $slot, time: $time, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$BuddyActiveCardCopyWith<$Res> implements $BuddyActiveCardCopyWith<$Res> {
  factory _$BuddyActiveCardCopyWith(_BuddyActiveCard value, $Res Function(_BuddyActiveCard) _then) = __$BuddyActiveCardCopyWithImpl;
@override @useResult
$Res call({
 String? slot, String? time, List<BuddyActiveCardLine> lines
});




}
/// @nodoc
class __$BuddyActiveCardCopyWithImpl<$Res>
    implements _$BuddyActiveCardCopyWith<$Res> {
  __$BuddyActiveCardCopyWithImpl(this._self, this._then);

  final _BuddyActiveCard _self;
  final $Res Function(_BuddyActiveCard) _then;

/// Create a copy of BuddyActiveCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slot = freezed,Object? time = freezed,Object? lines = null,}) {
  return _then(_BuddyActiveCard(
slot: freezed == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String?,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<BuddyActiveCardLine>,
  ));
}


}

// dart format on
