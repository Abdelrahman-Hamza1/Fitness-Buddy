import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';
import 'support/today_test_support.dart';

const _name = 'Pre workout';
const _banana = 'usda:banana_raw';

Finder _button(String label) => find.widgetWithText(FbButton, label);
Finder _meal(String label) => find.widgetWithText(FbListRow, label);

Future<void> _tab(WidgetTester tester, String label) => tapExactly(
  tester,
  find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  'the $label tab',
);

Future<void> _noSnackbar(WidgetTester tester) => waitUntil(
  tester,
  () => find.byType(SnackBar).evaluate().isEmpty,
  'the previous undo snackbar to close',
  timeout: const Duration(seconds: 20),
);

Future<void> _openMeals(WidgetTester tester) async {
  await _tab(tester, 'Me');
  final row = _meal('Meal times');
  await waitUntil(tester, () => row.evaluate().isNotEmpty, 'Meal times row');
  await tapExactly(tester, row, 'Meal times');
  await waitUntil(
    tester,
    () => _meal('Breakfast').evaluate().isNotEmpty,
    'the meals to load',
  );
}

Future<void> _today(WidgetTester tester, LocalDate date) async {
  await tapExactly(tester, find.byTooltip('Back'), 'Back to Me');
  await _tab(tester, 'Today');
  await waitUntil(tester, () => showsLoadedDay(tester, date), 'Today to load');
}

Future<void> _expectFood(
  WidgetTester tester,
  LocalDate date,
  String meal,
  String entryId,
) async {
  final header = find.descendant(
    of: dayPage(date),
    matching: find.widgetWithText(FbDisclosureRow, meal),
  );
  await revealDayWidget(tester, header, date);
  if (!tester.widget<FbDisclosureRow>(header).expanded) {
    await tapExactly(tester, header, 'the $meal header');
    await waitUntil(
      tester,
      () => tester.widget<FbDisclosureRow>(header).expanded,
      'the $meal section to expand',
    );
  }
  final tile = find.descendant(
    of: dayPage(date),
    matching: find.byKey(ValueKey<String>('entry:$entryId')),
  );
  await revealDayWidget(tester, tile, date, interactive: false);
  expect(
    find.descendant(of: tile, matching: find.text('Banana, raw')),
    findsOneWidget,
    reason: 'the logged food is visible under $meal',
  );
}

/// DY-010 DY-011 UX-030: real router, single writer and isolated device DB.
/// No meal is chosen from the input bar or food sheet: the new window wins.
void main() {
  patrolTest('A10 meal slots journey add window remove', ($) async {
    final tester = $.tester;
    final container = await bootApp(
      $,
      'it-meal-slots',
      rootName: 'fb_slots_it',
    );
    final repo = container.read(diaryRepositoryProvider);
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    // Attachment can precede completion of the background pack install.
    await waitUntilAsync(
      tester,
      () async =>
          (await container.read(foodCatalogRepositoryProvider).foodsByIds([
            _banana,
          ]))[_banana]?.isNotEmpty ??
          false,
      'the banana in the installed pack',
    );

    await _openMeals(tester);
    await tapExactly(tester, _button('Add meal'), 'Add meal');
    await waitUntil(
      tester,
      () => find.byType(SlotEditSheet).evaluate().isNotEmpty,
      'the add meal sheet',
    );
    await tester.enterText(find.byType(TextField), _name);
    // Set times initializes a two-hour window from the current hour, modulo
    // 1440. At 23:xx it is 23:00-01:00; no 12/24-hour picker assumptions.
    await tapExactly(tester, find.byType(Switch), 'Set times');
    // Dismiss the keyboard through focus: on a device there is no fake text
    // input to hide (`testTextInput` is only registered in host tests).
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await tapExactly(tester, _button('Add'), 'Add');
    await waitUntil(
      tester,
      () =>
          find.byType(SlotEditSheet).evaluate().isEmpty &&
          _meal(_name).evaluate().isNotEmpty,
      'the new meal to appear',
    );
    final added = (await repo.watchSlotRecords().first.timeout(
      const Duration(seconds: 10),
    )).singleWhere((r) => r.slot.name == _name);
    final now = EntryTime.now(container.read(clockProvider)).localDateTime;
    expect(added.slot.window, isNotNull);
    expect(added.slot.window!.contains(now.minuteOfDay), isTrue);
    expect(
      (added.slot.window!.endMin - added.slot.window!.startMin) % 1440,
      120,
    );
    await _noSnackbar(tester);
    await _today(tester, today);

    await tapExactly(tester, find.byType(FbInputBar), 'the input bar');
    await waitUntil(
      tester,
      () => find.byType(FoodSearchScreen).evaluate().isNotEmpty,
      'food search',
    );
    await tester.enterText(find.byType(TextField), 'banana');
    final result = find.byWidgetPredicate(
      (w) => w is FoodResultRow && w.row.choice.ref.id == _banana,
    );
    await waitUntil(
      tester,
      () => result.evaluate().isNotEmpty,
      'banana result',
    );
    await tapExactly(tester, result.first, 'banana result');
    await waitUntil(
      tester,
      () => _button('Add').evaluate().isNotEmpty,
      'the food sheet to load',
    );
    final chip = find.byWidgetPredicate(
      (w) => w is FbChoiceChip && w.label == 'Meal' && w.value == _name,
    );
    expect(chip, findsOneWidget);
    await tapExactly(
      tester,
      _button('Add'),
      'Add food without choosing a meal',
    );
    await waitUntil(
      tester,
      () =>
          find.byType(FoodSearchScreen).evaluate().isEmpty &&
          find.byType(FoodSheet).evaluate().isEmpty,
      'the food search to close',
    );
    final entries = await repo
        .watchEntries(today, today)
        .first
        .timeout(const Duration(seconds: 10));
    final entry = entries.single;
    expect(entry.food.ref.id, _banana);
    expect(entry.slotId, added.slot.id);
    await _expectFood(tester, today, _name, entry.id);
    await _noSnackbar(tester);

    await _openMeals(tester);
    await tapExactly(tester, _meal(_name), 'the new meal');
    await waitUntil(
      tester,
      () => _button('Remove meal').evaluate().isNotEmpty,
      'the edit sheet',
    );
    await tapExactly(tester, _button('Remove meal'), 'Remove meal');
    await waitUntil(
      tester,
      () => find.byType(FbOptionList<String>).evaluate().isNotEmpty,
      'the removal destinations',
    );
    expect(
      tester
          .widget<FbOptionList<String>>(find.byType(FbOptionList<String>))
          .selected,
      DefaultSlots.snacksId,
    );
    await tapExactly(tester, _button('Remove and move'), 'Remove and move');
    await waitUntil(
      tester,
      () =>
          find.byType(SlotRemoveSheet).evaluate().isEmpty &&
          find.byType(SlotEditSheet).evaluate().isEmpty,
      'both sheets to close',
    );
    await _today(tester, today);
    await _expectFood(tester, today, 'Snacks', entry.id);
    final moved = await repo
        .watchEntries(today, today)
        .first
        .timeout(const Duration(seconds: 10));
    expect(moved.single.slotId, DefaultSlots.snacksId);
    await tapExactly(
      tester,
      find.descendant(of: find.byType(SnackBar), matching: find.text('Undo')),
      'Undo removal',
    );
    await waitUntilAsync(
      tester,
      () async =>
          (await repo.watchEntries(today, today).first).single.slotId ==
          added.slot.id,
      'Undo to restore the meal and its food',
    );
    await _expectFood(tester, today, _name, entry.id);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
