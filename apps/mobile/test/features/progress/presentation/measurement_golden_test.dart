import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/measurement_repository.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../body/support/measurement_harness.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;

Measurement _m(int n, MeasurementDraft draft) => Measurement(
  id: mId(n),
  version: 1,
  type: draft.type,
  time: draft.time,
  localDate: draft.localDate,
  value: draft.value,
  input: draft.input,
);

final MeasurementType _leftArm = MeasurementType(
  id: tId(1),
  version: 1,
  name: 'Left arm',
);

final MeasurementTypeRef _bodyFat = MeasurementTypeRef.builtIn(
  MeasurementKind.bodyFat,
);

/// Five weekly waist entries, one chest, three body fat, two left arm.
final MeasurementData _data = MeasurementData(
  types: [_leftArm],
  measurements: [
    for (var i = 0; i < 5; i++)
      _m(
        i,
        measureDraft(95.5 - i * 0.8, date: measureDay.plusDays(-7 * (4 - i))),
      ),
    _m(
      10,
      measureDraft(
        104,
        type: MeasurementTypeRef.builtIn(MeasurementKind.chest),
        date: measureDay.plusDays(-3),
      ),
    ),
    for (var i = 0; i < 3; i++)
      _m(
        20 + i,
        measureDraft(
          24.5 - i * 0.6,
          type: _bodyFat,
          unit: MeasurementUnit.percent,
          date: measureDay.plusDays(-14 * (2 - i)),
        ),
      ),
    for (var i = 0; i < 2; i++)
      _m(
        30 + i,
        measureDraft(
          13.5 - i * 0.25,
          type: _leftArm.ref,
          unit: MeasurementUnit.inch,
          date: measureDay.plusDays(-10 * (1 - i)),
        ),
      ),
  ],
);

/// A fixed clock, [data] and metric units.
List<Override> _overrides(MeasurementData data) => [
  clockProvider.overrideWithValue(ManualClock(measureNow, offsetMinutes: 180)),
  measurementsProvider.overrideWith((ref) => Stream.value(data)),
  unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
];

Widget _app(
  Widget screen,
  MeasurementData data,
  Brightness brightness,
  double scale,
) => ProviderScope(
  overrides: _overrides(data),
  child: phoneApp(screen, brightness: brightness, textScale: scale),
);

GoldenTestGroup _group(
  Map<String, (Widget, MeasurementData)> rows, {
  double height = 1000,
}) => GoldenTestGroup(
  columns: 4,
  children: [
    for (final MapEntry(key: name, value: (screen, data)) in rows.entries)
      for (final scale in const [1.0, 2.0])
        for (final (label, brightness) in const [
          ('light', Brightness.light),
          ('dark', Brightness.dark),
        ])
          GoldenTestScenario(
            name: '$name, $label, x$scale',
            child: SizedBox(
              width: 360,
              height: height,
              child: _app(screen, data, brightness, scale),
            ),
          ),
  ],
);

/// [sheet] as the body of a screen (the modal's content).
Widget _sheet(Widget sheet) => Scaffold(body: SafeArea(child: sheet));

Future<void> main() async {
  final empty = MeasurementData(types: const [], measurements: const []);
  await goldenTest(
    'WB-040 UX-050 measurements list: empty · with data',
    fileName: 'measurements_list',
    builder: () => _group({
      'empty': (const MeasurementsScreen(), empty),
      'with data': (const MeasurementsScreen(), _data),
    }),
  );
  await goldenTest(
    'WB-041 WB-042 measurement type: no trend · trend · body fat',
    fileName: 'measurement_type',
    builder: () => _group({
      'no trend': (MeasurementTypeScreen(typeKey: _leftArm.ref.key), _data),
      'trend': (const MeasurementTypeScreen(typeKey: 'waist'), _data),
      'body fat': (const MeasurementTypeScreen(typeKey: 'bodyFat'), _data),
    }, height: 1400),
  );
  await goldenTest(
    'WB-040 measurement sheet: length · body fat · edit',
    fileName: 'measurement_sheet',
    builder: () => _group({
      'length': (_sheet(const MeasurementSheet()), _data),
      'body fat': (_sheet(MeasurementSheet(type: _bodyFat)), _data),
      'edit': (_sheet(MeasurementSheet(edit: _data.measurements[2])), _data),
    }, height: 800),
  );
  await goldenTest(
    'WB-040 custom type sheet',
    fileName: 'custom_type_sheet',
    builder: () =>
        _group({'new': (_sheet(const CustomTypeSheet()), _data)}, height: 600),
  );
}
