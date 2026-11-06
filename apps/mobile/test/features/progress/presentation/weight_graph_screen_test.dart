import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/application/weigh_in_actions.dart'
    show WeighInOutcome;
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../body/support/weigh_in_harness.dart';
import '../../body/support/weigh_in_sheet_support.dart'
    show SheetRig, button, settle, unmount;
import '../../today/presentation/support/today_support.dart' show phoneApp;
import '../support/weight_graph_support.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

/// Refuses the first deletion as a version conflict (another device
/// changed the weigh-in), then deletes for real.
final class _RefuseFirstDelete extends WeighInActions {
  bool _refused = false;

  @override
  Future<WeighInOutcome> delete(WeighIn weighIn) async {
    if (_refused) return await super.delete(weighIn);
    _refused = true;
    return const WeighInFailed(WeighInFailure.changed);
  }
}

FbTimeSeriesChart chartOf(WidgetTester tester) =>
    tester.widget<FbTimeSeriesChart>(find.byType(FbTimeSeriesChart));

Future<void> pumpGraph(WidgetTester tester, Widget app) async {
  tester.view
    ..physicalSize = const Size(360, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Taps the point [key] of the weigh-in series, as a tap on the chart does.
Future<void> selectPoint(WidgetTester tester, String key) async {
  chartOf(tester).onSelect!(FbPointRef(series: 0, key: key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('WB-020 the range chips switch 1M, 3M, 6M, 1Y and All; 3M by '
      'default; the choice survives leaving and returning', (tester) async {
    final container = ProviderContainer.test(
      overrides: graphOverrides(range: null),
    );
    Widget app() => UncontrolledProviderScope(
      container: container,
      child: phoneApp(const WeightGraphScreen()),
    );
    await pumpGraph(tester, app());
    for (final label in ['1M', '3M', '6M', '1Y', 'All']) {
      expect(find.widgetWithText(FbChoiceChip, label), findsOneWidget);
    }
    expect(chartOf(tester).range.start, DateTime.utc(2026, 7, 17));
    await tester.tap(find.widgetWithText(FbChoiceChip, '1Y'));
    await tester.pumpAndSettle();
    expect(chartOf(tester).range.start, DateTime.utc(2025, 10, 17));

    await tester.pumpWidget(const SizedBox());
    await pumpGraph(tester, app());
    expect(chartOf(tester).range.start, DateTime.utc(2025, 10, 17));
    await tester.tap(find.widgetWithText(FbChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(chartOf(tester).range.start, DateTime.utc(2024, 10, 18));
    expect(chartOf(tester).panBounds, isNull);
  });

  testWidgets('WB-022 tapping a point shows its value, date, note and the '
      'trend that day', (tester) async {
    final history = seededHistory();
    await pumpGraph(tester, graphApp(graphOverrides(weighIns: history)));
    await selectPoint(tester, fixtureId(730));
    final last = history.last;
    // The entries list below also shows the value: look inside the card.
    final details = find
        .ancestor(of: find.text('After the run'), matching: find.byType(FbCard))
        .first;
    expect(
      find.descendant(
        of: details,
        matching: find.text('${last.input.value.toStringAsFixed(1)} kg'),
      ),
      findsOneWidget,
    );
    expect(find.text('After the run'), findsOneWidget);
    expect(find.textContaining('Oct 17, 2026'), findsOneWidget);
    expect(find.textContaining('that day'), findsOneWidget);
    expect(find.text('Not used for the trend'), findsNothing);
    expect(button('Edit'), findsOneWidget);
    expect(find.text('Tap a point to see details'), findsNothing);
    expect(
      chartOf(tester).selected,
      FbPointRef(series: 0, key: fixtureId(730)),
    );
  });

  group('with the write path', () {
    Future<SheetRig> pumpWithRig(
      WidgetTester tester,
      List<WeighInDraft> drafts, {
      double height = 1400,
      List<Override> extra = const [],
    }) async {
      final rig = SheetRig();
      await rig.seed(tester, drafts);
      tester.view
        ..physicalSize = Size(360, height)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...rig.overrides, ...graphExtras(), ...extra],
          child: phoneApp(const WeightGraphScreen()),
        ),
      );
      await settle(tester);
      return rig;
    }

    testWidgets('WB-022 WB-003 a weigh-in not used for the trend says so, and '
        "Use for trend makes it the day's choice with undo", (tester) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
        weighInDraft(97.6, date: day17, hour: 9),
      ]);
      await selectPoint(tester, fixtureId(3));
      expect(find.text('Not used for the trend'), findsOneWidget);
      await tester.tap(button('Use for trend'));
      await settle(tester);
      final live = await rig.live(tester);
      expect(
        live.firstWhere((w) => w.id == fixtureId(3)).preferredForDay,
        isTrue,
      );
      expect(find.text('Trend weigh-in for the day changed'), findsOneWidget);
      expect(find.text('Not used for the trend'), findsNothing);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      final undone = await rig.live(tester);
      expect(
        undone.firstWhere((w) => w.id == fixtureId(3)).preferredForDay,
        isFalse,
      );
      await unmount(tester, rig);
    });

    testWidgets('A65 M3 a pinned Log weigh-in opens the sheet to log', (
      tester,
    ) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
      ]);
      await tester.tap(find.byKey(const ValueKey('weight-graph-log')));
      await settle(tester);
      expect(find.byType(WeighInSheet), findsOneWidget);
      expect(tester.widget<WeighInSheet>(find.byType(WeighInSheet)).edit, null);
      await unmount(tester, rig);
    });

    testWidgets('A65 M3 WB-003 the entries list is newest first, marks a '
        'weigh-in not used for the trend, and a tap edits it', (tester) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
        weighInDraft(97.6, date: day17, hour: 9),
      ], height: 2400);
      final entries = find.byWidgetPredicate(
        (w) =>
            w is FbSwipeActions &&
            (w.key as ValueKey<String>?)?.value.startsWith('weight-entry-') ==
                true,
      );
      expect(entries, findsNWidgets(3));
      final ids = [
        for (final e in tester.widgetList<FbSwipeActions>(entries))
          (e.key! as ValueKey<String>).value,
      ];
      expect(ids.first, 'weight-entry-${fixtureId(3)}');
      expect(ids.last, 'weight-entry-${fixtureId(1)}');
      final notUsed = tester.widget<FbListRow>(
        find.descendant(
          of: find.byKey(ValueKey('weight-entry-${fixtureId(3)}')),
          matching: find.byType(FbListRow),
        ),
      );
      final used = tester.widget<FbListRow>(
        find.descendant(
          of: find.byKey(ValueKey('weight-entry-${fixtureId(2)}')),
          matching: find.byType(FbListRow),
        ),
      );
      expect(notUsed.subtitle, isNot(used.subtitle));
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey('weight-entry-${fixtureId(1)}')),
          matching: find.byType(FbListRow),
        ),
      );
      await settle(tester);
      expect(
        tester.widget<WeighInSheet>(find.byType(WeighInSheet)).edit?.id,
        fixtureId(1),
      );
      await unmount(tester, rig);
    });

    /// Swipes entry `fixtureId(n)` toward the start edge, as a finger does.
    Future<void> swipeAway(WidgetTester tester, int n) async {
      await tester.drag(
        find.descendant(
          of: find.byKey(ValueKey('weight-entry-${fixtureId(n)}')),
          matching: find.byType(FbListRow),
        ),
        const Offset(-600, 0),
      );
      await settle(tester);
    }

    testWidgets('A65 M3 UX-030 swiping an entry away deletes it with Undo; '
        'the restored row swipes away again', (tester) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
      ], height: 2400);
      await swipeAway(tester, 1);
      expect((await rig.live(tester)).map((w) => w.id), [fixtureId(2)]);
      expect(find.text(_l10n.weighInDeleted), findsOneWidget);
      await tester.tap(find.byType(SnackBarAction));
      await settle(tester);
      expect((await rig.live(tester)).map((w) => w.id), hasLength(2));
      expect(find.byKey(ValueKey('weight-entry-${fixtureId(1)}')), findsOne);

      await swipeAway(tester, 1);
      expect((await rig.live(tester)).map((w) => w.id), [fixtureId(2)]);
      await unmount(tester, rig);
    });

    testWidgets('A65 review 4 a refused deletion says the weigh-in changed '
        '(not that it was deleted) and the row stays usable', (tester) async {
      final actions = _RefuseFirstDelete();
      final rig = await pumpWithRig(
        tester,
        [
          weighInDraft(97, date: day17.plusDays(-2)),
          weighInDraft(96.8, date: day17),
        ],
        height: 2400,
        extra: [weighInActionsProvider.overrideWith(() => actions)],
      );
      await swipeAway(tester, 1);
      expect(find.text(_l10n.weightEntryDeleteChanged), findsOneWidget);
      expect(find.text(_l10n.weighInRemoved), findsNothing);
      expect((await rig.live(tester)).map((w) => w.id), hasLength(2));
      final row = find.byKey(ValueKey('weight-entry-${fixtureId(1)}'));
      expect(row, findsOne);

      // Still usable: the same row swipes away for real now.
      await swipeAway(tester, 1);
      expect((await rig.live(tester)).map((w) => w.id), [fixtureId(2)]);
      await unmount(tester, rig);
    });

    testWidgets('A65 M3 Add past weigh-ins is a labelled row, not an icon', (
      tester,
    ) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17),
      ], height: 2400);
      expect(find.byKey(const ValueKey('weight-graph-history')), findsOne);
      expect(find.byIcon(FbIcons.diary), findsNothing);
      await unmount(tester, rig);
    });

    testWidgets('WB-022 Edit opens the weigh-in sheet in edit mode', (
      tester,
    ) async {
      final rig = await pumpWithRig(tester, [
        weighInDraft(97, date: day17.plusDays(-2)),
        weighInDraft(96.8, date: day17),
      ]);
      await selectPoint(tester, fixtureId(2));
      await tester.tap(button('Edit'));
      await settle(tester);
      expect(find.byType(WeighInSheet), findsOneWidget);
      expect(find.text('Edit weigh-in'), findsOneWidget);
      await unmount(tester, rig);
    });
  });
}
