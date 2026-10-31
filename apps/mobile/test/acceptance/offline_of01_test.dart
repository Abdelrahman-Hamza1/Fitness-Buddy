import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weigh_in_repository.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:fb_mobile/features/workouts/presentation/set_row.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../core/catalog/support/catalog_support.dart' show writeFixturePack;
import '../core/db/support/db_support.dart'
    show FixedPack, fileDatabase, tempDir;
import '../features/diary/support/diary_harness.dart' show atDay, newEntry;
import '../features/foods/presentation/support/personal_food_support.dart'
    show applyOps, dbOf, settle, useWindow;
import '../features/workouts/support/workout_harness.dart'
    show benchDraft, sessionDraft, wid;
import '../helpers/pump_app.dart';
import 'support/acceptance_app.dart';
import 'support/hanging_network.dart';

/// Today's live diary entries.
Future<List<DiaryEntryRow>> _todayEntries(
  WidgetTester tester,
  AppDatabase db,
  LocalDate today,
) async => (await tester.runAsync(
  () => (db.select(
    db.diaryEntries,
  )..where((t) => t.deletedAt.isNull() & t.localDate.equals('$today'))).get(),
))!;

/// Types [keys] on the visible number pad.
Future<void> _pad(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    await tester.tap(
      find.descendant(of: find.byType(FbNumberPad), matching: find.text(key)),
    );
    await tester.pump();
  }
}

/// The bundled pack's rice (the fixture pack), so the chip resolves it the
/// way the app does.
const _rice = 'usda:rice_white_long_grain_cooked';

void main() {
  // covers: OF-01, AT-005
  testWidgets('OF-01 AT-005 airplane mode: a quick-add chip, an entry edit, a '
      'weigh-in, a workout by the form and the Progress charts all work while '
      'every request hangs unanswered', (tester) async {
    // Tall, so a sheet with its pad and the day's rows show whole.
    useWindow(tester, width: 360, height: 1500);
    // Production wiring: pack updates, online search and notification
    // scheduling on; the bundled pack (the fixture) resolves foods. Every
    // request hangs, so anything that awaits the network never finishes.
    final phone = TestPhone(
      onlineSearch: true,
      packUpdates: true,
      notifications: true,
    );
    final network = HangingNetwork();
    phone.adapter.respond = network.respond;
    final pack = writeFixturePack('${tempDir().path}/catalog-1.db');
    final container = await pumpApp(
      tester,
      phone: phone,
      overrides: [
        barcodeCameraEnabledProvider.overrideWithValue(false),
        appDatabaseProvider.overrideWith((ref) {
          final db = fileDatabase(
            '${tempDir().path}/user.db',
            catalog: FixedPack(pack),
          );
          return db;
        }),
      ],
    );
    final db = dbOf(container);
    final router = container.read(appRouterProvider);
    final now = EntryTime.now(container.read(clockProvider)).localDateTime;
    final today = now.date;

    // History for a repeat meal: the same food at this time of day, in the
    // meal the app picks for now, on the three days before; and a past
    // workout for the form's hints.
    final slot = container.read(quickAddContextProvider).slotId;
    await applyOps(tester, container, [
      LogEntries([
        for (var d = 1; d <= 3; d++)
          newEntry(
            d,
            when: atDay(today.plusDays(-d), now.hour, now.minute),
            slotId: slot,
            ref: FoodRef.catalog(_rice, version: '1'),
          ),
      ]),
      CreateCustomExercise(wid(1), benchDraft()),
      LogWorkoutSession(wid(10), sessionDraft(date: today.plusDays(-2))),
    ]);
    await settle(tester);
    expect(await _todayEntries(tester, db, today), isEmpty);

    // 1. The quick-add chip logs the repeat meal in one tap. Resolving it
    // builds the search index in a background isolate: real time passes.
    final chip = find.byType(FbQuickAddChip);
    for (var i = 0; i < 100 && chip.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(chip, findsWidgets);
    // The row grows in above the input bar.
    await settle(tester);
    await tester.tap(chip.first);
    await settle(tester);
    final logged = (await _todayEntries(tester, db, today)).single;
    expect(logged.amount, 150);
    // Resolved through the bundled pack, as in the app.
    expect(logged.foodId, _rice);

    // 2. Edit it: open its meal, its row, the amount; 2 × 150 g.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is SlotHeaderTile && w.section.key == logged.slotId,
      ),
    );
    await settle(tester);
    await tester.tap(find.widgetWithText(FbListRow, logged.nameEn).first);
    await settle(tester);
    await tester.tap(
      find.byWidgetPredicate((w) => w is FbChoiceChip && w.label == 'Amount'),
    );
    await settle(tester);
    await _pad(tester, '300');
    await tester.tap(find.widgetWithText(FbButton, 'Save').last);
    await settle(tester);
    final edited = (await _todayEntries(tester, db, today)).single;
    expect(edited.version, 2);
    expect(edited.amount, 300);

    // 3. A weigh-in from Today's weight card.
    await tester.tap(
      find.descendant(of: dayPage(today), matching: find.byType(WeightCard)),
    );
    await settle(tester);
    expect(find.byType(WeighInSheet), findsOneWidget);
    await _pad(tester, '97.4');
    await tester.tap(find.widgetWithText(FbButton, 'Save').last);
    await settle(tester);
    final weighIns = (await tester.runAsync(
      () => WeighInRepository(db).watchLive().first,
    ))!;
    expect(weighIns.single.kg, 97.4);

    // 4. A workout by the form: last time's sets accepted, then Done (the
    // weigh-in's snackbar would cover Done).
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    router.go(WorkoutLogRoute(exercises: [wid(1)]));
    await settle(tester);
    for (final row in tester.widgetList<SetRow>(find.byType(SetRow)).toList()) {
      await tester.tap(find.byKey(ValueKey('workout-set-done-${row.row.id}')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('workout-log-done')));
    await settle(tester);
    final sessions = (await tester.runAsync(
      () => WorkoutRepository(db).allSessions(),
    ))!;
    expect(sessions, hasLength(2));
    expect(sessions.map((s) => s.draft.date), contains(today));

    // 5. Progress draws its charts from the local data.
    router.go(const ProgressRoute());
    await settle(tester);
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is FbBarChart || w is FbTimeSeriesChart,
        skipOffstage: false,
      ),
      findsWidgets,
    );

    // The app did try the network, and none of it has answered: nothing
    // above waited for it. Then the calls fail, as when a timeout ends them.
    expect(phone.events, contains('GET /v1/config'));
    expect(network.waiting, isNotEmpty);
    expect(network.answered, 0);
    network.failAll();
    await unmountApp(tester, container);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
