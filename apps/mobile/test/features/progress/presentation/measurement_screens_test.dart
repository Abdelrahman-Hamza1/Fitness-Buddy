import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/measurement_repository.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/measurement_support.dart';

/// The chart on screen.
FbTimeSeriesChart chartOf(WidgetTester tester) =>
    tester.widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart));

/// The type screen of [key].
Widget typeScreen(String key) => MeasurementTypeScreen(typeKey: key);

void main() {
  testWidgets('WB-040 adding a waist measurement from the form shows it in '
      'the list and on its graph', (tester) async {
    final rig = MeasureRig();
    await pumpMeasure(tester, rig, const MeasurementsScreen());
    expect(find.text('No measurements yet'), findsOneWidget);
    await tester.tap(fbButton('Add measurement'));
    await settleMeasure(tester);
    expect(find.text('Add measurement'), findsWidgets);
    expect(
      tester
          .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'Waist'))
          .selected,
      isTrue,
    );
    await tester.enterText(find.byType(TextField), '92');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(find.text('Waist saved: 92.0 cm'), findsOneWidget);
    expect(find.text('Latest 92.0 cm · Today'), findsOneWidget);
    await tester.tap(find.text('Waist'));
    expect(
      rig.navigator.pushed.single.location,
      '/progress/measurements/waist',
    );
    await unmountMeasure(tester, rig);

    final graph = MeasureRig();
    await graph.seed(tester, [CreateMeasurement(mId(1), measureDraft(92))]);
    await pumpMeasure(tester, graph, typeScreen('waist'));
    expect(chartOf(tester).series.single.points, hasLength(1));
    expect(find.text('Latest 92.0 cm · Today'), findsOneWidget);
    await unmountMeasure(tester, graph);
  });

  testWidgets('WB-040 UX-030 editing a measurement; deleting with undo from '
      'the list and from the sheet', (tester) async {
    final rig = MeasureRig();
    await rig.seed(tester, [
      CreateMeasurement(mId(1), measureDraft(92, hour: 6)),
      CreateMeasurement(
        mId(2),
        measureDraft(93, date: measureDay.plusDays(-7)),
      ),
    ]);
    await pumpMeasure(tester, rig, typeScreen('waist'));
    await tester.tap(find.widgetWithText(FbListRow, '92.0 cm'));
    await settleMeasure(tester);
    expect(find.text('Edit measurement'), findsOneWidget);
    expect(fieldText(tester), '92');
    await tester.enterText(find.byType(TextField), '91');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(find.text('Waist updated: 91.0 cm'), findsOneWidget);

    // Swipe-delete from the list, then undo.
    tester
        .widget<FbSwipeActions>(find.byType(FbSwipeActions).first)
        .dismissAction!
        .onTriggered();
    await settleMeasure(tester);
    expect(find.text('Entry deleted'), findsOneWidget);
    expect((await rig.live(tester)).measurements, hasLength(1));
    await tester.tap(find.text('Undo'));
    await settleMeasure(tester);
    expect((await rig.live(tester)).measurements, hasLength(2));

    // Delete from the sheet.
    await tester.tap(find.widgetWithText(FbListRow, '93.0 cm'));
    await settleMeasure(tester);
    await tester.tap(fbButton('Delete'));
    await settleMeasure(tester);
    expect(
      [for (final m in (await rig.live(tester)).measurements) m.id],
      [mId(1)],
    );
    await unmountMeasure(tester, rig);
  });

  testWidgets('WB-040 editing an older entry while a newer one exists opens '
      "with the older entry's exact value, unit, date, time and offset", (
    tester,
  ) async {
    final rig = MeasureRig();
    final olderTime = EntryTime.local(
      LocalDateTime(LocalDate(2026, 9, 17), hour: 21, minute: 15),
      -300,
    );
    await rig.seed(tester, [
      CreateMeasurement(
        mId(1),
        MeasurementDraft(
          type: waistRef,
          time: olderTime,
          input: const MeasurementInput(36.25, MeasurementUnit.inch),
        ),
      ),
      CreateMeasurement(mId(2), measureDraft(92)),
    ]);
    await pumpMeasure(tester, rig, typeScreen('waist'));
    await tester.tap(find.widgetWithText(FbListRow, '36.3 in'));
    await settleMeasure(tester);
    expect(fieldText(tester), '36.25');
    expect(
      tester
          .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'in'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'Date'))
          .value,
      'Thu, Sep 17',
    );
    await unmountMeasure(tester, rig);
  });

  testWidgets('WB-040 opening an entry and saving without a change writes '
      'nothing and adds no undo entry', (tester) async {
    final rig = MeasureRig();
    await rig.seed(tester, [CreateMeasurement(mId(1), measureDraft(92.257))]);
    final before = (await tester.runAsync(rig.h.raw))!;
    await pumpMeasure(tester, rig, typeScreen('waist'));
    await tester.tap(find.widgetWithText(FbListRow, '92.3 cm'));
    await settleMeasure(tester);
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(find.text('Edit measurement'), findsNothing);
    expect(rig.stack.latest, isNull);
    expect(await tester.runAsync(rig.h.raw), before);
    await unmountMeasure(tester, rig);
  });

  testWidgets('WB-040 add, rename and delete a custom type; deleting one with '
      'entries asks first; undo restores type and entries', (tester) async {
    final rig = MeasureRig();
    await pumpMeasure(tester, rig, const MeasurementsScreen());
    await tester.tap(fbButton('Add custom measurement'));
    await settleMeasure(tester);
    expect(find.text('New measurement'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Left calf');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    // Its form opens next, with the new type selected.
    expect(find.text('Add measurement'), findsWidgets);
    await tester.enterText(find.byType(TextField), '40');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(find.text('Left calf saved: 40.0 cm'), findsOneWidget);
    expect(find.text('Left calf'), findsOneWidget);
    final type = (await rig.live(tester)).types.single;
    await unmountMeasure(tester, rig);

    final screen = MeasureRig();
    await screen.seed(tester, [
      CreateMeasurementType(type.id, 'Left calf'),
      CreateMeasurement(mId(1), measureDraft(40, type: type.ref)),
    ]);
    await pumpMeasure(tester, screen, typeScreen(type.ref.key));
    await tester.tap(find.byTooltip('More'));
    await settleMeasure(tester);
    await tester.tap(find.text('Rename'));
    await settleMeasure(tester);
    await tester.enterText(find.byType(TextField), 'Calf L');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(find.text('Renamed to Calf L'), findsOneWidget);
    expect(find.text('Calf L'), findsWidgets);

    await tester.tap(find.byTooltip('More'));
    await settleMeasure(tester);
    await tester.tap(find.text('Delete type'));
    await settleMeasure(tester);
    expect(find.text('Delete Calf L?'), findsOneWidget);
    await tester.tap(fbButton('Keep'));
    await settleMeasure(tester);
    expect((await screen.live(tester)).types, hasLength(1));
    await tester.tap(find.byTooltip('More'));
    await settleMeasure(tester);
    await tester.tap(find.text('Delete type'));
    await settleMeasure(tester);
    await tester.tap(fbButton('Delete'));
    await settleMeasure(tester);
    expect(screen.navigator.pops, 1);
    expect(find.text('Calf L deleted'), findsOneWidget);
    expect((await screen.live(tester)).types, isEmpty);
    await tester.tap(find.text('Undo'));
    await settleMeasure(tester);
    final back = await screen.live(tester);
    expect(back.types.single.name, 'Calf L');
    expect(back.measurements, hasLength(1));
    await unmountMeasure(tester, screen);
  });

  testWidgets('WB-041 each type has its own graph; the trend line appears '
      'from 5 points', (tester) async {
    final rig = MeasureRig();
    await rig.seed(tester, [
      for (var i = 0; i < 4; i++)
        CreateMeasurement(
          mId(i),
          measureDraft(95.0 - i, date: measureDay.plusDays(-7 * (4 - i))),
        ),
      CreateMeasurement(
        mId(9),
        measureDraft(
          101,
          type: MeasurementTypeRef.builtIn(MeasurementKind.chest),
        ),
      ),
    ]);
    await pumpMeasure(tester, rig, typeScreen('waist'));
    expect(chartOf(tester).series, hasLength(1));
    expect(chartOf(tester).series.single.points, hasLength(4));
    expect(find.text('A trend line shows from 5 entries'), findsOneWidget);
    await rig.seed(tester, [CreateMeasurement(mId(5), measureDraft(90.5))]);
    await settleMeasure(tester);
    expect(chartOf(tester).series, hasLength(2));
    expect(chartOf(tester).series.last.style, FbSeriesStyle.line);
    expect(find.text('A trend line shows from 5 entries'), findsNothing);
    await unmountMeasure(tester, rig);

    final chest = MeasureRig();
    await chest.seed(tester, [
      CreateMeasurement(
        mId(9),
        measureDraft(
          101,
          type: MeasurementTypeRef.builtIn(MeasurementKind.chest),
        ),
      ),
    ]);
    await pumpMeasure(tester, chest, typeScreen('chest'));
    expect(chartOf(tester).series.single.points, hasLength(1));
    await unmountMeasure(tester, chest);
  });

  testWidgets('WB-022 tapping a measurement point shows its value as typed '
      'and date, and Edit opens the sheet', (tester) async {
    final rig = MeasureRig();
    await rig.seed(tester, [
      CreateMeasurement(
        mId(1),
        measureDraft(36.5, unit: MeasurementUnit.inch, minute: 30),
      ),
    ]);
    await pumpMeasure(tester, rig, typeScreen('waist'));
    expect(find.text('Tap a point to see details'), findsOneWidget);
    chartOf(tester).onSelect!(FbPointRef(series: 0, key: mId(1)));
    await tester.pump();
    expect(
      find.descendant(of: find.byType(FbCard), matching: find.text('36.5 in')),
      findsOneWidget,
    );
    // CLDR puts a narrow no-break space before AM.
    expect(find.textContaining('Oct 17, 2026 7:30'), findsOneWidget);
    await tester.tap(fbButton('Edit'));
    await settleMeasure(tester);
    expect(find.text('Edit measurement'), findsOneWidget);
    expect(fieldText(tester), '36.5');
    await unmountMeasure(tester, rig);
  });

  testWidgets('WB-042 body fat is entered in % and has its own graph with a % '
      'axis', (tester) async {
    final rig = MeasureRig();
    await pumpMeasure(tester, rig, const MeasurementsScreen());
    await tester.tap(fbButton('Add measurement'));
    await settleMeasure(tester);
    await tester.tap(find.widgetWithText(FbChoiceChip, 'Body fat'));
    await tester.pump();
    expect(tester.widget<FbNumberField>(find.byType(FbNumberField)).unit, '%');
    expect(find.widgetWithText(FbChoiceChip, 'cm'), findsNothing);
    await tester.enterText(find.byType(TextField), '18.4');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(find.text('Body fat saved: 18.4 %'), findsOneWidget);
    final entry = (await rig.live(tester)).measurements.single;
    expect(entry.type.kind, MeasurementKind.bodyFat);
    expect(entry.input, const MeasurementInput(18.4, MeasurementUnit.percent));
    await unmountMeasure(tester, rig);

    final graph = MeasureRig();
    await graph.seed(tester, [
      CreateMeasurement(
        mId(1),
        measureDraft(
          18.4,
          type: MeasurementTypeRef.builtIn(MeasurementKind.bodyFat),
          unit: MeasurementUnit.percent,
        ),
      ),
    ]);
    await pumpMeasure(tester, graph, typeScreen('bodyFat'));
    expect(chartOf(tester).formatValue!(18.4), '18.4 %');
    expect(find.text('Latest 18.4 % · Today'), findsOneWidget);
    await unmountMeasure(tester, graph);
  });

  testWidgets('LC-010 the imperial setting defaults lengths to inches; a value '
      'typed in cm stays cm', (tester) async {
    final rig = MeasureRig()..units.value = UnitSystem.imperial;
    await pumpMeasure(tester, rig, const MeasurementsScreen());
    await tester.tap(fbButton('Add measurement'));
    await settleMeasure(tester);
    expect(
      tester
          .widget<FbChoiceChip>(find.widgetWithText(FbChoiceChip, 'in'))
          .selected,
      isTrue,
    );
    await tester.tap(find.widgetWithText(FbChoiceChip, 'cm'));
    await tester.enterText(find.byType(TextField), '92');
    await tester.pump();
    await tester.tap(fbButton('Save'));
    await settleMeasure(tester);
    expect(
      (await rig.live(tester)).measurements.single.input,
      const MeasurementInput(92, MeasurementUnit.cm),
    );
    // The list shows it in the setting's unit.
    expect(find.text('Latest 36.2 in · Today'), findsOneWidget);
    await unmountMeasure(tester, rig);
  });

  testWidgets('UX-050 measurements empty state · a type with no entries '
      'invites the first one · UX-051 loading · UX-052 error shows Try '
      'again', (tester) async {
    final rig = MeasureRig();
    await pumpMeasure(tester, rig, const MeasurementsScreen());
    expect(find.text('No measurements yet'), findsOneWidget);
    expect(fbButton('Add custom measurement'), findsOneWidget);
    await unmountMeasure(tester, rig);

    final none = MeasureRig();
    await pumpMeasure(tester, none, typeScreen('neck'));
    expect(find.text('No entries yet'), findsOneWidget);
    expect(
      find.text('Add your first entry to start this graph.'),
      findsOneWidget,
    );
    expect(fbButton('Add measurement'), findsOneWidget);
    await unmountMeasure(tester, none);

    final loading = StreamController<MeasurementData>();
    addTearDown(loading.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...MeasureRig().overrides,
          measurementsProvider.overrideWith((ref) => loading.stream),
        ],
        child: phoneApp(const MeasurementsScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(FbSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox());

    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...MeasureRig().overrides,
          measurementsProvider.overrideWith((ref) {
            calls++;
            return Stream.error(StateError('boom'));
          }),
        ],
        child: phoneApp(const MeasurementsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load your measurements"), findsOneWidget);
    final before = calls;
    await tester.tap(fbButton('Try again'));
    await tester.pumpAndSettle();
    expect(calls, greaterThan(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("a removed type's route shows the removed state", (tester) async {
    for (final key in ['custom-${tId(5)}', 'not-a-type']) {
      final rig = MeasureRig();
      await pumpMeasure(tester, rig, typeScreen(key));
      expect(find.text('This measurement was removed'), findsOneWidget);
      expect(fbButton('Add measurement'), findsNothing);
      await unmountMeasure(tester, rig);
    }
  });

  test('typed routes: MeasurementTypeRoute carries the key', () {
    expect(const MeasurementsRoute().location, '/progress/measurements');
    expect(
      const MeasurementTypeRoute('custom-0199e3c2-5b1a-7c3d-8e4f-0000000000c9')
          .location,
      '/progress/measurements/custom-0199e3c2-5b1a-7c3d-8e4f-0000000000c9',
    );
  });
}
