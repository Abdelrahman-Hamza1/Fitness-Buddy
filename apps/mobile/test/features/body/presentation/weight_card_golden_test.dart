import 'package:alchemist/alchemist.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/body/data/weight_tip_store.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/memory_tip_store.dart';
import '../support/weigh_in_harness.dart';

/// The card's providers: a fixed clock, metric units, [weighIns] and a
/// suggestion that never showed.
List<Override> _overrides(List<WeighIn> weighIns) => [
  clockProvider.overrideWithValue(ManualClock(harnessNow, offsetMinutes: 180)),
  unitSystemProvider.overrideWith((ref) => Stream.value(UnitSystem.metric)),
  weighInsProvider.overrideWith((ref) => Stream.value(weighIns)),
  weightTipStoreProvider.overrideWithValue(MemoryTipStore()),
];

Widget _phone(
  LocalDate date,
  List<WeighIn> weighIns,
  Brightness brightness,
  double scale,
) => SizedBox(
  width: 360,
  height: 760,
  child: ProviderScope(
    overrides: _overrides(weighIns),
    child: phoneApp(
      Scaffold(
        body: ListView(
          children: [WeightCard(date: date, isToday: date == day17)],
        ),
      ),
      brightness: brightness,
      textScale: scale,
    ),
  ),
);

Future<void> _golden(
  String name,
  String file,
  List<WeighIn> weighIns, {
  LocalDate? date,
}) => goldenTest(
  name,
  fileName: file,
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
            child: _phone(date ?? day17, weighIns, brightness, scale),
          ),
    ],
  ),
);

/// Weigh-ins `fixtureId(1…)` on the days [daysAgo] before the 17th.
List<WeighIn> _on(List<int> daysAgo, List<double> kgs) => [
  for (final (i, ago) in daysAgo.indexed)
    storedWeighIn(i + 1, weighInDraft(kgs[i], date: day17.plusDays(-ago))),
];

Future<void> main() async {
  await _golden('UX-050 weight card: empty', 'weight_card_empty', const []);
  await _golden(
    'WB-011 weight card: one weigh-in',
    'weight_card_one',
    _on([1], [97.4]),
  );
  await _golden(
    'HM-005 WB-011 WB-012 weight card: trend, rate, sparse line, suggestion',
    'weight_card_trend',
    _on([21, 14, 7, 0], [97.5, 97, 96.5, 96]),
  );
  await _golden(
    'WB-012 weight card: stale',
    'weight_card_stale',
    _on([40, 33], [98, 97]),
  );
  await _golden(
    'HM-009 weight card: past day',
    'weight_card_past_day',
    _on([21, 14, 7, 0], [97.5, 97, 96.5, 96]),
    date: day17.plusDays(-8),
  );
}
