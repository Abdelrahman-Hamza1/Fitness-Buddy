// UX-007 on the device (A42 D1, review fix 6): frame times of the common
// screens under normal frame scheduling. Not run in CI.
//
// Run on the phone in profile mode with `make perf-device` (or, from
// apps/mobile, with the phone connected over adb):
//   flutter test integration_test/jank_benchmark_test.dart --profile \
//     --flavor dev --dart-define-from-file=config/dev.json -d <device-id>
// It seeds ten months of diary and 120 workouts into a throw-away file
// profile, starts the real app wiring and, with the binding's fully live
// `benchmarkLive` frame policy (the engine schedules every frame, as in the
// app; the test never pumps), records the frames (`watchPerformance`) of
// real flings: Today's day pages swiped back and forth; Progress scrolled
// and switched between periods; the long workout history scrolled. Each
// fling must actually move its list. Per journey it prints the 90th/99th
// percentile and worst build and raster times and the share of frames over
// 16 ms, and fails when any frame is over 16 ms ("no frame > 16 ms on common
// screens", `09` §6). Record the printed lines in A42's Outcome.
import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../test/acceptance/support/acceptance_app.dart'
    show SeededProfile, profileSeed;

const double _budgetMs = 16;

/// Lets real time pass (the engine draws meanwhile; nothing is pumped).
Future<void> _wait([int ms = 800]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// Waits in real time until [done], at most 20 s.
Future<void> _until(bool Function() done) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > const Duration(seconds: 20)) fail('timed out');
    await _wait(100);
  }
  await _wait(500);
}

/// The main vertical scroll position of [screen].
ScrollPosition _list(WidgetTester tester, Type screen) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(screen),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    )
    .position;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // covers: UX-007
  testWidgets('UX-007 Today, Progress and workout history: no frame over '
      '$_budgetMs ms on the device, under live frame scheduling', (
    tester,
  ) async {
    expect(kProfileMode, isTrue, reason: 'Run this benchmark with --profile');
    final config = AppConfig.fromEnvironment();
    final cache = await getTemporaryDirectory();
    final root = await cache.createTemp('fb_perf_jank');
    addTearDown(() => root.deleteSync(recursive: true));
    final container = ProviderContainer(
      overrides: [
        ...appOverrides(config),
        databaseLocationProvider.overrideWithValue(
          DatabaseLocation(
            profileKey: 'perf-jank',
            root: () async => root.path,
            temporary: () async => root.path,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final seeded = SeededProfile(
      EntryTime.now(container.read(clockProvider)).localDate,
    );
    for (final ops in profileSeed(
      seeded,
      historyDays: 290,
      extraSessions: 120,
    )) {
      final result = await container
          .read(changeSetApplierProvider)
          .apply(ChangeSet(ops, origin: Origin.direct));
      expect(result.toString(), startsWith('Applied'));
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FitnessBuddyApp(),
      ),
    );
    // From here on the engine schedules every frame, as in the app.
    binding.framePolicy =
        LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
    await _until(() => find.byType(PageView).evaluate().isNotEmpty);
    final router = container.read(appRouterProvider);
    final failures = <String>[];

    Future<void> journey(String key, Future<void> Function() body) async {
      await binding.watchPerformance(body, reportKey: key);
      final report = binding.reportData![key] as Map<String, dynamic>;
      double ms(String field) => (report[field] as num).toDouble();
      final frames = report['frame_count'] as int;
      final buildOver = report['missed_frame_build_budget_count'] as int;
      final rasterOver = report['missed_frame_rasterizer_budget_count'] as int;
      String share(int n) =>
          frames == 0 ? '-' : '${(100 * n / frames).toStringAsFixed(1)} %';
      final buildWorst = ms('worst_frame_build_time_millis');
      final rasterWorst = ms('worst_frame_rasterizer_time_millis');
      stdout.writeln(
        'UX-007 $key: $frames frames; build p90 '
        '${ms('90th_percentile_frame_build_time_millis')} ms, p99 '
        '${ms('99th_percentile_frame_build_time_millis')} ms, max '
        '$buildWorst ms, over 16 ms ${share(buildOver)}; raster p90 '
        '${ms('90th_percentile_frame_rasterizer_time_millis')} ms, p99 '
        '${ms('99th_percentile_frame_rasterizer_time_millis')} ms, max '
        '$rasterWorst ms, over 16 ms ${share(rasterOver)}',
      );
      expect(frames, greaterThan(20), reason: '$key drew frames');
      if (buildWorst > _budgetMs) failures.add('$key build max $buildWorst ms');
      if (rasterWorst > _budgetMs) {
        failures.add('$key raster max $rasterWorst ms');
      }
    }

    /// Flings [screen]'s list by [dy] and requires that it moved.
    Future<void> fling(Type screen, double dy) async {
      final before = _list(tester, screen).pixels;
      await tester.fling(
        find
            .descendant(
              of: find.byType(screen),
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              ),
            )
            .first,
        Offset(0, dy),
        2500,
      );
      await _wait(1200);
      expect(
        _list(tester, screen).pixels,
        isNot(before),
        reason: 'the $screen list moved',
      );
    }

    // Today: swipe five days back and forth; each swipe changes the page.
    await journey('today_swipes', () async {
      final pages = find.byType(PageView).first;
      double page() => tester
          .state<ScrollableState>(
            find.descendant(of: pages, matching: find.byType(Scrollable)).first,
          )
          .position
          .pixels;
      for (final dx in const <double>[300, 300, 300, -300, -300, -300]) {
        final before = page();
        await tester.fling(pages, Offset(dx, 0), 2500);
        await _wait();
        expect(page(), isNot(before), reason: 'the day changed');
      }
    });

    // Progress: scroll its cards and charts, switch the periods.
    router.go(const ProgressRoute());
    await _until(() => find.byType(ProgressScreen).evaluate().isNotEmpty);
    await journey('progress_scroll_periods', () async {
      await fling(ProgressScreen, -700);
      await fling(ProgressScreen, 700);
      for (final period in ['Month', 'Phase', 'Week']) {
        final target = find.text(period);
        expect(target, findsWidgets, reason: period);
        await tester.tap(target.first);
        await _wait();
      }
      await fling(ProgressScreen, -700);
    });

    // The workout history: 122 sessions.
    router.go(const WorkoutHistoryRoute());
    await _until(() => find.byType(WorkoutHistoryScreen).evaluate().isNotEmpty);
    await journey('workout_history_scroll', () async {
      for (var i = 0; i < 3; i++) {
        await fling(WorkoutHistoryScreen, -900);
      }
      for (var i = 0; i < 3; i++) {
        await fling(WorkoutHistoryScreen, 900);
      }
    });

    expect(failures, isEmpty, reason: failures.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 6)));
}
