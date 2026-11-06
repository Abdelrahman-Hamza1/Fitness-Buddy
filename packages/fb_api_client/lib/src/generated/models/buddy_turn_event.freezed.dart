// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_turn_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
BuddyTurnEvent _$BuddyTurnEventFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'step':
          return BuddyTurnEventStep.fromJson(
            json
          );
                case 'text':
          return BuddyTurnEventText.fromJson(
            json
          );
                case 'proposal':
          return BuddyTurnEventProposal.fromJson(
            json
          );
                case 'question':
          return BuddyTurnEventQuestion.fromJson(
            json
          );
                case 'phoneTools':
          return BuddyTurnEventPhoneTools.fromJson(
            json
          );
                case 'summary':
          return BuddyTurnEventSummary.fromJson(
            json
          );
                case 'trace':
          return BuddyTurnEventTrace.fromJson(
            json
          );
                case 'done':
          return BuddyTurnEventDone.fromJson(
            json
          );
                case 'error':
          return BuddyTurnEventError.fromJson(
            json
          );
        
          default:
            return BuddyTurnEventUnrecognized.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$BuddyTurnEvent {



  /// Serializes this BuddyTurnEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEvent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyTurnEvent()';
}


}

/// @nodoc
class $BuddyTurnEventCopyWith<$Res>  {
$BuddyTurnEventCopyWith(BuddyTurnEvent _, $Res Function(BuddyTurnEvent) __);
}


