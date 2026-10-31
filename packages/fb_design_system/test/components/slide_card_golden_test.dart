// Covers: UX-051
import 'package:alchemist/alchemist.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  await goldenTest(
    'summary pager and sparkline',
    fileName: 'slide_card',
    builder: () => GoldenTestGroup(
      columns: 4,
      children: [
        for (final scale in [1.0, 2.0])
          for (final b in Brightness.values)
            GoldenTestScenario(
              name: '${b.name} x$scale',
              child: SizedBox(
                width: 360,
                height: 600,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: b == Brightness.light
                      ? FbTheme.light()
                      : FbTheme.dark(),
                  home: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Scaffold(
                      body: FbSlideCard(
                        height: 200,
                        index: 0,
                        onIndexChanged: (_) {},
                        semanticLabel: (s, n, c) => '$s, $n of $c',
                        slides: [
                          FbSlide(
                            label: 'Nutrition',
                            builder: (_) =>
                                const FbSparkline(values: [80, 79, 79, 78]),
                          ),
                          FbSlide(
                            label: 'Weight',
                            builder: (_) => const Text('Weight'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    ),
  );
}
