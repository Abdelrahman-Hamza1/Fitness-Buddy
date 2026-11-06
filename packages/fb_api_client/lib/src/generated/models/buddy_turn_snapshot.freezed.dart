// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnSnapshot {

 DateTime get now; int get tzOffsetMin; List<BuddySlot> get slots; BuddyDayTotals get today;/// Up to 5 still-pending cards a follow-up may update with replaces.
 List<BuddyOpenCard> get openCards;
/// Create a copy of BuddyTurnSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnSnapshotCopyWith<BuddyTurnSnapshot> get copyWith => _$BuddyTurnSnapshotCopyWithImpl<BuddyTurnSnapshot>(this as BuddyTurnSnapshot, _$identity);

  /// Serializes this BuddyTurnSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnSnapshot&&(identical(other.now, _this.now) || other.now == _this.now)&&(identical(other.tzOffsetMin, _this.tzOffsetMin) || other.tzOffsetMin == _this.tzOffsetMin)&&const DeepCollectionEquality().equals(other.slots, _this.slots)&&(identical(other.today, _this.today) || other.today == _this.today)&&const DeepCollectionEquality().equals(other.openCards, _this.openCards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnSnapshot;
  return Object.hash(runtimeType,_this.now,_this.tzOffsetMin,const DeepCollectionEquality().hash(_this.slots),_this.today,const DeepCollectionEquality().hash(_this.openCards));
}

