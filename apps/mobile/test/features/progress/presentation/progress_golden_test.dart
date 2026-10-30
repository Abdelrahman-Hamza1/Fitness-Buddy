import 'package:alchemist/alchemist.dart';
import 'package:material_ui/material_ui.dart';

import '../support/progress_support.dart';

Widget _cell(Brightness brightness, double scale) => SizedBox(
  width: 360,
  height: 1500,
  child: progressApp(
    progressOverrides(),
    brightness: brightness,
    textScale: scale,
  ),
);

Future<void> main() async {
  // A key screen (A46): this week with a logged, an over-target, an
  // incomplete (hatched), an unknown day and today so far.
  await goldenTest(
    'IN-002 DY-004 Progress: this week, an incomplete day hatched',
    fileName: 'progress_screen',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: [
        GoldenTestScenario(name: 'light', child: _cell(Brightness.light, 1)),
        GoldenTestScenario(name: 'dark', child: _cell(Brightness.dark, 1)),
        GoldenTestScenario(
          name: 'light, text 2.0',
          child: _cell(Brightness.light, 2),
        ),
      ],
    ),
  );
}
