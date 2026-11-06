// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_query_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyQueryPlan _$BuddyQueryPlanFromJson(Map<String, dynamic> json) =>
    _BuddyQueryPlan(
      metric: BuddyQueryMetric.fromJson(json['metric'] as String),
      measurementType: json['measurementType'] as String?,
      op: BuddyQueryOp.fromJson(json['op'] as String),
      period: BuddyQueryPeriod.fromJson(json['period'] as Map<String, dynamic>),
      filters: json['filters'] == null
          ? null
          : BuddyQueryFilters.fromJson(json['filters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyQueryPlanToJson(_BuddyQueryPlan instance) =>
    <String, dynamic>{
      'metric': _$BuddyQueryMetricEnumMap[instance.metric]!,
      'measurementType': instance.measurementType,
      'op': _$BuddyQueryOpEnumMap[instance.op]!,
      'period': instance.period.toJson(),
      'filters': instance.filters?.toJson(),
    };

const _$BuddyQueryMetricEnumMap = {
  BuddyQueryMetric.kcal: 'kcal',
  BuddyQueryMetric.protein: 'protein',
  BuddyQueryMetric.carbs: 'carbs',
  BuddyQueryMetric.fat: 'fat',
  BuddyQueryMetric.fiber: 'fiber',
  BuddyQueryMetric.weight: 'weight',
  BuddyQueryMetric.weightTrend: 'weightTrend',
  BuddyQueryMetric.measurement: 'measurement',
  BuddyQueryMetric.workouts: 'workouts',
  BuddyQueryMetric.sets: 'sets',
  BuddyQueryMetric.volume: 'volume',
  BuddyQueryMetric.exerciseLastDate: 'exerciseLastDate',
  BuddyQueryMetric.exercisePr: 'exercisePr',
  BuddyQueryMetric.weighIns: 'weighIns',
  BuddyQueryMetric.loggedDays: 'loggedDays',
  BuddyQueryMetric.$unknown: r'$unknown',
};

const _$BuddyQueryOpEnumMap = {
  BuddyQueryOp.total: 'total',
  BuddyQueryOp.average: 'average',
  BuddyQueryOp.remaining: 'remaining',
  BuddyQueryOp.latest: 'latest',
  BuddyQueryOp.change: 'change',
  BuddyQueryOp.count: 'count',
  BuddyQueryOp.max: 'max',
  BuddyQueryOp.min: 'min',
  BuddyQueryOp.last: 'last',
  BuddyQueryOp.$unknown: r'$unknown',
};
