// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_claim_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyClaimValue _$BuddyClaimValueFromJson(Map<String, dynamic> json) =>
    _BuddyClaimValue(
      metric: BuddyQueryMetric.fromJson(json['metric'] as String),
      operation: BuddyQueryOp.fromJson(json['operation'] as String),
      value: (json['value'] as num?)?.toDouble(),
      date: json['date'] as String?,
      unit: BuddyClaimUnit.fromJson(json['unit'] as String),
      workoutId: json['workoutId'] as String?,
      exerciseRef: json['exerciseRef'] as String?,
      muscleGroup: json['muscleGroup'] as String?,
    );

Map<String, dynamic> _$BuddyClaimValueToJson(_BuddyClaimValue instance) =>
    <String, dynamic>{
      'metric': _$BuddyQueryMetricEnumMap[instance.metric]!,
      'operation': _$BuddyQueryOpEnumMap[instance.operation]!,
      'value': instance.value,
      'date': instance.date,
      'unit': _$BuddyClaimUnitEnumMap[instance.unit]!,
      'workoutId': instance.workoutId,
      'exerciseRef': instance.exerciseRef,
      'muscleGroup': instance.muscleGroup,
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

const _$BuddyClaimUnitEnumMap = {
  BuddyClaimUnit.kcal: 'kcal',
  BuddyClaimUnit.g: 'g',
  BuddyClaimUnit.kg: 'kg',
  BuddyClaimUnit.cm: 'cm',
  BuddyClaimUnit.percent: 'percent',
  BuddyClaimUnit.count: 'count',
  BuddyClaimUnit.date: 'date',
  BuddyClaimUnit.$unknown: r'$unknown',
};
