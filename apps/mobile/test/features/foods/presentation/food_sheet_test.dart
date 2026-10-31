import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

/// Pumps a page with an "Open" button that opens the food sheet for [rig]'s
/// food, and opens it.
Future<void> openSheet(
  WidgetTester tester,
  SheetRig rig, {
  LocalDate? date,
  String? slotId,
  ParsedAmount? carried,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = const Size(360, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: rig.overrides,
      child: screenApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openFoodSheet(
                context,
                FoodPick(
                  row: rig.row,
                  date: date,
                  slotId: slotId,
                  carried: carried,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        brightness: brightness,
        textScale: textScale,
        navigatorKey: rig.navigatorKey,
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder amount(String label) => find.bySemanticsLabel(label);

Future<void> tapKeys(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    await tester.tap(
      key == '<' ? find.byIcon(FbIcons.backspace) : find.text(key),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('FD-022 sheet load failure retries and offers Close', (
    tester,
  ) async {
    final choice = catalogChoice(pita);
    var attempts = 0;
    final rig = SheetRig(choice);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides.skip(1),
          foodChoiceProvider(rig.row.choiceRef).overrideWith((ref) async {
            attempts++;
            if (attempts == 1) throw StateError('load');
            return choice;
          }),
        ],
        child: screenApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openFoodSheet(context, FoodPick(row: rig.row)),
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
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(FbAmountDisplay), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
  testWidgets('FD-022 closing a failed load dismisses sheet', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides.skip(1),
          foodChoiceProvider(rig.row.choiceRef)
              .overrideWith((ref) async => throw StateError('load')),
        ],
        child: screenApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openFoodSheet(context, FoodPick(row: rig.row)),
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
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSheet), findsNothing);
  });

  testWidgets('FD-022 the sheet opens with the last used amount of the food '
      'and its calories', (tester) async {
    final used = usedBefore(pita, 2, 'loaf', 120);
    await openSheet(tester, SheetRig(catalogChoice(pita, history: used)));

    expect(amount('Amount, 2 loaves'), findsOneWidget);
    // 120 g at 275 kcal per 100 g.
    expect(find.text('330 kcal'), findsOneWidget);
    expect(
      find.text('Protein 11 g · Carbs 67 g · Fat 1.4 g · Fiber 2.6 g'),
      findsOneWidget,
    );
  });

  testWidgets('LC-011 a zero amount disables Add and shows no calories', (
    tester,
  ) async {
    await openSheet(tester, SheetRig(catalogChoice(pita)));
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await tapKeys(tester, '0');

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
          .onPressed,
      isNull,
    );
    expect(find.text('—'), findsOneWidget);

    await tapKeys(tester, '4');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Add'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('FD-062 PA12 rice cooked offers "Log as Rice, white, raw" and '
      'the yield note; choosing it switches the food, not the input', (
    tester,
  ) async {
    await openSheet(
      tester,
      SheetRig(catalogChoice(riceCooked, siblings: [riceDry], yields: yields)),
    );
    // 1 cup of cooked rice is 158 g.
    await tester.tap(find.widgetWithText(FbChoiceChip, 'g'));
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await tapKeys(tester, '100');
    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('Rice, white, cooked'), findsOneWidget);
    expect(find.text('رز مطبوخ'), findsOneWidget);
    expect(find.text('Log as Rice, white, raw'), findsOneWidget);
    expect(find.text('100 g cooked ≈ 36 g dry'), findsOneWidget);
    // The chosen amount, and the same 100 g under "Per 100 g".
    expect(find.text('130 kcal'), findsNWidgets(2));

    await tester.tap(find.text('Log as Rice, white, raw'));
    await tester.pump();

    expect(find.text('Rice, white, raw'), findsOneWidget);
    expect(find.text('رز أبيض'), findsOneWidget);
    expect(find.text('State: dry'), findsOneWidget);
    // The input stays as typed.
    expect(amount('Amount, 100 g'), findsOneWidget);
    expect(find.text('100 g dry ≈ 280 g cooked'), findsOneWidget);
    expect(find.text('365 kcal'), findsNWidgets(2));
    // And the way back is offered.
    expect(find.text('Log as Rice, white, cooked'), findsOneWidget);
  });

  testWidgets('FD-062 PA12 minced beef 90/10 raw has a yield factor but no '
      'compatible cooked food: no switch and a display yield note', (
    tester,
  ) async {
    await openSheet(tester, SheetRig(catalogChoice(beefRaw, yields: yields)));

    expect(find.textContaining('Log as'), findsNothing);
    expect(find.text('100 g raw ≈ 65 g cooked'), findsOneWidget);
    expect(find.text('State: raw'), findsOneWidget);
  });

  testWidgets('AI-048 UX-006 a known food logs with one tap: the sheet '
      'closes with the outcome and the entry is written', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    await openSheet(tester, rig);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FoodSheet), findsNothing);
    final rows = (await tester.runAsync(
      () => rig.diary.db.select(rig.diary.db.diaryEntries).get(),
    ))!;
    expect(rows, hasLength(1));
    expect(rows.single.foodId, 'usda:pita_white');
    expect(rows.single.inputAmount, 1);
    expect(rows.single.inputUnit, 'loaf');
    expect(rows.single.amount, 60);
    expect(rows.single.slotId, DefaultSlots.lunchId);
    rig.stack.dispose();
  });

  testWidgets('FD-022 a typed amount in another unit is logged as typed', (
    tester,
  ) async {
    final rig = SheetRig(catalogChoice(pita));
    await openSheet(tester, rig);
    await tester.tap(find.widgetWithText(FbChoiceChip, 'oz'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    final rows = (await tester.runAsync(
      () => rig.diary.db.select(rig.diary.db.diaryEntries).get(),
    ))!;
    expect(rows.single.inputUnit, 'oz');
    expect(rows.single.amount, closeTo(28.35, 0.01));
    rig.stack.dispose();
  });

  testWidgets('AI-048 a failed add keeps the sheet open with a calm message', (
    tester,
  ) async {
    final rig = SheetRig(
      catalogChoice(pita),
      apply: (_) async => const Rejected(InvalidOp('x')),
    );
    tester.view
      ..physicalSize = const Size(360, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: rig.overrides,
        child: screenApp(
          Scaffold(
            body: SingleChildScrollView(
              child: FoodSheet(pick: FoodPick(row: rig.row)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't add this food. Try again."), findsOneWidget);
    expect(find.byType(FoodSheet), findsOneWidget);
  });
}
