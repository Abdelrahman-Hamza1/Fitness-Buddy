// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_continue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnContinue {

 String get turnId;/// The round the phoneTools event announced (1–3).
 int get round;/// The phoneTools event's sealed continuation, unchanged.
 String get continuation; List<BuddyPhoneToolResult> get results; BuddyPriorAttempt? get priorAttempt;
/// Create a copy of BuddyTurnContinue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnContinueCopyWith<BuddyTurnContinue> get copyWith => _$BuddyTurnContinueCopyWithImpl<BuddyTurnContinue>(this as BuddyTurnContinue, _$identity);

  /// Serializes this BuddyTurnContinue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnContinue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnContinue&&(identical(other.turnId, _this.turnId) || other.turnId == _this.turnId)&&(identical(other.round, _this.round) || other.round == _this.round)&&(identical(other.continuation, _this.continuation) || other.continuation == _this.continuation)&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.priorAttempt, _this.priorAttempt) || other.priorAttempt == _this.priorAttempt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnContinue;
  return Object.hash(runtimeType,_this.turnId,_this.round,_this.continuation,const DeepCollectionEquality().hash(_this.results),_this.priorAttempt);
}

@override
String toString() {
  final _this = this as BuddyTurnContinue;
  return 'BuddyTurnContinue(turnId: ${_this.turnId}, round: ${_this.round}, continuation: ${_this.continuation}, results: ${_this.results}, priorAttempt: ${_this.priorAttempt})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnContinueCopyWith<$Res>  {
  factory $BuddyTurnContinueCopyWith(BuddyTurnContinue value, $Res Function(BuddyTurnContinue) _then) = _$BuddyTurnContinueCopyWithImpl;
@useResult
$Res call({
 String turnId, int round, String continuation, List<BuddyPhoneToolResult> results, BuddyPriorAttempt? priorAttempt
});


$BuddyPriorAttemptCopyWith<$Res>? get priorAttempt;

}
/// @nodoc
class _$BuddyTurnContinueCopyWithImpl<$Res>
    implements $BuddyTurnContinueCopyWith<$Res> {
  _$BuddyTurnContinueCopyWithImpl(this._self, this._then);

  final BuddyTurnContinue _self;
  final $Res Function(BuddyTurnContinue) _then;

/// Create a copy of BuddyTurnContinue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? turnId = null,Object? round = null,Object? continuation = null,Object? results = null,Object? priorAttempt = freezed,}) {
  return _then(BuddyTurnContinue(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,continuation: null == continuation ? _self.continuation : continuation // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<BuddyPhoneToolResult>,priorAttempt: freezed == priorAttempt ? _self.priorAttempt : priorAttempt // ignore: cast_nullable_to_non_nullable
as BuddyPriorAttempt?,
  ));
}
/// Create a copy of BuddyTurnContinue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPriorAttemptCopyWith<$Res>? get priorAttempt {
    if (_self.priorAttempt == null) {
    return null;
  }

  return $BuddyPriorAttemptCopyWith<$Res>(_self.priorAttempt!, (value) {
    return _then(_self.copyWith(priorAttempt: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyTurnContinue].
extension BuddyTurnContinuePatterns on BuddyTurnContinue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnContinue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnContinue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnContinue value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnContinue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnContinue value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnContinue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String turnId,  int round,  String continuation,  List<BuddyPhoneToolResult> results,  BuddyPriorAttempt? priorAttempt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnContinue() when $default != null:
return $default(_that.turnId,_that.round,_that.continuation,_that.results,_that.priorAttempt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String turnId,  int round,  String continuation,  List<BuddyPhoneToolResult> results,  BuddyPriorAttempt? priorAttempt)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnContinue():
return $default(_that.turnId,_that.round,_that.continuation,_that.results,_that.priorAttempt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String turnId,  int round,  String continuation,  List<BuddyPhoneToolResult> results,  BuddyPriorAttempt? priorAttempt)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnContinue() when $default != null:
return $default(_that.turnId,_that.round,_that.continuation,_that.results,_that.priorAttempt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnContinue implements BuddyTurnContinue {
  const _BuddyTurnContinue({required this.turnId, required this.round, required this.continuation, required  List<BuddyPhoneToolResult> results, required this.priorAttempt}): _results = results;
  factory _BuddyTurnContinue.fromJson(Map<String, dynamic> json) => _$BuddyTurnContinueFromJson(json);

@override final  String turnId;
/// The round the phoneTools event announced (1–3).
@override final  int round;
/// The phoneTools event's sealed continuation, unchanged.
@override final  String continuation;
 final  List<BuddyPhoneToolResult> _results;
@override List<BuddyPhoneToolResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  BuddyPriorAttempt? priorAttempt;

/// Create a copy of BuddyTurnContinue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnContinueCopyWith<_BuddyTurnContinue> get copyWith => __$BuddyTurnContinueCopyWithImpl<_BuddyTurnContinue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnContinueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnContinue&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.round, round) || other.round == round)&&(identical(other.continuation, continuation) || other.continuation == continuation)&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.priorAttempt, priorAttempt) || other.priorAttempt == priorAttempt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,round,continuation,const DeepCollectionEquality().hash(_results),priorAttempt);
}

@override
String toString() {
    return 'BuddyTurnContinue(turnId: $turnId, round: $round, continuation: $continuation, results: $results, priorAttempt: $priorAttempt)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnContinueCopyWith<$Res> implements $BuddyTurnContinueCopyWith<$Res> {
  factory _$BuddyTurnContinueCopyWith(_BuddyTurnContinue value, $Res Function(_BuddyTurnContinue) _then) = __$BuddyTurnContinueCopyWithImpl;
@override @useResult
$Res call({
 String turnId, int round, String continuation, List<BuddyPhoneToolResult> results, BuddyPriorAttempt? priorAttempt
});


@override $BuddyPriorAttemptCopyWith<$Res>? get priorAttempt;

}
/// @nodoc
class __$BuddyTurnContinueCopyWithImpl<$Res>
    implements _$BuddyTurnContinueCopyWith<$Res> {
  __$BuddyTurnContinueCopyWithImpl(this._self, this._then);

  final _BuddyTurnContinue _self;
  final $Res Function(_BuddyTurnContinue) _then;

/// Create a copy of BuddyTurnContinue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? round = null,Object? continuation = null,Object? results = null,Object? priorAttempt = freezed,}) {
  return _then(_BuddyTurnContinue(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,continuation: null == continuation ? _self.continuation : continuation // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<BuddyPhoneToolResult>,priorAttempt: freezed == priorAttempt ? _self.priorAttempt : priorAttempt // ignore: cast_nullable_to_non_nullable
as BuddyPriorAttempt?,
  ));
}

/// Create a copy of BuddyTurnContinue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPriorAttemptCopyWith<$Res>? get priorAttempt {
    if (_self.priorAttempt == null) {
    return null;
  }

  return $BuddyPriorAttemptCopyWith<$Res>(_self.priorAttempt!, (value) {
    return _then(_self.copyWith(priorAttempt: value));
  });
}
}

// dart format on
