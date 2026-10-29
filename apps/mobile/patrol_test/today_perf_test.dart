import 'dart:io';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/app_database.dart' show DiaryEntriesCompanion;
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import '../test/features/diary/support/diary_fixtures.dart'
    show entryRow, insertEntries;
import 'support/today_test_support.dart';

/// Median in milliseconds (nearest rank).
double _median(List<int> micros) {
  final sorted = List.of(micros)..sort();
  return sorted[(sorted.length * .5).ceil() - 1] / 1000;
}

/// p95 in milliseconds (nearest rank).
double _p95(List<int> micros) {
  final sorted = List.of(micros)..sort();
  return sorted[(sorted.length * .95).ceil() - 1] / 1000;
}

/// 30 entries on [date], spread over the four default meals.
List<DiaryEntriesCompanion> _thirtyEntries(LocalDate date, int dayIndex) {
  const meals = [
    DefaultSlots.breakfastId,
    DefaultSlots.lunchId,
    DefaultSlots.dinnerId,
    DefaultSlots.snacksId,
  ];
  return [
    for (var n = 0; n < 30; n++)
      entryRow(
        dayIndex * 100 + n + 1,
        date: '$date',
        slotId: meals[n < 24 ? n ~/ 8 : 3],
        kcal: 80.0 + n * 7,
        occurredAtUtc: DateTime.utc(
          date.year,
          date.month,
          date.day,
          7 + (n < 24 ? n ~/ 8 : 3) * 4,
          n % 8 * 5,
        ).millisecondsSinceEpoch,
      ),
  ];
}

/// The A08 D17 gate on the device (card exit 3, "Today renders in < 100 ms
/// from tap with 30 entries on the A55"), run by `make test-it`. The host
/// benchmarks (P1-P3, W1, W2) are the asserted gate; this prints the device
/// numbers (median and p95, numbers only), which the owner records from the
/// A55 (backlog item).
///
/// "From tap" is from the input event to the end of the first frame in which
/// the target day renders its loaded sliver list, in three cases, 20 runs each
/// after 2 warm-ups: (a) the previous-day button to a prefetched day, (b) a
/// jump to an uncached day (the date picker's result, `TodayController.goTo`:
/// the calendar dialog itself isn't part of the budget), (c) selecting the
/// Today tab again from another tab. Every target day has 30 entries. The real
/// app, the real router and a throw-away database file in the cache directory;
/// no API is reachable.
///
/// The only assertions are generous sanity bounds so an emulator or a slow
/// CI runner doesn't flake.

/// drift opens the database in a background isolate and sends the location's
/// resolvers there, so they must capture only the path (a closure written in
/// the test body would capture the WidgetTester and can't be sent).
DatabaseLocation isolatedLocation(String profileKey, String path) =>
    DatabaseLocation(
      profileKey: profileKey,
      root: () async => path,
      temporary: () async => path,
    );

