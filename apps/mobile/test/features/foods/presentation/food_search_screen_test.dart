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

  testWidgets('A57 A41 T-R1 UX-045 stale search results are faded, ignore '
      'taps and are excluded from semantics; the progress slot is always '
      'reserved', (tester) async {
    final picks = <FoodPick>[];
    await pumpScreen(
      tester,
      FoodSearchScreen(onPick: (_, pick) => picks.add(pick)),
      FakeFoodSearch(recent: [_rice, _pita], hold: {'pit'}),
    );
    final progress = find.byKey(const ValueKey('food-search-progress'));
    final results = find.byKey(const ValueKey('food-search-results'));
    final idleTop = tester.getTopLeft(results).dy;
    expect(tester.getSize(progress).height, FbProgressLine.height);
    expect(tester.widget<FbProgressLine>(progress).active, isFalse);
    expect(tester.widget<AnimatedOpacity>(results).opacity, 1);

    await tester.enterText(find.byType(TextField), 'pit');
    await tester.pump();
    expect(tester.widget<FbProgressLine>(progress).active, isTrue);
    expect(tester.getSize(progress).height, FbProgressLine.height);
    expect(tester.getTopLeft(results).dy, idleTop);
    expect(tester.widget<AnimatedOpacity>(results).opacity, 0.35);
    final hidden = find.descendant(
      of: results,
      matching: find.byType(ExcludeSemantics),
    );
    expect(tester.widget<ExcludeSemantics>(hidden.first).excluding, isTrue);
    await tester.tap(find.text('Pita bread, white'), warnIfMissed: false);
    expect(picks, isEmpty);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(tester.widget<FbProgressLine>(progress).active, isFalse);
    expect(tester.widget<AnimatedOpacity>(results).opacity, 1);
    await tester.tap(find.text('Pita bread, white'));
    expect(tester.widget<ExcludeSemantics>(hidden.first).excluding, isFalse);
    expect(picks, hasLength(1));
  });

  testWidgets('A57 A41 the first search shows rows shaped like results, '
      'never an empty state', (tester) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(hold: {''}),
    );
    expect(find.byKey(const ValueKey('food-search-skeleton')), findsOneWidget);
    expect(find.byType(FbEmptyState), findsNothing);
  });
}
