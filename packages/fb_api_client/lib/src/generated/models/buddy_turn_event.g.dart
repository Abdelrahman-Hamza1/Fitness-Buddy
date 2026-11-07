// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_turn_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuddyTurnEventStep _$BuddyTurnEventStepFromJson(Map<String, dynamic> json) =>
    BuddyTurnEventStep(
      type: BuddyStepEventType.fromJson(json['type'] as String),
      code: BuddyStepCode.fromJson(json['code'] as String),
    );

Map<String, dynamic> _$BuddyTurnEventStepToJson(BuddyTurnEventStep instance) =>
    <String, dynamic>{
      'type': _$BuddyStepEventTypeEnumMap[instance.type]!,
      'code': _$BuddyStepCodeEnumMap[instance.code]!,
    };

const _$BuddyStepEventTypeEnumMap = {
  BuddyStepEventType.step: 'step',
  BuddyStepEventType.$unknown: r'$unknown',
};

const _$BuddyStepCodeEnumMap = {
  BuddyStepCode.searchingFoods: 'searchingFoods',
  BuddyStepCode.readingDiary: 'readingDiary',
  BuddyStepCode.readingYourFoods: 'readingYourFoods',
  BuddyStepCode.readingBody: 'readingBody',
  BuddyStepCode.readingWorkouts: 'readingWorkouts',
  BuddyStepCode.readingMemory: 'readingMemory',
  BuddyStepCode.computing: 'computing',
  BuddyStepCode.checkingFit: 'checkingFit',
  BuddyStepCode.writingReply: 'writingReply',
  BuddyStepCode.summarizing: 'summarizing',
  BuddyStepCode.searchingExercises: 'searchingExercises',
  BuddyStepCode.$unknown: r'$unknown',
};

BuddyTurnEventText _$BuddyTurnEventTextFromJson(Map<String, dynamic> json) =>
    BuddyTurnEventText(
      type: BuddyTextEventType.fromJson(json['type'] as String),
      text: json['text'] as String,
    );

Map<String, dynamic> _$BuddyTurnEventTextToJson(BuddyTurnEventText instance) =>
    <String, dynamic>{
      'type': _$BuddyTextEventTypeEnumMap[instance.type]!,
      'text': instance.text,
    };

const _$BuddyTextEventTypeEnumMap = {
  BuddyTextEventType.text: 'text',
  BuddyTextEventType.$unknown: r'$unknown',
};

