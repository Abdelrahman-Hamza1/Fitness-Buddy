// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryFilters _$BuddyQueryFiltersFromJson(Map<String, dynamic> json) =>
    _BuddyQueryFilters(
      slot: json['slot'] as String?,
      exerciseRef: json['exerciseRef'] as String?,
      muscleGroup: json['muscleGroup'] as String?,
      completeDaysOnly: json['completeDaysOnly'] as bool?,
      weekdays: (json['weekdays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$BuddyQueryFiltersToJson(_BuddyQueryFilters instance) =>
    <String, dynamic>{
      'slot': instance.slot,
      'exerciseRef': instance.exerciseRef,
      'muscleGroup': instance.muscleGroup,
      'completeDaysOnly': instance.completeDaysOnly,
      'weekdays': instance.weekdays,
    };