void main() {
  patrolTest('HM-009 DY-020 A08 device perf', ($) async {
    const warmUps = 2;
    const runs = 20;
    final config = AppConfig.fromEnvironment();
    final cache = await getTemporaryDirectory();
    final root = await cache.createTemp('fb_today_perf');
    addTearDown(() {
      try {
        root.deleteSync(recursive: true);
      } on FileSystemException {
        // The cache directory is cleaned by the system anyway.
      }
    });
    final container = ProviderContainer(
      overrides: [
        ...appOverrides(config),
        databaseLocationProvider.overrideWithValue(
          isolatedLocation('it-today-perf', root.path),
        ),
      ],
    );
    addTearDown(container.dispose);
    final tester = $.tester;

    // Today, yesterday and one far day per jump (every second day, so no
    // jump target is a neighbour of another and none is prefetched).
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final yesterday = today.plusDays(-1);
    final jumps = [
      for (var i = 0; i < warmUps + runs; i++) today.plusDays(-4 - 2 * i),
    ];
    final db = container.read(appDatabaseProvider);
    await insertEntries(db, [
      ..._thirtyEntries(today, 1),
      ..._thirtyEntries(yesterday, 2),
      for (final (i, date) in jumps.indexed) ..._thirtyEntries(date, 10 + i),
    ]).timeout(
      const Duration(seconds: 30),
      onTimeout: () => fail('Timed out seeding the performance diary'),
    );

    // Do not settle the continuously pulsing loading skeletons.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FitnessBuddyApp(),
      ),
    );
    expect($(TodayScreen), findsOneWidget);

    Future<void> waitFor(bool Function() done, String reason) async {
      final watch = Stopwatch()..start();
      while (!done()) {
        if (watch.elapsed > const Duration(seconds: 30)) {
          fail('Timed out waiting for $reason');
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> rest() async {
      final watch = Stopwatch()..start();
      while (watch.elapsed < const Duration(milliseconds: 500)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // Only wait for the measured pager/fling, independent of skeletons or
    // other tickers. WidgetTester's default settle timeout is ten minutes.
    Future<void> finishMotion() async {
      await tester.pump(const Duration(milliseconds: 16));
      await waitFor(
        () => !tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .any((state) => state.position.isScrollingNotifier.value),
        'the measured scrolling motion to finish',
      );
    }

    /// Frames pumped one by one (no fixed delay) from the start of
    /// [input] until [done] holds; returns the microseconds it took.
    Future<int> measure(
      Future<void> Function() input,
      bool Function() done,
      String reason,
    ) async {
      final timer = Stopwatch()..start();
      await input();
      while (!done()) {
        if (timer.elapsed > const Duration(seconds: 10)) {
          fail('Timed out waiting for $reason');
        }
        await tester.pump();
      }
      return timer.elapsedMicroseconds;
    }

    final controller = container.read(todayControllerProvider.notifier);
    await waitFor(
      () => showsLoadedDay(tester, today),
      'Today to render its loaded day',
    );
    // Yesterday is prefetched once today has its data (A08 D3).
    await waitFor(
      () => container.read(dayViewProvider(yesterday)).hasValue,
      'yesterday to be prefetched',
    );

    // (a) The previous-day button to the prefetched yesterday, and back.
    final prefetched = <int>[];
    for (var i = 0; i < warmUps + runs; i++) {
      await rest();
      final micros = await measure(
        () => tester.tap(find.byTooltip('Previous day')),
        () => showsLoadedDay(tester, yesterday),
        'yesterday to show its loaded day',
      );
      if (i >= warmUps) prefetched.add(micros);
      await rest();
      await tester.tap(find.byTooltip('Next day'));
      await waitFor(() => showsLoadedDay(tester, today), 'Today to come back');
    }

    // (b) A jump to a day that isn't cached, and back.
    final uncached = <int>[];
    for (final (i, date) in jumps.indexed) {
      await rest();
      expect(
        container.exists(dayViewProvider(date)),
        isFalse,
        reason: '$date must not be loaded before the jump',
      );
      final micros = await measure(
        () async => controller.goTo(date),
        () => showsLoadedDay(tester, date),
        '$date to show its loaded day',
      );
      if (i >= warmUps) uncached.add(micros);
      await rest();
      controller.goTo(today);
      await waitFor(() => showsLoadedDay(tester, today), 'Today to come back');
    }

    // (c) Another tab and back to Today.
    final reselect = <int>[];
    for (var i = 0; i < warmUps + runs; i++) {
      await tester.tap($(NavigationBar).$('Progress'));
      await rest();
      final micros = await measure(
        () => tester.tap($(NavigationBar).$('Today')),
        () => showsLoadedDay(tester, today),
        'Today to show its loaded day again',
      );
      if (i >= warmUps) reselect.add(micros);
    }

    // Debug-mode Patrol timings are pessimistic. The A55 profile run is
    // collected separately in backlog #90; these are sanity checks only.
    Future<void> frameTimings(
      String name,
      Future<void> Function() action,
    ) async {
      final frames = <FrameTiming>[];
      void record(List<FrameTiming> batch) => frames.addAll(batch);
      // Drain the preceding case's batched timing report before subscribing.
      await finishMotion();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      SchedulerBinding.instance.addTimingsCallback(record);
      try {
        await action();
        // Engine reports timings in batches. Keep the callback through the
        // final animation frames and the report delivery. Wait without pumping
        // idle frames into the measured distribution.
        await finishMotion();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(record);
      }
      expect(frames, isNotEmpty, reason: name);
      for (final (phase, micros) in [
        ('build', [for (final f in frames) f.buildDuration.inMicroseconds]),
        ('raster', [for (final f in frames) f.rasterDuration.inMicroseconds]),
      ]) {
        final worst = micros.reduce((a, b) => a > b ? a : b) / 1000;
        debugPrint(
          'A08 perf device $name $phase: ${micros.length} frames, '
          'median ${_median(micros).toStringAsFixed(1)} ms, '
          'p95 ${_p95(micros).toStringAsFixed(1)} ms, '
          'worst ${worst.toStringAsFixed(1)} ms',
        );
        expect(worst, lessThan(2000), reason: '$name $phase sanity only');
      }
    }

    await rest();
    // CI disables animations; record the frames the device actually renders.
    await frameTimings('day transition', () async {
      await tester.tap(find.byTooltip('Previous day'));
      // The page animation can start a frame after the tap; wait (bounded)
      // instead of asserting on the first idle frame.
      await waitFor(
        () => showsLoadedDay(tester, yesterday),
        'yesterday after the measured day transition',
      );
    });
    await tester.tap(find.byTooltip('Next day'));
    await rest();
    await waitFor(
      () => showsLoadedDay(tester, today),
      'Today before expanded scroll',
    );
    final choices = container.read(diaryViewStateProvider.notifier);
    for (final slot in DefaultSlots.all) {
      choices.toggleSlot(slot.id);
    }
    await rest();
    final scrollView = find.descendant(
      of: dayPage(today),
      matching: find.byType(CustomScrollView),
    );
    final scrollable = find.descendant(
      of: scrollView,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await frameTimings('expanded 30-entry day scroll', () async {
      for (final dy in [-500.0, -500.0, -500.0, 500.0, 500.0, 500.0]) {
        await tester.fling(scrollView, Offset(0, dy), 1500);
        await finishMotion();
      }
    });

    for (final (name, micros) in [
      ('prefetched swipe (a)', prefetched),
      ('uncached jump (b)', uncached),
      ('tab reselect (c)', reselect),
    ]) {
      debugPrint(
        'A08 perf device $name: ${micros.length} runs after $warmUps '
        'warm-ups, median ${_median(micros).toStringAsFixed(1)} ms, '
        'p95 ${_p95(micros).toStringAsFixed(1)} ms',
      );
      expect(micros, hasLength(runs));
      // Sanity only; the budget (< 100 ms for (a) and (b) on the A55) is
      // checked by reading the numbers on the phone.
      expect(_p95(micros), lessThan(2000), reason: name);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
