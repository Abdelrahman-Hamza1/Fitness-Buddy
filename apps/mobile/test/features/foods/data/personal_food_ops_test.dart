import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/foods/data/personal_food_mappers.dart';
import 'package:fb_mobile/features/foods/data/personal_food_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'personal_food_harness.dart';

// Exact food columns shared by diary entries and saved items, including JSON
// spelling.
Object entryValues(DiaryEntryRow r) => values(r.toColumns(false));
Object itemValues(SavedMealItemRow r) => values(r.toColumns(false));
Object values(Map<String, Expression> columns) => {
  for (final e in columns.entries)
    if (!{
      'id',
      'created_at',
      'updated_hlc',
      'version',
      'deleted_at',
      'device_id',
      'origin',
      'food_kind',
      'food_id',
      'food_version',
      'local_date',
      'occurred_at_utc',
      'tz_offset_min',
      'slot_id',
      'dish_group_id',
      'saved_meal_id',
      'sort_order',
    }.contains(e.key))
      e.key: (e.value as Variable).value,
};
void main() {
  test('FD-070 CreatePersonalFood inserts one row (created_from '
      'form, origin direct) and one outbox row personalFood; Undo '
      'tombstones it', () async {
    final h = PersonalHarness();
    final before = await h.state();
    final a = await h.apply([
      CreatePersonalFood(fixtureId(1), draft('Secret')),
    ]);
    final row = await h.row(1);
    expect((row.createdFrom, row.origin, row.version), ('form', 'direct', 1));
    final out = await h.db.select(h.db.syncOutbox).get();
    expect(out.map((r) => r.entity), ['personalFood']);
    await h.undo(a);
    expect((await h.row(1)).deletedAt, isNotNull);
    expect(await h.state(), before);
  });
  test('FD-073 UpdatePersonalFood changes only the food: entries '
      'and saved items referencing it keep names, per-100, '
      'snapshot and provenance (exact-state comparison)', () async {
    final h = PersonalHarness();
    await h.seed();
    final entries = await h.db.select(h.db.diaryEntries).get();
    final items = await h.liveItems();
    final before = await h.state();
    final a = await h.apply([
      UpdatePersonalFood(fixtureId(2), 1, draft('New name')),
    ]);
    expect(await h.db.select(h.db.diaryEntries).get(), entries);
    expect(await h.liveItems(), items);
    await h.undo(a);
    expect(await h.state(), before);
  });
  test('FD-073 UpdatePersonalFood with the same draft writes '
      'nothing; a stale version → VersionConflict, nothing written', () async {
    final h = PersonalHarness();
    await h.seed();
    final before = await h.raw();
    await h.apply([UpdatePersonalFood(fixtureId(1), 1, draft('A'))]);
    expect(await h.raw(), before);
    await h.apply([UpdatePersonalFood(fixtureId(1), 1, draft('Edited'))]);
    expect(
      await h.reject([UpdatePersonalFood(fixtureId(1), 1, draft('Again'))]),
      isA<VersionConflict>(),
    );
    expect(
      await h.reject([
        CreatePersonalFood(fixtureId(4), draft('Too long' * 20)),
      ]),
      isA<InvalidOp>(),
    );
    expect(
      await h.reject([UpdatePersonalFood(fixtureId(99), 1, draft('Missing'))]),
      isA<RowNotFound>(),
    );
  });
  test('FD-073 DeletePersonalFood tombstones the food; entries keep '
      'their values; Undo revives it', () async {
    final h = PersonalHarness();
    await h.seed();
    final before = await h.state();
    final entries = await h.db.select(h.db.diaryEntries).get();
    final a = await h.apply([DeletePersonalFood(VersionedId(fixtureId(2), 1))]);
    expect((await h.row(2)).deletedAt, isNotNull);
    expect(await h.db.select(h.db.diaryEntries).get(), entries);
    await h.undo(a);
    expect(await h.state(), before);
  });
  test('FD-073 merging B into A: every live diary entry and saved '
      'item that referenced B keeps its names, per-100, snapshot, '
      'provenance and edited_by_user, and now references A; '
      'tombstoned entries are untouched; B is tombstoned; A has '
      "B's names as aliases", () async {
    final h = PersonalHarness();
    await h.seed(entries: 3, items: 3);
    final saved = await h.liveItems();
    await h.write([
      UpdateRow(
        h.db.diaryEntries,
        fixtureId(10),
        const DiaryEntriesCompanion(editedByUser: Value(true)),
      ),
      UpdateRow(
        h.db.savedMealItems,
        saved.first.id,
        const SavedMealItemsCompanion(editedByUser: Value(true)),
      ),
      TombstoneRow(h.db.savedMealItems, saved.last.id),
    ]);
    final deadItem = (await h.db.select(h.db.savedMealItems).get())
        .where((r) => r.id == saved.last.id)
        .single;
    await h.apply([
      DeleteEntries([VersionedId(fixtureId(12), 1)]),
    ]);
    final dead = await (h.db.select(
      h.db.diaryEntries,
    )..where((t) => t.id.equals(fixtureId(12)))).getSingle();
    final beforeEntries = await h.db.select(h.db.diaryEntries).get();
    final beforeItems = await h.liveItems();
    final a = await h.apply(h.merge());
    final afterEntries = await h.db.select(h.db.diaryEntries).get();
    final afterItems = await h.liveItems();
    for (var i = 0; i < beforeEntries.length; i++) {
      final x = beforeEntries[i];
      final y = afterEntries[i];
      if (x.deletedAt != null) {
        expect(y, x);
      } else {
        expect(entryValues(y), entryValues(x));
        expect(y.foodId, fixtureId(1));
        expect(y.foodKind, 'personal');
        expect(y.foodVersion, isNull);
      }
    }
    for (var i = 0; i < beforeItems.length; i++) {
      expect(itemValues(afterItems[i]), itemValues(beforeItems[i]));
      expect(afterItems[i].foodId, fixtureId(1));
    }
    expect(
      (await h.db.select(h.db.savedMealItems).get())
          .where((r) => r.id == deadItem.id)
          .single,
      deadItem,
    );
    expect(beforeEntries.any((r) => r.editedByUser), isTrue);
    expect(beforeItems.any((r) => r.editedByUser), isTrue);
    expect((await h.row(2)).deletedAt, isNotNull);
    expect(jsonDecode((await h.row(1)).aliasesJson!), ['B']);
    expect(
      await (h.db.select(
        h.db.diaryEntries,
      )..where((t) => t.id.equals(dead.id))).getSingle(),
      dead,
    );
    expect(a.events.whereType<EntryChanged>().single.entryIds.toSet(), {
      fixtureId(10),
      fixtureId(11),
    });
  });
  test(
    'FD-073 merge Undo restores A, B and every relinked row exactly',
    () async {
      final h = PersonalHarness();
      await h.seed();
      final before = await h.state();
      final a = await h.apply(h.merge());
      await h.undo(a);
      expect(await h.state(), before);
    },
  );
  test('FD-073 an entry relinked by a merge and edited before Undo '
      '→ Undo conflicts and nothing is reverted', () async {
    final h = PersonalHarness();
    await h.seed();
    final a = await h.apply(h.merge());
    await h.apply([
      UpdateDiaryEntry(
        fixtureId(10),
        2,
        EntryPatch(
          amount: EntryAmount(
            input: Quantity(200, 'g'),
            amount: 200,
            basis: NutrientBasis.per100g,
          ),
        ),
      ),
    ]);
    await h.conflict(a);
  });
  test('FD-073 a saved item relinked by a merge and changed before '
      'Undo (the meal deleted) → Undo conflicts and nothing is '
      'reverted', () async {
    final h = PersonalHarness();
    await h.seed();
    final a = await h.apply(h.merge());
    await h.apply([DeleteSavedMeal(fixtureId(3), 1)]);
    await h.conflict(a);
  });
  test('FD-073 merge rejects (nothing written): the same food, a '
      'stale version of either, different bases, too many '
      'aliases/barcodes/servings', () async {
    final h = PersonalHarness();
    await h.seed();
    expect(
      await h.reject([
        MergePersonalFoods(
          survivor: VersionedId(fixtureId(1), 1),
          merged: VersionedId(fixtureId(1), 1),
        ),
      ]),
      isA<InvalidOp>(),
    );
    expect(await h.reject(h.merge(av: 2)), isA<VersionConflict>());
    expect(await h.reject(h.merge(bv: 2)), isA<VersionConflict>());
    await h.apply([
      UpdatePersonalFood(
        fixtureId(2),
        1,
        draft('B', basis: NutrientBasis.per100ml),
      ),
    ]);
    expect(await h.reject(h.merge(bv: 2)), isA<InvalidOp>());
    await h.apply([UpdatePersonalFood(fixtureId(2), 2, draft('B'))]);
    String gtin(int i) {
      final s = i.toString().padLeft(7, '0');
      var sum = 0;
      for (var j = 0; j < 7; j++) {
        sum += int.parse(s[6 - j]) * (j.isEven ? 3 : 1);
      }
      return '$s${(10 - sum % 10) % 10}';
    }

    for (final (a, b) in [
      (draft('A', aliases: List.generate(30, (i) => 'alias$i')), draft('B')),
      (
        draft('A', barcodes: List.generate(10, gtin)),
        draft('B', barcodes: [gtin(10)]),
      ),
      (
        draft(
          'A',
          servings: PersonalFoodBounds.units
              .take(10)
              .map((u) => PersonalFoodServing(u, 1))
              .toList(),
        ),
        draft(
          'B',
          servings: [PersonalFoodServing(PersonalFoodBounds.units.last, 1)],
        ),
      ),
    ]) {
      final av = (await h.row(1)).version;
      final bv = (await h.row(2)).version;
      await h.apply([
        UpdatePersonalFood(fixtureId(1), av, a),
        UpdatePersonalFood(fixtureId(2), bv, b),
      ]);
      expect(
        await h.reject(
          h.merge(av: (await h.row(1)).version, bv: (await h.row(2)).version),
        ),
        isA<InvalidOp>().having((e) => e.code, 'code', 'tooMany'),
      );
    }
  });
  test('a change set whose second op fails (RelinkFoodRefs rejects '
      'after MergePersonalFoods planned) writes no row and no '
      'outbox row', () async {
    final h = PersonalHarness(failRelink: true);
    await h.seed();
    expect(
      await h.reject(h.merge()),
      isA<InvalidOp>().having((e) => e.code, 'code', 'injectedFailure'),
    );
  });
  test('RelinkFoodRefs touches only live rows with that kind and '
      'id; none → no write', () async {
    final h = PersonalHarness();
    await h.seed(entries: 3);
    await h.apply([
      LogEntries([
        newEntry(20, ref: FoodRef.catalog(fixtureId(2), version: 'old')),
      ]),
      DeleteEntries([VersionedId(fixtureId(12), 1)]),
    ]);
    final catalog = await (h.db.select(
      h.db.diaryEntries,
    )..where((t) => t.id.equals(fixtureId(20)))).getSingle();
    final stateBefore = await h.state();
    final applied = await h.apply([
      RelinkFoodRefs(
        from: FoodRef.personal(fixtureId(2)),
        to: FoodRef.personal(fixtureId(1)),
      ),
    ]);
    expect(
      await (h.db.select(
        h.db.diaryEntries,
      )..where((t) => t.id.equals(catalog.id))).getSingle(),
      catalog,
    );
    final before = await h.raw();
    await h.apply([
      RelinkFoodRefs(
        from: FoodRef.personal(fixtureId(2)),
        to: FoodRef.personal(fixtureId(1)),
      ),
    ]);
    expect(await h.raw(), before);
    await h.undo(applied);
    expect(await h.state(), stateBefore);
  });
  test('FD-073 RequirePersonalFood with LogEntries: the food '
      'edited, deleted or merged away after it was shown → '
      'rejected, no entry and no outbox row', () async {
    for (final kind in ['edit', 'delete', 'merge']) {
      final h = PersonalHarness();
      await h.seed();
      if (kind == 'edit') {
        await h.apply([UpdatePersonalFood(fixtureId(2), 1, draft('Changed'))]);
      } else if (kind == 'delete') {
        await h.apply([DeletePersonalFood(VersionedId(fixtureId(2), 1))]);
      } else {
        await h.apply(h.merge());
      }
      expect(
        await h.reject([
          RequirePersonalFood(VersionedId(fixtureId(2), 1)),
          LogEntries([newEntry(50, ref: FoodRef.personal(fixtureId(2)))]),
        ]),
        kind == 'edit' ? isA<VersionConflict>() : isA<RowNotFound>(),
      );
    }
    final h = PersonalHarness();
    await h.seed();
    final before = await h.raw();
    final guarded = await h.apply([
      RequirePersonalFood(VersionedId(fixtureId(2), 1)),
    ]);
    expect(await h.raw(), before);
    await h.undo(guarded);
    expect(await h.raw(), before);
  });
  test('FD-073 the survivor of a merge shown before the merge → '
      'VersionConflict, nothing written', () async {
    final h = PersonalHarness();
    await h.seed();
    await h.apply(h.merge());
    expect(
      await h.reject([
        RequirePersonalFood(VersionedId(fixtureId(1), 1)),
        LogEntries([newEntry(50)]),
      ]),
      isA<VersionConflict>(),
    );
  });
  test("DY-031 LogSavedMeal copies each item's columns exactly "
      '(snapshot, source, edited_by_user, input) in sort order '
      'into the chosen slot; one Undo removes them all', () async {
    final h = PersonalHarness();
    await h.seed();
    final items = await h.liveItems();
    await h.write([
      UpdateRow(
        h.db.savedMealItems,
        items.first.id,
        const SavedMealItemsCompanion(
          editedByUser: Value(true),
          per100ExtrasJson: Value('{ "sugar" : 1.300 }'),
          extrasJson: Value('{ "sugar" : 1.950 }'),
          inputUnit: Value('piece'),
          inputAmount: Value(2),
        ),
      ),
    ]);
    final sources = await h.liveItems();
    final before = await h.state();
    final v = await h.versions();
    final command = h.log(v);
    final a = await h.apply([
      LogSavedMeal(
        expected: SavedMealVersions(meal: v.meal, items: v.items.reversed),
        entryIds: command.entryIds,
        when: command.when,
        slotId: command.slotId,
      ),
    ]);
    final entries =
        await (h.db.select(h.db.diaryEntries)
              ..where((t) => t.id.isIn([fixtureId(2000), fixtureId(2001)]))
              ..orderBy([(t) => OrderingTerm(expression: t.id)]))
            .get();
    expect(entries.length, sources.length);
    for (var i = 0; i < sources.length; i++) {
      expect(entryValues(entries[i]), itemValues(sources[i]));
      expect(entries[i].dishGroupId, isNull);
      expect(entries[i].slotId, DefaultSlots.all.first.id);
    }
    await h.undo(a);
    expect(await h.state(), before);
  });
  test("DY-031 LogSavedMeal on a past day uses the slot's default "
      'time; a future day → futureDate', () async {
    final h = PersonalHarness();
    await h.seed();
    final v = await h.versions();
    final past = LocalDate(2026, 10, 16);
    await h.apply([h.log(v, when: EntryWhen.onDay(past))]);
    final row = await (h.db.select(
      h.db.diaryEntries,
    )..where((t) => t.id.equals(fixtureId(2000)))).getSingle();
    expect(row.localDate, '$past');
    expect(
      EntryTime(
        DateTime.fromMillisecondsSinceEpoch(row.occurredAtUtc, isUtc: true),
        row.tzOffsetMin,
      ).localDateTime.minuteOfDay,
      DefaultSlots.all.first.defaultTime.minuteOfDay,
    );
    expect(
      await h.reject([
        h.log(v, when: EntryWhen.onDay(LocalDate(2026, 10, 18))),
      ]),
      isA<InvalidOp>().having((e) => e.code, 'code', 'futureDate'),
    );
  });
  test('DY-031 LogSavedMeal rejects with nothing written when, '
      'between display and apply, the meal is renamed '
      '(VersionConflict), deleted (RowNotFound), an item is added '
      'or removed (sourceChanged), or an item is relinked by a '
      'merge (VersionConflict)', () async {
    for (final kind in ['rename', 'delete', 'add', 'remove', 'relink']) {
      final h = PersonalHarness();
      await h.seed();
      final v = await h.versions();
      final items = await h.liveItems();
      switch (kind) {
        case 'rename':
          await h.apply([RenameSavedMeal(fixtureId(3), 1, 'New')]);
        case 'delete':
          await h.apply([DeleteSavedMeal(fixtureId(3), 1)]);
        case 'add':
          await h.write([
            InsertRow(
              h.db.savedMealItems,
              RawValuesInsertable<SavedMealItemRow>({
                for (final e in items.first.toColumns(false).entries)
                  if (!{
                    'created_at',
                    'updated_hlc',
                    'version',
                    'device_id',
                    'origin',
                    'deleted_at',
                  }.contains(e.key))
                    e.key: e.key == 'id' ? Variable(fixtureId(900)) : e.value,
              }),
            ),
          ]);
        case 'remove':
          await h.write([TombstoneRow(h.db.savedMealItems, items.first.id)]);
        case 'relink':
          await h.apply(h.merge());
      }
      final failure = await h.reject([h.log(v)]);
      expect(failure, switch (kind) {
        'rename' || 'relink' => isA<VersionConflict>(),
        'delete' => isA<RowNotFound>(),
        _ => isA<InvalidOp>().having((e) => e.code, 'code', 'sourceChanged'),
      });
    }
  });
  test('DY-031 LogSavedMeal on a meal whose live items are all gone '
      '→ emptySource, nothing written', () async {
    final h = PersonalHarness();
    await h.seed();
    final v = await h.versions();
    await h.write([
      for (final item in await h.liveItems())
        TombstoneRow(h.db.savedMealItems, item.id),
    ]);
    expect(
      await h.reject([h.log(v)]),
      isA<InvalidOp>().having((e) => e.code, 'code', 'emptySource'),
    );
  });
  test('DY-031 RenameSavedMeal trims to 1–60 characters; a stale '
      'version → conflict; Undo restores the name', () async {
    final h = PersonalHarness();
    await h.seed();
    final before = await h.state();
    final a = await h.apply([RenameSavedMeal(fixtureId(3), 1, '  New name  ')]);
    expect((await h.db.select(h.db.savedMeals).get()).single.name, 'New name');
    expect(
      await h.reject([RenameSavedMeal(fixtureId(3), 1, 'Other')]),
      isA<VersionConflict>(),
    );
    final raw = await h.raw();
    await h.apply([RenameSavedMeal(fixtureId(3), 2, 'New name')]);
    expect(await h.raw(), raw);
    await h.undo(a);
    expect(await h.state(), before);
  });
  test('DY-031 DeleteSavedMeal tombstones the meal and its live '
      'items; Undo revives all', () async {
    final h = PersonalHarness();
    await h.seed();
    final before = await h.state();
    final a = await h.apply([DeleteSavedMeal(fixtureId(3), 1)]);
    expect(await h.liveItems(), isEmpty);
    expect(
      (await h.db.select(h.db.savedMeals).get()).single.deletedAt,
      isNotNull,
    );
    await h.undo(a);
    expect(await h.state(), before);
  });
  test('malformed stored JSON in a personal food row surfaces a '
      'typed error without content', () async {
    final h = PersonalHarness();
    await h.apply([CreatePersonalFood(fixtureId(1), draft('Private canary'))]);
    final row = await h.row(1);
    for (final bad in ['{private-canary', '{}', '[3]']) {
      expect(
        () => personalFoodOf(row.copyWith(aliasesJson: Value(bad))),
        throwsA(
          isA<PersonalFoodMappingError>().having(
            (e) => e.toString(),
            'redacted',
            'PersonalFoodMappingError',
          ),
        ),
      );
    }
    for (final changed in [
      row.copyWith(barcodesJson: const Value('["bad"]')),
      row.copyWith(servingsJson: const Value('[{"unit":"piece","amount":0}]')),
      row.copyWith(servingsJson: const Value('{}')),
      row.copyWith(servingsJson: const Value('[{}]')),
      row.copyWith(per100ExtrasJson: const Value('[]')),
      row.copyWith(
        per100ExtrasJson: const Value('{"sodium":"private-canary"}'),
      ),
      row.copyWith(basis: 'unknown'),
      row.copyWith(entryServingUnit: const Value('piece')),
      row.copyWith(entryServingAmount: const Value(30)),
      row.copyWith(per100Kcal: -1),
    ]) {
      expect(
        () => personalFoodOf(changed),
        throwsA(isA<PersonalFoodMappingError>()),
      );
    }
    expect(
      () => personalFoodOf(row.copyWith(aliasesJson: Value(' ' * 16385))),
      throwsA(isA<PersonalFoodMappingError>()),
    );
    final definition = PersonalFoodDraft(
      names: FoodNames('Structured'),
      per100: Nutrients(
        kcal: 1,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        extras: {NutrientKey.sodium: 10},
      ),
      servings: [PersonalFoodServing('cup', 30)],
      entryServing: PersonalFoodServing('cup', 30),
      barcodes: ['96385074'],
    );
    final update = await h.apply([
      UpdatePersonalFood(fixtureId(1), 1, definition),
    ]);
    expect(personalFoodOf(await h.row(1)).draft, definition);
    await h.undo(update);
    final repo = PersonalFoodRepository(h.db);
    expect((await repo.byId(fixtureId(1)))!.draft.names.en, 'Private canary');
    expect(await repo.byId(fixtureId(999)), isNull);
    expect((await repo.watchAll().first).length, 1);
    expect((await repo.watchFood(fixtureId(1)).first)!.version, 3);
    final stream = repo.watchAll().asBroadcastStream();
    final initial = stream.first;
    expect((await initial).length, 1);
    final next = stream.firstWhere((v) => v.single.draft.names.en == 'Changed');
    await h.apply([UpdatePersonalFood(fixtureId(1), 3, draft('Changed'))]);
    expect((await next).single.draft.names.en, 'Changed');
  });
  test('A09 perf merge relinking 1,000 entries and 50 saved items '
      'applies in < 300 ms (host, p95 of 20, printed)', () async {
    final samples = <int>[];
    for (var i = 0; i < 20; i++) {
      final h = PersonalHarness();
      await h.seed(entries: 1000, items: 50);
      final timer = Stopwatch()..start();
      await h.apply(h.merge());
      timer.stop();
      samples.add(timer.elapsedMicroseconds);
    }
    samples.sort();
    final p95 = samples[18] / 1000;
    stdout.writeln(
      'A09 merge p95: $p95 ms (20 runs, 1000 entries + 50 saved items)',
    );
    expect(p95, lessThan(300));
  });
  test('DY-031 LogSavedMeal keeps explicit instants and rejects '
      'unusable slots without writes', () async {
    final h = PersonalHarness();
    await h.seed();
    final v = await h.versions();
    final instant = EntryTime(DateTime.utc(2026, 10, 16, 17), 180);
    final a = await h.apply([h.log(v, when: EntryWhen.at(instant))]);
    final row = await (h.db.select(
      h.db.diaryEntries,
    )..where((t) => t.id.equals(fixtureId(2000)))).getSingle();
    expect(row.occurredAtUtc, instant.occurredAtUtc.millisecondsSinceEpoch);
    expect(row.tzOffsetMin, 180);
    await h.undo(a);
    expect(
      await h.reject([h.log(v, slotId: fixtureId(999))]),
      isA<InvalidOp>().having((e) => e.code, 'code', 'unknownSlot'),
    );
    await h.write([
      UpdateRow(
        h.db.mealSlots,
        DefaultSlots.all.first.id,
        const MealSlotsCompanion(active: Value(false)),
      ),
    ]);
    expect(
      await h.reject([h.log(v)]),
      isA<InvalidOp>().having((e) => e.code, 'code', 'inactiveSlot'),
    );
    final command = h.log(v);
    await h.write([
      for (final slot in DefaultSlots.all.skip(1))
        UpdateRow(
          h.db.mealSlots,
          slot.id,
          const MealSlotsCompanion(active: Value(false)),
        ),
    ]);
    expect(
      await h.reject([
        LogSavedMeal(
          expected: v,
          entryIds: command.entryIds,
          when: EntryWhen.at(instant),
        ),
      ]),
      isA<InvalidOp>().having((e) => e.code, 'code', 'noSlot'),
    );
  });
  test('FD-070 SQL checks reject half entry servings and negative values '
      'atomically', () async {
    final h = PersonalHarness();
    await h.apply([CreatePersonalFood(fixtureId(1), draft('Check'))]);
    for (final changes in [
      const PersonalFoodsCompanion(entryServingUnit: Value('piece')),
      const PersonalFoodsCompanion(entryServingAmount: Value(30)),
      const PersonalFoodsCompanion(per100Kcal: Value(-1)),
      const PersonalFoodsCompanion(basis: Value('unknown')),
    ]) {
      expect(
        await h.reject([
          ScriptOp.rows([UpdateRow(h.db.personalFoods, fixtureId(1), changes)]),
        ]),
        isA<ConstraintViolation>(),
      );
    }
  });
  test(
    'FD-071 stored sanity failures remain readable, updatable and mergeable',
    () async {
      final h = PersonalHarness();
      await h.seed();
      await h.write([
        UpdateRow(
          h.db.personalFoods,
          fixtureId(1),
          const PersonalFoodsCompanion(
            per100Kcal: Value(424),
            per100ProteinG: Value(106),
          ),
        ),
      ]);
      final repo = PersonalFoodRepository(h.db);
      final stored = (await repo.watchAll().first).firstWhere(
        (f) => f.id == fixtureId(1),
      );
      expect(stored.sanity.reason, SanityReason.macrosTooHeavy);
      final renamed = PersonalFoodDraft(
        names: FoodNames('Renamed'),
        per100: stored.per100,
      );
      await h.apply([UpdatePersonalFood(stored.id, stored.version, renamed)]);
      final updated = (await repo.byId(stored.id))!;
      expect(updated.names.en, 'Renamed');
      expect(updated.per100, stored.per100);
      final merge = await h.apply(h.merge(av: updated.version));
      expect((await repo.byId(stored.id))!.per100, stored.per100);
      await h.undo(merge);
      expect((await repo.byId(stored.id))!.per100, stored.per100);
      expect(
        await h.reject([
          UpdatePersonalFood(
            stored.id,
            (await repo.byId(stored.id))!.version,
            PersonalFoodDraft(
              names: FoodNames('Changed numbers'),
              per100: Nutrients(
                kcal: 428,
                protein: 107,
                carbs: 0,
                fat: 0,
                fiber: 0,
              ),
            ),
          ),
        ]),
        isA<InvalidOp>(),
      );
    },
  );
  test('FD-071 corrupt personal rows do not hide readable rows', () async {
    final h = PersonalHarness();
    await h.seed();
    await h.apply([CreatePersonalFood(fixtureId(4), draft('Out of bounds'))]);
    await h.write([
      UpdateRow(
        h.db.personalFoods,
        fixtureId(1),
        const PersonalFoodsCompanion(aliasesJson: Value('{private-corrupt')),
      ),
      UpdateRow(
        h.db.personalFoods,
        fixtureId(4),
        const PersonalFoodsCompanion(per100ProteinG: Value(1001)),
      ),
    ]);
    final repo = PersonalFoodRepository(h.db);
    expect((await repo.watchAll().first).map((f) => f.id), [fixtureId(2)]);
    expect(await repo.byId(fixtureId(1)), isNull);
    expect(await repo.watchFood(fixtureId(4)).first, isNull);
  });
  test(
    'FD-071 unknown extras and state survive personal-food rewrites',
    () async {
      final h = PersonalHarness();
      await h.seed();
      const raw = '{ "future_nutrient" : 1.2300, "sodium" : 10.00 }';
      await h.write([
        UpdateRow(
          h.db.personalFoods,
          fixtureId(1),
          const PersonalFoodsCompanion(
            per100ExtrasJson: Value(raw),
            state: Value('future_state'),
          ),
        ),
      ]);
      final repo = PersonalFoodRepository(h.db);
      final stored = (await repo.byId(fixtureId(1)))!;
      expect(stored.state, FoodState.asSold);
      expect(stored.per100.extra(NutrientKey.sodium), 10);
      final renamed = PersonalFoodDraft(
        names: FoodNames('Renamed'),
        per100: stored.per100,
      );
      await h.apply([UpdatePersonalFood(stored.id, stored.version, renamed)]);
      expect((await h.row(1)).per100ExtrasJson, raw);
      expect((await h.row(1)).state, 'future_state');
      await h.apply(h.merge(av: (await h.row(1)).version));
      expect((await h.row(1)).per100ExtrasJson, raw);
      expect((await h.row(1)).state, 'future_state');
      final current = (await repo.byId(stored.id))!;
      await h.apply([
        UpdatePersonalFood(
          stored.id,
          current.version,
          PersonalFoodDraft(
            names: current.names,
            per100: Nutrients(
              kcal: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              fiber: 0,
              extras: {NutrientKey.sodium: 20},
            ),
          ),
        ),
      ]);
      expect(jsonDecode((await h.row(1)).per100ExtrasJson!), {
        'future_nutrient': 1.23,
        'sodium': 20,
      });
    },
  );
  test('FD-073 RelinkFoodRefs requires a live personal destination', () async {
    final h = PersonalHarness();
    await h.seed();
    final from = FoodRef.personal(fixtureId(2));
    expect(
      await h.reject([
        RelinkFoodRefs(from: from, to: FoodRef.personal(fixtureId(999))),
      ]),
      isA<RowNotFound>(),
    );
    await h.apply([DeletePersonalFood(VersionedId(fixtureId(1), 1))]);
    expect(
      await h.reject([
        RelinkFoodRefs(from: from, to: FoodRef.personal(fixtureId(1))),
      ]),
      isA<RowNotFound>(),
    );
  });
  test(
    'DY-031 LogSavedMeal redacts malformed extras and negative stored values',
    () async {
      for (final corrupt in [
        const SavedMealItemsCompanion(extrasJson: Value('{private-extras')),
        const SavedMealItemsCompanion(per100ProteinG: Value(-1)),
      ]) {
        final h = PersonalHarness();
        await h.seed();
        final item = (await h.liveItems()).first;
        await h.write([UpdateRow(h.db.savedMealItems, item.id, corrupt)]);
        final versions = await h.versions();
        final failure = await h.reject([h.log(versions)]);
        expect(failure, const InvalidOp('invalidSource'));
        expect(failure.toString(), 'InvalidOp(invalidSource)');
      }
    },
  );
  test('DY-031 LogSavedMeal rejects a same-count item replacement '
      'as sourceChanged', () async {
    final h = PersonalHarness();
    await h.seed();
    final versions = await h.versions();
    final item = (await h.liveItems()).first;
    await h.write([
      TombstoneRow(h.db.savedMealItems, item.id),
      InsertRow(
        h.db.savedMealItems,
        RawValuesInsertable<SavedMealItemRow>({
          for (final e in item.toColumns(false).entries)
            if (!{
              'created_at',
              'updated_hlc',
              'version',
              'device_id',
              'origin',
              'deleted_at',
            }.contains(e.key))
              e.key: e.key == 'id' ? Variable(fixtureId(900)) : e.value,
        }),
      ),
    ]);
    expect((await h.liveItems()).length, versions.items.length);
    expect(await h.reject([h.log(versions)]), const InvalidOp('sourceChanged'));
  });
}
