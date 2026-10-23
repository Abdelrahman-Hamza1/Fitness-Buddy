import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptOp;
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

const String lunch = DefaultSlots.lunchId;
const String dinner = DefaultSlots.dinnerId;
final LocalDate past = today.plusDays(-1);

Future<DiaryHarness> source() async {
  final h = DiaryHarness(offsetMinutes: 180);
  await h.apply([
    CreateDishGroup(
      id: fixtureId(50),
      name: 'Dish',
      date: today,
      slotId: lunch,
    ),
    LogEntries([
      newEntry(1, grams: 200, group: 50, slotId: lunch),
      newEntry(2, group: 50, slotId: lunch),
      newEntry(3, slotId: dinner),
    ]),
  ]);
  return h;
}

SourceVersions versions({bool groups = true}) => SourceVersions(
  entries: [VersionedId(fixtureId(1), 1), VersionedId(fixtureId(2), 1)],
  groups: [if (groups) VersionedId(fixtureId(50), 1)],
);
CopyMeal copy({MealSource? selector, SourceVersions? expected}) => CopyMeal(
  selector ?? MealSource.slot(today, lunch),
  toDate: past,
  expected: expected ?? versions(),
  copyIds: {
    fixtureId(1): newId(1),
    fixtureId(2): newId(2),
    if ((expected ?? versions()).groups.isNotEmpty) fixtureId(50): newId(50),
  },
);
SaveMeal save() => SaveMeal(
  savedMealId: newId(90),
  name: 'Meal',
  source: MealSource.entries([fixtureId(1), fixtureId(2)]),
  expected: versions(groups: false),
);
Future<void> rejectsUnchanged(
  DiaryHarness h,
  DiaryOp op,
  Matcher failure,
) async {
  final before = await h.state();
  final outbox = await h.db
      .customSelect('SELECT * FROM sync_outbox ORDER BY rowid')
      .get();
  expect(await h.reject([op]), failure);
  expect(await h.state(), before);
  expect(
    (await h.db.customSelect('SELECT * FROM sync_outbox ORDER BY rowid').get())
        .map((r) => r.data)
        .toList(),
    outbox.map((r) => r.data).toList(),
  );
}

