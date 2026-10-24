import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';
import 'support/today_test_support.dart';

const _pita = 'usda:pita_white';
const _pitaName = 'Pita bread, white';
const _banana = 'usda:banana_raw';
const _bananaName = 'Banana, raw';
const _mealName = 'Pita and banana';

/// The chip of the food or meal called [label] in the quick-add row.
Finder _chip(String label) => find.byWidgetPredicate(
  (w) => w is FbQuickAddChip && w.label == label,
  description: 'quick-add chip "$label"',
);

/// The stored entries of [date], read from the diary.
Future<List<DiaryEntry>> _stored(ProviderContainer container, LocalDate date) =>
    container
        .read(diaryRepositoryProvider)
        .watchEntries(date, date)
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw TestFailure('Timed out reading the diary for $date'),
        );

/// The meal the clock's current time falls in, worked out here from the
/// stored slots (not from the app's quick-add context), so the tests check
/// the app's choice against an independent one.
Future<String> _currentSlot(ProviderContainer container) async {
  final slots = await container
      .read(diaryRepositoryProvider)
      .watchSlots()
      .first
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TestFailure('Timed out reading the meals'),
      );
  final now = EntryTime.now(container.read(clockProvider)).localDateTime;
  final slot = const SlotAssigner().assign(
    now.minuteOfDay,
    slots,
    SlotMode.normal,
  );
  expect(slot, isNotNull, reason: 'a meal covers the current time');
  return slot!;
}

