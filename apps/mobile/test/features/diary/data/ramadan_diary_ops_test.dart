import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_inputs.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/changes/support/test_db.dart';
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

// Ramadan 1447: 2026-02-18 … 2026-03-19 (Umm al-Qura).
final _ramadanDay = LocalDate(2026, 2, 20);

/// Stores the Ramadan decisions [settings] (like a synced settings row).
Future<void> _seasons(DiaryHarness h, RamadanSettings settings) async {
  final result = await h.applier.apply(
    ChangeSet([
      ScriptOp.rows([
        UpsertRow(
          h.db.settingsKv,
          SettingsKvCompanion(
            id: Value(settingRowId(AppSettings.ramadanSeasons.name)),
            valueJson: Value(jsonEncode(settings.toJson())),
          ),
        ),
      ]),
    ], origin: Origin.direct),
  );
  expect(result, isA<Applied>());
}

/// Stores [date]'s per-date fasting mark (like a synced settings row).
Future<void> _fasting(DiaryHarness h, LocalDate date, FastingMark mark) async {
  final key = AppSettings.fastingMark(date);
  final result = await h.applier.apply(
    ChangeSet([
      ScriptOp.rows([
        UpsertRow(
          h.db.settingsKv,
          SettingsKvCompanion(
            id: Value(settingRowId(key.name)),
            valueJson: Value(key.codec.encode(mark)),
          ),
        ),
      ]),
    ], origin: Origin.direct),
  );
  expect(result, isA<Applied>());
}

Future<DayMarkRow?> _mark(DiaryHarness h, LocalDate date) =>
    (h.db.select(h.db.dayMarks)
          ..where((t) => t.localDate.equals('$date') & t.deletedAt.isNull()))
        .getSingleOrNull();

final _on = RamadanSettings([RamadanSeason(hijriYear: 1447, on: true)]);

