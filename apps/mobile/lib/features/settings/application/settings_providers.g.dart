// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Display units; never affects stored nutrition quantities.

@ProviderFor(unitSystem)
final unitSystemProvider = UnitSystemProvider._();

/// Display units; never affects stored nutrition quantities.

final class UnitSystemProvider
    extends
        $FunctionalProvider<
          AsyncValue<UnitSystem>,
          UnitSystem,
          Stream<UnitSystem>
        >
    with $FutureModifier<UnitSystem>, $StreamProvider<UnitSystem> {
  /// Display units; never affects stored nutrition quantities.
  UnitSystemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unitSystemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unitSystemHash();

  @$internal
  @override
  $StreamProviderElement<UnitSystem> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<UnitSystem> create(Ref ref) {
    return unitSystem(ref);
  }
}

String _$unitSystemHash() => r'a515f6882040d710edeb7fb68d08467429335323';

/// The chosen first day, including the Saturday default.

@ProviderFor(weekStart)
final weekStartProvider = WeekStartProvider._();

/// The chosen first day, including the Saturday default.

final class WeekStartProvider
    extends
        $FunctionalProvider<AsyncValue<DayOfWeek>, DayOfWeek, Stream<DayOfWeek>>
    with $FutureModifier<DayOfWeek>, $StreamProvider<DayOfWeek> {
  /// The chosen first day, including the Saturday default.
  WeekStartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekStartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekStartHash();

  @$internal
  @override
  $StreamProviderElement<DayOfWeek> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DayOfWeek> create(Ref ref) {
    return weekStart(ref);
  }
}

String _$weekStartHash() => r'656abc5c29e168a35ec34f461f99965bc2d6548e';

/// The training-day shifting weight, or null when off (TG-043).

@ProviderFor(trainingDayWeight)
final trainingDayWeightProvider = TrainingDayWeightProvider._();

/// The training-day shifting weight, or null when off (TG-043).

final class TrainingDayWeightProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, Stream<double?>>
    with $FutureModifier<double?>, $StreamProvider<double?> {
  /// The training-day shifting weight, or null when off (TG-043).
  TrainingDayWeightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainingDayWeightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainingDayWeightHash();

  @$internal
  @override
  $StreamProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double?> create(Ref ref) {
    return trainingDayWeight(ref);
  }
}

String _$trainingDayWeightHash() => r'8ae477ec2985d9cdbdcca93b4cd7184dc736aa78';

/// Ask or apply the weekly check-in automatically (TG-034).

@ProviderFor(checkInMode)
final checkInModeProvider = CheckInModeProvider._();

/// Ask or apply the weekly check-in automatically (TG-034).

final class CheckInModeProvider
    extends
        $FunctionalProvider<
          AsyncValue<CheckInMode>,
          CheckInMode,
          Stream<CheckInMode>
        >
    with $FutureModifier<CheckInMode>, $StreamProvider<CheckInMode> {
  /// Ask or apply the weekly check-in automatically (TG-034).
  CheckInModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInModeHash();

  @$internal
  @override
  $StreamProviderElement<CheckInMode> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CheckInMode> create(Ref ref) {
    return checkInMode(ref);
  }
}

String _$checkInModeHash() => r'82dd2f71e6cdd9efdb80996d828865f3efb8647c';

/// The notification settings (NT-020, A40 D3).

@ProviderFor(notificationPrefs)
final notificationPrefsProvider = NotificationPrefsProvider._();

/// The notification settings (NT-020, A40 D3).

final class NotificationPrefsProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationPrefs>,
          NotificationPrefs,
          Stream<NotificationPrefs>
        >
    with
        $FutureModifier<NotificationPrefs>,
        $StreamProvider<NotificationPrefs> {
  /// The notification settings (NT-020, A40 D3).
  NotificationPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPrefsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPrefsHash();

  @$internal
  @override
  $StreamProviderElement<NotificationPrefs> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<NotificationPrefs> create(Ref ref) {
    return notificationPrefs(ref);
  }
}

