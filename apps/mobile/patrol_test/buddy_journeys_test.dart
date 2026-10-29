import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import '../test/fixtures/buddy_fixtures.dart';
import 'support/buddy_fake_api.dart';
import 'support/patrol_support.dart';

/// The live diary entries of the profile.
Future<int> _liveEntries(ProviderContainer container) async {
  final db = container.read(appDatabaseProvider);
  final rows = await (db.select(
    db.diaryEntries,
  )..where((t) => t.deletedAt.isNull())).get();
  return rows.length;
}

/// Opens Buddy's sheet from Today's input bar.
Future<void> _openSheet(WidgetTester tester) async {
  await tapExactly(tester, find.byType(FbInputBar), 'the input bar');
  await waitUntil(
    tester,
    () => find.byType(FbComposer).evaluate().isNotEmpty,
    "Buddy's sheet",
  );
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Types [text] into the composer, sends it and waits for its card.
Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 100));
  await tapExactly(tester, find.byTooltip('Send'), 'Send');
  await waitUntil(
    tester,
    () => find.text('Log it').evaluate().isNotEmpty,
    'the proposal card',
  );
}

/// Scrolls [target] into the sheet's view and taps it.
Future<void> _tapInSheet(
  WidgetTester tester,
  Finder target,
  String what,
) async {
  await tester.ensureVisible(target);
  await pumpFor(tester, const Duration(milliseconds: 300));
  await tapExactly(tester, target, what);
}

/// Logs the open card and waits for its one-line reply.
Future<void> _logIt(WidgetTester tester) async {
  await _tapInSheet(tester, find.text('Log it').last, 'Log it');
  await waitUntil(
    tester,
    () => find.textContaining('Logged ').evaluate().isNotEmpty,
    'the logged reply',
  );
}

/// J1–J3 on the device (A22 D18): the real app and sheet on a throw-away
/// profile, Buddy's answers recorded and served by in-app fake transports
/// for both the auth and the API clients, with an in-memory session store
/// (no network, no keystore). Each journey logs through the single writer.
void main() {
  patrolTest(
    'AI-030 AI-032 AI-143 J1 J2 J3 Buddy journeys log through the chat sheet',
    ($) async {
      final api = BuddyFakeAdapter();
      final auth = BuddyFakeAuthAdapter();
      final container = await bootApp(
        $,
        'it-buddy',
        rootName: 'fb_buddy_it',
        overrides: buddyFakeApi(api, auth: auth),
      );
      final tester = $.tester;
      final before = await _liveEntries(container);

      await _openSheet(tester);

      // J1: two questions, answer one, then log.
      await _send(tester, j1Text);
      expect(find.text('Any cooking oil?'), findsOneWidget);
      await _tapInSheet(
        tester,
        find.widgetWithText(FbAnswerChip, 'Cooked'),
        'the Cooked answer',
      );
      await pumpFor(tester, const Duration(milliseconds: 300));
      await _logIt(tester);
      await waitUntilAsync(
        tester,
        () async => await _liveEntries(container) == before + 2,
        'J1 entries',
      );

      // J2: an estimate with its range, then log.
      await _send(tester, j2Text);
      await _tapInSheet(
        tester,
        find.byType(FbEstimateMarker).first,
        'the estimate marker',
      );
      await waitUntil(
        tester,
        () => find
            .text("Buddy's estimate: no close match in the food database.")
            .evaluate()
            .isNotEmpty,
        'the estimate sheet',
      );
      // Close the estimate sheet (the topmost route).
      final reason = find.text(
        "Buddy's estimate: no close match in the food database.",
      );
      await Navigator.of(tester.element(reason)).maybePop();
      await pumpFor(tester, const Duration(milliseconds: 500));
      await _logIt(tester);
      await waitUntilAsync(
        tester,
        () async => await _liveEntries(container) == before + 3,
        'J2 entry',
      );

      // J3: Arabic in, English reply out.
      await _send(tester, j3Text);
      await _logIt(tester);
      await waitUntilAsync(
        tester,
        () async => await _liveEntries(container) == before + 5,
        'J3 entries',
      );
      expect(find.textContaining('eaten today'), findsWidgets);
      expect(api.interpreted, [j1Text, j2Text, j3Text]);
      expect(auth.calls, contains('/v1/auth/anonymous'));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
