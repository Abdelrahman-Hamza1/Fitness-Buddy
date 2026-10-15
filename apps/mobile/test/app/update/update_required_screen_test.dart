import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/pump_app.dart';

/// The app on [phone], opened on the update screen (the signal tripped).
Future<void> _pumpUpdateScreen(WidgetTester tester, TestPhone phone) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: ProviderContainer.test(
        overrides: [...phone.overrides(), tripped],
      ),
      child: const FitnessBuddyApp(),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(UpdateRequiredScreen), findsOneWidget);
}

/// Taps "Check again" and lets the check finish.
Future<void> _checkAgain(WidgetTester tester) async {
  await tester.tap(find.text('Check again'));
  await tester.pumpAndSettle();
}

const _checking = 'Checking…';
const _stillOld =
    'Still on an older version. Install the new build, then check again.';
const _failed = "Couldn't check. Are you online?";

void main() {
  testWidgets('UX-040 update screen: body, neutral icon hidden from screen '
      'readers, no result before a check', (tester) async {
    await _pumpUpdateScreen(tester, TestPhone());

    expect(
      find.text(
        "This version can't connect any more. Install the latest one to "
        'continue. Your data stays on your phone.',
      ),
      findsOneWidget,
    );
    final icon = find.byIcon(Icons.system_update_outlined);
    expect(icon, findsOneWidget);
    expect(
      find.ancestor(of: icon, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    expect(find.text(_stillOld), findsNothing);
    expect(find.text(_failed), findsNothing);
  });

  testWidgets('Check again shows "Checking…" and disables the button while '
      'the check runs', (tester) async {
    final answer = Completer<ResponseBody>();
    final phone = TestPhone();
    await _pumpUpdateScreen(tester, phone);
    phone.adapter.respond = (_) => answer.future;

    await tester.tap(find.text('Check again'));
    // dio runs its interceptors on timers: let the fake clock move.
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text(_checking), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    answer.complete(config('0.2.0')(RequestOptions()) as ResponseBody);
    await tester.pumpAndSettle();
    expect(find.text(_checking), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Check again while still too old says so, and the gate stays', (
    tester,
  ) async {
    final phone = TestPhone();
    await _pumpUpdateScreen(tester, phone);

    phone.adapter.respond = config('0.2.0');
    await _checkAgain(tester);

    expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    expect(find.text(_stillOld), findsOneWidget);
    expect(find.text(_failed), findsNothing);
  });

  for (final (name, failure) in [('offline', offline), ('timeout', timeout)]) {
    testWidgets('Check again that fails ($name) asks whether the phone is '
        'online, and the gate stays', (tester) async {
      final phone = TestPhone();
      await _pumpUpdateScreen(tester, phone);

      phone.adapter.respond = failure;
      await _checkAgain(tester);

      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
      expect(find.text(_failed), findsOneWidget);
      expect(find.text(_stillOld), findsNothing);
    });
  }

  testWidgets('the result of the last check replaces the previous one', (
    tester,
  ) async {
    final phone = TestPhone();
    await _pumpUpdateScreen(tester, phone);

    phone.adapter.respond = offline;
    await _checkAgain(tester);
    expect(find.text(_failed), findsOneWidget);

    phone.adapter.respond = config('0.2.0');
    await _checkAgain(tester);
    expect(find.text(_stillOld), findsOneWidget);
    expect(find.text(_failed), findsNothing);
  });

  testWidgets('UX-040 the update screen scrolls instead of overflowing at '
      'text scale 2.0 in landscape', (tester) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(640, 360);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    final phone = TestPhone();
    await _pumpUpdateScreen(tester, phone);

    expect(tester.takeException(), isNull);
    final button = find.text('Check again');
    await tester.scrollUntilVisible(
      button,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    phone.adapter.respond = offline;
    await _checkAgain(tester);
    await tester.scrollUntilVisible(
      find.text(_failed),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
}
