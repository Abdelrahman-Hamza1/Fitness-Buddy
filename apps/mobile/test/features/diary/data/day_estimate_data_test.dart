import 'package:drift/drift.dart' show Value, Variable;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_inputs.dart';
import 'package:fb_mobile/features/diary/data/diary_op_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart' show ScriptOp;
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

const String _lunch = DefaultSlots.lunchId;
const String _dinner = DefaultSlots.dinnerId;

/// Tuesday before the harness's Saturday "today".
final LocalDate _tue = LocalDate(2026, 10, 13);

SetDayEstimate _create(double kcal, {int? version, LocalDate? date}) =>
    SetDayEstimate(
      date ?? _tue,
      kcal: kcal,
      expectedVersion: version,
      expectEstimate: false,
    );

SetDayEstimate _edit(double? kcal, int version) => SetDayEstimate(
  _tue,
  kcal: kcal,
  expectedVersion: version,
  expectEstimate: true,
);

Future<DayMarkRow?> _mark(DiaryHarness h, [LocalDate? date]) => (h.db.select(
  h.db.dayMarks,
)..where((t) => t.id.equals(dayMarkRowId(date ?? _tue)))).getSingleOrNull();

/// A harness whose Tuesday holds a 2,300 kcal day estimate (mark v1).
Future<DiaryHarness> _estimated() async {
  final h = DiaryHarness();
  await h.apply([_create(2300)]);
  return h;
}

