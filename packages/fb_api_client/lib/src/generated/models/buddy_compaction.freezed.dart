// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_compaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyCompaction {

 List<BuddyHistoryEntry> get evicted;/// The summary revision the phone holds (0 when it has none); the returned summary has previousRevision + 1 and is stored only if the phone's revision still matches.
 int get previousRevision;
/// Create a copy of BuddyCompaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyCompactionCopyWith<BuddyCompaction> get copyWith => _$BuddyCompactionCopyWithImpl<BuddyCompaction>(this as BuddyCompaction, _$identity);

  /// Serializes this BuddyCompaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyCompaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyCompaction&&const DeepCollectionEquality().equals(other.evicted, _this.evicted)&&(identical(other.previousRevision, _this.previousRevision) || other.previousRevision == _this.previousRevision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyCompaction;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.evicted),_this.previousRevision);
}

@override
String toString() {
  final _this = this as BuddyCompaction;
  return 'BuddyCompaction(evicted: ${_this.evicted}, previousRevision: ${_this.previousRevision})';
}


}

/// @nodoc
abstract mixin class $BuddyCompactionCopyWith<$Res>  {
  factory $BuddyCompactionCopyWith(BuddyCompaction value, $Res Function(BuddyCompaction) _then) = _$BuddyCompactionCopyWithImpl;
@useResult
$Res call({
 List<BuddyHistoryEntry> evicted, int previousRevision
});




}
/// @nodoc
class _$BuddyCompactionCopyWithImpl<$Res>
    implements $BuddyCompactionCopyWith<$Res> {
  _$BuddyCompactionCopyWithImpl(this._self, this._then);

  final BuddyCompaction _self;
  final $Res Function(BuddyCompaction) _then;

/// Create a copy of BuddyCompaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? evicted = null,Object? previousRevision = null,}) {
  return _then(BuddyCompaction(
evicted: null == evicted ? _self.evicted : evicted // ignore: cast_nullable_to_non_nullable
as List<BuddyHistoryEntry>,previousRevision: null == previousRevision ? _self.previousRevision : previousRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BuddyCompaction].
extension BuddyCompactionPatterns on BuddyCompaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyCompaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyCompaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyCompaction value)  $default,){
final _that = this;
switch (_that) {
case _BuddyCompaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyCompaction value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyCompaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuddyHistoryEntry> evicted,  int previousRevision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyCompaction() when $default != null:
return $default(_that.evicted,_that.previousRevision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuddyHistoryEntry> evicted,  int previousRevision)  $default,) {final _that = this;
switch (_that) {
case _BuddyCompaction():
return $default(_that.evicted,_that.previousRevision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuddyHistoryEntry> evicted,  int previousRevision)?  $default,) {final _that = this;
switch (_that) {
case _BuddyCompaction() when $default != null:
return $default(_that.evicted,_that.previousRevision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyCompaction implements BuddyCompaction {
  const _BuddyCompaction({required  List<BuddyHistoryEntry> evicted, required this.previousRevision}): _evicted = evicted;
  factory _BuddyCompaction.fromJson(Map<String, dynamic> json) => _$BuddyCompactionFromJson(json);

 final  List<BuddyHistoryEntry> _evicted;
@override List<BuddyHistoryEntry> get evicted {
  if (_evicted is EqualUnmodifiableListView) return _evicted;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evicted);
}

/// The summary revision the phone holds (0 when it has none); the returned summary has previousRevision + 1 and is stored only if the phone's revision still matches.
@override final  int previousRevision;

/// Create a copy of BuddyCompaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyCompactionCopyWith<_BuddyCompaction> get copyWith => __$BuddyCompactionCopyWithImpl<_BuddyCompaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyCompactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyCompaction&&const DeepCollectionEquality().equals(other.evicted, _evicted)&&(identical(other.previousRevision, previousRevision) || other.previousRevision == previousRevision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_evicted),previousRevision);
}

@override
String toString() {
    return 'BuddyCompaction(evicted: $evicted, previousRevision: $previousRevision)';
}


}

/// @nodoc
abstract mixin class _$BuddyCompactionCopyWith<$Res> implements $BuddyCompactionCopyWith<$Res> {
  factory _$BuddyCompactionCopyWith(_BuddyCompaction value, $Res Function(_BuddyCompaction) _then) = __$BuddyCompactionCopyWithImpl;
@override @useResult
$Res call({
 List<BuddyHistoryEntry> evicted, int previousRevision
});




}
/// @nodoc
class __$BuddyCompactionCopyWithImpl<$Res>
    implements _$BuddyCompactionCopyWith<$Res> {
  __$BuddyCompactionCopyWithImpl(this._self, this._then);

  final _BuddyCompaction _self;
  final $Res Function(_BuddyCompaction) _then;

/// Create a copy of BuddyCompaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? evicted = null,Object? previousRevision = null,}) {
  return _then(_BuddyCompaction(
evicted: null == evicted ? _self._evicted : evicted // ignore: cast_nullable_to_non_nullable
as List<BuddyHistoryEntry>,previousRevision: null == previousRevision ? _self.previousRevision : previousRevision // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
