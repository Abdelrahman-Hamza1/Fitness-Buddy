// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'buddy_intent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
BuddyIntent _$BuddyIntentFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'foodLog':
          return BuddyIntentFoodLog.fromJson(
            json
          );
                case 'clarify':
          return BuddyIntentClarify.fromJson(
            json
          );
                case 'outOfScope':
          return BuddyIntentOutOfScope.fromJson(
            json
          );
                case 'medical':
          return BuddyIntentMedical.fromJson(
            json
          );
                case 'weighIn':
          return BuddyIntentWeighIn.fromJson(
            json
          );
                case 'diaryEdit':
          return BuddyIntentDiaryEdit.fromJson(
            json
          );
                case 'diaryDelete':
          return BuddyIntentDiaryDelete.fromJson(
            json
          );
                case 'ambiguousReference':
          return BuddyIntentAmbiguousReference.fromJson(
            json
          );
                case 'diaryCopy':
          return BuddyIntentDiaryCopy.fromJson(
            json
          );
                case 'memoryChange':
          return BuddyIntentMemoryChange.fromJson(
            json
          );
                case 'batch':
          return BuddyIntentBatch.fromJson(
            json
          );
                case 'batchPortion':
          return BuddyIntentBatchPortion.fromJson(
            json
          );
                case 'batchClose':
          return BuddyIntentBatchClose.fromJson(
            json
          );
                case 'personalFoodCreate':
          return BuddyIntentPersonalFoodCreate.fromJson(
            json
          );
                case 'savedMealLog':
          return BuddyIntentSavedMealLog.fromJson(
            json
          );
                case 'savedMealCreate':
          return BuddyIntentSavedMealCreate.fromJson(
            json
          );
        
          default:
            return BuddyIntentUnrecognized.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$BuddyIntent {



  /// Serializes this BuddyIntent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyIntent()';
}


}

/// @nodoc
class $BuddyIntentCopyWith<$Res>  {
$BuddyIntentCopyWith(BuddyIntent _, $Res Function(BuddyIntent) __);
}


