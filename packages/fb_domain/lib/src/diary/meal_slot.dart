import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// Which set of meal slots is in use (A06 D7): the normal day, or Ramadan
/// (A41 seeds its own slots, e.g. suhoor and iftar).
enum SlotMode {
  /// The normal day.
  normal('normal'),

  /// Ramadan.
  ramadan('ramadan');

  new(this.code);

  /// The stable code stored in `meal_slots.mode`.
  final String code;

  /// The mode whose [code] is exactly [code], or `null`.
  static SlotMode? fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}

/// A meal slot's time window, `[startMin, endMin)` in minutes after local
/// midnight (0–1439). A window whose start is after its end wraps midnight
/// (22:00–02:00). An empty window (start == end) is invalid (A06 D7).
final class TimeWindow {
  /// The window from [startMin] (inclusive) to [endMin] (exclusive). Throws
  /// an `ArgumentError` for a bound outside 0–1439 or an empty window.
  new(this.startMin, this.endMin) {
    _checkMinute(startMin, 'startMin');
    _checkMinute(endMin, 'endMin');
    if (startMin == endMin) {
      throw ArgumentError.value(endMin, 'endMin', 'must differ from startMin');
    }
  }

  /// The window from the stored bounds (`window_start_min`,
  /// `window_end_min`): both or neither. `null` when both are `null`;
  /// an `ArgumentError` when only one is.
  static TimeWindow? fromBounds(int? startMin, int? endMin) {
    if (startMin == null && endMin == null) return null;
    if (startMin == null || endMin == null) {
      throw ArgumentError('a window needs both bounds or neither');
    }
    return TimeWindow(startMin, endMin);
  }

  /// The first minute in the window.
  final int startMin;

  /// The first minute after the window.
  final int endMin;

  /// Whether the window wraps midnight.
  bool get wraps => startMin > endMin;

  /// Whether the minute of day [minute] (0–1439) is in the window.
  bool contains(int minute) {
    _checkMinute(minute, 'minute');
    return wraps
        ? minute >= startMin || minute < endMin
        : minute >= startMin && minute < endMin;
  }

  @override
  bool operator ==(Object other) =>
      other is TimeWindow &&
      other.startMin == startMin &&
      other.endMin == endMin;

  @override
  int get hashCode => Object.hash(startMin, endMin);

  @override
  String toString() => '${_hhmm(startMin)}–${_hhmm(endMin)}';
}

/// A meal slot (DY-010): Breakfast, Lunch, Dinner, Snacks or one the user
/// adds. A row of `meal_slots`.
final class MealSlot {
  /// The slot [id] (a lowercase canonical UUID). A default slot has a
  /// [defaultKey] and no [name] until the user renames it (the UI shows the
  /// label for [defaultKey]). A custom slot has a [name].
  new({
    required this.id,
    required this.sortOrder,
    this.defaultKey,
    this.name,
    this.window,
    this.mode = SlotMode.normal,
    this.active = true,
  }) {
    if (!isUuid(id)) {
      throw ArgumentError.value(id, 'id', 'must be a lowercase canonical UUID');
    }
    if (defaultKey == null && name == null) {
      throw ArgumentError('a slot needs a defaultKey or a name');
    }
  }

  /// The time of day an entry gets when it is logged into this slot on a
  /// past day without a time (A06 D6): the window's start, else 12:00.
  static const int defaultMinuteWithoutWindow = 12 * 60;

  /// The slot's ID.
  final String id;

  /// The key of a default slot (`breakfast`, …), or `null` for a custom one.
  final String? defaultKey;

  /// The name the user gave it, or `null` (a default slot not renamed).
  /// User content: never logged.
  final String? name;

  /// The position in the day, lowest first.
  final int sortOrder;

  /// The time window, or `null` (the catch-all, like Snacks).
  final TimeWindow? window;

  /// The set this slot belongs to.
  final SlotMode mode;

