import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';

import '../../diary/support/diary_fixtures.dart' show fixtureId;
import '../../today/presentation/support/today_support.dart';

/// A food chip as the model would build it, for screens that only render it.
QuickAddChip fakeFoodChip(
  int n,
  String name, {
  String slotId = DefaultSlots.lunchId,
}) {
  final entry = fakeEntry(n, date: testYesterday, name: name, slotId: slotId);
  return QuickAddChip(
    ranked: RankedChip(
      candidate: FoodCandidate(
        foodKey: FoodKey(FoodRefKind.catalog, 'food-$n'),
        latest: entry,
        latestInSlot: entry,
      ),
      score: 1,
      occurrences: 3,
      latestUse: LocalDateTime(testYesterday, hour: 12, minute: 30),
    ),
    slotId: slotId,
  );
}

/// A saved-meal chip as the model would build it.
QuickAddChip fakeMealChip(
  int n,
  String name, {
  String slotId = DefaultSlots.lunchId,
}) {
  final entry = fakeEntry(n, date: testYesterday, name: 'Item $n');
  final meal = SavedMeal(
    id: fixtureId(500 + n),
    version: 1,
    name: name,
    items: [
      SavedMealItem(
        id: fixtureId(600 + n),
        version: 1,
        sortOrder: 0,
        food: entry.food,
        amount: entry.amount,
        snapshot: entry.snapshot,
      ),
    ],
  );
  return QuickAddChip(
    ranked: RankedChip(
      candidate: SavedMealCandidate(meal),
      score: 1,
      occurrences: 3,
      latestUse: LocalDateTime(testYesterday, hour: 12, minute: 30),
    ),
    slotId: slotId,
  );
}
