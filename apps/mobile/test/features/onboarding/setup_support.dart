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

  /// The back arrow in the bar.
  Future<void> back() async {
    taps++;
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
  }

  /// Taps Continue (or another bottom button).
  Future<void> next([String label = 'Continue']) => tap(label);

  /// "About you" in metric: Male, 1990, 180 cm, 80 kg.
  Future<void> you() async {
    await tap('Male');
    await enter('Birth year', '1990');
    await enter('Height', '180');
    await enter('Current weight', '80');
  }

  /// Goal, about you, activity and training with the minimal answers,
  /// ending on "Here's your plan".
  Future<void> toPlan({String goal = 'Lose weight'}) async {
    await tap(goal);
    await next();
    await you();
    await next();
    await tap('Moderately active');
    await next();
    await tap('Not right now');
    await next();
  }
}

/// Opens the app on a fresh offline phone and shows setup (or [route]:
/// the first run's questions).
Future<ProviderContainer> openSetup(
  WidgetTester tester, {
  TestPhone? phone,
  List<Override> overrides = const [],
  Future<void> Function(ProviderContainer container)? before,
  AppRoute route = const SetupRoute(),
}) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = await pumpApp(tester, phone: phone, overrides: overrides);
  if (before != null) await tester.runAsync(() => before(container));
  showRoute(container, route);
  await settleWrites(tester);
  expect(find.byType(SetupScreen), findsOneWidget);
  return container;
}

/// The bottom button labelled [label].
FbButton button(WidgetTester tester, String label) => tester.widget<FbButton>(
  find.ancestor(of: find.text(label), matching: find.byType(FbButton)),
);
