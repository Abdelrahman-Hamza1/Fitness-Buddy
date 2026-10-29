import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'buddy_harness.dart';

/// The label of the button that opens the sheet in [pumpBuddyHost].
const openSheet = 'open-buddy';

/// A screen over [h]'s container with one button that opens Buddy's sheet,
/// at [size] and [textScale], in [brightness].
Future<void> pumpBuddyHost(
  WidgetTester tester,
  BuddyHarness h, {
  Size size = const Size(360, 720),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool disableAnimations = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.light
            ? FbTheme.light()
            : FbTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FbLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: app!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    showBuddySheet(context, date: LocalDate(2026, 10, 17)),
                child: const Text(openSheet),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Opens the sheet of [pumpBuddyHost].
Future<void> openBuddySheet(WidgetTester tester) async {
  await tester.tap(find.text(openSheet));
  await tester.pumpAndSettle();
}

/// Lets the database and the fake transport finish what a tap started (the
/// writes run on the real event loop), then settles the frames.
Future<void> settleBuddy(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Types [text] into the composer and taps Send.
Future<void> sendInSheet(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byTooltip('Send'));
  await tester.pump();
}

/// Takes the widget tree down so drift's stream timers finish, and stops
/// [h]'s undo expiry timers (as the app rigs do).
Future<void> unmountBuddy(WidgetTester tester, [BuddyHarness? h]) async {
  h?.undo.dispose();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}
