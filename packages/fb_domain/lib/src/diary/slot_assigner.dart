import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// Picks the slot a new entry goes into from its local time (DY-011,
/// A06 D7). Pure and deterministic. Used only when the op leaves the slot
/// empty: an explicit slot always wins.
///
/// Among the active slots of the mode:
/// 1. the slots whose window contains the time: lowest `sortOrder`, then
///    lowest ID;
/// 2. else the slots with no window (the default Snacks): the same order;
/// 3. else the slot whose window started most recently before the time,
///    going back across midnight;
/// 4. else (no active slot) `null`.
final class SlotAssigner {
  /// The assigner. It has no state.
  const new();

  /// The ID of the slot for the local minute of day [minuteOfDay] (0–1439)
  /// among [slots] in [mode], or `null` when none is active.
  String? assign(int minuteOfDay, Iterable<MealSlot> slots, SlotMode mode) {
    if (minuteOfDay < 0 || minuteOfDay >= LocalTime.minutesPerDay) {
      throw RangeError.range(
        minuteOfDay,
        0,
        LocalTime.minutesPerDay - 1,
        'minuteOfDay',
      );
    }
    final candidates = [
      for (final slot in slots)
        if (slot.active && slot.mode == mode) slot,
    ];
    final containing = [
      for (final slot in candidates)
        if (slot.window?.contains(minuteOfDay) ?? false) slot,
    ];
    if (containing.isNotEmpty) return _first(containing).id;
    final windowless = [
      for (final slot in candidates)
        if (slot.window == null) slot,
    ];
    if (windowless.isNotEmpty) return _first(windowless).id;
    if (candidates.isEmpty) return null;
    // Every candidate has a window that doesn't contain the time.
    int sinceStart(MealSlot slot) =>
        (minuteOfDay - slot.window!.startMin) % LocalTime.minutesPerDay;
    candidates.sort((a, b) {
      final bySince = sinceStart(a).compareTo(sinceStart(b));
      return bySince != 0 ? bySince : _bySortOrderThenId(a, b);
    });
    return candidates.first.id;
  }

  static MealSlot _first(List<MealSlot> slots) =>
      (slots..sort(_bySortOrderThenId)).first;

  static int _bySortOrderThenId(MealSlot a, MealSlot b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
  }
}
