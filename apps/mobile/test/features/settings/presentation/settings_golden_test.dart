import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/export/export_service.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
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

/// The units choice as the option sheet shows it, under a dimmed screen.
class _UnitsSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: AlignmentDirectional.bottomCenter,
      child: FbSheet(
        title: l10n.settingsUnits,
        child: FbOptionList<UnitSystem>(
          selected: UnitSystem.imperial,
          onSelected: (_) {},
          options: [
            FbOption(
              value: UnitSystem.metric,
              label: l10n.settingsUnitsMetric,
              subtitle: l10n.settingsUnitsMetricHint,
            ),
            FbOption(
              value: UnitSystem.imperial,
              label: l10n.settingsUnitsImperial,
              subtitle: l10n.settingsUnitsImperialHint,
            ),
          ],
        ),
      ),
    );
  }
}

/// The export sheet's content as the sheet shows it, under a dimmed screen.
class _ExportSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.bottomCenter,
    child: FbSheet(
      title: context.l10n.meExportData,
      actions: const ExportSheetActions(),
      child: const ExportSheetBody(),
    ),
  );
}

/// A controller stuck in [state]: a golden shows one state.
class _FixedExport extends DataExportController {
  new(this.fixed);

  final DataExportState fixed;

  @override
  DataExportState build() => fixed;
}

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
  await _golden(
    'LC-010 UX-011 UX-070 units option sheet',
    'units_option_sheet',
    const Scaffold(body: _UnitsSheet()),
    fakeToday(),
  );
  await _golden(
    'AC-030 UX-011 UX-070 export sheet: idle',
    'export_sheet',
    const Scaffold(body: _ExportSheet()),
    [
      ...fakeToday(),
      dataExportControllerProvider.overrideWith(
        () => _FixedExport(const ExportIdle()),
      ),
    ],
    height: 900,
  );
  await _golden(
    'AC-030 UX-052 UX-070 export sheet: failure with Try again',
    'export_sheet_failed',
    const Scaffold(body: _ExportSheet()),
    [
      ...fakeToday(),
      dataExportControllerProvider.overrideWith(
        () => _FixedExport(const ExportFailed(ExportFailureKind.sharing)),
      ),
    ],
    height: 900,
  );
  await _golden(
    'LC-033 UX-070 city picker: suggestions',
    'city_picker_suggestions',
    const CityPickerScreen(),
    [...fakeToday(), ...base, ...fakeSettings(city: nablus)],
  );
  await _golden(
    'LC-033 UX-070 city picker: results',
    'city_picker_results',
    const CityPickerScreen(),
    [...fakeToday(), ...base, ...fakeSettings(city: nablus)],
    whilePerforming: (tester) async {
      final fields = find.byType(TextField);
      for (var i = 0; i < fields.evaluate().length; i++) {
        await tester.enterText(fields.at(i), 'ra');
      }
      await tester.pump();
      return;
    },
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
