import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../diary/support/diary_fixtures.dart' show fixtureId;
import '../../diary/support/diary_harness.dart';
import '../../today/presentation/support/today_support.dart';
import '../../today/presentation/today_actions_test.dart' show log, settle;
import 'quick_add_support.dart';

/// Today on the real in-memory diary, with the quick-add row reading it, and
/// a counter of every finger that touches the screen (the gesture layer).
final class _Taps {
  int count = 0;
}

Future<void> _pumpReal(
  WidgetTester tester,
  TodayRig rig,
  _Taps taps, {
  List<Override> extra = const [],
}) async {
  usePhone(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...rig.overrides,
        // No catalog pack in a widget test: the chip falls back to the
        // history snapshot, which is what an unresolvable food does anyway.
        foodChoiceProvider.overrideWith((ref, key) async => null),
        ...extra,
      ],
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => taps.count++,
        child: phoneApp(const TodayScreen()),
      ),
    ),
  );
  await settle(tester);
}

/// Three lunches of "Food 1" on the days before today, 12:30, and one
/// two-item saved meal made from an earlier lunch.
List<NewDiaryEntry> _lunchHistory() => [
  for (var d = 1; d <= 3; d++)
    newEntry(
      d,
      when: atDay(testToday.plusDays(-d), 12, 30),
      slotId: DefaultSlots.lunchId,
      ref: FoodRef.catalog('food-1', version: '1'),
    ),
];

Finder _chip(String label) => find.widgetWithText(FbQuickAddChip, label);

