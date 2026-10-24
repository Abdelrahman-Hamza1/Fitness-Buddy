import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../patrol_test/support/today_test_support.dart';
import '../../quick_add/presentation/quick_add_support.dart';
import 'support/today_support.dart';

/// Today at 320 x 640 dp with animations on; the quick-add row shows what
/// [chips] holds (nothing until a test sets some).
Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<List<QuickAddChip>> chips,
) async {
  // The emulator of the device tests: 320 x 640 dp, animations on.
  tester.view
    ..physicalSize = const Size(320, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fakeToday(
        days: {testToday: fullDay(testToday)},
        chipsOverride: quickAddChipsProvider.overrideWith((ref, date) {
          void changed() => ref.invalidateSelf();
          chips.addListener(changed);
          ref.onDispose(() => chips.removeListener(changed));
          return AsyncData(chips.value);
        }),
      ),
      child: phoneApp(const TodayScreen(), disableAnimations: false),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('HM-008 DY-030 the chip row growing in takes the day list '
      'room, never covers it; a row at the bottom edge is reached again '
      'after the row settles', (tester) async {
    final chips = ValueNotifier<List<QuickAddChip>>(const []);
    addTearDown(chips.dispose);
    await _pump(tester, chips);
    for (final name in ['Breakfast', 'Lunch']) {
      final row = find.widgetWithText(FbDisclosureRow, name);
      await tester.ensureVisible(row);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(row);
      await tester.pump(const Duration(milliseconds: 500));
    }
    final pager = find.byType(PageView);
    final bar = find.byType(QuickAddBar);
    final rows = find.descendant(
      of: dayPage(testToday),
      matching: find.byType(FbListRow),
    );
    // The last built item row, scrolled so its centre sits just above the
    // bottom edge of the day list: hit-testable, with no chip row yet.
    final target = rows.last;
    final scrollable = find.descendant(
      of: dayPage(testToday),
      matching: find.byType(Scrollable),
    );
    for (var i = 0; i < 60; i++) {
      final centre = tester.getCenter(target).dy;
      final bottom = tester.getRect(pager).bottom;
      if (centre > bottom - 10 && centre < bottom) break;
      await tester.drag(scrollable, Offset(0, centre > bottom ? -3 : 3));
      await tester.pump();
    }
    expect(target.hitTestable(), findsOneWidget);
    final rowCentre = tester.getCenter(target);
    final roomBefore = tester.getRect(pager).bottom;

    chips.value = [fakeFoodChip(1, 'Labaneh'), fakeFoodChip(2, 'Pita')];
    var sawGrowing = false;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (bar.evaluate().isEmpty) continue;
      // The day list always ends where the chip row starts: nothing of the
      // list is drawn or hit under a chip.
      expect(
        tester.getRect(pager).bottom,
        lessThanOrEqualTo(tester.getTopLeft(bar).dy + 0.01),
      );
      if (tester.getRect(pager).bottom < roomBefore) sawGrowing = true;
    }
    expect(sawGrowing, isTrue, reason: 'the day list gave up room');

    await settleQuickAddRow(tester);
    expect(tester.getRect(pager).bottom, lessThan(roomBefore));
    // The row's old centre is now under the chip row: the finger would hit a
    // chip, which is why the device journeys settle before they tap a row.
    expect(tester.getRect(bar).contains(rowCentre), isTrue);
    expect(target.hitTestable(), findsNothing);

    // Revealed again on the settled layout, the same tap point is on the row.
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 300));
    expect(target.hitTestable(), findsOneWidget);
    final box = tester.renderObject(target);
    final hit = tester.hitTestOnBinding(tester.getCenter(target)).path;
    expect(hit.any((e) => e.target == box), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HM-008 settleQuickAddRow returns at once with no chip row and '
      'waits for a growing one', (tester) async {
    final chips = ValueNotifier<List<QuickAddChip>>(const []);
    addTearDown(chips.dispose);
    await _pump(tester, chips);
    expect(find.byType(FbQuickAddChip), findsNothing);
    await settleQuickAddRow(tester);

    chips.value = [fakeFoodChip(1, 'Labaneh')];
    await tester.pump();
    await settleQuickAddRow(tester);
    final settled = tester.getSize(find.byType(QuickAddBar));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getSize(find.byType(QuickAddBar)), settled);
    expect(find.byType(FbQuickAddChip), findsNWidgets(2));
  });
}
