import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';

/// A name no pack food or fuzzy match comes close to, in plain ASCII.
const _name = 'Zqxjkvw';

/// Types [text] into the form field labelled [label].
Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextField, label), text);
  await tester.pump(const Duration(milliseconds: 100));
}

/// Opens the add-food search from Today (input bar → Buddy's sheet →
/// search), once the previous action's Undo snackbar (which can cover the
/// bar on a small phone) is gone.
Future<void> _openSearch(WidgetTester tester) async {
  await waitUntil(
    tester,
    () => find.byType(SnackBar).evaluate().isEmpty,
    'the undo snackbar to go',
    timeout: const Duration(seconds: 15),
  );
  await openSearchFromToday(tester);
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// OF-01 FD-070 FD-021 on the device: no API is reachable (as in `app_test`),
/// the profile is a throw-away database. A search with no match offers a food
/// of your own; its form saves it, the food sheet opens for it, Add logs it
/// with the Y badge, and the next search finds it first.
void main() {
  patrolTest('OF-01 FD-070 FD-021 create a personal food offline and log it '
      'from search', ($) async {
    final container = await bootApp(
      $,
      'it-personal',
      rootName: 'fb_personal_it',
    );
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;

    // No match: the search offers to create the food.
    await _openSearch(tester);
    await tester.enterText(find.byType(TextField), _name);
    final create = find.text('Create "$_name" as your own food');
    await waitUntil(
      tester,
      () => create.evaluate().isNotEmpty,
      'the create offer for "$_name"',
    );
    await tapExactly(tester, create.last, 'Create as your own food');

    // The form opens with the name filled in. Fill the label's numbers.
    await waitUntil(
      tester,
      () => find.byType(PersonalFoodFormScreen).evaluate().isNotEmpty,
      'the personal food form',
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Name'))
          .controller!
          .text,
      _name,
    );
    await _type(tester, 'Calories', '180');
    await _type(tester, 'Protein', '6');
    await _type(tester, 'Carbs', '4');
    await _type(tester, 'Fat', '15');
    await tapExactly(tester, find.widgetWithText(FbButton, 'Save'), 'Save');

    // The food sheet opens for the new food, with the Y badge.
    await waitUntil(
      tester,
      () =>
          find.byType(PersonalFoodFormScreen).evaluate().isEmpty &&
          find.byType(FoodSheet).evaluate().isNotEmpty &&
          find.widgetWithText(FbButton, 'Add').evaluate().isNotEmpty,
      'the food sheet for the new food',
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    final badge = find.descendant(
      of: find.byType(FoodSheet),
      matching: find.byType(FbSourceBadge),
    );
    expect(
      tester.widget<FbSourceBadge>(badge.first).source,
      FbSource.yours,
      reason: 'a food of your own shows the Y badge',
    );
    await tapExactly(tester, find.widgetWithText(FbButton, 'Add'), 'Add');
    await waitUntil(
      tester,
      () =>
          find.byType(FoodSearchScreen).evaluate().isEmpty &&
          find.byType(FoodSheet).evaluate().isEmpty &&
          find.textContaining('Added $_name to ').evaluate().isNotEmpty,
      'the search to close and the undo snackbar to show',
    );
    expect(find.byType(TodayScreen), findsOneWidget);

    // Stored: one entry of the personal food, with the Y source.
    final entries = await container
        .read(diaryRepositoryProvider)
        .watchEntries(today.plusDays(-1), today.plusDays(1))
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TestFailure('Timed out reading the diary'),
        );
    final logged = entries.where((e) => e.food.names.en == _name).toList();
    expect(logged, hasLength(1));
    expect(logged.single.food.ref.kind, FoodRefKind.personal);
    expect(logged.single.food.provenance.source, FoodSource.yours);

    // The next search finds the food first, with the Y badge.
    await _openSearch(tester);
    await tester.enterText(find.byType(TextField), 'Zqxj');
    final first = find.byType(FoodResultRow);
    await waitUntil(
      tester,
      () =>
          first.evaluate().isNotEmpty &&
          tester.widget<FoodResultRow>(first.first).row.nameEn == _name,
      'the new food as the first result',
    );
    final row = tester.widget<FoodResultRow>(first.first).row;
    expect(row.choice.ref.kind, FoodRefKind.personal);
    expect(row.source, FoodSource.yours);
    expect(
      tester
          .widget<FbSourceBadge>(
            find.descendant(
              of: first.first,
              matching: find.byType(FbSourceBadge),
            ),
          )
          .source,
      FbSource.yours,
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}
