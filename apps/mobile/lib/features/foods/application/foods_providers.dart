import 'dart:async';
import 'dart:developer' as developer;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/application/food_choice.dart';
import 'package:fb_mobile/features/foods/application/food_search_service.dart';
import 'package:fb_mobile/features/foods/application/log_food.dart';
import 'package:fb_mobile/features/foods/application/replace_entry_food.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'foods_providers.g.dart';

/// Offline read port over the attached pack.
@riverpod
FoodCatalogRepository foodCatalogRepository(Ref ref) =>
    FoodCatalogRepository(ref.watch(offlineCatalogProvider));

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
  ref.onDispose(() {
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
  return await FoodChoiceLoader(
    ref.watch(foodCatalogRepositoryProvider),
    () => service.history,
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

/// Active normal meal slots for the amount sheet.
@riverpod
Stream<List<MealSlot>> foodSlots(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchSlots();

/// Replace-mode command with the same applier and undo history.
@riverpod
ReplaceEntryFood replaceEntryFood(Ref ref) => ReplaceEntryFood(
  apply: ref.watch(changeSetApplierProvider).apply,
  undoStack: ref.watch(undoStackProvider),
);
