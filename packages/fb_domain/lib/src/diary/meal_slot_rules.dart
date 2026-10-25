import 'package:fb_domain/src/diary/meal_slot.dart';

/// Pure meal-slot editor rules (DY-010, A10 D9–D11).
abstract final class MealSlotRules {
  /// Maximum active normal meals.
  static const int maxActive = 8;

  /// Maximum normalized name length.
  static const int nameMax = 30;

  /// Collapse whitespace without changing the user's letters.
  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Whether a custom name can be stored.
  static bool validName(String name) =>
      name.isNotEmpty &&
      name.length <= nameMax &&
      !RegExp(r'[\p{Cc}\p{Cf}]', unicode: true).hasMatch(name);

  /// Minutes in a nonempty, possibly overnight window.
  static int windowMinutes(TimeWindow window) =>
      (window.endMin - window.startMin) % 1440;

  /// Insert timed meals before the first later start or windowless meal.
  static int insertIndex(List<MealSlot> active, TimeWindow? window) {
    if (window == null) return active.length;
    final index = active.indexWhere(
      (slot) => slot.window == null || slot.window!.startMin > window.startMin,
    );
    return index < 0 ? active.length : index;
  }

  /// Contiguous ordering for the supplied identities.
  static Map<String, int> renumber(Iterable<String> order) => {
    for (final (index, id) in order.indexed) id: index,
  };
}
