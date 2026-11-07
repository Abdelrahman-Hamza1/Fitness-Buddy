// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_start.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyTurnStart {

/// The user chat message ID (UUIDv7); equals Idempotency-Key and names the turn in SSE ids and proposal IDs.
 String get turnId;/// chat, or weeklyReview (B26: the weekly aggregates only, no tools, at most two observations).
 BuddyTurnMode get mode; BuddyTurnMessage get message;/// The last 12 chat entries, oldest first, with their card outcomes (TD-126).
 List<BuddyHistoryEntry> get history;/// The phone's current conversation summary, or null.
 BuddyConversationSummary? get summary;/// Entries evicted past the summary's watermark (the phone owns compaction, 06 §6.1); the server answers with a summary event before done.
 BuddyCompaction? get compact;/// The personal slice: up to 20 personal foods, saved meals, open batches and usual meals pre-matched on the phone against the message tokens (fb_text normalization), with their facts. Resolved before the catalog (AI-070).
 List<BuddyPersonalItem> get personal; BuddyTurnProfile get profile; BuddyTurnSnapshot get snapshot;/// The previous turn, acknowledging its final round (06 §3.4); null when there is none.
 BuddyTurnReference? get ackTurn;/// Retries only: the cards the earlier attempt of this round produced and what happened to them.
 BuddyPriorAttempt? get priorAttempt;/// Dev builds only; honoured only when the server enables Buddy:Agent:TraceEnabled. Adds trace events for the phone, never logged.
 bool get trace;/// Mode weeklyReview only, and required there (else 400): the week's aggregates. Optional: absent and null are the same.
 BuddyWeeklySummary? get weekly;
/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnStartCopyWith<BuddyTurnStart> get copyWith => _$BuddyTurnStartCopyWithImpl<BuddyTurnStart>(this as BuddyTurnStart, _$identity);

  /// Serializes this BuddyTurnStart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyTurnStart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnStart&&(identical(other.turnId, _this.turnId) || other.turnId == _this.turnId)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.message, _this.message) || other.message == _this.message)&&const DeepCollectionEquality().equals(other.history, _this.history)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.compact, _this.compact) || other.compact == _this.compact)&&const DeepCollectionEquality().equals(other.personal, _this.personal)&&(identical(other.profile, _this.profile) || other.profile == _this.profile)&&(identical(other.snapshot, _this.snapshot) || other.snapshot == _this.snapshot)&&(identical(other.ackTurn, _this.ackTurn) || other.ackTurn == _this.ackTurn)&&(identical(other.priorAttempt, _this.priorAttempt) || other.priorAttempt == _this.priorAttempt)&&(identical(other.trace, _this.trace) || other.trace == _this.trace)&&(identical(other.weekly, _this.weekly) || other.weekly == _this.weekly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyTurnStart;
  return Object.hash(runtimeType,_this.turnId,_this.mode,_this.message,const DeepCollectionEquality().hash(_this.history),_this.summary,_this.compact,const DeepCollectionEquality().hash(_this.personal),_this.profile,_this.snapshot,_this.ackTurn,_this.priorAttempt,_this.trace,_this.weekly);
}

@override
String toString() {
  final _this = this as BuddyTurnStart;
  return 'BuddyTurnStart(turnId: ${_this.turnId}, mode: ${_this.mode}, message: ${_this.message}, history: ${_this.history}, summary: ${_this.summary}, compact: ${_this.compact}, personal: ${_this.personal}, profile: ${_this.profile}, snapshot: ${_this.snapshot}, ackTurn: ${_this.ackTurn}, priorAttempt: ${_this.priorAttempt}, trace: ${_this.trace}, weekly: ${_this.weekly})';
}


}

