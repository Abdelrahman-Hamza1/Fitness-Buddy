import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/application/weight_history_form.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/weigh_in_harness.dart';

/// Rows flagged as a duplicate, a same-day value, a likely unit mix-up and
/// an out-of-range value.
WeightHistoryForm _flagged() =>
    WeightHistoryForm.start(MassUnit.kilogram)
        .withDate(0, LocalDate(2026, 10, 7))
        .withText(0, '97')
        .addRow(day17)
        .withText(1, '98')
        .addRow(day17)
        .withText(2, '214')
        .addRow(day17)
        .withText(3, '19');

final List<WeighIn> _stored = [
  storedWeighIn(1, weighInDraft(97, date: LocalDate(2026, 10, 7))),
  storedWeighIn(2, weighInDraft(97.2, date: LocalDate(2026, 10, 14))),
];

/// A fixed clock, the stored weigh-ins and metric units.
List<Override> _overrides() => [
  clockProvider.overrideWithValue(ManualClock(harnessNow, offsetMinutes: 180)),
  weighInsProvider.overrideWith((ref) => Stream.value(_stored)),
  unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
];

/// The screen with [form] over the stored weigh-ins.
Widget _app(WeightHistoryForm? form, Brightness brightness, double scale) =>
    ProviderScope(
      overrides: _overrides(),
      child: phoneApp(
        WeightHistoryScreen(initial: form),
        brightness: brightness,
        textScale: scale,
      ),
    );

Widget _cell(WeightHistoryForm? form, Brightness brightness, double scale) =>
    SizedBox(width: 360, height: 1500, child: _app(form, brightness, scale));

Future<void> main() async {
  await goldenTest(
    'WB-001 WB-005 UX-070 weight history: empty · flagged rows',
    fileName: 'weight_history',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final (name, form) in [('empty', null), ('flagged', _flagged())])
          for (final scale in const [1.0, 2.0])
            for (final (label, brightness) in const [
              ('light', Brightness.light),
              ('dark', Brightness.dark),
            ])
              GoldenTestScenario(
                name: '$name, $label, x$scale',
                child: _cell(form, brightness, scale),
              ),
      ],
    ),
  );
}
