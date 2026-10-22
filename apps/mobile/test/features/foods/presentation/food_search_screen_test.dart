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
  for (final query in ['', 'zzqx']) {
    testWidgets('FD-020 unavailable pack empty state for "$query"', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FoodSearchScreen(initialQuery: query),
        FakeFoodSearch(packReady: false),
      );
      expect(find.text('Nothing to search yet'), findsOneWidget);
      expect(
        find.text(
          "The food database isn't ready yet. Foods you log will show up here.",
        ),
        findsOneWidget,
      );
      expect(find.textContaining('No match'), findsNothing);
    });
  }
  testWidgets('FD-020 failed search keeps rows and retries current query', (
    tester,
  ) async {
    var fail = false;
    final search = FakeFoodSearch(recent: [_rice], shouldFail: () => fail);
    await pumpScreen(tester, const FoodSearchScreen(), search);
    fail = true;
    await tester.enterText(find.byType(TextField), 'rice');
    await tester.pump();
    expect(find.text('Rice, white'), findsOneWidget);
    expect(find.text("Couldn't search just now. Try again."), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(search.queries, ['', 'rice', 'rice']);
    expect(find.text("Couldn't search just now. Try again."), findsNothing);
  });

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

  testWidgets('FD-023 an empty query with no history shows the hint', (
    tester,
  ) async {
    await pumpScreen(tester, const FoodSearchScreen(), FakeFoodSearch());

    expect(find.text('Search in English, Arabic or Arabizi'), findsOneWidget);
    expect(find.text('Recent'), findsNothing);
    expect(find.byType(FoodResultRow), findsNothing);
  });

  testWidgets('FD-020 FD-021 a result shows the badge, the English name, the '
      'Arabic name and the kcal of the default serving', (tester) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(
        answers: {
          'pita': [_pita],
        },
      ),
    );
    await tester.enterText(find.byType(TextField), 'pita');
    await tester.pump();

    final row = find.byType(FoodResultRow);
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Pita bread, white')),
      findsOneWidget,
    );
    // The Arabic name comes with the serving the calories are for.
    expect(
      find.descendant(of: row, matching: find.text('خبز عربي · 1 loaf')),
      findsOneWidget,
    );
    // One loaf is 60 g at 275 kcal per 100 g.
    expect(
      find.descendant(of: row, matching: find.text('165 kcal')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byType(FbSourceBadge)),
      findsOneWidget,
    );
    // The query shows results, not the "Recent" list.
    expect(find.text('Recent'), findsNothing);
  });

  testWidgets('LC-011 a food with no Arabic name shows the serving alone, in '
      'the unit of the last use', (tester) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(recent: [_rice]),
    );

    final row = find.byType(FoodResultRow);
    expect(
      find.descendant(of: row, matching: find.text('100 g')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('130 kcal')),
      findsOneWidget,
    );
  });

  testWidgets('FD-020 every keystroke asks for the text typed so far', (
    tester,
  ) async {
    final search = FakeFoodSearch();
    await pumpScreen(tester, const FoodSearchScreen(), search);

    for (final text in ['r', 'ri', 'ric']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }
    expect(search.queries, ['', 'r', 'ri', 'ric']);
  });

  testWidgets('FD-020 the search box has the focus when the screen opens', (
    tester,
  ) async {
    await pumpScreen(tester, const FoodSearchScreen(), FakeFoodSearch());

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('FD-020 no results shows the try-another-name hint', (
    tester,
  ) async {
    await pumpScreen(tester, const FoodSearchScreen(), FakeFoodSearch());
    await tester.enterText(find.byType(TextField), 'zzqx');
    await tester.pump();

    expect(find.text('No match for "zzqx"'), findsOneWidget);
    expect(find.text('Try another name or spelling.'), findsOneWidget);
    expect(find.byType(FoodResultRow), findsNothing);
  });

  testWidgets('FD-020 clearing the box goes back to the recent foods', (
    tester,
  ) async {
    final search = FakeFoodSearch(
      recent: [_rice],
      answers: {
        'pita': [_pita],
      },
    );
    await pumpScreen(tester, const FoodSearchScreen(), search);
    await tester.enterText(find.byType(TextField), 'pita');
    await tester.pump();
    expect(find.text('Pita bread, white'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(search.queries.last, '');
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Rice, white'), findsOneWidget);
    expect(find.text('Pita bread, white'), findsNothing);
  });

  testWidgets('FD-023 with no food database the banner shows next to the '
      'foods logged before', (tester) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(packReady: false, recent: [_rice]),
    );

    expect(
      find.text(
        "The food database isn't ready yet. "
        "Showing foods you've logged before.",
      ),
      findsOneWidget,
    );
    expect(find.byType(FbInlineBanner), findsOneWidget);
    expect(find.text('Rice, white'), findsOneWidget);
  });

  testWidgets('FD-020 with a database the banner is not shown', (tester) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(recent: [_rice]),
    );

    expect(find.byType(FbInlineBanner), findsNothing);
  });

  testWidgets('FD-020 a failed search shows a calm banner, not a crash', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(fail: true),
    );

    expect(find.text("Couldn't search just now. Try again."), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('UX-040 a result reads as name, Arabic name and calories to a '
      'screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(recent: [_pita]),
    );

    expect(find.bySemanticsLabel('Search foods'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(FoodResultRow)).label,
      'Pita bread, white\nخبز عربي · 1 loaf\n165 kcal',
    );
    handle.dispose();
  });

  testWidgets('UX-070 the screen holds up at text scale 2.0 in dark', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const FoodSearchScreen(),
      FakeFoodSearch(recent: recentRows),
      brightness: Brightness.dark,
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Recent'), findsOneWidget);
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
