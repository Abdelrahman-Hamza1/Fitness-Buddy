import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
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

/// Types [keys] on every scenario's pad, then taps every pinned Save.
PumpAction _typeAndSave(String keys) => (tester) async {
  await tester.pumpAndSettle();
  final pads = find.byType(FbNumberPad);
  final count = pads.evaluate().length;
  for (var i = 0; i < count; i++) {
    for (final c in keys.split('')) {
      final key = find.descendant(of: pads.at(i), matching: find.text(c));
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }
  }
  // From the last scenario back: a confirmation replaces its own scenario's
  // pinned Save with the answers, so the earlier Saves keep their indexes.
  final saves = find.widgetWithText(FbButton, 'Save');
  for (var i = count - 1; i >= 0; i--) {
    await tester.tap(saves.at(i));
    await tester.pumpAndSettle();
  }
};

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
  await _golden(
    'WB-005 weigh-in sheet: large-change confirm',
    'weigh_in_sheet_large_change',
    const WeighInSheet(),
    lastWeek,
    pumpBeforeTest: _typeAndSave('100'),
  );
  await _golden(
    'WB-005 weigh-in sheet: unit confirm',
    'weigh_in_sheet_unit',
    const WeighInSheet(),
    lastWeek,
    pumpBeforeTest: _typeAndSave('214'),
  );
  await _golden(
    'WB-003 weigh-in sheet: same day',
    'weigh_in_sheet_same_day',
    const WeighInSheet(),
    [...lastWeek, storedWeighIn(3, weighInDraft(97.2, hour: 6, minute: 50))],
  );
  final edited = storedWeighIn(
    4,
    weighInDraft(97.8, hour: 9, note: 'after Eid'),
    preferred: true,
  );
  await _golden(
    'weigh-in sheet: edit',
    'weigh_in_sheet_edit',
    WeighInSheet(edit: edited),
    [...lastWeek, storedWeighIn(3, weighInDraft(97.2, hour: 6)), edited],
  );
}
