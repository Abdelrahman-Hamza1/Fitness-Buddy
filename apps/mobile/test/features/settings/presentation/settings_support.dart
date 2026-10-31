import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

/// A [CatalogCity] as the pack would give it.
CatalogCity cityOf(
  int id,
  String nameEn,
  String? nameAr,
  String country,
  int population,
) => CatalogCity(
  id: 'city:$id',
  nameEn: nameEn,
  nameAr: nameAr,
  countryCode: country,
  population: population,
  timezone: 'Asia/Hebron',
  latitude: 32,
  longitude: 35,
);

/// The cities of the screen goldens: a few of Palestine and Jordan, and one
/// of Egypt and of the world (shown with its ISO code).
final List<CatalogCity> sampleCities = [
  cityOf(282615, 'Nablus', 'نابلس', 'PS', 130326),
  cityOf(285066, 'Hebron', 'الخليل', 'PS', 160470),
  cityOf(7303419, 'East Jerusalem', 'القدس الشرقية', 'PS', 428304),
  cityOf(282239, 'Ramallah', 'رام الله', 'PS', 43880),
  cityOf(281577, 'Tulkarm', 'طولكرم', 'PS', 44169),
  cityOf(250441, 'Amman', 'عمّان', 'JO', 1275857),
  cityOf(250624, 'Karak', 'الكرك', 'JO', 22581),
  cityOf(360630, 'Cairo', 'القاهرة', 'EG', 9606916),
  cityOf(2643743, 'London', null, 'GB', 8961989),
];

/// The settings the Me tab shows, without a database (the unit system is
/// `fakeToday`'s).
List<Override> fakeSettings({
  DayOfWeek weekStart = DayOfWeek.saturday,
  bool halal = true,
  ThemePreference theme = ThemePreference.system,
  CatalogCity? city,
}) => [
  weekStartProvider.overrideWith((ref) => Stream.value(weekStart)),
  halalProvider.overrideWith((ref) => Stream.value(halal)),
  themePreferenceProvider.overrideWith((ref) => Stream.value(theme)),
  cityIdProvider.overrideWith((ref) => Stream.value(city?.id)),
  selectedCityProvider.overrideWith((ref) async => city),
];

/// A phone: 360 x 1200 so the whole Me list shows.
void useTallScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 1200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The Me tab, opened from Today.
Future<void> openMe(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text('Me')),
  );
  await tester.pumpAndSettle();
}

/// The Me subpage behind the row titled [row] (A51), opened from Today.
Future<void> openMePage(WidgetTester tester, String row) async {
  await openMe(tester);
  final link = find.widgetWithText(FbListRow, row);
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
}

/// A fresh phone of the given flavor.
TestPhone phoneOf(AppConfig config) => TestPhone(config: config);

/// [pumpApp] on a tall screen.
Future<ProviderContainer> pumpAt(
  WidgetTester tester, {
  TestPhone? phone,
  List<Override> overrides = const [],
}) {
  useTallScreen(tester);
  return pumpApp(tester, phone: phone, overrides: overrides);
}