/// Adds pattern-matching-related methods to [BuddyTurnEvent].
extension BuddyTurnEventPatterns on BuddyTurnEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BuddyTurnEventStep value)?  step,TResult Function( BuddyTurnEventText value)?  text,TResult Function( BuddyTurnEventProposal value)?  proposal,TResult Function( BuddyTurnEventQuestion value)?  question,TResult Function( BuddyTurnEventPhoneTools value)?  phoneTools,TResult Function( BuddyTurnEventSummary value)?  summary,TResult Function( BuddyTurnEventTrace value)?  trace,TResult Function( BuddyTurnEventDone value)?  done,TResult Function( BuddyTurnEventError value)?  error,TResult Function( BuddyTurnEventUnrecognized value)?  unrecognized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BuddyTurnEventStep() when step != null:
return step(_that);case BuddyTurnEventText() when text != null:
return text(_that);case BuddyTurnEventProposal() when proposal != null:
return proposal(_that);case BuddyTurnEventQuestion() when question != null:
return question(_that);case BuddyTurnEventPhoneTools() when phoneTools != null:
return phoneTools(_that);case BuddyTurnEventSummary() when summary != null:
return summary(_that);case BuddyTurnEventTrace() when trace != null:
return trace(_that);case BuddyTurnEventDone() when done != null:
return done(_that);case BuddyTurnEventError() when error != null:
return error(_that);case BuddyTurnEventUnrecognized() when unrecognized != null:
return unrecognized(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BuddyTurnEventStep value)  step,required TResult Function( BuddyTurnEventText value)  text,required TResult Function( BuddyTurnEventProposal value)  proposal,required TResult Function( BuddyTurnEventQuestion value)  question,required TResult Function( BuddyTurnEventPhoneTools value)  phoneTools,required TResult Function( BuddyTurnEventSummary value)  summary,required TResult Function( BuddyTurnEventTrace value)  trace,required TResult Function( BuddyTurnEventDone value)  done,required TResult Function( BuddyTurnEventError value)  error,required TResult Function( BuddyTurnEventUnrecognized value)  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyTurnEventStep():
return step(_that);case BuddyTurnEventText():
return text(_that);case BuddyTurnEventProposal():
return proposal(_that);case BuddyTurnEventQuestion():
return question(_that);case BuddyTurnEventPhoneTools():
return phoneTools(_that);case BuddyTurnEventSummary():
return summary(_that);case BuddyTurnEventTrace():
return trace(_that);case BuddyTurnEventDone():
return done(_that);case BuddyTurnEventError():
return error(_that);case BuddyTurnEventUnrecognized():
return unrecognized(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BuddyTurnEventStep value)?  step,TResult? Function( BuddyTurnEventText value)?  text,TResult? Function( BuddyTurnEventProposal value)?  proposal,TResult? Function( BuddyTurnEventQuestion value)?  question,TResult? Function( BuddyTurnEventPhoneTools value)?  phoneTools,TResult? Function( BuddyTurnEventSummary value)?  summary,TResult? Function( BuddyTurnEventTrace value)?  trace,TResult? Function( BuddyTurnEventDone value)?  done,TResult? Function( BuddyTurnEventError value)?  error,TResult? Function( BuddyTurnEventUnrecognized value)?  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyTurnEventStep() when step != null:
return step(_that);case BuddyTurnEventText() when text != null:
return text(_that);case BuddyTurnEventProposal() when proposal != null:
return proposal(_that);case BuddyTurnEventQuestion() when question != null:
return question(_that);case BuddyTurnEventPhoneTools() when phoneTools != null:
return phoneTools(_that);case BuddyTurnEventSummary() when summary != null:
return summary(_that);case BuddyTurnEventTrace() when trace != null:
return trace(_that);case BuddyTurnEventDone() when done != null:
return done(_that);case BuddyTurnEventError() when error != null:
return error(_that);case BuddyTurnEventUnrecognized() when unrecognized != null:
return unrecognized(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BuddyStepEventType type,  BuddyStepCode code)?  step,TResult Function( BuddyTextEventType type,  String text)?  text,TResult Function( BuddyProposalEventType type,  String proposalId,  int revision,  BuddyCardRevision? replaces,  BuddyIntent intent)?  proposal,TResult Function( BuddyQuestionEventType type,  String text,  List<String> options)?  question,TResult Function( BuddyPhoneToolsEventType type,  int round,  String continuation,  List<BuddyPhoneToolCall> calls)?  phoneTools,TResult Function( BuddySummaryEventType type,  String text,  int revision,  String watermark)?  summary,TResult Function( BuddyTraceEventType type,  List<BuddyTraceStep> steps)?  trace,TResult Function( BuddyDoneEventType type,  BuddyDoneReason reason,  BuddyTurnUsage usage)?  done,TResult Function( BuddyErrorEventType type,  BuddyTurnErrorCode code)?  error,TResult Function()?  unrecognized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BuddyTurnEventStep() when step != null:
return step(_that.type,_that.code);case BuddyTurnEventText() when text != null:
return text(_that.type,_that.text);case BuddyTurnEventProposal() when proposal != null:
return proposal(_that.type,_that.proposalId,_that.revision,_that.replaces,_that.intent);case BuddyTurnEventQuestion() when question != null:
return question(_that.type,_that.text,_that.options);case BuddyTurnEventPhoneTools() when phoneTools != null:
return phoneTools(_that.type,_that.round,_that.continuation,_that.calls);case BuddyTurnEventSummary() when summary != null:
return summary(_that.type,_that.text,_that.revision,_that.watermark);case BuddyTurnEventTrace() when trace != null:
return trace(_that.type,_that.steps);case BuddyTurnEventDone() when done != null:
return done(_that.type,_that.reason,_that.usage);case BuddyTurnEventError() when error != null:
return error(_that.type,_that.code);case BuddyTurnEventUnrecognized() when unrecognized != null:
return unrecognized();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BuddyStepEventType type,  BuddyStepCode code)  step,required TResult Function( BuddyTextEventType type,  String text)  text,required TResult Function( BuddyProposalEventType type,  String proposalId,  int revision,  BuddyCardRevision? replaces,  BuddyIntent intent)  proposal,required TResult Function( BuddyQuestionEventType type,  String text,  List<String> options)  question,required TResult Function( BuddyPhoneToolsEventType type,  int round,  String continuation,  List<BuddyPhoneToolCall> calls)  phoneTools,required TResult Function( BuddySummaryEventType type,  String text,  int revision,  String watermark)  summary,required TResult Function( BuddyTraceEventType type,  List<BuddyTraceStep> steps)  trace,required TResult Function( BuddyDoneEventType type,  BuddyDoneReason reason,  BuddyTurnUsage usage)  done,required TResult Function( BuddyErrorEventType type,  BuddyTurnErrorCode code)  error,required TResult Function()  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyTurnEventStep():
return step(_that.type,_that.code);case BuddyTurnEventText():
return text(_that.type,_that.text);case BuddyTurnEventProposal():
return proposal(_that.type,_that.proposalId,_that.revision,_that.replaces,_that.intent);case BuddyTurnEventQuestion():
return question(_that.type,_that.text,_that.options);case BuddyTurnEventPhoneTools():
return phoneTools(_that.type,_that.round,_that.continuation,_that.calls);case BuddyTurnEventSummary():
return summary(_that.type,_that.text,_that.revision,_that.watermark);case BuddyTurnEventTrace():
return trace(_that.type,_that.steps);case BuddyTurnEventDone():
return done(_that.type,_that.reason,_that.usage);case BuddyTurnEventError():
return error(_that.type,_that.code);case BuddyTurnEventUnrecognized():
return unrecognized();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BuddyStepEventType type,  BuddyStepCode code)?  step,TResult? Function( BuddyTextEventType type,  String text)?  text,TResult? Function( BuddyProposalEventType type,  String proposalId,  int revision,  BuddyCardRevision? replaces,  BuddyIntent intent)?  proposal,TResult? Function( BuddyQuestionEventType type,  String text,  List<String> options)?  question,TResult? Function( BuddyPhoneToolsEventType type,  int round,  String continuation,  List<BuddyPhoneToolCall> calls)?  phoneTools,TResult? Function( BuddySummaryEventType type,  String text,  int revision,  String watermark)?  summary,TResult? Function( BuddyTraceEventType type,  List<BuddyTraceStep> steps)?  trace,TResult? Function( BuddyDoneEventType type,  BuddyDoneReason reason,  BuddyTurnUsage usage)?  done,TResult? Function( BuddyErrorEventType type,  BuddyTurnErrorCode code)?  error,TResult? Function()?  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyTurnEventStep() when step != null:
return step(_that.type,_that.code);case BuddyTurnEventText() when text != null:
return text(_that.type,_that.text);case BuddyTurnEventProposal() when proposal != null:
return proposal(_that.type,_that.proposalId,_that.revision,_that.replaces,_that.intent);case BuddyTurnEventQuestion() when question != null:
return question(_that.type,_that.text,_that.options);case BuddyTurnEventPhoneTools() when phoneTools != null:
return phoneTools(_that.type,_that.round,_that.continuation,_that.calls);case BuddyTurnEventSummary() when summary != null:
return summary(_that.type,_that.text,_that.revision,_that.watermark);case BuddyTurnEventTrace() when trace != null:
return trace(_that.type,_that.steps);case BuddyTurnEventDone() when done != null:
return done(_that.type,_that.reason,_that.usage);case BuddyTurnEventError() when error != null:
return error(_that.type,_that.code);case BuddyTurnEventUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventStep implements BuddyTurnEvent {
  const BuddyTurnEventStep({required this.type, required this.code});
  factory BuddyTurnEventStep.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventStepFromJson(json);

 final  BuddyStepEventType type;
 final  BuddyStepCode code;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventStepCopyWith<BuddyTurnEventStep> get copyWith => _$BuddyTurnEventStepCopyWithImpl<BuddyTurnEventStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventStep&&(identical(other.type, type) || other.type == type)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,code);
}