void main() {
  group('DY-006 SetDayEstimate (A62 D12)', () {
    test('DY-006 SetDayEstimate create on an empty past day; rejects '
        'today/future, out of range, and a day that now has food', () async {
      final h = DiaryHarness();
      final applied = await h.apply([_create(2300)]);
      final mark = (await _mark(h))!;
      expect(
        (
          mark.estimateKcal,
          mark.incomplete,
          mark.notFasting,
          mark.estimateOnly,
          mark.version,
        ),
        (2300.0, false, false, true, 1),
      );
      expect(applied.events, contains(DayEstimateChanged(_tue)));

      final before = await h.state();
      for (final date in [today, today.plusDays(1)]) {
        expect(
          await h.reject([_create(2000, date: date)]),
          const InvalidOp('notPast'),
        );
      }
      for (final kcal in [0.5, 20001.0, double.nan]) {
        expect(
          await h.reject([_create(kcal, date: LocalDate(2026, 10, 12))]),
          const InvalidOp('outOfRange'),
        );
      }
      // Monday gets food first: the empty-day card was stale.
      final monday = LocalDate(2026, 10, 12);
      await h.apply([
        LogEntries([newEntry(1, when: atDay(monday), slotId: _lunch)]),
      ]);
      final withFood = await h.state();
      expect(
        await h.reject([_create(2000, date: monday)]),
        const InvalidOp('dayHasFood'),
      );
      expect(await h.state(), withFood);
      expect(before, isNot(withFood));
      // Undo of the create tombstones the mark it made (the tombstone
      // keeps its last values); live reads and totals show no estimate.
      await h.undo(applied);
      expect((await _mark(h))!.deletedAt, isNotNull);
      expect(await h.reads.markOn(_tue), isNull);
      expect(await h.reads.dailyTotals(_tue, _tue), isEmpty);
    });

    test('DY-006 stale create (an estimate appeared), stale edit (version '
        'moved), edit after remote clear → VersionConflict, nothing '
        'written', () async {
      final h = await _estimated();
      final start = await h.state();
      // Another view created it meanwhile: this one saw no mark.
      expect(await h.reject([_create(2100)]), isA<VersionConflict>());
      // A mark without an estimate at v1 is not this view's either.
      expect(
        await h.reject([_create(2100, version: 1)]),
        isA<VersionConflict>(),
      );
      expect(await h.state(), start);

      await h.apply([_edit(2400, 1)]);
      expect((await _mark(h))!.estimateKcal, 2400);
      final edited = await h.state();
      expect(await h.reject([_edit(2500, 1)]), isA<VersionConflict>());
      expect(await h.state(), edited);

      // Cleared elsewhere (the estimate-only mark is a tombstone at v3):
      // an edit that still sees the estimate fails.
      await h.apply([_edit(null, 2)]);
      final cleared = await h.state();
      expect(await h.reject([_edit(2500, 3)]), isA<VersionConflict>());
      expect(await h.reject([_edit(null, 3)]), isA<VersionConflict>());
      expect(await h.state(), cleared);
      // The same number writes nothing (the recreate revived it at v4).
      final same = await h.applier.apply(
        ChangeSet([_create(1900)], origin: Origin.direct),
      );
      expect(same, isA<Applied>());
      final unchanged = await h.applier.apply(
        ChangeSet([_edit(1900, 4)], origin: Origin.direct),
      );
      expect((unchanged as Applied).inverse.rows, isEmpty);
    });

    test('DY-006 clear then recreate; Undo of each; Undo after a synced '
        'remote edit conflicts instead of overwriting', () async {
      final h = await _estimated();
      final clear = await h.apply([_edit(null, 1)]);
      var mark = (await _mark(h))!;
      // The mark only held the estimate: back to no mark.
      expect(mark.deletedAt, isNotNull);
      expect(await h.reads.markOn(_tue), isNull);
      await h.undo(clear);
      mark = (await _mark(h))!;
      expect(
        (mark.estimateKcal, mark.deletedAt, mark.estimateOnly),
        (2300.0, null, true),
      );

      await h.apply([_edit(null, mark.version)]);
      final recreate = await h.apply([_create(1800)]);
      expect((await _mark(h))!.estimateKcal, 1800);
      await h.undo(recreate);
      expect(await h.reads.markOn(_tue), isNull);

      // A remote edit after the save: Undo refuses rather than overwrite.
      final save = await h.apply([_create(2200)]);
      await h.apply([
        ScriptOp.rows([
          UpdateRow(
            h.db.dayMarks,
            dayMarkRowId(_tue),
            const DayMarksCompanion(estimateKcal: Value(2700)),
          ),
        ]),
      ]);
      final result = await h.applier.revert(save.inverse);
      expect(result, isA<Rejected>());
      expect((result as Rejected).failure, isA<VersionConflict>());
      expect((await _mark(h))!.estimateKcal, 2700);
    });

    test(
      'DY-006 a tombstoned mark is revived by a create with default marks',
      () async {
        final h = DiaryHarness();
        await h.apply([MarkDay(_tue, incomplete: true)]);
        await h.apply([
          ScriptOp.rows([TombstoneRow(h.db.dayMarks, dayMarkRowId(_tue))]),
        ]);
        await h.apply([_create(2000)]);
        final mark = (await _mark(h))!;
        expect(
          (mark.deletedAt, mark.estimateKcal, mark.incomplete),
          (null, 2000.0, false),
        );
        expect(mark.estimateOnly, isTrue);
      },
    );
  });

  group('DY-006 food replaces the day estimate (A62 D12)', () {
    /// Applies [op] (built once the setup ran) on a harness whose Tuesday
    /// holds an estimate, checks the estimate is cleared in that change set
    /// with the food on Tuesday, and that one Undo restores both.
    Future<void> expectReplaces(
      String name,
      Future<void> Function(DiaryHarness h) setup,
      Future<ChangeOp> Function(DiaryHarness h) op,
    ) async {
      final h = await _estimated();
      await setup(h);
      final before = await h.state();
      final markVersion = (await _mark(h))!.version;
      final applied = await h.apply([await op(h)]);
      final mark = (await _mark(h))!;
      // The mark only held the estimate: it goes (one write), so the food
      // day isn't taken as confirmed complete (DY-004).
      expect(mark.deletedAt, isNotNull, reason: name);
      expect(await h.reads.markOn(_tue), isNull, reason: name);
      expect(mark.version, markVersion + 1, reason: '$name: one clear');
      expect(await h.reads.entriesOn(_tue), isNotEmpty, reason: name);
      expect(applied.events, contains(DayEstimateChanged(_tue)), reason: name);
      await h.undo(applied);
      expect(await h.state(), before, reason: '$name: one Undo');
      expect((await _mark(h))!.estimateKcal, 2300, reason: name);
    }

    test('DY-006 logging food (search, quick-add, saved meal, copy, move-in) '
        'on an estimated day clears it in the same change set; one Undo '
        'restores both', () async {
      Future<void> none(DiaryHarness h) async {}
      Future<void> todayFood(DiaryHarness h) => h.apply([
        LogEntries([newEntry(1, slotId: _lunch)]),
      ]);

      // Search, quick-add, barcode and Buddy confirm all log entries.
      await expectReplaces(
        'LogEntries',
        none,
        (_) async => LogEntries([
          newEntry(1, when: atDay(_tue), slotId: _lunch),
          newEntry(2, when: atDay(_tue, 19), slotId: _dinner),
        ]),
      );
      await expectReplaces(
        'MoveEntries',
        todayFood,
        (_) async => MoveEntries([VersionedId(fixtureId(1), 1)], toDate: _tue),
      );
      await expectReplaces(
        'UpdateDiaryEntry',
        todayFood,
        (_) async =>
            UpdateDiaryEntry(fixtureId(1), 1, EntryPatch(localDate: _tue)),
      );
      await expectReplaces(
        'CopyMeal',
        todayFood,
        (_) async => CopyMeal(
          MealSource.entries([fixtureId(1)]),
          toDate: _tue,
          copyIds: {fixtureId(1): newId(1)},
          expected: SourceVersions(entries: [VersionedId(fixtureId(1), 1)]),
        ),
      );
      await expectReplaces(
        'LogSavedMeal',
        (h) async {
          await todayFood(h);
          await h.apply([
            SaveMeal(
              savedMealId: newId(90),
              name: 'Usual',
              source: MealSource.entries([fixtureId(1)]),
              expected: SourceVersions(entries: [VersionedId(fixtureId(1), 1)]),
            ),
          ]);
        },
        (h) async {
          final meal = (await h.reads.savedMeal(newId(90)))!;
          return LogSavedMeal(
            expected: meal.versions!,
            entryIds: {for (final item in meal.items) item.id: newId(5)},
            when: atDay(_tue, 19),
            slotId: _dinner,
          );
        },
      );
    });

    test('DY-006 moves within a day, or onto a day without an estimate, '
        'leave the marks alone', () async {
      final h = await _estimated();
      await h.apply([
        LogEntries([newEntry(1, slotId: _lunch)]),
      ]);
      final markBefore = (await _mark(h))!;
      await h.apply([
        MoveEntries([VersionedId(fixtureId(1), 1)], toSlotId: _dinner),
      ]);
      await h.apply([
        MoveEntries([
          VersionedId(fixtureId(1), 2),
        ], toDate: LocalDate(2026, 10, 14)),
      ]);
      final markAfter = (await _mark(h))!;
      expect(markAfter.version, markBefore.version);
      expect(markAfter.estimateKcal, 2300);
    });

    test('DY-006 MoveDishGroup into an estimated day clears it once (two '
        'members, one date); one Undo restores group location and '
        'estimate', () async {
      final h = await _estimated();
      await h.apply([
        CreateDishGroup(
          id: fixtureId(50),
          name: 'Maqluba',
          date: today,
          slotId: _lunch,
        ),
        LogEntries([
          newEntry(1, group: 50, slotId: _lunch, when: atDay(today, 12)),
          newEntry(2, group: 50, slotId: _lunch, when: atDay(today, 12, 30)),
        ]),
      ]);
      final before = await h.state();
      final applied = await h.apply([
        MoveDishGroup(fixtureId(50), 1, toDate: _tue),
      ]);
      final mark = (await _mark(h))!;
      expect((mark.deletedAt != null, mark.version), (true, 2));
      expect(
        applied.inverse.rows.where((r) => r.table == h.db.dayMarks),
        hasLength(1),
      );
      expect((await h.group(50)).localDate, '$_tue');
      await h.undo(applied);
      expect(await h.state(), before);
      expect((await h.group(50)).localDate, '$today');
      expect((await _mark(h))!.estimateKcal, 2300);
    });
  });

  group('DY-006 the day intake projection (A62 D9, D13)', () {
    test('DY-006 a day estimate stands in for an empty day: kcal only, '
        'estimated, macros unknown; the mark streams through', () async {
      final h = await _estimated();
      final days = await h.reads.dailyTotals(_tue.plusDays(-1), today);
      final day = days.single;
      expect(day.date, _tue);
      expect(
        (day.entryCount, day.dayEstimate, day.hasDayEstimate),
        (0, true, true),
      );
      expect(day.intake, IntakeTotals.ofDayEstimate(2300));
      expect(day.intake.valueOf(NutrientField.protein), isNull);
      expect('$day', isNot(contains('2300')));
      final mark = await h.reads.markOn(_tue);
      expect((mark!.estimateKcal, mark.version), (2300.0, 1));
    });

    test('DY-006 deleting the last food on a day with a superseded estimate '
        'reactivates it; Undo of the delete supersedes it again', () async {
      final h = await _estimated();
      // Another device logged food on Tuesday offline (no clear here).
      await insertEntries(h.db, [
        entryRow(1, date: '$_tue', slotId: _lunch, kcal: 600),
      ]);
      var day = (await h.reads.dailyTotals(_tue, _tue)).single;
      expect(
        (day.entryCount, day.dayEstimate, day.hasDayEstimate),
        (1, false, true),
      );
      expect(day.intake.sum.kcal, 600);
      expect(day.intake.dayEstimate, isFalse);

      final delete = await h.apply([
        DeleteEntries([VersionedId(fixtureId(1), 1)]),
      ]);
      expect((await _mark(h))!.version, 1, reason: 'the mark is untouched');
      day = (await h.reads.dailyTotals(_tue, _tue)).single;
      expect((day.entryCount, day.dayEstimate), (0, true));
      expect(day.intake.sum.kcal, 2300);

      await h.undo(delete);
      day = (await h.reads.dailyTotals(_tue, _tue)).single;
      expect(
        (day.entryCount, day.dayEstimate, day.intake.sum.kcal),
        (1, false, 600.0),
      );
    });

    test('TG-032 intakeDaysOf excludes day-estimate days; meal estimates '
        'count', () async {
      final h = await _estimated();
      final wed = _tue.plusDays(1);
      final thu = _tue.plusDays(2);
      await h.apply([
        LogEntries([
          NewDiaryEntry(
            id: fixtureId(1),
            when: atDay(wed),
            slotId: _lunch,
            food: const UserEstimate(kcal: 700).food(),
            amount: UserEstimate.amount,
          ),
        ]),
      ]);
      // Thursday: food logged elsewhere over an estimate (superseded).
      await h.apply([_create(1500, date: thu)]);
      await insertEntries(h.db, [
        entryRow(2, date: '$thu', slotId: _lunch, kcal: 900),
      ]);
      final totals = await h.reads.dailyTotals(_tue, thu);
      final days = {
        for (final d in intakeDaysOf(
          totals: totals,
          marks: await h.reads.marksBetween(_tue, thu),
        ))
          d.date: d,
      };
      expect(days.keys, [_tue, wed, thu]);
      // Logged (toward the 14 days) but never complete (TG-031).
      expect((days[_tue]!.logged, days[_tue]!.incomplete), (true, true));
      expect(days[_tue]!.dayEstimate, isTrue);
      expect(days[thu]!.incomplete, isTrue);
      // A meal estimate is food: complete, its kcal counts.
      expect((days[wed]!.incomplete, days[wed]!.kcal), (false, 700.0));
    });
  });

  group('A62b review fixes: estimate-only marks', () {
    test('DY-006 create → Undo → MarkDay(incomplete) revives the mark '
        'without the undone estimate', () async {
      final h = DiaryHarness();
      final save = await h.apply([_create(2300)]);
      await h.undo(save);
      await h.apply([MarkDay(_tue, incomplete: true)]);
      final mark = (await _mark(h))!;
      expect(
        (mark.deletedAt, mark.incomplete, mark.estimateKcal, mark.estimateOnly),
        (null, true, null, false),
      );
      expect(await h.reads.dailyTotals(_tue, _tue), isEmpty);
    });

    test('DY-006 create → Undo → log food → mark incomplete → count again '
        '→ delete the last food: no estimate comes back', () async {
      final h = DiaryHarness();
      final save = await h.apply([_create(2300)]);
      await h.undo(save);
      await h.apply([
        LogEntries([newEntry(1, when: atDay(_tue), slotId: _lunch)]),
      ]);
      await h.apply([MarkDay(_tue, incomplete: true)]);
      await h.apply([MarkDay(_tue, incomplete: false)]);
      final mark = (await _mark(h))!;
      expect((mark.estimateKcal, mark.incomplete), (null, false));
      await h.apply([
        DeleteEntries([VersionedId(fixtureId(1), 1)]),
      ]);
      expect(await h.reads.dailyTotals(_tue, _tue), isEmpty);
    });

    test('DY-006 marking an estimated day keeps the estimate and makes the '
        "mark the user's own; clearing then keeps the mark", () async {
      final h = await _estimated();
      await h.apply([MarkDay(_tue, incomplete: true)]);
      var mark = (await _mark(h))!;
      expect(
        (mark.estimateKcal, mark.incomplete, mark.estimateOnly),
        (2300.0, true, false),
      );
      await h.apply([_edit(null, mark.version)]);
      mark = (await _mark(h))!;
      expect(
        (mark.deletedAt, mark.estimateKcal, mark.incomplete),
        (null, null, true),
      );
    });

    /// Tuesday as the adaptive estimate and DY-004 see it.
    Future<IntakeDay> tuesday(DiaryHarness h) async => intakeDaysOf(
      totals: await h.reads.dailyTotals(_tue, _tue),
      marks: await h.reads.marksBetween(_tue, _tue),
    ).single;

    test('DY-004 DY-006 replacing the estimate with food, or clearing it '
        'first, leaves an unconfirmed day: the incomplete-day suggestion '
        'still applies', () async {
      for (final clearFirst in [false, true]) {
        final h = await _estimated();
        if (clearFirst) await h.apply([_edit(null, 1)]);
        await h.apply([
          LogEntries([newEntry(1, when: atDay(_tue), slotId: _lunch)]),
        ]);
        final day = await tuesday(h);
        expect(
          (day.logged, day.incomplete, day.confirmed, day.mealCount),
          (true, false, false, 1),
          reason: 'clearFirst: $clearFirst',
        );
      }
    });

    test('DY-004 DY-006 a day the user confirmed (count again) stays '
        'confirmed when food replaces its estimate', () async {
      final h = DiaryHarness();
      await h.apply([MarkDay(_tue, incomplete: true)]);
      await h.apply([MarkDay(_tue, incomplete: false)]);
      await h.apply([_create(2300, version: (await _mark(h))!.version)]);
      expect((await _mark(h))!.estimateOnly, isFalse);
      await h.apply([
        LogEntries([newEntry(1, when: atDay(_tue), slotId: _lunch)]),
      ]);
      final mark = (await _mark(h))!;
      expect(
        (mark.deletedAt, mark.estimateKcal, mark.incomplete),
        (null, null, false),
      );
      final day = await tuesday(h);
      expect((day.incomplete, day.confirmed), (false, true));
    });

    test('DY-004 a superseded estimate-only mark (food from another '
        'device) is never a confirmation', () async {
      final h = await _estimated();
      await insertEntries(h.db, [
        entryRow(1, date: '$_tue', slotId: _lunch, kcal: 600),
      ]);
      final day = await tuesday(h);
      expect((day.incomplete, day.confirmed), (true, false));
    });
  });

  test('D14 dayMark round trip: a day estimate encodes as v2 and the entity '
      'is downgrade-protected', () async {
    final h = await _estimated();
    final table = h.db.syncedTables.singleWhere(
      (t) => t.entity == dayMarkEntity,
    );
    final row = await h.db
        .customSelect(
          'SELECT * FROM day_marks WHERE id = ?',
          variables: [Variable.withString(dayMarkRowId(_tue))],
        )
        .getSingle();
    final codec = ColumnSyncCodec(table);
    expect(codec.uploadVersion, 2);
    final payload = codec.encode(row.data);
    expect(payload['estimateKcal'], 2300);
    expect(payload['estimateOnly'], isTrue);
    expect(payload['localDate'], '$_tue');
    expect(SyncDocumentUpgraders.downgradeProtected, contains(dayMarkEntity));
  });
}
