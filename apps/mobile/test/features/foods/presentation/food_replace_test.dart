import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_fixtures.dart' show fixtureId;
import '../../diary/support/diary_harness.dart';
import 'support/search_screen_support.dart';
import 'support/sheet_support.dart';

/// A read starts on a fake timer and answers in real time, so a few rounds.
Future<void> settleWrites(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pumpAndSettle();
  }
}

/// The search in change-food mode for entry 1 of a rig whose diary holds a
/// plain "Food 1" (150 g) in breakfast; the new food is pita.
Future<SheetRig> pumpReplace(
  WidgetTester tester, {
  Future<ApplyResult> Function(ChangeSet)? apply,
}) async {
  final rig = SheetRig(catalogChoice(pita), apply: apply);
  tester.view
    ..physicalSize = const Size(360, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await rig.diary.apply([
    LogEntries([
      newEntry(
        1,
        when: atDay(LocalDate(2026, 10, 17), 8),
        slotId: DefaultSlots.breakfastId,
      ),
    ]),
  ]);
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
                  builder: (_) => FoodSearchScreen(
                    date: LocalDate(2026, 10, 17),
                    slotId: DefaultSlots.breakfastId,
                    replace: VersionedId(fixtureId(1), 1),
                  ),
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
  return rig;
}

void main() {
  testWidgets('DY-021 Change food opens search in replace mode; Use this food '
      'replaces it with Undo "Changed to …"', (tester) async {
    final rig = await pumpReplace(tester);
    expect(find.text('Change food'), findsOneWidget);

    await tester.tap(find.text('Pita bread, white'));
    await settleWrites(tester);
    // Replace mode: no meal to choose, the button says what it does.
    expect(find.byType(FoodSheet), findsOneWidget);
    expect(find.text('Use this food'), findsOneWidget);
    expect(find.text('Add'), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is FbChoiceChip && w.label == 'Meal'),
      findsNothing,
    );

    await tester.tap(find.text('Use this food'));
    await settleWrites(tester);

    expect(find.byType(FoodSheet), findsNothing);
    expect(find.byType(FoodSearchScreen), findsNothing);
    expect(rig.navigator.pops, 1);
    expect(find.text('Changed to Pita bread, white'), findsOneWidget);
    final changed = (await tester.runAsync(() => rig.diary.entry(1)))!;
    expect(changed.nameEn, 'Pita bread, white');
    expect(changed.slotId, DefaultSlots.breakfastId);
    expect(changed.version, 2);

    await tester.tap(find.text('Undo'));
    await settleWrites(tester);
    expect((await tester.runAsync(() => rig.diary.entry(1)))!.nameEn, 'Food 1');
    rig.stack.dispose();
  });
}