/// Adds pattern-matching-related methods to [BuddyIntent].
extension BuddyIntentPatterns on BuddyIntent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BuddyIntentFoodLog value)?  foodLog,TResult Function( BuddyIntentClarify value)?  clarify,TResult Function( BuddyIntentOutOfScope value)?  outOfScope,TResult Function( BuddyIntentMedical value)?  medical,TResult Function( BuddyIntentWeighIn value)?  weighIn,TResult Function( BuddyIntentDiaryEdit value)?  diaryEdit,TResult Function( BuddyIntentDiaryDelete value)?  diaryDelete,TResult Function( BuddyIntentAmbiguousReference value)?  ambiguousReference,TResult Function( BuddyIntentDiaryCopy value)?  diaryCopy,TResult Function( BuddyIntentMemoryChange value)?  memoryChange,TResult Function( BuddyIntentBatch value)?  batch,TResult Function( BuddyIntentBatchPortion value)?  batchPortion,TResult Function( BuddyIntentBatchClose value)?  batchClose,TResult Function( BuddyIntentPersonalFoodCreate value)?  personalFoodCreate,TResult Function( BuddyIntentSavedMealLog value)?  savedMealLog,TResult Function( BuddyIntentSavedMealCreate value)?  savedMealCreate,TResult Function( BuddyIntentUnrecognized value)?  unrecognized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that);case BuddyIntentClarify() when clarify != null:
return clarify(_that);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that);case BuddyIntentMedical() when medical != null:
return medical(_that);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that);case BuddyIntentDiaryEdit() when diaryEdit != null:
return diaryEdit(_that);case BuddyIntentDiaryDelete() when diaryDelete != null:
return diaryDelete(_that);case BuddyIntentAmbiguousReference() when ambiguousReference != null:
return ambiguousReference(_that);case BuddyIntentDiaryCopy() when diaryCopy != null:
return diaryCopy(_that);case BuddyIntentMemoryChange() when memoryChange != null:
return memoryChange(_that);case BuddyIntentBatch() when batch != null:
return batch(_that);case BuddyIntentBatchPortion() when batchPortion != null:
return batchPortion(_that);case BuddyIntentBatchClose() when batchClose != null:
return batchClose(_that);case BuddyIntentPersonalFoodCreate() when personalFoodCreate != null:
return personalFoodCreate(_that);case BuddyIntentSavedMealLog() when savedMealLog != null:
return savedMealLog(_that);case BuddyIntentSavedMealCreate() when savedMealCreate != null:
return savedMealCreate(_that);case BuddyIntentUnrecognized() when unrecognized != null:
return unrecognized(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BuddyIntentFoodLog value)  foodLog,required TResult Function( BuddyIntentClarify value)  clarify,required TResult Function( BuddyIntentOutOfScope value)  outOfScope,required TResult Function( BuddyIntentMedical value)  medical,required TResult Function( BuddyIntentWeighIn value)  weighIn,required TResult Function( BuddyIntentDiaryEdit value)  diaryEdit,required TResult Function( BuddyIntentDiaryDelete value)  diaryDelete,required TResult Function( BuddyIntentAmbiguousReference value)  ambiguousReference,required TResult Function( BuddyIntentDiaryCopy value)  diaryCopy,required TResult Function( BuddyIntentMemoryChange value)  memoryChange,required TResult Function( BuddyIntentBatch value)  batch,required TResult Function( BuddyIntentBatchPortion value)  batchPortion,required TResult Function( BuddyIntentBatchClose value)  batchClose,required TResult Function( BuddyIntentPersonalFoodCreate value)  personalFoodCreate,required TResult Function( BuddyIntentSavedMealLog value)  savedMealLog,required TResult Function( BuddyIntentSavedMealCreate value)  savedMealCreate,required TResult Function( BuddyIntentUnrecognized value)  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyIntentFoodLog():
return foodLog(_that);case BuddyIntentClarify():
return clarify(_that);case BuddyIntentOutOfScope():
return outOfScope(_that);case BuddyIntentMedical():
return medical(_that);case BuddyIntentWeighIn():
return weighIn(_that);case BuddyIntentDiaryEdit():
return diaryEdit(_that);case BuddyIntentDiaryDelete():
return diaryDelete(_that);case BuddyIntentAmbiguousReference():
return ambiguousReference(_that);case BuddyIntentDiaryCopy():
return diaryCopy(_that);case BuddyIntentMemoryChange():
return memoryChange(_that);case BuddyIntentBatch():
return batch(_that);case BuddyIntentBatchPortion():
return batchPortion(_that);case BuddyIntentBatchClose():
return batchClose(_that);case BuddyIntentPersonalFoodCreate():
return personalFoodCreate(_that);case BuddyIntentSavedMealLog():
return savedMealLog(_that);case BuddyIntentSavedMealCreate():
return savedMealCreate(_that);case BuddyIntentUnrecognized():
return unrecognized(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BuddyIntentFoodLog value)?  foodLog,TResult? Function( BuddyIntentClarify value)?  clarify,TResult? Function( BuddyIntentOutOfScope value)?  outOfScope,TResult? Function( BuddyIntentMedical value)?  medical,TResult? Function( BuddyIntentWeighIn value)?  weighIn,TResult? Function( BuddyIntentDiaryEdit value)?  diaryEdit,TResult? Function( BuddyIntentDiaryDelete value)?  diaryDelete,TResult? Function( BuddyIntentAmbiguousReference value)?  ambiguousReference,TResult? Function( BuddyIntentDiaryCopy value)?  diaryCopy,TResult? Function( BuddyIntentMemoryChange value)?  memoryChange,TResult? Function( BuddyIntentBatch value)?  batch,TResult? Function( BuddyIntentBatchPortion value)?  batchPortion,TResult? Function( BuddyIntentBatchClose value)?  batchClose,TResult? Function( BuddyIntentPersonalFoodCreate value)?  personalFoodCreate,TResult? Function( BuddyIntentSavedMealLog value)?  savedMealLog,TResult? Function( BuddyIntentSavedMealCreate value)?  savedMealCreate,TResult? Function( BuddyIntentUnrecognized value)?  unrecognized,}){
final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that);case BuddyIntentClarify() when clarify != null:
return clarify(_that);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that);case BuddyIntentMedical() when medical != null:
return medical(_that);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that);case BuddyIntentDiaryEdit() when diaryEdit != null:
return diaryEdit(_that);case BuddyIntentDiaryDelete() when diaryDelete != null:
return diaryDelete(_that);case BuddyIntentAmbiguousReference() when ambiguousReference != null:
return ambiguousReference(_that);case BuddyIntentDiaryCopy() when diaryCopy != null:
return diaryCopy(_that);case BuddyIntentMemoryChange() when memoryChange != null:
return memoryChange(_that);case BuddyIntentBatch() when batch != null:
return batch(_that);case BuddyIntentBatchPortion() when batchPortion != null:
return batchPortion(_that);case BuddyIntentBatchClose() when batchClose != null:
return batchClose(_that);case BuddyIntentPersonalFoodCreate() when personalFoodCreate != null:
return personalFoodCreate(_that);case BuddyIntentSavedMealLog() when savedMealLog != null:
return savedMealLog(_that);case BuddyIntentSavedMealCreate() when savedMealCreate != null:
return savedMealCreate(_that);case BuddyIntentUnrecognized() when unrecognized != null:
return unrecognized(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dateHint,  String? dishGroup,  List<BuddyFoodItem> items)?  foodLog,TResult Function( BuddyClarifyKind kind,  String language,  String script,  String reason)?  clarify,TResult Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)?  outOfScope,TResult Function( BuddyMedicalKind kind,  String language,  String script)?  medical,TResult Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint,  String? dateHint)?  weighIn,TResult Function( BuddyDiaryEditKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference,  BuddyDiaryPatch patch)?  diaryEdit,TResult Function( BuddyDiaryDeleteKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference)?  diaryDelete,TResult Function( BuddyAmbiguousReferenceKind kind,  String language,  String script,  BuddyReferenceOperation operation,  List<String> candidates,  BuddyEntryReference reference,  BuddyDiaryPatch? patch)?  ambiguousReference,TResult Function( BuddyDiaryCopyKind kind,  String language,  String script,  BuddyDayHint source,  BuddyDayHint target)?  diaryCopy,TResult Function( BuddyMemoryChangeKind kind,  String language,  String script,  BuddyMemoryOperation operation,  BuddyMemoryKind memoryKind,  String? subject,  BuddyMemoryDimension? dimension,  String? value,  BuddyAmount? amount,  BuddyFoodItem? food)?  memoryChange,TResult Function( BuddyBatchKind kind,  String language,  String script,  String? name,  List<BuddyFoodItem> ingredients,  BuddyAmount? cookedWeight,  BuddyBatchPath? path,  BuddyPortion? eatenNow,  String? timeHint,  String? slotHint,  String? dateHint)?  batch,TResult Function( BuddyBatchPortionKind kind,  String language,  String script,  String batchId,  BuddyPortion? portion,  bool rest,  String? timeHint,  String? slotHint,  String? dateHint)?  batchPortion,TResult Function( BuddyBatchCloseKind kind,  String language,  String script,  String batchId)?  batchClose,TResult Function( BuddyPersonalFoodCreateKind kind,  String language,  String script,  String name,  List<String> aliases,  List<BuddyFoodItem> components,  BuddyStatedNutrients? stated)?  personalFoodCreate,TResult Function( BuddySavedMealLogKind kind,  String language,  String script,  String savedMealId,  String? timeHint,  String? slotHint,  String? dateHint,  BuddyShare? share)?  savedMealLog,TResult Function( BuddySavedMealCreateKind kind,  String language,  String script,  String name,  String? activeProposal,  List<String> targets,  BuddyDayHint? source)?  savedMealCreate,TResult Function()?  unrecognized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dateHint,_that.dishGroup,_that.items);case BuddyIntentClarify() when clarify != null:
return clarify(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentMedical() when medical != null:
return medical(_that.kind,_that.language,_that.script);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint,_that.dateHint);case BuddyIntentDiaryEdit() when diaryEdit != null:
return diaryEdit(_that.kind,_that.language,_that.script,_that.targets,_that.reference,_that.patch);case BuddyIntentDiaryDelete() when diaryDelete != null:
return diaryDelete(_that.kind,_that.language,_that.script,_that.targets,_that.reference);case BuddyIntentAmbiguousReference() when ambiguousReference != null:
return ambiguousReference(_that.kind,_that.language,_that.script,_that.operation,_that.candidates,_that.reference,_that.patch);case BuddyIntentDiaryCopy() when diaryCopy != null:
return diaryCopy(_that.kind,_that.language,_that.script,_that.source,_that.target);case BuddyIntentMemoryChange() when memoryChange != null:
return memoryChange(_that.kind,_that.language,_that.script,_that.operation,_that.memoryKind,_that.subject,_that.dimension,_that.value,_that.amount,_that.food);case BuddyIntentBatch() when batch != null:
return batch(_that.kind,_that.language,_that.script,_that.name,_that.ingredients,_that.cookedWeight,_that.path,_that.eatenNow,_that.timeHint,_that.slotHint,_that.dateHint);case BuddyIntentBatchPortion() when batchPortion != null:
return batchPortion(_that.kind,_that.language,_that.script,_that.batchId,_that.portion,_that.rest,_that.timeHint,_that.slotHint,_that.dateHint);case BuddyIntentBatchClose() when batchClose != null:
return batchClose(_that.kind,_that.language,_that.script,_that.batchId);case BuddyIntentPersonalFoodCreate() when personalFoodCreate != null:
return personalFoodCreate(_that.kind,_that.language,_that.script,_that.name,_that.aliases,_that.components,_that.stated);case BuddyIntentSavedMealLog() when savedMealLog != null:
return savedMealLog(_that.kind,_that.language,_that.script,_that.savedMealId,_that.timeHint,_that.slotHint,_that.dateHint,_that.share);case BuddyIntentSavedMealCreate() when savedMealCreate != null:
return savedMealCreate(_that.kind,_that.language,_that.script,_that.name,_that.activeProposal,_that.targets,_that.source);case BuddyIntentUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dateHint,  String? dishGroup,  List<BuddyFoodItem> items)  foodLog,required TResult Function( BuddyClarifyKind kind,  String language,  String script,  String reason)  clarify,required TResult Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)  outOfScope,required TResult Function( BuddyMedicalKind kind,  String language,  String script)  medical,required TResult Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint,  String? dateHint)  weighIn,required TResult Function( BuddyDiaryEditKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference,  BuddyDiaryPatch patch)  diaryEdit,required TResult Function( BuddyDiaryDeleteKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference)  diaryDelete,required TResult Function( BuddyAmbiguousReferenceKind kind,  String language,  String script,  BuddyReferenceOperation operation,  List<String> candidates,  BuddyEntryReference reference,  BuddyDiaryPatch? patch)  ambiguousReference,required TResult Function( BuddyDiaryCopyKind kind,  String language,  String script,  BuddyDayHint source,  BuddyDayHint target)  diaryCopy,required TResult Function( BuddyMemoryChangeKind kind,  String language,  String script,  BuddyMemoryOperation operation,  BuddyMemoryKind memoryKind,  String? subject,  BuddyMemoryDimension? dimension,  String? value,  BuddyAmount? amount,  BuddyFoodItem? food)  memoryChange,required TResult Function( BuddyBatchKind kind,  String language,  String script,  String? name,  List<BuddyFoodItem> ingredients,  BuddyAmount? cookedWeight,  BuddyBatchPath? path,  BuddyPortion? eatenNow,  String? timeHint,  String? slotHint,  String? dateHint)  batch,required TResult Function( BuddyBatchPortionKind kind,  String language,  String script,  String batchId,  BuddyPortion? portion,  bool rest,  String? timeHint,  String? slotHint,  String? dateHint)  batchPortion,required TResult Function( BuddyBatchCloseKind kind,  String language,  String script,  String batchId)  batchClose,required TResult Function( BuddyPersonalFoodCreateKind kind,  String language,  String script,  String name,  List<String> aliases,  List<BuddyFoodItem> components,  BuddyStatedNutrients? stated)  personalFoodCreate,required TResult Function( BuddySavedMealLogKind kind,  String language,  String script,  String savedMealId,  String? timeHint,  String? slotHint,  String? dateHint,  BuddyShare? share)  savedMealLog,required TResult Function( BuddySavedMealCreateKind kind,  String language,  String script,  String name,  String? activeProposal,  List<String> targets,  BuddyDayHint? source)  savedMealCreate,required TResult Function()  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyIntentFoodLog():
return foodLog(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dateHint,_that.dishGroup,_that.items);case BuddyIntentClarify():
return clarify(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentOutOfScope():
return outOfScope(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentMedical():
return medical(_that.kind,_that.language,_that.script);case BuddyIntentWeighIn():
return weighIn(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint,_that.dateHint);case BuddyIntentDiaryEdit():
return diaryEdit(_that.kind,_that.language,_that.script,_that.targets,_that.reference,_that.patch);case BuddyIntentDiaryDelete():
return diaryDelete(_that.kind,_that.language,_that.script,_that.targets,_that.reference);case BuddyIntentAmbiguousReference():
return ambiguousReference(_that.kind,_that.language,_that.script,_that.operation,_that.candidates,_that.reference,_that.patch);case BuddyIntentDiaryCopy():
return diaryCopy(_that.kind,_that.language,_that.script,_that.source,_that.target);case BuddyIntentMemoryChange():
return memoryChange(_that.kind,_that.language,_that.script,_that.operation,_that.memoryKind,_that.subject,_that.dimension,_that.value,_that.amount,_that.food);case BuddyIntentBatch():
return batch(_that.kind,_that.language,_that.script,_that.name,_that.ingredients,_that.cookedWeight,_that.path,_that.eatenNow,_that.timeHint,_that.slotHint,_that.dateHint);case BuddyIntentBatchPortion():
return batchPortion(_that.kind,_that.language,_that.script,_that.batchId,_that.portion,_that.rest,_that.timeHint,_that.slotHint,_that.dateHint);case BuddyIntentBatchClose():
return batchClose(_that.kind,_that.language,_that.script,_that.batchId);case BuddyIntentPersonalFoodCreate():
return personalFoodCreate(_that.kind,_that.language,_that.script,_that.name,_that.aliases,_that.components,_that.stated);case BuddyIntentSavedMealLog():
return savedMealLog(_that.kind,_that.language,_that.script,_that.savedMealId,_that.timeHint,_that.slotHint,_that.dateHint,_that.share);case BuddyIntentSavedMealCreate():
return savedMealCreate(_that.kind,_that.language,_that.script,_that.name,_that.activeProposal,_that.targets,_that.source);case BuddyIntentUnrecognized():
return unrecognized();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BuddyFoodLogKind kind,  String language,  String script,  String? timeHint,  String? slotHint,  String? dateHint,  String? dishGroup,  List<BuddyFoodItem> items)?  foodLog,TResult? Function( BuddyClarifyKind kind,  String language,  String script,  String reason)?  clarify,TResult? Function( BuddyOutOfScopeKind kind,  String language,  String script,  String reason)?  outOfScope,TResult? Function( BuddyMedicalKind kind,  String language,  String script)?  medical,TResult? Function( BuddyWeighInKind kind,  String language,  String script,  double value,  String unit,  String? timeHint,  String? dateHint)?  weighIn,TResult? Function( BuddyDiaryEditKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference,  BuddyDiaryPatch patch)?  diaryEdit,TResult? Function( BuddyDiaryDeleteKind kind,  String language,  String script,  List<String> targets,  BuddyEntryReference reference)?  diaryDelete,TResult? Function( BuddyAmbiguousReferenceKind kind,  String language,  String script,  BuddyReferenceOperation operation,  List<String> candidates,  BuddyEntryReference reference,  BuddyDiaryPatch? patch)?  ambiguousReference,TResult? Function( BuddyDiaryCopyKind kind,  String language,  String script,  BuddyDayHint source,  BuddyDayHint target)?  diaryCopy,TResult? Function( BuddyMemoryChangeKind kind,  String language,  String script,  BuddyMemoryOperation operation,  BuddyMemoryKind memoryKind,  String? subject,  BuddyMemoryDimension? dimension,  String? value,  BuddyAmount? amount,  BuddyFoodItem? food)?  memoryChange,TResult? Function( BuddyBatchKind kind,  String language,  String script,  String? name,  List<BuddyFoodItem> ingredients,  BuddyAmount? cookedWeight,  BuddyBatchPath? path,  BuddyPortion? eatenNow,  String? timeHint,  String? slotHint,  String? dateHint)?  batch,TResult? Function( BuddyBatchPortionKind kind,  String language,  String script,  String batchId,  BuddyPortion? portion,  bool rest,  String? timeHint,  String? slotHint,  String? dateHint)?  batchPortion,TResult? Function( BuddyBatchCloseKind kind,  String language,  String script,  String batchId)?  batchClose,TResult? Function( BuddyPersonalFoodCreateKind kind,  String language,  String script,  String name,  List<String> aliases,  List<BuddyFoodItem> components,  BuddyStatedNutrients? stated)?  personalFoodCreate,TResult? Function( BuddySavedMealLogKind kind,  String language,  String script,  String savedMealId,  String? timeHint,  String? slotHint,  String? dateHint,  BuddyShare? share)?  savedMealLog,TResult? Function( BuddySavedMealCreateKind kind,  String language,  String script,  String name,  String? activeProposal,  List<String> targets,  BuddyDayHint? source)?  savedMealCreate,TResult? Function()?  unrecognized,}) {final _that = this;
switch (_that) {
case BuddyIntentFoodLog() when foodLog != null:
return foodLog(_that.kind,_that.language,_that.script,_that.timeHint,_that.slotHint,_that.dateHint,_that.dishGroup,_that.items);case BuddyIntentClarify() when clarify != null:
return clarify(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentOutOfScope() when outOfScope != null:
return outOfScope(_that.kind,_that.language,_that.script,_that.reason);case BuddyIntentMedical() when medical != null:
return medical(_that.kind,_that.language,_that.script);case BuddyIntentWeighIn() when weighIn != null:
return weighIn(_that.kind,_that.language,_that.script,_that.value,_that.unit,_that.timeHint,_that.dateHint);case BuddyIntentDiaryEdit() when diaryEdit != null:
return diaryEdit(_that.kind,_that.language,_that.script,_that.targets,_that.reference,_that.patch);case BuddyIntentDiaryDelete() when diaryDelete != null:
return diaryDelete(_that.kind,_that.language,_that.script,_that.targets,_that.reference);case BuddyIntentAmbiguousReference() when ambiguousReference != null:
return ambiguousReference(_that.kind,_that.language,_that.script,_that.operation,_that.candidates,_that.reference,_that.patch);case BuddyIntentDiaryCopy() when diaryCopy != null:
return diaryCopy(_that.kind,_that.language,_that.script,_that.source,_that.target);case BuddyIntentMemoryChange() when memoryChange != null:
return memoryChange(_that.kind,_that.language,_that.script,_that.operation,_that.memoryKind,_that.subject,_that.dimension,_that.value,_that.amount,_that.food);case BuddyIntentBatch() when batch != null:
return batch(_that.kind,_that.language,_that.script,_that.name,_that.ingredients,_that.cookedWeight,_that.path,_that.eatenNow,_that.timeHint,_that.slotHint,_that.dateHint);case BuddyIntentBatchPortion() when batchPortion != null:
return batchPortion(_that.kind,_that.language,_that.script,_that.batchId,_that.portion,_that.rest,_that.timeHint,_that.slotHint,_that.dateHint);case BuddyIntentBatchClose() when batchClose != null:
return batchClose(_that.kind,_that.language,_that.script,_that.batchId);case BuddyIntentPersonalFoodCreate() when personalFoodCreate != null:
return personalFoodCreate(_that.kind,_that.language,_that.script,_that.name,_that.aliases,_that.components,_that.stated);case BuddyIntentSavedMealLog() when savedMealLog != null:
return savedMealLog(_that.kind,_that.language,_that.script,_that.savedMealId,_that.timeHint,_that.slotHint,_that.dateHint,_that.share);case BuddyIntentSavedMealCreate() when savedMealCreate != null:
return savedMealCreate(_that.kind,_that.language,_that.script,_that.name,_that.activeProposal,_that.targets,_that.source);case BuddyIntentUnrecognized() when unrecognized != null:
return unrecognized();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BuddyIntentFoodLog implements BuddyIntent {
  const BuddyIntentFoodLog({required this.kind, required this.language, required this.script, required this.timeHint, required this.slotHint, required this.dateHint, required this.dishGroup, required  List<BuddyFoodItem> items}): _items = items;
  factory BuddyIntentFoodLog.fromJson(Map<String, dynamic> json) => _$BuddyIntentFoodLogFromJson(json);

 final  BuddyFoodLogKind kind;
 final  String language;
 final  String script;
/// Literal time phrase as the user said it (B08); the app resolves it.
 final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 final  String? dateHint;
 final  String? dishGroup;
 final  List<BuddyFoodItem> _items;
 List<BuddyFoodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentFoodLogCopyWith<BuddyIntentFoodLog> get copyWith => _$BuddyIntentFoodLogCopyWithImpl<BuddyIntentFoodLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentFoodLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentFoodLog&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.dishGroup, dishGroup) || other.dishGroup == dishGroup)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,timeHint,slotHint,dateHint,dishGroup,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'BuddyIntent.foodLog(kind: $kind, language: $language, script: $script, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint, dishGroup: $dishGroup, items: $items)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentFoodLogCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentFoodLogCopyWith(BuddyIntentFoodLog value, $Res Function(BuddyIntentFoodLog) _then) = _$BuddyIntentFoodLogCopyWithImpl;
@useResult
$Res call({
 BuddyFoodLogKind kind, String language, String script, String? timeHint, String? slotHint, String? dateHint, String? dishGroup, List<BuddyFoodItem> items
});




}
/// @nodoc
class _$BuddyIntentFoodLogCopyWithImpl<$Res>
    implements $BuddyIntentFoodLogCopyWith<$Res> {
  _$BuddyIntentFoodLogCopyWithImpl(this._self, this._then);

  final BuddyIntentFoodLog _self;
  final $Res Function(BuddyIntentFoodLog) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,Object? dishGroup = freezed,Object? items = null,}) {
  return _then(BuddyIntentFoodLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyFoodLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,dishGroup: freezed == dishGroup ? _self.dishGroup : dishGroup // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentClarify implements BuddyIntent {
  const BuddyIntentClarify({required this.kind, required this.language, required this.script, required this.reason});
  factory BuddyIntentClarify.fromJson(Map<String, dynamic> json) => _$BuddyIntentClarifyFromJson(json);

 final  BuddyClarifyKind kind;
 final  String language;
 final  String script;
 final  String reason;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentClarifyCopyWith<BuddyIntentClarify> get copyWith => _$BuddyIntentClarifyCopyWithImpl<BuddyIntentClarify>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentClarifyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentClarify&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,reason);
}

