import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart';
import '../../body/support/weigh_in_sheet_support.dart'
    show SheetRig, button, settle, unmount;
import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/weight_graph_support.dart';

FbTimeSeriesChart chartOf(WidgetTester tester) =>
    tester.widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart));

Future<void> pumpGraph(WidgetTester tester, Widget app) async {
  tester.view
    ..physicalSize = const Size(360, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Taps the point [key] of the weigh-in series, as a tap on the chart does.
Future<void> selectPoint(WidgetTester tester, String key) async {
  chartOf(tester).onSelect!(FbPointRef(series: 0, key: key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('WB-020 IN-004 weigh-ins are points and the trend is a line', (
    tester,
  ) async {
    await pumpGraph(tester, graphApp(graphOverrides()));
    final chart = chartOf(tester);
    expect(chart.series[0].style, FbSeriesStyle.points);
    expect(chart.series[0].selectable, isTrue);
    expect(chart.series[0].points, hasLength(730));
    expect(chart.series[1].style, FbSeriesStyle.line);
    expect(chart.series[1].points, hasLength(730));
    expect(find.text('Tap a point to see details'), findsOneWidget);
  });

  testWidgets('WB-020 the range chips switch 1M, 3M, 6M, 1Y and All; 3M by '
      'default; the choice survives leaving and returning', (tester) async {
    final container = ProviderContainer.test(
      overrides: graphOverrides(range: null),
    );
    Widget app() => UncontrolledProviderScope(
      container: container,
      child: phoneApp(const WeightGraphScreen()),
    );
    await pumpGraph(tester, app());
    for (final label in ['1M', '3M', '6M', '1Y', 'All']) {
      expect(find.widgetWithText(FbChoiceChip, label), findsOneWidget);
    }
    expect(chartOf(tester).range.start, DateTime.utc(2026, 7, 17));
    await tester.tap(find.widgetWithText(FbChoiceChip, '1Y'));
    await tester.pumpAndSettle();
    expect(chartOf(tester).range.start, DateTime.utc(2025, 10, 17));

    await tester.pumpWidget(const SizedBox());
    await pumpGraph(tester, app());
    expect(chartOf(tester).range.start, DateTime.utc(2025, 10, 17));
    await tester.tap(find.widgetWithText(FbChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(chartOf(tester).range.start, DateTime.utc(2024, 10, 18));
    expect(chartOf(tester).panBounds, isNull);
  });

  testWidgets('WB-020 dragging pans back in time and Today resets the '
      'window', (tester) async {
    await pumpGraph(tester, graphApp(graphOverrides()));
    final before = chartOf(tester).range;
    expect(find.widgetWithText(FbChoiceChip, 'Today'), findsNothing);
    chartOf(tester).onRangeChanged!(before.shift(const Duration(days: -20)));
    await tester.pumpAndSettle();
    expect(
      chartOf(tester).range.start,
      before.start.subtract(const Duration(days: 20)),
    );
    await tester.tap(find.widgetWithText(FbChoiceChip, 'Today'));
    await tester.pumpAndSettle();
    expect(chartOf(tester).range, before);
    expect(find.widgetWithText(FbChoiceChip, 'Today'), findsNothing);
  });

  testWidgets("WB-021 the active goal's weight line, the projection cone and "
      'the phase shading are drawn; an unnamed phase shows its goal type '
      'label', (tester) async {
    await pumpGraph(
      tester,
      graphApp(
        graphOverrides(
          weighIns: seededHistory(days: 200, perDay: 0.02),
          phases: [losePhase(graphToday.plusDays(-60))],
        ),
      ),
    );
    final chart = chartOf(tester);
    expect(chart.goal?.label, startsWith('Goal 85'));
    expect(chart.series, hasLength(3));
    expect(chart.series[2].style, FbSeriesStyle.dashedLine);
    expect(chart.bands.single.points, isNotEmpty);
    expect(chart.periods.single.label, 'Lose weight');
    expect(chart.periods.single.tone, FbPeriodTone.phaseA);
    expect(find.textContaining('at your current trend'), findsOneWidget);
  });

  testWidgets('WB-021 a period from chartHighlightPeriodsProvider is shaded '
      'and labelled Ramadan', (tester) async {
    await pumpGraph(
      tester,
      graphApp(
        graphOverrides(
          highlights: [
            (start: graphToday.plusDays(-20), end: graphToday.plusDays(-10)),
          ],
        ),
      ),
    );
    final period = chartOf(tester).periods.single;
    expect(period.label, 'Ramadan');
    expect(period.tone, FbPeriodTone.highlight);
  });

  testWidgets('WB-022 tapping a point shows its value, date, note and the '
      'trend that day', (tester) async {
    final history = seededHistory();
    await pumpGraph(tester, graphApp(graphOverrides(weighIns: history)));
    await selectPoint(tester, fixtureId(730));
    final last = history.last;
    expect(
      find.text('${last.input.value.toStringAsFixed(1)} kg'),
      findsOneWidget,
    );
    expect(find.text('After the run'), findsOneWidget);
    expect(find.textContaining('Oct 17, 2026'), findsOneWidget);
    expect(find.textContaining('that day'), findsOneWidget);
    expect(find.text('Not used for the trend'), findsNothing);
    expect(button('Edit'), findsOneWidget);
    expect(find.text('Tap a point to see details'), findsNothing);
    expect(
      chartOf(tester).selected,
      FbPointRef(series: 0, key: fixtureId(730)),
    );
  });

  testWidgets('LC-010 imperial shows lb on the axis, the details and the '
      'stats', (tester) async {
    await pumpGraph(
      tester,
      graphApp(graphOverrides(units: UnitSystem.imperial)),
    );
    final chart = chartOf(tester);
    expect(chart.series[1].points.last.value, greaterThan(150));
    await selectPoint(tester, fixtureId(730));
    expect(find.textContaining('lb that day'), findsOneWidget);
    expect(find.textContaining(' lb'), findsWidgets);
  });

  testWidgets('WB-023 the stats show change since the start, this month, the '
      'average since a date and why a monthly target is missing', (
    tester,
  ) async {
    await pumpGraph(tester, graphApp(graphOverrides()));
    expect(find.text('Summary'), findsOneWidget);
    expect(find.textContaining('Change since'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.textContaining('Average since'), findsOneWidget);
    expect(find.text('Set a goal to see a monthly target'), findsOneWidget);
  });

  testWidgets('one weigh-in: one point, no projection, stats say they show '
      'after 2 weeks', (tester) async {
    await pumpGraph(
      tester,
      graphApp(graphOverrides(weighIns: seededHistory(days: 1))),
    );
    expect(chartOf(tester).series[0].points, hasLength(1));
    expect(chartOf(tester).bands, isEmpty);
    expect(find.text('Shows after 2 weeks of weigh-ins'), findsOneWidget);
  });

  testWidgets('UX-050 no weigh-ins: the empty state offers Log weigh-in', (
    tester,
  ) async {
    await pumpGraph(tester, graphApp(graphOverrides(weighIns: const [])));
    expect(find.text('No weigh-ins yet'), findsOneWidget);
    expect(button('Log weigh-in'), findsOneWidget);
    expect(find.byType(FbTimeSeriesChart), findsNothing);
  });

  testWidgets('UX-052 an error shows Try again', (tester) async {
    await pumpGraph(
      tester,
      graphApp(graphOverrides(graphError: StateError('read failed'))),
    );
    expect(find.text("Couldn't load your weight"), findsOneWidget);
    expect(button('Try again'), findsOneWidget);
  });

  group('with the write path', () {
    Future<SheetRig> pumpWithRig(
      WidgetTester tester,
      List<WeighInDraft> drafts,
    ) async {
      final rig = SheetRig();
      await rig.seed(tester, drafts);
      tester.view
        ..physicalSize = const Size(360, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...rig.overrides, ...graphExtras()],
          child: phoneApp(const WeightGraphScreen()),
        ),
      );
      await settle(tester);
      return rig;
    }

    testWidgets('WB-022 WB-003 a weigh-in not used for the trend says so, and '
        "Use for trend makes it the day's choice with undo", (tester) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
        weighInDraft(97.6, date: day17, hour: 9),
      ]);
      await selectPoint(tester, fixtureId(3));
      expect(find.text('Not used for the trend'), findsOneWidget);
      await tester.tap(button('Use for trend'));
      await settle(tester);
      final live = await rig.live(tester);
      expect(
        live.firstWhere((w) => w.id == fixtureId(3)).preferredForDay,
        isTrue,
      );
      expect(find.text('Trend weigh-in for the day changed'), findsOneWidget);
      expect(find.text('Not used for the trend'), findsNothing);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      final undone = await rig.live(tester);
      expect(
        undone.firstWhere((w) => w.id == fixtureId(3)).preferredForDay,
        isFalse,
      );
      await unmount(tester, rig);
    });

    testWidgets('WB-022 Edit opens the weigh-in sheet in edit mode', (
      tester,
    ) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
      ]);
      await selectPoint(tester, fixtureId(2));
      await tester.tap(button('Edit'));
      await settle(tester);
      expect(find.byType(WeighInSheet), findsOneWidget);
      expect(find.text('Edit weigh-in'), findsOneWidget);
      await unmount(tester, rig);
    });
  });
}
