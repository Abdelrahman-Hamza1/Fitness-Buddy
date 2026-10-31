import 'package:fb_domain/src/diary/meal_slot.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// The Ramadan meal slots (DY-012, A41a D5): Suhoor, Iftar and Snacks,
/// seeded on every device with deterministic IDs like the normal ones
/// (TD-070): `uuidv5(fbNamespace, 'mealSlot:ramadan:<defaultKey>')`.
///
/// Suhoor and Iftar are stored without a window: while the user hasn't set
/// one, their window follows the day's prayer times ([withPrayerWindows]).
abstract final class RamadanSlots {
  /// The default key of Suhoor.
  static const String suhoorKey = 'suhoor';

  /// The default key of Iftar.
  static const String iftarKey = 'iftar';

  /// `uuidv5(fbNamespace, 'mealSlot:ramadan:suhoor')`.
  static const String suhoorId = 'd66f696e-cfcb-5a60-a70d-8a4d21f3c9c0';

  /// `uuidv5(fbNamespace, 'mealSlot:ramadan:iftar')`.
  static const String iftarId = 'd8814590-7c87-5da2-8ad9-de3f1d155c92';

  /// `uuidv5(fbNamespace, 'mealSlot:ramadan:snacks')`.
  static const String snacksId = '623c0dd7-e319-5fc0-987a-0b2c33643a0a';

  /// Suhoor: the window ends at Fajr and starts [suhoorLeadMinutes] before.
  static final MealSlot suhoor = MealSlot(
    id: suhoorId,
    defaultKey: suhoorKey,
    sortOrder: 0,
    mode: .ramadan,
  );

  /// Iftar: the window starts at Maghrib and lasts [iftarMinutes].
  static final MealSlot iftar = MealSlot(
    id: iftarId,
    defaultKey: iftarKey,
    sortOrder: 1,
    mode: .ramadan,
  );

  /// Snacks, the catch-all.
  static final MealSlot snacks = MealSlot(
    id: snacksId,
    defaultKey: 'snacks',
    sortOrder: 2,
    mode: .ramadan,
  );

  /// The three, in order. Unmodifiable.
  static final List<MealSlot> all = List.unmodifiable([suhoor, iftar, snacks]);

  /// Suhoor's window starts this long before Fajr (`09` §2).
  static const int suhoorLeadMinutes = 3 * 60;

  /// Iftar's window lasts this long after Maghrib (`09` §2).
  static const int iftarMinutes = 3 * 60;

  /// Suhoor's window when no prayer times are known (no city chosen):
  /// 01:30–05:00.
  static final TimeWindow fallbackSuhoor = TimeWindow(90, 300);

  /// Iftar's window when no prayer times are known: 16:30–20:30.
  static final TimeWindow fallbackIftar = TimeWindow(990, 1230);

  /// [slots] with the effective windows of the day: an active Ramadan
  /// Suhoor or Iftar default slot without a stored window gets the window
  /// from [fajrMinute] / [maghribMinute] (local minutes of the day), or the
  /// fallback window when they are null. Every other slot is unchanged
  /// (a window the user set always wins).
  static List<MealSlot> withPrayerWindows(
    Iterable<MealSlot> slots, {
    int? fajrMinute,
    int? maghribMinute,
  }) => [
    for (final slot in slots)
      if (slot.mode != SlotMode.ramadan || slot.window != null)
        slot
      else
        switch (slot.defaultKey) {
          suhoorKey => _withWindow(
            slot,
            fajrMinute == null
                ? fallbackSuhoor
                : TimeWindow(
                    (fajrMinute - suhoorLeadMinutes) % LocalTime.minutesPerDay,
                    fajrMinute,
                  ),
          ),
          iftarKey => _withWindow(
            slot,
            maghribMinute == null
                ? fallbackIftar
                : TimeWindow(
                    maghribMinute,
                    (maghribMinute + iftarMinutes) % LocalTime.minutesPerDay,
                  ),
          ),
          _ => slot,
        },
  ];

  /// Whether [slot] is a Ramadan default slot whose window follows the
  /// prayer times (no window stored).
  static bool followsPrayerTimes(MealSlot slot) =>
      slot.mode == SlotMode.ramadan &&
      slot.window == null &&
      (slot.defaultKey == suhoorKey || slot.defaultKey == iftarKey);

  static MealSlot _withWindow(MealSlot slot, TimeWindow window) => MealSlot(
    id: slot.id,
    sortOrder: slot.sortOrder,
    defaultKey: slot.defaultKey,
    name: slot.name,
    window: window,
    mode: slot.mode,
    active: slot.active,
  );
}
