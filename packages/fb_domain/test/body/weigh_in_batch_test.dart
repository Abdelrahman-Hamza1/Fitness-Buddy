import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

/// The checks' "today": 30 days after [day0].
final LocalDate _today = dayN(30);

EntryTime _timeFor(LocalDate date) => morningOf(date, hour: 8);

WeighInBatchRow _row(
  int? day,
  double? value, {
  MassUnit unit = MassUnit.kilogram,
  WeighInKeep? keep,
}) => WeighInBatchRow(
  date: day == null ? null : dayN(day),
  value: value,
  unit: unit,
  keep: keep,
);

WeighInBatchResult _check(
  List<WeighInBatchRow> rows, [
  List<WeighIn> existing = const [],
]) => WeighInBatchCheck.check(
  rows: rows,
  existing: existing,
  today: _today,
  timeFor: _timeFor,
);

/// [row] with the Keep its result offers.
WeighInBatchRow _kept(WeighInBatchRow row, WeighInRowResult result) =>
    WeighInBatchRow(
      date: row.date,
      value: row.value,
      unit: row.unit,
      keep: result.keepToken,
    );

void main() {
  test('WB-005 WeighInBatchCheck blocks incomplete, out-of-range and future '
      'rows', () {
    final result = _check([
      _row(null, 80),
      _row(1, null),
      _row(null, null),
      _row(2, 19.9),
      _row(3, 1200, unit: MassUnit.pound),
      _row(31, 80),
      _row(30, 80),
    ]);
    expect(result.rows.map((r) => r.blocking), [
      WeighInRowFlag.incomplete,
      WeighInRowFlag.incomplete,
      WeighInRowFlag.incomplete,
      WeighInRowFlag.outOfRange,
      WeighInRowFlag.outOfRange,
      WeighInRowFlag.future,
      null,
    ]);
    expect(result.rows.map((r) => r.index), [0, 1, 2, 3, 4, 5, 6]);
    expect(result.rows.first.draft, isNull);
    expect(result.rows[3].draft, isNotNull);
    expect(result.rows[3].flags, [WeighInRowFlag.outOfRange]);
    expect(result.rows.last.included, isTrue);
    expect(result.hasBlocking, isTrue);
    expect(result.canSave, isFalse);
    expect(result.included, hasLength(1));
    // A date before 1970 is out of range too.
    final old = WeighInBatchCheck.check(
      rows: [
        WeighInBatchRow(
          date: LocalDate(1969, 12, 31),
          value: 80,
          unit: MassUnit.kilogram,
        ),
      ],
      existing: const [],
      today: _today,
      timeFor: (d) => EntryTime.local(LocalDateTime(d, hour: 8), 0),
    );
    expect(old.rows.single.blocking, WeighInRowFlag.outOfRange);

    final clean = _check([_row(1, 80), _row(8, 79.6)]);
    expect(clean.hasBlocking, isFalse);
    expect(clean.canSave, isTrue);
    expect(clean.rows.every((r) => r.flags.isEmpty), isTrue);
    expect(clean.included.map((d) => d.kg), [80, 79.6]);
    expect(clean.included.first.time, _timeFor(dayN(1)));
  });

  test('WB-005 WB-031 a duplicate of an existing weigh-in or of an earlier '
      'row is excluded until kept', () {
    final existing = [storedOn(dayN(1), 80)];
    final rows = [
      _row(1, 80.05), // within 0.05 kg of the stored one
      _row(5, 79.8),
      _row(5, 79.8), // the row above, same date
      _row(1, 80.2), // 0.2 away: not a duplicate
    ];
    final result = _check(rows, existing);
    final [stored, first, copy, other] = result.rows;
    expect(stored.exclusion, WeighInRowFlag.duplicate);
    expect(stored.reference, existing.single);
    expect(stored.duplicateOfRow, isNull);
    expect(stored.included, isFalse);
    expect(stored.sameDay, isFalse);
    expect(stored.keepToken, isNotNull);
    expect(first.flags, isEmpty);
    expect(copy.exclusion, WeighInRowFlag.duplicate);
    expect(copy.duplicateOfRow, 1);
    expect(copy.reference!.localDate, dayN(5));
    expect(other.exclusion, isNull);
    expect(other.sameDay, isTrue);
    expect(result.included.map((d) => d.kg), [80.2, 79.8]);
    expect(result.canSave, isTrue);

    // Keep both duplicates: they are saved.
    final kept = _check([
      _kept(rows[0], stored),
      rows[1],
      _kept(rows[2], copy),
      rows[3],
    ], existing);
    expect(kept.rows[0].kept, isTrue);
    expect(kept.rows[0].included, isTrue);
    expect(kept.rows[2].kept, isTrue);
    expect(kept.included, hasLength(4));
    expect(kept.rows[0].toString(), 'WeighInRowResult(0, duplicate, kept)');
  });

  test('WB-005 a row unit mix-up (214 after 97 kg) is implausible and '
      'suggests lb; a 4 % jump within 7 days asks; kept rows become '
      'references for later rows', () {
    final rows = [
      _row(1, 97),
      _row(8, 214),
      _row(10, 100.9), // 9 days after the only included row
    ];
    final result = _check(rows);
    final mixUp = result.rows[1];
    expect(mixUp.exclusion, WeighInRowFlag.implausible);
    final finding = mixUp.implausible! as LikelyOtherUnit;
    expect(finding.suggestedUnit, MassUnit.pound);
    expect(mixUp.reference!.kg, 97);
    expect(mixUp.reference!.localDate, dayN(1));
    // The excluded mix-up isn't a reference: day 10 is 9 days after day 1.
    expect(result.rows[2].flags, isEmpty);

    // A 4 % jump within 7 days asks.
    final jump = _check([_row(1, 97), _row(4, 100.9)]);
    final large = jump.rows[1].implausible! as LargeChange;
    expect(jump.rows[1].exclusion, WeighInRowFlag.implausible);
    expect(large.diffKg, closeTo(3.9, 1e-9));
    // Against a stored weigh-in too, and a backfill before it.
    final stored = [storedOn(dayN(20), 90)];
    final before = _check([_row(15, 94)], stored);
    expect(before.rows.single.exclusion, WeighInRowFlag.implausible);
    expect(before.rows.single.reference, stored.single);

    // Kept, the jump becomes the reference for the next row.
    final keptRows = [
      _row(1, 97),
      _kept(_row(4, 100.9), jump.rows[1]),
      _row(6, 101),
    ];
    final kept = _check(keptRows);
    expect(kept.rows[1].included, isTrue);
    expect(kept.rows[2].flags, isEmpty); // 101 vs 100.9: plausible
    final notKept = _check([_row(1, 97), _row(4, 100.9), _row(6, 101)]);
    expect(notKept.rows[2].exclusion, WeighInRowFlag.implausible);
  });

  test('WB-003 a row on a date with a different existing weigh-in gets the '
      'sameDay info flag and stays included', () {
    final existing = [storedOn(dayN(3), 80)];
    final result = _check([_row(3, 80.4)], existing);
    final row = result.rows.single;
    expect(row.sameDay, isTrue);
    expect(row.flags, [WeighInRowFlag.sameDay]);
    expect(row.included, isTrue);
    expect(row.keepToken, isNull);
    expect(result.canSave, isTrue);
    expect(row.toString(), 'WeighInRowResult(0, sameDay)');
  });

  test('WB-003 WeighInBatch.timeFor gives 08:00 local on past dates, '
      'min(08:00, now) today, and the right offset across a DST change', () {
    expect(WeighInBatch.defaultTime, LocalTime(8));
    // UTC+03:00, now 2026-01-31 06:30 local.
    final clock = ManualClock(
      DateTime.utc(2026, 1, 31, 3, 30),
      offsetMinutes: 180,
    );
    final past = WeighInBatch.timeFor(LocalDate(2026, 1, 10), clock);
    expect(past.localDateTime, LocalDateTime(LocalDate(2026, 1, 10), hour: 8));
    expect(past.tzOffsetMin, 180);
    final earlyToday = WeighInBatch.timeFor(LocalDate(2026, 1, 31), clock);
    expect(earlyToday, EntryTime.now(clock));
    clock.utc = DateTime.utc(2026, 1, 31, 9);
    final lateToday = WeighInBatch.timeFor(LocalDate(2026, 1, 31), clock);
    expect(
      lateToday.localDateTime,
      LocalDateTime(LocalDate(2026, 1, 31), hour: 8),
    );

    // A zone at +01:00 in winter and +02:00 from 2026-03-29 01:00Z.
    final change = DateTime.utc(2026, 3, 29, 1);
    final dst = ManualClock(
      DateTime.utc(2026, 6, 1, 12),
      zone: (utc) => utc.isBefore(change) ? 60 : 120,
    );
    final winter = WeighInBatch.timeFor(LocalDate(2026, 3, 28), dst);
    final summer = WeighInBatch.timeFor(LocalDate(2026, 3, 29), dst);
    expect(winter.tzOffsetMin, 60);
    expect(winter.occurredAtUtc, DateTime.utc(2026, 3, 28, 7));
    expect(summer.tzOffsetMin, 120);
    expect(summer.occurredAtUtc, DateTime.utc(2026, 3, 29, 6));
    expect(summer.localDateTime.hour, 8);
  });

  test('WB-001 WeighInBatch.ops builds one CreateWeighIn per included row '
      'with the given ids, at most 500', () {
    final result = _check([_row(1, 80), _row(2, null), _row(3, 80.2)]);
    expect(result.canSave, isFalse); // the incomplete row blocks
    final ok = _check([_row(1, 80), _row(3, 80.2)]);
    final ops = WeighInBatch.ops(ok.included, [weighInA, weighInB]);
    expect(ops, [
      CreateWeighIn(weighInA, ok.included[0]),
      CreateWeighIn(weighInB, ok.included[1]),
    ]);
    expect(
      () => WeighInBatch.ops(ok.included, [weighInA]),
      throwsArgumentError,
    );
    expect(() => WeighInBatch.ops(const [], const []), throwsArgumentError);
    expect(WeighInBatchCheck.maxRows, 500);

    final draft = draftOn(day0, 80);
    final ids = [for (var i = 0; i < 501; i++) weighInId(i)];
    expect(
      WeighInBatch.ops(List.filled(500, draft), ids.sublist(0, 500)),
      hasLength(500),
    );
    expect(
      () => WeighInBatch.ops(List.filled(501, draft), ids),
      throwsArgumentError,
    );
    // 501 included rows can't be saved in one go.
    final many = _check([
      for (var i = 0; i < 501; i++)
        WeighInBatchRow(
          date: LocalDate(2020, 1, 1).plusDays(i),
          value: 80,
          unit: MassUnit.kilogram,
        ),
    ]);
    expect(many.included, hasLength(501));
    expect(many.hasBlocking, isFalse);
    expect(many.canSave, isFalse);
  });

  test("WB-031 a Keep is cleared when its row's date, value or unit changes, "
      'or when an earlier row or existing weigh-in it was checked against '
      'changes', () {
    final reference = _row(1, 97);
    final jumpRow = _row(4, 100.9);
    final token = _check([reference, jumpRow]).rows[1].keepToken!;
    bool keptWith(
      List<WeighInBatchRow> rows, [
      List<WeighIn> stored = const [],
    ]) => _check(rows, stored).rows.last.kept;
    WeighInBatchRow kept(
      int day,
      double value, [
      MassUnit unit = MassUnit.kilogram,
    ]) => _row(day, value, unit: unit, keep: token);

    expect(keptWith([reference, kept(4, 100.9)]), isTrue);
    expect(token, _check([reference, jumpRow]).rows[1].keepToken);
    expect(
      token.hashCode,
      _check([reference, jumpRow]).rows[1].keepToken.hashCode,
    );
    expect(token.toString(), 'WeighInKeep');
    // The row changes.
    expect(keptWith([reference, kept(5, 100.9)]), isFalse);
    expect(keptWith([reference, kept(4, 101)]), isFalse);
    expect(keptWith([reference, kept(4, 100.9, MassUnit.pound)]), isFalse);
    // The earlier row it was checked against changes.
    expect(keptWith([_row(1, 96.9), kept(4, 100.9)]), isFalse);
    expect(keptWith([_row(2, 97), kept(4, 100.9)]), isFalse);

    // A stored weigh-in it was checked against changes (a new version).
    final stored = storedOn(dayN(1), 97);
    final storedToken = _check([jumpRow], [stored]).rows.single.keepToken!;
    final keptRow = _row(4, 100.9, keep: storedToken);
    expect(keptWith([keptRow], [stored]), isTrue);
    expect(keptWith([keptRow], [storedOn(dayN(1), 97, version: 2)]), isFalse);
    expect(keptWith([keptRow], [storedOn(dayN(1), 97.1)]), isFalse);
  });

  test('WB-031 a Keep of rows dated today survives the clock moving before '
      '08:00 (their time follows now until then)', () {
    // 06:00 local at UTC+03:00.
    final clock = ManualClock(DateTime.utc(2026, 1, 31, 3), offsetMinutes: 180);
    final today = LocalDate(2026, 1, 31);
    WeighInBatchResult check(List<WeighInBatchRow> rows) =>
        WeighInBatchCheck.check(
          rows: rows,
          existing: const [],
          today: today,
          timeFor: (date) => WeighInBatch.timeFor(date, clock),
        );
    WeighInBatchRow row({WeighInKeep? keep}) => WeighInBatchRow(
      date: today,
      value: 80,
      unit: MassUnit.kilogram,
      keep: keep,
    );
    final first = check([row(), row()]);
    expect(first.rows[1].exclusion, WeighInRowFlag.duplicate);
    final keep = first.rows[1].keepToken!;
    // To 06:01, 06:30 and 07:59.
    for (final (minutes, step) in [(1, 1), (30, 29), (119, 89)]) {
      clock.advance(Duration(minutes: step));
      final again = check([row(), row(keep: keep)]);
      expect(again.rows[1].kept, isTrue, reason: '+$minutes min');
      expect(again.included, hasLength(2));
    }
  });

  test('WB-031 zero included rows (all excluded or blocked) give nothing to '
      'save', () {
    expect(_check(const []).canSave, isFalse);
    expect(_check(const []).included, isEmpty);
    final existing = [storedOn(dayN(1), 80)];
    final allExcluded = _check([_row(1, 80), _row(1, 80.02)], existing);
    expect(allExcluded.hasBlocking, isFalse);
    expect(allExcluded.included, isEmpty);
    expect(allExcluded.canSave, isFalse);
    expect(allExcluded.toString(), 'WeighInBatchResult(2 rows, 0 included)');
    final blocked = _check([_row(null, 80)]);
    expect(blocked.included, isEmpty);
    expect(blocked.canSave, isFalse);
  });

  test('weigh-in batch rows compare by value and show no values', () {
    final row = _row(1, 97.4);
    expect(row, _row(1, 97.4));
    expect(row.hashCode, _row(1, 97.4).hashCode);
    expect(row == _row(1, 97.5), isFalse);
    expect(row.toString(), isNot(contains('97')));
  });
}
