import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/progress/presentation/goal_progress_card.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_fixtures.dart';
import '../../targets/application/targets_app_harness.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/progress_support.dart';

FbBarChart _chart(WidgetTester tester, String key) =>
    tester.widget<FbBarChart>(find.byKey(ValueKey(key)));

List<FbBar> _bars(WidgetTester tester, String key) => _chart(tester, key).bars;

FbChartRange _weightWindow(WidgetTester tester) => tester
    .widget<FbTimeSeriesChart>(
      find.byKey(const ValueKey('progress-weight-chart')),
    )
    .range;

const _macros = [
  'progress-macro-protein',
  'progress-macro-carbs',
  'progress-macro-fat',
  'progress-macro-fiber',
];

void _tallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 3200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Every chart shows [count] bars from [first], and the weight chart the
/// window [start]–[end].
void _expectCharts(
  WidgetTester tester, {
  required int count,
  required DateTime first,
  required DateTime start,
  required DateTime end,
}) {
  for (final key in ['progress-calories-chart', ..._macros]) {
    final bars = _bars(tester, key);
    expect(bars, hasLength(count), reason: key);
    expect(bars.first.at, first, reason: key);
  }
  expect(_weightWindow(tester).start, start);
  expect(_weightWindow(tester).end, end);
}

void main() {
  testWidgets('IN-009 the period selector changes every chart', (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(progressApp(progressOverrides()));
    await tester.pumpAndSettle();

    // Opens on this week (SC-5): 17–23 October, one bar a day.
    _expectCharts(
      tester,
      count: 7,
      first: DateTime.utc(2026, 10, 17),
      start: DateTime.utc(2026, 10, 17),
      end: DateTime.utc(2026, 10, 24),
    );
    // › is off at the current period.
    expect(
      tester
          .widget<FbIconButton>(
            find.byKey(const ValueKey('progress-period-next')),
          )
          .onPressed,
      isNull,
    );

    // This month: a bar per day of October, the later days empty slots.
    await tester.tap(find.byKey(const ValueKey('progress-period-month')));
    await tester.pumpAndSettle();
    _expectCharts(
      tester,
      count: 31,
      first: DateTime.utc(2026, 10),
      start: DateTime.utc(2026, 10),
      end: DateTime.utc(2026, 11),
    );
    expect(_bars(tester, 'progress-calories-chart').last.placeholder, isTrue);

    // One month back: September.
    await tester.tap(find.byKey(const ValueKey('progress-period-previous')));
    await tester.pumpAndSettle();
    _expectCharts(
      tester,
      count: 30,
      first: DateTime.utc(2026, 9),
      start: DateTime.utc(2026, 9),
      end: DateTime.utc(2026, 10),
    );

    // The phase (1 July → today, 115 days): weekly bars from the phase
    // start, then Saturday weeks.
    await tester.tap(find.byKey(const ValueKey('progress-period-phase')));
    await tester.pumpAndSettle();
    _expectCharts(
      tester,
      count: 17,
      first: DateTime.utc(2026, 7),
      start: DateTime.utc(2026, 7),
      end: DateTime.utc(2026, 10, 24),
    );
    expect(
      _bars(tester, 'progress-calories-chart')[1].at,
      DateTime.utc(2026, 7, 4),
    );
  });

  testWidgets('UX-052 Try again refreshes the failed upstream data, not only '
      "the section's own", (tester) async {
    _tallPhone(tester);
    var failing = true;
    await tester.pumpWidget(
      progressApp(progressOverrides(failLogs: () => failing)),
    );
    await tester.pumpAndSettle();
    const goalError = ValueKey('progress-goal-error');
    expect(find.byKey(goalError), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-calories-chart')), findsNothing);

    // The diary read works again; the goal card's Try again recovers the
    // whole chain (the period view and its days, not just the card).
    failing = false;
    await tester.tap(
      find.descendant(
        of: find.byKey(goalError),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(goalError), findsNothing);
    expect(
      find.byKey(const ValueKey('progress-calories-chart')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(GoalProgressCard),
        matching: find.byType(FbProgressBar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('DY-004 IN-002 marking a day from the chart hatches its bar and '
      'undo restores it', (tester) async {
    _tallPhone(tester);
    final h = TargetsAppHarness();
    await tester.runAsync(() async {
      // Weekly targets from 20 September, written by the single writer
      // (the setup command waits on fake-async timers inside a widget test).
      await h.apply([
        PutProfile(setupInput().profile),
        PutGoalPhase(
          loseHalf.toRecord(id: h.ids.next(), start: LocalDate(2026, 9, 20)),
        ),
        PutTargetSettings(
          TargetSettingsRecord(
            id: h.ids.next(),
            revision: 1,
            effectiveFrom: LocalDate(2026, 9, 20),
            baseKcal: setupBase,
            basisWeightKg: 80,
          ),
        ),
      ]);
      await insertEntries(h.db, [
        entryRow(
          1,
          date: '2026-10-18',
          slotId: DefaultSlots.lunchId,
          kcal: 2400,
        ),
      ]);
    });
    h.advanceDays(3); // Tuesday 20 October
    final today = h.date;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(h.db),
          changeSetApplierProvider.overrideWithValue(h.applier),
          clockProvider.overrideWithValue(h.clock),
          idGeneratorProvider.overrideWithValue(h.ids),
          undoStackProvider.overrideWithValue(h.undo),
          todayProvider.overrideWith((ref) => Stream.value(today)),
        ],
        child: phoneApp(const ProgressScreen()),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    // Sunday 18 October is the week's second bar: counted, solid.
    const calories = 'progress-calories-chart';
    expect(_bars(tester, calories)[1].value, 2400);
    expect(_bars(tester, calories)[1].style, FbBarStyle.solid);

    _chart(tester, calories).onSelect!(1);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('progress-mark-incomplete')));
    await settle();
    expect(_bars(tester, calories)[1].style, FbBarStyle.hatched);
    expect(_bars(tester, calories)[1].value, 2400, reason: 'still drawn');

    await tester.tap(find.byType(SnackBarAction));
    await settle();
    expect(_bars(tester, calories)[1].style, FbBarStyle.solid);

    // Take the app down so the database streams and undo timers end.
    h.undo.dispose();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 6));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