String _$notificationPrefsHash() => r'7140638d7bf9225fea2dd82c5fa80af6460319b1';

/// One shared calendar for future weekly views.

@ProviderFor(weekCalendar)
final weekCalendarProvider = WeekCalendarProvider._();

/// One shared calendar for future weekly views.

final class WeekCalendarProvider
    extends $FunctionalProvider<WeekCalendar, WeekCalendar, WeekCalendar>
    with $Provider<WeekCalendar> {
  /// One shared calendar for future weekly views.
  WeekCalendarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekCalendarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekCalendarHash();

  @$internal
  @override
  $ProviderElement<WeekCalendar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeekCalendar create(Ref ref) {
    return weekCalendar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeekCalendar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeekCalendar>(value),
    );
  }
}

String _$weekCalendarHash() => r'43ab2ac8018a596ec05eb566cd675c47373ebc82';

/// Owner's halal preference (downstream filtering arrives in A24).

@ProviderFor(halal)
final halalProvider = HalalProvider._();

/// Owner's halal preference (downstream filtering arrives in A24).

final class HalalProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Owner's halal preference (downstream filtering arrives in A24).
  HalalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'halalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$halalHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return halal(ref);
  }
}

String _$halalHash() => r'8a75b9b74d4d2736e277e8e2b7d25eccc62c067f';

/// Lazy persisted theme; callers use the default (light) before the first
/// emission.

@ProviderFor(themePreference)
final themePreferenceProvider = ThemePreferenceProvider._();

/// Lazy persisted theme; callers use the default (light) before the first
/// emission.

final class ThemePreferenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemePreference>,
          ThemePreference,
          Stream<ThemePreference>
        >
    with $FutureModifier<ThemePreference>, $StreamProvider<ThemePreference> {
  /// Lazy persisted theme; callers use the default (light) before the first
  /// emission.
  ThemePreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themePreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themePreferenceHash();

  @$internal
  @override
  $StreamProviderElement<ThemePreference> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ThemePreference> create(Ref ref) {
    return themePreference(ref);
  }
}

String _$themePreferenceHash() => r'5a7f0a0e1d93a05331458048e24354ed1910d1fb';

/// Validated optional city identity.

@ProviderFor(cityId)
final cityIdProvider = CityIdProvider._();

/// Validated optional city identity.

final class CityIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// Validated optional city identity.
  CityIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cityIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cityIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return cityId(ref);
  }
}

String _$cityIdHash() => r'c8c55e355fd7ec4f9fb40d1c53a2ee76c68d37db';

/// Unknown and unset identities have no selected city.

@ProviderFor(selectedCity)
final selectedCityProvider = SelectedCityProvider._();

/// Unknown and unset identities have no selected city.

final class SelectedCityProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogCity?>,
          CatalogCity?,
          FutureOr<CatalogCity?>
        >
    with $FutureModifier<CatalogCity?>, $FutureProvider<CatalogCity?> {
  /// Unknown and unset identities have no selected city.
  SelectedCityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCityHash();

  @$internal
  @override
  $FutureProviderElement<CatalogCity?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogCity?> create(Ref ref) {
    return selectedCity(ref);
  }
}

String _$selectedCityHash() => r'1da718c60a620f747396e677e59fa06070984c5f';

/// Commands retain pending keys across route changes.

@ProviderFor(settingsActions)
final settingsActionsProvider = SettingsActionsProvider._();

/// Commands retain pending keys across route changes.

final class SettingsActionsProvider
    extends
        $FunctionalProvider<SettingsActions, SettingsActions, SettingsActions>
    with $Provider<SettingsActions> {
  /// Commands retain pending keys across route changes.
  SettingsActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsActionsHash();

  @$internal
  @override
  $ProviderElement<SettingsActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsActions create(Ref ref) {
    return settingsActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsActions>(value),
    );
  }
}

String _$settingsActionsHash() => r'fc8d63b581962398b60991726441fa878cdad852';
