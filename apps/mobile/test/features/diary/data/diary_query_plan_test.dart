import 'package:drift/drift.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_fixtures.dart';

/// The `detail` lines of EXPLAIN QUERY PLAN for [sql].
Future<List<String>> _plan(
  AppDatabase db,
  String sql,
  List<Object> args,
) async {
  // The write guard only lets plain SELECTs through outside the applier.
  final rows = await runAuthorizedWrite(
    () => db
        .customSelect(
          'EXPLAIN QUERY PLAN $sql',
          variables: [for (final a in args) Variable(a)],
        )
        .get(),
  );
  return [for (final row in rows) row.read<String>('detail')];
}

void main() {
  test('DY-001 index: the day, slot and range queries search '
      'ix_diary_entries_live (no table scan)', () async {
    final db = memoryDatabase();
    await insertEntries(db, [entryRow(1, date: '2026-10-17', slotId: 'a')]);
    final plans = {
      'day': await _plan(db, DiaryReads.dayEntriesSql, ['2026-10-17']),
      'slot': await _plan(db, DiaryReads.slotEntriesSql, ['2026-10-17', 'a']),
      'range': await _plan(db, DiaryReads.rangeEntriesSql, [
        '2026-10-01',
        '2026-10-31',
      ]),
      'totals': await _plan(db, DiaryReads.dailyTotalsSql, [
        '2026-01-01',
        '2026-12-31',
      ]),
    };
    for (final MapEntry(:key, :value) in plans.entries) {
      expect(
        value.any(
          (d) => d.contains('USING') && d.contains('ix_diary_entries_live'),
        ),
        isTrue,
        reason: '$key plan: $value',
      );
      expect(
        value.any(
          (d) => d.startsWith('SCAN diary_entries') && !d.contains('USING'),
        ),
        isFalse,
        reason: '$key plan: $value',
      );
    }
  });
}
