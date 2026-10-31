import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';

/// Lets the database and the undo stack finish what a tap started.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

/// The menu's one option.
Finder get _option => find.descendant(
  of: find.byWidgetPredicate((w) => w is FbOptionList),
  matching: find.byType(ListTile),
);

Future<bool> _marked(WidgetTester tester, TodayRig rig, LocalDate date) async =>
    (await tester.runAsync(() => rig.diary.reads.markOn(date)))?.incomplete ??
    false;

/// Opens the ⋮ day menu and taps its one option.
Future<void> _useMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('today-day-menu')));
  await tester.pumpAndSettle();
  expect(_option, findsOneWidget);
  await tester.tap(_option);
  await _settle(tester);
}

void main() {
  testWidgets('DY-004 the Today day menu marks the viewed day incomplete and '
      'back, today and a past day', (tester) async {
    final rig = TodayRig();
    usePhone(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: rig.overrides,
        child: phoneApp(const TodayScreen()),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('today-incomplete-note')), findsNothing);

    // ⋮ → the menu's one option marks today incomplete.
    await _useMenu(tester);
    expect(await _marked(tester, rig, testToday), isTrue);
    expect(find.byKey(const ValueKey('today-incomplete-note')), findsOneWidget);

    // The note's button counts it again.
    await tester.tap(find.byKey(const ValueKey('today-count-again')));
    await _settle(tester);
    expect(await _marked(tester, rig, testToday), isFalse);
    expect(find.byKey(const ValueKey('today-incomplete-note')), findsNothing);

    // A past day: ‹ to yesterday, mark it from the menu; today is untouched.
    await tester.tap(
      find.descendant(
        of: find.byType(FbDateHeader),
        matching: find.byIcon(FbIcons.previous),
      ),
    );
    await _settle(tester);
    await _useMenu(tester);
    expect(await _marked(tester, rig, testYesterday), isTrue);
    expect(await _marked(tester, rig, testToday), isFalse);
    expect(find.byKey(const ValueKey('today-incomplete-note')), findsOneWidget);

    // The menu now offers Count this day again for yesterday.
    await _useMenu(tester);
    expect(await _marked(tester, rig, testYesterday), isFalse);
    expect(await _marked(tester, rig, testToday), isFalse);
    expect(find.byKey(const ValueKey('today-incomplete-note')), findsNothing);

    // Take the app down so the undo window and snackbar timers end.
    rig.stack.dispose();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 6));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
