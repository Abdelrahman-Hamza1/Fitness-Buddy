import 'package:alchemist/alchemist.dart';
import 'package:fb_mobile/features/progress/application/graph_window.dart';
import 'package:fb_mobile/features/progress/application/weight_graph_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart' show fixtureId;
import '../support/weight_graph_support.dart';

/// Two years of weigh-ins with a goal phase over the last 4 months.
List<Override> _seeded(GraphRange range, {bool selected = false}) => [
  ...graphOverrides(
    range: range,
    phases: [losePhase(graphToday.plusDays(-120))],
  ),
  if (selected)
    selectedWeighInProvider.overrideWithBuild((ref, n) => fixtureId(730)),
];

Widget _cell(List<Override> overrides, Brightness brightness, double scale) =>
    SizedBox(
      width: 360,
      height: 1000,
      child: graphApp(overrides, brightness: brightness, textScale: scale),
    );

GoldenTestGroup _group(Map<String, (List<Override>, double)> rows) =>
    GoldenTestGroup(
      columns: 2,
      children: [
        for (final MapEntry(key: name, value: (overrides, scale))
            in rows.entries)
          for (final (label, brightness) in const [
            ('light', Brightness.light),
            ('dark', Brightness.dark),
          ])
            GoldenTestScenario(
              name: '$name, $label',
              child: _cell(overrides, brightness, scale),
            ),
      ],
    );

Future<void> main() async {
  await goldenTest(
    'WB-020 IN-004 weight graph: 1M · 3M · 6M · 1Y · All',
    fileName: 'weight_graph_ranges',
    builder: () => _group({
      for (final range in GraphRange.values) range.name: (_seeded(range), 1.0),
    }),
  );
}
