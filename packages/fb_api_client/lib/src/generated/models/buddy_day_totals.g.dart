// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_day_totals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyDayTotals _$BuddyDayTotalsFromJson(Map<String, dynamic> json) =>
    _BuddyDayTotals(
      kcal: (json['kcal'] as num).toDouble(),
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
      fiberG: (json['fiberG'] as num).toDouble(),
      targets: json['targets'] == null
          ? null
          : BuddyDayTargets.fromJson(json['targets'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyDayTotalsToJson(_BuddyDayTotals instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'fiberG': instance.fiberG,
      'targets': instance.targets?.toJson(),
    };
