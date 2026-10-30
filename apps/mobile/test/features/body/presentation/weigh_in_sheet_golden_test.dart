import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/weigh_in_harness.dart';

/// A sheet shown under a dimmed screen, as the bottom sheet shows it.
class _Sheet extends StatelessWidget {
  const new(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(alignment: AlignmentDirectional.bottomCenter, child: child),
  );
}

/// The sheet's providers: a fixed clock, metric units and [weighIns].
List<Override> _overrides(List<WeighIn> weighIns) => [
  clockProvider.overrideWithValue(ManualClock(harnessNow, offsetMinutes: 180)),
  unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
  weighInsProvider.overrideWith((ref) => Stream.value(weighIns)),
];

Widget _phone(
  Widget sheet,
  Brightness brightness,
  double scale,
  List<WeighIn> weighIns,
) => SizedBox(
  width: 360,
  height: 800,
  child: ProviderScope(
    overrides: _overrides(weighIns),
    child: phoneApp(_Sheet(sheet), brightness: brightness, textScale: scale),
  ),
);

Future<void> _golden(
  String name,
  String file,
  Widget sheet,
  List<WeighIn> weighIns, {
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
}) => goldenTest(
  name,
  fileName: file,
  pumpBeforeTest: pumpBeforeTest,
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
            child: _phone(sheet, brightness, scale, weighIns),
          ),
    ],
  ),
);

Future<void> main() async {
  final yesterday = day17.plusDays(-1);
  final lastWeek = [
    storedWeighIn(1, weighInDraft(97.6, date: day17.plusDays(-8))),
    storedWeighIn(2, weighInDraft(97, date: yesterday)),
  ];

  await _golden(
    'WB-001 weigh-in sheet: prefilled',
    'weigh_in_sheet_prefilled',
    const WeighInSheet(),
    lastWeek,
  );
}
