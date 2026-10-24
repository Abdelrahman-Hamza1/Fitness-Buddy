import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/saved_meal.dart';
import 'package:fb_domain/src/quick_add/food_key.dart';

/// One attributed occurrence, with the canonical selected entries (D12).
final class MealOccurrence {
  /// The earliest selected entry supplies the local occurrence time.
  new(this.meal, Iterable<DiaryEntry> entries)
    : entries = List.unmodifiable(entries);

  /// Matched saved meal.
  final SavedMeal meal;

  /// Selected entries in UTC-time/ID order.
  final List<DiaryEntry> entries;

  /// Earliest selected entry (not necessarily the window's start).
  DiaryEntry get first => entries.first;
}

/// Complete attribution; an entry belongs to at most one occurrence.
final class SavedMealAttribution {
  /// Immutable matching result.
  new(Iterable<MealOccurrence> meals, Iterable<DiaryEntry> rest)
    : mealOccurrences = List.unmodifiable(meals),
      unassignedEntries = List.unmodifiable(rest);

  /// Matched meal occurrences.
  final List<MealOccurrence> mealOccurrences;

  /// Entries left for individual food usage.
  final List<DiaryEntry> unassignedEntries;
}

/// Deterministic greedy multiset matching within each diary day and slot.
final class SavedMealMatcher {
  /// The window is injected from QuickAddWeights by the ranker.
  const new({this.windowMinutes = 90});

  /// Inclusive maximum UTC separation.
  final int windowMinutes;

  /// Larger meals consume entries first; repeated occurrences remain possible.
  SavedMealAttribution attribute(
    Iterable<DiaryEntry> entries,
    Iterable<SavedMeal> meals, {
    required String Function(String) nameKey,
  }) {
    final requirements = <String, Map<FoodKey, int>>{};
    final orderedMeals = meals.where((m) => m.items.isNotEmpty).toList();
    for (final meal in orderedMeals) {
      final counts = <FoodKey, int>{};
      for (final item in meal.items) {
        final key = FoodKey.of(item.food, nameKey: nameKey);
        counts[key] = (counts[key] ?? 0) + 1;
      }
      requirements[meal.id] = counts;
    }
    orderedMeals.sort((a, b) {
      final size = b.items.length.compareTo(a.items.length);
      if (size != 0) return size;
      final distinct = requirements[b.id]!.length.compareTo(
        requirements[a.id]!.length,
      );
      return distinct != 0 ? distinct : a.id.compareTo(b.id);
    });
    final groups = <(int, String), List<DiaryEntry>>{};
    for (final entry in entries) {
      (groups[(entry.localDate.epochDay, entry.slotId)] ??= []).add(entry);
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        final date = a.$1.compareTo(b.$1);
        return date != 0 ? date : a.$2.compareTo(b.$2);
      });
    final occurrences = <MealOccurrence>[];
    final rest = <DiaryEntry>[];
    for (final group in groupKeys) {
      final ordered = groups[group]!..sort(compareEntryTime);
      final keys = {
        for (final e in ordered) e.id: FoodKey.of(e.food, nameKey: nameKey),
      };
      final available = <FoodKey, int>{};
      for (final key in keys.values) {
        available[key] = (available[key] ?? 0) + 1;
      }
      final assigned = <String>{};
      for (final meal in orderedMeals) {
        final required = requirements[meal.id]!;
        bool canMatch() =>
            required.entries.every((r) => (available[r.key] ?? 0) >= r.value);
        if (!canMatch()) continue;
        for (var i = 0; i < ordered.length; i++) {
          final start = ordered[i];
          if (assigned.contains(start.id)) continue;
          final needed = Map.of(requirements[meal.id]!);
          final selected = <DiaryEntry>[];
          for (var j = i; j < ordered.length; j++) {
            final entry = ordered[j];
            if (entry.time.occurredAtUtc
                    .difference(start.time.occurredAtUtc)
                    .inMilliseconds >
                windowMinutes * 60000) {
              break;
            }
            if (assigned.contains(entry.id)) continue;
            final key = keys[entry.id]!;
            final count = needed[key] ?? 0;
            if (count == 0) continue;
            selected.add(entry);
            if (count == 1) {
              needed.remove(key);
            } else {
              needed[key] = count - 1;
            }
            if (needed.isEmpty) break;
          }
          if (needed.isEmpty) {
            assigned.addAll(selected.map((e) => e.id));
            for (final r in required.entries) {
              available[r.key] = available[r.key]! - r.value;
            }
            occurrences.add(MealOccurrence(meal, selected));
            if (!canMatch()) break;
          }
        }
      }
      rest.addAll(ordered.where((e) => !assigned.contains(e.id)));
    }
    return SavedMealAttribution(occurrences, rest);
  }
}

/// Canonical entry order shared by attribution and last-used selection.
int compareEntryTime(DiaryEntry a, DiaryEntry b) {
  final time = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
  return time != 0 ? time : a.id.compareTo(b.id);
}
