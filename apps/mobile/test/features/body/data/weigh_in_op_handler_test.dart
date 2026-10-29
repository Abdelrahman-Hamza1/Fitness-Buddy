import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart' show outbox;
import '../support/weigh_in_harness.dart';

void main() {
  test('WB-001 CreateWeighIn writes kg, input, time, local date and note, '
      'and one outbox row', () async {
    final h = WeighInHarness();
    final draft = weighInDraft(
      214,
      unit: MassUnit.pound,
      hour: 6,
      minute: 42,
      note: ' after Eid ',
    );
    await h.apply([CreateWeighIn(fixtureId(1), draft)]);
    final row = await h.row(1);
    expect(row.kg, 97.07);
    expect((row.inputValue, row.inputUnit), (214.0, 'lb'));
    expect(
      row.measuredAtUtc,
      DateTime.utc(2026, 10, 17, 3, 42).millisecondsSinceEpoch,
    );
    expect(row.tzOffsetMin, 180);
    expect(row.localDate, '2026-10-17');
    expect(row.note, 'after Eid');
    expect(row.preferredForDay, isFalse);
    expect((row.version, row.origin, row.deletedAt), (1, 'direct', null));
    final out = await outbox(h.db);
    expect(out, hasLength(1));
    expect(out.single.$1, 'weighIn');
    expect(out.single.$2, fixtureId(1));
    expect((await h.live()).single.draft, draft);

    // A local date from the stored offset: 23:30 at UTC−05:00 is the
    // 16th locally even though it's the 17th in UTC.
    await h.apply([
      CreateWeighIn(
        fixtureId(2),
        WeighInDraft(
          time: EntryTime(DateTime.utc(2026, 10, 17, 4, 30), -300),
          input: const WeighInInput(97, MassUnit.kilogram),
        ),
      ),
    ]);
    expect((await h.row(2)).localDate, '2026-10-16');
    // The same ID twice is a duplicate.
    expect(
      await h.reject([CreateWeighIn(fixtureId(1), weighInDraft(97))]),
      isA<ConstraintViolation>(),
    );
  });

  test('UX-030 undo of CreateWeighIn leaves no live weigh-in (a tombstone) '
      'and the trend as before', () async {
    final h = WeighInHarness();
    await h.seed([
      weighInDraft(97, date: day17.plusDays(-7)),
      weighInDraft(96.6, date: day17.plusDays(-3)),
    ]);
    final before = await h.state();
    final trendBefore = TrendWeight().compute(await h.live());
    final a = await h.apply([CreateWeighIn(fixtureId(3), weighInDraft(95.8))]);
    expect(TrendWeight().compute(await h.live()), isNot(trendBefore));
    await h.undo(a);
    expect((await h.row(3)).deletedAt, isNotNull);
    expect(await h.live(), hasLength(2));
    expect(await h.state(), before);
    expect(TrendWeight().compute(await h.live()), trendBefore);
  });

  test('UpdateWeighIn with a stale version is rejected and writes '
      'nothing', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97)]);
    await h.apply([UpdateWeighIn(fixtureId(1), 1, weighInDraft(97.4))]);
    expect(
      await h.reject([UpdateWeighIn(fixtureId(1), 1, weighInDraft(97.8))]),
      isA<VersionConflict>()
          .having((f) => f.expected, 'expected', 1)
          .having((f) => f.actual, 'actual', 2),
    );
    // Gone (a tombstone) or never there: RowNotFound.
    await h.apply([DeleteWeighIn(VersionedId(fixtureId(1), 2))]);
    expect(
      await h.reject([UpdateWeighIn(fixtureId(1), 3, weighInDraft(97.8))]),
      isA<RowNotFound>(),
    );
    expect(
      await h.reject([UpdateWeighIn(fixtureId(9), 1, weighInDraft(97.8))]),
      isA<RowNotFound>(),
    );
  });

  test('UpdateWeighIn with an identical draft writes nothing', () async {
    final h = WeighInHarness();
    final draft = weighInDraft(214, unit: MassUnit.pound, note: 'n');
    await h.seed([draft]);
    final before = await h.raw();
    await h.apply([
      UpdateWeighIn(
        fixtureId(1),
        1,
        weighInDraft(214, unit: MassUnit.pound, note: ' n '),
      ),
    ]);
    expect(await h.raw(), before);

    // A real change writes the new content and is undoable exactly.
    final state = await h.state();
    final a = await h.apply([
      UpdateWeighIn(fixtureId(1), 1, weighInDraft(97.3, hour: 8)),
    ]);
    final row = await h.row(1);
    expect(
      (row.kg, row.inputValue, row.inputUnit, row.note),
      (97.3, 97.3, 'kg', null),
    );
    expect(row.version, 2);
    expect((await outbox(h.db)).last.$1, 'weighIn');
    await h.undo(a);
    expect(await h.state(), state);
  });

  test('UX-030 DeleteWeighIn tombstones the row and undo revives it', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97, note: 'n')]);
    final before = await h.state();
    final a = await h.apply([DeleteWeighIn(VersionedId(fixtureId(1), 1))]);
    expect((await h.row(1)).deletedAt, isNotNull);
    expect(await h.live(), isEmpty);
    expect((await outbox(h.db)).last.$4, isTrue);
    await h.undo(a);
    expect((await h.row(1)).deletedAt, isNull);
    expect(await h.state(), before);
    expect(
      await h.reject([DeleteWeighIn(VersionedId(fixtureId(1), 1))]),
      isA<VersionConflict>(),
    );
  });

  test('WB-003 ChooseTrendWeighIn sets the chosen flag, clears the others, '
      'and undo restores them', () async {
    final h = WeighInHarness();
    await h.seed([
      weighInDraft(97.2, hour: 6),
      weighInDraft(97, hour: 12),
      weighInDraft(96.8, hour: 14),
      weighInDraft(97.5, date: day17.plusDays(-1)),
    ]);
    final before = await h.state();
    final day = await h.dayIds(day17);
    expect(day, hasLength(3));

    ChooseTrendWeighIn choose(int? n, List<VersionedId> day) =>
        ChooseTrendWeighIn(
          day17,
          chosen: n == null
              ? null
              : day.singleWhere((v) => v.id == fixtureId(n)),
          dayWeighIns: day,
        );
    Future<List<bool>> flags() async => [
      for (final n in [1, 2, 3, 4]) (await h.row(n)).preferredForDay,
    ];

    final first = await h.apply([choose(2, day)]);
    expect(await flags(), [false, true, false, false]);
    expect(
      DayChoice.of(await h.live()).map((w) => w.id),
      contains(fixtureId(2)),
    );
    await h.undo(first);
    expect(await h.state(), before);
    expect(await flags(), [false, false, false, false]);

    await h.apply([choose(2, await h.dayIds(day17))]);
    // Switching writes only the two rows whose flag changes.
    final outboxBefore = (await outbox(h.db)).length;
    await h.apply([choose(3, await h.dayIds(day17))]);
    expect((await outbox(h.db)).length, outboxBefore + 2);
    expect(await flags(), [false, false, true, false]);
    final afterSecond = await h.state();

    // Back to the earliest clears every flag; undo restores the choice.
    final third = await h.apply([choose(null, await h.dayIds(day17))]);
    expect(await flags(), [false, false, false, false]);
    await h.undo(third);
    expect(await h.state(), afterSecond);
    expect(await flags(), [false, false, true, false]);
  });

  test('WB-003 ChooseTrendWeighIn rejects a day whose weigh-ins changed since '
      'they were shown', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97.2, hour: 6), weighInDraft(97, hour: 12)]);
    final shown = await h.dayIds(day17);
    ChooseTrendWeighIn choose(List<VersionedId> listed) => ChooseTrendWeighIn(
      day17,
      chosen: VersionedId(fixtureId(2), 1),
      dayWeighIns: listed,
    );

    // A weigh-in added to the day since.
    await h.apply([CreateWeighIn(fixtureId(3), weighInDraft(97.1, hour: 9))]);
    expect(await h.reject([choose(shown)]), const InvalidOp('sourceChanged'));
    // Fewer rows listed than live, or a row from another day.
    expect(
      await h.reject([
        choose([VersionedId(fixtureId(2), 1)]),
      ]),
      const InvalidOp('sourceChanged'),
    );
    // A shown row edited since (a newer version).
    await h.apply([
      UpdateWeighIn(fixtureId(1), 1, weighInDraft(97.3, hour: 6)),
    ]);
    expect(
      await h.reject([
        choose([...shown, VersionedId(fixtureId(3), 1)]),
      ]),
      const InvalidOp('sourceChanged'),
    );
    // A shown row deleted since.
    await h.apply([DeleteWeighIn(VersionedId(fixtureId(3), 1))]);
    expect(
      await h.reject([
        choose([
          VersionedId(fixtureId(1), 2),
          VersionedId(fixtureId(2), 1),
          VersionedId(fixtureId(3), 1),
        ]),
      ]),
      const InvalidOp('sourceChanged'),
    );
    // As shown now: accepted.
    await h.apply([choose(await h.dayIds(day17))]);
    expect((await h.row(2)).preferredForDay, isTrue);
  });

  test('WB-003 ChooseTrendWeighIn lists only the readable weigh-ins of the '
      'day; an unreadable synced row is left alone', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97.2, hour: 6), weighInDraft(97, hour: 12)]);
    // A synced row with an absurd kg on the same day: the lists never show it.
    await h.apply([
      ScriptOp.rows([
        InsertRow(
          h.db.weighIns,
          WeighInsCompanion(
            id: Value(fixtureId(3)),
            measuredAtUtc: Value(
              weighInDraft(
                1,
                hour: 9,
              ).time.occurredAtUtc.millisecondsSinceEpoch,
            ),
            tzOffsetMin: const Value(180),
            localDate: Value(day17.toString()),
            kg: const Value(1e306),
            inputValue: const Value(1e306),
            inputUnit: const Value('kg'),
            preferredForDay: const Value(true),
          ),
        ),
      ]),
    ]);
    final shown = [for (final w in await h.live()) w.versionedId];
    expect(shown, hasLength(2));
    await h.apply([
      ChooseTrendWeighIn(
        day17,
        chosen: VersionedId(fixtureId(2), 1),
        dayWeighIns: shown,
      ),
    ]);
    expect((await h.row(2)).preferredForDay, isTrue);
    expect((await h.row(1)).preferredForDay, isFalse);
    final unreadable = await h.row(3);
    expect(unreadable.preferredForDay, isTrue, reason: 'not touched');
    expect(unreadable.version, 1);
  });

  test('WB-003 logging and choosing for the trend in one change set is '
      'atomic', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97.2, hour: 6)]);
    final before = await h.state();
    // PA6: the new row is listed at version 1; the choose op sees the
    // create's write in the same transaction.
    final a = await h.apply([
      CreateWeighIn(fixtureId(2), weighInDraft(97, hour: 9)),
      ChooseTrendWeighIn(
        day17,
        chosen: VersionedId(fixtureId(2), 1),
        dayWeighIns: [
          VersionedId(fixtureId(1), 1),
          VersionedId(fixtureId(2), 1),
        ],
      ),
    ]);
    expect((await h.row(2)).preferredForDay, isTrue);
    expect((await h.row(1)).preferredForDay, isFalse);
    expect(DayChoice.of(await h.live()).single.id, fixtureId(2));
    // One undo takes both back.
    await h.undo(a);
    expect(await h.state(), before);

    // A failing choose rolls the create back too.
    expect(
      await h.reject([
        CreateWeighIn(fixtureId(3), weighInDraft(97, hour: 9)),
        ChooseTrendWeighIn(
          day17,
          chosen: VersionedId(fixtureId(3), 1),
          dayWeighIns: [VersionedId(fixtureId(3), 1)],
        ),
      ]),
      const InvalidOp('sourceChanged'),
    );
  });

  test('moving a preferred weigh-in to another day clears its '
      'preference', () async {
    final h = WeighInHarness();
    await h.seed([weighInDraft(97.2, hour: 6), weighInDraft(97, hour: 12)]);
    await h.apply([
      ChooseTrendWeighIn(
        day17,
        chosen: VersionedId(fixtureId(2), 1),
        dayWeighIns: await h.dayIds(day17),
      ),
    ]);
    // A time change on the same day keeps it.
    await h.apply([UpdateWeighIn(fixtureId(2), 2, weighInDraft(97, hour: 13))]);
    expect((await h.row(2)).preferredForDay, isTrue);
    final before = await h.state();
    final a = await h.apply([
      UpdateWeighIn(
        fixtureId(2),
        3,
        weighInDraft(97, date: day17.plusDays(-1), hour: 13),
      ),
    ]);
    final row = await h.row(2);
    expect((row.localDate, row.preferredForDay), ('2026-10-16', false));
    await h.undo(a);
    expect(await h.state(), before);
  });

  test('a measured time more than 5 minutes ahead is rejected '
      '(future)', () async {
    final h = WeighInHarness();
    WeighInDraft at(DateTime utc) => WeighInDraft(
      time: EntryTime(utc, 180),
      input: const WeighInInput(97, MassUnit.kilogram),
    );
    final tooLate = harnessNow.add(const Duration(minutes: 5, seconds: 1));
    expect(
      await h.reject([CreateWeighIn(fixtureId(1), at(tooLate))]),
      const InvalidOp('future'),
    );
    await h.apply([
      CreateWeighIn(
        fixtureId(1),
        at(harnessNow.add(const Duration(minutes: 5))),
      ),
    ]);
    expect(
      await h.reject([UpdateWeighIn(fixtureId(1), 1, at(tooLate))]),
      const InvalidOp('future'),
    );
  });

  test('a negative measured time is rejected (time)', () async {
    final h = WeighInHarness();
    final draft = WeighInDraft(
      time: EntryTime(DateTime.utc(1969, 12, 31, 23, 59), 0),
      input: const WeighInInput(97, MassUnit.kilogram),
    );
    expect(
      await h.reject([CreateWeighIn(fixtureId(1), draft)]),
      const InvalidOp('time'),
    );
    // PA9: the table's CHECK holds the same line for any writer.
    final raw = await h.applier.apply(
      ChangeSet([
        ScriptOp.rows([
          InsertRow(
            h.db.weighIns,
            const WeighInsCompanion(
              id: Value('0199e3c2-5b1a-7c3d-8e4f-000000000002'),
              measuredAtUtc: Value(-1),
              tzOffsetMin: Value(0),
              localDate: Value('1969-12-31'),
              kg: Value(97),
              inputValue: Value(97),
              inputUnit: Value('kg'),
            ),
          ),
        ]),
      ], origin: Origin.direct),
    );
    expect(raw, isA<Rejected>());
    expect(await h.live(), isEmpty);
  });

  test('an invalid draft is rejected (invalidDraft)', () async {
    final h = WeighInHarness();
    for (final draft in [
      weighInDraft(19.9),
      weighInDraft(500.1),
      weighInDraft(double.nan),
      weighInDraft(97, unit: MassUnit.gram),
      weighInDraft(97, note: 'x' * 201),
      weighInDraft(97, note: 'a\u0000b'),
    ]) {
      expect(
        await h.reject([CreateWeighIn(fixtureId(1), draft)]),
        const InvalidOp('invalidDraft'),
      );
    }
    await h.seed([weighInDraft(97)]);
    expect(
      await h.reject([UpdateWeighIn(fixtureId(1), 1, weighInDraft(600))]),
      const InvalidOp('invalidDraft'),
    );
  });
}
