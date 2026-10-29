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
      dateHint: json['dateHint'] as String?,
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
      'dateHint': instance.dateHint,
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
      dateHint: json['dateHint'] as String?,
    );

Map<String, dynamic> _$BuddyIntentWeighInToJson(BuddyIntentWeighIn instance) =>
    <String, dynamic>{
      'kind': _$BuddyWeighInKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'value': instance.value,
      'unit': instance.unit,
      'timeHint': instance.timeHint,
      'dateHint': instance.dateHint,
    };

const _$BuddyWeighInKindEnumMap = {
  BuddyWeighInKind.weighIn: 'weighIn',
  BuddyWeighInKind.$unknown: r'$unknown',
};

BuddyIntentDiaryEdit _$BuddyIntentDiaryEditFromJson(
  Map<String, dynamic> json,
) => BuddyIntentDiaryEdit(
  kind: BuddyDiaryEditKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  targets: (json['targets'] as List<dynamic>).map((e) => e as String).toList(),
  reference: BuddyEntryReference.fromJson(
    json['reference'] as Map<String, dynamic>,
  ),
  patch: BuddyDiaryPatch.fromJson(json['patch'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyIntentDiaryEditToJson(
  BuddyIntentDiaryEdit instance,
) => <String, dynamic>{
  'kind': _$BuddyDiaryEditKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'targets': instance.targets,
  'reference': instance.reference.toJson(),
  'patch': instance.patch.toJson(),
};

const _$BuddyDiaryEditKindEnumMap = {
  BuddyDiaryEditKind.diaryEdit: 'diaryEdit',
  BuddyDiaryEditKind.$unknown: r'$unknown',
};

BuddyIntentDiaryDelete _$BuddyIntentDiaryDeleteFromJson(
  Map<String, dynamic> json,
) => BuddyIntentDiaryDelete(
  kind: BuddyDiaryDeleteKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  targets: (json['targets'] as List<dynamic>).map((e) => e as String).toList(),
  reference: BuddyEntryReference.fromJson(
    json['reference'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$BuddyIntentDiaryDeleteToJson(
  BuddyIntentDiaryDelete instance,
) => <String, dynamic>{
  'kind': _$BuddyDiaryDeleteKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'targets': instance.targets,
  'reference': instance.reference.toJson(),
};

const _$BuddyDiaryDeleteKindEnumMap = {
  BuddyDiaryDeleteKind.diaryDelete: 'diaryDelete',
  BuddyDiaryDeleteKind.$unknown: r'$unknown',
};

BuddyIntentAmbiguousReference _$BuddyIntentAmbiguousReferenceFromJson(
  Map<String, dynamic> json,
) => BuddyIntentAmbiguousReference(
  kind: BuddyAmbiguousReferenceKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  operation: BuddyReferenceOperation.fromJson(json['operation'] as String),
  candidates: (json['candidates'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  reference: BuddyEntryReference.fromJson(
    json['reference'] as Map<String, dynamic>,
  ),
  patch: json['patch'] == null
      ? null
      : BuddyDiaryPatch.fromJson(json['patch'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyIntentAmbiguousReferenceToJson(
  BuddyIntentAmbiguousReference instance,
) => <String, dynamic>{
  'kind': _$BuddyAmbiguousReferenceKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'operation': _$BuddyReferenceOperationEnumMap[instance.operation]!,
  'candidates': instance.candidates,
  'reference': instance.reference.toJson(),
  'patch': instance.patch?.toJson(),
};

const _$BuddyAmbiguousReferenceKindEnumMap = {
  BuddyAmbiguousReferenceKind.ambiguousReference: 'ambiguousReference',
  BuddyAmbiguousReferenceKind.$unknown: r'$unknown',
};

const _$BuddyReferenceOperationEnumMap = {
  BuddyReferenceOperation.edit: 'edit',
  BuddyReferenceOperation.delete: 'delete',
  BuddyReferenceOperation.$unknown: r'$unknown',
};

BuddyIntentDiaryCopy _$BuddyIntentDiaryCopyFromJson(
  Map<String, dynamic> json,
) => BuddyIntentDiaryCopy(
  kind: BuddyDiaryCopyKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  source: BuddyDayHint.fromJson(json['source'] as Map<String, dynamic>),
  target: BuddyDayHint.fromJson(json['target'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyIntentDiaryCopyToJson(
  BuddyIntentDiaryCopy instance,
) => <String, dynamic>{
  'kind': _$BuddyDiaryCopyKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'source': instance.source.toJson(),
  'target': instance.target.toJson(),
};

const _$BuddyDiaryCopyKindEnumMap = {
  BuddyDiaryCopyKind.diaryCopy: 'diaryCopy',
  BuddyDiaryCopyKind.$unknown: r'$unknown',
};

BuddyIntentMemoryChange _$BuddyIntentMemoryChangeFromJson(
  Map<String, dynamic> json,
) => BuddyIntentMemoryChange(
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

Map<String, dynamic> _$BuddyIntentMemoryChangeToJson(
  BuddyIntentMemoryChange instance,
) => <String, dynamic>{
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

BuddyIntentBatch _$BuddyIntentBatchFromJson(Map<String, dynamic> json) =>
    BuddyIntentBatch(
      kind: BuddyBatchKind.fromJson(json['kind'] as String),
      language: json['language'] as String,
      script: json['script'] as String,
      name: json['name'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      cookedWeight: json['cookedWeight'] == null
          ? null
          : BuddyAmount.fromJson(json['cookedWeight'] as Map<String, dynamic>),
      path: json['path'] == null
          ? null
          : BuddyBatchPath.fromJson(json['path'] as String),
      eatenNow: json['eatenNow'] == null
          ? null
          : BuddyPortion.fromJson(json['eatenNow'] as Map<String, dynamic>),
      timeHint: json['timeHint'] as String?,
      slotHint: json['slotHint'] as String?,
      dateHint: json['dateHint'] as String?,
    );

Map<String, dynamic> _$BuddyIntentBatchToJson(BuddyIntentBatch instance) =>
    <String, dynamic>{
      'kind': _$BuddyBatchKindEnumMap[instance.kind]!,
      'language': instance.language,
      'script': instance.script,
      'name': instance.name,
      'ingredients': instance.ingredients.map((e) => e.toJson()).toList(),
      'cookedWeight': instance.cookedWeight?.toJson(),
      'path': _$BuddyBatchPathEnumMap[instance.path],
      'eatenNow': instance.eatenNow?.toJson(),
      'timeHint': instance.timeHint,
      'slotHint': instance.slotHint,
      'dateHint': instance.dateHint,
    };

const _$BuddyBatchKindEnumMap = {
  BuddyBatchKind.batch: 'batch',
  BuddyBatchKind.$unknown: r'$unknown',
};

const _$BuddyBatchPathEnumMap = {
  BuddyBatchPath.quick: 'quick',
  BuddyBatchPath.leftovers: 'leftovers',
  BuddyBatchPath.$unknown: r'$unknown',
};

BuddyIntentBatchPortion _$BuddyIntentBatchPortionFromJson(
  Map<String, dynamic> json,
) => BuddyIntentBatchPortion(
  kind: BuddyBatchPortionKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  batchId: json['batchId'] as String,
  portion: json['portion'] == null
      ? null
      : BuddyPortion.fromJson(json['portion'] as Map<String, dynamic>),
  rest: json['rest'] as bool,
  timeHint: json['timeHint'] as String?,
  slotHint: json['slotHint'] as String?,
  dateHint: json['dateHint'] as String?,
);

Map<String, dynamic> _$BuddyIntentBatchPortionToJson(
  BuddyIntentBatchPortion instance,
) => <String, dynamic>{
  'kind': _$BuddyBatchPortionKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'batchId': instance.batchId,
  'portion': instance.portion?.toJson(),
  'rest': instance.rest,
  'timeHint': instance.timeHint,
  'slotHint': instance.slotHint,
  'dateHint': instance.dateHint,
};

const _$BuddyBatchPortionKindEnumMap = {
  BuddyBatchPortionKind.batchPortion: 'batchPortion',
  BuddyBatchPortionKind.$unknown: r'$unknown',
};

BuddyIntentBatchClose _$BuddyIntentBatchCloseFromJson(
  Map<String, dynamic> json,
) => BuddyIntentBatchClose(
  kind: BuddyBatchCloseKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  batchId: json['batchId'] as String,
);

Map<String, dynamic> _$BuddyIntentBatchCloseToJson(
  BuddyIntentBatchClose instance,
) => <String, dynamic>{
  'kind': _$BuddyBatchCloseKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'batchId': instance.batchId,
};

const _$BuddyBatchCloseKindEnumMap = {
  BuddyBatchCloseKind.batchClose: 'batchClose',
  BuddyBatchCloseKind.$unknown: r'$unknown',
};

BuddyIntentPersonalFoodCreate _$BuddyIntentPersonalFoodCreateFromJson(
  Map<String, dynamic> json,
) => BuddyIntentPersonalFoodCreate(
  kind: BuddyPersonalFoodCreateKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  name: json['name'] as String,
  aliases: (json['aliases'] as List<dynamic>).map((e) => e as String).toList(),
  components: (json['components'] as List<dynamic>)
      .map((e) => BuddyFoodItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  stated: json['stated'] == null
      ? null
      : BuddyStatedNutrients.fromJson(json['stated'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyIntentPersonalFoodCreateToJson(
  BuddyIntentPersonalFoodCreate instance,
) => <String, dynamic>{
  'kind': _$BuddyPersonalFoodCreateKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'name': instance.name,
  'aliases': instance.aliases,
  'components': instance.components.map((e) => e.toJson()).toList(),
  'stated': instance.stated?.toJson(),
};

const _$BuddyPersonalFoodCreateKindEnumMap = {
  BuddyPersonalFoodCreateKind.personalFoodCreate: 'personalFoodCreate',
  BuddyPersonalFoodCreateKind.$unknown: r'$unknown',
};

BuddyIntentSavedMealLog _$BuddyIntentSavedMealLogFromJson(
  Map<String, dynamic> json,
) => BuddyIntentSavedMealLog(
  kind: BuddySavedMealLogKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  savedMealId: json['savedMealId'] as String,
  timeHint: json['timeHint'] as String?,
  slotHint: json['slotHint'] as String?,
  dateHint: json['dateHint'] as String?,
  share: json['share'] == null
      ? null
      : BuddyShare.fromJson(json['share'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyIntentSavedMealLogToJson(
  BuddyIntentSavedMealLog instance,
) => <String, dynamic>{
  'kind': _$BuddySavedMealLogKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'savedMealId': instance.savedMealId,
  'timeHint': instance.timeHint,
  'slotHint': instance.slotHint,
  'dateHint': instance.dateHint,
  'share': instance.share?.toJson(),
};

const _$BuddySavedMealLogKindEnumMap = {
  BuddySavedMealLogKind.savedMealLog: 'savedMealLog',
  BuddySavedMealLogKind.$unknown: r'$unknown',
};

BuddyIntentSavedMealCreate _$BuddyIntentSavedMealCreateFromJson(
  Map<String, dynamic> json,
) => BuddyIntentSavedMealCreate(
  kind: BuddySavedMealCreateKind.fromJson(json['kind'] as String),
  language: json['language'] as String,
  script: json['script'] as String,
  name: json['name'] as String,
  activeProposal: json['activeProposal'] as String?,
  targets: (json['targets'] as List<dynamic>).map((e) => e as String).toList(),
  source: json['source'] == null
      ? null
      : BuddyDayHint.fromJson(json['source'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BuddyIntentSavedMealCreateToJson(
  BuddyIntentSavedMealCreate instance,
) => <String, dynamic>{
  'kind': _$BuddySavedMealCreateKindEnumMap[instance.kind]!,
  'language': instance.language,
  'script': instance.script,
  'name': instance.name,
  'activeProposal': instance.activeProposal,
  'targets': instance.targets,
  'source': instance.source?.toJson(),
};

const _$BuddySavedMealCreateKindEnumMap = {
  BuddySavedMealCreateKind.savedMealCreate: 'savedMealCreate',
  BuddySavedMealCreateKind.$unknown: r'$unknown',
};

BuddyIntentUnrecognized _$BuddyIntentUnrecognizedFromJson(
  Map<String, dynamic> json,
) => BuddyIntentUnrecognized($type: json['kind'] as String?);

Map<String, dynamic> _$BuddyIntentUnrecognizedToJson(
  BuddyIntentUnrecognized instance,
) => <String, dynamic>{'kind': instance.$type};
