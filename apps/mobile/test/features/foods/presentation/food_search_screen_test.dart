import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/catalog/support/catalog_support.dart';
import 'support/search_screen_support.dart';

final FoodSearchRow _rice = rowOf(
  'usda:rice_white_cooked',
  'Rice, white',
  kcal: 130,
);
final FoodSearchRow _pita = rowOf(
  'usda:pita_white',
  'Pita bread, white',
  ar: 'خبز عربي',
  kcal: 275,
  loaf: true,
);

void main() {
  testWidgets('FD-023 an empty query shows recent foods, newest first', (
    tester,
  ) async {
    final search = FakeFoodSearch(recent: recentRows);
    await pumpScreen(tester, const FoodSearchScreen(), search);

    expect(search.queries, ['']);
    expect(find.text('Recent'), findsOneWidget);
    final names = [
      'Pita bread, white',
      'Rice, white, long-grain, cooked',
      'Labaneh',
    ];
    final tops = [
      for (final name in names) tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, [...tops]..sort());
    expect(find.byType(FoodResultRow), findsNWidgets(recentRows.length));
  });

  testWidgets('FD-022 tapping a result hands it, the day and the slot to the '
      'food sheet', (tester) async {
    final picks = <FoodPick>[];
    await pumpScreen(
      tester,
      FoodSearchScreen(
        date: LocalDate(2026, 10, 20),
        slotId: 'slot-lunch',
        onPick: (_, pick) => picks.add(pick),
      ),
      FakeFoodSearch(recent: [_rice, _pita]),
    );

    await tester.tap(find.text('Pita bread, white'));

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    expect(picks, hasLength(1));
    expect(picks.single.row, same(_pita));
    expect(picks.single.date, LocalDate(2026, 10, 20));
    expect(picks.single.slotId, 'slot-lunch');
    expect(picks.single.carried, isNull);
  });

  testWidgets(
    'FD-020 FD-021 typing finds the fixture pack through the real search',
    (tester) async {
      final service = (await tester.runAsync(() async {
        final (_, catalog) = fixtureCatalog();
        return FoodSearchService(FoodCatalogRepository(catalog));
      }))!;
      addTearDown(service.dispose);
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [foodSearchServiceProvider.overrideWithValue(service)],
          child: screenApp(const FoodSearchScreen()),
        ),
      );
      await tester.runAsync(() async {
        await service.updateHistory([]);
        await service.indexReady;
      });
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'rice');
      // The search runs on the database's own isolate: give it real time.
      for (
        var i = 0;
        i < 20 && find.byType(FoodResultRow).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }

      expect(find.byType(FoodResultRow), findsWidgets);
      expect(find.textContaining('Rice, white'), findsWidgets);
      expect(find.byType(FbInlineBanner), findsNothing);
    },
  );
}
