import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/support/db_support.dart';
import '../../diary/support/diary_harness.dart' hide foodOf;
import '../../foods/presentation/food_sheet_test.dart' show openSheet;
import '../../foods/presentation/support/search_screen_support.dart';
import '../../foods/presentation/support/sheet_support.dart';
import '../../today/presentation/support/today_support.dart';
import '../../today/presentation/today_actions_test.dart'
    show log, pumpRig, row, settle;
import '../../today/presentation/today_edit_test.dart'
    show button, chip, pad, pitaDetails, useTallPhone;

Finder _in(Finder of, String text) =>
    find.descendant(of: of, matching: find.text(text));

void main() {
  testWidgets('LC-010 exit 1: switching to imperial changes every food amount '
      'on Today rows, expanded details, the amount sheet and undo messages; '
      'switching back restores them', (tester) async {
    final rig = await pitaDetails(tester);
    // Two more items: a weighed one and a drink on a gram food.
    await log(tester, rig, [
      newEntry(2, when: atDay(testToday, 9), slotId: DefaultSlots.breakfastId),
    ]);
    // Metric: a loaf stays a loaf, grams stay grams.
    expect(_in(row('Pita bread, white'), '1 loaf'), findsOneWidget);
    expect(_in(row('Food 2'), '150 g'), findsOneWidget);
    expect(_in(chip('Amount'), '1 loaf (60 g)'), findsOneWidget);

    rig.units.set(UnitSystem.imperial);
    await tester.pumpAndSettle();
    // Today rows and the expanded details follow; the typed word stays.
    expect(_in(row('Pita bread, white'), '1 loaf'), findsOneWidget);
    expect(_in(row('Food 2'), '5.3 oz'), findsOneWidget);
    expect(_in(chip('Amount'), '1 loaf (2.1 oz)'), findsOneWidget);

    // The amount sheet: chips lead with ounces, the number stays as typed,
    // and the undo message after a save says it in ounces.
    await tester.tap(chip('Amount'));
    await tester.pumpAndSettle();
    final oz = tester.getTopLeft(find.widgetWithText(ChoiceChip, 'oz')).dx;
    final g = tester.getTopLeft(find.widgetWithText(ChoiceChip, 'g')).dx;
    expect(oz, lessThan(g));
    await tester.tap(find.widgetWithText(ChoiceChip, 'oz'));
    await tester.pump();
    await pad(tester, '8');
    await tester.tap(button('Save'));
    await settle(tester);
    expect(find.text('Changed Pita bread, white to 8 oz'), findsOneWidget);
    expect(_in(row('Pita bread, white'), '8 oz'), findsOneWidget);

    // Switching back shows the same stored input in grams.
    rig.units.set(UnitSystem.metric);
    await tester.pumpAndSettle();
    expect(_in(row('Pita bread, white'), '227 g'), findsOneWidget);
    rig.units.set(UnitSystem.imperial);
    await tester.pumpAndSettle();
    expect(_in(row('Pita bread, white'), '8 oz'), findsOneWidget);
    rig.stack.dispose();
  });

  testWidgets('LC-010 exit 1: switching to imperial changes the amount on '
      'search results and the food sheet (default and yield note); switching '
      'back restores them', (tester) async {
    final rig = SheetRig(
      catalogChoice(riceCooked, siblings: [riceDry], yields: yields),
    );
    tester.view
      ..physicalSize = const Size(360, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final loaf = rowOf('usda:pita_white', 'Pita bread, white', loaf: true);
    final plain = rowOf('usda:rice', 'Rice, cooked', kcal: 130);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...rig.overrides,
          searchOverride(FakeFoodSearch(recent: [loaf, plain])),
        ],
        child: screenApp(
          const FoodSearchScreen(),
          navigatorKey: rig.navigatorKey,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('1 loaf'), findsOneWidget);
    expect(find.textContaining('100 g'), findsOneWidget);

    rig.units.set(UnitSystem.imperial);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 loaf'), findsOneWidget);
    expect(find.textContaining('3.5 oz'), findsOneWidget);
    expect(find.textContaining('100 g'), findsNothing);

    rig.units.set(UnitSystem.metric);
    await tester.pumpAndSettle();
    expect(find.textContaining('100 g'), findsOneWidget);
  });

  testWidgets("LC-010 exit 1: the food sheet's yield note and default follow "
      'the unit system', (tester) async {
    final rig = SheetRig(
      catalogChoice(riceCooked, siblings: [riceDry], yields: yields),
    );
    rig.units.set(UnitSystem.imperial);
    await openSheet(tester, rig);
    // No history and no serving to lead with: the imperial fallback is 4 oz
    // (the cup serving leads, so pick the weight chips by their label).
    expect(find.widgetWithText(ChoiceChip, 'oz'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'oz'));
    await tester.pump();
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await pad(tester, '4');
    await tester.tap(find.text('Done'));
    await tester.pump();
    // Only the yield note is a food amount here: nutrient grams stay grams.
    final note = tester.widget<Text>(find.textContaining('≈')).data!;
    expect(note, matches(RegExp(r'^[\d.]+ oz cooked ≈ [\d.]+ oz dry$')));

    rig.units.set(UnitSystem.metric);
    await tester.pumpAndSettle();
    final metricNote = tester.widget<Text>(find.textContaining('≈')).data!;
    expect(metricNote, matches(RegExp(r'^\d+ g cooked ≈ \d+ g dry$')));
  });

  testWidgets('LC-010 Per 100 g headings and nutrient grams stay metric in '
      'imperial', (tester) async {
    final rig = SheetRig(catalogChoice(pita));
    rig.units.set(UnitSystem.imperial);
    await openSheet(tester, rig);
    expect(find.text('Per 100 g'), findsOneWidget);
    expect(find.textContaining('Protein'), findsWidgets);
    expect(find.textContaining('oz per'), findsNothing);
    // The macros line of the chosen amount stays in grams.
    expect(find.textContaining(' g · Carbs'), findsOneWidget);
  });

  testWidgets('PA2 UX-052 in imperial, opening the amount sheet on a 100 g '
      'entry shows 100 g as typed; Save untouched is Unchanged and the row '
      '(input, amount, snapshot, version) is byte-identical', (tester) async {
    final rig = TodayRig();
    rig.units.set(UnitSystem.imperial);
    await pumpRig(tester, rig);
    useTallPhone(tester);
    await log(tester, rig, [
      newEntry(
        1,
        when: atDay(testToday, 8),
        slotId: DefaultSlots.breakfastId,
        grams: 100,
      ),
    ]);
    await tester.tap(find.widgetWithText(FbDisclosureRow, 'Breakfast'));
    await tester.pump();
    await tester.tap(row('Food 1'));
    await tester.pump();
    // The row and the chip say ounces; the editor is on the typed input.
    expect(_in(chip('Amount'), '3.5 oz'), findsOneWidget);
    final before = await tester.runAsync(() => rig.diary.entry(1));

    await tester.tap(chip('Amount'));
    await tester.pumpAndSettle();
    final display = tester.widget<FbAmountDisplay>(
      find.byType(FbAmountDisplay),
    );
    expect(display.amount, '100');
    expect(display.unit, 'g');
    await tester.tap(button('Save'));
    await settle(tester);

    // Unchanged: no undo message, no new version, nothing rewritten.
    expect(find.text('Undo'), findsNothing);
    expect(find.byType(EntryAmountSheet), findsNothing);
    final after = (await tester.runAsync(() => rig.diary.entry(1)))!;
    expect(after.toJson(), before!.toJson());
    expect(after.version, 1);
    rig.stack.dispose();
  });

  testWidgets("PA2 the food sheet's typed buffer is never replaced by a "
      'converted display value', (tester) async {
    final rig = SheetRig(catalogChoice(foodOf('usda:oil', 'Oil')));
    await openSheet(tester, rig);
    await tester.tap(find.byType(FbAmountDisplay));
    await tester.pump();
    await pad(tester, '8');
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(_amount(tester), ('8', 'g'));

    // Display rules follow the setting; the editor keeps what was typed.
    rig.units.set(UnitSystem.imperial);
    await tester.pump();
    expect(_amount(tester), ('8', 'g'));
    rig.units.set(UnitSystem.metric);
    await tester.pump();
    expect(_amount(tester), ('8', 'g'));
  });

  test('LC-010 exit 1: after switching, the diary, groups and saved-meal '
      'tables are byte-identical (A01 D3 comparison) and the outbox gained '
      'only setting rows', () async {
    final diary = DiaryHarness();
    final applier = ChangeSetApplier(
      db: diary.db,
      tables: diary.db.syncedTables,
      handlers: (db) => [DiaryOpHandler(db), SettingsOpHandler(db.settingsKv)],
      clock: diary.clock,
      ids: diary.ids,
      deviceId: () async => testDevice,
      events: diary.bus,
    );
    final stack = UndoStack(revert: applier.revert, clock: diary.clock);
    addTearDown(stack.dispose);
    final actions = SettingsActions(
      store: SettingsStore(db: diary.db, applier: applier),
      undoStack: stack,
    );
    await applier.apply(
      ChangeSet([
        LogEntries([
          newEntry(1, slotId: DefaultSlots.lunchId, grams: 227),
          newEntry(2, slotId: DefaultSlots.lunchId, group: 900),
        ]),
      ], origin: Origin.direct),
    );
    final tablesBefore = await diary.state();
    final outboxBefore = await outbox(diary.db);

    final done = await actions.setUnitSystem(UnitSystem.imperial);
    expect(done, isA<SettingsDone>());

    expect(await diary.state(), tablesBefore);
    final gained = (await outbox(diary.db)).skip(outboxBefore.length);
    expect(gained, isNotEmpty);
    expect(gained.map((row) => row.$1).toSet(), {'setting'});
  });

  test('D4 guard: no presentation file formats a food amount outside '
      'amount_text.dart', () {
    // Not food amounts: the gallery's sample unit IDs, and the nutrient
    // sheet's `g` or `mg` unit of a nutrient field.
    const notFoodAmounts = {
      'lib/features/design_preview/presentation/gallery/gallery_input.dart',
      'lib/features/diary/presentation/nutrient_override_sheet.dart',
    };
    final offenders = <String>[];
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              f.path.contains('/presentation/') &&
              !f.path.endsWith('.g.dart') &&
              !notFoodAmounts.contains(f.path),
        );
    expect(files, isNotEmpty);
    for (final file in files) {
      final code = [
        for (final line in file.readAsLinesSync())
          if (!line.trimLeft().startsWith('//')) line,
      ].join('\n');
      // Rounding a food amount, or a hard-coded gram or millilitre label.
      for (final pattern in [
        'DisplayRounding.foodAmount(',
        "'g'",
        "'ml'",
        '"g"',
        '"ml"',
      ]) {
        if (code.contains(pattern)) offenders.add('${file.path}: $pattern');
      }
      // A quantity worded by hand, or a size next to the raw basis unit
      // (the personal food serving preview): both skip the unit system.
      for (final pattern in [
        RegExp(r'\.foodResultServing\('),
        RegExp(r'\.unitPortionSized\('),
        RegExp(r'ServingShownAs\([^;]*?basisUnit'),
      ]) {
        if (pattern.hasMatch(code)) offenders.add('${file.path}: $pattern');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

/// The number and unit shown in the one amount display on screen.
(String, String) _amount(WidgetTester tester) {
  final display = tester.widget<FbAmountDisplay>(find.byType(FbAmountDisplay));
  return (display.amount, display.unit);
}
