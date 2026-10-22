import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

/// Lets the database and the undo stack finish what a tap started.
Future<void> settleWrites(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AI-048 UX-030 UX-006 Add closes the search and shows the undo '
      'snackbar; Undo removes the entry', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides,
          searchOverride(FakeFoodSearch(recent: [rig.row])),
        ],
        child: screenApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FoodSearchScreen(),
                  ),
                ),
                child: const Text('Today'),
              ),
            ),
          ),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchScreen), findsOneWidget);

    // Type, tap, one tap on Add.
    await tester.tap(find.text('Pita bread, white'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSheet), findsOneWidget);
    await tester.tap(find.text('Add'));
    await settleWrites(tester);

    expect(find.byType(FoodSheet), findsNothing);
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(rig.navigator.pops, 1);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Added Pita bread, white to Lunch'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    final db = rig.diary.db;
    final live = (await tester.runAsync(
      () => (db.select(
        db.diaryEntries,
      )..where((t) => t.deletedAt.isNull())).get(),
    ))!;
    expect(live, hasLength(1));
    expect(live.single.foodId, 'usda:pita_white');

    await tester.tap(find.text('Undo'));
    await settleWrites(tester);

    final after = (await tester.runAsync(
      () => (db.select(
        db.diaryEntries,
      )..where((t) => t.deletedAt.isNull())).get(),
    ))!;
    expect(after, isEmpty);
    rig.stack.dispose();
  });

  testWidgets('AI-048 closing the sheet without Add writes nothing and keeps '
      'the search open', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides,
          searchOverride(FakeFoodSearch(recent: [rig.row])),
        ],
        child: screenApp(
          const FoodSearchScreen(),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Pita bread, white'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSheet), findsOneWidget);

    // Dismiss the sheet by tapping the barrier.
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();

    expect(find.byType(FoodSheet), findsNothing);
    expect(find.byType(FoodSearchScreen), findsOneWidget);
    expect(rig.navigator.pops, 0);
    expect(find.byType(SnackBar), findsNothing);
    final db = rig.diary.db;
    expect(
      await tester.runAsync(() => db.select(db.diaryEntries).get()),
      isEmpty,
    );
  });
}
