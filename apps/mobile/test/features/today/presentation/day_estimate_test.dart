import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/diary/data/diary_op_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_fixtures.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show pumpRig, settle;

// A62b (DY-006, E2 A): the past-day card, the "~2,300" row and its popup.

Future<DayMarkRow?> _mark(TodayRig rig, LocalDate date) => (rig.diary.db.select(
  rig.diary.db.dayMarks,
)..where((t) => t.id.equals(dayMarkRowId(date)))).getSingleOrNull();

Future<void> _toYesterday(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Previous day'));
  await settle(tester);
}

/// A rig whose yesterday holds a 2,300 kcal day estimate.
Future<TodayRig> _estimated(WidgetTester tester) async {
  final rig = TodayRig();
  await tester.runAsync(
    () => rig.diary.apply([
      SetDayEstimate(
        testYesterday,
        kcal: 2300,
        expectedVersion: null,
        expectEstimate: false,
      ),
    ]),
  );
  await pumpRig(tester, rig);
  await _toYesterday(tester);
  return rig;
}

/// Takes the rig's undo stack down so its undo-window timer ends.
Future<void> _finish(WidgetTester tester, TodayRig rig) async {
  rig.stack.dispose();
  await tester.pump(const Duration(seconds: 7));
}

void main() {
  testWidgets('DY-006 past empty day card saves; today shows none', (
    tester,
  ) async {
    final rig = TodayRig();
    await pumpRig(tester, rig);
    expect(find.byKey(const ValueKey('day-estimate-prompt')), findsNothing);

    await _toYesterday(tester);
    expect(find.byKey(const ValueKey('day-estimate-prompt')), findsOneWidget);
    Finder save() => find.byKey(const ValueKey('day-estimate-save'));
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('day-estimate-kcal')),
        matching: find.byType(EditableText),
      ),
      '2300',
    );
    await tester.pump();
    await tester.tap(save());
    await settle(tester);

    final mark = await tester.runAsync(() => _mark(rig, testYesterday));
    expect(mark!.estimateKcal, 2300);
    expect(find.byKey(const ValueKey('day-estimate-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('day-estimate-prompt')), findsNothing);
    expect(find.textContaining('~2,300'), findsWidgets);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    // The mark the save created is gone again (a tombstone).
    expect(
      (await tester.runAsync(() => _mark(rig, testYesterday)))!.deletedAt,
      isNotNull,
    );
    expect(find.byKey(const ValueKey('day-estimate-prompt')), findsOneWidget);
    await _finish(tester, rig);
  });

  testWidgets('DY-006 day swap: search keeps the estimate; cancel writes '
      'nothing', (tester) async {
    final rig = await _estimated(tester);
    final before = await tester.runAsync(rig.diary.state);
    await tester.tap(find.byKey(const ValueKey('day-estimate-marker')));
    await settle(tester);
    expect(
      find.byKey(const ValueKey('day-estimate-popup-edit')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('day-estimate-popup-swap')));
    await settle(tester);
    expect(
      rig.navigator.pushed.single,
      isA<FoodSearchRoute>()
          .having((r) => r.date, 'date', testYesterday)
          .having((r) => r.replace, 'replace', isNull),
    );
    // The search was left without picking a food: nothing written.
    expect(await tester.runAsync(rig.diary.state), before);
    expect(find.byKey(const ValueKey('day-estimate-row')), findsOneWidget);
    await _finish(tester, rig);
  });

  testWidgets('DY-006 D13 a superseded estimate is shown muted; its popup has '
      'no Edit and Swap for foods removes it with Undo', (tester) async {
    final rig = TodayRig();
    await tester.runAsync(() async {
      await rig.diary.apply([
        SetDayEstimate(
          testYesterday,
          kcal: 2300,
          expectedVersion: null,
          expectEstimate: false,
        ),
      ]);
      // Another device logged food on the day offline.
      await insertEntries(rig.diary.db, [
        entryRow(
          1,
          date: '$testYesterday',
          slotId: DefaultSlots.lunchId,
          kcal: 600,
        ),
      ]);
    });
    await pumpRig(tester, rig);
    await _toYesterday(tester);
    expect(
      find.byKey(const ValueKey('day-estimate-superseded')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('day-estimate-marker')));
    await settle(tester);
    expect(find.byKey(const ValueKey('day-estimate-popup-edit')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('day-estimate-popup-swap')));
    await settle(tester);
    // The mark only held the estimate: removing it leaves no mark.
    expect(
      (await tester.runAsync(() => _mark(rig, testYesterday)))!.deletedAt,
      isNotNull,
    );
    expect(find.byKey(const ValueKey('day-estimate-superseded')), findsNothing);
    expect(find.text('Undo'), findsOneWidget);
    expect(rig.navigator.pushed, isEmpty);
    await _finish(tester, rig);
  });

  testWidgets(
    'DY-006 tapping the row edits the estimate at the shown version',
    (tester) async {
      final rig = await _estimated(tester);
      await tester.tap(find.byKey(const ValueKey('day-estimate-row')));
      await settle(tester);
      expect(find.byKey(const ValueKey('day-estimate-submit')), findsOneWidget);
      // Backspace "2300" to "230", then "0" again and a "1": 2,301.
      for (final key in ['<', '1']) {
        await tester.tap(
          find.descendant(
            of: find.byType(FbNumberPad),
            matching: key == '<'
                ? find.byIcon(FbIcons.backspace)
                : find.text(key),
          ),
        );
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('day-estimate-submit')));
      await settle(tester);
      final mark = await tester.runAsync(() => _mark(rig, testYesterday));
      expect((mark!.estimateKcal, mark.version), (2301.0, 2));
      await _finish(tester, rig);
    },
  );
}