@override
String toString() {
    return 'BuddyIntent.clarify(kind: $kind, language: $language, script: $script, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentClarifyCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentClarifyCopyWith(BuddyIntentClarify value, $Res Function(BuddyIntentClarify) _then) = _$BuddyIntentClarifyCopyWithImpl;
@useResult
$Res call({
 BuddyClarifyKind kind, String language, String script, String reason
});




}
/// @nodoc
class _$BuddyIntentClarifyCopyWithImpl<$Res>
    implements $BuddyIntentClarifyCopyWith<$Res> {
  _$BuddyIntentClarifyCopyWithImpl(this._self, this._then);

  final BuddyIntentClarify _self;
  final $Res Function(BuddyIntentClarify) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(BuddyIntentClarify(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyClarifyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentOutOfScope implements BuddyIntent {
  const BuddyIntentOutOfScope({required this.kind, required this.language, required this.script, required this.reason});
  factory BuddyIntentOutOfScope.fromJson(Map<String, dynamic> json) => _$BuddyIntentOutOfScopeFromJson(json);

 final  BuddyOutOfScopeKind kind;
 final  String language;
 final  String script;
 final  String reason;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentOutOfScopeCopyWith<BuddyIntentOutOfScope> get copyWith => _$BuddyIntentOutOfScopeCopyWithImpl<BuddyIntentOutOfScope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentOutOfScopeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentOutOfScope&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,reason);
}

@override
String toString() {
    return 'BuddyIntent.outOfScope(kind: $kind, language: $language, script: $script, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentOutOfScopeCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentOutOfScopeCopyWith(BuddyIntentOutOfScope value, $Res Function(BuddyIntentOutOfScope) _then) = _$BuddyIntentOutOfScopeCopyWithImpl;
@useResult
$Res call({
 BuddyOutOfScopeKind kind, String language, String script, String reason
});




}
/// @nodoc
class _$BuddyIntentOutOfScopeCopyWithImpl<$Res>
    implements $BuddyIntentOutOfScopeCopyWith<$Res> {
  _$BuddyIntentOutOfScopeCopyWithImpl(this._self, this._then);

  final BuddyIntentOutOfScope _self;
  final $Res Function(BuddyIntentOutOfScope) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? reason = null,}) {
  return _then(BuddyIntentOutOfScope(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyOutOfScopeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentMedical implements BuddyIntent {
  const BuddyIntentMedical({required this.kind, required this.language, required this.script});
  factory BuddyIntentMedical.fromJson(Map<String, dynamic> json) => _$BuddyIntentMedicalFromJson(json);

 final  BuddyMedicalKind kind;
 final  String language;
 final  String script;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentMedicalCopyWith<BuddyIntentMedical> get copyWith => _$BuddyIntentMedicalCopyWithImpl<BuddyIntentMedical>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentMedicalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentMedical&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script);
}

@override
String toString() {
    return 'BuddyIntent.medical(kind: $kind, language: $language, script: $script)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentMedicalCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentMedicalCopyWith(BuddyIntentMedical value, $Res Function(BuddyIntentMedical) _then) = _$BuddyIntentMedicalCopyWithImpl;
@useResult
$Res call({
 BuddyMedicalKind kind, String language, String script
});




}
/// @nodoc
class _$BuddyIntentMedicalCopyWithImpl<$Res>
    implements $BuddyIntentMedicalCopyWith<$Res> {
  _$BuddyIntentMedicalCopyWithImpl(this._self, this._then);

  final BuddyIntentMedical _self;
  final $Res Function(BuddyIntentMedical) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,}) {
  return _then(BuddyIntentMedical(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMedicalKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentWeighIn implements BuddyIntent {
  const BuddyIntentWeighIn({required this.kind, required this.language, required this.script, required this.value, required this.unit, required this.timeHint, required this.dateHint});
  factory BuddyIntentWeighIn.fromJson(Map<String, dynamic> json) => _$BuddyIntentWeighInFromJson(json);

 final  BuddyWeighInKind kind;
 final  String language;
 final  String script;
 final  double value;
 final  String unit;
/// Literal time phrase as the user said it (B08); the app resolves it.
 final  String? timeHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 final  String? dateHint;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentWeighInCopyWith<BuddyIntentWeighIn> get copyWith => _$BuddyIntentWeighInCopyWithImpl<BuddyIntentWeighIn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentWeighInToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentWeighIn&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,value,unit,timeHint,dateHint);
}

@override
String toString() {
    return 'BuddyIntent.weighIn(kind: $kind, language: $language, script: $script, value: $value, unit: $unit, timeHint: $timeHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentWeighInCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentWeighInCopyWith(BuddyIntentWeighIn value, $Res Function(BuddyIntentWeighIn) _then) = _$BuddyIntentWeighInCopyWithImpl;
@useResult
$Res call({
 BuddyWeighInKind kind, String language, String script, double value, String unit, String? timeHint, String? dateHint
});




}
/// @nodoc
class _$BuddyIntentWeighInCopyWithImpl<$Res>
    implements $BuddyIntentWeighInCopyWith<$Res> {
  _$BuddyIntentWeighInCopyWithImpl(this._self, this._then);

  final BuddyIntentWeighIn _self;
  final $Res Function(BuddyIntentWeighIn) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? value = null,Object? unit = null,Object? timeHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyIntentWeighIn(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyWeighInKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentDiaryEdit implements BuddyIntent {
  const BuddyIntentDiaryEdit({required this.kind, required this.language, required this.script, required  List<String> targets, required this.reference, required this.patch}): _targets = targets;
  factory BuddyIntentDiaryEdit.fromJson(Map<String, dynamic> json) => _$BuddyIntentDiaryEditFromJson(json);

 final  BuddyDiaryEditKind kind;
 final  String language;
 final  String script;
/// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
 final  List<String> _targets;
/// Request recentEntries IDs to change. Empty: the app looks the entries up from reference's day/slot hints and asks.
 List<String> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

 final  BuddyEntryReference reference;
 final  BuddyDiaryPatch patch;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentDiaryEditCopyWith<BuddyIntentDiaryEdit> get copyWith => _$BuddyIntentDiaryEditCopyWithImpl<BuddyIntentDiaryEdit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentDiaryEditToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentDiaryEdit&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&const DeepCollectionEquality().equals(other.targets, _targets)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.patch, patch) || other.patch == patch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,const DeepCollectionEquality().hash(_targets),reference,patch);
}

@override
String toString() {
    return 'BuddyIntent.diaryEdit(kind: $kind, language: $language, script: $script, targets: $targets, reference: $reference, patch: $patch)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentDiaryEditCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentDiaryEditCopyWith(BuddyIntentDiaryEdit value, $Res Function(BuddyIntentDiaryEdit) _then) = _$BuddyIntentDiaryEditCopyWithImpl;
@useResult
$Res call({
 BuddyDiaryEditKind kind, String language, String script, List<String> targets, BuddyEntryReference reference, BuddyDiaryPatch patch
});


$BuddyEntryReferenceCopyWith<$Res> get reference;$BuddyDiaryPatchCopyWith<$Res> get patch;

}
/// @nodoc
class _$BuddyIntentDiaryEditCopyWithImpl<$Res>
    implements $BuddyIntentDiaryEditCopyWith<$Res> {
  _$BuddyIntentDiaryEditCopyWithImpl(this._self, this._then);

  final BuddyIntentDiaryEdit _self;
  final $Res Function(BuddyIntentDiaryEdit) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? targets = null,Object? reference = null,Object? patch = null,}) {
  return _then(BuddyIntentDiaryEdit(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryEditKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as BuddyDiaryPatch,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<$Res> get patch {
  
  return $BuddyDiaryPatchCopyWith<$Res>(_self.patch, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentDiaryDelete implements BuddyIntent {
  const BuddyIntentDiaryDelete({required this.kind, required this.language, required this.script, required  List<String> targets, required this.reference}): _targets = targets;
  factory BuddyIntentDiaryDelete.fromJson(Map<String, dynamic> json) => _$BuddyIntentDiaryDeleteFromJson(json);

 final  BuddyDiaryDeleteKind kind;
 final  String language;
 final  String script;
/// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
 final  List<String> _targets;
/// Request recentEntries IDs to delete. Empty: the app looks the entries up from reference's day/slot hints and asks.
 List<String> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

 final  BuddyEntryReference reference;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentDiaryDeleteCopyWith<BuddyIntentDiaryDelete> get copyWith => _$BuddyIntentDiaryDeleteCopyWithImpl<BuddyIntentDiaryDelete>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentDiaryDeleteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentDiaryDelete&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&const DeepCollectionEquality().equals(other.targets, _targets)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,const DeepCollectionEquality().hash(_targets),reference);
}

@override
String toString() {
    return 'BuddyIntent.diaryDelete(kind: $kind, language: $language, script: $script, targets: $targets, reference: $reference)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentDiaryDeleteCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentDiaryDeleteCopyWith(BuddyIntentDiaryDelete value, $Res Function(BuddyIntentDiaryDelete) _then) = _$BuddyIntentDiaryDeleteCopyWithImpl;
@useResult
$Res call({
 BuddyDiaryDeleteKind kind, String language, String script, List<String> targets, BuddyEntryReference reference
});


$BuddyEntryReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class _$BuddyIntentDiaryDeleteCopyWithImpl<$Res>
    implements $BuddyIntentDiaryDeleteCopyWith<$Res> {
  _$BuddyIntentDiaryDeleteCopyWithImpl(this._self, this._then);

  final BuddyIntentDiaryDelete _self;
  final $Res Function(BuddyIntentDiaryDelete) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? targets = null,Object? reference = null,}) {
  return _then(BuddyIntentDiaryDelete(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryDeleteKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentAmbiguousReference implements BuddyIntent {
  const BuddyIntentAmbiguousReference({required this.kind, required this.language, required this.script, required this.operation, required  List<String> candidates, required this.reference, required this.patch}): _candidates = candidates;
  factory BuddyIntentAmbiguousReference.fromJson(Map<String, dynamic> json) => _$BuddyIntentAmbiguousReferenceFromJson(json);

 final  BuddyAmbiguousReferenceKind kind;
 final  String language;
 final  String script;
 final  BuddyReferenceOperation operation;
/// Request recentEntries IDs the message could mean; the app asks which (AI-091).
 final  List<String> _candidates;
/// Request recentEntries IDs the message could mean; the app asks which (AI-091).
 List<String> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}

 final  BuddyEntryReference reference;
/// The edit to apply to the chosen entry; null for delete.
 final  BuddyDiaryPatch? patch;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentAmbiguousReferenceCopyWith<BuddyIntentAmbiguousReference> get copyWith => _$BuddyIntentAmbiguousReferenceCopyWithImpl<BuddyIntentAmbiguousReference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentAmbiguousReferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentAmbiguousReference&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.operation, operation) || other.operation == operation)&&const DeepCollectionEquality().equals(other.candidates, _candidates)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.patch, patch) || other.patch == patch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,operation,const DeepCollectionEquality().hash(_candidates),reference,patch);
}

@override
String toString() {
    return 'BuddyIntent.ambiguousReference(kind: $kind, language: $language, script: $script, operation: $operation, candidates: $candidates, reference: $reference, patch: $patch)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentAmbiguousReferenceCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentAmbiguousReferenceCopyWith(BuddyIntentAmbiguousReference value, $Res Function(BuddyIntentAmbiguousReference) _then) = _$BuddyIntentAmbiguousReferenceCopyWithImpl;
@useResult
$Res call({
 BuddyAmbiguousReferenceKind kind, String language, String script, BuddyReferenceOperation operation, List<String> candidates, BuddyEntryReference reference, BuddyDiaryPatch? patch
});


$BuddyEntryReferenceCopyWith<$Res> get reference;$BuddyDiaryPatchCopyWith<$Res>? get patch;

}
/// @nodoc
class _$BuddyIntentAmbiguousReferenceCopyWithImpl<$Res>
    implements $BuddyIntentAmbiguousReferenceCopyWith<$Res> {
  _$BuddyIntentAmbiguousReferenceCopyWithImpl(this._self, this._then);

  final BuddyIntentAmbiguousReference _self;
  final $Res Function(BuddyIntentAmbiguousReference) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? operation = null,Object? candidates = null,Object? reference = null,Object? patch = freezed,}) {
  return _then(BuddyIntentAmbiguousReference(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyAmbiguousReferenceKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyReferenceOperation,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<String>,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as BuddyEntryReference,patch: freezed == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as BuddyDiaryPatch?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyEntryReferenceCopyWith<$Res> get reference {
  
  return $BuddyEntryReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDiaryPatchCopyWith<$Res>? get patch {
    if (_self.patch == null) {
    return null;
  }

  return $BuddyDiaryPatchCopyWith<$Res>(_self.patch!, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentDiaryCopy implements BuddyIntent {
  const BuddyIntentDiaryCopy({required this.kind, required this.language, required this.script, required this.source, required this.target});
  factory BuddyIntentDiaryCopy.fromJson(Map<String, dynamic> json) => _$BuddyIntentDiaryCopyFromJson(json);

 final  BuddyDiaryCopyKind kind;
 final  String language;
 final  String script;
/// Where to copy from.
 final  BuddyDayHint source;
/// Where to copy to.
 final  BuddyDayHint target;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentDiaryCopyCopyWith<BuddyIntentDiaryCopy> get copyWith => _$BuddyIntentDiaryCopyCopyWithImpl<BuddyIntentDiaryCopy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentDiaryCopyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentDiaryCopy&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.source, source) || other.source == source)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,source,target);
}

@override
String toString() {
    return 'BuddyIntent.diaryCopy(kind: $kind, language: $language, script: $script, source: $source, target: $target)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentDiaryCopyCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentDiaryCopyCopyWith(BuddyIntentDiaryCopy value, $Res Function(BuddyIntentDiaryCopy) _then) = _$BuddyIntentDiaryCopyCopyWithImpl;
@useResult
$Res call({
 BuddyDiaryCopyKind kind, String language, String script, BuddyDayHint source, BuddyDayHint target
});


$BuddyDayHintCopyWith<$Res> get source;$BuddyDayHintCopyWith<$Res> get target;

}
/// @nodoc
class _$BuddyIntentDiaryCopyCopyWithImpl<$Res>
    implements $BuddyIntentDiaryCopyCopyWith<$Res> {
  _$BuddyIntentDiaryCopyCopyWithImpl(this._self, this._then);

  final BuddyIntentDiaryCopy _self;
  final $Res Function(BuddyIntentDiaryCopy) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? source = null,Object? target = null,}) {
  return _then(BuddyIntentDiaryCopy(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyDiaryCopyKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BuddyDayHint,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BuddyDayHint,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res> get source {
  
  return $BuddyDayHintCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res> get target {
  
  return $BuddyDayHintCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentMemoryChange implements BuddyIntent {
  const BuddyIntentMemoryChange({required this.kind, required this.language, required this.script, required this.operation, required this.memoryKind, required this.subject, required this.dimension, required this.value, required this.amount, required this.food});
  factory BuddyIntentMemoryChange.fromJson(Map<String, dynamic> json) => _$BuddyIntentMemoryChangeFromJson(json);

 final  BuddyMemoryChangeKind kind;
 final  String language;
 final  String script;
 final  BuddyMemoryOperation operation;
 final  BuddyMemoryKind memoryKind;
/// The food or name the statement is about, as the user said it.
 final  String? subject;
 final  BuddyMemoryDimension? dimension;
/// Closed for state (raw, cooked, dry, drained, fried) and fat (none, oil); literal otherwise (alias, brand, nickname, variant).
 final  String? value;
/// The portion, or the fat quantity. Authoritative; food.amount is ignored.
 final  BuddyAmount? amount;
/// The subject food when it matches a real food; never an estimate.
 final  BuddyFoodItem? food;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentMemoryChangeCopyWith<BuddyIntentMemoryChange> get copyWith => _$BuddyIntentMemoryChangeCopyWithImpl<BuddyIntentMemoryChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentMemoryChangeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentMemoryChange&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.memoryKind, memoryKind) || other.memoryKind == memoryKind)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.value, value) || other.value == value)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.food, food) || other.food == food));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,operation,memoryKind,subject,dimension,value,amount,food);
}

@override
String toString() {
    return 'BuddyIntent.memoryChange(kind: $kind, language: $language, script: $script, operation: $operation, memoryKind: $memoryKind, subject: $subject, dimension: $dimension, value: $value, amount: $amount, food: $food)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentMemoryChangeCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentMemoryChangeCopyWith(BuddyIntentMemoryChange value, $Res Function(BuddyIntentMemoryChange) _then) = _$BuddyIntentMemoryChangeCopyWithImpl;
@useResult
$Res call({
 BuddyMemoryChangeKind kind, String language, String script, BuddyMemoryOperation operation, BuddyMemoryKind memoryKind, String? subject, BuddyMemoryDimension? dimension, String? value, BuddyAmount? amount, BuddyFoodItem? food
});


$BuddyAmountCopyWith<$Res>? get amount;$BuddyFoodItemCopyWith<$Res>? get food;

}
/// @nodoc
class _$BuddyIntentMemoryChangeCopyWithImpl<$Res>
    implements $BuddyIntentMemoryChangeCopyWith<$Res> {
  _$BuddyIntentMemoryChangeCopyWithImpl(this._self, this._then);

  final BuddyIntentMemoryChange _self;
  final $Res Function(BuddyIntentMemoryChange) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? operation = null,Object? memoryKind = null,Object? subject = freezed,Object? dimension = freezed,Object? value = freezed,Object? amount = freezed,Object? food = freezed,}) {
  return _then(BuddyIntentMemoryChange(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyMemoryChangeKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as BuddyMemoryOperation,memoryKind: null == memoryKind ? _self.memoryKind : memoryKind // ignore: cast_nullable_to_non_nullable
as BuddyMemoryKind,subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,dimension: freezed == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as BuddyMemoryDimension?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,food: freezed == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as BuddyFoodItem?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $BuddyAmountCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyFoodItemCopyWith<$Res>? get food {
    if (_self.food == null) {
    return null;
  }

  return $BuddyFoodItemCopyWith<$Res>(_self.food!, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentBatch implements BuddyIntent {
  const BuddyIntentBatch({required this.kind, required this.language, required this.script, required this.name, required  List<BuddyFoodItem> ingredients, required this.cookedWeight, required this.path, required this.eatenNow, required this.timeHint, required this.slotHint, required this.dateHint}): _ingredients = ingredients;
  factory BuddyIntentBatch.fromJson(Map<String, dynamic> json) => _$BuddyIntentBatchFromJson(json);

 final  BuddyBatchKind kind;
 final  String language;
 final  String script;
 final  String? name;
/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 final  List<BuddyFoodItem> _ingredients;
/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 List<BuddyFoodItem> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

/// The cooked weight the user stated.
 final  BuddyAmount? cookedWeight;
 final  BuddyBatchPath? path;
/// The portion eaten now (AI-101).
 final  BuddyPortion? eatenNow;
/// Literal time phrase as the user said it (B08); the app resolves it.
 final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 final  String? dateHint;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentBatchCopyWith<BuddyIntentBatch> get copyWith => _$BuddyIntentBatchCopyWithImpl<BuddyIntentBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentBatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentBatch&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.ingredients, _ingredients)&&(identical(other.cookedWeight, cookedWeight) || other.cookedWeight == cookedWeight)&&(identical(other.path, path) || other.path == path)&&(identical(other.eatenNow, eatenNow) || other.eatenNow == eatenNow)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,name,const DeepCollectionEquality().hash(_ingredients),cookedWeight,path,eatenNow,timeHint,slotHint,dateHint);
}

@override
String toString() {
    return 'BuddyIntent.batch(kind: $kind, language: $language, script: $script, name: $name, ingredients: $ingredients, cookedWeight: $cookedWeight, path: $path, eatenNow: $eatenNow, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentBatchCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentBatchCopyWith(BuddyIntentBatch value, $Res Function(BuddyIntentBatch) _then) = _$BuddyIntentBatchCopyWithImpl;
@useResult
$Res call({
 BuddyBatchKind kind, String language, String script, String? name, List<BuddyFoodItem> ingredients, BuddyAmount? cookedWeight, BuddyBatchPath? path, BuddyPortion? eatenNow, String? timeHint, String? slotHint, String? dateHint
});


$BuddyAmountCopyWith<$Res>? get cookedWeight;$BuddyPortionCopyWith<$Res>? get eatenNow;

}
/// @nodoc
class _$BuddyIntentBatchCopyWithImpl<$Res>
    implements $BuddyIntentBatchCopyWith<$Res> {
  _$BuddyIntentBatchCopyWithImpl(this._self, this._then);

  final BuddyIntentBatch _self;
  final $Res Function(BuddyIntentBatch) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = freezed,Object? ingredients = null,Object? cookedWeight = freezed,Object? path = freezed,Object? eatenNow = freezed,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyIntentBatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,cookedWeight: freezed == cookedWeight ? _self.cookedWeight : cookedWeight // ignore: cast_nullable_to_non_nullable
as BuddyAmount?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as BuddyBatchPath?,eatenNow: freezed == eatenNow ? _self.eatenNow : eatenNow // ignore: cast_nullable_to_non_nullable
as BuddyPortion?,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyAmountCopyWith<$Res>? get cookedWeight {
    if (_self.cookedWeight == null) {
    return null;
  }

  return $BuddyAmountCopyWith<$Res>(_self.cookedWeight!, (value) {
    return _then(_self.copyWith(cookedWeight: value));
  });
}/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<$Res>? get eatenNow {
    if (_self.eatenNow == null) {
    return null;
  }

  return $BuddyPortionCopyWith<$Res>(_self.eatenNow!, (value) {
    return _then(_self.copyWith(eatenNow: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentBatchPortion implements BuddyIntent {
  const BuddyIntentBatchPortion({required this.kind, required this.language, required this.script, required this.batchId, required this.portion, required this.rest, required this.timeHint, required this.slotHint, required this.dateHint});
  factory BuddyIntentBatchPortion.fromJson(Map<String, dynamic> json) => _$BuddyIntentBatchPortionFromJson(json);

 final  BuddyBatchPortionKind kind;
 final  String language;
 final  String script;
/// A request openBatches ID.
 final  String batchId;
/// The portion eaten; null when rest is true.
 final  BuddyPortion? portion;
/// The user ate the rest of the batch.
 final  bool rest;
/// Literal time phrase as the user said it (B08); the app resolves it.
 final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 final  String? dateHint;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentBatchPortionCopyWith<BuddyIntentBatchPortion> get copyWith => _$BuddyIntentBatchPortionCopyWithImpl<BuddyIntentBatchPortion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentBatchPortionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentBatchPortion&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.portion, portion) || other.portion == portion)&&(identical(other.rest, rest) || other.rest == rest)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,batchId,portion,rest,timeHint,slotHint,dateHint);
}

@override
String toString() {
    return 'BuddyIntent.batchPortion(kind: $kind, language: $language, script: $script, batchId: $batchId, portion: $portion, rest: $rest, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentBatchPortionCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentBatchPortionCopyWith(BuddyIntentBatchPortion value, $Res Function(BuddyIntentBatchPortion) _then) = _$BuddyIntentBatchPortionCopyWithImpl;
@useResult
$Res call({
 BuddyBatchPortionKind kind, String language, String script, String batchId, BuddyPortion? portion, bool rest, String? timeHint, String? slotHint, String? dateHint
});


$BuddyPortionCopyWith<$Res>? get portion;

}
/// @nodoc
class _$BuddyIntentBatchPortionCopyWithImpl<$Res>
    implements $BuddyIntentBatchPortionCopyWith<$Res> {
  _$BuddyIntentBatchPortionCopyWithImpl(this._self, this._then);

  final BuddyIntentBatchPortion _self;
  final $Res Function(BuddyIntentBatchPortion) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? batchId = null,Object? portion = freezed,Object? rest = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,}) {
  return _then(BuddyIntentBatchPortion(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchPortionKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,portion: freezed == portion ? _self.portion : portion // ignore: cast_nullable_to_non_nullable
as BuddyPortion?,rest: null == rest ? _self.rest : rest // ignore: cast_nullable_to_non_nullable
as bool,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyPortionCopyWith<$Res>? get portion {
    if (_self.portion == null) {
    return null;
  }

  return $BuddyPortionCopyWith<$Res>(_self.portion!, (value) {
    return _then(_self.copyWith(portion: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentBatchClose implements BuddyIntent {
  const BuddyIntentBatchClose({required this.kind, required this.language, required this.script, required this.batchId});
  factory BuddyIntentBatchClose.fromJson(Map<String, dynamic> json) => _$BuddyIntentBatchCloseFromJson(json);

 final  BuddyBatchCloseKind kind;
 final  String language;
 final  String script;
/// A request openBatches ID.
 final  String batchId;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentBatchCloseCopyWith<BuddyIntentBatchClose> get copyWith => _$BuddyIntentBatchCloseCopyWithImpl<BuddyIntentBatchClose>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentBatchCloseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentBatchClose&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.batchId, batchId) || other.batchId == batchId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,batchId);
}

@override
String toString() {
    return 'BuddyIntent.batchClose(kind: $kind, language: $language, script: $script, batchId: $batchId)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentBatchCloseCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentBatchCloseCopyWith(BuddyIntentBatchClose value, $Res Function(BuddyIntentBatchClose) _then) = _$BuddyIntentBatchCloseCopyWithImpl;
@useResult
$Res call({
 BuddyBatchCloseKind kind, String language, String script, String batchId
});




}
/// @nodoc
class _$BuddyIntentBatchCloseCopyWithImpl<$Res>
    implements $BuddyIntentBatchCloseCopyWith<$Res> {
  _$BuddyIntentBatchCloseCopyWithImpl(this._self, this._then);

  final BuddyIntentBatchClose _self;
  final $Res Function(BuddyIntentBatchClose) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? batchId = null,}) {
  return _then(BuddyIntentBatchClose(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyBatchCloseKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,batchId: null == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuddyIntentPersonalFoodCreate implements BuddyIntent {
  const BuddyIntentPersonalFoodCreate({required this.kind, required this.language, required this.script, required this.name, required  List<String> aliases, required  List<BuddyFoodItem> components, required this.stated}): _aliases = aliases,_components = components;
  factory BuddyIntentPersonalFoodCreate.fromJson(Map<String, dynamic> json) => _$BuddyIntentPersonalFoodCreateFromJson(json);

 final  BuddyPersonalFoodCreateKind kind;
 final  String language;
 final  String script;
 final  String name;
 final  List<String> _aliases;
 List<String> get aliases {
  if (_aliases is EqualUnmodifiableListView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aliases);
}

/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 final  List<BuddyFoodItem> _components;
/// An estimate inside it keeps its badge and is review-only (WP4 may restrict these to real matches, D10).
 List<BuddyFoodItem> get components {
  if (_components is EqualUnmodifiableListView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_components);
}

 final  BuddyStatedNutrients? stated;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentPersonalFoodCreateCopyWith<BuddyIntentPersonalFoodCreate> get copyWith => _$BuddyIntentPersonalFoodCreateCopyWithImpl<BuddyIntentPersonalFoodCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentPersonalFoodCreateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentPersonalFoodCreate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.aliases, _aliases)&&const DeepCollectionEquality().equals(other.components, _components)&&(identical(other.stated, stated) || other.stated == stated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,name,const DeepCollectionEquality().hash(_aliases),const DeepCollectionEquality().hash(_components),stated);
}

@override
String toString() {
    return 'BuddyIntent.personalFoodCreate(kind: $kind, language: $language, script: $script, name: $name, aliases: $aliases, components: $components, stated: $stated)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentPersonalFoodCreateCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentPersonalFoodCreateCopyWith(BuddyIntentPersonalFoodCreate value, $Res Function(BuddyIntentPersonalFoodCreate) _then) = _$BuddyIntentPersonalFoodCreateCopyWithImpl;
@useResult
$Res call({
 BuddyPersonalFoodCreateKind kind, String language, String script, String name, List<String> aliases, List<BuddyFoodItem> components, BuddyStatedNutrients? stated
});


$BuddyStatedNutrientsCopyWith<$Res>? get stated;

}
/// @nodoc
class _$BuddyIntentPersonalFoodCreateCopyWithImpl<$Res>
    implements $BuddyIntentPersonalFoodCreateCopyWith<$Res> {
  _$BuddyIntentPersonalFoodCreateCopyWithImpl(this._self, this._then);

  final BuddyIntentPersonalFoodCreate _self;
  final $Res Function(BuddyIntentPersonalFoodCreate) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = null,Object? aliases = null,Object? components = null,Object? stated = freezed,}) {
  return _then(BuddyIntentPersonalFoodCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddyPersonalFoodCreateKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as List<BuddyFoodItem>,stated: freezed == stated ? _self.stated : stated // ignore: cast_nullable_to_non_nullable
as BuddyStatedNutrients?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyStatedNutrientsCopyWith<$Res>? get stated {
    if (_self.stated == null) {
    return null;
  }

  return $BuddyStatedNutrientsCopyWith<$Res>(_self.stated!, (value) {
    return _then(_self.copyWith(stated: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentSavedMealLog implements BuddyIntent {
  const BuddyIntentSavedMealLog({required this.kind, required this.language, required this.script, required this.savedMealId, required this.timeHint, required this.slotHint, required this.dateHint, required this.share});
  factory BuddyIntentSavedMealLog.fromJson(Map<String, dynamic> json) => _$BuddyIntentSavedMealLogFromJson(json);

 final  BuddySavedMealLogKind kind;
 final  String language;
 final  String script;
/// A request savedMeals ID.
 final  String savedMealId;
/// Literal time phrase as the user said it (B08); the app resolves it.
 final  String? timeHint;
/// The exact provided slot name when one matches, else a canonical English slot word: breakfast, lunch, dinner, snack, suhoor, iftar. No match: null (no hint).
 final  String? slotHint;
/// Closed day grammar the app resolves locally: today, yesterday, daysAgo:N (N is 2-999; 0 and 1 are today and yesterday), lastWeekday:mon..sun (the most recent such day strictly before today), date:[YYYY-]MM-DD (a date the user stated). The server guarantees a valid month/day, and a valid calendar date when a year is given. A missing year is the most recent past occurrence (02-29 resolves up to 4 years back); the app rejects future dates. A value the app can't parse routes the intent as unrecognized.
 final  String? dateHint;
 final  BuddyShare? share;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentSavedMealLogCopyWith<BuddyIntentSavedMealLog> get copyWith => _$BuddyIntentSavedMealLogCopyWithImpl<BuddyIntentSavedMealLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentSavedMealLogToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentSavedMealLog&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.savedMealId, savedMealId) || other.savedMealId == savedMealId)&&(identical(other.timeHint, timeHint) || other.timeHint == timeHint)&&(identical(other.slotHint, slotHint) || other.slotHint == slotHint)&&(identical(other.dateHint, dateHint) || other.dateHint == dateHint)&&(identical(other.share, share) || other.share == share));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,savedMealId,timeHint,slotHint,dateHint,share);
}

@override
String toString() {
    return 'BuddyIntent.savedMealLog(kind: $kind, language: $language, script: $script, savedMealId: $savedMealId, timeHint: $timeHint, slotHint: $slotHint, dateHint: $dateHint, share: $share)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentSavedMealLogCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentSavedMealLogCopyWith(BuddyIntentSavedMealLog value, $Res Function(BuddyIntentSavedMealLog) _then) = _$BuddyIntentSavedMealLogCopyWithImpl;
@useResult
$Res call({
 BuddySavedMealLogKind kind, String language, String script, String savedMealId, String? timeHint, String? slotHint, String? dateHint, BuddyShare? share
});


$BuddyShareCopyWith<$Res>? get share;

}
/// @nodoc
class _$BuddyIntentSavedMealLogCopyWithImpl<$Res>
    implements $BuddyIntentSavedMealLogCopyWith<$Res> {
  _$BuddyIntentSavedMealLogCopyWithImpl(this._self, this._then);

  final BuddyIntentSavedMealLog _self;
  final $Res Function(BuddyIntentSavedMealLog) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? savedMealId = null,Object? timeHint = freezed,Object? slotHint = freezed,Object? dateHint = freezed,Object? share = freezed,}) {
  return _then(BuddyIntentSavedMealLog(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySavedMealLogKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,savedMealId: null == savedMealId ? _self.savedMealId : savedMealId // ignore: cast_nullable_to_non_nullable
as String,timeHint: freezed == timeHint ? _self.timeHint : timeHint // ignore: cast_nullable_to_non_nullable
as String?,slotHint: freezed == slotHint ? _self.slotHint : slotHint // ignore: cast_nullable_to_non_nullable
as String?,dateHint: freezed == dateHint ? _self.dateHint : dateHint // ignore: cast_nullable_to_non_nullable
as String?,share: freezed == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as BuddyShare?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyShareCopyWith<$Res>? get share {
    if (_self.share == null) {
    return null;
  }

  return $BuddyShareCopyWith<$Res>(_self.share!, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentSavedMealCreate implements BuddyIntent {
  const BuddyIntentSavedMealCreate({required this.kind, required this.language, required this.script, required this.name, required this.activeProposal, required  List<String> targets, required this.source}): _targets = targets;
  factory BuddyIntentSavedMealCreate.fromJson(Map<String, dynamic> json) => _$BuddyIntentSavedMealCreateFromJson(json);

 final  BuddySavedMealCreateKind kind;
 final  String language;
 final  String script;
/// Never null: a nameless "save this" is clarified.
 final  String name;
/// The request activeProposal ("save this").
 final  String? activeProposal;
/// Request recentEntries IDs to save.
 final  List<String> _targets;
/// Request recentEntries IDs to save.
 List<String> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

/// Day/slot to save from, for the app's local lookup.
 final  BuddyDayHint? source;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuddyIntentSavedMealCreateCopyWith<BuddyIntentSavedMealCreate> get copyWith => _$BuddyIntentSavedMealCreateCopyWithImpl<BuddyIntentSavedMealCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentSavedMealCreateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentSavedMealCreate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.language, language) || other.language == language)&&(identical(other.script, script) || other.script == script)&&(identical(other.name, name) || other.name == name)&&(identical(other.activeProposal, activeProposal) || other.activeProposal == activeProposal)&&const DeepCollectionEquality().equals(other.targets, _targets)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,language,script,name,activeProposal,const DeepCollectionEquality().hash(_targets),source);
}

@override
String toString() {
    return 'BuddyIntent.savedMealCreate(kind: $kind, language: $language, script: $script, name: $name, activeProposal: $activeProposal, targets: $targets, source: $source)';
}


}

/// @nodoc
abstract mixin class $BuddyIntentSavedMealCreateCopyWith<$Res> implements $BuddyIntentCopyWith<$Res> {
  factory $BuddyIntentSavedMealCreateCopyWith(BuddyIntentSavedMealCreate value, $Res Function(BuddyIntentSavedMealCreate) _then) = _$BuddyIntentSavedMealCreateCopyWithImpl;
@useResult
$Res call({
 BuddySavedMealCreateKind kind, String language, String script, String name, String? activeProposal, List<String> targets, BuddyDayHint? source
});


$BuddyDayHintCopyWith<$Res>? get source;

}
/// @nodoc
class _$BuddyIntentSavedMealCreateCopyWithImpl<$Res>
    implements $BuddyIntentSavedMealCreateCopyWith<$Res> {
  _$BuddyIntentSavedMealCreateCopyWithImpl(this._self, this._then);

  final BuddyIntentSavedMealCreate _self;
  final $Res Function(BuddyIntentSavedMealCreate) _then;

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? language = null,Object? script = null,Object? name = null,Object? activeProposal = freezed,Object? targets = null,Object? source = freezed,}) {
  return _then(BuddyIntentSavedMealCreate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as BuddySavedMealCreateKind,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,activeProposal: freezed == activeProposal ? _self.activeProposal : activeProposal // ignore: cast_nullable_to_non_nullable
as String?,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<String>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BuddyDayHint?,
  ));
}

/// Create a copy of BuddyIntent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuddyDayHintCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $BuddyDayHintCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class BuddyIntentUnrecognized implements BuddyIntent {
  const BuddyIntentUnrecognized({ String? $type}): $type = $type ?? 'unrecognized';
  factory BuddyIntentUnrecognized.fromJson(Map<String, dynamic> json) => _$BuddyIntentUnrecognizedFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BuddyIntentUnrecognizedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BuddyIntentUnrecognized);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'BuddyIntent.unrecognized()';
}


}




// dart format on
