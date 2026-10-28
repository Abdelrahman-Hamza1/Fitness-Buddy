@Tags(['perf'])
library;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_fixtures.dart';
import '../support/diary_harness.dart';

void main() {
  test('DY-010 A10b perf: removing a slot with 1,500 entries and 100 '
      'groups over 365 days applies p95 < 500 ms and undoes p95 < 500 '
      'ms on the host (printed)', () async {
    final h = DiaryHarness();
    const source = DefaultSlots.lunchId;
    final start = today.plusDays(-364);
    await runAuthorizedWrite(
      () => h.db.batch((b) {
        b
          ..insertAll(h.db.dishGroups, [
            for (var i = 0; i < 100; i++)
              DishGroupsCompanion.insert(
                id: fixtureId(10000 + i),
                name: 'Private',
                localDate: '${start.plusDays(i)}',
                slotId: source,
                createdAt: 1,
                updatedHlc: hlcAt(i + 1),
                version: 1,
                deviceId: testDevice,
                origin: 'direct',
              ),
          ])
          ..insertAll(h.db.diaryEntries, [
            for (var i = 0; i < 1500; i++)
              entryRow(
                i + 1,
                date: '${start.plusDays(i % 365)}',
                slotId: source,
                dishGroupId: i < 100 ? fixtureId(10000 + i) : null,
              ),
          ]);
      }),
    );
    final repo = DiaryRepository(h.db);
    final applyTimes = <int>[];
    final undoTimes = <int>[];
    for (var i = 0; i < 23; i++) {
      final records = await repo.watchSlotRecords().first;
      final op = RemoveMealSlot(
        source,
        records.singleWhere((r) => r.slot.id == source).version,
        expected: await repo.watchSlotContents(source).first,
        moveTo: records
            .singleWhere((r) => r.slot.id == DefaultSlots.snacksId)
            .versionedId,
      );
      final watch = Stopwatch()..start();
      final applied = await h.apply([op]);
      watch.stop();
      if (i >= 3) applyTimes.add(watch.elapsedMicroseconds);
      watch
        ..reset()
        ..start();
      await h.undo(applied);
      watch.stop();
      if (i >= 3) undoTimes.add(watch.elapsedMicroseconds);
    }
    applyTimes.sort();
    undoTimes.sort();
    final applyP95 = applyTimes[18] / 1000;
    final undoP95 = undoTimes[18] / 1000;
    // Timings are the required host benchmark evidence.
    // ignore: avoid_print
    print(
      'A10b removal host: 1500 entries, 100 groups, 365 days; 3 '
      'warmups, 20 runs; apply p95 $applyP95 ms; undo p95 $undoP95 ms',
    );
    expect(applyP95, lessThan(500));
    expect(undoP95, lessThan(500));
    expect((await repo.watchSlotContents(source).first).entries.length, 1500);
  });
}