/// @nodoc
abstract mixin class $BuddyTurnStartCopyWith<$Res>  {
  factory $BuddyTurnStartCopyWith(BuddyTurnStart value, $Res Function(BuddyTurnStart) _then) = _$BuddyTurnStartCopyWithImpl;
@useResult
$Res call({
 String turnId, BuddyTurnMode mode, BuddyTurnMessage message, List<BuddyHistoryEntry> history, BuddyConversationSummary? summary, BuddyCompaction? compact, List<BuddyPersonalItem> personal, BuddyTurnProfile profile, BuddyTurnSnapshot snapshot, BuddyTurnReference? ackTurn, BuddyPriorAttempt? priorAttempt, bool trace, BuddyWeeklySummary? weekly
});


$BuddyTurnMessageCopyWith<$Res> get message;$BuddyConversationSummaryCopyWith<$Res>? get summary;$BuddyCompactionCopyWith<$Res>? get compact;$BuddyTurnProfileCopyWith<$Res> get profile;$BuddyTurnSnapshotCopyWith<$Res> get snapshot;$BuddyTurnReferenceCopyWith<$Res>? get ackTurn;$BuddyPriorAttemptCopyWith<$Res>? get priorAttempt;$BuddyWeeklySummaryCopyWith<$Res>? get weekly;

}
/// @nodoc
class _$BuddyTurnStartCopyWithImpl<$Res>
    implements $BuddyTurnStartCopyWith<$Res> {
  _$BuddyTurnStartCopyWithImpl(this._self, this._then);

  final BuddyTurnStart _self;
  final $Res Function(BuddyTurnStart) _then;

/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? turnId = null,Object? mode = null,Object? message = null,Object? history = null,Object? summary = freezed,Object? compact = freezed,Object? personal = null,Object? profile = null,Object? snapshot = null,Object? ackTurn = freezed,Object? priorAttempt = freezed,Object? trace = null,Object? weekly = freezed,}) {
  return _then(BuddyTurnStart(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as BuddyTurnMode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as BuddyTurnMessage,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<BuddyHistoryEntry>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as BuddyConversationSummary?,compact: freezed == compact ? _self.compact : compact // ignore: cast_nullable_to_non_nullable
as BuddyCompaction?,personal: null == personal ? _self.personal : personal // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalItem>,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BuddyTurnProfile,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as BuddyTurnSnapshot,ackTurn: freezed == ackTurn ? _self.ackTurn : ackTurn // ignore: cast_nullable_to_non_nullable
as BuddyTurnReference?,priorAttempt: freezed == priorAttempt ? _self.priorAttempt : priorAttempt // ignore: cast_nullable_to_non_nullable
as BuddyPriorAttempt?,trace: null == trace ? _self.trace : trace // ignore: cast_nullable_to_non_nullable
as bool,weekly: freezed == weekly ? _self.weekly : weekly // ignore: cast_nullable_to_non_nullable
as BuddyWeeklySummary?,
  ));
}
/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnMessageCopyWith<$Res> get message {
  
  return $BuddyTurnMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyConversationSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $BuddyConversationSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCompactionCopyWith<$Res>? get compact {
    if (_self.compact == null) {
    return null;
  }

  return $BuddyCompactionCopyWith<$Res>(_self.compact!, (value) {
    return _then(_self.copyWith(compact: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnProfileCopyWith<$Res> get profile {
  
  return $BuddyTurnProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnSnapshotCopyWith<$Res> get snapshot {
  
  return $BuddyTurnSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnReferenceCopyWith<$Res>? get ackTurn {
    if (_self.ackTurn == null) {
    return null;
  }

  return $BuddyTurnReferenceCopyWith<$Res>(_self.ackTurn!, (value) {
    return _then(_self.copyWith(ackTurn: value));
  });
}/// Create a copy of BuddyTurnStart
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
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeeklySummaryCopyWith<$Res>? get weekly {
    if (_self.weekly == null) {
    return null;
  }

  return $BuddyWeeklySummaryCopyWith<$Res>(_self.weekly!, (value) {
    return _then(_self.copyWith(weekly: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyTurnStart].
extension BuddyTurnStartPatterns on BuddyTurnStart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyTurnStart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyTurnStart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyTurnStart value)  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnStart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyTurnStart value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyTurnStart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String turnId,  BuddyTurnMode mode,  BuddyTurnMessage message,  List<BuddyHistoryEntry> history,  BuddyConversationSummary? summary,  BuddyCompaction? compact,  List<BuddyPersonalItem> personal,  BuddyTurnProfile profile,  BuddyTurnSnapshot snapshot,  BuddyTurnReference? ackTurn,  BuddyPriorAttempt? priorAttempt,  bool trace,  BuddyWeeklySummary? weekly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyTurnStart() when $default != null:
return $default(_that.turnId,_that.mode,_that.message,_that.history,_that.summary,_that.compact,_that.personal,_that.profile,_that.snapshot,_that.ackTurn,_that.priorAttempt,_that.trace,_that.weekly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String turnId,  BuddyTurnMode mode,  BuddyTurnMessage message,  List<BuddyHistoryEntry> history,  BuddyConversationSummary? summary,  BuddyCompaction? compact,  List<BuddyPersonalItem> personal,  BuddyTurnProfile profile,  BuddyTurnSnapshot snapshot,  BuddyTurnReference? ackTurn,  BuddyPriorAttempt? priorAttempt,  bool trace,  BuddyWeeklySummary? weekly)  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnStart():
return $default(_that.turnId,_that.mode,_that.message,_that.history,_that.summary,_that.compact,_that.personal,_that.profile,_that.snapshot,_that.ackTurn,_that.priorAttempt,_that.trace,_that.weekly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String turnId,  BuddyTurnMode mode,  BuddyTurnMessage message,  List<BuddyHistoryEntry> history,  BuddyConversationSummary? summary,  BuddyCompaction? compact,  List<BuddyPersonalItem> personal,  BuddyTurnProfile profile,  BuddyTurnSnapshot snapshot,  BuddyTurnReference? ackTurn,  BuddyPriorAttempt? priorAttempt,  bool trace,  BuddyWeeklySummary? weekly)?  $default,) {final _that = this;
switch (_that) {
case _BuddyTurnStart() when $default != null:
return $default(_that.turnId,_that.mode,_that.message,_that.history,_that.summary,_that.compact,_that.personal,_that.profile,_that.snapshot,_that.ackTurn,_that.priorAttempt,_that.trace,_that.weekly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyTurnStart implements BuddyTurnStart {
  const _BuddyTurnStart({required this.turnId, required this.mode, required this.message, required  List<BuddyHistoryEntry> history, required this.summary, required this.compact, required  List<BuddyPersonalItem> personal, required this.profile, required this.snapshot, required this.ackTurn, required this.priorAttempt, required this.trace, this.weekly}): _history = history,_personal = personal;
  factory _BuddyTurnStart.fromJson(Map<String, dynamic> json) => _$BuddyTurnStartFromJson(json);

/// The user chat message ID (UUIDv7); equals Idempotency-Key and names the turn in SSE ids and proposal IDs.
@override final  String turnId;
/// chat, or weeklyReview (B26: the weekly aggregates only, no tools, at most two observations).
@override final  BuddyTurnMode mode;
@override final  BuddyTurnMessage message;
/// The last 12 chat entries, oldest first, with their card outcomes (TD-126).
 final  List<BuddyHistoryEntry> _history;
/// The last 12 chat entries, oldest first, with their card outcomes (TD-126).
@override List<BuddyHistoryEntry> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

/// The phone's current conversation summary, or null.
@override final  BuddyConversationSummary? summary;
/// Entries evicted past the summary's watermark (the phone owns compaction, 06 §6.1); the server answers with a summary event before done.
@override final  BuddyCompaction? compact;
/// The personal slice: up to 20 personal foods, saved meals, open batches and usual meals pre-matched on the phone against the message tokens (fb_text normalization), with their facts. Resolved before the catalog (AI-070).
 final  List<BuddyPersonalItem> _personal;
/// The personal slice: up to 20 personal foods, saved meals, open batches and usual meals pre-matched on the phone against the message tokens (fb_text normalization), with their facts. Resolved before the catalog (AI-070).
@override List<BuddyPersonalItem> get personal {
  if (_personal is EqualUnmodifiableListView) return _personal;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_personal);
}

@override final  BuddyTurnProfile profile;
@override final  BuddyTurnSnapshot snapshot;
/// The previous turn, acknowledging its final round (06 §3.4); null when there is none.
@override final  BuddyTurnReference? ackTurn;
/// Retries only: the cards the earlier attempt of this round produced and what happened to them.
@override final  BuddyPriorAttempt? priorAttempt;
/// Dev builds only; honoured only when the server enables Buddy:Agent:TraceEnabled. Adds trace events for the phone, never logged.
@override final  bool trace;
/// Mode weeklyReview only, and required there (else 400): the week's aggregates. Optional: absent and null are the same.
@override final  BuddyWeeklySummary? weekly;

/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyTurnStartCopyWith<_BuddyTurnStart> get copyWith => __$BuddyTurnStartCopyWithImpl<_BuddyTurnStart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnStartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyTurnStart&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.history, _history)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.compact, compact) || other.compact == compact)&&const DeepCollectionEquality().equals(other.personal, _personal)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.ackTurn, ackTurn) || other.ackTurn == ackTurn)&&(identical(other.priorAttempt, priorAttempt) || other.priorAttempt == priorAttempt)&&(identical(other.trace, trace) || other.trace == trace)&&(identical(other.weekly, weekly) || other.weekly == weekly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,mode,message,const DeepCollectionEquality().hash(_history),summary,compact,const DeepCollectionEquality().hash(_personal),profile,snapshot,ackTurn,priorAttempt,trace,weekly);
}

@override
String toString() {
    return 'BuddyTurnStart(turnId: $turnId, mode: $mode, message: $message, history: $history, summary: $summary, compact: $compact, personal: $personal, profile: $profile, snapshot: $snapshot, ackTurn: $ackTurn, priorAttempt: $priorAttempt, trace: $trace, weekly: $weekly)';
}


}

/// @nodoc
abstract mixin class _$BuddyTurnStartCopyWith<$Res> implements $BuddyTurnStartCopyWith<$Res> {
  factory _$BuddyTurnStartCopyWith(_BuddyTurnStart value, $Res Function(_BuddyTurnStart) _then) = __$BuddyTurnStartCopyWithImpl;
@override @useResult
$Res call({
 String turnId, BuddyTurnMode mode, BuddyTurnMessage message, List<BuddyHistoryEntry> history, BuddyConversationSummary? summary, BuddyCompaction? compact, List<BuddyPersonalItem> personal, BuddyTurnProfile profile, BuddyTurnSnapshot snapshot, BuddyTurnReference? ackTurn, BuddyPriorAttempt? priorAttempt, bool trace, BuddyWeeklySummary? weekly
});


@override $BuddyTurnMessageCopyWith<$Res> get message;@override $BuddyConversationSummaryCopyWith<$Res>? get summary;@override $BuddyCompactionCopyWith<$Res>? get compact;@override $BuddyTurnProfileCopyWith<$Res> get profile;@override $BuddyTurnSnapshotCopyWith<$Res> get snapshot;@override $BuddyTurnReferenceCopyWith<$Res>? get ackTurn;@override $BuddyPriorAttemptCopyWith<$Res>? get priorAttempt;@override $BuddyWeeklySummaryCopyWith<$Res>? get weekly;

}
/// @nodoc
class __$BuddyTurnStartCopyWithImpl<$Res>
    implements _$BuddyTurnStartCopyWith<$Res> {
  __$BuddyTurnStartCopyWithImpl(this._self, this._then);

  final _BuddyTurnStart _self;
  final $Res Function(_BuddyTurnStart) _then;

/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? mode = null,Object? message = null,Object? history = null,Object? summary = freezed,Object? compact = freezed,Object? personal = null,Object? profile = null,Object? snapshot = null,Object? ackTurn = freezed,Object? priorAttempt = freezed,Object? trace = null,Object? weekly = freezed,}) {
  return _then(_BuddyTurnStart(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as BuddyTurnMode,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as BuddyTurnMessage,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<BuddyHistoryEntry>,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as BuddyConversationSummary?,compact: freezed == compact ? _self.compact : compact // ignore: cast_nullable_to_non_nullable
as BuddyCompaction?,personal: null == personal ? _self._personal : personal // ignore: cast_nullable_to_non_nullable
as List<BuddyPersonalItem>,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as BuddyTurnProfile,snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as BuddyTurnSnapshot,ackTurn: freezed == ackTurn ? _self.ackTurn : ackTurn // ignore: cast_nullable_to_non_nullable
as BuddyTurnReference?,priorAttempt: freezed == priorAttempt ? _self.priorAttempt : priorAttempt // ignore: cast_nullable_to_non_nullable
as BuddyPriorAttempt?,trace: null == trace ? _self.trace : trace // ignore: cast_nullable_to_non_nullable
as bool,weekly: freezed == weekly ? _self.weekly : weekly // ignore: cast_nullable_to_non_nullable
as BuddyWeeklySummary?,
  ));
}

/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnMessageCopyWith<$Res> get message {
  
  return $BuddyTurnMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyConversationSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $BuddyConversationSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCompactionCopyWith<$Res>? get compact {
    if (_self.compact == null) {
    return null;
  }

  return $BuddyCompactionCopyWith<$Res>(_self.compact!, (value) {
    return _then(_self.copyWith(compact: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnProfileCopyWith<$Res> get profile {
  
  return $BuddyTurnProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnSnapshotCopyWith<$Res> get snapshot {
  
  return $BuddyTurnSnapshotCopyWith<$Res>(_self.snapshot, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnReferenceCopyWith<$Res>? get ackTurn {
    if (_self.ackTurn == null) {
    return null;
  }

  return $BuddyTurnReferenceCopyWith<$Res>(_self.ackTurn!, (value) {
    return _then(_self.copyWith(ackTurn: value));
  });
}/// Create a copy of BuddyTurnStart
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
}/// Create a copy of BuddyTurnStart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyWeeklySummaryCopyWith<$Res>? get weekly {
    if (_self.weekly == null) {
    return null;
  }

  return $BuddyWeeklySummaryCopyWith<$Res>(_self.weekly!, (value) {
    return _then(_self.copyWith(weekly: value));
  });
}
}

// dart format on
