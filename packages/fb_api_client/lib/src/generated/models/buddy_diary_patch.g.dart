// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_diary_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDiaryPatch _$BuddyDiaryPatchFromJson(Map<String, dynamic> json) =>
    _BuddyDiaryPatch(
      amount: json['amount'] == null
          ? null
          : BuddyAmount.fromJson(json['amount'] as Map<String, dynamic>),
      replacement: json['replacement'] == null
          ? null
          : BuddyFoodItem.fromJson(json['replacement'] as Map<String, dynamic>),
      move: json['move'] == null
          ? null
          : BuddyDayHint.fromJson(json['move'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyDiaryPatchToJson(_BuddyDiaryPatch instance) =>
    <String, dynamic>{
      'amount': instance.amount?.toJson(),
      'replacement': instance.replacement?.toJson(),
      'move': instance.move?.toJson(),
    };