void main() {
  testWidgets('UX-004 DY-030 a repeat meal is logged from Today in 1 tap '
      '(tap counter) and Undo removes it', (tester) async {
    final rig = TodayRig(realChips: true);
    final taps = _Taps();
    await _pumpReal(tester, rig, taps);
    await log(tester, rig, _lunchHistory());
    expect(_chip('Food 1'), findsOneWidget);
    expect(taps.count, 0);

    await tester.tap(_chip('Food 1'));
    await settle(tester);

    // One touch logged the meal, with the last-used amount, in the meal of
    // the current time (lunch at 12:00).
    expect(taps.count, 1);
    final day = (await tester.runAsync(() => rig.diary.reads.day(testToday)))!;
    final entry = day.entries.single;
    expect(entry.food.names.en, 'Food 1');
    expect(entry.slotId, DefaultSlots.lunchId);
    expect(entry.amount.input, Quantity(150, 'g'));
    expect(find.text('Logged Food 1, 150 g'), findsOneWidget);

    // Undo is the second touch of the whole journey, and removes it.
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(taps.count, 2);
    final after = (await tester.runAsync(
      () => rig.diary.reads.day(testToday),
    ))!;
    expect(after.entries, isEmpty);
    rig.stack.dispose();
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('DY-030 DY-031 a saved-meal chip logs the whole meal in one '
      'tap, with one Undo', (tester) async {
    final rig = TodayRig(realChips: true);
    final taps = _Taps();
    await _pumpReal(tester, rig, taps);
    // A usual lunch of two foods, eaten on three days, saved as a meal.
    await log(tester, rig, [
      for (var d = 1; d <= 3; d++) ...[
        newEntry(
          d * 2,
          when: atDay(testToday.plusDays(-d), 12, 30),
          slotId: DefaultSlots.lunchId,
        ),
        newEntry(
          d * 2 + 1,
          when: atDay(testToday.plusDays(-d), 12, 40),
          slotId: DefaultSlots.lunchId,
        ),
      ],
    ]);
    await tester.runAsync(
      () => rig.diary.apply([
        SaveMeal(
          savedMealId: fixtureId(90),
          name: 'Usual lunch',
          source: MealSource.entries([fixtureId(2), fixtureId(3)]),
          expected: SourceVersions(
            entries: [
              VersionedId(fixtureId(2), 1),
              VersionedId(fixtureId(3), 1),
            ],
          ),
        ),
      ]),
    );
    await settle(tester);
    expect(_chip('Usual lunch'), findsOneWidget);
    expect(
      find.descendant(
        of: _chip('Usual lunch'),
        matching: find.byIcon(FbIcons.meal),
      ),
      findsOneWidget,
    );

    taps.count = 0;
    await tester.tap(_chip('Usual lunch'));
    await settle(tester);

    expect(taps.count, 1);
    final day = (await tester.runAsync(() => rig.diary.reads.day(testToday)))!;
    expect(day.entries.map((e) => e.food.names.en), ['Food 2', 'Food 3']);
    expect(find.text('Logged Usual lunch, 2 items'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    final after = (await tester.runAsync(
      () => rig.diary.reads.day(testToday),
    ))!;
    expect(after.entries, isEmpty);
    rig.stack.dispose();
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('DY-030 a chip on yesterday logs there and the snackbar names '
      'the day', (tester) async {
    final rig = TodayRig(realChips: true);
    final taps = _Taps();
    await _pumpReal(tester, rig, taps);
    await log(tester, rig, _lunchHistory());

    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    await tester.tap(_chip('Food 1'));
    await settle(tester);

    final yesterday = (await tester.runAsync(
      () => rig.diary.reads.day(testYesterday),
    ))!;
    // Yesterday had the earlier lunch; the chip added one more, in lunch.
    final added = yesterday.entries.where((e) => e.id != fixtureId(1));
    expect(added.map((e) => e.slotId), [DefaultSlots.lunchId]);
    final todayDay = (await tester.runAsync(
      () => rig.diary.reads.day(testToday),
    ))!;
    expect(todayDay.entries, isEmpty);
    expect(find.text('Logged Food 1, 150 g for yesterday'), findsOneWidget);
    rig.stack.dispose();
    await tester.pump(const Duration(seconds: 7));
  });

  testWidgets('DY-030 a rejected chip log says "That changed. Nothing was '
      'logged." and offers no Undo', (tester) async {
    final rig = TodayRig(
      realChips: true,
      apply: (change) async => const Rejected(
        VersionConflict(entity: 'diary_entry', id: 'x', expected: 1, actual: 2),
      ),
    );
    await _pumpReal(tester, rig, _Taps());
    await log(tester, rig, _lunchHistory());

    await tester.tap(_chip('Food 1'));
    await settle(tester);

    expect(find.text('That changed. Nothing was logged.'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    final day = (await tester.runAsync(() => rig.diary.reads.day(testToday)))!;
    expect(day.entries, isEmpty);
    rig.stack.dispose();
    await tester.pump(const Duration(seconds: 7));
  });

  group('the row', () {
    testWidgets('HM-008 the chip row sits above the input bar and under the '
        'day, and "+" opens search for the viewed day', (tester) async {
      final nav = RecordingNavigator();
      usePhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeToday(
            navigator: nav,
            chips: [fakeFoodChip(1, 'Labaneh'), fakeMealChip(2, 'Usual lunch')],
          ),
          child: phoneApp(const TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();

      final row = find.byType(FbQuickAddRow);
      expect(row, findsOneWidget);
      expect(
        tester.getTopLeft(row).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(PageView)).dy),
      );
      expect(
        tester.getBottomLeft(row).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(FbInputBar)).dy),
      );
      expect(find.byType(FbQuickAddChip), findsNWidgets(3));
      expect(find.text('Add food'), findsOneWidget);

      await tester.tap(find.widgetWithText(FbQuickAddChip, 'Add food'));
      final route = nav.pushed.single as FoodSearchRoute;
      expect(route.date, testYesterday);
      expect(route.slotId, isNull);
    });

    testWidgets('HM-008 the row animates in when animations are on, and the '
        'day keeps its room', (tester) async {
      usePhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeToday(chips: [fakeFoodChip(1, 'Labaneh')]),
          child: phoneApp(const TodayScreen(), disableAnimations: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(FbQuickAddChip), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('HM-008 the row is hidden when there is nothing to suggest', (
      tester,
    ) async {
      usePhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeToday(),
          child: phoneApp(const TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FbQuickAddRow), findsNothing);
      expect(find.byType(FbQuickAddChip), findsNothing);
      expect(find.byType(FbInputBar), findsOneWidget);
    });

    testWidgets('DY-030 chips have a screen-reader label naming the action, '
        'and a meal chip a meal icon', (tester) async {
      final handle = tester.ensureSemantics();
      usePhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeToday(
            chips: [fakeFoodChip(1, 'Labaneh'), fakeMealChip(2, 'Usual lunch')],
          ),
          child: phoneApp(const TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Log Labaneh'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Log saved meal Usual lunch'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _chip('Usual lunch'),
          matching: find.byIcon(FbIcons.meal),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _chip('Labaneh'),
          matching: find.byIcon(FbIcons.meal),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('UX-070 the row and the input bar fit a 320 x 640 phone at '
          'text scale $scale', (tester) async {
        tester.view
          ..physicalSize = const Size(320, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeToday(
              chips: [
                fakeFoodChip(1, 'Greek yoghurt with honey and walnuts'),
                fakeMealChip(2, 'Usual lunch'),
              ],
            ),
            child: phoneApp(const TodayScreen(), textScale: scale),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final bar = tester.getRect(find.byType(FbInputBar));
        final row = tester.getRect(find.byType(FbQuickAddRow));
        expect(bar.bottom, lessThanOrEqualTo(640));
        expect(row.bottom, lessThanOrEqualTo(bar.top));
        // The day still has room above the row.
        expect(tester.getSize(find.byType(PageView)).height, greaterThan(100));
      });
    }
  });
}
