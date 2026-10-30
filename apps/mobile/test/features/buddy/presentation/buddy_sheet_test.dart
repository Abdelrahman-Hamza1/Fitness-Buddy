import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

void main() {
  // rule: A22 sheet-layout
  // rule: A22 offline-usable
  testWidgets('A22 offline send keeps the app usable', (tester) async {
    final h = BuddyHarness(); // Offline by default.
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    await sendInSheet(tester, '2 eggs');
    await settleBuddy(tester);
    expect(find.text("You're offline. Food search still works."), findsOne);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Search foods'), findsOneWidget);
    // Nothing blocks: the composer still takes text and search opens.
    await tester.enterText(find.byType(TextField), 'tea');
    await tester.pump();
    expect(find.text('tea'), findsOneWidget);
    await tester.tap(find.byTooltip('Search foods'));
    await tester.pumpAndSettle();
    expect(find.byType(BuddySheet), findsNothing);
    expect(h.navigator.pushed.single, isA<FoodSearchRoute>());
    expect(
      (h.navigator.pushed.single as FoodSearchRoute).date,
      LocalDate(2026, 10, 17),
    );
    await unmountBuddy(tester, h);
  });

  // rule: A22 one-tap-confirm
  testWidgets('UX-003 a valid card is confirmed with one tap', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String);
        }
        return null;
      },
    );
    final h = BuddyHarness()..answer(message());
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    await sendInSheet(tester, '2 eggs');
    await settleBuddy(tester);
    await tester.tap(find.text('Log it'));
    await settleBuddy(tester);
    expect(await h.entries(), hasLength(1));
    expect(find.textContaining('Logged '), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    // UX-025: haptic feedback on Log it.
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    // One undo per confirm: no global undo snackbar while the sheet is open.
    expect(find.byType(SnackBar), findsNothing);
    await unmountBuddy(tester, h);
  });
}
