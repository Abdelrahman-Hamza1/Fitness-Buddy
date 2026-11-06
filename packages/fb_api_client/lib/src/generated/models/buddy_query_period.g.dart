// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryPeriod _$BuddyQueryPeriodFromJson(Map<String, dynamic> json) =>
    _BuddyQueryPeriod(
      kind: BuddyPeriodKind.fromJson(json['kind'] as String),
      days: (json['days'] as num?)?.toInt(),
      since: json['since'] == null
          ? null
          : BuddySinceEvent.fromJson(json['since'] as String),
      from: json['from'] as String?,
      to: json['to'] as String?,
    );

Map<String, dynamic> _$BuddyQueryPeriodToJson(_BuddyQueryPeriod instance) =>
    <String, dynamic>{
      'kind': _$BuddyPeriodKindEnumMap[instance.kind]!,
      'days': instance.days,
      'since': _$BuddySinceEventEnumMap[instance.since],
      'from': instance.from,
      'to': instance.to,
    };

const _$BuddyPeriodKindEnumMap = {
  BuddyPeriodKind.today: 'today',
  BuddyPeriodKind.yesterday: 'yesterday',
  BuddyPeriodKind.thisWeek: 'thisWeek',
  BuddyPeriodKind.lastWeek: 'lastWeek',
  BuddyPeriodKind.thisMonth: 'thisMonth',
  BuddyPeriodKind.lastMonth: 'lastMonth',
  BuddyPeriodKind.lastNDays: 'lastNDays',
  BuddyPeriodKind.since: 'since',
  BuddyPeriodKind.range: 'range',
  BuddyPeriodKind.$unknown: r'$unknown',
};

const _$BuddySinceEventEnumMap = {
  BuddySinceEvent.ramadanStart: 'ramadanStart',
  BuddySinceEvent.phaseStart: 'phaseStart',
  BuddySinceEvent.date: 'date',
  BuddySinceEvent.$unknown: r'$unknown',
};