void main() {
  group(
    'A41a fix 1: not fasting never touches the diary marks (A38, DY-004)',
    () {
      // Ramadan 1447 days: an unmarked one and one the user counted again.
      final unmarked = _ramadanDay;
      final counted = _ramadanDay.plusDays(1);
      final totals = [
        for (final d in [unmarked, counted]) DailyTotals(d, Nutrients.zero, 3),
      ];

      Future<Map<LocalDate, bool>> confirmedOf(DiaryHarness h) async {
        final marks = await h.reads.marksBetween(unmarked, counted);
        return {
          for (final d in intakeDaysOf(totals: totals, marks: marks))
            d.date: d.confirmed,
        };
      }

      test('toggling not fasting on and off, with the setting written and '
          'reverted (Undo or a synced value), keeps the marks and the '
          'complete-day decisions exactly', () async {
        final h = DiaryHarness();
        await h.apply([MarkDay(counted, incomplete: true)]);
        await h.apply([MarkDay(counted, incomplete: false)]);
        final before = await h.state();
        expect(await confirmedOf(h), {unmarked: false, counted: true});
        await _seasons(h, _on);
        for (final (date, mark) in [
          (unmarked, FastingMark.notFasting),
          (counted, FastingMark.notFasting),
          (unmarked, FastingMark.fasting),
          (counted, FastingMark.fasting),
        ]) {
          await _fasting(h, date, mark);
          expect(await h.state(), before, reason: 'no day-mark change');
          expect(await confirmedOf(h), {unmarked: false, counted: true});
        }
        expect(await _mark(h, unmarked), isNull);
      });
    },
  );

  group('DY-012 A41a D6 the handler picks a Ramadan slot on a fasting day', () {
    EntryWhen at(LocalDate date, int hour, int minute) =>
        atDay(date, hour, minute);

    test('T31 suhoor at 03:30 on a fasting day counts toward that day, in '
        'Suhoor; 18:00 in Iftar', () async {
      final h = DiaryHarness();
      await _seasons(h, _on);
      await h.apply([
        LogEntries([
          newEntry(1, when: at(_ramadanDay, 3, 30)),
          newEntry(2, when: at(_ramadanDay, 18, 0)),
        ]),
      ]);
      final suhoor = await h.entry(1);
      expect(suhoor.slotId, RamadanSlots.suhoorId);
      expect(suhoor.localDate, '$_ramadanDay');
      expect((await h.entry(2)).slotId, RamadanSlots.iftarId);
    });

    test(
      'a not-fasting day, mode off, or after Ramadan: normal slots',
      () async {
        final h = DiaryHarness();
        await _seasons(h, _on);
        final notFasting = _ramadanDay.plusDays(1);
        await _fasting(h, notFasting, FastingMark.notFasting);
        await h.apply([
          LogEntries([
            newEntry(1, when: at(notFasting, 18, 0)),
            newEntry(2, when: at(LocalDate(2026, 3, 20), 18, 0)),
          ]),
        ]);
        expect((await h.entry(1)).slotId, DefaultSlots.dinnerId);
        expect((await h.entry(2)).slotId, DefaultSlots.dinnerId);
        final off = DiaryHarness();
        await _seasons(
          off,
          RamadanSettings([RamadanSeason(hijriYear: 1447, on: false)]),
        );
        await off.apply([
          LogEntries([newEntry(1, when: at(_ramadanDay, 18, 0))]),
        ]);
        expect((await off.entry(1)).slotId, DefaultSlots.dinnerId);
      },
    );

    test("a shifted start: the calendar day before isn't Ramadan", () async {
      final h = DiaryHarness();
      await _seasons(
        h,
        RamadanSettings([
          RamadanSeason(hijriYear: 1447, on: true, startShift: 1),
        ]),
      );
      await h.apply([
        LogEntries([
          newEntry(1, when: at(LocalDate(2026, 2, 18), 18, 0)),
          newEntry(2, when: at(LocalDate(2026, 2, 19), 18, 0)),
        ]),
      ]);
      expect((await h.entry(1)).slotId, DefaultSlots.dinnerId);
      expect((await h.entry(2)).slotId, RamadanSlots.iftarId);
    });

    test(
      'a past-day log into Iftar without a time gets the window start',
      () async {
        final h = DiaryHarness();
        await _seasons(h, _on);
        await h.apply([
          LogEntries([
            newEntry(
              1,
              when: EntryWhen.onDay(_ramadanDay),
              slotId: RamadanSlots.iftarId,
            ),
          ]),
        ]);
        final row = await h.entry(1);
        // The fallback Iftar window starts at 16:30 (no prayer times here).
        expect(
          row.occurredAtUtc,
          DateTime.utc(2026, 2, 20, 16, 30).millisecondsSinceEpoch,
        );
      },
    );

    test('an explicit active slot of the other mode is accepted', () async {
      final h = DiaryHarness();
      await h.apply([
        LogEntries([newEntry(1, slotId: RamadanSlots.snacksId)]),
      ]);
      expect((await h.entry(1)).slotId, RamadanSlots.snacksId);
    });
  });

  group('DY-012 the Ramadan set is edited on its own', () {
    Future<List<MealSlotRow>> ramadan(DiaryHarness h) =>
        (h.db.select(h.db.mealSlots)
              ..where((t) => t.mode.equals('ramadan') & t.active.equals(true))
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();

    test(
      'add, rename, reorder and remove within Ramadan; normal untouched',
      () async {
        final h = DiaryHarness();
        final normalBefore = await (h.db.select(
          h.db.mealSlots,
        )..where((t) => t.mode.equals('normal'))).get();
        await h.apply([
          AddMealSlot(
            newId(1),
            'Tarawih snack',
            window: TimeWindow(20 * 60, 22 * 60),
            mode: SlotMode.ramadan,
          ),
        ]);
        var rows = await ramadan(h);
        expect(rows.map((r) => r.id), [
          RamadanSlots.suhoorId,
          RamadanSlots.iftarId,
          newId(1),
          RamadanSlots.snacksId,
        ]);
        await h.apply([
          UpdateMealSlot(
            RamadanSlots.iftarId,
            1,
            MealSlotPatch(name: 'Ftoor', setName: true),
          ),
        ]);
        rows = await ramadan(h);
        await h.apply([
          ReorderMealSlots([
            for (final id in [
              RamadanSlots.iftarId,
              RamadanSlots.suhoorId,
              newId(1),
              RamadanSlots.snacksId,
            ])
              VersionedId(id, rows.firstWhere((r) => r.id == id).version),
          ]),
        ]);
        rows = await ramadan(h);
        expect(rows.first.id, RamadanSlots.iftarId);
        expect(rows.first.name, 'Ftoor');
        await h.apply([
          RemoveMealSlot(
            newId(1),
            rows.firstWhere((r) => r.id == newId(1)).version,
            expected: SlotContents.empty,
          ),
        ]);
        expect((await ramadan(h)).map((r) => r.id), isNot(contains(newId(1))));
        final normalAfter = await (h.db.select(
          h.db.mealSlots,
        )..where((t) => t.mode.equals('normal'))).get();
        expect(normalAfter, normalBefore);
      },
    );

    test(
      'a removed Ramadan slot can only move its food to a Ramadan slot',
      () async {
        final h = DiaryHarness();
        await h.apply([
          LogEntries([newEntry(1, slotId: RamadanSlots.snacksId)]),
        ]);
        final contents = SlotContents(
          entries: [VersionedId(fixtureId(1), 1)],
          dates: ['$today'],
        );
        expect(
          await h.reject([
            RemoveMealSlot(
              RamadanSlots.snacksId,
              1,
              expected: contents,
              moveTo: VersionedId(DefaultSlots.snacksId, 1),
            ),
          ]),
          const InvalidOp('badTarget'),
        );
        await h.apply([
          RemoveMealSlot(
            RamadanSlots.snacksId,
            1,
            expected: contents,
            moveTo: VersionedId(RamadanSlots.iftarId, 1),
          ),
        ]);
        expect((await h.entry(1)).slotId, RamadanSlots.iftarId);
      },
    );

    test('a reorder mixing the two sets is refused', () async {
      final h = DiaryHarness();
      final failure = await h.reject([
        ReorderMealSlots([
          VersionedId(RamadanSlots.suhoorId, 1),
          VersionedId(DefaultSlots.breakfastId, 1),
        ]),
      ]);
      expect(failure, isA<InvalidOp>());
    });
  });
}
