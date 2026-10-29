import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/unit_feed.dart';
import '../../today/presentation/support/today_support.dart' show phoneApp;
import 'weigh_in_harness.dart';

export 'weigh_in_harness.dart';

/// The weigh-in sheet on a real in-memory database, applier and undo stack.
final class SheetRig {
  /// Creates the rig (metric units; switch with `units.set`).
  new() {
    stack = UndoStack(revert: h.applier.revert, clock: h.clock);
    addTearDown(stack.dispose);
  }

  /// The database, applier and clock (2026-10-17 15:00 at UTC+03:00).
  final WeighInHarness h = WeighInHarness();

  /// The unit setting.
  final UnitFeed units = UnitFeed();

  /// The undo stack the snackbar uses.
  late final UndoStack stack;

  /// The providers of the sheet.
  List<Override> get overrides => [
    ...h.overrides,
    undoStackProvider.overrideWithValue(stack),
    units.override,
  ];

  /// Logs [drafts] (ids `fixtureId(1…)`) outside the fake async zone.
  Future<void> seed(WidgetTester tester, List<WeighInDraft> drafts) async {
    await tester.runAsync(() => h.seed(drafts));
  }

  /// The live weigh-ins, read outside the fake async zone.
  Future<List<WeighIn>> live(WidgetTester tester) async =>
      (await tester.runAsync(h.live))!;
}

/// The label of the host's button that opens the sheet.
const String openLabel = 'Open sheet';

/// A screen with one button that opens the weigh-in sheet.
class SheetHost extends StatelessWidget {
  /// Opens it for [date] / [edit].
  const new({this.date, this.edit, super.key});

  /// See `showWeighInSheet`.
  final LocalDate? date;

  /// See `showWeighInSheet`.
  final WeighIn? edit;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FbButton.primary(
        label: openLabel,
        onPressed: () => showWeighInSheet(context, date: date, edit: edit),
      ),
    ),
  );
}

/// Waits for the database, then for the frames.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

/// Pumps the host on a tall phone (the whole sheet shows) and opens the
/// sheet.
Future<void> openSheet(
  WidgetTester tester,
  SheetRig rig, {
  LocalDate? date,
  WeighIn? edit,
  double textScale = 1,
  Size size = const Size(360, 1400),
  List<Override> extra = const [],
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...rig.overrides, ...extra],
      child: phoneApp(
        SheetHost(date: date, edit: edit),
        textScale: textScale,
      ),
    ),
  );
  await tester.tap(find.text(openLabel));
  await settle(tester);
}

/// Takes the app down so database streams and undo timers end.
Future<void> unmount(WidgetTester tester, SheetRig rig) async {
  rig.stack.dispose();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 6));
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Waits out the confirmation's tap guard (300 ms after it appears).
Future<void> pastConfirmGuard(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
}

/// The FbButton labelled [label].
Finder button(String label) => find.widgetWithText(FbButton, label);

/// Whether [finder]'s FbButton can be tapped.
bool isEnabled(WidgetTester tester, Finder finder) =>
    tester.widget<FbButton>(finder).onPressed != null;

/// Taps the pad keys of [keys] ("97.4"; `<` is backspace).
Future<void> typeOnPad(WidgetTester tester, String keys) async {
  final pad = find.byType(FbNumberPad);
  for (final c in keys.split('')) {
    final key = find.descendant(
      of: pad,
      matching: c == '<' ? find.byIcon(FbIcons.backspace) : find.text(c),
    );
    await tester.tap(key.first);
    await tester.pump();
  }
}

/// The amount shown above the pad ("97.4").
String shownAmount(WidgetTester tester) =>
    tester.widget<FbAmountDisplay>(find.byType(FbAmountDisplay)).amount;

/// The unit shown above the pad ("kg").
String shownUnit(WidgetTester tester) =>
    tester.widget<FbAmountDisplay>(find.byType(FbAmountDisplay)).unit;
