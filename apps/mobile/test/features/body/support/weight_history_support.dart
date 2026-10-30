import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/application/weight_history_form.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/unit_feed.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;
import 'weigh_in_harness.dart';
import 'weigh_in_sheet_support.dart' show settle;

export 'weigh_in_harness.dart';
export 'weigh_in_sheet_support.dart' show button, isEnabled, settle;

/// A navigator that counts pops (the screen leaves through the port).
final class PopCounter implements AppNavigator {
  /// How many times [pop] was called.
  int pops = 0;

  @override
  void go(AppRoute route) => throw UnimplementedError();

  @override
  void push(AppRoute route) => throw UnimplementedError();

  @override
  void pop() => pops++;
}

/// The weight history screen on a real in-memory database, applier and
/// undo stack (the harness's 2026-10-17 15:00 at UTC+03:00).
final class HistoryRig {
  /// Creates the rig (metric units; switch with `units.value`).
  new() {
    stack = UndoStack(revert: h.applier.revert, clock: h.clock);
    addTearDown(stack.dispose);
  }

  /// The database, applier and clock.
  final WeighInHarness h = WeighInHarness();

  /// The unit setting.
  final UnitFeed units = UnitFeed();

  /// The navigator port.
  final PopCounter navigator = PopCounter();

  /// The undo stack the snackbar uses.
  late final UndoStack stack;

  /// The providers of the screen.
  List<Override> get overrides => [
    ...h.overrides,
    undoStackProvider.overrideWithValue(stack),
    units.override,
    appNavigatorProvider.overrideWithValue(navigator),
  ];

  /// Logs [drafts] (ids `fixtureId(1…)`) outside the fake async zone.
  Future<void> seed(WidgetTester tester, List<WeighInDraft> drafts) async {
    await tester.runAsync(() => h.seed(drafts));
  }

  /// The live weigh-ins, read outside the fake async zone.
  Future<List<WeighIn>> live(WidgetTester tester) async =>
      (await tester.runAsync(h.live))!;
}

/// Pumps the screen on a tall phone.
Future<void> openHistory(
  WidgetTester tester,
  HistoryRig rig, {
  WeightHistoryForm? initial,
  Size size = const Size(360, 1600),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: rig.overrides,
      child: phoneApp(WeightHistoryScreen(initial: initial)),
    ),
  );
  await settle(tester);
}

/// Takes the app down so database streams and undo timers end.
Future<void> unmountHistory(WidgetTester tester, HistoryRig rig) async {
  rig.stack.dispose();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 6));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// Picks [day] of the month the open date picker shows, for row [row].
Future<void> pickRowDate(WidgetTester tester, int row, int day) async {
  await tester.tap(find.byType(FbChoiceChip).at(row + 2));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(Dialog), matching: find.text('$day')),
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Types [text] into row [row]'s value field.
Future<void> typeRow(WidgetTester tester, int row, String text) async {
  await tester.enterText(find.byType(TextField).at(row), text);
  await tester.pump();
}
