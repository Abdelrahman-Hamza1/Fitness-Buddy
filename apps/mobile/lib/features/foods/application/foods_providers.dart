import 'dart:async';
import 'dart:developer' as developer;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_mobile/core/catalog/online_food_search.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/application/barcode_providers.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/food_search_service.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';
import 'package:fb_mobile/features/foods/application/personal_food_actions.dart';
import 'package:fb_mobile/features/foods/application/replace_entry_food.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/data/personal_food_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export '../data/personal_food_repository.dart'
    show personalFoodRepositoryProvider;

part 'foods_providers.g.dart';

/// Offline read port over the attached pack.
@riverpod
FoodCatalogRepository foodCatalogRepository(Ref ref) =>
    FoodCatalogRepository(ref.watch(offlineCatalogProvider));

/// The other names a catalog food (and its dish) is known by: the pack's
/// aliases and spellings, normalized (D-091, the food page's "Also
/// called"). Empty without a pack.
@riverpod
Future<List<String>> catalogAliases(Ref ref, String foodId, String? dishId) =>
    ref
        .watch(foodCatalogRepositoryProvider)
        .namesForTargets([foodId, ?dishId])
        .then(
          (names) => {
            for (final n in names)
              if (!n.isDisplay) n.key,
          }.toList(),
        );

/// Search session with reactive history and background fuzzy builds.
@riverpod
FoodSearchService foodSearchService(Ref ref) {
  final service = FoodSearchService(
    ref.watch(foodCatalogRepositoryProvider),
    onIndexCounts: (words, keys, {required distanceTwo}) {
      if (!distanceTwo) {
        developer.log(
          'fuzzy distance2 disabled: words=$words keys=$keys',
          name: 'catalog',
        );
      }
    },
  );
  final sub = ref
      .watch(diaryRepositoryProvider)
      .watchFoodHistory()
      .listen((history) => unawaited(service.updateHistory(history)));
  final personalSub = ref
      .watch(personalFoodRepositoryProvider)
      .watchAll()
      .listen((foods) => unawaited(service.updatePersonalFoods(foods)));
  ref.onDispose(() {
    unawaited(personalSub.cancel());
    unawaited(sub.cancel());
    service.dispose();
  });
  return service;
}

/// Loads the selected food using fresh history and current metadata.
@riverpod
Future<FoodChoice?> foodChoice(Ref ref, FoodChoiceRef choice) async {
  final service = ref.watch(foodSearchServiceProvider);
  await service.updateHistory(
    await ref.read(diaryRepositoryProvider).watchFoodHistory().first,
  );
  await service.updatePersonalFoods(
    await ref.read(personalFoodRepositoryProvider).watchAll().first,
  );
  return await FoodChoiceLoader(
    ref.watch(foodCatalogRepositoryProvider),
    () => service.history,
    personalFoods: () => service.personalFoods,
    onlineFood: (id) => ref.read(onlineFoodCacheProvider)[id],
    scannedFood: (id) => ref.read(scannedFoodRegistryProvider)[id],
  ).load(choice);
}

/// Structured command used to submit through the applier.
@riverpod
LogFood logFood(Ref ref) => LogFood(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
  clock: ref.watch(clockProvider),
  ids: ref.watch(idGeneratorProvider),
);

/// The meal slots the amount sheet offers on [date] (DY-012, A41a D6): the
/// day's mode (Ramadan on a fasting day) with its windows, removed ones
/// included (a sheet open on one drops it).
/// Every slot in the list is of the day's mode ([slotModeOf]).
@riverpod
Stream<List<MealSlot>> foodSlots(Ref ref, LocalDate date) async* {
  final day = await ref.watch(daySlotsProvider(date).future);
  yield [
    for (final s in day.slots)
      if (s.mode == day.mode) s,
  ];
}

/// The mode of a [foodSlots] list (one mode only): Ramadan when it holds
/// Ramadan slots.
SlotMode slotModeOf(Iterable<MealSlot> slots) =>
    slots.firstOrNull?.mode ?? SlotMode.normal;

/// Replace-mode command with the same applier and undo history.
@riverpod
ReplaceEntryFood replaceEntryFood(Ref ref) => ReplaceEntryFood(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
);

/// Live search/form definitions.
@riverpod
Stream<List<PersonalFood>> personalFoods(Ref ref) =>
    ref.watch(personalFoodRepositoryProvider).watchAll();

/// How many live personal foods can't be read (#100).
@riverpod
Stream<int> unreadablePersonalFoodCount(Ref ref) =>
    ref.watch(personalFoodRepositoryProvider).watchUnreadableCount();

/// Row observed by a disposable edit form.
@riverpod
Stream<PersonalFood?> personalFood(Ref ref, String id) =>
    ref.watch(personalFoodRepositoryProvider).watchFood(id);

/// Commands retain pending keys across route changes.
@Riverpod(keepAlive: true)
PersonalFoodActions personalFoodActions(Ref ref) => PersonalFoodActions(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
  ids: ref.watch(idGeneratorProvider),
);
