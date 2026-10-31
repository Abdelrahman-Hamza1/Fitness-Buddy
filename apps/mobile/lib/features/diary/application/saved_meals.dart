import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_meals.g.dart';

/// Live saved snapshots, including empty meals for the detail empty state.
@riverpod
Stream<List<SavedMeal>> savedMeals(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchSavedMeals();

/// Authoritative source at the observed version; null after deletion.
@riverpod
Stream<SavedMeal?> savedMeal(Ref ref, String id) =>
    ref.watch(diaryRepositoryProvider).watchSavedMeal(id);

/// Every live meal of both modes, for the detail screen's Meal chip (the
/// chosen day's mode picks among them, DY-012).
@riverpod
Stream<List<MealSlot>> savedMealSlots(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchAllSlots();
