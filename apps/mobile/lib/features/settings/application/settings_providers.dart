import 'dart:ui' show PlatformDispatcher;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/application/app_settings.dart';
import 'package:fb_mobile/features/settings/application/settings_actions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

/// Display units; never affects stored nutrition quantities.
@riverpod
Stream<UnitSystem> unitSystem(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.unitSystem);

/// The chosen first day, including the Saturday default.
@riverpod
Stream<DayOfWeek> weekStart(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.weekStart);

/// The stored "Food names" choice (D-091), "Match my phone" by default.
@riverpod
Stream<FoodNameLanguage> foodNameSetting(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.foodNames);

/// The phone's languages in preference order (language codes), read when
/// first needed; tests override it.
@riverpod
List<String> phoneLanguages(Ref ref) => [
  for (final locale in PlatformDispatcher.instance.locales) locale.languageCode,
];

/// The language food names show in (D-091): the setting with "Match my
/// phone" resolved; English until the setting has loaded.
@riverpod
FoodNameLanguage foodNameLanguage(Ref ref) =>
    (ref.watch(foodNameSettingProvider).value ?? FoodNameLanguage.phone)
        .resolve(ref.watch(phoneLanguagesProvider));

/// The weekday factors confirmed below the floor (A53 D4).
@riverpod
Stream<Map<DayOfWeek, double>> dayFloorAcks(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.dayFloorAcks);

/// Ask or apply the weekly check-in automatically (TG-034).
@riverpod
Stream<CheckInMode> checkInMode(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.checkInMode);

/// The notification settings (NT-020, A40 D3).
@riverpod
Stream<NotificationPrefs> notificationPrefs(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.notificationPrefs);

/// One shared calendar for future weekly views.
@riverpod
WeekCalendar weekCalendar(Ref ref) => WeekCalendar(
  weekStart: ref.watch(weekStartProvider).value ?? DayOfWeek.saturday,
);

/// Owner's halal preference (downstream filtering arrives in A24).
@riverpod
Stream<bool> halal(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.halal);

/// Lazy persisted theme; callers use the default (light) before the first
/// emission.
@riverpod
Stream<ThemePreference> themePreference(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.theme);

/// Validated optional city identity.
@riverpod
Stream<String?> cityId(Ref ref) =>
    ref.watch(settingsStoreProvider).watch(AppSettings.cityId);

/// Unknown and unset identities have no selected city.
@riverpod
Future<CatalogCity?> selectedCity(Ref ref) async {
  final id = await ref.watch(cityIdProvider.future);
  return id == null ? null : await ref.watch(offlineCatalogProvider).city(id);
}

/// Commands retain pending keys across route changes.
@Riverpod(keepAlive: true)
SettingsActions settingsActions(Ref ref) => SettingsActions(
  store: ref.watch(settingsStoreProvider),
  undoStack: ref.watch(undoStackProvider),
);
