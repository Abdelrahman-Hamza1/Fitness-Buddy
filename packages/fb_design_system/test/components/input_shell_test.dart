import 'dart:io';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

NumberPadBuffer _press(NumberPadBuffer b, String keys) {
  var buffer = b;
  for (final c in keys.split('')) {
    buffer = buffer.apply(switch (c) {
      '.' => NumberPadKey.decimal,
      '<' => NumberPadKey.backspace,
      _ => NumberPadKey.digit(int.parse(c)),
    });
  }
  return buffer;
}

void main() {
  group('number pad', () {
    // keys (< = backspace) -> expected text and value, with
    // maxDigits 3 and maxDecimals 2.
    const table = <(String, String, double?)>[
      ('', '', null),
      ('1', '1', 1),
      ('123', '123', 123),
      ('1234', '123', 123), // max digits
      ('0', '0', 0),
      ('00', '0', 0), // no leading zeros
      ('05', '5', 5),
      ('.', '0.', 0),
      ('1.5', '1.5', 1.5),
      ('1..5', '1.5', 1.5), // one point
      ('1.234', '1.23', 1.23), // max decimals
      ('1234.5', '123.5', 123.5), // digits capped, decimals still allowed
      ('12<', '1', 1),
      ('1<', '', null),
      ('1.<', '1', 1),
      ('<', '', null),
      ('0.5<<', '0', 0),
    ];
    for (final (keys, text, value) in table) {
      test('AI-040 NumberPadBuffer "$keys" gives "$text"', () {
        final b = _press(
          const NumberPadBuffer(maxDigits: 3, maxDecimals: 2),
          keys,
        );
        expect(b.text, text);
        expect(b.value, value);
        expect(b.isEmpty, text.isEmpty);
      });
    }

    test('AI-040 NumberPadBuffer: zero decimals disallows the point', () {
      final b = _press(const NumberPadBuffer(maxDecimals: 0), '1.5');
      expect(b.text, '15');
    });

    testWidgets('AI-040 number pad keys and unit picker selection reach '
        'their callbacks', (tester) async {
      final keys = <NumberPadKey>[];
      var done = 0;
      String? unit;
      await pumpFb(
        tester,
        Column(
          children: [
            FbNumberPad(onKey: keys.add, onDone: () => done++),
            FbUnitPicker(
              units: const [
                FbUnitOption(id: 'g', label: 'g'),
                FbUnitOption(id: 'ml', label: 'ml'),
              ],
              selected: 'g',
              onSelected: (id) => unit = id,
            ),
          ],
        ),
      );
      await tester.tap(find.text('7'));
      await tester.tap(find.text('.'));
      await tester.tap(find.byIcon(FbIcons.backspace));
      await tester.tap(find.text('Done'));
      await tester.tap(find.text('ml'));
      expect(keys, [
        const NumberPadKey.digit(7),
        NumberPadKey.decimal,
        NumberPadKey.backspace,
      ]);
      expect(done, 1);
      expect(unit, 'ml');
      expect(find.bySemanticsLabel('Delete last digit'), findsOneWidget);
      expect(find.bySemanticsLabel('Decimal point'), findsOneWidget);
    });
  });

  group('snackbars', () {
    Future<void> show(
      WidgetTester tester,
      void Function(BuildContext) action, {
      bool accessible = false,
    }) async {
      await pumpFb(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => action(context),
            child: const Text('go'),
          ),
        ),
        accessibleNavigation: accessible,
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('UX-030 undo snackbar shows the message, calls onUndo once '
        'on Undo, closes after 5 s', (tester) async {
      var undone = 0;
      await show(
        tester,
        (c) => showFbUndoSnackBar(c, message: 'Logged', onUndo: () => undone++),
      );
      expect(find.text('Logged'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Logged'), findsNothing);
    });

    testWidgets('UX-030 undo snackbar closes after the 5 s window', (
      tester,
    ) async {
      await show(
        tester,
        (c) => showFbUndoSnackBar(c, message: 'Logged', onUndo: () {}),
      );
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Logged'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Logged'), findsNothing);
    });

    testWidgets('UX-030 undo snackbar close() dismisses it without calling '
        'onUndo', (tester) async {
      var undone = 0;
      late FbSnackBarHandle handle;
      await show(
        tester,
        (c) => handle = showFbUndoSnackBar(
          c,
          message: 'Logged',
          onUndo: () => undone++,
        ),
      );
      handle.close();
      await tester.pumpAndSettle();
      expect(find.text('Logged'), findsNothing);
      expect(undone, 0);
    });

    testWidgets('UX-030 / WCAG 2.2.1 with accessibleNavigation the undo '
        'snackbar is not auto-dismissed', (tester) async {
      await show(
        tester,
        (c) => showFbUndoSnackBar(c, message: 'Logged', onUndo: () {}),
        accessible: true,
      );
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Logged'), findsOneWidget);
    });

    testWidgets('UX-030 / WCAG 2.2.1 with accessibleNavigation the plain '
        'snackbar is not auto-dismissed, otherwise it is', (tester) async {
      await show(tester, (c) => showFbSnackBar(c, 'Hello'), accessible: true);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('showFbSnackBar closes by itself without a screen reader', (
      tester,
    ) async {
      await show(tester, (c) => showFbSnackBar(c, 'Hello'));
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsNothing);
    });

    testWidgets('showFbSnackBar shows a message with no action', (
      tester,
    ) async {
      await show(tester, (c) => showFbSnackBar(c, 'Cannot undo anymore'));
      expect(find.text('Cannot undo anymore'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });

  group('shell', () {
    testWidgets('HM-008 input bar taps and optional buttons', (tester) async {
      var taps = 0;
      var cam = 0;
      await pumpFb(
        tester,
        Column(
          children: [
            FbInputBar(
              hint: 'Tell Buddy',
              onTap: () => taps++,
              onCamera: () => cam++,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Tell Buddy'));
      await tester.tap(find.byIcon(FbIcons.camera));
      expect((taps, cam), (1, 1));
      expect(find.byIcon(FbIcons.barcode), findsNothing);
    });

    for (final dir in TextDirection.values) {
      testWidgets('HM-009 date header previous/next call back, next disabled '
          'when null, chevrons mirror in RTL ($dir)', (tester) async {
        var prev = 0;
        var next = 0;
        await pumpFb(
          tester,
          FbDateHeader(
            label: 'Today',
            onPrevious: () => prev++,
            onNext: () => next++,
          ),
          direction: dir,
        );
        await tester.tap(find.byTooltip('Previous day'));
        await tester.tap(find.byTooltip('Next day'));
        expect((prev, next), (1, 1));
        final p = tester.getCenter(find.byTooltip('Previous day')).dx;
        final n = tester.getCenter(find.byTooltip('Next day')).dx;
        expect(p < n, dir == TextDirection.ltr);
        for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
          expect(icon.icon!.matchTextDirection, isTrue);
        }
        await pumpFb(
          tester,
          FbDateHeader(label: 'Today', onPrevious: () {}),
          direction: dir,
        );
        final button = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, FbIcons.next),
        );
        expect(button.onPressed, isNull);
      });
    }

    testWidgets('UX-011 sheet shell shows a drag handle and its title', (
      tester,
    ) async {
      await pumpFb(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showFbSheet<void>(
              context,
              title: 'Pick one',
              builder: (_) => const Text('body'),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(find.bySemanticsLabel('Drag handle'), findsOneWidget);
    });
  });

  group('chart', () {
    testWidgets('IN-004 chart placeholder keeps its aspect ratio and accepts '
        'series, bands and a goal line', (tester) async {
      final t0 = DateTime.utc(2026, 10);
      await pumpFb(
        tester,
        FbTimeSeriesChart(
          range: FbChartRange(start: t0, end: t0.add(const Duration(days: 30))),
          series: [
            FbSeries(
              points: [
                FbPoint(t0, 80),
                FbPoint(t0.add(const Duration(days: 1)), 79.5),
              ],
            ),
            FbSeries(style: FbSeriesStyle.points, points: [FbPoint(t0, 80.2)]),
          ],
          bands: [
            FbBand(points: [FbBandPoint(t0, lower: 79, upper: 81)]),
          ],
          goal: const FbGoalLine(value: 75, label: 'Goal'),
          tooltip: (p) => '${p.value}',
          aspectRatio: 2,
        ),
      );
      final size = tester.getSize(find.byType(FbTimeSeriesChart));
      expect(size.width / size.height, closeTo(2, 0.01));
      expect(find.text('Chart coming soon'), findsOneWidget);
    });
  });

  group('package', () {
    test('barrel exports every public component', () {
      // A missing export fails to compile: every public type is named here.
      final types = <Type>[
        FbBigNumber,
        FbButton,
        FbCard,
        FbAssumptionChip,
        FbAnswerChip,
        FbQuickAddChip,
        FbEmptyState,
        FbEstimateMarker,
        FbInlineBanner,
        FbInlineBannerKind,
        FbListRow,
        FbMacroBars,
        FbMacroValue,
        FbProgressBar,
        FbSource,
        FbMacroKind,
        FbSectionHeader,
        FbSheet,
        FbSkeleton,
        FbSourceBadge,
        NumberPadBuffer,
        NumberPadKey,
        FbNumberPad,
        FbUnitPicker,
        FbUnitOption,
        FbInputBar,
        FbSnackBarHandle,
        FbDateHeader,
        FbTimeSeriesChart,
        FbPoint,
        FbSeries,
        FbSeriesStyle,
        FbBand,
        FbBandPoint,
        FbGoalLine,
        FbChartRange,
        FbTheme,
        FbColors,
        FbType,
        FbSpace,
        FbRadius,
        FbMotion,
        FbIcons,
        FbLocalizations,
      ];
      // Every public class in lib/src/components and charts is in the list.
      final names = types.map((t) => t.toString()).toSet();
      final declared = <String>{};
      for (final dir in ['lib/src/components', 'lib/src/charts']) {
        for (final f in Directory(dir).listSync().whereType<File>()) {
          declared.addAll(
            RegExp(
              r'^(?:abstract |final |sealed )*(?:class|enum) (Fb\w+)',
              multiLine: true,
            ).allMatches(f.readAsStringSync()).map((m) => m.group(1)!),
          );
        }
      }
      // FbBarTrack is the progress bars' internal building block; the two
      // sheet bodies are public only for the goldens (not in the barrel).
      const internal = {
        'FbBarTrack',
        'FbSourceLegendBody',
        'FbEstimateRangeBody',
      };
      expect(declared.difference(names).difference(internal), isEmpty);
    });

    test('LC-002 every built-in component string comes from '
        'FbLocalizations', () {
      final sources = Directory('lib/src')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      final all = sources.map((f) => f.readAsStringSync()).join('\n');
      // 1. No literal with a letter is rendered: Text('..'), tooltip: '..',
      //    label: '..', semanticLabel: '..' (single-character glyphs such as
      //    digits and '.' on the number pad are not words).
      final literal = RegExp(
        r"(?:Text\(|tooltip:|label:|semanticLabel:|hintText:)\s*'[^'$]*[A-Za-z]{2,}[^']*'",
      );
      final offenders = literal.allMatches(all).map((m) => m.group(0)).toList();
      expect(offenders, isEmpty);
      // 2. Every ARB key is used by a component.
      final arb = File('lib/l10n/fb_ds_en.arb').readAsStringSync();
      final keys = RegExp(
        r'^\s*"(fb\w+)":',
        multiLine: true,
      ).allMatches(arb).map((m) => m.group(1)!);
      final unused = keys.where((k) => !all.contains('.$k')).toList();
      expect(unused, isEmpty);
    });
  });
}
