import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show TextField;

import '../../../../helpers/pump_app.dart';
import '../../../diary/support/diary_fixtures.dart' show fixtureId;
import 'search_screen_support.dart';

/// A stored personal food: [n] makes its ID, [name] its name.
PersonalFood aFood(
  int n, {
  String name = 'Labneh',
  String? ar,
  List<String> aliases = const [],
  String? brand,
  NutrientBasis basis = NutrientBasis.per100g,
  Nutrients? per100,
  List<PersonalFoodServing> servings = const [],
  PersonalFoodServing? entryServing,
  int version = 1,
}) => PersonalFood(
  id: fixtureId(n),
  version: version,
  draft: PersonalFoodDraft(
    names: FoodNames(name, ar: ar),
    aliases: aliases,
    brand: brand,
    basis: basis,
    per100:
        per100 ?? Nutrients(kcal: 180, protein: 6, carbs: 4, fat: 15, fiber: 0),
    servings: servings,
    entryServing: entryServing,
  ),
);

/// A phone-sized or tall window for the test.
void useWindow(WidgetTester tester, {double width = 412, double height = 915}) {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Lets the database, the undo stack and the animations finish. A screen
/// that is still loading from the database keeps a skeleton animating, so
/// real time must pass between the frames, not only before them.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle();
}

/// Stops the undo stack's expiry timer (it counts real time, the test's
/// timers count fake time) and runs out the snackbars, so the test ends with
/// no timer pending.
Future<void> finish(WidgetTester tester, ProviderContainer container) async {
  container.read(undoStackProvider).dispose();
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}

/// The whole app on an in-memory profile, with the search stubbed
/// ([search]) so no pack is needed. It runs on the real clock, like
/// `pumpApp`.
Future<ProviderContainer> pumpPersonal(
  WidgetTester tester, {
  FakeFoodSearch? search,
  AppRoute? at,
  List<PersonalFood> foods = const [],
  Size? window,
  List<Override> overrides = const [],
}) async {
  useWindow(tester, width: window?.width ?? 412, height: window?.height ?? 915);
  final container = await pumpApp(
    tester,
    overrides: [searchOverride(search ?? FakeFoodSearch()), ...overrides],
  );
  for (final food in foods) {
    await seed(tester, container, food);
  }
  if (at != null) {
    container.read(appRouterProvider).go(at);
    await settle(tester);
  }
  return container;
}

/// Creates [food] through the single writer.
Future<void> seed(
  WidgetTester tester,
  ProviderContainer container,
  PersonalFood food,
) async {
  final result = await applyOps(tester, container, [
    CreatePersonalFood(food.id, food.draft),
  ]);
  expect(result, isA<Applied>());
  await settle(tester);
}

/// Applies [ops] as one direct change set.
Future<ApplyResult> applyOps(
  WidgetTester tester,
  ProviderContainer container,
  List<ChangeOp> ops,
) async {
  // Read outside runAsync: building providers there never finishes.
  final applier = container.read(changeSetApplierProvider);
  return (await tester.runAsync(
    () => applier.apply(ChangeSet(ops, origin: Origin.direct)),
  ))!;
}

/// The profile database of the app under test.
AppDatabase dbOf(ProviderContainer container) =>
    container.read(appDatabaseProvider);

/// Every live personal food row.
Future<List<PersonalFoodRow>> liveFoods(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final db = dbOf(container);
  return (await tester.runAsync(
    () =>
        (db.select(db.personalFoods)..where((t) => t.deletedAt.isNull())).get(),
  ))!;
}

/// Every live personal food as the app reads it, by name.
Future<List<PersonalFood>> storedFoods(
  WidgetTester tester,
  ProviderContainer container,
) async => (await tester.runAsync(
  () => PersonalFoodRepository(dbOf(container)).watchAll().first,
))!;

/// Every live diary entry row.
Future<List<DiaryEntryRow>> liveEntries(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final db = dbOf(container);
  return (await tester.runAsync(
    () =>
        (db.select(db.diaryEntries)..where((t) => t.deletedAt.isNull())).get(),
  ))!;
}

/// A diary entry of [food] ([grams] g) logged now, for the history tests.
NewDiaryEntry entryOfPersonal(
  ProviderContainer container,
  PersonalFood food, {
  required int n,
  double grams = 100,
}) => NewDiaryEntry(
  id: fixtureId(500 + n),
  when: EntryWhen.at(EntryTime.now(container.read(clockProvider))),
  slotId: DefaultSlots.breakfastId,
  food: EntryFood(
    ref: FoodRef.personal(food.id),
    names: food.names,
    per100: food.per100,
    provenance: Provenance(source: FoodSource.yours),
  ),
  amount: EntryAmount(
    input: Quantity(grams, 'g'),
    amount: grams,
    basis: NutrientBasis.per100g,
  ),
);

/// Typed form fields by their label.
Finder fieldLabelled(String label) => find.widgetWithText(TextField, label);
