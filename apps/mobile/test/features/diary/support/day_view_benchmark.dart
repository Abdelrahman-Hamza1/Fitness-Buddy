import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import 'diary_benchmark.dart';
import 'diary_fixtures.dart';

/// Provider-path timings in milliseconds, with a per-day concurrency spy.
final class DayViewBenchmarkResult {
  /// The three host budgets of A08 D17.
  const new(this.coldP95, this.writeP95, this.settleMs, this.maxReads);

  /// P1: 200 cold subscriptions after 20 warm-ups.
  final double coldP95;

  /// P2: 100 writes with three days watched.
  final double writeP95;

  /// P3: time after the last apply until all streams settle.
  final double settleMs;

  /// Largest number of concurrent reads for a single day.
  final int maxReads;
}

Future<DayView> _view(
  ProviderContainer c,
  LocalDate day, {
  int? version,
  String? id,
}) async {
  final ready = Completer<DayView>();
  final sub = c.listen(dayViewProvider(day), (_, next) {
    if (next case AsyncData(:final value)) {
      if ((version == null ||
              value.raw.entries.any(
                (e) => e.id == id && e.version == version,
              )) &&
          !ready.isCompleted) {
        ready.complete(value);
      }
    }
    if (next case AsyncError(:final error, :final stackTrace)) {
      if (!ready.isCompleted) ready.completeError(error, stackTrace);
    }
  }, fireImmediately: true);
  try {
    return await ready.future;
  } finally {
    sub.close();
  }
}

/// Reuses A06's year fixture on the supplied file/WAL/background connection.
Future<DayViewBenchmarkResult> runDayViewBenchmark(AppDatabase db) async {
  await runDiaryBenchmark(db, runs: 1, warmUps: 0);
  // A06's 365-day distribution contains 5,490 rows; top up a non-target day.
  await insertEntries(db, [
    for (var i = 0; i < 10; i++)
      entryRow(
        9000 + i,
        date: '2026-01-01',
        slotId: DefaultSlots.lunchId,
        occurredAtUtc: DateTime.utc(2026, 1, 1, 12).millisecondsSinceEpoch + i,
      ),
  ]);
  final date = LocalDate(2026, 6, 15);
  final reads = DiaryReads(db);
  await runAuthorizedWrite(() async {
    final entries = await reads.entriesOn(date);
    for (var g = 0; g < 3; g++) {
      final id = fixtureId(10000 + g);
      await db
          .into(db.dishGroups)
          .insert(
            DishGroupsCompanion.insert(
              id: id,
              createdAt: 1,
              updatedHlc: hlcAt(1),
              version: 1,
              deviceId: testDevice,
              origin: 'direct',
              name: 'Dish',
              localDate: '$date',
              slotId: DefaultSlots.all[g].id,
            ),
          );
      for (final entry
          in entries.where((e) => e.slotId == DefaultSlots.all[g].id).take(3)) {
        await (db.update(db.diaryEntries)..where((t) => t.id.equals(entry.id)))
            .write(DiaryEntriesCompanion(dishGroupId: Value(id)));
      }
    }
  });
  final running = <LocalDate, int>{};
  var maxReads = 0;
  final repo = DiaryRepository(
    db,
    readDay: (day) async {
      running[day] = (running[day] ?? 0) + 1;
      if (running[day]! > maxReads) maxReads = running[day]!;
      try {
        return await reads.day(day);
      } finally {
        running[day] = running[day]! - 1;
      }
    },
  );
  final c = ProviderContainer(
    overrides: [diaryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  final cold = <int>[];
  for (var i = 0; i < 220; i++) {
    final watch = Stopwatch()..start();
    final data = await _view(c, date);
    watch.stop();
    expect(data.layout.entryCount, 30);
    expect(data.raw.groups, hasLength(3));
    if (i >= 20) cold.add(watch.elapsedMicroseconds);
    // Dispose both autoDispose providers, so every iteration is cold.
    await c.pump();
  }
  final days = DayPager(date.plusDays(1)).window(date);
  final emissions = <LocalDate, int>{};
  final subs = [
    for (final day in days)
      c.listen(dayViewProvider(day), (_, next) {
        if (next is AsyncData<DayView>) {
          emissions[day] = (emissions[day] ?? 0) + 1;
        }
      }),
  ];
  for (final day in days) {
    await _view(c, day);
  }
  final bus = DomainEventBus();
  addTearDown(bus.close);
  final applier = ChangeSetApplier(
    db: db,
    tables: db.syncedTables,
    handlers: (db) => [DiaryOpHandler(db)],
    clock: ManualClock(DateTime.utc(2026, 10, 23)),
    ids: SequenceIdGenerator(),
    deviceId: () async => testDevice,
    events: bus,
  );
  var entry = (await reads.day(date)).entries
      .firstWhere((e) => e.dishGroupId == null);
  final id = entry.id;
  final write = <int>[];
  for (var i = 0; i < 100; i++) {
    final nextVersion = entry.version + 1;
    final watch = Stopwatch()..start();
    final result = await applier.apply(
      ChangeSet([
        MoveEntries(
          [VersionedId(id, entry.version)],
          toSlotId: entry.slotId == DefaultSlots.dinnerId
              ? DefaultSlots.lunchId
              : DefaultSlots.dinnerId,
        ),
      ], origin: Origin.direct),
    );
    expect(result, isA<Applied>());
    final data = await _view(c, date, id: id, version: nextVersion);
    write.add(watch.elapsedMicroseconds);
    entry = data.raw.entries.firstWhere((e) => e.id == id);
  }
  var version = entry.version;
  var beforeLast = <LocalDate, int>{};
  for (var i = 0; i < 5; i++) {
    final result = await applier.apply(
      ChangeSet([
        MoveEntries(
          [VersionedId(id, version)],
          toSlotId: entry.slotId == DefaultSlots.dinnerId
              ? DefaultSlots.lunchId
              : DefaultSlots.dinnerId,
        ),
      ], origin: Origin.direct),
    );
    if (result is! Applied) throw StateError('benchmark move rejected');
    beforeLast = Map.of(emissions);
    final undone = await applier.revert(result.inverse);
    if (undone is! Applied) throw StateError('benchmark undo rejected');
    version += 2;
  }
  final settle = Stopwatch()..start();
  await _view(c, date, id: id, version: version);
  // Empty neighbours must also emit after the final invalidation.
  while (days.any((day) => (emissions[day] ?? 0) <= (beforeLast[day] ?? 0)) ||
      running.values.any((n) => n != 0)) {
    if (settle.elapsedMilliseconds > 150) {
      throw StateError('burst did not settle');
    }
    await Future<void>.delayed(Duration.zero);
  }
  settle.stop();
  for (final day in days) {
    final fresh = await reads.day(day);
    final shown = c.read(dayViewProvider(day)).requireValue.raw;
    expect(shown.entries, fresh.entries);
    expect(shown.totals, fresh.totals);
  }
  for (final sub in subs) {
    sub.close();
  }
  double p95(List<int> values) {
    values.sort();
    return values[(values.length * .95).ceil() - 1] / 1000;
  }

  return DayViewBenchmarkResult(
    p95(cold),
    p95(write),
    settle.elapsedMicroseconds / 1000,
    maxReads,
  );
}
