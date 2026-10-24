import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../patrol_test/support/today_test_support.dart';
import '../../../core/db/support/db_support.dart';
import '../../../helpers/pump_app.dart' show unmountApp;
import '../../../helpers/test_phone.dart';
import '../../diary/support/diary_fixtures.dart';

void main() {
  testWidgets('HM-009 HM-001 empty yesterday totals can be revealed without '
      'a hit-testable centre', (tester) async {
    final container = await _start(tester);
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final yesterday = today.plusDays(-1);
    await waitForToday(tester, () => showsLoadedDay(tester, today), 'today');
    await tester.tap(find.byTooltip('Previous day'));
    await waitForToday(
      tester,
      () => showsLoadedDay(tester, yesterday),
      'yesterday',
    );
    expect(dayNumber(yesterday).hitTestable(), findsNothing);
    await revealDayWidget(
      tester,
      dayNumber(yesterday),
      yesterday,
      interactive: false,
    );
    expect(tester.widget<FbBigNumber>(dayNumber(yesterday)).value, '0');
    expect(
      find.text(
        'Nothing logged on this day. Forgot something? Tap + on a meal.',
      ),
      findsOneWidget,
    );
    // Exercise the same lazy row traversal and return to totals as Patrol.
    for (final slot in DefaultSlots.all) {
      final row = find.descendant(
        of: dayPage(yesterday),
        matching: find.byKey(ValueKey('slot:${slot.id}')),
      );
      await revealDayWidget(tester, row, yesterday);
    }
    await revealDayWidget(
      tester,
      dayNumber(yesterday),
      yesterday,
      interactive: false,
    );
    expect(tester.widget<FbBigNumber>(dayNumber(yesterday)).value, '0');
    await unmountApp(tester);
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'HM-009 DY-020 thirty-entry device readiness survives lazy meals, '
    'prefetch, uncached jump and tab reselect',
    (tester) async {
      final clock = ManualClock(
        DateTime.utc(2026, 10, 23, 1),
        offsetMinutes: -180,
      );
      final today = EntryTime.now(clock).localDate;
      expect(today, LocalDate(2026, 10, 22));
      final yesterday = today.plusDays(-1);
      final far = today.plusDays(-4);
      final container = await _start(
        tester,
        clock: clock,
        seed: [today, yesterday, far],
      );
      Future<void> loaded(LocalDate date) async {
        await waitForToday(tester, () => showsLoadedDay(tester, date), '$date');
        final view = container.read(dayViewProvider(date)).requireValue;
        expect(view.raw.entries, hasLength(30));
        expect(
          view.layout.sections.map((s) => s.key),
          DefaultSlots.all.map((s) => s.id),
        );
        expect(tester.widget<FbBigNumber>(dayNumber(date)).value, '5,445');
        // The old device predicate never becomes true on this viewport.
        expect(
          find
              .descendant(
                of: dayPage(date),
                matching: find.byType(SlotHeaderTile),
              )
              .evaluate()
              .length,
          lessThan(4),
        );
      }

      await loaded(today);
      await waitForToday(
        tester,
        () => container.read(dayViewProvider(yesterday)).hasValue,
        'prefetch',
      );
      await tester.tap(find.byTooltip('Previous day'));
      // A mounted outgoing page must not satisfy the incoming day's check.
      expect(showsLoadedDay(tester, yesterday), isFalse);
      await loaded(yesterday);
      await tester.tap(find.byTooltip('Next day'));
      await loaded(today);
      expect(container.exists(dayViewProvider(far)), isFalse);
      container.read(todayControllerProvider.notifier).goTo(far);
      expect(showsLoadedDay(tester, far), isFalse);
      await loaded(far);
      container.read(todayControllerProvider.notifier).goTo(today);
      await loaded(today);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Progress'),
        ),
      );
      await tester.pumpAndSettle();
      expect(showsLoadedDay(tester, today), isFalse);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Today'),
        ),
      );
      await loaded(today);
      await unmountApp(tester);
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

Future<ProviderContainer> _start(
  WidgetTester tester, {
  ManualClock? clock,
  List<LocalDate> seed = const [],
}) async {
  // A compact phone reproduces the emulator's lazy-list behaviour. The full
  // router, app bootstrap and database readers remain real; HTTP is offline.
  tester.view
    ..physicalSize = const Size(320, 480)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final db = memoryDatabase();
  await tester.runAsync(
    () => insertEntries(db, [
      for (final (day, date) in seed.indexed)
        for (var n = 0; n < 30; n++)
          entryRow(
            day * 100 + n + 1,
            date: '$date',
            slotId: DefaultSlots.all[n < 24 ? n ~/ 8 : 3].id,
            kcal: 80.0 + n * 7,
            occurredAtUtc: DateTime.utc(
              date.year,
              date.month,
              date.day,
              7 + (n < 24 ? n ~/ 8 : 3) * 4,
              n % 8 * 5,
            ).millisecondsSinceEpoch,
          ),
    ]),
  );
  final container = ProviderContainer.test(
    overrides: [
      ...TestPhone().overrides().where((o) => o.origin != clockProvider),
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(
        clock ?? ManualClock(DateTime.utc(2026, 10, 23, 1)),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
  return container;
}
