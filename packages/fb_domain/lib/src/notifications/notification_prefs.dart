import 'package:fb_domain/src/time/local_date.dart';

/// The local reminders (NT-001–NT-007, `spec/17` §1). Stored names are
/// permanent synced values; [code] is part of each notification's stable
/// platform ID, so it never changes either. Batch closing (NT-010) comes with
/// batches (A27); suhoor and iftar (NT-008/009) with A41a.
enum NotificationType {
  /// NT-001: only if fewer than 2 meals are logged today.
  logReminder(1, 21 * 60, enabledByDefault: true),

  /// NT-002: something unconfirmed, 30 minutes after it was created, once.
  pendingProposal(2, null, enabledByDefault: true),

  /// NT-003: weekly, on the chosen day.
  weighIn(3, 8 * 60, enabledByDefault: true),

  /// NT-004: the weekly summary is ready (phase 1: no Buddy review yet).
  weeklySummary(4, 9 * 60, enabledByDefault: true),

  /// NT-005: on planned training days.
  workout(5, 18 * 60, enabledByDefault: false),

  /// NT-006: protein far below target late in the day.
  proteinCheck(6, 20 * 60, enabledByDefault: false),

  /// NT-007: monthly.
  measurement(7, 9 * 60, enabledByDefault: false),

  /// NT-008: 45 minutes before Fajr on Ramadan fasting days (A41a D10);
  /// timed by the prayer times, allowed in quiet hours, outside the cap.
  suhoor(8, null, enabledByDefault: true),

  /// NT-009: 90 minutes after Maghrib on Ramadan fasting days; timed by the
  /// prayer times, outside the cap.
  iftar(9, null, enabledByDefault: false);

  new(this.code, this.defaultMinute, {required this.enabledByDefault});

  /// Stable number in the platform ID (1–99).
  final int code;

  /// The default time (minute of the day), or null for a type timed by an
  /// event (the pending proposal).
  final int? defaultMinute;

  /// Whether the type is on by default (`spec/17` §1).
  final bool enabledByDefault;

  /// Whether the user picks this type's time.
  bool get hasTime => defaultMinute != null;
}

/// One type's setting: on or off, and its time (minute of the day).
final class NotificationTypePrefs {
  /// [minute] is 0–1439; ignored for a type without a time.
  new({required this.enabled, required this.minute}) {
    _checkMinute(minute, 'minute');
  }

  /// Whether the type fires.
  final bool enabled;

  /// When, as minutes after midnight.
  final int minute;

  /// A copy with the given fields replaced.
  NotificationTypePrefs copyWith({bool? enabled, int? minute}) =>
      NotificationTypePrefs(
        enabled: enabled ?? this.enabled,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is NotificationTypePrefs &&
      other.enabled == enabled &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, minute);

  @override
  String toString() => 'NotificationTypePrefs($enabled, $minute)';
}

/// The notification settings (NT-020, NT-021, A40 D3): a master switch,
/// quiet hours, and each type's switch and time, with `spec/17`'s defaults.
/// Stored as one synced settings value ([toJson]); `fromJson` reads what it
/// can and falls back to the default field by field, so a value written by
/// a newer app (or a damaged one) never turns reminders off by accident.
final class NotificationPrefs {
  /// Prefs; a type missing from [types] has its defaults.
  new({
    this.enabled = true,
    this.quietStart = defaultQuietStart,
    this.quietEnd = defaultQuietEnd,
    Map<NotificationType, NotificationTypePrefs> types = const {},
    this.weighInDay,
  }) : types = Map.unmodifiable({
         for (final type in NotificationType.values)
           type: types[type] ?? defaultsOf(type),
       }) {
    _checkMinute(quietStart, 'quietStart');
    _checkMinute(quietEnd, 'quietEnd');
  }

