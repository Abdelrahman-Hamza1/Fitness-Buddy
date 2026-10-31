import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../test/fixtures/buddy_fixtures.dart';

/// The 20 fixed synthetic messages (A22 D19): J1–J3 and short meals in the
/// M3 style (English, Arabic, Arabizi). No real user's data.
const List<String> roundTripTexts = [
  j1Text,
  j2Text,
  j3Text,
  '2 eggs and toast',
  'a bowl of lentil soup',
  'chicken shawarma sandwich',
  '150g grilled salmon with rice',
  'a cup of tea with 2 sugars',
  'greek yogurt with honey',
  'a banana and a coffee with milk',
  'فول مع خبز',
  'صحن حمص وزيت زيتون',
  'كاسة لبن',
  'تفاحة وموزة',
  'akalt falafel w hummus',
  'shwayet ruz ma3 djej',
  'tabbouleh salad',
  'a slice of pizza',
  'oatmeal with milk and dates',
  '3 dates and water',
];

/// The value at fraction [p] of the sorted [values] (nearest rank).
int percentile(List<int> values, double p) {
  final sorted = [...values]..sort();
  final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}

/// A22 D19 device round trip, **manual, never in CI**: the real app and
/// sheet against the configured API (dev flavor: the laptop server over
/// `adb reverse`), 20 real interpret calls (paid: needs the owner's scope).
/// Measures Send tap → the first frame after the thread's state has the
/// reply (card, template or failure) and prints only `case-index ms`, the
/// median and p90.
///
/// ```bash
/// cd apps/mobile
/// flutter test integration_test/buddy_round_trip_test.dart --profile \
///   -d <adb-device-id> --dart-define-from-file=config/dev.json \
///   --dart-define=A22_ROUND_TRIP=1
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // covers: AI-030
  // rule: A22 device-round-trip
  testWidgets('A22 message to card p90 on the device', (tester) async {
    const enabled = bool.fromEnvironment('A22_ROUND_TRIP');
    if (!enabled) {
      markTestSkipped('Paid sends: pass --dart-define=A22_ROUND_TRIP=1');
      return;
    }
    final config = AppConfig.fromEnvironment();
    final cache = await getTemporaryDirectory();
    final root = await cache.createTemp('fb_round_trip');
    addTearDown(() => root.deleteSync(recursive: true));
    final container = ProviderContainer(
      overrides: [
        ...appOverrides(config),
        // A51 TD-110: start on Today, not the first run.
        firstRunEnabledProvider.overrideWithValue(false),
        // A throw-away profile: the phone's real diary is never touched.
        databaseLocationProvider.overrideWithValue(
          DatabaseLocation(
            profileKey: 'buddy_round_trip',
            root: () async => root.path,
            temporary: () async => root.path,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FitnessBuddyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    final db = container.read(appDatabaseProvider);
    final watch = Stopwatch()..start();
    while (!await db.isCatalogAttached() && watch.elapsed.inSeconds < 60) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.tap(find.byType(FbInputBar));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BuddySheet), findsOneWidget);

    final timings = <int>[];
    for (final (index, text) in roundTripTexts.indexed) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      // The thread's state says when the reply (card, template or failure)
      // is in: a new turn that has left "sending". Widget counts would also
      // count the user's bubble, the skeleton and lazily built rows.
      BuddyThread thread() => container.read(buddyThreadControllerProvider);
      final turnsBefore = thread().turns.length;
      bool replied() =>
          thread().turns.length > turnsBefore &&
          thread().turns.last.phase != BuddyTurnPhase.sending;
      final timer = Stopwatch()..start();
      await tester.tap(find.byTooltip('Send'));
      while (!replied() && timer.elapsed.inSeconds < 60) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      // The frame that shows it.
      await tester.pump();
      timer.stop();
      timings.add(timer.elapsedMilliseconds);
      // Only the case index and timing: never the text or the reply.
      // ignore: avoid_print
      print('case-$index ${timer.elapsedMilliseconds}');
      await tester.pump(const Duration(milliseconds: 500));
    }
    // The summary: counts and timings only.
    // ignore: avoid_print
    print(
      'device=${Platform.operatingSystem} n=${timings.length} '
      'median=${percentile(timings, 0.5)} p90=${percentile(timings, 0.9)}',
    );
    expect(timings, hasLength(roundTripTexts.length));
  });
}
