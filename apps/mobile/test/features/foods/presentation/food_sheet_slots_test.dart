import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

MealSlot _slot(MealSlot base, {String? name, bool? active}) => MealSlot(
  id: base.id,
  defaultKey: base.defaultKey,
  name: name ?? base.name,
  sortOrder: base.sortOrder,
  window: base.window,
  active: active ?? base.active,
);

void main() {
  testWidgets("DY-010 PA3 the food sheet's meal chip shows a rename at once; a "
      'removed chosen meal shows "Choose a meal" with Add disabled and the '
      'typed amount kept', (tester) async {
    final slots = StreamController<List<MealSlot>>();
    addTearDown(slots.close);
    slots.add(DefaultSlots.all);
    final rig = SheetRig(catalogChoice(pita));
    final slotsOverride = foodSlotsProvider.overrideWith((ref) => slots.stream);
    tester.view
      ..physicalSize = const Size(360, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides.where((o) => o.origin != slotsOverride.origin),
          slotsOverride,
        ],
        child: screenApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openFoodSheet(
                  context,
                  // Noon: the assigner picks Lunch.
                  FoodPick(row: rig.row),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    Finder mealChip(String value) => find.byWidgetPredicate(
      (w) => w is FbChoiceChip && w.label == 'Meal' && w.value == value,
    );
    expect(mealChip('Lunch'), findsOneWidget);
    // Type 3 loaves on the pad.
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.bySemanticsLabel('Amount, 3 loaves'), findsOneWidget);

    // A rename shows at once and loses nothing.
    slots.add([
      for (final slot in DefaultSlots.all)
        if (slot.id == DefaultSlots.lunchId)
          _slot(slot, name: 'Noon')
        else
          slot,
    ]);
    await tester.pumpAndSettle();
    expect(mealChip('Noon'), findsOneWidget);
    expect(find.bySemanticsLabel('Amount, 3 loaves'), findsOneWidget);

    final queuedAdd = tester
        .widget<FbButton>(find.widgetWithText(FbButton, 'Add'))
        .onPressed!;
    // The chosen meal is removed: no silent reassignment.
    slots.add([
      for (final slot in DefaultSlots.all)
        if (slot.id == DefaultSlots.lunchId)
          _slot(slot, active: false)
        else
          slot,
    ]);
    await tester.pumpAndSettle();
    expect(mealChip('Choose a meal'), findsOneWidget);
    expect(find.bySemanticsLabel('Amount, 3 loaves'), findsOneWidget);
    expect(
      tester.widget<FbButton>(find.widgetWithText(FbButton, 'Add')).onPressed,
      isNull,
    );

    // A queued tap that reaches submit after the removal explains noMeal.
    queuedAdd();
    await tester.pumpAndSettle();
    expect(
      tester.widget<FbInlineBanner>(find.byType(FbInlineBanner)).message,
      'Choose a meal',
    );
    // Choosing another meal brings Add back.
    await tester.tap(mealChip('Choose a meal'));
    await tester.pumpAndSettle();
    // The nested picker also follows removals while it is open.
    slots.add([
      for (final slot in DefaultSlots.all)
        if (slot.id == DefaultSlots.lunchId || slot.id == DefaultSlots.snacksId)
          _slot(slot, active: false)
        else
          slot,
    ]);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FbListRow, 'Snacks'), findsNothing);

    await tester.tap(find.widgetWithText(FbListRow, 'Dinner').last);
    await tester.pumpAndSettle();
    expect(mealChip('Dinner'), findsOneWidget);
    expect(
      tester.widget<FbButton>(find.widgetWithText(FbButton, 'Add')).onPressed,
      isNotNull,
    );
    expect(find.bySemanticsLabel('Amount, 3 loaves'), findsOneWidget);
  });
}