  /// The prefs in [json]; anything unreadable is its default. Never throws.
  factory fromJson(Object? json) {
    if (json is! Map<String, Object?>) return defaults;
    bool flag(Object? v, {required bool fallback}) => v is bool ? v : fallback;
    int minute(Object? v, int fallback) =>
        v is int && v >= 0 && v < minutesPerDay ? v : fallback;
    final types = <NotificationType, NotificationTypePrefs>{};
    if (json['types'] case final Map<String, Object?> stored) {
      for (final type in NotificationType.values) {
        final fallback = defaultsOf(type);
        if (stored[type.name] case final Map<String, Object?> value) {
          types[type] = NotificationTypePrefs(
            enabled: flag(value['enabled'], fallback: fallback.enabled),
            minute: minute(value['minute'], fallback.minute),
          );
        }
      }
    }
    final day = json['weighInDay'];
    return NotificationPrefs(
      enabled: flag(json['enabled'], fallback: true),
      quietStart: minute(json['quietStart'], defaultQuietStart),
      quietEnd: minute(json['quietEnd'], defaultQuietEnd),
      types: types,
      weighInDay: DayOfWeek.values.where((d) => d.name == day).firstOrNull,
    );
  }

  /// The defaults (`spec/17`).
  static final NotificationPrefs defaults = NotificationPrefs();

  /// Quiet hours start, 23:00 (NT-021).
  static const int defaultQuietStart = 23 * 60;

  /// Quiet hours end, 07:00 (NT-021).
  static const int defaultQuietEnd = 7 * 60;

  /// The day of the month the measurement reminder fires (NT-007).
  static const int measurementDayOfMonth = 1;

  /// [type]'s default switch and time.
  static NotificationTypePrefs defaultsOf(NotificationType type) =>
      NotificationTypePrefs(
        enabled: type.enabledByDefault,
        minute: type.defaultMinute ?? 0,
      );

  /// The master switch (NT-020).
  final bool enabled;

  /// Quiet hours, minutes after midnight; start after end crosses midnight;
  /// equal means no quiet hours.
  final int quietStart;

  /// See [quietStart].
  final int quietEnd;

  /// Every type's setting. Unmodifiable.
  final Map<NotificationType, NotificationTypePrefs> types;

  /// The weigh-in reminder's day; null means the week's first day.
  final DayOfWeek? weighInDay;

  /// [type]'s setting.
  NotificationTypePrefs of(NotificationType type) => types[type]!;

  /// Whether [minute] falls in quiet hours (NT-021).
  bool isQuiet(int minute) {
    if (quietStart == quietEnd) return false;
    return quietStart < quietEnd
        ? minute >= quietStart && minute < quietEnd
        : minute >= quietStart || minute < quietEnd;
  }

  /// A copy with the given fields replaced; [clearWeighInDay] goes back to
  /// the week's first day.
  NotificationPrefs copyWith({
    bool? enabled,
    int? quietStart,
    int? quietEnd,
    DayOfWeek? weighInDay,
    bool clearWeighInDay = false,
  }) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    types: types,
    weighInDay: clearWeighInDay ? null : weighInDay ?? this.weighInDay,
  );

  /// A copy with [type]'s setting replaced.
  NotificationPrefs withType(
    NotificationType type,
    NotificationTypePrefs value,
  ) => NotificationPrefs(
    enabled: enabled,
    quietStart: quietStart,
    quietEnd: quietEnd,
    types: {...types, type: value},
    weighInDay: weighInDay,
  );

  /// The stored form.
  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'quietStart': quietStart,
    'quietEnd': quietEnd,
    'weighInDay': weighInDay?.name,
    'types': {
      for (final MapEntry(:key, :value) in types.entries)
        key.name: {'enabled': value.enabled, 'minute': value.minute},
    },
  };

  /// Minutes in a day.
  static const int minutesPerDay = 1440;

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.enabled == enabled &&
      other.quietStart == quietStart &&
      other.quietEnd == quietEnd &&
      other.weighInDay == weighInDay &&
      NotificationType.values.every((t) => other.of(t) == of(t));

  @override
  int get hashCode => Object.hash(
    enabled,
    quietStart,
    quietEnd,
    weighInDay,
    Object.hashAll([for (final t in NotificationType.values) of(t)]),
  );

  @override
  String toString() => 'NotificationPrefs(enabled: $enabled)';
}

int _checkMinute(int minute, String name) {
  if (minute < 0 || minute >= NotificationPrefs.minutesPerDay) {
    throw RangeError.range(
      minute,
      0,
      NotificationPrefs.minutesPerDay - 1,
      name,
    );
  }
  return minute;
}