BuddyTurnEventProposal _$BuddyTurnEventProposalFromJson(
  Map<String, dynamic> json,
) => BuddyTurnEventProposal(
  type: BuddyProposalEventType.fromJson(json['type'] as String),
  proposalId: json['proposalId'] as String,
  revision: (json['revision'] as num).toInt(),
  replaces: json['replaces'] == null
      ? null
      : BuddyCardRevision.fromJson(json['replaces'] as Map<String, dynamic>),
  intent: BuddyIntent.fromJson(json['intent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyTurnEventProposalToJson(
  BuddyTurnEventProposal instance,
) => <String, dynamic>{
  'type': _$BuddyProposalEventTypeEnumMap[instance.type]!,
  'proposalId': instance.proposalId,
  'revision': instance.revision,
  'replaces': instance.replaces?.toJson(),
  'intent': instance.intent.toJson(),
};

const _$BuddyProposalEventTypeEnumMap = {
  BuddyProposalEventType.proposal: 'proposal',
  BuddyProposalEventType.$unknown: r'$unknown',
};

BuddyTurnEventQuestion _$BuddyTurnEventQuestionFromJson(
  Map<String, dynamic> json,
) => BuddyTurnEventQuestion(
  type: BuddyQuestionEventType.fromJson(json['type'] as String),
  text: json['text'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$BuddyTurnEventQuestionToJson(
  BuddyTurnEventQuestion instance,
) => <String, dynamic>{
  'type': _$BuddyQuestionEventTypeEnumMap[instance.type]!,
  'text': instance.text,
  'options': instance.options,
};

const _$BuddyQuestionEventTypeEnumMap = {
  BuddyQuestionEventType.question: 'question',
  BuddyQuestionEventType.$unknown: r'$unknown',
};

BuddyTurnEventPhoneTools _$BuddyTurnEventPhoneToolsFromJson(
  Map<String, dynamic> json,
) => BuddyTurnEventPhoneTools(
  type: BuddyPhoneToolsEventType.fromJson(json['type'] as String),
  round: (json['round'] as num).toInt(),
  continuation: json['continuation'] as String,
  calls: (json['calls'] as List<dynamic>)
      .map((e) => BuddyPhoneToolCall.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BuddyTurnEventPhoneToolsToJson(
  BuddyTurnEventPhoneTools instance,
) => <String, dynamic>{
  'type': _$BuddyPhoneToolsEventTypeEnumMap[instance.type]!,
  'round': instance.round,
  'continuation': instance.continuation,
  'calls': instance.calls.map((e) => e.toJson()).toList(),
};

const _$BuddyPhoneToolsEventTypeEnumMap = {
  BuddyPhoneToolsEventType.phoneTools: 'phoneTools',
  BuddyPhoneToolsEventType.$unknown: r'$unknown',
};

BuddyTurnEventSummary _$BuddyTurnEventSummaryFromJson(
  Map<String, dynamic> json,
) => BuddyTurnEventSummary(
  type: BuddySummaryEventType.fromJson(json['type'] as String),
  text: json['text'] as String,
  revision: (json['revision'] as num).toInt(),
  watermark: json['watermark'] as String,
);

Map<String, dynamic> _$BuddyTurnEventSummaryToJson(
  BuddyTurnEventSummary instance,
) => <String, dynamic>{
  'type': _$BuddySummaryEventTypeEnumMap[instance.type]!,
  'text': instance.text,
  'revision': instance.revision,
  'watermark': instance.watermark,
};

const _$BuddySummaryEventTypeEnumMap = {
  BuddySummaryEventType.summary: 'summary',
  BuddySummaryEventType.$unknown: r'$unknown',
};

BuddyTurnEventTrace _$BuddyTurnEventTraceFromJson(Map<String, dynamic> json) =>
    BuddyTurnEventTrace(
      type: BuddyTraceEventType.fromJson(json['type'] as String),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => BuddyTraceStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyTurnEventTraceToJson(
  BuddyTurnEventTrace instance,
) => <String, dynamic>{
  'type': _$BuddyTraceEventTypeEnumMap[instance.type]!,
  'steps': instance.steps.map((e) => e.toJson()).toList(),
};

const _$BuddyTraceEventTypeEnumMap = {
  BuddyTraceEventType.trace: 'trace',
  BuddyTraceEventType.$unknown: r'$unknown',
};

BuddyTurnEventDone _$BuddyTurnEventDoneFromJson(Map<String, dynamic> json) =>
    BuddyTurnEventDone(
      type: BuddyDoneEventType.fromJson(json['type'] as String),
      reason: BuddyDoneReason.fromJson(json['reason'] as String),
      usage: BuddyTurnUsage.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyTurnEventDoneToJson(BuddyTurnEventDone instance) =>
    <String, dynamic>{
      'type': _$BuddyDoneEventTypeEnumMap[instance.type]!,
      'reason': _$BuddyDoneReasonEnumMap[instance.reason]!,
      'usage': instance.usage.toJson(),
    };

const _$BuddyDoneEventTypeEnumMap = {
  BuddyDoneEventType.done: 'done',
  BuddyDoneEventType.$unknown: r'$unknown',
};

const _$BuddyDoneReasonEnumMap = {
  BuddyDoneReason.answered: 'answered',
  BuddyDoneReason.asked: 'asked',
  BuddyDoneReason.declined: 'declined',
  BuddyDoneReason.limit: 'limit',
  BuddyDoneReason.quota: 'quota',
  BuddyDoneReason.$unknown: r'$unknown',
};

BuddyTurnEventError _$BuddyTurnEventErrorFromJson(Map<String, dynamic> json) =>
    BuddyTurnEventError(
      type: BuddyErrorEventType.fromJson(json['type'] as String),
      code: BuddyTurnErrorCode.fromJson(json['code'] as String),
    );

Map<String, dynamic> _$BuddyTurnEventErrorToJson(
  BuddyTurnEventError instance,
) => <String, dynamic>{
  'type': _$BuddyErrorEventTypeEnumMap[instance.type]!,
  'code': _$BuddyTurnErrorCodeEnumMap[instance.code]!,
};

const _$BuddyErrorEventTypeEnumMap = {
  BuddyErrorEventType.error: 'error',
  BuddyErrorEventType.$unknown: r'$unknown',
};

const _$BuddyTurnErrorCodeEnumMap = {
  BuddyTurnErrorCode.unavailable: 'unavailable',
  BuddyTurnErrorCode.timeout: 'timeout',
  BuddyTurnErrorCode.invalid: 'invalid',
  BuddyTurnErrorCode.roundAlreadyRan: 'roundAlreadyRan',
  BuddyTurnErrorCode.expired: 'expired',
  BuddyTurnErrorCode.$unknown: r'$unknown',
};

BuddyTurnEventUnrecognized _$BuddyTurnEventUnrecognizedFromJson(
  Map<String, dynamic> json,
) => BuddyTurnEventUnrecognized($type: json['type'] as String?);

Map<String, dynamic> _$BuddyTurnEventUnrecognizedToJson(
  BuddyTurnEventUnrecognized instance,
) => <String, dynamic>{'type': instance.$type};
