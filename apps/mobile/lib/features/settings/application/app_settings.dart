import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';

/// Stored enum names are permanent synced values.
enum ThemePreference {
  /// Follow the device theme.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// How the weekly adaptive check-in changes targets (TG-034, A38 D3).
/// Stored enum names are permanent synced values.
enum CheckInMode {
  /// Propose the change; the user accepts, adjusts or keeps (default).
  ask,

  /// Apply it through the single writer; Progress offers Change back.
  automatic,
}

/// Permanent key names participate in UUIDv5 row identities (A10 D2).
abstract final class AppSettings {
  /// LC-010 display preference.
  static final SettingKey<UnitSystem> unitSystem = SettingKey.enumeration(
    'units.system',
    UnitSystem.values,
    defaultValue: UnitSystem.metric,
  );

  /// LC-021 / D-070.
  static final SettingKey<DayOfWeek> weekStart = SettingKey.enumeration(
    'calendar.weekStart',
    DayOfWeek.values,
    defaultValue: DayOfWeek.saturday,
  );

  /// FD-080 owner default.
  static final SettingKey<bool> halal = SettingKey.boolean(
    'food.halal',
    defaultValue: true,
  );

  /// UX-040: light by default (D-083, TD-107). An unset key reads as light;
  /// stored values keep their meaning. A pick that equalled the default of
  /// its time was never stored (the store skips no-op writes), so it now
  /// reads light too (A45 D6).
  static final SettingKey<ThemePreference> theme = SettingKey.enumeration(
    'appearance.theme',
    ThemePreference.values,
    defaultValue: ThemePreference.light,
  );

  /// LC-033: invalid or newer identity formats read as unset.
  static final cityId = SettingKey<String?>(
    'location.cityId',
    codec: SettingCodec(
      toJson: (value) => value,
      fromJson: (json) => json is String && isCityId(json) ? json : null,
    ),
    defaultValue: null,
  );

  /// D-091: the language food names show in; "Match my phone" by default.
  static final SettingKey<FoodNameLanguage> foodNames = SettingKey.enumeration(
    'food.nameLanguage',
    FoodNameLanguage.values,
    defaultValue: FoodNameLanguage.phone,
  );

  /// A53 D4 / SF-012: the weekday factors the user confirmed below the
  /// safety floor on the warning screen (weekday name → factor). A day
  /// below the floor stays as set only while its factor is the confirmed
  /// one; unreadable entries are skipped.
  static final dayFloorAcks = SettingKey<Map<DayOfWeek, double>>(
    'targets.dayFloorAcks',
    codec: SettingCodec(
      toJson: (value) => {
        for (final MapEntry(:key, :value) in value.entries) key.name: value,
      },
      fromJson: (json) => {
        if (json is Map)
          for (final day in DayOfWeek.values)
            if (json[day.name] case final num factor
                when TargetLimits.isDayFactor(factor.toDouble()))
              day: factor.toDouble(),
      },
    ),
    defaultValue: const {},
  );

  /// TG-034: ask (default) or apply the weekly check-in automatically.
  static final SettingKey<CheckInMode> checkInMode = SettingKey.enumeration(
    'targets.checkInMode',
    CheckInMode.values,
    defaultValue: CheckInMode.ask,
  );

  /// LC-030/031, TG-060: the user's decision per Ramadan (on/off, the
  /// ±1-day shifts, "maintain during Ramadan"), by Hijri year. Unreadable
  /// years are skipped, never an error.
  static final ramadanSeasons = SettingKey<RamadanSettings>(
    'ramadan.seasons',
    codec: SettingCodec(
      toJson: (value) => value.toJson(),
      fromJson: RamadanSettings.fromJson,
    ),
    defaultValue: RamadanSettings.none,
  );

  /// LC-034: [date]'s fasting decision (A41a fix round 2), one synced key
  /// per date (`ramadan.fasting.d<yyyymmdd>`), so marks on different days
  /// and season preferences never overwrite each other. Unset reads as
  /// fasting.
  static SettingKey<FastingMark> fastingMark(LocalDate date) =>
      SettingKey.enumeration(
        RamadanFasting.keyName(date),
        FastingMark.values,
        defaultValue: FastingMark.fasting,
      );

  /// Every per-date fasting key a Ramadan of the calendar table can use,
  /// for export's natural-id reverse lookup.
  static Iterable<String> get fastingKeyNames sync* {
    final calendar = RamadanCalendar(RamadanSettings.none);
    for (final year in UmmAlQura.ramadan.keys) {
      for (final d in RamadanFasting.datesOf(calendar.calendarPeriod(year)!)) {
        yield RamadanFasting.keyName(d);
      }
    }
  }

  /// AI-132 (A68 D6): Buddy's weekly review of the week from [weekStart],
  /// one setting per week (`buddy.weeklyReview.d<yyyymmdd>`), so reviews of
  /// different weeks never overwrite each other. Unset: none written yet.
  static SettingKey<String?> weeklyReview(LocalDate weekStart) => SettingKey(
    'buddy.weeklyReview.d${'$weekStart'.replaceAll('-', '')}',
    codec: SettingCodec.optionalString,
    defaultValue: null,
  );

  /// Every per-week review key a week from 2026 to 2035 can use (any day
  /// may start a week), for export's natural-id reverse lookup.
  static Iterable<String> get weeklyReviewKeyNames sync* {
    final last = LocalDate(2035, 12, 31);
    for (var d = LocalDate(2026, 1, 1); !d.isAfter(last); d = d.plusDays(1)) {
      yield weeklyReview(d).name;
    }
  }

  /// LC-033 / G12: how Fajr and Maghrib are computed (A41a D2).
  static final SettingKey<PrayerMethod> prayerMethod = SettingKey.enumeration(
    'prayer.method',
    PrayerMethod.values,
    defaultValue: PrayerMethod.muslimWorldLeague,
  );

  /// NT-020/NT-021: the local reminders (A40 D3), one value; unreadable
  /// fields read as their `spec/17` defaults.
  static final notificationPrefs = SettingKey<NotificationPrefs>(
    'notifications.prefs',
    codec: SettingCodec(
      toJson: (value) => value.toJson(),
      fromJson: NotificationPrefs.fromJson,
    ),
    defaultValue: NotificationPrefs.defaults,
  );

  /// UX-085 (A71 D8): the home-screen widgets show only their buttons.
  static final SettingKey<bool> widgetNumbersHidden = SettingKey.boolean(
    'widgets.hideNumbers',
    defaultValue: false,
  );

  /// Complete setting vocabulary for export's natural-id reverse lookup.
  static final List<SettingKey<Object?>> all = [
    unitSystem,
    weekStart,
    halal,
    foodNames,
    theme,
    cityId,
    dayFloorAcks,
    checkInMode,
    ramadanSeasons,
    prayerMethod,
    notificationPrefs,
    widgetNumbersHidden,
  ];

  /// Accepted GeoNames identity format, without including input in errors.
  static bool isCityId(String value) =>
      RegExp(r'^city:[0-9]+$').hasMatch(value);
}
