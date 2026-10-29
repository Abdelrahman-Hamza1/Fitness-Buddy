// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_memory_change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuddyMemoryChange _$BuddyMemoryChangeFromJson(Map<String, dynamic> json) =>
    _BuddyMemoryChange(
      kind: BuddyMemoryChangeKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      operation: BuddyMemoryOperation.fromJson(json['operation'] as String),
      memoryKind: BuddyMemoryKind.fromJson(json['memoryKind'] as String),
      subject: json['subject'] as String?,
      dimension: json['dimension'] == null
          ? null
          : BuddyMemoryDimension.fromJson(json['dimension'] as String),
      value: json['value'] as String?,
      amount: json['amount'] == null
          ? null
          : BuddyAmount.fromJson(json['amount'] as Map<String, dynamic>),
      food: json['food'] == null
          ? null
          : BuddyFoodItem.fromJson(json['food'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuddyMemoryChangeToJson(_BuddyMemoryChange instance) =>
    <String, dynamic>{
      'kind': _$BuddyMemoryChangeKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'operation': _$BuddyMemoryOperationEnumMap[instance.operation]!,
      'memoryKind': _$BuddyMemoryKindEnumMap[instance.memoryKind]!,
      'subject': instance.subject,
      'dimension': _$BuddyMemoryDimensionEnumMap[instance.dimension],
      'value': instance.value,
      'amount': instance.amount?.toJson(),
      'food': instance.food?.toJson(),
    };

const _$BuddyMemoryChangeKindEnumMap = {
  BuddyMemoryChangeKind.memoryChange: 'memoryChange',
  BuddyMemoryChangeKind.$unknown: r'$unknown',
};

const _$BuddyMemoryOperationEnumMap = {
  BuddyMemoryOperation.remember: 'remember',
  BuddyMemoryOperation.forget: 'forget',
  BuddyMemoryOperation.$unknown: r'$unknown',
};

const _$BuddyMemoryKindEnumMap = {
  BuddyMemoryKind.valueDefault: 'default',
  BuddyMemoryKind.portion: 'portion',
  BuddyMemoryKind.alias: 'alias',
  BuddyMemoryKind.brand: 'brand',
  BuddyMemoryKind.nickname: 'nickname',
  BuddyMemoryKind.$unknown: r'$unknown',
};

const _$BuddyMemoryDimensionEnumMap = {
  BuddyMemoryDimension.state: 'state',
  BuddyMemoryDimension.fat: 'fat',
  BuddyMemoryDimension.variant: 'variant',
  BuddyMemoryDimension.portion: 'portion',
  BuddyMemoryDimension.$unknown: r'$unknown',
};
