import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../today/presentation/support/today_support.dart';
import '../support/diary_fixtures.dart' show fixtureId;
import '../support/diary_harness.dart';

/// Saves the entries [ids] of [rig] (already logged) as the saved meal
/// [mealN], named [name].
Future<void> saveMeal(
  WidgetTester tester,
  TodayRig rig,
  int mealN,
  String name,
  List<int> ids,
) async {
  await tester.runAsync(
    () => rig.diary.apply([
      SaveMeal(
        savedMealId: fixtureId(mealN),
        name: name,
        source: MealSource.entries([for (final n in ids) fixtureId(n)]),
        expected: SourceVersions(
          entries: [for (final n in ids) VersionedId(fixtureId(n), 1)],
        ),
      ),
    ]),
  );
}

/// Today's date entries 2 ("database") and 3 ("yours"), saved as "Usual
/// lunch" (meal 90), plus entry 4 saved as "Breakfast set" (meal 91).
Future<void> seedMeals(WidgetTester tester, TodayRig rig) async {
  await tester.runAsync(
    () => rig.diary.apply([
      LogEntries([
        newEntry(2, slotId: DefaultSlots.lunchId),
        newEntry(
          3,
          slotId: DefaultSlots.lunchId,
          provenance: Provenance(source: FoodSource.yours),
        ),
        newEntry(4, slotId: DefaultSlots.breakfastId),
      ]),
    ]),
  );
  await saveMeal(tester, rig, 90, 'Usual lunch', [2, 3]);
  await saveMeal(tester, rig, 91, 'Breakfast set', [4]);
}

/// The saved meal [n] as a screen test shows it, without a database.
SavedMeal aMeal(
  int n,
  String name, {
  List<String> items = const ['Pita bread, white', 'Labaneh'],
}) => SavedMeal(
  id: fixtureId(n),
  version: 1,
  name: name,
  items: [
    for (final (i, item) in items.indexed)
      SavedMealItem(
        id: fixtureId(700 + n * 10 + i),
        version: 1,
        sortOrder: i,
        food: fakeEntry(
          i + 1,
          date: testToday,
          name: item,
          source: i == 1 ? FoodSource.yours : FoodSource.database,
        ).food,
        amount: fakeEntry(i + 1, date: testToday, name: item).amount,
        snapshot: fakeEntry(
          i + 1,
          date: testToday,
          name: item,
          kcal: 165.0 + i * 90,
        ).snapshot,
      ),
  ],
);

/// Providers of the saved meals screens on [meals], no database.
List<Override> fakeMeals(List<SavedMeal> meals) => [
  ...fakeToday(),
  savedMealsProvider.overrideWith((ref) => Stream.value(meals)),
  savedMealProvider.overrideWith(
    (ref, id) => Stream.value(meals.where((m) => m.id == id).firstOrNull),
  ),
  savedMealSlotsProvider.overrideWith((ref) => Stream.value(DefaultSlots.all)),
];