void main() {
  test('AI-072 override surfaces corrupt stored rows without writes', () async {
    final h = await source();
    await h.applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpdateRow(
            h.db.diaryEntries,
            fixtureId(1),
            const DiaryEntriesCompanion(per100Kcal: Value(-1)),
          ),
        ]),
      ], origin: Origin.direct),
    );
    final before = await h.state();
    await expectLater(
      h.applier.apply(
        ChangeSet([
          OverrideNutrients(fixtureId(1), 2, {NutrientField.protein: 30}),
        ], origin: Origin.direct),
      ),
      throwsArgumentError,
    );
    expect(await h.state(), before);
  });

  test(
    'PA8 a cross-day orphan is excluded from group-copy eligibility',
    () async {
      final h = await source();
      expect(
        await h.applier.apply(
          ChangeSet([
            ScriptOp.rows([
              UpdateRow(
                h.db.diaryEntries,
                fixtureId(1),
                DiaryEntriesCompanion(localDate: Value('$past')),
              ),
            ]),
          ], origin: Origin.direct),
        ),
        isA<Applied>(),
      );
      // Only member 2 really belongs to today's group; the orphan outside
      // the selection must not prevent copying that complete group.
      await h.apply([
        CopyMeal(
          MealSource.entries([fixtureId(2)]),
          toDate: past,
          expected: SourceVersions(
            entries: [VersionedId(fixtureId(2), 1)],
            groups: [VersionedId(fixtureId(50), 1)],
          ),
          copyIds: {fixtureId(2): newId(2), fixtureId(50): newId(50)},
        ),
      ]);
      expect((await h.entry(1002)).dishGroupId, newId(50));
      // A mixed-day selection can observe the valid group, while its orphan
      // member must still copy ungrouped.
      await h.apply([
        CopyMeal(
          MealSource.entries([fixtureId(1), fixtureId(2)]),
          toDate: past,
          expected: SourceVersions(
            entries: [
              VersionedId(fixtureId(1), 2),
              VersionedId(fixtureId(2), 1),
            ],
            groups: [VersionedId(fixtureId(50), 1)],
          ),
          copyIds: {
            fixtureId(1): newId(11),
            fixtureId(2): newId(12),
            fixtureId(50): newId(51),
          },
        ),
      ]);
      expect((await h.entry(1011)).dishGroupId, isNull);
      expect((await h.entry(1012)).dishGroupId, newId(51));
    },
  );

  test(
    'AI-072 tiny amount plus large value rejects outOfRange without writes',
    () async {
      for (final amount in [1e-7, 1e-300]) {
        final h = await source();
        // Simulate synced amounts below the calculator's storage precision.
        expect(
          await h.applier.apply(
            ChangeSet([
              ScriptOp.rows([
                UpdateRow(
                  h.db.diaryEntries,
                  fixtureId(1),
                  DiaryEntriesCompanion(amount: Value(amount)),
                ),
              ]),
            ], origin: Origin.direct),
          ),
          isA<Applied>(),
        );
        await rejectsUnchanged(
          h,
          OverrideNutrients(fixtureId(1), 2, {NutrientField.kcal: 20000}),
          equals(const InvalidOp('outOfRange')),
        );
      }
    },
  );
  test(
    'AI-072 negative zero stores positive zero and retains exact amount',
    () async {
      final h = await source();
      await h.applier.apply(
        ChangeSet([
          ScriptOp.rows([
            UpdateRow(
              h.db.diaryEntries,
              fixtureId(1),
              const DiaryEntriesCompanion(amount: Value(200.001)),
            ),
          ]),
        ], origin: Origin.direct),
      );
      await h.apply([
        OverrideNutrients(fixtureId(1), 2, {
          NutrientField.kcal: -0.0,
          NutrientField.sodium: -0.0,
        }),
      ]);
      final row = await h.entry(1);
      expect(row.amount, 200.001);
      expect(row.per100Kcal, 0);
      expect(row.per100Kcal.isNegative, isFalse);
      expect(row.kcal.isNegative, isFalse);
      expect(row.per100ExtrasJson, contains('0.0'));
    },
  );
  test('PA7 PA8 cross-day group is missing in layout and slot copy', () async {
    final h = await source();
    await h.applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpdateRow(
            h.db.dishGroups,
            fixtureId(50),
            DishGroupsCompanion(localDate: Value('$past')),
          ),
        ]),
      ], origin: Origin.direct),
    );
    final day = await h.reads.day(today);
    expect(day.groups, isEmpty);
    final rawGroup = DishGroup(
      id: fixtureId(50),
      version: 1,
      name: 'Dish',
      localDate: past,
      slotId: lunch,
    );
    for (final groups in [
      day.groups,
      [rawGroup],
    ]) {
      final section = DayLayout.build(
        day.slots,
        groups,
        day.entries,
      ).sections.singleWhere((s) => s.slot?.id == lunch);
      expect(section.items.every((i) => i is EntryItem), isTrue);
      expect(section.entryCopyGroupIds, isEmpty);
    }
    await h.apply([copy(expected: versions(groups: false))]);
    expect(
      (await h.reads.entriesOn(past)).every((e) => e.dishGroupId == null),
      isTrue,
    );
  });
  test(
    'PA7 PA8 unchanged orphan slot source copies ungrouped; revival rejects',
    () async {
      for (final revive in [false, true]) {
        final h = await source();
        final removed = await h.applier.apply(
          ChangeSet([
            ScriptOp.rows([TombstoneRow(h.db.dishGroups, fixtureId(50))]),
          ], origin: Origin.direct),
        );
        final op = copy(expected: versions(groups: false));
        if (revive) {
          await h.undo(removed as Applied);
          await rejectsUnchanged(
            h,
            op,
            equals(const InvalidOp('sourceChanged')),
          );
        } else {
          await h.apply([op]);
          expect(
            (await h.reads.entriesOn(past)).every((e) => e.dishGroupId == null),
            isTrue,
          );
        }
      }
    },
  );
  test(
    'PA8 renamed group alone pins VersionConflict with members untouched',
    () async {
      final h = await source();
      final op = copy();
      final before = await h.reads.entriesOn(today);
      await h.apply([RenameDishGroup(fixtureId(50), 1, 'Renamed')]);
      expect(await h.reads.entriesOn(today), before);
      await rejectsUnchanged(h, op, isA<VersionConflict>());
    },
  );

  test('AI-072 OverrideNutrients sets edited_by_user and '
      "changes only the given fields; kcal isn't recomputed", () async {
    final h = await source();
    final before = (await h.reads.entriesIn(today, lunch)).first;
    final result = await h.apply([
      OverrideNutrients(fixtureId(1), 1, {
        NutrientField.protein: 30,
        NutrientField.sodium: 123,
      }),
    ]);
    final after = (await h.reads.entriesIn(today, lunch)).first;
    expect(after.editedByUser, isTrue);
    expect(after.snapshot.protein, 30);
    expect(after.snapshot.extra(NutrientKey.sodium), 123);
    expect(after.snapshot.kcal, before.snapshot.kcal);
    expect(after.snapshot.carbs, before.snapshot.carbs);
    expect(after.snapshot.fat, before.snapshot.fat);
    expect(after.snapshot.fiber, before.snapshot.fiber);
    expect(
      after.snapshot.extra(NutrientKey.sugar),
      before.snapshot.extra(NutrientKey.sugar),
    );
    expect(result.events.first, isA<EntryChanged>());
    await rejectsUnchanged(
      h,
      OverrideNutrients(fixtureId(1), 1, {NutrientField.kcal: 1}),
      isA<VersionConflict>(),
    );
  });
  test('AI-072 an amount edit after an override scales it (30 g '
      'protein at 200 g → 60 g at 400 g) and keeps the flag', () async {
    final h = await source();
    await h.apply([
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final before = await h.state();
    final result = await h.apply([
      UpdateDiaryEntry(
        fixtureId(1),
        2,
        EntryPatch(
          amount: EntryAmount(
            input: Quantity(400, 'g'),
            amount: 400,
            basis: NutrientBasis.per100g,
          ),
        ),
      ),
    ]);
    expect((await h.entry(1)).proteinG, 60);
    expect((await h.entry(1)).editedByUser, isTrue);
    await h.undo(result);
    expect(await h.state(), before);
  });
  test('AI-072 a food change clears the flag', () async {
    final h = await source();
    await h.apply([
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final before = await h.state();
    final changed = await h.apply([
      UpdateDiaryEntry(fixtureId(1), 2, EntryPatch(food: foodOf(4))),
    ]);
    expect((await h.entry(1)).editedByUser, isFalse);
    await h.undo(changed);
    expect(await h.state(), before);
  });
  test('AI-072 amount 0 → InvalidOp(zeroAmount); same values on '
      'an edited entry → no write', () async {
    final h = DiaryHarness();
    await h.apply([
      LogEntries([newEntry(1, grams: 0), newEntry(2)]),
    ]);
    await rejectsUnchanged(
      h,
      OverrideNutrients(fixtureId(1), 1, {NutrientField.kcal: 1}),
      equals(const InvalidOp('zeroAmount')),
    );
    await h.apply([
      OverrideNutrients(fixtureId(2), 1, {NutrientField.protein: 30}),
    ]);
    final before = await h.state();
    final row = await h.entry(2);
    final applied = await h.apply([
      OverrideNutrients(fixtureId(2), 2, {NutrientField.protein: 30}),
    ]);
    expect(applied.inverse.isEmpty, isTrue);
    expect(await h.entry(2), row);
    expect(await h.state(), before);
  });
  test(
    'AI-072 + undo restores per-100, snapshot and edited_by_user exactly',
    () async {
      final h = await source();
      final before = await h.state();
      final applied = await h.apply([
        OverrideNutrients(fixtureId(1), 1, {
          for (final f in NutrientField.values) f: 31.37,
        }),
      ]);
      await h.undo(applied);
      expect(await h.state(), before);
    },
  );
  test('DY-023 CopyMeal and SaveMeal carry edited_by_user', () async {
    final h = await source();
    await h.apply([
      OverrideNutrients(fixtureId(1), 1, {NutrientField.protein: 30}),
    ]);
    final expected = SourceVersions(
      entries: [VersionedId(fixtureId(1), 2)],
      groups: [VersionedId(fixtureId(50), 1)],
    );
    final before = await h.state();
    final copied = await h.apply([
      CopyMeal(
        MealSource.entries([fixtureId(1)]),
        toDate: past,
        expected: expected,
        copyIds: {fixtureId(1): newId(1)},
      ),
    ]);
    expect((await h.entry(1001)).editedByUser, isTrue);
    await h.undo(copied);
    expect(await h.state(), before);
    final saved = await h.apply([
      SaveMeal(
        savedMealId: newId(80),
        name: 'Meal',
        source: MealSource.entries([fixtureId(1)]),
        expected: SourceVersions(entries: expected.entries),
      ),
    ]);
    expect(
      (await h.db.select(h.db.savedMealItems).getSingle()).editedByUser,
      isTrue,
    );
    await h.undo(saved);
    expect(await h.state(), before);
  });
  final races = <String, Future<void> Function(DiaryHarness)>{
    'an entry added to the slot → sourceChanged': (h) async {
      await h.apply([
        LogEntries([newEntry(4, slotId: lunch)]),
      ]);
    },
    'a shown entry edited → VersionConflict': (h) async {
      await h.apply([
        UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(localTime: LocalTime(9))),
      ]);
    },
    'a shown entry deleted → sourceChanged (slot source) / '
        'RowNotFound (entries source)': (h) async {
      await h.apply([
        DeleteEntries([VersionedId(fixtureId(1), 1)]),
      ]);
    },
    'a shown entry moved out of the slot → sourceChanged': (h) async {
      await h.apply([
        MoveEntries([VersionedId(fixtureId(1), 1)], toSlotId: dinner),
      ]);
    },
    'an entry moved into the slot → sourceChanged': (h) async {
      await h.apply([
        MoveEntries([VersionedId(fixtureId(3), 1)], toSlotId: lunch),
      ]);
    },
  };
  for (final race in races.entries) {
    test(race.key, () async {
      final h = await source();
      final op = copy();
      await race.value(h);
      await rejectsUnchanged(
        h,
        op,
        race.key.contains('edited')
            ? isA<VersionConflict>()
            : equals(const InvalidOp('sourceChanged')),
      );
      if (race.key.contains('deleted')) {
        await rejectsUnchanged(
          h,
          copy(selector: MealSource.entries([fixtureId(1), fixtureId(2)])),
          isA<RowNotFound>(),
        );
      }
    });
  }
  test(
    'a shown dish group renamed or moved → VersionConflict / sourceChanged',
    () async {
      for (final move in [false, true]) {
        final h = await source();
        final op = copy();
        await h.apply([
          if (move)
            MoveDishGroup(fixtureId(50), 1, toSlotId: dinner)
          else
            RenameDishGroup(fixtureId(50), 1, 'Renamed'),
        ]);
        await rejectsUnchanged(
          h,
          op,
          move
              ? equals(const InvalidOp('sourceChanged'))
              : isA<VersionConflict>(),
        );
      }
    },
  );
  test('SaveMeal: an edited shown entry → VersionConflict; a '
      'deleted one → RowNotFound', () async {
    for (final delete in [false, true]) {
      final h = await source();
      final op = save();
      await h.apply([
        if (delete)
          DeleteEntries([VersionedId(fixtureId(1), 1)])
        else
          UpdateDiaryEntry(
            fixtureId(1),
            1,
            EntryPatch(localTime: LocalTime(9)),
          ),
      ]);
      await rejectsUnchanged(
        h,
        op,
        delete ? isA<RowNotFound>() : isA<VersionConflict>(),
      );
    }
  });
  test('PA7 a live group disappearing rejects with nothing written', () async {
    final h = await source();
    final op = copy();
    await h.applier.apply(
      ChangeSet([
        ScriptOp.rows([TombstoneRow(h.db.dishGroups, fixtureId(50))]),
      ], origin: Origin.direct),
    );
    await rejectsUnchanged(h, op, equals(const InvalidOp('sourceChanged')));
  });

  test(
    'the unchanged source copies and saves exactly the shown values',
    () async {
      final h = await source();
      final shown = await h.reads.entriesIn(today, lunch);
      await h.apply([copy(), save()]);
      final copies = await h.reads.entriesOn(past);
      for (var i = 0; i < copies.length; i++) {
        expect(copies[i].food, shown[i].food);
        expect(copies[i].amount, shown[i].amount);
        expect(copies[i].snapshot, shown[i].snapshot);
      }
      final items = await h.db.select(h.db.savedMealItems).get();
      expect(items.map((e) => e.kcal), shown.map((e) => e.snapshot.kcal));
    },
  );
  test('copy, edit one copy, Undo → conflict and every copy stays '
      '(no partial revert)', () async {
    final h = await source();
    final copied = await h.apply([copy()]);
    await h.apply([
      UpdateDiaryEntry(newId(1), 1, EntryPatch(localTime: LocalTime(9))),
    ]);
    final before = await h.state();
    final undo = await h.applier.revert(copied.inverse);
    expect(
      undo,
      isA<Rejected>().having(
        (r) => r.failure,
        'conflict',
        isA<VersionConflict>(),
      ),
    );
    expect(await h.state(), before);
    expect(await h.reads.entriesOn(past), hasLength(2));
  });
  test('DY-023 save, edit one saved item, Undo rejects atomically', () async {
    final h = await source();
    final saved = await h.apply([save()]);
    final item = (await h.db.select(h.db.savedMealItems).get()).first;
    final edited = await h.applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpdateRow(
            h.db.savedMealItems,
            item.id,
            const SavedMealItemsCompanion(kcal: Value(123)),
          ),
        ]),
      ], origin: Origin.direct),
    );
    expect(edited, isA<Applied>());
    final before = await h.state();
    expect(
      await h.applier.revert(saved.inverse),
      isA<Rejected>().having(
        (r) => r.failure,
        'conflict',
        isA<VersionConflict>(),
      ),
    );
    expect(await h.state(), before);
  });

  test(
    'DY-023 source checks observe earlier writes in the same transaction',
    () async {
      final h = await source();
      final before = await h.state();
      expect(
        await h.reject([
          LogEntries([newEntry(4, slotId: lunch)]),
          copy(),
        ]),
        const InvalidOp('sourceChanged'),
      );
      expect(await h.state(), before);
    },
  );

  test('copy, Undo → every copy and copied group tombstoned', () async {
    final h = await source();
    final before = await h.state();
    final copied = await h.apply([copy()]);
    await h.undo(copied);
    expect(await h.state(), before);
    for (final n in [1001, 1002]) {
      expect((await h.entry(n)).deletedAt, isNotNull);
    }
    expect((await h.group(1050)).deletedAt, isNotNull);
  });
  test('save, Undo → the saved meal and all its items tombstoned', () async {
    final h = await source();
    final before = await h.state();
    final saved = await h.apply([save()]);
    await h.undo(saved);
    expect(await h.state(), before);
    expect(
      (await h.db.select(h.db.savedMeals).getSingle()).deletedAt,
      isNotNull,
    );
    expect(
      (await h.db.select(h.db.savedMealItems).get()).every(
        (r) => r.deletedAt != null,
      ),
      isTrue,
    );
  });
  test('watchEntry(id) follows the row across a slot and day '
      'move, emits null after a delete, and the revived row '
      'after undo', () async {
    final h = await source();
    final repo = DiaryRepository(h.db);
    final values = <DiaryEntry?>[];
    final sub = repo.watchEntry(fixtureId(1)).listen(values.add);
    addTearDown(sub.cancel);
    Future<void> wait(bool Function() ready) async {
      for (var i = 0; i < 200 && !ready(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      expect(ready(), isTrue);
    }

    await wait(() => values.isNotEmpty);
    await h.apply([
      MoveEntries(
        [VersionedId(fixtureId(1), 1)],
        toDate: past,
        toSlotId: dinner,
      ),
    ]);
    await wait(() => values.last?.localDate == past);
    expect(values.last!.slotId, dinner);
    final deleted = await h.apply([
      DeleteEntries([VersionedId(fixtureId(1), 2)]),
    ]);
    await wait(() => values.last == null);
    await h.undo(deleted);
    await wait(() => values.last != null);
    expect(values.last!.localDate, past);
    expect(values.last!.version, 4);
  });
  test('DY-023 a member of a partially selected group added or removed '
      'elsewhere → sourceChanged', () async {
    for (final added in [false, true]) {
      final h = await source();
      final selected = [fixtureId(1), if (added) fixtureId(2)];
      final op = CopyMeal(
        MealSource.entries(selected),
        toDate: past,
        expected: SourceVersions(
          entries: selected.map((id) => VersionedId(id, 1)),
          groups: [VersionedId(fixtureId(50), 1)],
        ),
        copyIds: {
          for (final id in selected)
            id: newId(int.parse(id.substring(id.length - 4), radix: 16)),
          if (added) fixtureId(50): newId(50),
        },
      );
      await h.apply([
        if (added)
          LogEntries([newEntry(4, group: 50, slotId: lunch)])
        else
          DeleteEntries([VersionedId(fixtureId(2), 1)]),
      ]);
      await rejectsUnchanged(h, op, equals(const InvalidOp('sourceChanged')));
    }
  });
  test('DY-023 an unchanged partially selected group is observed and '
      'copies ungrouped; a rename rejects', () async {
    for (final renamed in [false, true]) {
      final h = await source();
      final op = CopyMeal(
        MealSource.entries([fixtureId(1)]),
        toDate: past,
        expected: SourceVersions(
          entries: [VersionedId(fixtureId(1), 1)],
          groups: [VersionedId(fixtureId(50), 1)],
        ),
        copyIds: {fixtureId(1): newId(1)},
      );
      if (renamed) {
        await h.apply([RenameDishGroup(fixtureId(50), 1, 'Changed')]);
        await rejectsUnchanged(h, op, isA<VersionConflict>());
      } else {
        final before = await h.state();
        final applied = await h.apply([op]);
        expect((await h.entry(1001)).dishGroupId, isNull);
        await h.undo(applied);
        expect(await h.state(), before);
      }
    }
  });
  test('PA7 an unchanged orphan entry copies; a group-state '
      'change between open and submit rejects with nothing '
      'written', () async {
    for (final live in [false, true]) {
      final h = await source();
      // Both entries retain the missing group reference; only entry 2 is
      // selected. Revival makes the group live but ineligible for copying.
      final tombstoned = await h.applier.apply(
        ChangeSet([
          ScriptOp.rows([TombstoneRow(h.db.dishGroups, fixtureId(50))]),
        ], origin: Origin.direct),
      );
      final op = CopyMeal(
        MealSource.entries([fixtureId(2)]),
        toDate: past,
        expected: SourceVersions(entries: [VersionedId(fixtureId(2), 1)]),
        copyIds: {fixtureId(2): newId(2)},
      );
      if (live) {
        await h.undo(tombstoned as Applied);
        await rejectsUnchanged(h, op, equals(const InvalidOp('sourceChanged')));
      } else {
        await h.apply([op]);
        expect((await h.entry(1002)).dishGroupId, isNull);
      }
    }
  });
}
