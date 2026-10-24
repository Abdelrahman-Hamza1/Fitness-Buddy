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

  /// UX-040.
  static final SettingKey<ThemePreference> theme = SettingKey.enumeration(
    'appearance.theme',
    ThemePreference.values,
    defaultValue: ThemePreference.system,
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

  /// Accepted GeoNames identity format, without including input in errors.
  static bool isCityId(String value) =>
      RegExp(r'^city:[0-9]+$').hasMatch(value);
}
