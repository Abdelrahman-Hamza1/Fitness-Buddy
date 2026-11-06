// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_proposal_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuddyProposalEvent {

 BuddyProposalEventType get type; String get proposalId; int get revision; BuddyCardRevision? get replaces; BuddyIntent get intent;
/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyProposalEventCopyWith<BuddyProposalEvent> get copyWith => _$BuddyProposalEventCopyWithImpl<BuddyProposalEvent>(this as BuddyProposalEvent, _$identity);

  /// Serializes this BuddyProposalEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BuddyProposalEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyProposalEvent&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.proposalId, _this.proposalId) || other.proposalId == _this.proposalId)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.replaces, _this.replaces) || other.replaces == _this.replaces)&&(identical(other.intent, _this.intent) || other.intent == _this.intent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BuddyProposalEvent;
  return Object.hash(runtimeType,_this.type,_this.proposalId,_this.revision,_this.replaces,_this.intent);
}

@override
String toString() {
  final _this = this as BuddyProposalEvent;
  return 'BuddyProposalEvent(type: ${_this.type}, proposalId: ${_this.proposalId}, revision: ${_this.revision}, replaces: ${_this.replaces}, intent: ${_this.intent})';
}


}

/// @nodoc
abstract mixin class $BuddyProposalEventCopyWith<$Res>  {
  factory $BuddyProposalEventCopyWith(BuddyProposalEvent value, $Res Function(BuddyProposalEvent) _then) = _$BuddyProposalEventCopyWithImpl;
@useResult
$Res call({
 BuddyProposalEventType type, String proposalId, int revision, BuddyCardRevision? replaces, BuddyIntent intent
});


$BuddyCardRevisionCopyWith<$Res>? get replaces;$BuddyIntentCopyWith<$Res> get intent;

}
/// @nodoc
class _$BuddyProposalEventCopyWithImpl<$Res>
    implements $BuddyProposalEventCopyWith<$Res> {
  _$BuddyProposalEventCopyWithImpl(this._self, this._then);

  final BuddyProposalEvent _self;
  final $Res Function(BuddyProposalEvent) _then;

/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? proposalId = null,Object? revision = null,Object? replaces = freezed,Object? intent = null,}) {
  return _then(BuddyProposalEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyProposalEventType,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,replaces: freezed == replaces ? _self.replaces : replaces // ignore: cast_nullable_to_non_nullable
as BuddyCardRevision?,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as BuddyIntent,
  ));
}
/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCardRevisionCopyWith<$Res>? get replaces {
    if (_self.replaces == null) {
    return null;
  }

  return $BuddyCardRevisionCopyWith<$Res>(_self.replaces!, (value) {
    return _then(_self.copyWith(replaces: value));
  });
}/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyIntentCopyWith<$Res> get intent {
  
  return $BuddyIntentCopyWith<$Res>(_self.intent, (value) {
    return _then(_self.copyWith(intent: value));
  });
}
}


/// Adds pattern-matching-related methods to [BuddyProposalEvent].
extension BuddyProposalEventPatterns on BuddyProposalEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuddyProposalEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuddyProposalEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuddyProposalEvent value)  $default,){
final _that = this;
switch (_that) {
case _BuddyProposalEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuddyProposalEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BuddyProposalEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuddyProposalEventType type,  String proposalId,  int revision,  BuddyCardRevision? replaces,  BuddyIntent intent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuddyProposalEvent() when $default != null:
return $default(_that.type,_that.proposalId,_that.revision,_that.replaces,_that.intent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuddyProposalEventType type,  String proposalId,  int revision,  BuddyCardRevision? replaces,  BuddyIntent intent)  $default,) {final _that = this;
switch (_that) {
case _BuddyProposalEvent():
return $default(_that.type,_that.proposalId,_that.revision,_that.replaces,_that.intent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuddyProposalEventType type,  String proposalId,  int revision,  BuddyCardRevision? replaces,  BuddyIntent intent)?  $default,) {final _that = this;
switch (_that) {
case _BuddyProposalEvent() when $default != null:
return $default(_that.type,_that.proposalId,_that.revision,_that.replaces,_that.intent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuddyProposalEvent implements BuddyProposalEvent {
  const _BuddyProposalEvent({required this.type, required this.proposalId, required this.revision, required this.replaces, required this.intent});
  factory _BuddyProposalEvent.fromJson(Map<String, dynamic> json) => _$BuddyProposalEventFromJson(json);

@override final  BuddyProposalEventType type;
@override final  String proposalId;
@override final  int revision;
@override final  BuddyCardRevision? replaces;
@override final  BuddyIntent intent;

/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuddyProposalEventCopyWith<_BuddyProposalEvent> get copyWith => __$BuddyProposalEventCopyWithImpl<_BuddyProposalEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyProposalEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuddyProposalEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.replaces, replaces) || other.replaces == replaces)&&(identical(other.intent, intent) || other.intent == intent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,proposalId,revision,replaces,intent);
}

@override
String toString() {
    return 'BuddyProposalEvent(type: $type, proposalId: $proposalId, revision: $revision, replaces: $replaces, intent: $intent)';
}


}

/// @nodoc
abstract mixin class _$BuddyProposalEventCopyWith<$Res> implements $BuddyProposalEventCopyWith<$Res> {
  factory _$BuddyProposalEventCopyWith(_BuddyProposalEvent value, $Res Function(_BuddyProposalEvent) _then) = __$BuddyProposalEventCopyWithImpl;
@override @useResult
$Res call({
 BuddyProposalEventType type, String proposalId, int revision, BuddyCardRevision? replaces, BuddyIntent intent
});


@override $BuddyCardRevisionCopyWith<$Res>? get replaces;@override $BuddyIntentCopyWith<$Res> get intent;

}
/// @nodoc
class __$BuddyProposalEventCopyWithImpl<$Res>
    implements _$BuddyProposalEventCopyWith<$Res> {
  __$BuddyProposalEventCopyWithImpl(this._self, this._then);

  final _BuddyProposalEvent _self;
  final $Res Function(_BuddyProposalEvent) _then;

/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? proposalId = null,Object? revision = null,Object? replaces = freezed,Object? intent = null,}) {
  return _then(_BuddyProposalEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyProposalEventType,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,replaces: freezed == replaces ? _self.replaces : replaces // ignore: cast_nullable_to_non_nullable
as BuddyCardRevision?,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as BuddyIntent,
  ));
}

/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyCardRevisionCopyWith<$Res>? get replaces {
    if (_self.replaces == null) {
    return null;
  }

  return $BuddyCardRevisionCopyWith<$Res>(_self.replaces!, (value) {
    return _then(_self.copyWith(replaces: value));
  });
}/// Create a copy of BuddyProposalEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyIntentCopyWith<$Res> get intent {
  
  return $BuddyIntentCopyWith<$Res>(_self.intent, (value) {
    return _then(_self.copyWith(intent: value));
  });
}
}

// dart format on
