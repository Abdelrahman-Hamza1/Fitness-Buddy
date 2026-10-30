import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart';
import 'settings_support.dart';

Widget _phone(
  Widget screen,
  Brightness brightness,
  double scale,
  List<Override> overrides,
  double height,
) => SizedBox(
  width: 360,
  height: height,
  child: ProviderScope(
    overrides: overrides,
    child: phoneApp(screen, brightness: brightness, textScale: scale),
  ),
);

Future<void> _golden(
  String name,
  String file,
  Widget screen,
  List<Override> overrides, {
  Interaction? whilePerforming,
  double height = 640,
}) => goldenTest(
  name,
  fileName: file,
  whilePerforming: whilePerforming,
  builder: () => GoldenTestGroup(
    columns: 4,
    children: [
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$label, x$scale',
            child: _phone(screen, brightness, scale, overrides, height),
          ),
    ],
  ),
);

Future<void> main() async {
  final nablus = sampleCities.first;
  final base = [
    citySearchProvider.overrideWith((ref) async => CitySearch(sampleCities)),
  ];
  await _golden(
    'LC-010 LC-033 UX-010 UX-070 me: settings',
    'me_settings',
    const MeScreen(),
    [
      ...fakeToday(units: UnitSystem.imperial),
      ...base,
      ...fakeSettings(city: nablus),
    ],
    height: 900,
  );
  await _golden('SF-040 UX-070 about', 'about', const AboutScreen(), [
    ...base,
    aboutInfoProvider.overrideWith(
      (ref) async => const AboutInfo(
        version: '0.1.0',
        build: '1',
        flavor: AppFlavor.prod,
        packVersion: 12,
        activeCredits: [
          AboutCredit(
            name: 'USDA FoodData Central',
            credit: 'Food data from USDA FoodData Central, public domain.',
          ),
          AboutCredit(
            name: 'GeoNames',
            credit: 'City names and places from GeoNames, CC BY 4.0.',
          ),
        ],
      ),
    ),
  ]);
}
