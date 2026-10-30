import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_fixtures.dart';

final LocalDate _day = LocalDate(2026, 10, 17);
const String _lunch = DefaultSlots.lunchId;

void main() {
  test('DY-010 watchSlots lists the four default slots by sort order, '
      'with their windows', () async {
    final repo = DiaryRepository(memoryDatabase());
    final slots = await repo.watchSlots().first;
    expect(slots, DefaultSlots.all);
  });

  test('DY-001 watchDay returns the day: entries by time, groups, mark, '
      'and excludes tombstoned rows and other days', () async {
    final db = memoryDatabase();
    final repo = DiaryRepository(db);
    await insertEntries(db, [
      entryRow(2, date: '2026-10-17', slotId: _lunch, occurredAtUtc: 2000),
      entryRow(1, date: '2026-10-17', slotId: _lunch, occurredAtUtc: 1000),
      entryRow(3, date: '2026-10-17', slotId: _lunch, deletedAt: 9),
      entryRow(4, date: '2026-10-18', slotId: _lunch),
    ]);
    final day = await repo.watchDay(_day).first;
    expect(day.entries.map((e) => e.id), [fixtureId(1), fixtureId(2)]);
    expect(day.slots, hasLength(4));
    expect(day.groups, isEmpty);
    expect(day.mark, isNull);
    expect(day.toString(), isNot(contains('Food')));
  });

  test('DY-004 watchDay includes the day mark and the dish groups', () async {
    final db = memoryDatabase();
    await runAuthorizedWrite(() async {
      await db
          .into(db.dayMarks)
          .insert(
            DayMarksCompanion.insert(
              id: fixtureId(50),
              createdAt: 1,
              updatedHlc: hlcAt(1),
              version: 1,
              deviceId: testDevice,
              origin: 'direct',
              localDate: '2026-10-17',
              incomplete: true,
            ),
          );
      await db
          .into(db.dishGroups)
          .insert(
            DishGroupsCompanion.insert(
              id: fixtureId(60),
              createdAt: 1,
              updatedHlc: hlcAt(1),
              version: 1,
              deviceId: testDevice,
              origin: 'direct',
              name: 'Maqluba',
              localDate: '2026-10-17',
              slotId: _lunch,
            ),
          );
    });
    final day = await DiaryRepository(db).watchDay(_day).first;
    expect(day.mark, DayMark(localDate: _day, incomplete: true));
    expect(day.groups.single.name, 'Maqluba');
    expect(day.groups.single.slotId, _lunch);
  });

  test('DY-001 watchDay emits again after a write, and after a tombstone '
      'drops the entry', () async {
    final db = memoryDatabase();
    final repo = DiaryRepository(db);
    final counts = <int>[];
    final sub = repo.watchDay(_day).listen((d) => counts.add(d.entries.length));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await insertEntries(db, [entryRow(1, date: '2026-10-17', slotId: _lunch)]);
    await pumpEventQueue();
    await tombstoneEntry(db, 1);
    await pumpEventQueue();
    expect(counts, [0, 1, 0]);
  });

  test('FD-010 / SC-4 provenance, estimate range, assumptions, extras and '
      'both names are read back; an unknown kind and source read as '
      'estimates', () async {
    final db = memoryDatabase();
    await insertEntries(db, [
      entryRow(
        1,
        date: '2026-10-17',
        slotId: _lunch,
        foodKind: 'estimate',
        source: 'estimate',
        isEstimate: true,
        estimateRangeJson: '{"lowKcal": 300, "highKcal": 500}',
        assumptionsJson: '["a plate", "olive oil"]',
        extrasJson: '{"sugar": 2.5, "nonsense": 1}',
      ),
      entryRow(
        2,
        date: '2026-10-17',
        slotId: _lunch,
        foodKind: 'batch',
        source: 'newer',
      ),
    ]);
    final entries = (await DiaryRepository(db).watchDay(_day).first).entries;
    final estimate = entries.first;
    expect(estimate.food.ref.kind, FoodRefKind.estimate);
    expect(estimate.food.ref.id, isNull);
    expect(estimate.food.provenance.source, FoodSource.estimate);
    expect(estimate.food.provenance.range, EstimateRange(300, 500));
    expect(estimate.food.provenance.assumptions, ['a plate', 'olive oil']);
    expect(estimate.snapshot.extras, {NutrientKey.sugar: 2.5});
    expect(estimate.food.names, FoodNames('Food 1', ar: 'طعام'));
    final unknown = entries.last;
    expect(unknown.food.ref.kind, FoodRefKind.estimate);
    expect(unknown.food.ref.id, 'food-2');
    expect(unknown.food.provenance.isEstimate, isTrue);
  });

  test('DY-002 an entry keeps its stored offset: local date and time come '
      'from it', () async {
    final db = memoryDatabase();
    // 23:30 local at +03:00 on the 17th = 20:30 UTC.
    await insertEntries(db, [
      entryRow(
        1,
        date: '2026-10-17',
        slotId: DefaultSlots.dinnerId,
        occurredAtUtc: DateTime.utc(
          2026,
          10,
          17,
          20,
          30,
        ).millisecondsSinceEpoch,
        tzOffsetMin: 180,
      ),
    ]);
    final entry = (await DiaryRepository(
      db,
    ).watchDay(_day).first).entries.single;
    expect(entry.time.localDate, _day);
    expect(entry.time.tzOffsetMin, 180);
    expect(entry.localDate, _day);
  });

  test('DY-021 watchSlot returns only that slot on that day', () async {
    final db = memoryDatabase();
    await insertEntries(db, [
      entryRow(1, date: '2026-10-17', slotId: _lunch),
      entryRow(2, date: '2026-10-17', slotId: DefaultSlots.dinnerId),
      entryRow(3, date: '2026-10-18', slotId: _lunch),
    ]);
    final entries = await DiaryRepository(db).watchSlot(_day, _lunch).first;
    expect(entries.map((e) => e.id), [fixtureId(1)]);
  });

  test('DY-021 watchEntries(range) is ordered by local_date, occurred_at_utc '
      'and leaves out days outside the range', () async {
    final db = memoryDatabase();
    await insertEntries(db, [
      entryRow(1, date: '2026-10-18', slotId: _lunch, occurredAtUtc: 1),
      entryRow(2, date: '2026-10-17', slotId: _lunch, occurredAtUtc: 9),
      entryRow(3, date: '2026-10-17', slotId: _lunch, occurredAtUtc: 5),
      entryRow(4, date: '2026-10-19', slotId: _lunch),
    ]);
    final entries = await DiaryRepository(db)
        .watchEntries(_day, LocalDate(2026, 10, 18))
        .first;
    expect(entries.map((e) => e.id), [
      fixtureId(3),
      fixtureId(2),
      fixtureId(1),
    ]);
  });

  test('DY-021 watchDailyTotals equals DiaryTotals.day for the same rows, '
      'per day, without tombstoned rows', () async {
    final db = memoryDatabase();
    await insertEntries(db, [
      entryRow(
        1,
        date: '2026-10-17',
        slotId: _lunch,
        kcal: 123.45,
        protein: 0.1,
      ),
      entryRow(2, date: '2026-10-17', slotId: _lunch, kcal: 0.2, protein: 0.2),
      entryRow(3, date: '2026-10-17', slotId: _lunch, kcal: 7, deletedAt: 4),
      entryRow(4, date: '2026-10-18', slotId: _lunch, kcal: 50),
    ]);
    final repo = DiaryRepository(db);
    final totals = await repo
        .watchDailyTotals(_day, LocalDate(2026, 10, 18))
        .first;
    final entries = (await repo.watchDay(_day).first).entries;
    expect(totals.map((t) => (t.date, t.entryCount)), [
      (_day, 2),
      (LocalDate(2026, 10, 18), 1),
    ]);
    // Two entries in one meal: one meal (A38 D3, DY-004).
    expect(totals.map((t) => t.mealCount), [1, 1]);
    final expected = DiaryTotals.day(entries);
    final actual = totals.first.totals;
    expect(actual.kcal, expected.kcal);
    expect(actual.protein, expected.protein);
    expect(actual.carbs, expected.carbs);
    expect(actual.fat, expected.fat);
    expect(actual.fiber, expected.fiber);
  });

  test('DY-004 watchDayMarks lists the marks in a range', () async {
    final db = memoryDatabase();
    await runAuthorizedWrite(
      () => db
          .into(db.dayMarks)
          .insert(
            DayMarksCompanion.insert(
              id: fixtureId(50),
              createdAt: 1,
              updatedHlc: hlcAt(1),
              version: 1,
              deviceId: testDevice,
              origin: 'direct',
              localDate: '2026-10-17',
              incomplete: false,
              notFasting: const Value(true),
            ),
          ),
    );
    final marks = await DiaryRepository(db)
        .watchDayMarks(_day, LocalDate(2026, 10, 18))
        .first;
    expect(marks, [
      DayMark(localDate: _day, incomplete: false, notFasting: true),
    ]);
  });
}
