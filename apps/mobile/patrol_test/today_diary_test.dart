import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/database_location.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import 'support/today_test_support.dart';

const _pita = 'usda:pita_white';
const _banana = 'usda:banana_raw';

const List<(String, String)> _slots = [
  (DefaultSlots.breakfastId, 'Breakfast'),
  (DefaultSlots.lunchId, 'Lunch'),
  (DefaultSlots.snacksId, 'Snacks'),
  (DefaultSlots.dinnerId, 'Dinner'),
];

/// Pumps in real time until [done] holds; fails with [reason] after
/// [timeout]. Local work only (database, pack), so the bounds are generous
/// for a slow emulator but nothing waits on a network.
Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() done,
  String reason, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > timeout) {
      fail('Timed out waiting for $reason; on screen: ${_screenSummary()}');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  // One more frame so the widgets reflect the state that satisfied [done].
  await tester.pump(const Duration(milliseconds: 100));
}

/// Taps [target] after proving the tap point really hits it; otherwise fails
/// with what is there instead (a tap that misses is otherwise silent).
Future<void> _tapExactly(
  WidgetTester tester,
  Finder target,
  String what,
) async {
  await tester.ensureVisible(target);
  await _pumpFor(tester, const Duration(milliseconds: 300));
  final box = tester.renderObject<RenderBox>(target);
  final center = tester.getCenter(target);
  final result = tester.hitTestOnBinding(center);
  final hits =
      result.path.any((entry) => entry.target == box) ||
      result.path.any(
        (entry) =>
            entry.target is RenderObject &&
            _isDescendant(entry.target as RenderObject, box),
      );
  if (!hits) {
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    String describe(Iterable<Object> targets) =>
        targets.take(40).map((t) => t.runtimeType.toString()).join(' > ');
    final route = ModalRoute.of(tester.element(target));
    final sheets = find.byType(BottomSheet);
    final sheetRect = sheets.evaluate().isEmpty
        ? 'none'
        : '${tester.getRect(sheets.last)}';
    final first = describe(result.path.map((e) => e.target));
    // Is it transient (an animation) or structural? Look again after 2 s.
    await _pumpFor(tester, const Duration(seconds: 2));
    final later = tester.hitTestOnBinding(tester.getCenter(target));
    final hitsLater = later.path.any(
      (e) =>
          e.target is RenderObject &&
          _isDescendant(e.target as RenderObject, box),
    );
    fail(
      'Tap on $what would miss: center=$center, '
      'rect=${tester.getRect(target)}, screen=$size, sheet=$sheetRect, '
      'route current=${route?.isCurrent} active=${route?.isActive} '
      'animation=${route?.animation?.status} '
      'secondary=${route?.secondaryAnimation?.status}; '
      'hits after 2 s=$hitsLater; path=[$first]',
    );
  }
  await tester.tap(target);
}

bool _isDescendant(RenderObject child, RenderObject ancestor) {
  RenderObject? node = child;
  while (node != null) {
    if (identical(node, ancestor)) return true;
    node = node.parent;
  }
  return false;
}

