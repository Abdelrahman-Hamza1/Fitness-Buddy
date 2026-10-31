// The Progress tab's device benchmark (A16 WP6, T15, PA5). Not run in CI.
//
// Run on the phone in profile mode with `make perf-device` (A42), or from
// apps/mobile with the device connected over adb:
//   flutter test integration_test/progress_benchmark_test.dart --profile \
//     --flavor dev --dart-define-from-file=config/dev.json \
//     -d <device-id> --dart-define=A16_DEVICE=A55
// It seeds one year of synthetic data (ProgressWorkload) into an in-memory
// database, then for the current month and the 1-year phase times, per
// chart, from the period being set to the first painted frame of that chart
// containing its loaded data (the SQL reads, the series and target build
// and the layout included; every run starts cold). It prints p50/p95 per
// chart and period and fails above 300 ms (exit criterion 1). Record the
// printed lines in the A16 Progress log.
import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_period.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/features/progress/support/progress_workload.dart';
import '../test/features/today/presentation/support/today_support.dart'
    show phoneApp;

const int _runs = 12;
const double _budgetMs = 300;

/// One period to time: its kind, its bar count and its first day.
typedef _Case = ({ProgressPeriodKind kind, int bars, DateTime start});

double _percentile(List<double> sorted, double p) =>
    sorted[((sorted.length * p).ceil() - 1).clamp(0, sorted.length - 1)];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("IN-002 one year: each chart's first painted frame with loaded "
      'data within 300 ms on the device', (tester) async {
    expect(kProfileMode, isTrue, reason: 'Run this benchmark with --profile');
    const device = String.fromEnvironment('A16_DEVICE');
    expect(device, isNotEmpty, reason: 'Supply --dart-define=A16_DEVICE=...');
    // Tall enough that every section of the list is built.
    tester.view
      ..physicalSize = const Size(1080, 7200)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final workload = ProgressWorkload();
    await workload.seed();
    final h = workload.h;
    final today = h.date;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(h.db),
        changeSetApplierProvider.overrideWithValue(h.applier),
        clockProvider.overrideWithValue(h.clock),
        idGeneratorProvider.overrideWithValue(h.ids),
        undoStackProvider.overrideWithValue(h.undo),
        todayProvider.overrideWith((ref) => Stream.value(today)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: phoneApp(const ProgressScreen()),
      ),
    );
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find
          .byKey(const ValueKey('progress-calories-chart'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final cases = <_Case>[
      (
        kind: ProgressPeriodKind.month,
        bars: 31,
        start: DateTime.utc(today.year, today.month),
      ),
      (
        kind: ProgressPeriodKind.phase,
        bars: 53,
        start: DateTime.utc(
          workload.first.year,
          workload.first.month,
          workload.first.day,
        ),
      ),
    ];
    bool barsReady(String key, _Case c) {
      final found = find.byKey(ValueKey(key)).evaluate();
      if (found.isEmpty) return false;
      final bars = (found.first.widget as FbBarChart).bars;
      return bars.length == c.bars && bars.first.at == c.start;
    }

    final checks = <String, bool Function(_Case)>{
      'calories': (c) => barsReady('progress-calories-chart', c),
      'macros': (c) => barsReady('progress-macro-protein', c),
      'weight': (c) {
        final found = find
            .byKey(const ValueKey('progress-weight-chart'))
            .evaluate();
        if (found.isEmpty) return false;
        final chart = found.first.widget as FbTimeSeriesChart;
        return chart.range.start == c.start &&
            chart.series.first.points.isNotEmpty;
      },
      'goal': (c) {
        final card = container.read(goalProgressCardProvider);
        return card.hasValue &&
            !card.isLoading &&
            find.byType(FbProgressBar).evaluate().isNotEmpty;
      },
    };
    final timings = <String, List<double>>{};
    final controller = container.read(
      progressPeriodControllerProvider.notifier,
    );
    for (var run = 0; run < _runs; run++) {
      for (final c in cases) {
        // Cold: the next read goes to SQL and rebuilds the series.
        container
          ..invalidate(progressLogsProvider)
          ..invalidate(progressDaysProvider)
          ..invalidate(weighInsProvider);
        final watch = Stopwatch()..start();
        controller.setKind(c.kind);
        final pending = {...checks.keys};
        while (pending.isNotEmpty && watch.elapsed.inSeconds < 20) {
          await tester.pump();
          for (final name in [...pending]) {
            if (checks[name]!(c)) {
              timings
                  .putIfAbsent('${c.kind.name} $name', () => [])
                  .add(watch.elapsedMicroseconds / 1000);
              pending.remove(name);
            }
          }
        }
        expect(
          pending,
          isEmpty,
          reason: '${c.kind.name}: $pending never ready',
        );
      }
    }

    final failures = <String>[];
    for (final MapEntry(key: name, value: values) in timings.entries) {
      final sorted = [...values]..sort();
      final p50 = _percentile(sorted, .5);
      final p95 = _percentile(sorted, .95);
      // Synthetic data only: the device, the chart and the timings.
      // ignore: avoid_print
      print(
        'A16 progress ${Platform.operatingSystem}/$device $name: '
        'p50 ${p50.toStringAsFixed(1)} ms, p95 ${p95.toStringAsFixed(1)} ms '
        '(${values.length} runs)',
      );
      if (p95 > _budgetMs) failures.add(name);
    }
    expect(failures, isEmpty, reason: 'over $_budgetMs ms at p95');
    await tester.pumpWidget(const SizedBox());
  });
}
