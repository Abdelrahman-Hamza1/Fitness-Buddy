import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/pump_app.dart';

/// The whole app at its first screen, as the system with [brightness] and
/// [textScale] would show it; with [updateRequired], the update screen.
Widget _shell(
  Brightness brightness, {
  double textScale = 1,
  bool updateRequired = false,
}) => SizedBox(
  width: 360,
  height: 640,
  child: Builder(
    // The app's own MediaQuery takes brightness and text scale from here.
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        platformBrightness: brightness,
        textScaler: TextScaler.linear(textScale),
      ),
      child: testApp(overrides: [if (updateRequired) tripped]),
    ),
  ),
);

Future<void> main() async {
  // No "DEBUG" ribbon in the images.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  await goldenTest(
    'UX-010 UX-040 app shell light/dark',
    fileName: 'app_shell',
    builder: () => GoldenTestGroup(
      columns: 3,
      children: [
        GoldenTestScenario(name: 'light', child: _shell(Brightness.light)),
        GoldenTestScenario(name: 'dark', child: _shell(Brightness.dark)),
        GoldenTestScenario(
          name: 'light, text x2',
          child: _shell(Brightness.light, textScale: 2),
        ),
      ],
    ),
  );
}
