import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

void main() {
  // rule: A22 skeleton
  testWidgets('AI-030 skeleton card shows before the response arrives', (
    tester,
  ) async {
    final h = BuddyHarness();
    final answer = Completer<ResponseBody>();
    h.adapter.respond = (_) => answer.future;
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    await sendInSheet(tester, '2 eggs');
    await settleBuddy(tester);
    expect(find.text('2 eggs'), findsOneWidget);
    expect(find.byType(FbSkeleton), findsWidgets);
    expect(find.text('Log it'), findsNothing);

    answer.complete(await json(message())(RequestOptions()));
    await settleBuddy(tester);
    expect(find.byType(FbSkeleton), findsNothing);
    expect(find.text('Log it'), findsOneWidget);
    // The plain cards line is stored but not drawn above its card.
    expect(
      find.text("Here's your meal. Check it, then tap Log it."),
      findsNothing,
    );
    expect((await h.chat()).where((r) => r.role == 'assistant'), hasLength(1));
    await unmountBuddy(tester, h);
  });

  // rule: A22 sheet-layout
  for (final size in const [Size(320, 640), Size(412, 915)]) {
    testWidgets('UX-011 UX-012 chat sheet opens over Today and keeps the '
        'numbers visible at ${size.width.toInt()} x ${size.height.toInt()}', (
      tester,
    ) async {
      final h = BuddyHarness();
      await pumpBuddyHost(tester, h, size: size);
      await openBuddySheet(tester);
      final sheet = tester.getRect(find.byType(BuddySheet));
      // Resting at 60% of the screen: the top 40% (the numbers) stays
      // visible behind the light scrim.
      expect(sheet.top, closeTo(size.height * 0.4, 2));

      // With the keyboard up, it rests at 60% of the space above it.
      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();
      final composer = tester.getRect(find.byType(FbComposer));
      expect(composer.bottom, lessThanOrEqualTo(size.height - keyboard));
      final above = size.height - keyboard;
      final top = tester.getRect(find.byType(DraggableScrollableSheet)).top;
      expect(top, closeTo(above * 0.4, 2));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();

      // Drag up to full height.
      await tester.drag(
        find.textContaining('Nothing is logged until you tap Log it'),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(DraggableScrollableSheet)).top,
        lessThan(size.height * 0.1),
      );

      // Dismissing keeps the thread: reopened, the message is still there.
      h.answer(message());
      await sendInSheet(tester, '2 eggs');
      await settleBuddy(tester);
      // The card took the sheet to full height: back dismisses it.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BuddySheet), findsNothing);
      await openBuddySheet(tester);
      expect(find.text('2 eggs', skipOffstage: false), findsOneWidget);
      expect(find.text('Log it', skipOffstage: false), findsOneWidget);
      await unmountBuddy(tester, h);
    });
  }

  // rule: A22 card-top-visible
  testWidgets('A22 a new card opens the sheet to full height and shows from '
      'its top', (tester) async {
    final h = BuddyHarness()
      ..answer(
        message([
          intent([item(), item(), item(), item()]),
        ]),
      );
    await pumpBuddyHost(tester, h, size: const Size(320, 640));
    await openBuddySheet(tester);
    await sendInSheet(tester, '4 eggs');
    await settleBuddy(tester);
    final sheet = tester.getRect(find.byType(DraggableScrollableSheet));
    expect(sheet.top, lessThan(640 * 0.1));
    final header = tester.getRect(find.text('Breakfast · 8:00 AM'));
    final composer = tester.getRect(find.byType(FbComposer));
    expect(header.top, greaterThanOrEqualTo(sheet.top));
    expect(header.bottom, lessThan(composer.top));
    await unmountBuddy(tester, h);
  });

  // rule: A22 composer-focus
  testWidgets('UX-023 composer keeps focus after sending and while a card is '
      'open', (tester) async {
    final h = BuddyHarness()..answer(message());
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    await sendInSheet(tester, '2 eggs');
    await settleBuddy(tester);
    expect(find.text('Log it'), findsOneWidget);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await unmountBuddy(tester, h);
  });

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

  // rule: A22 second-503
  testWidgets('A22 second 503 stops retry and returns the text to the '
      'composer', (tester) async {
    final h = BuddyHarness();
    h.adapter.respond = json({'status': 503}, status: 503);
    await pumpBuddyHost(tester, h);
    await openBuddySheet(tester);
    await sendInSheet(tester, '2 eggs');
    await settleBuddy(tester);
    expect(find.text('Buddy is busy right now.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await settleBuddy(tester);
    expect(
      find.text('Buddy is still busy. Your text is back in the box below.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
    // Buddy gave up: search is offered instead.
    expect(find.text('Search foods'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '2 eggs');
    expect(h.adapter.requests, hasLength(2));
    // Closed and opened again before typing: the text is still there once.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await openBuddySheet(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
      reason: 'taken by the first sheet',
    );
    await unmountBuddy(tester, h);
  });

  // rule: A22 failure-copy
  testWidgets('A22 rejected or rate limited sends offer search, not retry', (
    tester,
  ) async {
    for (final (status, copy) in [
      (400, "Buddy couldn't read that message."),
      (429, "You've reached today's Buddy limit. Search still works."),
    ]) {
      final h = BuddyHarness();
      h.adapter.respond = json({'status': status}, status: status);
      await pumpBuddyHost(tester, h);
      await openBuddySheet(tester);
      await sendInSheet(tester, '2 eggs');
      await settleBuddy(tester);
      expect(find.text(copy), findsOneWidget, reason: '$status');
      expect(find.text('Try again'), findsNothing);
      await tester.tap(find.text('Search foods'));
      await tester.pumpAndSettle();
      expect(h.navigator.pushed.single, isA<FoodSearchRoute>());
      await unmountBuddy(tester, h);
    }
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
