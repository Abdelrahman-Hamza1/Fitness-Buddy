import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/data/measurement_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/unit_feed.dart';
import '../../body/support/measurement_harness.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;

export '../../body/support/measurement_harness.dart';

/// A navigator that records pushes and counts pops.
final class MeasureNavigator implements AppNavigator {
  /// Every pushed route, in order.
  final List<AppRoute> pushed = [];

  /// How many times [pop] was called.
  int pops = 0;

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => pushed.add(route);

  @override
  void pop() => pops++;
}

/// The measurement screens on a real in-memory database, applier and undo
/// stack (2026-10-17 15:00 at UTC+03:00).
final class MeasureRig {
  /// Creates the rig (metric units; switch with `units.value`).
  new() {
    stack = UndoStack(revert: h.applier.revert, clock: h.clock);
    addTearDown(stack.dispose);
  }

  /// The database, applier and clock.
  final MeasurementHarness h = MeasurementHarness();

  /// The unit setting.
  final UnitFeed units = UnitFeed();

  /// The navigator port.
  final MeasureNavigator navigator = MeasureNavigator();

  /// The undo stack the snackbar uses.
  late final UndoStack stack;

  /// The providers of the screens.
  List<Override> get overrides => [
    ...h.overrides,
    undoStackProvider.overrideWithValue(stack),
    units.override,
    appNavigatorProvider.overrideWithValue(navigator),
  ];

  /// Applies [ops] outside the fake async zone.
  Future<void> seed(WidgetTester tester, List<ChangeOp> ops) async {
    await tester.runAsync(() => h.apply(ops));
  }

  /// The live data, read outside the fake async zone.
  Future<MeasurementData> live(WidgetTester tester) async =>
      (await tester.runAsync(h.live))!;
}

/// Pumps [screen] on a tall phone.
Future<void> pumpMeasure(
  WidgetTester tester,
  MeasureRig rig,
  Widget screen, {
  Size size = const Size(360, 1600),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(overrides: rig.overrides, child: phoneApp(screen)),
  );
  await settleMeasure(tester);
}

/// Waits for the database, then for the frames.
Future<void> settleMeasure(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

/// Takes the app down so database streams and undo timers end.
Future<void> unmountMeasure(WidgetTester tester, MeasureRig rig) async {
  rig.stack.dispose();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 6));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// The FbButton labelled [label].
Finder fbButton(String label) => find.widgetWithText(FbButton, label);

/// The value field's text.
String fieldText(WidgetTester tester) =>
    tester.widget<FbNumberField>(find.byType(FbNumberField)).controller.text;
