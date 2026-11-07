// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_weekly_check_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyWeeklyCheckIn _$BuddyWeeklyCheckInFromJson(Map<String, dynamic> json) =>
    _BuddyWeeklyCheckIn(
      currentKcal: (json['currentKcal'] as num).toDouble(),
      proposedKcal: (json['proposedKcal'] as num).toDouble(),
    );

Map<String, dynamic> _$BuddyWeeklyCheckInToJson(_BuddyWeeklyCheckIn instance) =>
    <String, dynamic>{
      'currentKcal': instance.currentKcal,
      'proposedKcal': instance.proposedKcal,
    };