/// Logs [foodId] once on each of the days [daysAgo] into [slotId] through the
/// app's own logging command (the real single writer, as a user would have),
/// with one [unit]. Past days only, so nothing is logged
/// on today.
Future<void> _seedHistory(
  ProviderContainer container, {
  required String foodId,
  required String unit,
  required List<int> daysAgo,
  required String slotId,
  required LocalDate today,
}) async {
  // The pack installs in the background after the app boots: wait (bounded,
  // 30 s) until it can answer, instead of failing on the first empty read.
  final catalog = container.read(foodCatalogRepositoryProvider);
  CatalogFood? food;
  for (var attempt = 0; attempt < 60 && food == null; attempt++) {
    food = (await catalog.foodsByIds([foodId]))[foodId]?.firstOrNull;
    if (food == null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
  if (food == null) fail('The pack has no food $foodId after 30 s');
  final choice = catalogChoice(food);
  for (final ago in daysAgo) {
    final result = await container.read(logFoodProvider)(
      choice: choice,
      input: Quantity(1, unit),
      date: today.plusDays(-ago),
      slotId: slotId,
    );
    expect(result, isA<FoodLogged>(), reason: 'seeding $foodId $ago days ago');
  }
}

/// Waits for the snackbar that says [prefix]... (a prefix match, never the
/// whole text) and returns once it shows.
Future<void> _waitForSnackBar(WidgetTester tester, String prefix) => waitUntil(
  tester,
  () => find
      .descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(prefix),
      )
      .evaluate()
      .isNotEmpty,
  'the snackbar "$prefix..."',
);

/// Taps the snackbar's Undo, proving the tap lands.
Future<void> _tapUndo(WidgetTester tester) => tapExactly(
  tester,
  find.descendant(of: find.byType(SnackBar), matching: find.text('Undo')),
  'Undo',
);

/// OF-01 UX-004 DY-030 DY-031 on the device (A09 D15): no API is reachable (as
/// in `app_test`), the profile is a throw-away database, and the history is
/// seeded through the app's own logging command and the real single writer,
/// never by writing tables.
void main() {
  patrolTest('OF-01 UX-004 DY-030 quick-add chip offline', ($) async {
    final container = await bootApp($, 'it-quick', rootName: 'fb_quick_it');
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final slotId = await _currentSlot(container);

    // A week of history: the pita five days running, the banana twice. The
    // pita is used more and as recently, so it is the first chip.
    await _seedHistory(
      container,
      foodId: _pita,
      unit: 'loaf',
      daysAgo: [1, 2, 3, 4, 5],
      slotId: slotId,
      today: today,
    );
    await _seedHistory(
      container,
      foodId: _banana,
      unit: 'piece',
      daysAgo: [1, 2],
      slotId: slotId,
      today: today,
    );
    expect(await _stored(container, today), isEmpty);

    // The chip row shows the two foods, with nothing logged today yet.
    final pita = _chip(_pitaName);
    await waitUntil(
      tester,
      () =>
          pita.evaluate().isNotEmpty &&
          _chip(_bananaName).evaluate().isNotEmpty,
      'the pita and banana chips',
    );
    expect(find.byType(FbQuickAddRow), findsOneWidget);
    await pumpFor(tester, const Duration(milliseconds: 400));

    // The 320 x 640 dp phone: the first chip is on screen and above the input
    // bar, so neither the bar nor the row hides it.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final chipRect = tester.getRect(pita);
    final barRect = tester.getRect(find.byType(FbInputBar));
    expect(chipRect.left, greaterThanOrEqualTo(0));
    expect(chipRect.right, lessThanOrEqualTo(screen.width));
    expect(
      chipRect.bottom,
      lessThanOrEqualTo(barRect.top),
      reason: 'the chip must not sit under the input bar',
    );

    // One tap on the chip logs the pita, one loaf, into the current meal.
    await tapExactly(tester, pita, 'the pita chip');
    await waitUntilAsync(
      tester,
      () async => (await _stored(container, today)).isNotEmpty,
      'the pita to be logged',
    );
    final logged = await _stored(container, today);
    expect(logged, hasLength(1));
    expect(logged.single.food.ref.id, _pita);
    expect(logged.single.localDate, today);
    expect(logged.single.slotId, slotId);
    expect(logged.single.amount.input, Quantity(1, 'loaf'));
    expect(DiaryTotals.day(logged).kcal, greaterThan(0));
    await _waitForSnackBar(tester, 'Logged $_pitaName');

    // The day's total on Today is the stored total.
    final number = NumberFormat.decimalPattern();
    final header = dayNumber(today);
    await waitUntil(
      tester,
      () =>
          header.evaluate().length == 1 &&
          tester.widget<FbBigNumber>(header).value ==
              number.format(DisplayRounding.kcal(DiaryTotals.day(logged).kcal)),
      'the header total to show the pita',
    );

    // Undo removes it again, and the pita is offered again.
    await _tapUndo(tester);
    await waitUntilAsync(
      tester,
      () async => (await _stored(container, today)).isEmpty,
      'Undo to remove the pita',
    );
    await waitUntil(
      tester,
      () =>
          header.evaluate().length == 1 &&
          tester.widget<FbBigNumber>(header).value ==
              number.format(DisplayRounding.kcal(0)),
      'the header total to be empty again',
    );
    await waitUntil(
      tester,
      () => pita.evaluate().isNotEmpty,
      'the pita chip to come back',
    );
  }, timeout: const Timeout(Duration(minutes: 4)));

  patrolTest('OF-01 DY-031 log a saved meal from Me offline', ($) async {
    final container = await bootApp(
      $,
      'it-saved-meal',
      rootName: 'fb_quick_it',
    );
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final yesterday = today.plusDays(-1);
    final slotId = await _currentSlot(container);

    // A meal saved from yesterday's pita and banana, the way a user saves one
    // (the same op the meal's menu on Today sends).
    await _seedHistory(
      container,
      foodId: _pita,
      unit: 'loaf',
      daysAgo: [1],
      slotId: slotId,
      today: today,
    );
    await _seedHistory(
      container,
      foodId: _banana,
      unit: 'piece',
      daysAgo: [1],
      slotId: slotId,
      today: today,
    );
    final source = await _stored(container, yesterday);
    expect(source, hasLength(2));
    final saved = await container.read(diaryApplyProvider)(
      ChangeSet([
        SaveMeal(
          savedMealId: container.read(idGeneratorProvider).next(),
          name: _mealName,
          source: MealSource.entries([for (final e in source) e.id]),
          expected: SourceVersions(
            entries: [for (final e in source) VersionedId(e.id, e.version)],
          ),
        ),
      ], origin: Origin.direct),
    );
    expect(saved, isA<Applied>(), reason: 'saving the meal');

    // Me > Saved meals > the meal.
    await tapExactly(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Me'),
      ),
      'the Me tab',
    );
    await waitUntil(
      tester,
      () => find.byType(MeScreen).evaluate().isNotEmpty,
      'the Me screen',
    );
    await tapExactly(
      tester,
      find.widgetWithText(FbListRow, 'Saved meals'),
      'the Saved meals row',
    );
    final row = find.widgetWithText(FbListRow, _mealName);
    await waitUntil(
      tester,
      () => row.evaluate().isNotEmpty,
      'the saved meal in the list',
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    await tapExactly(tester, row, 'the saved meal row');

    // The detail shows both items; Log copies them into the current meal.
    final log = find.widgetWithText(FbButton, 'Log');
    await waitUntil(
      tester,
      () =>
          find.text(_pitaName).evaluate().isNotEmpty &&
          find.text(_bananaName).evaluate().isNotEmpty &&
          log.evaluate().isNotEmpty &&
          tester.widget<FbButton>(log).onPressed != null,
      'the saved meal detail',
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    await tapExactly(tester, log, 'Log');
    await waitUntilAsync(
      tester,
      () async => (await _stored(container, today)).length == 2,
      'the saved meal to be logged',
    );
    final logged = await _stored(container, today);
    expect(logged.map((e) => e.food.ref.id).toSet(), {_pita, _banana});
    expect(logged.every((e) => e.slotId == slotId), isTrue);
    expect(logged.every((e) => e.localDate == today), isTrue);
    await _waitForSnackBar(tester, 'Logged $_mealName');

    // Undo removes the whole meal in one step.
    await _tapUndo(tester);
    await waitUntilAsync(
      tester,
      () async => (await _stored(container, today)).isEmpty,
      'Undo to remove the saved meal',
    );
    // The saved meal itself is untouched, and so is yesterday.
    expect(await _stored(container, yesterday), hasLength(2));
    expect(find.widgetWithText(FbButton, 'Log'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