  /// Whether the slot is in use (a removed slot stays as history).
  final bool active;

  /// The local time an entry gets when logged into this slot without a time
  /// (A06 D6): the window's start, else 12:00.
  LocalTime get defaultTime =>
      LocalTime.ofMinuteOfDay(window?.startMin ?? defaultMinuteWithoutWindow);

  @override
  bool operator ==(Object other) =>
      other is MealSlot &&
      other.id == id &&
      other.defaultKey == defaultKey &&
      other.name == name &&
      other.sortOrder == sortOrder &&
      other.window == window &&
      other.mode == mode &&
      other.active == active;

  @override
  int get hashCode =>
      Object.hash(id, defaultKey, name, sortOrder, window, mode, active);

  /// Without the [name] (user content).
  @override
  String toString() =>
      'MealSlot($id, ${defaultKey ?? 'custom'}, #$sortOrder, '
      '${window ?? 'no window'}, ${mode.code}${active ? '' : ', inactive'})';
}

/// The default slots (DY-010, A06 D8), seeded by the database on every
/// device with the same deterministic IDs (TD-070):
/// `uuidv5(fbNamespace, 'mealSlot:normal:<defaultKey>')`. The app's tests
/// recompute them.
///
/// | Slot | Window |
/// |---|---|
/// | breakfast | 04:00–11:00 |
/// | lunch | 11:00–16:00 |
/// | dinner | 16:00–22:00 |
/// | snacks | none (the catch-all) |
abstract final class DefaultSlots {
  /// `uuidv5(fbNamespace, 'mealSlot:normal:breakfast')`.
  static const String breakfastId = '4c5aed24-f404-506e-a925-f0ff33099753';

  /// `uuidv5(fbNamespace, 'mealSlot:normal:lunch')`.
  static const String lunchId = 'ca0daf21-3d15-53c5-b4ec-ee09a5e0c674';

  /// `uuidv5(fbNamespace, 'mealSlot:normal:dinner')`.
  static const String dinnerId = '260cb3fe-def5-53e5-9f5c-d64f61a4ec3e';

  /// `uuidv5(fbNamespace, 'mealSlot:normal:snacks')`.
  static const String snacksId = '9c906ed8-064d-52d3-b116-803e12ee5630';

  /// The natural key of a default slot, the part after `mealSlot:` in its
  /// UUIDv5 name: `<mode>:<defaultKey>`, e.g. `normal:breakfast`.
  static String naturalKey(String defaultKey, {SlotMode mode = .normal}) =>
      '${mode.code}:$defaultKey';

  /// Breakfast, 04:00–11:00.
  static final MealSlot breakfast = MealSlot(
    id: breakfastId,
    defaultKey: 'breakfast',
    sortOrder: 0,
    window: TimeWindow(4 * 60, 11 * 60),
  );

  /// Lunch, 11:00–16:00.
  static final MealSlot lunch = MealSlot(
    id: lunchId,
    defaultKey: 'lunch',
    sortOrder: 1,
    window: TimeWindow(11 * 60, 16 * 60),
  );

  /// Dinner, 16:00–22:00.
  static final MealSlot dinner = MealSlot(
    id: dinnerId,
    defaultKey: 'dinner',
    sortOrder: 2,
    window: TimeWindow(16 * 60, 22 * 60),
  );

  /// Snacks, no window.
  static final MealSlot snacks = MealSlot(
    id: snacksId,
    defaultKey: 'snacks',
    sortOrder: 3,
  );

  /// The four, in order. Unmodifiable.
  static final List<MealSlot> all = List.unmodifiable([
    breakfast,
    lunch,
    dinner,
    snacks,
  ]);
}

void _checkMinute(int minute, String name) {
  if (minute < 0 || minute >= LocalTime.minutesPerDay) {
    throw RangeError.range(minute, 0, LocalTime.minutesPerDay - 1, name);
  }
}

String _hhmm(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';
