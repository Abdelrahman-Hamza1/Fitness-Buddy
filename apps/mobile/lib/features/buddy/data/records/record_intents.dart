import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';

/// A record intent as the planner takes it (A67 D1): the typed request and
/// the contract food items the app builds with the food engine (a batch's
/// ingredients, a food's components, an edit's replacement), kept as the
/// raw JSON the engine decodes. User content: never logged.
final class RecordIntent {
  /// The intent.
  const new(this.request, {this.foodItems = const [], this.language});

  /// The typed request.
  final RecordRequest request;

  /// Raw `BuddyFoodItem` maps to build.
  final List<Map<String, Object?>> foodItems;

  /// The message language code, when given.
  final String? language;

  @override
  String toString() => 'RecordIntent(${request.kind.code})';
}

/// Decodes a raw contract intent of a record kind with the generated
/// types; `null` for another kind or a shape this version can't read.
RecordIntent? decodeRecordIntent(Map<String, Object?> raw) {
  if (RecordKind.fromCode(raw['kind']) == null) return null;
  final BuddyIntent intent;
  try {
    intent = BuddyIntent.fromJson(raw);
    // A malformed shape is an intent this version can't read (its text
    // never leaves here).
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
  List<Map<String, Object?>> items(Object? list) => [
    if (list is List<Object?>)
      for (final i in list)
        if (i is Map<String, Object?>) i,
  ];
  RecordDayHint hint(BuddyDayHint? h) => RecordDayHint(
    dateHint: h?.dateHint,
    slotHint: h?.slotHint,
    timeHint: h?.timeHint,
  );
  RecordReference reference(BuddyEntryReference r) => RecordReference(
    mention: r.mention,
    when: RecordDayHint(dateHint: r.dateHint, slotHint: r.slotHint),
    all: r.scope == BuddyReferenceScope.all,
  );
  RecordAmountInput? amount(BuddyAmount? a) =>
      a?.value == null || a?.unit == null
      ? null
      : RecordAmountInput(a!.value!, a.unit!);
  RecordPortion? portion(BuddyPortion? p) => p == null
      ? null
      : RecordPortion(
          amount: amount(p.amount),
          fraction: p.share?.fraction,
          people: p.share?.people,
        );
  EditRecord edit(
    List<String> targets,
    BuddyEntryReference ref,
    BuddyDiaryPatch patch,
  ) => EditRecord(
    targets: targets,
    reference: reference(ref),
    amount: amount(patch.amount),
    replace: patch.replacement != null,
    move: patch.move == null ? null : hint(patch.move),
  );
  final patchJson = raw['patch'];
  final replacement = patchJson is Map<String, Object?>
      ? patchJson['replacement']
      : null;
  return switch (intent) {
    BuddyIntentDiaryEdit(:final targets, reference: final r, :final patch) =>
      RecordIntent(
        edit(targets, r, patch),
        foodItems: items([replacement]),
        language: intent.language,
      ),
    BuddyIntentDiaryDelete(:final targets, reference: final r) => RecordIntent(
      DeleteRecord(targets: targets, reference: reference(r)),
    ),
    BuddyIntentAmbiguousReference(
      :final operation,
      :final candidates,
      reference: final r,
      :final patch,
    ) =>
      RecordIntent(
        AmbiguousRecord(
          candidates: candidates,
          reference: reference(r),
          then: operation == BuddyReferenceOperation.edit && patch != null
              ? edit(const [], r, patch)
              : DeleteRecord(targets: const [], reference: reference(r)),
        ),
        foodItems: items([replacement]),
        language: intent.language,
      ),
    BuddyIntentDiaryCopy(:final source, :final target) => RecordIntent(
      CopyRecord(source: hint(source), target: hint(target)),
    ),
    BuddyIntentSavedMealLog(
      :final savedMealId,
      :final dateHint,
      :final slotHint,
      :final timeHint,
      :final share,
    ) =>
      RecordIntent(
        SavedMealLogRecord(
          savedMealId: savedMealId,
          when: RecordDayHint(
            dateHint: dateHint,
            slotHint: slotHint,
            timeHint: timeHint,
          ),
          shared: share?.fraction != null || share?.people != null,
        ),
      ),
    BuddyIntentSavedMealCreate(
      :final name,
      :final activeProposal,
      :final targets,
      :final source,
    ) =>
      RecordIntent(
        SavedMealCreateRecord(
          name: name,
          targets: targets,
          source: source == null ? null : hint(source),
          activeProposal: activeProposal,
        ),
      ),
    BuddyIntentBatch(
      :final name,
      :final cookedWeight,
      :final path,
      :final eatenNow,
      :final dateHint,
      :final slotHint,
      :final timeHint,
    ) =>
      RecordIntent(
        BatchRecord(
          name: name,
          cooked: amount(cookedWeight),
          path: switch (path) {
            BuddyBatchPath.quick => BatchPath.quick,
            BuddyBatchPath.leftovers => BatchPath.leftovers,
            _ => null,
          },
          eatenNow: portion(eatenNow),
          when: RecordDayHint(
            dateHint: dateHint,
            slotHint: slotHint,
            timeHint: timeHint,
          ),
        ),
        foodItems: items(raw['ingredients']),
        language: intent.language,
      ),
    BuddyIntentBatchPortion(
      :final batchId,
      portion: final p,
      :final rest,
      :final dateHint,
      :final slotHint,
      :final timeHint,
    ) =>
      RecordIntent(
        BatchPortionRecord(
          batchId: batchId,
          portion: portion(p),
          rest: rest,
          when: RecordDayHint(
            dateHint: dateHint,
            slotHint: slotHint,
            timeHint: timeHint,
          ),
        ),
      ),
    BuddyIntentBatchClose(:final batchId) => RecordIntent(
      BatchCloseRecord(batchId),
    ),
    BuddyIntentPersonalFoodCreate(:final name, :final aliases, :final stated) =>
      RecordIntent(
        PersonalFoodRecord(
          name: name,
          aliases: aliases,
          stated: stated == null
              ? null
              : StatedFigures(
                  basis: stated.basis.json ?? 'per100g',
                  servingG: stated.servingG,
                  servingMl: stated.servingMl,
                  kcal: stated.kcal,
                  protein: stated.proteinG,
                  carbs: stated.carbsG,
                  fat: stated.fatG,
                  fiber: stated.fiberG,
                ),
        ),
        foodItems: items(raw['components']),
        language: intent.language,
      ),
    BuddyIntentMemoryChange(
      :final operation,
      :final memoryKind,
      :final subject,
      :final dimension,
      :final value,
      amount: final a,
      :final food,
    ) =>
      RecordIntent(
        MemoryRecord(
          forget: operation == BuddyMemoryOperation.forget,
          memoryKind: memoryKind.json ?? '',
          subject: subject,
          dimension: dimension?.json,
          value: value,
          amount: amount(a),
          foodGroup: food?.match?.yieldGroup ?? food?.match?.key,
          foodName: food?.match?.nameEn,
        ),
      ),
    BuddyIntentWeighIn(
      :final value,
      :final unit,
      :final dateHint,
      :final timeHint,
    ) =>
      RecordIntent(
        WeighInRecord(
          value: value,
          unit: unit.trim().toLowerCase(),
          when: RecordDayHint(dateHint: dateHint, timeHint: timeHint),
        ),
      ),
    _ => null,
  };
}

/// A short code-made label of a record card (history outcomes, the
/// holder row; never shown as a bubble, ≤ 120). User content.
String recordLabel(RecordView view) {
  final names = [
    for (final l in view.lines.take(4))
      if (l.names.en.trim() case final n when n.isNotEmpty) n,
  ].join(', ');
  final text = switch (view.kind) {
    RecordKind.diaryEdit || RecordKind.ambiguousReference => 'Edit: $names',
    RecordKind.diaryDelete => 'Delete: $names',
    RecordKind.diaryCopy => 'Copy: $names',
    RecordKind.savedMealLog => 'Saved meal: ${view.title ?? names}',
    RecordKind.savedMealCreate => 'Save meal: ${view.title ?? names}',
    RecordKind.batch => 'Batch: ${view.title ?? names}',
    RecordKind.batchPortion => 'Batch portion: ${view.title ?? ''}',
    RecordKind.batchClose => 'Close batch: ${view.title ?? ''}',
    RecordKind.personalFoodCreate => 'Your food: ${view.title ?? ''}',
    RecordKind.memoryChange =>
      '${view.memory?.forget ?? false ? 'Forget' : 'Remember'}: '
          '${view.memory?.subject ?? ''}',
    RecordKind.weighIn => 'Weigh-in',
  };
  return text.length <= 120 ? text : '${text.substring(0, 117)}...';
}
