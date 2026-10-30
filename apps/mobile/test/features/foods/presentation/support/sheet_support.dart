import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/db/support/db_support.dart';
import '../../../../helpers/unit_feed.dart';
import '../../../diary/support/diary_harness.dart';

/// A catalog food as the pack would give it.
CatalogFood foodOf(
  String id,
  String nameEn, {
  String? nameAr,
  FoodState state = FoodState.asSold,
  NutrientBasis basis = NutrientBasis.per100g,
  double kcal = 100,
  double protein = 5,
  double carbs = 10,
  double fat = 2,
  double fiber = 1,
  Map<NutrientKey, double> extras = const {},
  List<ServingUnit> servings = const [],
  String? yieldGroup,
  CatalogSanity sanity = CatalogSanity.ok,
}) => CatalogFood(
  id: id,
  kind: CatalogFoodKind.basic,
  nameEn: nameEn,
  nameAr: nameAr,
  dishId: null,
  state: state,
  basis: basis,
  nutrients: Nutrients(
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    fiber: fiber,
    extras: extras,
  ),
  servingUnits: servings,
  densityGramsPerMl: null,
  yieldGroup: yieldGroup,
  badge: CatalogBadge.database,
  verified: true,
  isDraft: false,
  packVersion: 6,
  sanity: sanity,
);

/// Pita bread: a food with a local portion, the loaf.
final CatalogFood pita = foodOf(
  'usda:pita_white',
  'Pita bread, white',
  nameAr: 'خبز عربي',
  kcal: 275,
  protein: 9.1,
  carbs: 55.7,
  fat: 1.2,
  fiber: 2.2,
  extras: {NutrientKey.sugar: 2.7, NutrientKey.sodium: 536},
  servings: [ServingUnit.grams('loaf', 60)],
);

/// Cooked rice and dry rice share the `rice` yield group.
final CatalogFood riceCooked = foodOf(
  'usda:rice_white_long_grain_cooked',
  'Rice, white, cooked',
  nameAr: 'رز مطبوخ',
  state: FoodState.cooked,
  kcal: 130,
  protein: 2.7,
  carbs: 28.2,
  fat: 0.3,
  fiber: 0.4,
  servings: [ServingUnit.grams('cup', 158)],
  yieldGroup: 'rice',
);

final CatalogFood riceDry = foodOf(
  'usda:rice_white_long_grain_raw',
  'Rice, white, raw',
  nameAr: 'رز أبيض',
  state: FoodState.dry,
  kcal: 365,
  protein: 7.1,
  carbs: 80,
  fat: 0.7,
  fiber: 1.3,
  servings: [ServingUnit.grams('cup', 185)],
  yieldGroup: 'rice',
);

/// Minced beef 90/10 has a yield factor but no compatible cooked food.
final CatalogFood beefRaw = foodOf(
  'usda:beef_ground_90_raw',
  'Beef, ground, 90% lean, raw',
  state: FoodState.raw,
  kcal: 176,
  protein: 20,
  carbs: 0,
  fat: 10,
  fiber: 0,
  yieldGroup: 'beef',
);

final YieldConverter yields = YieldConverter([
  YieldFactor(
    group: 'rice',
    from: FoodState.dry,
    to: FoodState.cooked,
    factor: 2.8,
  ),
  YieldFactor(
    group: 'beef',
    from: FoodState.raw,
    to: FoodState.cooked,
    factor: 0.67,
  ),
]);

/// A last use of [food]: [amount] of [unit] ([grams] canonical).
FoodHistoryItem usedBefore(
  CatalogFood food,
  double amount,
  String unit,
  double grams,
) => FoodHistoryItem(
  food: catalogChoice(food).food,
  amount: EntryAmount(
    input: Quantity(amount, unit),
    amount: grams,
    basis: NutrientBasis.per100g,
  ),
  uses: 3,
  lastUsedHlc: Hlc.parse(hlcAt(1)),
);

/// The row the search screen would show for [choice].
FoodSearchRow rowFor(FoodChoice choice) =>
    FoodSearchRow(choice: choice, tier: SourceTier.database);

/// A navigator that pops the app's one navigator, like the router's `pop`.
final class PopNavigator implements AppNavigator {
  new(this.key);

  final GlobalKey<NavigatorState> key;

  /// How many times the sheet's owner asked to close the search screen.
  int pops = 0;

  @override
  void pop() {
    pops++;
    key.currentState!.pop();
  }

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => throw UnimplementedError();
}

/// The providers a food sheet needs to be shown (no writes): [choice] is
/// what the row loads, the slots are the defaults, and it is noon.
List<Override> displayOverrides(FoodChoice choice) => [
  foodChoiceProvider(rowFor(choice).choiceRef)
      .overrideWith((ref) async => choice),
  unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
  foodSlotsProvider.overrideWith((ref) => Stream.value(DefaultSlots.all)),
  clockProvider.overrideWithValue(ManualClock(DateTime.utc(2026, 10, 17, 12))),
];

/// The providers a food sheet needs: [choice] is what the row loads, the
/// slots are the defaults, and Add writes to [diary] through the real
/// applier with a real undo stack.
final class SheetRig {
  new(this.choice, {this.apply}) {
    stack = UndoStack(revert: diary.applier.revert, clock: diary.clock);
    addTearDown(stack.dispose);
    navigator = PopNavigator(navigatorKey);
  }

  final FoodChoice choice;

  /// Replaces the applier (to make Add fail).
  final Future<ApplyResult> Function(ChangeSet)? apply;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final DiaryHarness diary = DiaryHarness();

  /// The unit system; switch it with `units.set`.
  final UnitFeed units = UnitFeed();
  late final UndoStack stack;
  late final PopNavigator navigator;

  /// Replaces [navigator] in [overrides] (a test that records pushes).
  AppNavigator? appNavigator;

  FoodSearchRow get row => rowFor(choice);

  List<Override> get overrides => [
    foodChoiceProvider(row.choiceRef).overrideWith((ref) async => choice),
    units.override,
    foodSlotsProvider.overrideWith((ref) => Stream.value(DefaultSlots.all)),
    clockProvider.overrideWithValue(diary.clock),
    undoStackProvider.overrideWithValue(stack),
    appNavigatorProvider.overrideWithValue(appNavigator ?? navigator),
    diaryRepositoryProvider.overrideWithValue(DiaryRepository(diary.db)),
    replaceEntryFoodProvider.overrideWith(
      (ref) => ReplaceEntryFood(
        apply: apply ?? diary.applier.apply,
        undoStack: stack,
      ),
    ),
    logFoodProvider.overrideWith(
      (ref) => LogFood(
        apply: apply ?? diary.applier.apply,
        undoStack: stack,
        clock: diary.clock,
        ids: diary.ids,
      ),
    ),
  ];
}
