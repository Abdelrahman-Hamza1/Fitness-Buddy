// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buddy_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuddyIntentFoodLog _$BuddyIntentFoodLogFromJson(Map<String, dynamic> json) =>
    BuddyIntentFoodLog(
      kind: BuddyFoodLogKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      timeHint: json['timeHint'] as String?,
      slotHint: json['slotHint'] as String?,
      dishGroup: json['dishGroup'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BuddyIntentFoodLogToJson(BuddyIntentFoodLog instance) =>
    <String, dynamic>{
      'kind': _$BuddyFoodLogKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'timeHint': instance.timeHint,
      'slotHint': instance.slotHint,
      'dishGroup': instance.dishGroup,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$BuddyFoodLogKindEnumMap = {
  BuddyFoodLogKind.foodLog: 'foodLog',
  BuddyFoodLogKind.$unknown: r'$unknown',
};

BuddyIntentClarify _$BuddyIntentClarifyFromJson(Map<String, dynamic> json) =>
    BuddyIntentClarify(
      kind: BuddyClarifyKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$BuddyIntentClarifyToJson(BuddyIntentClarify instance) =>
    <String, dynamic>{
      'kind': _$BuddyClarifyKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'reason': instance.reason,
    };

const _$BuddyClarifyKindEnumMap = {
  BuddyClarifyKind.clarify: 'clarify',
  BuddyClarifyKind.$unknown: r'$unknown',
};

BuddyIntentOutOfScope _$BuddyIntentOutOfScopeFromJson(
  Map<String, dynamic> json,
) => BuddyIntentOutOfScope(
  kind: BuddyOutOfScopeKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  reason: json['reason'] as String,
);

Map<String, dynamic> _$BuddyIntentOutOfScopeToJson(
  BuddyIntentOutOfScope instance,
) => <String, dynamic>{
  'kind': _$BuddyOutOfScopeKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'reason': instance.reason,
};

const _$BuddyOutOfScopeKindEnumMap = {
  BuddyOutOfScopeKind.outOfScope: 'outOfScope',
  BuddyOutOfScopeKind.$unknown: r'$unknown',
};

BuddyIntentMedical _$BuddyIntentMedicalFromJson(Map<String, dynamic> json) =>
    BuddyIntentMedical(
      kind: BuddyMedicalKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
    );

Map<String, dynamic> _$BuddyIntentMedicalToJson(BuddyIntentMedical instance) =>
    <String, dynamic>{
      'kind': _$BuddyMedicalKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
    };

const _$BuddyMedicalKindEnumMap = {
  BuddyMedicalKind.medical: 'medical',
  BuddyMedicalKind.$unknown: r'$unknown',
};

BuddyIntentWeighIn _$BuddyIntentWeighInFromJson(Map<String, dynamic> json) =>
    BuddyIntentWeighIn(
      kind: BuddyWeighInKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timeHint: json['timeHint'] as String?,
    );

Map<String, dynamic> _$BuddyIntentWeighInToJson(BuddyIntentWeighIn instance) =>
    <String, dynamic>{
      'kind': _$BuddyWeighInKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'value': instance.value,
      'unit': instance.unit,
      'timeHint': instance.timeHint,
    };

const _$BuddyWeighInKindEnumMap = {
  BuddyWeighInKind.weighIn: 'weighIn',
  BuddyWeighInKind.$unknown: r'$unknown',
};

BuddyIntentUnrecognized _$BuddyIntentUnrecognizedFromJson(
  Map<String, dynamic> json,
) => BuddyIntentUnrecognized($type: json['kind'] as String?);

Map<String, dynamic> _$BuddyIntentUnrecognizedToJson(
  BuddyIntentUnrecognized instance,
) => <String, dynamic>{'kind': instance.$type};