@override
String toString() {
    return 'BuddyTurnEvent.step(type: $type, code: $code)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventStepCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventStepCopyWith(BuddyTurnEventStep value, $Res Function(BuddyTurnEventStep) _then) = _$BuddyTurnEventStepCopyWithImpl;
@useResult
$Res call({
 BuddyStepEventType type, BuddyStepCode code
});




}
/// @nodoc
class _$BuddyTurnEventStepCopyWithImpl<$Res>
    implements $BuddyTurnEventStepCopyWith<$Res> {
  _$BuddyTurnEventStepCopyWithImpl(this._self, this._then);

  final BuddyTurnEventStep _self;
  final $Res Function(BuddyTurnEventStep) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? code = null,}) {
  return _then(BuddyTurnEventStep(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyStepEventType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as BuddyStepCode,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventText implements BuddyTurnEvent {
  const BuddyTurnEventText({required this.type, required this.text});
  factory BuddyTurnEventText.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventTextFromJson(json);

 final  BuddyTextEventType type;
 final  String text;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventTextCopyWith<BuddyTurnEventText> get copyWith => _$BuddyTurnEventTextCopyWithImpl<BuddyTurnEventText>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventTextToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventText&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,text);
}

@override
String toString() {
    return 'BuddyTurnEvent.text(type: $type, text: $text)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventTextCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventTextCopyWith(BuddyTurnEventText value, $Res Function(BuddyTurnEventText) _then) = _$BuddyTurnEventTextCopyWithImpl;
@useResult
$Res call({
 BuddyTextEventType type, String text
});




}
/// @nodoc
class _$BuddyTurnEventTextCopyWithImpl<$Res>
    implements $BuddyTurnEventTextCopyWith<$Res> {
  _$BuddyTurnEventTextCopyWithImpl(this._self, this._then);

  final BuddyTurnEventText _self;
  final $Res Function(BuddyTurnEventText) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,}) {
  return _then(BuddyTurnEventText(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyTextEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventProposal implements BuddyTurnEvent {
  const BuddyTurnEventProposal({required this.type, required this.proposalId, required this.revision, required this.replaces, required this.intent});
  factory BuddyTurnEventProposal.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventProposalFromJson(json);

 final  BuddyProposalEventType type;
 final  String proposalId;
 final  int revision;
 final  BuddyCardRevision? replaces;
 final  BuddyIntent intent;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventProposalCopyWith<BuddyTurnEventProposal> get copyWith => _$BuddyTurnEventProposalCopyWithImpl<BuddyTurnEventProposal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventProposalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventProposal&&(identical(other.type, type) || other.type == type)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.replaces, replaces) || other.replaces == replaces)&&(identical(other.intent, intent) || other.intent == intent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,proposalId,revision,replaces,intent);
}

@override
String toString() {
    return 'BuddyTurnEvent.proposal(type: $type, proposalId: $proposalId, revision: $revision, replaces: $replaces, intent: $intent)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventProposalCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventProposalCopyWith(BuddyTurnEventProposal value, $Res Function(BuddyTurnEventProposal) _then) = _$BuddyTurnEventProposalCopyWithImpl;
@useResult
$Res call({
 BuddyProposalEventType type, String proposalId, int revision, BuddyCardRevision? replaces, BuddyIntent intent
});


$BuddyCardRevisionCopyWith<$Res>? get replaces;$BuddyIntentCopyWith<$Res> get intent;

}
/// @nodoc
class _$BuddyTurnEventProposalCopyWithImpl<$Res>
    implements $BuddyTurnEventProposalCopyWith<$Res> {
  _$BuddyTurnEventProposalCopyWithImpl(this._self, this._then);

  final BuddyTurnEventProposal _self;
  final $Res Function(BuddyTurnEventProposal) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? proposalId = null,Object? revision = null,Object? replaces = freezed,Object? intent = null,}) {
  return _then(BuddyTurnEventProposal(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyProposalEventType,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,replaces: freezed == replaces ? _self.replaces : replaces // ignore: cast_nullable_to_non_nullable
as BuddyCardRevision?,intent: null == intent ? _self.intent : intent // ignore: cast_nullable_to_non_nullable
as BuddyIntent,
  ));
}

/// Create a copy of BuddyTurnEvent
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
}/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyIntentCopyWith<$Res> get intent {
  
  return $BuddyIntentCopyWith<$Res>(_self.intent, (value) {
    return _then(_self.copyWith(intent: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventQuestion implements BuddyTurnEvent {
  const BuddyTurnEventQuestion({required this.type, required this.text, required  List<String> options}): _options = options;
  factory BuddyTurnEventQuestion.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventQuestionFromJson(json);

 final  BuddyQuestionEventType type;
 final  String text;
 final  List<String> _options;
 List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventQuestionCopyWith<BuddyTurnEventQuestion> get copyWith => _$BuddyTurnEventQuestionCopyWithImpl<BuddyTurnEventQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventQuestion&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,text,const DeepCollectionEquality().hash(_options));
}

@override
String toString() {
    return 'BuddyTurnEvent.question(type: $type, text: $text, options: $options)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventQuestionCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventQuestionCopyWith(BuddyTurnEventQuestion value, $Res Function(BuddyTurnEventQuestion) _then) = _$BuddyTurnEventQuestionCopyWithImpl;
@useResult
$Res call({
 BuddyQuestionEventType type, String text, List<String> options
});




}
/// @nodoc
class _$BuddyTurnEventQuestionCopyWithImpl<$Res>
    implements $BuddyTurnEventQuestionCopyWith<$Res> {
  _$BuddyTurnEventQuestionCopyWithImpl(this._self, this._then);

  final BuddyTurnEventQuestion _self;
  final $Res Function(BuddyTurnEventQuestion) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,Object? options = null,}) {
  return _then(BuddyTurnEventQuestion(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyQuestionEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventPhoneTools implements BuddyTurnEvent {
  const BuddyTurnEventPhoneTools({required this.type, required this.round, required this.continuation, required  List<BuddyPhoneToolCall> calls}): _calls = calls;
  factory BuddyTurnEventPhoneTools.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventPhoneToolsFromJson(json);

 final  BuddyPhoneToolsEventType type;
 final  int round;
 final  String continuation;
 final  List<BuddyPhoneToolCall> _calls;
 List<BuddyPhoneToolCall> get calls {
  if (_calls is EqualUnmodifiableListView) return _calls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_calls);
}


/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventPhoneToolsCopyWith<BuddyTurnEventPhoneTools> get copyWith => _$BuddyTurnEventPhoneToolsCopyWithImpl<BuddyTurnEventPhoneTools>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventPhoneToolsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventPhoneTools&&(identical(other.type, type) || other.type == type)&&(identical(other.round, round) || other.round == round)&&(identical(other.continuation, continuation) || other.continuation == continuation)&&const DeepCollectionEquality().equals(other.calls, _calls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,round,continuation,const DeepCollectionEquality().hash(_calls));
}

@override
String toString() {
    return 'BuddyTurnEvent.phoneTools(type: $type, round: $round, continuation: $continuation, calls: $calls)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventPhoneToolsCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventPhoneToolsCopyWith(BuddyTurnEventPhoneTools value, $Res Function(BuddyTurnEventPhoneTools) _then) = _$BuddyTurnEventPhoneToolsCopyWithImpl;
@useResult
$Res call({
 BuddyPhoneToolsEventType type, int round, String continuation, List<BuddyPhoneToolCall> calls
});




}
/// @nodoc
class _$BuddyTurnEventPhoneToolsCopyWithImpl<$Res>
    implements $BuddyTurnEventPhoneToolsCopyWith<$Res> {
  _$BuddyTurnEventPhoneToolsCopyWithImpl(this._self, this._then);

  final BuddyTurnEventPhoneTools _self;
  final $Res Function(BuddyTurnEventPhoneTools) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? round = null,Object? continuation = null,Object? calls = null,}) {
  return _then(BuddyTurnEventPhoneTools(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyPhoneToolsEventType,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,continuation: null == continuation ? _self.continuation : continuation // ignore: cast_nullable_to_non_nullable
as String,calls: null == calls ? _self._calls : calls // ignore: cast_nullable_to_non_nullable
as List<BuddyPhoneToolCall>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventSummary implements BuddyTurnEvent {
  const BuddyTurnEventSummary({required this.type, required this.text, required this.revision, required this.watermark});
  factory BuddyTurnEventSummary.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventSummaryFromJson(json);

 final  BuddySummaryEventType type;
 final  String text;
 final  int revision;
 final  String watermark;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventSummaryCopyWith<BuddyTurnEventSummary> get copyWith => _$BuddyTurnEventSummaryCopyWithImpl<BuddyTurnEventSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventSummary&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.watermark, watermark) || other.watermark == watermark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,text,revision,watermark);
}

@override
String toString() {
    return 'BuddyTurnEvent.summary(type: $type, text: $text, revision: $revision, watermark: $watermark)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventSummaryCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventSummaryCopyWith(BuddyTurnEventSummary value, $Res Function(BuddyTurnEventSummary) _then) = _$BuddyTurnEventSummaryCopyWithImpl;
@useResult
$Res call({
 BuddySummaryEventType type, String text, int revision, String watermark
});




}
/// @nodoc
class _$BuddyTurnEventSummaryCopyWithImpl<$Res>
    implements $BuddyTurnEventSummaryCopyWith<$Res> {
  _$BuddyTurnEventSummaryCopyWithImpl(this._self, this._then);

  final BuddyTurnEventSummary _self;
  final $Res Function(BuddyTurnEventSummary) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,Object? revision = null,Object? watermark = null,}) {
  return _then(BuddyTurnEventSummary(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddySummaryEventType,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,watermark: null == watermark ? _self.watermark : watermark // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventTrace implements BuddyTurnEvent {
  const BuddyTurnEventTrace({required this.type, required  List<BuddyTraceStep> steps}): _steps = steps;
  factory BuddyTurnEventTrace.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventTraceFromJson(json);

 final  BuddyTraceEventType type;
 final  List<BuddyTraceStep> _steps;
 List<BuddyTraceStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventTraceCopyWith<BuddyTurnEventTrace> get copyWith => _$BuddyTurnEventTraceCopyWithImpl<BuddyTurnEventTrace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventTraceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventTrace&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_steps));
}

@override
String toString() {
    return 'BuddyTurnEvent.trace(type: $type, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventTraceCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventTraceCopyWith(BuddyTurnEventTrace value, $Res Function(BuddyTurnEventTrace) _then) = _$BuddyTurnEventTraceCopyWithImpl;
@useResult
$Res call({
 BuddyTraceEventType type, List<BuddyTraceStep> steps
});




}
/// @nodoc
class _$BuddyTurnEventTraceCopyWithImpl<$Res>
    implements $BuddyTurnEventTraceCopyWith<$Res> {
  _$BuddyTurnEventTraceCopyWithImpl(this._self, this._then);

  final BuddyTurnEventTrace _self;
  final $Res Function(BuddyTurnEventTrace) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? steps = null,}) {
  return _then(BuddyTurnEventTrace(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyTraceEventType,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<BuddyTraceStep>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventDone implements BuddyTurnEvent {
  const BuddyTurnEventDone({required this.type, required this.reason, required this.usage});
  factory BuddyTurnEventDone.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventDoneFromJson(json);

 final  BuddyDoneEventType type;
 final  BuddyDoneReason reason;
 final  BuddyTurnUsage usage;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventDoneCopyWith<BuddyTurnEventDone> get copyWith => _$BuddyTurnEventDoneCopyWithImpl<BuddyTurnEventDone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventDoneToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventDone&&(identical(other.type, type) || other.type == type)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,reason,usage);
}

@override
String toString() {
    return 'BuddyTurnEvent.done(type: $type, reason: $reason, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventDoneCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventDoneCopyWith(BuddyTurnEventDone value, $Res Function(BuddyTurnEventDone) _then) = _$BuddyTurnEventDoneCopyWithImpl;
@useResult
$Res call({
 BuddyDoneEventType type, BuddyDoneReason reason, BuddyTurnUsage usage
});


$BuddyTurnUsageCopyWith<$Res> get usage;

}
/// @nodoc
class _$BuddyTurnEventDoneCopyWithImpl<$Res>
    implements $BuddyTurnEventDoneCopyWith<$Res> {
  _$BuddyTurnEventDoneCopyWithImpl(this._self, this._then);

  final BuddyTurnEventDone _self;
  final $Res Function(BuddyTurnEventDone) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? reason = null,Object? usage = null,}) {
  return _then(BuddyTurnEventDone(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyDoneEventType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as BuddyDoneReason,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as BuddyTurnUsage,
  ));
}

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyTurnUsageCopyWith<$Res> get usage {
  
  return $BuddyTurnUsageCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventError implements BuddyTurnEvent {
  const BuddyTurnEventError({required this.type, required this.code});
  factory BuddyTurnEventError.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventErrorFromJson(json);

 final  BuddyErrorEventType type;
 final  BuddyTurnErrorCode code;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyTurnEventErrorCopyWith<BuddyTurnEventError> get copyWith => _$BuddyTurnEventErrorCopyWithImpl<BuddyTurnEventError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventErrorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventError&&(identical(other.type, type) || other.type == type)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,code);
}

@override
String toString() {
    return 'BuddyTurnEvent.error(type: $type, code: $code)';
}


}

/// @nodoc
abstract mixin class $BuddyTurnEventErrorCopyWith<$Res> implements $BuddyTurnEventCopyWith<$Res> {
  factory $BuddyTurnEventErrorCopyWith(BuddyTurnEventError value, $Res Function(BuddyTurnEventError) _then) = _$BuddyTurnEventErrorCopyWithImpl;
@useResult
$Res call({
 BuddyErrorEventType type, BuddyTurnErrorCode code
});




}
/// @nodoc
class _$BuddyTurnEventErrorCopyWithImpl<$Res>
    implements $BuddyTurnEventErrorCopyWith<$Res> {
  _$BuddyTurnEventErrorCopyWithImpl(this._self, this._then);

  final BuddyTurnEventError _self;
  final $Res Function(BuddyTurnEventError) _then;

/// Create a copy of BuddyTurnEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? code = null,}) {
  return _then(BuddyTurnEventError(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as BuddyErrorEventType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as BuddyTurnErrorCode,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyTurnEventUnrecognized implements BuddyTurnEvent {
  const BuddyTurnEventUnrecognized({ String? $type}): $type = $type ?? 'unrecognized';
  factory BuddyTurnEventUnrecognized.fromJson(Map<String, dynamic> json) => _$BuddyTurnEventUnrecognizedFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BuddyTurnEventUnrecognizedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyTurnEventUnrecognized);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyTurnEvent.unrecognized()';
}


}




// dart format on
