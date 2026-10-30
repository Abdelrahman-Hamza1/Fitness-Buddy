import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_design_system/src/components/progress_bar.dart'
    show FbBarTrack, fbBarFill;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

/// The colour of the first DecoratedBox/ColoredBox fill with [color] below
/// [root]: bars are drawn with ColoredBox.
bool _hasFill(WidgetTester tester, Finder root, Color color) => tester
    .widgetList<ColoredBox>(
      find.descendant(of: root, matching: find.byType(ColoredBox)),
    )
    .any((b) => b.color == color);

FbColors _colors(WidgetTester tester, Finder f) =>
    Theme.of(tester.element(f)).extension<FbColors>()!;

void main() {
  group('bars', () {
    testWidgets('SF-021 progress and macro bars above target fill with '
        'overTarget, never ColorScheme.error', (tester) async {
      await pumpFb(
        tester,
        const Column(
          children: [
            FbProgressBar(value: 2200, target: 1800),
            FbMacroBars(
              macros: [
                FbMacroValue(
                  kind: FbMacroKind.protein,
                  value: 160,
                  target: 140,
                  label: 'Protein',
                  valueText: '20 g over',
                ),
              ],
            ),
          ],
        ),
      );
      final colors = _colors(tester, find.byType(FbProgressBar));
      final scheme = Theme.of(tester.element(find.byType(FbProgressBar)))
          .colorScheme;
      for (final bar in [
        find.byType(FbProgressBar),
        find.byType(FbMacroBars),
      ]) {
        expect(_hasFill(tester, bar, colors.overTarget), isTrue);
        expect(_hasFill(tester, bar, scheme.error), isFalse);
        expect(_hasFill(tester, bar, colors.protein), isFalse);
      }
      final fill = tester.getSize(
        find.descendant(
          of: find.byType(FbProgressBar),
          matching: find.byType(AnimatedFractionallySizedBox),
        ),
      );
      final track = tester.getSize(
        find.descendant(
          of: find.byType(FbProgressBar),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(fill.width, track.width);
    });

    test('SF-021 fbBarFill: a zero target is empty, over is full and '
        'flagged', () {
      expect(fbBarFill(5, 0), (fraction: 0.0, over: false));
      expect(fbBarFill(-1, 10), (fraction: 0.0, over: false));
      expect(fbBarFill(5, 10), (fraction: 0.5, over: false));
      expect(fbBarFill(10, 10), (fraction: 1.0, over: false));
      expect(fbBarFill(11, 10), (fraction: 1.0, over: true));
    });

    testWidgets('UX-071 macro bars always show a text label next to each '
        'colour', (tester) async {
      const macros = [
        FbMacroValue(
          kind: FbMacroKind.protein,
          value: 1,
          target: 2,
          label: 'Protein',
          valueText: '1 / 2 g',
        ),
        FbMacroValue(
          kind: FbMacroKind.carbs,
          value: 1,
          target: 2,
          label: 'Carbs',
          valueText: '1 / 2 g',
        ),
        FbMacroValue(
          kind: FbMacroKind.fat,
          value: 1,
          target: 2,
          label: 'Fat',
          valueText: '1 / 2 g',
        ),
        FbMacroValue(
          kind: FbMacroKind.fiber,
          value: 1,
          target: 2,
          label: 'Fibre',
          valueText: '1 / 2 g',
        ),
      ];
      await pumpFb(tester, const FbMacroBars(macros: macros));
      for (final m in macros) {
        expect(find.text(m.label), findsOneWidget);
      }
      expect(find.text('1 / 2 g'), findsNWidgets(4));
      // Each label sits above its bar.
      final labelBottom = tester.getBottomLeft(find.text('Protein')).dy;
      final firstBar = tester.getTopLeft(find.byType(ClipRRect).first).dy;
      expect(labelBottom, lessThanOrEqualTo(firstBar));
    });

    testWidgets('HM-003 FbMacroValue without a target shows text and no '
        'track', (tester) async {
      await pumpFb(
        tester,
        const FbMacroBars(
          macros: [
            FbMacroValue(
              kind: FbMacroKind.protein,
              value: 82,
              target: 140,
              label: 'Protein',
              valueText: '82 / 140 g',
            ),
            FbMacroValue(
              kind: FbMacroKind.carbs,
              value: 96,
              label: 'Carbs',
              valueText: '96 g',
            ),
          ],
        ),
      );
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('96 g'), findsOneWidget);
      // One track: the protein bar's. The carbs row draws none.
      expect(find.byType(FbBarTrack), findsOneWidget);
      final colors = _colors(tester, find.byType(FbMacroBars));
      expect(_hasFill(tester, find.byType(FbMacroBars), colors.carbs), isFalse);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Carbs, 96 g')),
        isNotNull,
      );
    });
  });

  group('source badges', () {
    testWidgets('UX-044 tapping a source badge opens the legend with all '
        'four sources', (tester) async {
      await pumpFb(tester, const FbSourceBadge(source: FbSource.database));
      await tester.tap(find.byType(FbSourceBadge));
      await tester.pumpAndSettle();
      for (final t in [
        'Where numbers come from',
        'Yours',
        'Food database',
        'Reference dish',
        'Estimate',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
    });

    testWidgets('AI-032 tapping the estimate marker shows the range and the '
        'reason', (tester) async {
      await pumpFb(
        tester,
        const FbEstimateMarker(
          rangeText: '450 to 650 kcal',
          reason: 'Portion size is a guess',
        ),
      );
      await tester.tap(find.byType(FbEstimateMarker));
      await tester.pumpAndSettle();
      expect(find.text('450 to 650 kcal'), findsOneWidget);
      expect(find.text('Portion size is a guess'), findsOneWidget);
      expect(find.text('Estimate'), findsOneWidget);
    });

    testWidgets('SF-041 estimate marker is present for the estimate source', (
      tester,
    ) async {
      await pumpFb(
        tester,
        const Column(
          children: [
            FbSourceBadge(source: FbSource.estimate),
            FbEstimateMarker(rangeText: '1', reason: 'r'),
          ],
        ),
      );
      expect(find.text('~'), findsNWidgets(2));
    });
  });

  group('chips', () {
    testWidgets('AI-034 answer chip calls onTap', (tester) async {
      var taps = 0;
      await pumpFb(tester, FbAnswerChip(label: 'Small', onTap: () => taps++));
      await tester.tap(find.byType(FbAnswerChip));
      expect(taps, 1);
    });

    testWidgets('DY-030 quick-add chips call onTap, .add shows a plus', (
      tester,
    ) async {
      var taps = 0;
      await pumpFb(
        tester,
        Column(
          children: [
            FbQuickAddChip(label: 'Coffee', onTap: () => taps++),
            FbQuickAddChip.add(label: 'Banana', onTap: () => taps++),
          ],
        ),
      );
      await tester.tap(find.byType(FbQuickAddChip).first);
      await tester.tap(find.byType(FbQuickAddChip).last);
      expect(taps, 2);
      expect(find.byIcon(FbIcons.add), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('UX-050 empty state shows title, message and the optional '
        'action', (tester) async {
      await pumpFb(
        tester,
        FbEmptyState(
          icon: FbIcons.empty,
          title: 'Nothing yet',
          message: 'Log your first meal.',
          action: FbButton.primary(label: 'Log it', onPressed: () {}),
        ),
      );
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Log your first meal.'), findsOneWidget);
      expect(find.text('Log it'), findsOneWidget);
      await pumpFb(
        tester,
        const FbEmptyState(icon: FbIcons.empty, title: 'T', message: 'M'),
      );
      expect(find.byType(FbButton), findsNothing);
    });

    testWidgets('UX-051 skeleton is static when animations are disabled', (
      tester,
    ) async {
      await pumpFb(
        tester,
        const Column(
          children: [
            FbSkeleton.line(),
            FbSkeleton.box(width: 40, height: 40),
            FbSkeleton.card(),
          ],
        ),
      );
      Iterable<double> opacities() => tester
          .widgetList<FadeTransition>(
            find.descendant(
              of: find.byType(FbSkeleton),
              matching: find.byType(FadeTransition),
            ),
          )
          .map((f) => f.opacity.value);
      expect(opacities(), everyElement(1.0));
      await tester.pump(const Duration(milliseconds: 600));
      expect(opacities(), everyElement(1.0));
      // Nothing keeps asking for frames: this would time out otherwise.
      await tester.pumpAndSettle();
    });
  });

  group('rendering', () {
    for (final (name, brightness, direction) in [
      ('light LTR', Brightness.light, TextDirection.ltr),
      ('dark RTL', Brightness.dark, TextDirection.rtl),
    ]) {
      testWidgets('UX-040 every display component renders at 2.0 ($name)', (
        tester,
      ) async {
        await pumpFb(
          tester,
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FbSectionHeader(title: 'Today', trailing: Text('All')),
                FbCard(onTap: () {}, child: const Text('Card')),
                const FbListRow(
                  title: 'A very long food name that wraps over lines',
                  subtitle: 'sub',
                  leading: Icon(FbIcons.today),
                  trailing: FbSourceBadge(source: FbSource.yours),
                ),
                const FbBigNumber(value: '1,240', caption: 'kcal left'),
                const FbProgressBar(value: 1, target: 2),
                const FbMacroBars(
                  macros: [
                    FbMacroValue(
                      kind: FbMacroKind.fiber,
                      value: 1,
                      target: 2,
                      label: 'Fibre',
                      valueText: '1 / 2 g',
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    FbAssumptionChip(label: 'Assuming one', onTap: () {}),
                    FbAnswerChip(label: 'Yes', onTap: () {}, isDefault: true),
                    FbQuickAddChip.add(label: 'Coffee', onTap: () {}),
                  ],
                ),
                const FbInlineBanner(
                  kind: FbInlineBannerKind.offline,
                  message: 'You are offline. Buddy needs a connection.',
                ),
                const FbSkeleton.card(),
              ],
            ),
          ),
          brightness: brightness,
          direction: direction,
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
