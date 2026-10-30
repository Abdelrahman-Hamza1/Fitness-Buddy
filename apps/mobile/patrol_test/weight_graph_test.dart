import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';
import 'support/today_test_support.dart';

/// A weigh-in ID of the seeded history.
String _id(int n) =>
    '0199e3c2-5b1a-7c3d-8e4f-${n.toRadixString(16).padLeft(12, '0')}';

/// A15a D22 on the device: two years of daily weigh-ins, the graph opened
/// from Today's weight card, every range, a pan with frame timings printed
/// (a sanity bound only; the A55 profile run is the owner's item), a point
/// selected and its Edit sheet opened.
void main() {
  patrolTest(
    'A15 weight graph ranges pan and point edit with two years of weigh-ins',
    ($) async {
      final container = await bootApp(
        $,
        'it-weight-graph',
        rootName: 'fb_weight_graph_it',
      );
      final tester = $.tester;
      final clock = container.read(clockProvider);
      final today = EntryTime.now(clock).localDate;

      // 730 days before today, 08:00 local, one change set.
      await tester.runAsync(
        () => container
            .read(changeSetApplierProvider)
            .apply(
              ChangeSet([
                for (var i = 1; i <= 730; i++)
                  CreateWeighIn(
                    _id(i),
                    WeighInDraft(
                      time: EntryTime.fromLocal(
                        LocalDateTime(today.plusDays(-i), hour: 8),
                        clock,
                      ),
                      input: WeighInInput(
                        ((90 + i * 0.01 + (i % 7) * 0.1) * 10).round() / 10,
                        MassUnit.kilogram,
                      ),
                    ),
                  ),
              ], origin: Origin.direct),
            ),
      );

      // Today's weight card, third row.
      final row = find.descendant(
        of: find.descendant(
          of: dayPage(today),
          matching: find.byType(WeightCard),
        ),
        matching: find.text('Weight graph'),
      );
      await waitUntil(
        tester,
        () => row.evaluate().isNotEmpty,
        "the weight card's graph row",
      );
      await revealDayWidget(tester, row, today);
      await tapExactly(tester, row, 'the weight graph row');
      await waitUntil(
        tester,
        () => find.byType(FbTimeSeriesChart).evaluate().isNotEmpty,
        'the weight graph',
      );

      for (final label in ['1M', '6M', '1Y', 'All', '3M']) {
        await tapExactly(
          tester,
          find.widgetWithText(FbChoiceChip, label),
          'the $label chip',
        );
        await pumpFor(tester, const Duration(milliseconds: 400));
      }

      // Pan on 1Y with frame timings.
      await tapExactly(
        tester,
        find.widgetWithText(FbChoiceChip, '1Y'),
        'the 1Y chip',
      );
      await pumpFor(tester, const Duration(milliseconds: 400));
      final frames = <FrameTiming>[];
      void record(List<FrameTiming> batch) => frames.addAll(batch);
      SchedulerBinding.instance.addTimingsCallback(record);
      try {
        final chart = find.byType(FbTimeSeriesChart);
        final gesture = await tester.startGesture(tester.getCenter(chart));
        for (var i = 0; i < 60; i++) {
          await gesture.moveBy(const Offset(4, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await pumpFor(tester, const Duration(milliseconds: 600));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(record);
      }
      expect(find.widgetWithText(FbChoiceChip, 'Today'), findsOneWidget);
      if (frames.isNotEmpty) {
        double worstMs(Duration Function(FrameTiming f) of) =>
            frames
                .map((f) => of(f).inMicroseconds)
                .reduce((a, b) => a > b ? a : b) /
            1000;
        final build = worstMs((f) => f.buildDuration);
        final raster = worstMs((f) => f.rasterDuration);
        debugPrint(
          'A15 weight graph pan (debug build, sanity only): '
          '${frames.length} frames, worst build $build ms, '
          'worst raster $raster ms',
        );
      }

      // Select yesterday's weigh-in (the chart's tap result; hit-testing is
      // covered by the design-system tests) and open Edit.
      tester
          .widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart))
          .onSelect!(FbPointRef(series: 0, key: _id(1)));
      await pumpFor(tester, const Duration(milliseconds: 400));
      final edit = find.widgetWithText(FbButton, 'Edit');
      await waitUntil(
        tester,
        () => edit.evaluate().isNotEmpty,
        'the point details',
      );
      expect(find.textContaining('that day'), findsOneWidget);
      await tester.ensureVisible(edit);
      await pumpFor(tester, const Duration(milliseconds: 300));
      await tapExactly(tester, edit, 'Edit');
      await waitUntil(
        tester,
        () => find.byType(WeighInSheet).evaluate().isNotEmpty,
        'the weigh-in sheet in edit mode',
      );
      expect(find.byType(WeightGraphScreen), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
