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

  testWidgets('D12 a change-food sheet whose entry is deleted says "This item '
      'was removed" and disables the button', (tester) async {
    final rig = await pumpReplace(tester);
    await tester.tap(find.text('Pita bread, white'));
    await settleWrites(tester);

    await tester.runAsync(
      () => rig.diary.apply([
        DeleteEntries([VersionedId(fixtureId(1), 1)]),
      ]),
    );
    await settleWrites(tester);

    expect(find.text('This item was removed.'), findsOneWidget);
    expect(
      tester
          .widget<FbButton>(find.widgetWithText(FbButton, 'Use this food'))
          .onPressed,
      isNull,
    );
    rig.stack.dispose();
  });

  testWidgets('D12 a change-food sheet follows a move, and offers Reload for '
      'a real change', (tester) async {
    final rig = await pumpReplace(tester);
    await tester.tap(find.text('Pita bread, white'));
    await settleWrites(tester);

    // Moved: still usable.
    await tester.runAsync(
      () => rig.diary.apply([
        MoveEntries([
          VersionedId(fixtureId(1), 1),
        ], toSlotId: DefaultSlots.lunchId),
      ]),
    );
    await settleWrites(tester);
    expect(find.text('This item changed.'), findsNothing);

    // Edited: Reload, then it works on the new version.
    await tester.runAsync(
      () => rig.diary.apply([
        UpdateDiaryEntry(
          fixtureId(1),
          2,
          EntryPatch(
            amount: EntryAmount(
              input: Quantity(200, 'g'),
              amount: 200,
              basis: NutrientBasis.per100g,
            ),
          ),
        ),
      ]),
    );
    await settleWrites(tester);
    expect(find.text('This item changed.'), findsOneWidget);
    expect(
      tester
          .widget<FbButton>(find.widgetWithText(FbButton, 'Use this food'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Reload'));
    await settleWrites(tester);
    expect(find.text('This item changed.'), findsNothing);

    await tester.tap(find.text('Use this food'));
    await settleWrites(tester);
    final changed = (await tester.runAsync(() => rig.diary.entry(1)))!;
    expect(changed.nameEn, 'Pita bread, white');
    expect(changed.version, 4);
    rig.stack.dispose();
  });

  testWidgets('DY-021 the change-food search names the item it replaces', (
    tester,
  ) async {
    final rig = await pumpReplace(tester);
    await settleWrites(tester);

    expect(find.text('Replacing Food 1'), findsOneWidget);
    rig.stack.dispose();
  });

  testWidgets('D12 a refused change-food says why: changed, removed, or '
      'invalid, not "Couldn\'t add this food"', (tester) async {
    for (final (failure, message) in [
      (
        const VersionConflict(
          entity: 'diary_entry',
          id: 'x',
          expected: 1,
          actual: 2,
        ),
        'That item was changed, so nothing was saved.',
      ),
      (
        const RowNotFound(entity: 'diary_entry', id: 'x'),
        'That item was removed, so nothing was saved.',
      ),
      (const InvalidOp('outOfRange'), "Couldn't save that. Try again."),
    ]) {
      final rig = await pumpReplace(
        tester,
        apply: (change) async => Rejected(failure),
      );
      await tester.tap(find.text('Pita bread, white'));
      await settleWrites(tester);
      await tester.tap(find.text('Use this food'));
      await settleWrites(tester);

      expect(find.text(message), findsOneWidget, reason: '$failure');
      expect(find.text("Couldn't add this food. Try again."), findsNothing);
      // Still open, nothing changed.
      expect(find.byType(FoodSheet), findsOneWidget);
      expect(
        (await tester.runAsync(() => rig.diary.entry(1)))!.nameEn,
        'Food 1',
      );
      rig.stack.dispose();
      // A fresh tree for the next case.
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('#85 the food sheet uses FbChoiceChip for meal and "Log as …"', (
    tester,
  ) async {
    final rig = SheetRig(
      catalogChoice(riceCooked, siblings: [riceDry], yields: yields),
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
            body: FoodSheet(pick: FoodPick(row: rig.row)),
          ),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<FbChoiceChip>(find.byType(FbChoiceChip))
        .map((c) => c.label);
    expect(labels, containsAll(['Meal', 'Log as Rice, white, raw']));
  });
}
