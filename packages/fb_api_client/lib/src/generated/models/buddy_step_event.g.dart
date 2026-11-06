// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_step_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyStepEvent _$BuddyStepEventFromJson(Map<String, dynamic> json) =>
    _BuddyStepEvent(
      type: BuddyStepEventType.fromJson(json['type'] as String),
      code: BuddyStepCode.fromJson(json['code'] as String),
    );

Map<String, dynamic> _$BuddyStepEventToJson(_BuddyStepEvent instance) =>
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
  BuddyStepCode.$unknown: r'$unknown',
};
