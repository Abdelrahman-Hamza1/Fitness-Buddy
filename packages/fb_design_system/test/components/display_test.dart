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
  group('buttons', () {
    testWidgets('UX-021 primary button is visually dominant (filled) and '
        'disabled without onPressed', (tester) async {
      var taps = 0;
      await pumpFb(
        tester,
        Column(
          children: [
            FbButton.primary(label: 'Save', onPressed: () => taps++),
            FbButton.secondary(label: 'Cancel', onPressed: () {}),
            FbButton.text(label: 'Skip', onPressed: () {}, icon: FbIcons.add),
            const FbButton.primary(label: 'Off', onPressed: null),
          ],
        ),
      );
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
      await tester.tap(find.text('Save'));
      expect(taps, 1);
      final off = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Off'),
      );
      expect(off.onPressed, isNull);
    });

    testWidgets('UX-021 expand fills the width', (tester) async {
      await pumpFb(
        tester,
        FbButton.primary(label: 'Wide', onPressed: () {}, expand: true),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 360);
    });
  });

  group('big number', () {
    testWidgets('HM-001 big number shows the over state in the neutral tone, '
        'without an error colour or warning icon', (tester) async {
      await pumpFb(
        tester,
        const FbBigNumber(value: '212', caption: 'kcal over', over: true),
      );
      final text = tester.widget<Text>(find.text('212'));
      final theme = Theme.of(tester.element(find.text('212')));
      expect(text.style!.color, _colors(tester, find.text('212')).overTarget);
      expect(text.style!.color, isNot(theme.colorScheme.error));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('HM-001 under target uses the normal text colour', (
      tester,
    ) async {
      await pumpFb(
        tester,
        const FbBigNumber(value: '640', caption: 'kcal left'),
      );
      final theme = Theme.of(tester.element(find.text('640')));
      expect(
        tester.widget<Text>(find.text('640')).style!.color,
        theme.colorScheme.onSurface,
      );
    });

    testWidgets('UX-070 big number clamps its text scale to 1.5 and never '
        'overflows at 2.0', (tester) async {
      await pumpFb(
        tester,
        const FbBigNumber(value: '1,234,567', caption: 'kcal left'),
        textScale: 2,
        width: 200,
      );
      final number = tester.element(find.text('1,234,567'));
      expect(MediaQuery.textScalerOf(number).scale(10), 15);
      final caption = tester.element(find.text('kcal left'));
      expect(MediaQuery.textScalerOf(caption).scale(10), 20);
      expect(tester.takeException(), isNull);
      // It scaled down to fit instead of overflowing.
      expect(
        tester.getSize(find.byType(FittedBox)).width,
        lessThanOrEqualTo(200),
      );
    });
  });

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

    testWidgets('SF-021 under target uses the brand and macro colours at the '
        'right width', (tester) async {
      await pumpFb(
        tester,
        const Column(
          children: [
            FbProgressBar(value: 900, target: 1800),
            FbMacroBars(
              macros: [
                FbMacroValue(
                  kind: FbMacroKind.carbs,
                  value: 50,
                  target: 100,
                  label: 'Carbs',
                  valueText: '50 / 100 g',
                ),
              ],
            ),
          ],
        ),
      );
      final colors = _colors(tester, find.byType(FbMacroBars));
      expect(_hasFill(tester, find.byType(FbMacroBars), colors.carbs), isTrue);
      final scheme = Theme.of(tester.element(find.byType(FbProgressBar)))
          .colorScheme;
      expect(
        _hasFill(tester, find.byType(FbProgressBar), scheme.primary),
        isTrue,
      );
      final fill = tester.getSize(
        find.descendant(
          of: find.byType(FbProgressBar),
          matching: find.byType(AnimatedFractionallySizedBox),
        ),
      );
      expect(
        fill.width,
        closeTo(tester.getSize(find.byType(FbProgressBar)).width / 2, 0.5),
      );
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

    testWidgets('UX-070 a macro row keeps its amounts on one line at the end; '
        'at large text they go under the label', (tester) async {
      // Four macros, so the long amount can't fit a compact column and the
      // bars fall back to rows (A44 PA3).
      const bars = FbMacroBars(
        macros: [
          FbMacroValue(
            kind: FbMacroKind.protein,
            value: 82,
            target: 140,
            label: 'Protein',
            valueText: '1,082 / 1,140 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.carbs,
            value: 120,
            target: 220,
            label: 'Carbs',
            valueText: '120 / 220 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.fat,
            value: 30,
            target: 70,
            label: 'Fat',
            valueText: '30 / 70 g',
          ),
          FbMacroValue(
            kind: FbMacroKind.fiber,
            value: 12,
            target: 30,
            label: 'Fiber',
            valueText: '12 / 30 g',
          ),
        ],
      );
      final amounts = find.text('1,082 / 1,140 g');
      double lineHeight() => tester.getSize(find.text('Protein')).height;

      await pumpFb(tester, bars, width: 320);
      // Same line as the label, ending at the end, never wrapped.
      expect(
        tester.getCenter(amounts).dy,
        closeTo(tester.getCenter(find.text('Protein')).dy, 4),
      );
      expect(tester.getTopRight(amounts).dx, 320);
      expect(tester.getSize(amounts).height, lessThan(lineHeight() * 1.5));

      await pumpFb(tester, bars, width: 320, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(amounts).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('Protein')).dy),
      );
      expect(tester.getTopRight(amounts).dx, 320);
    });
  });

  group('source badges', () {
    testWidgets('FD-010 each source shows its own badge letter', (
      tester,
    ) async {
      await pumpFb(
        tester,
        Row(
          children: [for (final s in FbSource.values) FbSourceBadge(source: s)],
        ),
      );
      for (final letter in ['Y', 'D', 'R', '~']) {
        expect(find.text(letter), findsOneWidget);
      }
    });

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

    testWidgets('UX-044 the badge is a 16 dp monochrome outlined circle', (
      tester,
    ) async {
      await pumpFb(tester, const FbSourceBadge(source: FbSource.yours));
      const key = ValueKey('fb-source-badge-circle');
      final deco =
          tester.widget<DecoratedBox>(find.byKey(key)).decoration
              as BoxDecoration;
      expect(deco.shape, BoxShape.circle);
      expect(
        deco.border!.top.color,
        _colors(tester, find.byType(FbSourceBadge)).badge,
      );
      expect(tester.getSize(find.byKey(key)), const Size(16, 16));
    });

    testWidgets('UX-044 the estimate marker and the badge both have a touch '
        'area of at least 24 x 24 dp', (tester) async {
      await pumpFb(
        tester,
        const Column(
          children: [
            FbSourceBadge(source: FbSource.yours),
            FbEstimateMarker(rangeText: '1 to 2 kcal', reason: 'Guess'),
          ],
        ),
      );
      for (final type in [FbSourceBadge, FbEstimateMarker]) {
        final size = tester.getSize(find.byType(type));
        expect(size.width, greaterThanOrEqualTo(24), reason: '$type width');
        expect(size.height, greaterThanOrEqualTo(24), reason: '$type height');
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
    testWidgets('AI-034 answer chip marks the default answer', (tester) async {
      await pumpFb(
        tester,
        Column(
          children: [
            FbAnswerChip(label: 'Small', onTap: () {}, isDefault: true),
            FbAnswerChip(label: 'Large', onTap: () {}, selected: true),
          ],
        ),
      );
      expect(find.text('Default'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Large'))
            .selected,
        isTrue,
      );
      expect(find.bySemanticsLabel('Small, Default'), findsOneWidget);
    });

    testWidgets('AI-034 answer chip calls onTap', (tester) async {
      var taps = 0;
      await pumpFb(tester, FbAnswerChip(label: 'Small', onTap: () => taps++));
      await tester.tap(find.byType(FbAnswerChip));
      expect(taps, 1);
    });

    testWidgets('AI-033 assumption chip calls onTap', (tester) async {
      var taps = 0;
      await pumpFb(
        tester,
        FbAssumptionChip(label: '1 tbsp oil', onTap: () => taps++),
      );
      await tester.tap(find.byType(FbAssumptionChip));
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

    testWidgets('DY-030 a quick-add chip shows its icon and says its '
        'semantic label instead of the bare name', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpFb(
        tester,
        FbQuickAddChip(
          label: 'Usual breakfast',
          icon: FbIcons.meal,
          semanticLabel: 'Log Usual breakfast',
          onTap: () {},
        ),
      );
      expect(find.byIcon(FbIcons.meal), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(FbQuickAddChip)),
        isSemantics(
          label: 'Log Usual breakfast',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('UX-070 a long quick-add label is cut with an ellipsis and '
        'never wider than the screen, also at text scale 2.0', (tester) async {
      for (final scale in [1.0, 2.0]) {
        await pumpFb(
          tester,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FbQuickAddChip(
              label: 'x' * 200,
              icon: FbIcons.meal,
              onTap: () {},
            ),
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(FbQuickAddChip)).width,
          lessThanOrEqualTo(360 * 0.7 + 120),
        );
        expect(
          tester.widget<Text>(find.text('x' * 200)).overflow,
          TextOverflow.ellipsis,
        );
      }
    });

    testWidgets('DY-030 HM-008 the quick-add row puts the chips first and '
        'the plus chip last, and mirrors in RTL', (tester) async {
      var added = 0;
      Widget row() => FbQuickAddRow(
        chips: [
          FbQuickAddChip(label: 'Labaneh', onTap: () {}),
          FbQuickAddChip(label: 'Coffee', onTap: () {}),
        ],
        addLabel: 'Add food',
        onAdd: () => added++,
      );
      await pumpFb(tester, row());
      final labaneh = tester.getCenter(find.text('Labaneh')).dx;
      final coffee = tester.getCenter(find.text('Coffee')).dx;
      final plus = tester.getCenter(find.text('Add food')).dx;
      expect(labaneh, lessThan(coffee));
      expect(coffee, lessThan(plus));
      // Starts one screen padding from the start edge.
      expect(
        tester.getTopLeft(find.byType(FbQuickAddChip).first).dx,
        FbSpace.s4,
      );
      await tester.tap(find.byType(FbQuickAddChip).last);
      expect(added, 1);

      await pumpFb(tester, row(), direction: TextDirection.rtl);
      expect(
        tester.getCenter(find.text('Labaneh')).dx,
        greaterThan(tester.getCenter(find.text('Coffee')).dx),
      );
      expect(
        tester.getCenter(find.text('Add food')).dx,
        lessThan(tester.getCenter(find.text('Coffee')).dx),
      );
    });

    testWidgets('DY-030 the quick-add row scrolls sideways instead of '
        'overflowing', (tester) async {
      await pumpFb(
        tester,
        FbQuickAddRow(
          chips: [
            for (var i = 0; i < 6; i++)
              FbQuickAddChip(label: 'Food number $i', onTap: () {}),
          ],
          addLabel: 'Add food',
          onAdd: () {},
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(FbQuickAddRow), const Offset(-2000, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Add food'), findsOneWidget);
    });

    testWidgets('UX-040 an icon button is labelled by its tooltip and is '
        'disabled without a handler', (tester) async {
      var pressed = 0;
      await pumpFb(
        tester,
        Row(
          children: [
            FbIconButton(
              icon: FbIcons.edit,
              tooltip: 'Rename',
              onPressed: () => pressed++,
            ),
            const FbIconButton(
              icon: FbIcons.delete,
              tooltip: 'Delete',
              onPressed: null,
            ),
          ],
        ),
      );
      await tester.tap(find.byTooltip('Rename'));
      await tester.tap(find.byTooltip('Delete'));
      expect(pressed, 1);
      expect(find.byTooltip('Delete'), findsOneWidget);
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

    testWidgets('UX-051 skeleton pulses when animations are enabled', (
      tester,
    ) async {
      await pumpFb(tester, const FbSkeleton.line(), disableAnimations: false);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.binding.hasScheduledFrame, isTrue);
      final opacity = tester
          .widgetList<FadeTransition>(
            find.descendant(
              of: find.byType(FbSkeleton),
              matching: find.byType(FadeTransition),
            ),
          )
          .first;
      expect(opacity.opacity.value, lessThan(1));
      // Dispose before the test ends so the repeating ticker stops.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('UX-052 UX-053 inline banners render each kind with its '
        'message and action', (tester) async {
      var taps = 0;
      await pumpFb(
        tester,
        Column(
          children: [
            for (final kind in FbInlineBannerKind.values)
              FbInlineBanner(
                kind: kind,
                message: 'msg ${kind.name}',
                actionLabel: 'Retry ${kind.name}',
                onAction: () => taps++,
              ),
            const FbInlineBanner(
              kind: FbInlineBannerKind.info,
              message: 'plain',
            ),
          ],
        ),
      );
      for (final kind in FbInlineBannerKind.values) {
        expect(find.text('msg ${kind.name}'), findsOneWidget);
        expect(find.text('Retry ${kind.name}'), findsOneWidget);
      }
      expect(find.byType(TextButton), findsNWidgets(4));
      await tester.tap(find.text('Retry error'));
      expect(taps, 1);
      expect(find.byIcon(FbIcons.offline), findsOneWidget);
      expect(find.byIcon(FbIcons.pending), findsOneWidget);
      expect(find.byIcon(FbIcons.error), findsOneWidget);
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