/// What a failed wait saw: open sheets and the texts in sheets and
/// snackbars (synthetic test data only), so CI annotations explain a timeout.
String _screenSummary() {
  String texts(Finder of) => find
      .descendant(of: of, matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .where((t) => t.isNotEmpty)
      .take(40)
      .join(' | ');
  final sheets = find.byType(BottomSheet);
  final snacks = find.byType(SnackBar);
  final buttons = find
      .byType(FbButton)
      .evaluate()
      .map((e) => e.widget as FbButton)
      .map((b) => '${b.label}:${b.onPressed == null ? 'off' : 'on'}')
      .join(' ');
  return 'sheets=${sheets.evaluate().length} [${texts(sheets)}]; '
      'snackbars=${snacks.evaluate().length} [${texts(snacks)}]; '
      'buttons [$buttons]';
}

/// The same, for a condition that needs an `await` (the database).
Future<void> _waitUntilAsync(
  WidgetTester tester,
  Future<bool> Function() done,
  String reason, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!await done().timeout(
    timeout,
    onTimeout: () => throw TestFailure('Timed out awaiting $reason'),
  )) {
    if (watch.elapsed > timeout) fail('Timed out waiting for $reason');
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets animations and queued frames finish, in real time.
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < duration) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The item row of the entry [id] (the tile, whatever its meal).
Finder _tile(String id) => find.byKey(ValueKey<String>('entry:$id'));

Finder _rowOf(String id) =>
    find.descendant(of: _tile(id), matching: find.byType(FbListRow));

Finder _slotRow(LocalDate date, String name) => find.descendant(
  of: dayPage(date),
  matching: find.widgetWithText(FbDisclosureRow, name),
);

/// A07 WP5's pick-and-add, from the search screen the "+" of a meal opened:
/// search [query], open the result of [foodId], choose [unitId] and the
/// amount [digit] explicitly (never the saved defaults), press Add and wait
/// for the search to close.
Future<void> _addFood(
  WidgetTester tester, {
  required String query,
  required String foodId,
  required String unitId,
  required String digit,
  required String addedName,
}) async {
  await _waitUntil(
    tester,
    () => find.byType(FoodSearchScreen).evaluate().isNotEmpty,
    'the food search screen',
  );
  await _pumpFor(tester, const Duration(milliseconds: 400));
  await tester.enterText(find.byType(TextField), query);
  final result = find.byWidgetPredicate(
    (w) => w is FoodResultRow && w.row.choice.ref.id == foodId,
  );
  await _waitUntil(
    tester,
    () => result.evaluate().isNotEmpty,
    'the result $foodId for "$query"',
  );
  await tester.ensureVisible(result.first);
  await tester.tap(result.first);
  await _waitUntil(
    tester,
    () =>
        find.byType(FoodSheet).evaluate().isNotEmpty &&
        find.text('Add').evaluate().isNotEmpty,
    'the food sheet to load',
  );
  await _pumpFor(tester, const Duration(milliseconds: 400));
  final picker = tester.widget<FbUnitPicker>(find.byType(FbUnitPicker));
  final unitLabel = picker.units.singleWhere((u) => u.id == unitId).label;
  await tester.tap(
    find.descendant(
      of: find.byType(FbUnitPicker),
      matching: find.text(unitLabel),
    ),
  );
  await tester.pump();
  await tester.tap(find.byType(FbAmountDisplay));
  await tester.pump();
  final key = find.descendant(
    of: find.byType(FbNumberPad),
    matching: find.text(digit),
  );
  await tester.ensureVisible(key);
  await tester.tap(key);
  await tester.pump();
  await tester.ensureVisible(find.text('Done'));
  await tester.tap(find.text('Done'));
  await tester.pump();
  final add = find.text('Add');
  expect(add, findsOneWidget);
  await tester.ensureVisible(add);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(add);
  await _waitUntil(
    tester,
    () =>
        find.byType(FoodSearchScreen).evaluate().isEmpty &&
        find.byType(FoodSheet).evaluate().isEmpty &&
        find.textContaining('Added $addedName to ').evaluate().isNotEmpty,
    'the search to close and the undo snackbar to show',
  );
  expect(find.byType(TodayScreen), findsOneWidget);
}

/// OF-01 HM-009 DY-022 on the device: the host journey of A08a (part a)
/// through the real app, the real router and the real database. Nothing is
/// faked and no API is reachable (as in `app_test`), so this is the offline
/// diary. The profile is a throw-away database in the cache directory, so
/// a phone's real diary is never touched.

/// drift opens the database in a background isolate and sends the location's
/// resolvers there, so they must capture only the path (a closure written in
/// the test body would capture the WidgetTester and can't be sent).
DatabaseLocation isolatedLocation(String profileKey, String path) =>
    DatabaseLocation(
      profileKey: profileKey,
      root: () async => path,
      temporary: () async => path,
    );

/// Starts the real app on a throw-away profile database in the cache
/// directory (a phone's real diary is never touched), waits for the pack,
/// and returns the container.
Future<ProviderContainer> _boot(
  PatrolIntegrationTester $,
  String profileKey,
) async {
  final config = AppConfig.fromEnvironment();
  final cache = await getTemporaryDirectory();
  final root = await cache.createTemp('fb_today_it');
  addTearDown(() {
    try {
      root.deleteSync(recursive: true);
    } on FileSystemException {
      // The cache directory is cleaned by the system anyway.
    }
  });
  final container = ProviderContainer(
    overrides: [
      ...appOverrides(config),
      databaseLocationProvider.overrideWithValue(
        isolatedLocation(profileKey, root.path),
      ),
    ],
  );
  addTearDown(container.dispose);
  final tester = $.tester;

  // Loading skeletons pulse continuously; wait for data below, not settle.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
  expect($(TodayScreen), findsOneWidget);

  // The pack installs in the background after the first frame; wait for it
  // before searching.
  final db = container.read(appDatabaseProvider);
  await _waitUntilAsync(
    tester,
    db.isCatalogAttached,
    'the catalog pack to attach',
    timeout: const Duration(seconds: 60),
  );
  return container;
}

/// What the journeys read: the stored diary, and the header and every meal
/// row of a day checked against it.
class _Diary {
  new(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  Future<List<DiaryEntry>> stored(LocalDate date) => container
      .read(diaryRepositoryProvider)
      .watchEntries(date, date)
      .first
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TestFailure('Timed out reading diary for $date'),
      );

  /// The header and every meal row of [date] against what is stored. The view
  /// follows the database through a stream, so it gets a moment.
  Future<void> expectStored(String step, LocalDate date) async {
    final number = NumberFormat.decimalPattern();
    final entries = await stored(date);
    // Sliver rows below the viewport may not even be built on a phone.
    // Verify each total after revealing its row, then restore the top.
    final numberFinder = dayNumber(date);
    await revealDayWidget(tester, numberFinder, date, interactive: false);
    await _waitUntil(
      tester,
      () =>
          tester.widget<FbBigNumber>(numberFinder).value ==
          number.format(DisplayRounding.kcal(DiaryTotals.day(entries).kcal)),
      '$step: header total for $date',
    );
    for (final (slotId, name) in _slots) {
      final row = _slotRow(date, name);
      await revealDayWidget(tester, row, date);
      final rows = entries.where((e) => e.slotId == slotId);
      final kcal = number.format(
        DisplayRounding.kcal(DiaryTotals.day(rows).kcal),
      );
      final text = rows.isEmpty ? '—' : '$kcal kcal';
      await _waitUntil(
        tester,
        () =>
            find
                .descendant(of: row, matching: find.text(text))
                .evaluate()
                .length ==
            1,
        '$step: $name should show $text on $date',
      );
    }
    await revealDayWidget(tester, numberFinder, date, interactive: false);
  }
}

/// Taps the header button [tooltip] and waits until it says [label].
Future<void> _goToDay(WidgetTester tester, String tooltip, String label) async {
  await tester.tap(find.byTooltip(tooltip));
  await _waitUntil(
    tester,
    () => find
        .descendant(of: find.byType(FbDateHeader), matching: find.text(label))
        .evaluate()
        .isNotEmpty,
    'the header to say $label',
  );
  await _pumpFor(tester, const Duration(milliseconds: 600));
}

/// Opens the meal [name] of [date] if it is closed.
Future<void> _openSlot(WidgetTester tester, LocalDate date, String name) async {
  final row = _slotRow(date, name);
  await revealDayWidget(tester, row, date);
  if (tester.widget<FbDisclosureRow>(row).expanded) return;
  await tester.tap(row);
  await _waitUntil(
    tester,
    () => tester.widget<FbDisclosureRow>(row).expanded,
    'the $name meal to open',
  );
}

/// Opens the details of the entry [id] (in the meal [slot] of [date]) and
/// returns the panel.
Future<Finder> _openDetails(
  WidgetTester tester,
  LocalDate date,
  String slot,
  String id,
) async {
  await _openSlot(tester, date, slot);
  final panel = find.byKey(ValueKey<String>('details:$id'));
  if (panel.evaluate().isNotEmpty) return panel;
  await revealDayWidget(tester, _rowOf(id), date);
  await tester.tap(_rowOf(id));
  await _waitUntil(
    tester,
    () => panel.evaluate().length == 1,
    'the item details to open',
  );
  return panel;
}

/// Taps [target] (revealed first) inside the day's page of [date].
Future<void> _tapIn(WidgetTester tester, Finder target, LocalDate date) async {
  await revealDayWidget(tester, target, date);
  await tester.tap(target);
}

void main() {
  patrolTest('OF-01 HM-009 DY-022 offline diary part a on yesterday', (
    $,
  ) async {
    final container = await _boot($, 'it-today');
    final tester = $.tester;
    final diary = _Diary(tester, container);
    final stored = diary.stored;
    final expectStored = diary.expectStored;

    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final yesterday = today.plusDays(-1);
    final dayBefore = today.plusDays(-2);

    // Yesterday, via the header's previous-day button.
    await tester.tap(find.byTooltip('Previous day'));
    await _waitUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(FbDateHeader),
            matching: find.text('Yesterday'),
          )
          .evaluate()
          .isNotEmpty,
      'the header to say Yesterday',
    );
    await _pumpFor(tester, const Duration(milliseconds: 600));
    await expectStored('empty yesterday', yesterday);
    expect(await stored(yesterday), isEmpty);

    // Add: pita to Breakfast and a banana to Lunch, each through the meal's
    // "+" (it opens the search for that meal and the viewed day).
    final addBreakfast = find.descendant(
      of: dayPage(yesterday),
      matching: find.byTooltip('Add food to Breakfast'),
    );
    await revealDayWidget(tester, addBreakfast, yesterday);
    await tester.tap(addBreakfast);
    await _addFood(
      tester,
      query: 'pita',
      foodId: _pita,
      unitId: 'loaf',
      digit: '1',
      addedName: 'Pita bread, white',
    );
    await _waitUntilAsync(
      tester,
      () async => (await stored(yesterday)).length == 1,
      'the pita in the diary',
    );
    final pita = (await stored(yesterday)).single;
    expect(pita.food.ref.id, _pita);
    expect(pita.slotId, DefaultSlots.breakfastId);
    expect(pita.localDate, yesterday);
    expect(pita.amount.input.unitCode, 'loaf');
    expect(pita.amount.input.amount, 1);
    await expectStored('pita added', yesterday);

    final addLunch = find.descendant(
      of: dayPage(yesterday),
      matching: find.byTooltip('Add food to Lunch'),
    );
    await revealDayWidget(tester, addLunch, yesterday);
    await tester.tap(addLunch);
    await _addFood(
      tester,
      query: 'banana',
      foodId: _banana,
      unitId: 'piece',
      digit: '1',
      addedName: 'Banana, raw',
    );
    await _waitUntilAsync(
      tester,
      () async => (await stored(yesterday)).length == 2,
      'the banana in the diary',
    );
    final banana = (await stored(yesterday))
        .singleWhere((e) => e.food.ref.id == _banana);
    expect(banana.slotId, DefaultSlots.lunchId);
    expect(banana.amount.input.unitCode, 'piece');
    expect(banana.amount.input.amount, 1);
    await expectStored('banana added', yesterday);

    // Details: open Breakfast, tap the item, see the panel.
    await revealDayWidget(tester, _slotRow(yesterday, 'Breakfast'), yesterday);
    await tester.tap(_slotRow(yesterday, 'Breakfast'));
    await revealDayWidget(tester, _rowOf(pita.id), yesterday);
    await tester.tap(_rowOf(pita.id));
    final panel = find.byKey(ValueKey<String>('details:${pita.id}'));
    await _waitUntil(
      tester,
      () => panel.evaluate().length == 1,
      'the item details to open',
    );
    for (final text in ['Pita bread, white', 'Nutrition for this amount']) {
      expect(
        find.descendant(of: panel, matching: find.textContaining(text)),
        findsWidgets,
        reason: text,
      );
    }
    expect(
      find.descendant(of: panel, matching: find.byType(TextField)),
      findsNothing,
      reason: 'the details edit through chips and sheets, not text fields',
    );
    await expectStored('details open', yesterday);
    await revealDayWidget(tester, _rowOf(pita.id), yesterday);
    await tester.tap(_rowOf(pita.id));
    await _waitUntil(
      tester,
      () => panel.evaluate().isEmpty,
      'the item details to close',
    );

    // Move: open Lunch, swipe the banana toward the end edge, pick Dinner.
    await revealDayWidget(tester, _slotRow(yesterday, 'Lunch'), yesterday);
    await tester.tap(_slotRow(yesterday, 'Lunch'));
    await revealDayWidget(tester, _rowOf(banana.id), yesterday);
    await _swipe(tester, _rowOf(banana.id), 0.7);
    await _waitUntil(
      tester,
      () => find.text('Move to').evaluate().isNotEmpty,
      'the move sheet',
    );
    final dinner = find.descendant(
      of: find.byType(MoveToSlotList),
      matching: find.widgetWithText(FbListRow, 'Dinner'),
    );
    await tester.ensureVisible(dinner);
    await _pumpFor(tester, const Duration(milliseconds: 400));
    await tester.tap(dinner);
    await _waitUntil(
      tester,
      () => find.text('Moved Banana, raw to Dinner').evaluate().isNotEmpty,
      'the move confirmation',
    );
    expect(
      (await stored(yesterday)).singleWhere((e) => e.id == banana.id).slotId,
      DefaultSlots.dinnerId,
    );
    await expectStored('banana moved', yesterday);

    // Delete: swipe the pita toward the start edge.
    await revealDayWidget(tester, _rowOf(pita.id), yesterday);
    await _swipe(tester, _rowOf(pita.id), -0.7);
    await _waitUntil(
      tester,
      () => find.text('Deleted Pita bread, white').evaluate().isNotEmpty,
      'the delete confirmation',
    );
    expect((await stored(yesterday)).map((e) => e.id), [banana.id]);
    expect(_tile(pita.id), findsNothing);
    await expectStored('pita deleted', yesterday);

    // Undo brings it back, with its meal.
    await tester.tap(find.text('Undo'));
    await _waitUntilAsync(
      tester,
      () async => (await stored(yesterday)).any((e) => e.id == pita.id),
      'Undo to restore the pita',
    );
    expect(
      (await stored(yesterday)).singleWhere((e) => e.id == pita.id).slotId,
      DefaultSlots.breakfastId,
    );
    await expectStored('undo', yesterday);

    // Day navigation: the day before is empty; coming back shows the same
    // entries; then on to today (nothing logged there).
    await tester.tap(find.byTooltip('Previous day'));
    await _waitUntil(
      tester,
      () => find
          .text(
            'Nothing logged on this day. Forgot something? Tap + on a meal.',
          )
          .evaluate()
          .isNotEmpty,
      'the empty day before',
    );
    await _pumpFor(tester, const Duration(milliseconds: 600));
    await expectStored('day before', dayBefore);
    await tester.tap(find.byTooltip('Next day'));
    await _waitUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(FbDateHeader),
            matching: find.text('Yesterday'),
          )
          .evaluate()
          .isNotEmpty,
      'the header to say Yesterday again',
    );
    await _pumpFor(tester, const Duration(milliseconds: 600));
    await expectStored('yesterday again', yesterday);
    expect(await stored(yesterday), hasLength(2));
    await tester.tap(find.byTooltip('Next day'));
    await _waitUntil(
      tester,
      () => find
          .descendant(
            of: find.byType(FbDateHeader),
            matching: find.text('Today'),
          )
          .evaluate()
          .isNotEmpty,
      'the header to say Today',
    );
    await _pumpFor(tester, const Duration(milliseconds: 600));
    await expectStored('today', today);
    expect(await stored(today), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 4)));

  // The full diary journey of A08b (D19): on yesterday add pita and a second
  // food, edit the pita to 2 loaves, move the second food to Dinner with the
  // Meal chip, delete it, undo, copy Breakfast to the next day (today).
  // Header and meal totals are checked against the stored diary after every
  // step. The second food is the banana of part a: the same food the A08a
  // device test already adds through the real pack.
  patrolTest('OF-01 DY-021 DY-022 DY-023 UX-030 offline diary journey', (
    $,
  ) async {
    final container = await _boot($, 'it-journey');
    final tester = $.tester;
    final diary = _Diary(tester, container);
    final stored = diary.stored;
    final expectStored = diary.expectStored;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final yesterday = today.plusDays(-1);

    await _goToDay(tester, 'Previous day', 'Yesterday');
    await expectStored('empty yesterday', yesterday);
    expect(await stored(yesterday), isEmpty);

    // Add pita (Breakfast) and a banana (Lunch), each through the meal's "+".
    Future<void> add(
      String meal,
      String query,
      String foodId,
      String unitId,
      String name,
      int count,
    ) async {
      await _tapIn(
        tester,
        find.descendant(
          of: dayPage(yesterday),
          matching: find.byTooltip('Add food to $meal'),
        ),
        yesterday,
      );
      await _addFood(
        tester,
        query: query,
        foodId: foodId,
        unitId: unitId,
        digit: '1',
        addedName: name,
      );
      await _waitUntilAsync(
        tester,
        () async => (await stored(yesterday)).length == count,
        'the $query in the diary',
      );
    }

    await add('Breakfast', 'pita', _pita, 'loaf', 'Pita bread, white', 1);
    await expectStored('pita added', yesterday);
    await add('Lunch', 'banana', _banana, 'piece', 'Banana, raw', 2);
    await expectStored('banana added', yesterday);
    final pita = (await stored(yesterday))
        .singleWhere((e) => e.food.ref.id == _pita);
    final banana = (await stored(yesterday))
        .singleWhere((e) => e.food.ref.id == _banana);
    final oneLoaf = pita.amount.amount;

    // Edit the pita to 2 loaves: the Amount chip, the pad's 2, Save.
    final pitaPanel = await _openDetails(
      tester,
      yesterday,
      'Breakfast',
      pita.id,
    );
    await _tapIn(
      tester,
      find.descendant(
        of: pitaPanel,
        matching: find.byWidgetPredicate(
          (w) => w is FbChoiceChip && w.label == 'Amount',
        ),
      ),
      yesterday,
    );
    await _waitUntil(
      tester,
      () => find.byType(EntryAmountSheet).evaluate().isNotEmpty,
      'the amount sheet',
    );
    final two = find.descendant(
      of: find.byType(FbNumberPad),
      matching: find.text('2'),
    );
    await tester.ensureVisible(two);
    await tester.tap(two);
    await tester.pump();
    // On a phone-height screen the open pad covers Save: close it with Done,
    // as a user would, before saving.
    await tester.tap(
      find.descendant(
        of: find.byType(FbNumberPad),
        matching: find.text('Done'),
      ),
    );
    await _pumpFor(tester, const Duration(milliseconds: 400));
    final save = find.widgetWithText(FbButton, 'Save');
    await _waitUntil(
      tester,
      () => tester.widget<FbButton>(save).onPressed != null,
      'Save to be enabled',
    );
    await _tapExactly(tester, save, 'Save');
    await _waitUntil(
      tester,
      // The unit's label comes from the real pack (it may differ from the
      // host fixture's "loaves"), so match the message by its prefix.
      () => find
          .textContaining('Changed Pita bread, white to 2 ')
          .evaluate()
          .isNotEmpty,
      'the amount confirmation',
    );
    final edited = (await stored(yesterday))
        .singleWhere((e) => e.id == pita.id);
    expect(edited.amount.input.amount, 2);
    expect(edited.amount.input.unitCode, 'loaf');
    expect(edited.amount.amount, closeTo(oneLoaf * 2, 0.01));
    await expectStored('pita edited', yesterday);

    // Move the banana to Dinner with the Meal chip.
    final bananaPanel = await _openDetails(
      tester,
      yesterday,
      'Lunch',
      banana.id,
    );
    await _tapIn(
      tester,
      find.descendant(
        of: bananaPanel,
        matching: find.byWidgetPredicate(
          (w) => w is FbChoiceChip && w.label == 'Meal',
        ),
      ),
      yesterday,
    );
    await _waitUntil(
      tester,
      () => find.byType(MoveEntrySheet).evaluate().isNotEmpty,
      'the move sheet',
    );
    final dinner = find.descendant(
      of: find.byType(MoveEntrySheet),
      matching: find.widgetWithText(FbListRow, 'Dinner'),
    );
    await tester.ensureVisible(dinner);
    await _pumpFor(tester, const Duration(milliseconds: 400));
    await tester.tap(dinner);
    await _waitUntil(
      tester,
      () => find.text('Moved Banana, raw to Dinner').evaluate().isNotEmpty,
      'the move confirmation',
    );
    expect(
      (await stored(yesterday)).singleWhere((e) => e.id == banana.id).slotId,
      DefaultSlots.dinnerId,
    );
    await expectStored('banana moved', yesterday);

    // Delete it with the details' Delete button, then Undo.
    final movedPanel = await _openDetails(
      tester,
      yesterday,
      'Dinner',
      banana.id,
    );
    await _tapIn(
      tester,
      find.descendant(
        of: movedPanel,
        matching: find.widgetWithText(FbButton, 'Delete'),
      ),
      yesterday,
    );
    await _waitUntil(
      tester,
      () => find.text('Deleted Banana, raw').evaluate().isNotEmpty,
      'the delete confirmation',
    );
    expect((await stored(yesterday)).map((e) => e.id), [pita.id]);
    await expectStored('banana deleted', yesterday);
    await tester.tap(find.text('Undo'));
    await _waitUntilAsync(
      tester,
      () async => (await stored(yesterday)).any((e) => e.id == banana.id),
      'Undo to restore the banana',
    );
    expect(
      (await stored(yesterday)).singleWhere((e) => e.id == banana.id).slotId,
      DefaultSlots.dinnerId,
    );
    await expectStored('undo', yesterday);

    // Copy Breakfast to the next day: the sheet opens on today.
    await _tapIn(
      tester,
      find.descendant(
        of: dayPage(yesterday),
        matching: find.byTooltip('More for Breakfast'),
      ),
      yesterday,
    );
    await _waitUntil(
      tester,
      () => find.text('Copy to…').evaluate().isNotEmpty,
      'the meal menu',
    );
    await tester.tap(find.text('Copy to…'));
    await _waitUntil(
      tester,
      () => find.byType(CopyMealSheet).evaluate().isNotEmpty,
      'the copy sheet',
    );
    final copy = find.descendant(
      of: find.byType(CopyMealSheet),
      matching: find.widgetWithText(FbButton, 'Copy'),
    );
    await tester.ensureVisible(copy);
    await _waitUntil(
      tester,
      () => tester.widget<FbButton>(copy).onPressed != null,
      'Copy to be enabled',
    );
    await tester.tap(copy);
    await _waitUntil(
      tester,
      () => find.text('Copied 1 item to Today').evaluate().isNotEmpty,
      'the copy confirmation',
    );
    await expectStored('breakfast copied, yesterday unchanged', yesterday);
    expect(await stored(yesterday), hasLength(2));

    // Today's breakfast holds 2 loaves of pita.
    final copied = await stored(today);
    expect(copied, hasLength(1));
    expect(copied.single.food.ref.id, _pita);
    expect(copied.single.slotId, DefaultSlots.breakfastId);
    expect(copied.single.amount.input.amount, 2);
    expect(copied.single.amount.input.unitCode, 'loaf');
    await _goToDay(tester, 'Next day', 'Today');
    await expectStored('today', today);
  }, timeout: const Timeout(Duration(minutes: 4)));
}

/// Drags [row] by [fraction] of its width (positive toward the end edge in
/// LTR) and lets the swipe finish.
Future<void> _swipe(WidgetTester tester, Finder row, double fraction) async {
  final width = tester.getSize(row).width;
  expect(
    row.hitTestable(),
    findsOneWidget,
    reason: 'swipe row must be visible',
  );
  final rect = tester.getRect(row);
  await tester.dragFrom(
    Offset(
      fraction > 0 ? rect.left + width * .1 : rect.right - width * .1,
      rect.center.dy,
    ),
    Offset(width * fraction, 0),
  );
  await _pumpFor(tester, const Duration(milliseconds: 600));
}
