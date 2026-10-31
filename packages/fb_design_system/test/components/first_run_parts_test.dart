import 'dart:ui' show Tristate;

import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('UX-060 FbStepBar fills up to the current step from the start '
      'edge and reads as one label', (tester) async {
    final handle = tester.ensureSemantics();
    Future<List<Color?>> colors(TextDirection direction) async {
      await pumpFb(
        tester,
        const FbStepBar(count: 4, current: 1, semanticsLabel: 'Step 2 of 4'),
        direction: direction,
      );
      final segments = find.byType(AnimatedContainer);
      expect(segments, findsNWidgets(4));
      // Left to right on screen.
      final byPosition = [
        for (var i = 0; i < 4; i++)
          (
            tester.getRect(segments.at(i)).left,
            tester.widget<AnimatedContainer>(segments.at(i)),
          ),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      return [
        for (final (_, w) in byPosition) (w.decoration! as BoxDecoration).color,
      ];
    }

    final ltr = await colors(TextDirection.ltr);
    final scheme = FbTheme.light().colorScheme;
    expect(ltr.take(2), everyElement(scheme.primary));
    expect(ltr.skip(2), everyElement(isNot(scheme.primary)));
    expect(find.bySemanticsLabel('Step 2 of 4'), findsOneWidget);
    final rtl = await colors(TextDirection.rtl);
    expect(rtl.reversed.take(2), everyElement(scheme.primary));
    handle.dispose();
  });

  testWidgets('UX-071 FbChoiceCard: a selected button in a group, 48 dp+, '
      'same size selected or not', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    Widget card({required bool selected}) => FbChoiceCard(
      title: 'Lose weight',
      subtitle: 'A steady, safe pace',
      icon: FbIcons.goalLose,
      selected: selected,
      onTap: () => taps++,
    );
    await pumpFb(tester, card(selected: false));
    final size = tester.getSize(find.byType(FbChoiceCard));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.text('Lose weight'));
    expect(taps, 1);
    await pumpFb(tester, card(selected: true));
    expect(tester.getSize(find.byType(FbChoiceCard)), size);
    expect(
      tester.getSemantics(find.byType(FbChoiceCard)),
      matchesSemantics(
        label: 'Lose weight\nA steady, safe pace',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('UX-071 FbSegmented picks one option; each segment is a '
      '48 dp selected-state button', (tester) async {
    final picked = <String>[];
    await pumpFb(
      tester,
      FbSegmented<String>(
        options: const [
          FbOption(value: 'm', label: 'Male'),
          FbOption(value: 'f', label: 'Female'),
        ],
        selected: 'm',
        onSelected: picked.add,
      ),
    );
    await tester.tap(find.text('Female'));
    expect(picked, ['f']);
    expect(
      tester
          .getSize(
            find.ancestor(
              of: find.text('Female'),
              matching: find.byType(InkWell),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
    final male = tester.getSemantics(find.text('Male'));
    expect(male.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('AC-001 FbCodeBoxes: a paste fills all boxes with digits only '
      'and completes once', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final done = <String>[];
    await pumpFb(
      tester,
      FbCodeBoxes(
        controller: controller,
        label: '6-digit code',
        onCompleted: done.add,
      ),
    );
    await tester.enterText(find.byType(TextField), '48');
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(done, isEmpty);
    // A pasted code with a space and extra text keeps the first six digits.
    await tester.enterText(find.byType(TextField), '481 920 ok 77');
    await tester.pump();
    expect(controller.text, '481920');
    expect(done, ['481920']);
    for (final digit in ['4', '8', '1', '9', '2', '0']) {
      expect(find.text(digit), findsWidgets);
    }
    // The error shows under the boxes.
    await pumpFb(
      tester,
      FbCodeBoxes(
        controller: controller,
        label: '6-digit code',
        errorText: 'That code is wrong.',
      ),
    );
    expect(find.text('That code is wrong.'), findsOneWidget);
    // Typing ignores letters.
    await tester.enterText(find.byType(TextField), 'ab12');
    expect(controller.text, '12');
    final formatters = tester
        .widget<TextField>(find.byType(TextField))
        .inputFormatters!;
    expect(formatters.whereType<FilteringTextInputFormatter>(), isNotEmpty);
  });

  testWidgets('AC-001 FbGoogleButton: one labelled button, neutral in light '
      'and dark, disabled without a callback', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    for (final brightness in Brightness.values) {
      await pumpFb(
        tester,
        FbGoogleButton(label: 'Continue with Google', onPressed: () => taps++),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FbGoogleButton));
      final fill = tester
          .widget<Material>(
            find.descendant(
              of: find.byType(FbGoogleButton),
              matching: find.byType(Material),
            ),
          )
          .color;
      expect(
        fill,
        brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF131314),
      );
      expect(
        tester.getSize(find.byType(FbGoogleButton)).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(taps, 2);
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget);
    // TalkBack can activate it.
    tester.semantics.tap(find.semantics.byLabel('Continue with Google'));
    expect(taps, 3);
    await pumpFb(
      tester,
      const FbGoogleButton(label: 'Continue with Google', onPressed: null),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel('Continue with Google'),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });
}
