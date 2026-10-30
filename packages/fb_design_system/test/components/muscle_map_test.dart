import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/components/muscle_map.dart'
    show FbMuscleMapPainter, fbBodyParts;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  test('WO-007 every body region has paths on at least one view, and '
      'shoulders on both', () {
    final regions = {
      for (final view in FbBodyView.values)
        for (final (region, _) in fbBodyParts(view)) ?region,
    };
    expect(regions, FbBodyRegion.values.toSet());
    for (final view in FbBodyView.values) {
      expect(
        fbBodyParts(view).where((p) => p.$1 == FbBodyRegion.deltoids),
        isNotEmpty,
        reason: '$view',
      );
      for (final (_, path) in fbBodyParts(view)) {
        expect(path.getBounds().isEmpty, isFalse);
      }
    }
  });

  testWidgets('WO-007 muscle map paints primary and secondary regions', (
    tester,
  ) async {
    await pumpFb(
      tester,
      const Center(
        child: FbMuscleMap(
          primary: {FbBodyRegion.chest},
          secondary: {FbBodyRegion.triceps, FbBodyRegion.chest},
          semanticLabel: 'Main: chest. Secondary: triceps.',
        ),
      ),
    );
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<FbMuscleMapPainter>()
        .toList();
    expect(painters.map((p) => p.view), [FbBodyView.front, FbBodyView.back]);
    final painter = painters.first;
    final colours = painter.colours;
    expect({colours.neutral, colours.primary, colours.secondary}, hasLength(3));
    // A region in both sets stays dark.
    expect(painter.colourOf(FbBodyRegion.chest), colours.primary);
    expect(painter.colourOf(FbBodyRegion.triceps), colours.secondary);
    expect(painter.colourOf(FbBodyRegion.calves), colours.neutral);
    expect(painter.colourOf(null), colours.neutral);
    // One image for screen readers, labelled in words (never colour alone).
    expect(
      find.bySemanticsLabel('Main: chest. Secondary: triceps.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('WO-007 no primary muscle shows the neutral body (RTL, dark)', (
    tester,
  ) async {
    await pumpFb(
      tester,
      const Center(
        child: FbMuscleMap(primary: {}, semanticLabel: 'No main muscle'),
      ),
      brightness: Brightness.dark,
      direction: TextDirection.rtl,
    );
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<FbMuscleMapPainter>()
        .first;
    for (final region in FbBodyRegion.values) {
      expect(painter.colourOf(region), painter.colours.neutral);
    }
    expect(tester.takeException(), isNull);
  });
}
