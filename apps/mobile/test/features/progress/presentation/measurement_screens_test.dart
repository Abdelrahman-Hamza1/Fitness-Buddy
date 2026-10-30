import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
}