@override
String toString() {
  final _this = this as BuddyTurnSnapshot;
  return 'BuddyTurnSnapshot(now: ${_this.now}, tzOffsetMin: ${_this.tzOffsetMin}, slots: ${_this.slots}, today: ${_this.today}, openCards: ${_this.openCards})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnSnapshotCopyWith<$Res>  {
  factory $BuddyTurnSnapshotCopyWith(BuddyTurnSnapshot value, $Res Function(BuddyTurnSnapshot) _then) = _$BuddyTurnSnapshotCopyWithImpl;
@useResult
$Res call({
 DateTime now, int tzOffsetMin, List<BuddySlot> slots, BuddyDayTotals today, List<BuddyOpenCard> openCards
});


$BuddyDayTotalsCopyWith<$Res> get today;

}
/// @nodoc
class _$BuddyTurnSnapshotCopyWithImpl<$Res>
    implements $BuddyTurnSnapshotCopyWith<$Res> {
  _$BuddyTurnSnapshotCopyWithImpl(this._self, this._then);

  final BuddyTurnSnapshot _self;
  final $Res Function(BuddyTurnSnapshot) _then;

/// Create a copy of BuddyTurnSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? now = null,Object? tzOffsetMin = null,Object? slots = null,Object? today = null,Object? openCards = null,}) {
  return _then(BuddyTurnSnapshot(
now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,tzOffsetMin: null == tzOffsetMin ? _self.tzOffsetMin : tzOffsetMin // ignore: cast_nullable_to_non_nullable
as int,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<BuddySlot>,today: null == today ? _self.today : today // ignore: cast_nullable_to_non_nullable
as BuddyDayTotals,openCards: null == openCards ? _self.openCards : openCards // ignore: cast_nullable_to_non_nullable
as List<BuddyOpenCard>,
  ));
}
/// Create a copy of BuddyTurnSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayTotalsCopyWith<$Res> get today {
  
  return $BuddyDayTotalsCopyWith<$Res>(_self.today, (value) {
    return _then(_self.copyWith(today: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyTurnSnapshot].
extension BuddyTurnSnapshotPatterns on BuddyTurnSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime now,  int tzOffsetMin,  List<BuddySlot> slots,  BuddyDayTotals today,  List<BuddyOpenCard> openCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnSnapshot() when $default != null:
return $default(_that.now,_that.tzOffsetMin,_that.slots,_that.today,_that.openCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime now,  int tzOffsetMin,  List<BuddySlot> slots,  BuddyDayTotals today,  List<BuddyOpenCard> openCards)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnSnapshot():
return $default(_that.now,_that.tzOffsetMin,_that.slots,_that.today,_that.openCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime now,  int tzOffsetMin,  List<BuddySlot> slots,  BuddyDayTotals today,  List<BuddyOpenCard> openCards)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnSnapshot() when $default != null:
return $default(_that.now,_that.tzOffsetMin,_that.slots,_that.today,_that.openCards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnSnapshot implements BuddyTurnSnapshot {
  const _BuddyTurnSnapshot({required this.now, required this.tzOffsetMin, required  List<BuddySlot> slots, required this.today, required  List<BuddyOpenCard> openCards}): _slots = slots,_openCards = openCards;
  factory _BuddyTurnSnapshot.fromJson(Map<String, dynamic> json) => _$BuddyTurnSnapshotFromJson(json);

@override final  DateTime now;
@override final  int tzOffsetMin;
 final  List<BuddySlot> _slots;
@override List<BuddySlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

@override final  BuddyDayTotals today;
/// Up to 5 still-pending cards a follow-up may update with replaces.
 final  List<BuddyOpenCard> _openCards;
/// Up to 5 still-pending cards a follow-up may update with replaces.
@override List<BuddyOpenCard> get openCards {
  if (_openCards is EqualUnmodifiableListView) return _openCards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openCards);
}


/// Create a copy of BuddyTurnSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnSnapshotCopyWith<_BuddyTurnSnapshot> get copyWith => __$BuddyTurnSnapshotCopyWithImpl<_BuddyTurnSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnSnapshot&&(identical(other.now, now) || other.now == now)&&(identical(other.tzOffsetMin, tzOffsetMin) || other.tzOffsetMin == tzOffsetMin)&&const DeepCollectionEquality().equals(other.slots, _slots)&&(identical(other.today, today) || other.today == today)&&const DeepCollectionEquality().equals(other.openCards, _openCards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,now,tzOffsetMin,const DeepCollectionEquality().hash(_slots),today,const DeepCollectionEquality().hash(_openCards));
}

@override
String toString() {
    return 'BuddyTurnSnapshot(now: $now, tzOffsetMin: $tzOffsetMin, slots: $slots, today: $today, openCards: $openCards)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnSnapshotCopyWith<$Res> implements $BuddyTurnSnapshotCopyWith<$Res> {
  factory _$BuddyTurnSnapshotCopyWith(_BuddyTurnSnapshot value, $Res Function(_BuddyTurnSnapshot) _then) = __$BuddyTurnSnapshotCopyWithImpl;
@override @useResult
$Res call({
 DateTime now, int tzOffsetMin, List<BuddySlot> slots, BuddyDayTotals today, List<BuddyOpenCard> openCards
});


@override $BuddyDayTotalsCopyWith<$Res> get today;

}
/// @nodoc
class __$BuddyTurnSnapshotCopyWithImpl<$Res>
    implements _$BuddyTurnSnapshotCopyWith<$Res> {
  __$BuddyTurnSnapshotCopyWithImpl(this._self, this._then);

  final _BuddyTurnSnapshot _self;
  final $Res Function(_BuddyTurnSnapshot) _then;

/// Create a copy of BuddyTurnSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? now = null,Object? tzOffsetMin = null,Object? slots = null,Object? today = null,Object? openCards = null,}) {
  return _then(_BuddyTurnSnapshot(
now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,tzOffsetMin: null == tzOffsetMin ? _self.tzOffsetMin : tzOffsetMin // ignore: cast_nullable_to_non_nullable
as int,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<BuddySlot>,today: null == today ? _self.today : today // ignore: cast_nullable_to_non_nullable
as BuddyDayTotals,openCards: null == openCards ? _self._openCards : openCards // ignore: cast_nullable_to_non_nullable
as List<BuddyOpenCard>,
  ));
}

/// Create a copy of BuddyTurnSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayTotalsCopyWith<$Res> get today {
  
  return $BuddyDayTotalsCopyWith<$Res>(_self.today, (value) {
    return _then(_self.copyWith(today: value));
  });
}
}

// dart format on
