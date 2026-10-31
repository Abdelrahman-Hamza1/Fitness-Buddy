import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_slots.g.dart';

/// The meal slots a day uses (DY-012, A41a D6): its mode (Ramadan on a
/// fasting day) and every live slot with that day's effective windows
/// (Suhoor/Iftar from the prayer times). Content-free [toString].
final class DaySlots {
  /// The slots of a day.
  const new({
    required this.mode,
    required this.slots,
    this.ramadan,
    this.notFasting = false,
  });

  /// The normal day, with [slots] as stored.
  new normal(List<MealSlot> slots) : this(mode: SlotMode.normal, slots: slots);

  /// The set in use.
  final SlotMode mode;

  /// Every live slot (any mode), Ramadan ones with the day's windows.
  final List<MealSlot> slots;

  /// The Ramadan (mode on) the day is in, or null.
  final RamadanPeriod? ramadan;

  /// Whether the day is marked not fasting (LC-034).
  final bool notFasting;

  /// The active slots of [mode], in order.
  List<MealSlot> get active => [
    for (final s in slots)
      if (s.active && s.mode == mode) s,
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Whether [slotId] is an active slot of the day's mode.
  bool offers(String? slotId) => active.any((s) => s.id == slotId);

  /// The slot for the local minute [minuteOfDay] (DY-011).
  String? assign(int minuteOfDay) =>
      const SlotAssigner().assign(minuteOfDay, slots, mode);

  @override
  String toString() => 'DaySlots(${mode.code})';
}

/// [DaySlots] of [date], live: follows the slots, the Ramadan decisions,
/// the day's not-fasting mark, the city and the prayer method.
@riverpod
Future<DaySlots> daySlots(Ref ref, LocalDate date) async {
  final slotsFuture = ref.watch(_allSlotsProvider.future);
  final calendarFuture = ref.watch(ramadanCalendarProvider.future);
  final slots = await slotsFuture;
  final calendar = await calendarFuture;
  final period = calendar.onPeriodContaining(date);
  if (period == null) return DaySlots.normal(slots);
  final notFasting = calendar.notFastingOn(date);
  if (notFasting) {
    return DaySlots(
      mode: SlotMode.normal,
      slots: slots,
      ramadan: period,
      notFasting: notFasting,
    );
  }
  final times = await ref.watch(prayerTimesProvider(date).future);
  return DaySlots(
    mode: SlotMode.ramadan,
    slots: RamadanSlots.withPrayerWindows(
      slots,
      fajrMinute: times?.fajrMinute,
      maghribMinute: times?.maghribMinute,
    ),
    ramadan: period,
  );
}

@riverpod
Stream<List<MealSlot>> _allSlots(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchAllSlots();
