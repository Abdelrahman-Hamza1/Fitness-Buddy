import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';

import 'diary_fixtures.dart';

/// The timings of [runDiaryBenchmark], in microseconds.
final class DiaryBenchmarkResult {
  /// [micros] of the day query and [yearlyMicros] of the yearly totals.
  new(Iterable<int> micros, Iterable<int> yearlyMicros)
    : micros = List.unmodifiable(micros.toList()..sort()),
      yearlyMicros = List.unmodifiable(yearlyMicros.toList()..sort());

  /// The day query runs, fastest first.
  final List<int> micros;

  /// The yearly totals query runs, fastest first.
  final List<int> yearlyMicros;

  /// The day query's median, ms.
  double get medianMs => _percentile(micros, 0.5);

  /// The day query's 95th percentile (nearest rank), ms.
  double get p95Ms => _percentile(micros, 0.95);

  /// The yearly totals' median, ms.
  double get yearlyMedianMs => _percentile(yearlyMicros, 0.5);

  static double _percentile(List<int> sorted, double p) {
    final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
    return sorted[rank - 1] / 1000;
  }

  /// One line of numbers, no row values.
  String summary(String where) =>
      'A06 diary benchmark ($where): day query with 30 entries in a '
      '5,500-entry year, ${micros.length} runs: median '
      '${medianMs.toStringAsFixed(2)} ms, p95 ${p95Ms.toStringAsFixed(2)} ms; '
      'yearly daily-totals query median '
      '${yearlyMedianMs.toStringAsFixed(2)} ms';
}

/// Seeds a 5,500-entry year (30 entries on the busiest day, 2026-06-15) and
/// times `DiaryReads.day` (the first emission of `watchDay`: slots, groups,
/// entries, mark, mapped to the domain) through [db]'s connection. Shared by
/// the host test and the on-device Patrol test.
Future<DiaryBenchmarkResult> runDiaryBenchmark(
  AppDatabase db, {
  int warmUps = 20,
  int runs = 200,
}) async {
  final slots = DefaultSlots.all;
  var n = 0;
  final rows = <DiaryEntriesCompanion>[];
  final start = LocalDate(2026, 1, 1);
  for (var d = 0; d < 365; d++) {
    final date = LocalDate.fromEpochDay(start.epochDay + d);
    final perDay = date == LocalDate(2026, 6, 15) ? 30 : 15;
    for (var i = 0; i < perDay; i++) {
      n++;
      rows.add(
        entryRow(
          n,
          date: '$date',
          slotId: slots[i % slots.length].id,
          occurredAtUtc: DateTime.utc(
            date.year,
            date.month,
            date.day,
            6 + i % 14,
            i,
          ).millisecondsSinceEpoch,
        ),
      );
    }
  }
  await insertEntries(db, rows);

  final reads = DiaryRepository(db).reads;
  final day = LocalDate(2026, 6, 15);
  final micros = <int>[];
  final watch = Stopwatch();
  for (var i = 0; i < warmUps + runs; i++) {
    watch
      ..reset()
      ..start();
    final result = await reads.day(day);
    watch.stop();
    if (result.entries.length != 30) {
      throw StateError('benchmark day has ${result.entries.length} entries');
    }
    if (i >= warmUps) micros.add(watch.elapsedMicroseconds);
  }
  final yearly = <int>[];
  for (var i = 0; i < 20; i++) {
    watch
      ..reset()
      ..start();
    await reads.dailyTotals(start, LocalDate(2026, 12, 31));
    watch.stop();
    yearly.add(watch.elapsedMicroseconds);
  }
  return DiaryBenchmarkResult(micros, yearly);
}
