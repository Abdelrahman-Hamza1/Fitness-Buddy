import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

/// The food with the most controls: a state choice ("Log as ...") with a
/// yield note, a unit row, the meal chip and Add.
FoodChoice _busyFood() => catalogChoice(
  riceCooked,
  history: usedBefore(riceCooked, 100, 'g', 100),
  siblings: [riceDry],
  yields: yields,
);

void main() {
  testWidgets("UX-070 #85 the food sheet's controls fit a 412 x 915 viewport "
      'at text scale 2.0: amount, units, state choice, meal and Add are all '
      'on screen without scrolling', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final rig = SheetRig(_busyFood());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides,
          searchOverride(FakeFoodSearch(recent: [rig.row])),
        ],
        child: screenApp(
          const FoodSearchScreen(),
          navigatorKey: rig.navigatorKey,
          textScale: 2,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Rice, white, cooked'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSheet), findsOneWidget);

    const screen = Rect.fromLTWH(0, 0, 412, 915);
    for (final control in [
      find.byType(FbAmountDisplay),
      find.byType(FbUnitPicker),
      find.widgetWithText(FbChoiceChip, 'Log as Rice, white, raw'),
      find.widgetWithText(FbChoiceChip, 'Meal'),
      find.widgetWithText(FbButton, 'Add'),
    ]) {
      final rect = tester.getRect(control);
      expect(
        screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
        isTrue,
        reason: '$control at $rect',
      );
    }
    expect(tester.takeException(), isNull);
    rig.stack.dispose();
  });
}
