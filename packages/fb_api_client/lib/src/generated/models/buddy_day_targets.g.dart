// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_day_targets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDayTargets _$BuddyDayTargetsFromJson(Map<String, dynamic> json) =>
    _BuddyDayTargets(
      kcal: (json['kcal'] as num?)?.toDouble(),
      proteinG: (json['proteinG'] as num?)?.toDouble(),
      carbsG: (json['carbsG'] as num?)?.toDouble(),
      fatG: (json['fatG'] as num?)?.toDouble(),
      fiberG: (json['fiberG'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BuddyDayTargetsToJson(_BuddyDayTargets instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'fiberG': instance.fiberG,
    };
