import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

/// Counts what a setup run asks of the user (the UX-060 tap budget).
final class SetupRun {
  /// A run in [tester].
  new(this.tester);

  /// The tester.
  final WidgetTester tester;

  /// Taps so far.
  int taps = 0;

  /// Number entries so far.
  int entries = 0;

  /// Taps the widget showing [text] (the last one: a page's own copy).
  Future<void> tap(String text) async {
    taps++;
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Taps the number field labelled [label] (a tap: focusing it) and types
  /// [value] (a number entry).
  Future<void> enter(String label, String value) async {
    entries++;
    taps++;
    final field = find.widgetWithText(TextField, label);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  /// Taps Next (or Save).
  Future<void> next([String label = 'Next']) => tap(label);

  /// Page 1 in metric: Male, 1990, 180 cm, 80 kg.
  Future<void> you() async {
    await tap('Male');
    await enter('Birth year', '1990');
    await enter('Height', '180');
    await enter('Current weight', '80');
  }

  /// Pages 1–4 with the minimal choices, ending on "Your targets".
  Future<void> toTargets() async {
    await you();
    await next();
    await tap('Moderately active');
    await next();
    await tap('Lose weight');
    await next();
    await next();
  }
}

/// Opens the app on a fresh offline phone and shows setup.
Future<ProviderContainer> openSetup(
  WidgetTester tester, {
  TestPhone? phone,
  List<Override> overrides = const [],
  Future<void> Function(ProviderContainer container)? before,
}) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await pumpApp(tester, phone: phone, overrides: overrides);
  if (before != null) await tester.runAsync(() => before(container));
  showRoute(container, const SetupRoute());
  await settleWrites(tester);
  expect(find.byType(SetupScreen), findsOneWidget);
  return container;
}

/// The bottom button labelled [label].
FbButton button(WidgetTester tester, String label) => tester.widget<FbButton>(
  find.ancestor(of: find.text(label), matching: find.byType(FbButton)),
);
