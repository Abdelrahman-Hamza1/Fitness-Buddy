import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../support/diary_fixtures.dart';

void main() {
  test('DY-020 latest-wins: 10 writes during a held read start one '
      'follow-up, discarding stale data', () async {
    final db = memoryDatabase();
    final reads = DiaryReads(db);
    final date = LocalDate(2026, 10, 17);
    final started = Completer<void>();
    final release = Completer<void>();
    var calls = 0;
    var running = 0;
    var maxRunning = 0;
    final repo = DiaryRepository(
      db,
      readDay: (day) async {
        calls++;
        running++;
        if (running > maxRunning) maxRunning = running;
        final value = await reads.day(day);
        if (calls == 1) {
          started.complete();
          await release.future;
        }
        running--;
        return value;
      },
    );
    final emitted = <DiaryDay>[];
    final settled = Completer<void>();
    final sub = repo.watchDay(date).listen((day) {
      emitted.add(day);
      if (day.entries.length == 10 && !settled.isCompleted) settled.complete();
    });
    addTearDown(sub.cancel);
    await started.future;
    for (var i = 0; i < 10; i++) {
      await insertEntries(db, [
        entryRow(i + 1, date: '$date', slotId: DefaultSlots.lunchId),
      ]);
    }
    await pumpEventQueue();
    expect(calls, 1);
    release.complete();
    await settled.future;
    expect(calls, 2);
    expect(maxRunning, 1);
    expect(emitted, hasLength(1));
    expect(emitted.single.entries, (await reads.day(date)).entries);
  });

  test('DY-020 latest-wins forwards current errors and cancellation '
      'starts no queued read', () async {
    final db = memoryDatabase();
    final date = LocalDate(2026, 10, 17);
    final failed = Completer<void>();
    final errors = <Object>[];
    final repo = DiaryRepository(
      db,
      readDay: (_) async => throw StateError('test'),
    );
    final sub = repo
        .watchDay(date)
        .listen(
          (_) {},
          onError: (Object e) {
            errors.add(e);
            failed.complete();
          },
        );
    await failed.future;
    expect(errors.single, isA<StateError>());
    await sub.cancel();
    var called = 0;
    final cancelled = DiaryRepository(
      db,
      readDay: (day) async {
        called++;
        return await DiaryReads(db).day(day);
      },
    );
    await cancelled.watchDay(date).listen((_) {}).cancel();
    await pumpEventQueue();
    expect(called, 0);
  });
}
