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
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../../diary/support/diary_harness.dart' hide foodOf;
import '../../foods/presentation/food_sheet_test.dart' show openSheet;
import '../../foods/presentation/support/sheet_support.dart';
import '../../today/presentation/today_edit_test.dart' show pad;

void main() {
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
