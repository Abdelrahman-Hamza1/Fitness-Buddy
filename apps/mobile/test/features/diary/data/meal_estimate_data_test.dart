import 'package:drift/drift.dart' show Variable;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

const String lunch = DefaultSlots.lunchId;

/// A meal estimate entry [n] of [estimate], logged today at 13:05 in lunch.
NewDiaryEntry estimateEntry(int n, UserEstimate estimate) => NewDiaryEntry(
  id: fixtureId(n),
  when: .at(EntryTime(DateTime.utc(2026, 10, 17, 13, 5), 0)),
  slotId: lunch,
  food: estimate.food(),
  amount: UserEstimate.amount,
);

Future<Map<String, Object?>> payloadOf(DiaryHarness h, int n) async {
  final row = await h.db
      .customSelect(
        'SELECT * FROM diary_entries WHERE id = ?',
        variables: [Variable.withString(fixtureId(n))],
      )
      .getSingle();
  final table = h.db.syncedTables.singleWhere(
    (t) => t.entity == diaryEntryEntity,
  );
  return ColumnSyncCodec(table).encode(row.data);
}

void main() {
  test('DY-005 log meal estimate writes the flags; the payload keeps W1-W3; '
      'Undo removes it', () async {
    final h = DiaryHarness();
    final applied = await h.apply([
      LogEntries([
        estimateEntry(1, const UserEstimate(kcal: 700, name: 'Out', fat: 0)),
      ]),
    ]);
    final row = await h.entry(1);
    expect(row.userEstimate, isTrue);
    expect(row.foodKind, 'estimate');
    expect(row.foodId, isNull);
    expect(row.source, 'yours');
    expect(row.isEstimate, isTrue);
    expect(row.editedByUser, isTrue);
    expect(
      (row.proteinKnown, row.carbsKnown, row.fatKnown, row.fiberKnown),
      (false, false, true, false),
    );
    expect((row.kcal, row.proteinG, row.fatG), (700.0, 0.0, 0.0));
    final payload = await payloadOf(h, 1);
    expect(payload['userEstimate'], isTrue);
    expect(payload['fatKnown'], isTrue);
    expect(DiaryEstimateWireRules.holds(diaryEntryEntity, 2, payload), isTrue);

    final entry = (await h.reads.entriesOn(today)).single;
    expect(entry.food.userEstimate, isTrue);
    final intake = DiaryTotals.intake([entry]);
    expect(intake.valueOf(NutrientField.protein), isNull);
    expect(intake.valueOf(NutrientField.fat), 0);

    await h.undo(applied);
    expect(await h.reads.entriesOn(today), isEmpty);
  });

  test('FD-012 logging a 10,000 kcal estimate never runs SanityCheck and is '
      'stored', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([estimateEntry(1, const UserEstimate(kcal: 10000))]),
    ]);
    expect((await h.entry(1)).kcal, 10000);
  });

  test('DY-005 edit keeps id; Undo restores; a swap to a food resets the '
      'flags in one change set with one Undo', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([estimateEntry(1, const UserEstimate(kcal: 700))]),
    ]);
    final edit = await h.apply([
      UpdateDiaryEntry(
        fixtureId(1),
        1,
        EntryPatch(
          food: const UserEstimate(kcal: 650, protein: 40).food(),
          amount: UserEstimate.amount,
        ),
      ),
    ]);
    var row = await h.entry(1);
    expect((row.kcal, row.proteinG, row.proteinKnown), (650.0, 40.0, true));
    await h.undo(edit);
    row = await h.entry(1);
    expect((row.kcal, row.proteinKnown), (700.0, false));

    // Swap for foods: ReplaceEntryFood's op on selection.
    final swap = await h.apply([
      UpdateDiaryEntry(
        fixtureId(1),
        row.version,
        EntryPatch(
          food: foodOf(9),
          amount: EntryAmount(
            input: Quantity(150, 'g'),
            amount: 150,
            basis: NutrientBasis.per100g,
          ),
        ),
      ),
    ]);
    row = await h.entry(1);
    expect(row.userEstimate, isFalse);
    expect(
      (row.proteinKnown, row.carbsKnown, row.fatKnown, row.fiberKnown),
      (true, true, true, true),
    );
    expect(row.foodKind, 'catalog');
    await h.undo(swap);
    row = await h.entry(1);
    expect(
      (row.userEstimate, row.proteinKnown, row.kcal),
      (true, false, 700.0),
    );

    // A stale swap (the estimate changed meanwhile) writes nothing.
    final before = await h.state();
    expect(
      await h.reject([
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(food: foodOf(9))),
      ]),
      isA<VersionConflict>(),
    );
    expect(await h.state(), before);
  });

  test('AI-072 override unknown protein → 0 writes once, syncs as '
      'proteinKnown true, Undo restores unknown (D24)', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([estimateEntry(1, const UserEstimate(kcal: 700))]),
    ]);
    final applied = await h.apply([
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 0}),
    ]);
    var row = await h.entry(1);
    expect(
      (row.proteinKnown, row.proteinG, row.per100ProteinG, row.version),
      (true, 0.0, 0.0, 2),
    );
    expect(row.carbsKnown, isFalse, reason: 'other unknowns stay unknown');
    final payload = await payloadOf(h, 1);
    expect((payload['proteinKnown'], payload['proteinG']), (true, 0.0));
    expect(DiaryEstimateWireRules.holds(diaryEntryEntity, 2, payload), isTrue);

    // The same value again is unchanged: no write.
    await h.apply([
      OverrideNutrients(fixtureId(1), 2, {NutrientField.protein: 0}),
    ]);
    expect((await h.entry(1)).version, 2);

    await h.undo(applied);
    row = await h.entry(1);
    expect(row.proteinKnown, isFalse);
  });

  test('DY-031 saved meal save + relog keeps known flags and "~"', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([
        estimateEntry(1, const UserEstimate(kcal: 600, protein: 0)),
        newEntry(2, slotId: lunch),
      ]),
    ]);
    await h.apply([
      SaveMeal(
        savedMealId: newId(90),
        name: 'Friday',
        source: MealSource.entries([fixtureId(1), fixtureId(2)]),
        expected: SourceVersions(
          entries: [VersionedId(fixtureId(1), 1), VersionedId(fixtureId(2), 1)],
        ),
      ),
    ]);
    final meal = (await h.reads.savedMeal(newId(90)))!;
    final estimate = meal.items.singleWhere((i) => i.food.userEstimate);
    expect(estimate.food.known, {NutrientField.protein});
    expect(meal.intake.estimated, isTrue);
    expect(meal.intake.isLowerBound(NutrientField.carbs), isTrue);
    expect(meal.intake.valueOf(NutrientField.protein), isNotNull);

    await h.apply([
      LogSavedMeal(
        expected: meal.versions!,
        entryIds: {
          for (final (i, item) in meal.items.indexed) item.id: newId(i),
        },
        when: .at(EntryTime(DateTime.utc(2026, 10, 17, 19), 0)),
        slotId: DefaultSlots.dinnerId,
      ),
    ]);
    final relogged = await h.reads.entriesIn(today, DefaultSlots.dinnerId);
    final copy = relogged.singleWhere((e) => e.food.userEstimate);
    expect(copy.food.known, {NutrientField.protein});
    expect(DiaryTotals.intake(relogged), meal.intake);
  });

  test(
    'D9 daily intake SQL counts estimates and unknowns per nutrient',
    () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([
          estimateEntry(1, const UserEstimate(kcal: 700, protein: 30)),
          newEntry(2, slotId: lunch),
        ]),
      ]);
      final day = (await h.reads.dailyTotals(today, today)).single;
      final expected = DiaryTotals.intake(await h.reads.entriesOn(today));
      expect(day.intake, expected);
      expect(day.intake.estimated, isTrue);
      expect(day.intake.coverage(NutrientField.protein), NutrientCoverage.full);
      expect(
        day.intake.coverage(NutrientField.carbs),
        NutrientCoverage.partial,
      );
      expect(day.entryCount, 2);
    },
  );
}
