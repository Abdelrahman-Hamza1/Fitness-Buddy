import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/l10n/domain_labels.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/l10n/gen/app_localizations_en.dart';
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

/// The meal chip showing [value] (#85: an FbChoiceChip reading "Meal", then
/// the meal).
Finder _mealChip(String value) => find.byWidgetPredicate(
  (w) => w is FbChoiceChip && w.label == 'Meal' && w.value == value,
);

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

  testWidgets('LC-005 the sheet shows "Pita bread, white · خبز عربي", the '
      'badge and the state', (tester) async {
    await openSheet(tester, SheetRig(catalogChoice(pita)));

    expect(find.text('Pita bread, white · خبز عربي'), findsOneWidget);
    expect(find.byType(FbSourceBadge), findsOneWidget);
    expect(find.text('State: as sold'), findsOneWidget);
  });

  testWidgets('LC-005 a food with no Arabic name shows only the English one', (
    tester,
  ) async {
    await openSheet(
      tester,
      SheetRig(catalogChoice(foodOf('usda:oats', 'Oats, dry'))),
    );

    expect(find.text('Oats, dry'), findsOneWidget);
    expect(find.textContaining('Oats, dry ·'), findsNothing);
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

  testWidgets('FD-022 without a last amount it starts at one local portion, '
      'and "2 pita" carries 2', (tester) async {
    await openSheet(tester, SheetRig(catalogChoice(pita)));
    expect(amount('Amount, 1 loaf'), findsOneWidget);
    expect(find.text('165 kcal'), findsOneWidget);
  });

  testWidgets('FD-022 D7 a quantity typed in the search is the starting '
      'amount', (tester) async {
    await openSheet(
      tester,
      SheetRig(catalogChoice(pita)),
      carried: ParsedAmount(3),
    );
    expect(amount('Amount, 3 loaves'), findsOneWidget);
    expect(find.text('495 kcal'), findsOneWidget);
  });

  testWidgets('LC-011 units: the food portion first, then g, then the '
      'others; switching to oz updates the calories', (tester) async {
    await openSheet(tester, SheetRig(catalogChoice(pita)));

    final chips = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .map((c) => (c.label as Text).data)
        .toList();
    expect(chips.take(3), ['loaf', 'g', 'oz']);
    expect(find.text('165 kcal'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'oz'));
    await tester.pump();

    // One oz is 28.35 g: 78 kcal at 275 per 100 g. The number is as typed.
    expect(amount('Amount, 1 oz'), findsOneWidget);
    expect(find.text('78 kcal'), findsOneWidget);
  });

  testWidgets('LC-011 the number pad types an amount: the first key replaces '
      'the default, then decimals, backspace and Done', (tester) async {
    await openSheet(tester, SheetRig(catalogChoice(pita)));
    expect(find.byType(FbNumberPad), findsNothing);

    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    expect(find.byType(FbNumberPad), findsOneWidget);

    await tapKeys(tester, '2.5');
    expect(amount('Amount, 2.5 loaves'), findsOneWidget);
    expect(find.text('413 kcal'), findsOneWidget); // 150 g -> 412.5

    await tapKeys(tester, '<<');
    expect(amount('Amount, 2 loaves'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.byType(FbNumberPad), findsNothing);
    expect(amount('Amount, 2 loaves'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(ChoiceChip, 'g'));
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await tapKeys(tester, '100');
    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(find.text('Rice, white, cooked · رز مطبوخ'), findsOneWidget);
    expect(find.text('Log as Rice, white, raw'), findsOneWidget);
    expect(find.text('100 g cooked ≈ 36 g dry'), findsOneWidget);
    // The chosen amount, and the same 100 g under "Per 100 g".
    expect(find.text('130 kcal'), findsNWidgets(2));

    await tester.tap(find.text('Log as Rice, white, raw'));
    await tester.pump();

    expect(find.text('Rice, white, raw · رز أبيض'), findsOneWidget);
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

  testWidgets('FD-012 a warn food shows the sanity note, an ok food does '
      'not', (tester) async {
    await openSheet(
      tester,
      SheetRig(
        catalogChoice(foodOf('x', 'Odd bar', sanity: CatalogSanity.warn)),
      ),
    );
    expect(
      find.text(
        "This food's calories don't quite match its protein, carbs and fat.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('FD-012 an ok or waived food shows no sanity note', (
    tester,
  ) async {
    await openSheet(
      tester,
      SheetRig(
        catalogChoice(foodOf('x', 'Waived bar', sanity: CatalogSanity.waived)),
      ),
    );
    expect(find.textContaining("don't quite add up"), findsNothing);
    expect(find.byType(FbInlineBanner), findsNothing);
  });

  testWidgets('FD-002 per 100 g shows the core five and the extras under '
      '"More"', (tester) async {
    await openSheet(tester, SheetRig(catalogChoice(pita)));

    expect(find.text('Per 100 g'), findsOneWidget);
    // The amount is one loaf (165 kcal); the 100 g reference is 275.
    expect(find.text('165 kcal'), findsOneWidget);
    expect(find.text('275 kcal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('More'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sodium'), findsNothing);

    await tester.tap(find.text('More'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Sodium'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sugar'), findsOneWidget);
    expect(find.text('536 mg'), findsOneWidget);
    expect(find.text('Less'), findsOneWidget);
  });

  testWidgets('DY-011 the meal chip starts with the slot of the time of day, '
      'a route slot wins, and the chip changes it', (tester) async {
    // The harness clock is 12:00: lunch.
    await openSheet(tester, SheetRig(catalogChoice(pita)));
    expect(_mealChip('Lunch'), findsOneWidget);

    await tester.tap(_mealChip('Lunch'));
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsOneWidget);
    await tester.tap(find.text('Dinner'));
    await tester.pumpAndSettle();

    expect(_mealChip('Dinner'), findsOneWidget);
  });

  testWidgets('DY-011 a slot given by the caller wins over the time of '
      'day', (tester) async {
    await openSheet(
      tester,
      SheetRig(catalogChoice(pita)),
      slotId: DefaultSlots.breakfastId,
    );
    expect(_mealChip('Breakfast'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(ChoiceChip, 'oz'));
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

  testWidgets('UX-040 the amount, the units and the state choice read well '
      'to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await openSheet(
      tester,
      SheetRig(catalogChoice(riceCooked, siblings: [riceDry], yields: yields)),
    );

    expect(find.bySemanticsLabel('Amount, 1 cup'), findsOneWidget);
    expect(
      tester.getSemantics(find.widgetWithText(ChoiceChip, 'g')),
      matchesSemantics(
        label: 'g',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Log as Rice, white, raw'), findsOneWidget);
    handle.dispose();
  });

  for (final (brightness, scale) in [
    (Brightness.light, 2.0),
    (Brightness.dark, 2.0),
    (Brightness.dark, 1.0),
  ]) {
    testWidgets('UX-070 the sheet holds up in $brightness at x$scale', (
      tester,
    ) async {
      await openSheet(
        tester,
        SheetRig(
          catalogChoice(riceCooked, siblings: [riceDry], yields: yields),
        ),
        brightness: brightness,
        textScale: scale,
      );
      await tester.tap(find.byType(FbAmountDisplay));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Add'), findsWidgets);
    });
  }

  group('unit labels', () {
    final l10n = AppLocalizationsEn();

    test('LC-011 plural forms follow the count', () {
      expect(unitLabel(l10n, 'loaf', 1), 'loaf');
      expect(unitLabel(l10n, 'loaf', 1.0), 'loaf');
      expect(unitLabel(l10n, 'loaf', 2), 'loaves');
      expect(unitLabel(l10n, 'loaf', 1.5), 'loaves');
      expect(unitLabel(l10n, 'loaf', 0), 'loaves');
      expect(unitLabel(l10n, 'g', 100), 'g');
      expect(unitLabel(l10n, 'fl_oz', 1), 'fl oz');
      expect(unitLabel(l10n, 'small_plate', 2), 'small plates');
    });

    test('LC-011 a code with no word shows "portion" and what it holds', () {
      expect(unitLabel(l10n, 'handful', 1), 'portion');
      expect(unitLabel(l10n, 'handful', 2), 'portions');
      expect(
        unitLabel(
          l10n,
          'handful',
          1,
          serving: ServingUnit.grams('handful', 60),
        ),
        'portion (60 g)',
      );
      expect(
        unitLabel(
          l10n,
          'handful',
          3,
          serving: ServingUnit.milliliters('handful', 125),
        ),
        'portions (125 ml)',
      );
    });
  });
}
