import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps [child] in a themed app with the DS localizations: a Navigator and
/// Overlay for sheets, a Scaffold for snackbars.
Future<void> pumpFb(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool disableAnimations = true,
  bool accessibleNavigation = false,
  double width = 360,
  double height = 800,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? FbTheme.light() : FbTheme.dark(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        FbLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: FbLocalizations.supportedLocales,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
            accessibleNavigation: accessibleNavigation,
          ),
          child: app!,
        ),
      ),
      home: Scaffold(body: child),
    ),
  );
}
