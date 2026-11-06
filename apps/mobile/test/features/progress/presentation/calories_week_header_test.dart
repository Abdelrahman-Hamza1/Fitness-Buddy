import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/progress/application/weekly_summary_providers.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/progress_support.dart';

// T-P6 (A63 PA9, moved to A62, backlog #292): A62's knowledge-aware week
// next to A63's calories week header and dashed future slots.

/// Tuesday 20 October 2026: the Saturday week 17–23 October has Sat, Sun
/// and Mon elapsed, today in progress and Wed–Fri still to come.
final LocalDate _today = LocalDate(2026, 10, 20);
final LocalDate _weekStart = LocalDate(2026, 10, 17);
final LocalDate _estimateDay = LocalDate(2026, 10, 18);

Nutrients _food(double kcal) => Nutrients(
  kcal: kcal,
  protein: kcal / 16,
  carbs: kcal / 9,
  fat: kcal / 32,
  fiber: 18 + kcal / 400,
);

/// Steady logging before the week, food on Sat and Mon, a little today,
/// and on Sunday either nothing or a day estimate of [estimateKcal].
List<DayLog> _logs({double? estimateKcal}) => [
  for (final log in progressLogs())
    if (log.date.isBefore(_weekStart)) log,
  DayLog(date: _weekStart, totals: _food(2050), entryCount: 4),
  if (estimateKcal != null)
    DayLog(
      date: _estimateDay,
      intake: IntakeTotals.ofDayEstimate(estimateKcal),
      entryCount: 0,
    ),
  DayLog(date: LocalDate(2026, 10, 19), totals: _food(1980), entryCount: 5),
  DayLog(date: _today, totals: _food(900), entryCount: 2),
];

List<Override> _overrides(List<DayLog> logs) => [
  for (final base in progressOverrides(logs: logs))
    if (base.origin != clockProvider && base.origin != todayProvider) base,
  clockProvider.overrideWithValue(
    ManualClock(DateTime.utc(2026, 10, 20, 9), offsetMinutes: 180),
  ),
  todayProvider.overrideWith((ref) => Stream.value(_today)),
];

Future<WeeklySummary> _pump(WidgetTester tester, List<DayLog> logs) async {
  await tester.pumpWidget(
    // A new scope per data set (its overrides can't change).
    KeyedSubtree(
      key: ValueKey(logs.length),
      child: progressApp(_overrides(logs)),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ProgressScreen)),
  );
  final summary = container.read(weeklySummaryProvider(_weekStart)).value;
  expect(summary, isNotNull);
  return summary!;
}

String _average(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('progress-week-average')),
        matching: find.byType(Text),
      ),
    )
    .data!;

String _keyLine(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('progress-week-line'))).data!;

void main() {
  testWidgets('IN-001 IN-002 D-096 D-097 T-P6 mixed food + day-estimate week: '
      'averages and In target include the estimate, protein and fiber '
      'leave it out, estimate bars hatched next to dashed future slots, '
      'the header average shows ~', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 3200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The same week without the estimate: Sunday is simply not counted.
    final base = await _pump(tester, _logs());
    expect(base.estimated, isFalse);
    expect(_average(tester), isNot(contains('~')));
    final target = base.averageTargetKcal!;

    // Sunday gets a day estimate right on its (fixed) target.
    final mixed = await _pump(
      tester,
      _logs(estimateKcal: target.roundToDouble()),
    );

    // (a) The calorie average and "In target" include the estimate: it
    // adds to both targetDays and daysWithinTarget (A62 D10).
    expect(mixed.countedDays, base.countedDays + 1);
    expect(mixed.targetDays, base.targetDays + 1);
    expect(mixed.daysWithinTarget, base.daysWithinTarget + 1);
    expect(
      mixed.averageKcal,
      closeTo((2050 + 1980 + target.roundToDouble()) / 3, 1e-6),
    );
    expect(mixed.averageTargetKcal, closeTo(target, 1e-6));
    expect(mixed.estimated, isTrue);

    // (b) Protein and fiber count only days whose values are known: the
    // day estimate has none.
    expect(mixed.proteinTargetDays, base.proteinTargetDays);
    expect(mixed.proteinDaysHit, base.proteinDaysHit);
    expect(mixed.averageFiber, base.averageFiber);

    // The header reads those fields, never recomputing them: "~" on the
    // average and the incremented In target count.
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(_average(tester), startsWith('avg ~'));
    expect(
      _keyLine(tester),
      contains(
        l10n.progressWeekInTarget(mixed.daysWithinTarget, mixed.targetDays),
      ),
    );
    expect(
      _keyLine(tester),
      contains(
        l10n.progressWeekProtein(mixed.proteinDaysHit, mixed.proteinTargetDays),
      ),
    );

    // (c) One chart: the estimated Sunday hatched, food days solid, today
    // faint, and Wed–Fri dashed placeholders.
    final bars = tester
        .widget<FbBarChart>(
          find.byKey(const ValueKey('progress-calories-chart')),
        )
        .bars;
    expect(bars, hasLength(7));
    expect(
      [for (final b in bars) b.placeholder],
      [
        false, false, false, false, true, true, true, //
      ],
    );
    expect(
      [for (final b in bars.take(4)) b.style],
      [
        FbBarStyle.solid,
        FbBarStyle.hatched,
        FbBarStyle.solid,
        FbBarStyle.faint,
      ],
    );
    expect(bars[1].value, target.roundToDouble());

    // The painter draws them: the hatched Sunday's stroked outline (only
    // hatched bars stroke a rounded rect), then Wed–Fri's dashed outlines
    // (only placeholders draw paths), in bar order.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('progress-calories-chart')),
        matching: find.byType(CustomPaint),
      ),
      paints
        ..something(
          (method, args) =>
              method == #drawRRect &&
              (args[1] as Paint).style == PaintingStyle.stroke,
        )
        ..path(style: PaintingStyle.stroke)
        ..path(style: PaintingStyle.stroke)
        ..path(style: PaintingStyle.stroke),
    );
  });
}
