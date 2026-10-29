import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

Widget _card({VoidCallback? onConfirm, String? reason}) => FbProposalCard(
  header: 'Breakfast · 08:40',
  title: 'Eggs with oil',
  details: const Text('details'),
  assumptions: [FbAssumptionChip(label: 'chip', onTap: () {})],
  questions: const Text('question'),
  impact: const Text('impact'),
  actions: FbProposalActions(
    discardLabel: 'Discard',
    confirmLabel: 'Log it',
    onDiscard: () {},
    onConfirm: onConfirm,
    reason: reason,
  ),
);

void main() {
  // rule: A22 card-shell
  testWidgets('UX-020 UX-021 UX-026 proposal card shell keeps the part order', (
    tester,
  ) async {
    await pumpFb(tester, SingleChildScrollView(child: _card(onConfirm: () {})));
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    final order = [
      'Breakfast · 08:40',
      'Eggs with oil',
      'details',
      'chip',
      'question',
      'impact',
      'Log it',
    ].map(top).toList();
    for (var i = 1; i < order.length; i++) {
      expect(order[i], greaterThan(order[i - 1]), reason: 'part $i');
    }
    // The primary action is the filled, dominant button.
    expect(find.widgetWithText(OutlinedButton, 'Discard'), findsOneWidget);
    expect(tester.getSize(find.text('Log it')).width, greaterThan(0));
    expect(find.byType(FilledButton), findsOneWidget);
  });

  // rule: A22 card-shell
  testWidgets('AI-030 the skeleton card is a calm placeholder', (tester) async {
    await pumpFb(tester, const FbProposalCard.skeleton());
    expect(find.byType(FbSkeleton), findsNWidgets(5));
    expect(find.byType(FilledButton), findsNothing);
  });

  // rule: A22 confirm-disabled
  testWidgets('A22 primary action is disabled with a one-line reason and '
      'stacks at large text', (tester) async {
    await pumpFb(
      tester,
      SingleChildScrollView(child: _card(reason: 'Add an amount')),
      textScale: 2,
    );
    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(filled.onPressed, isNull);
    expect(find.text('Add an amount'), findsOneWidget);
    // Stacked: primary on top of Discard.
    expect(
      tester.getTopLeft(find.text('Log it')).dy,
      lessThan(tester.getTopLeft(find.text('Discard')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  // rule: A22 resolved-row
  testWidgets('AI-035 the resolved row offers at most one undo', (
    tester,
  ) async {
    var undos = 0;
    await pumpFb(
      tester,
      Column(
        children: [
          FbProposalResolvedRow(
            icon: FbIcons.check,
            text: 'Logged ✓ 191 kcal · 1,240 left today',
            undoLabel: 'Undo',
            onUndo: () => undos++,
          ),
          const FbProposalResolvedRow(icon: FbIcons.info, text: 'Undone'),
        ],
      ),
    );
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undos, 1);
  });

  // rule: A22 highlight
  testWidgets('UX-024 change highlight tints on a new token and fades', (
    tester,
  ) async {
    Color? tint() {
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(FbChangeHighlight),
          matching: find.byType(DecoratedBox),
        ),
      );
      return (box.decoration as BoxDecoration).color;
    }

    Future<void> show(Object? token, {bool still = false}) => pumpFb(
      tester,
      FbChangeHighlight(token: token, child: const Text('line')),
      disableAnimations: still,
    );

    await show(null);
    expect(tint()!.a, 0);
    await show(1);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tint()!.a, greaterThan(0));
    await tester.pump(FbChangeHighlight.duration);
    expect(tint()!.a, 0);
    // Reduced motion: full tint without fading, then gone.
    await show(2, still: true);
    await tester.pump(const Duration(milliseconds: 600));
    final still = tint()!.a;
    await tester.pump(const Duration(milliseconds: 300));
    expect(tint()!.a, still);
    await tester.pump(FbChangeHighlight.duration);
    expect(tint()!.a, 0);
  });

  // rule: A22 composer
  testWidgets('A22 composer sends only non-blank text and keeps focus', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var sends = 0;
    await pumpFb(
      tester,
      FbComposer(
        controller: controller,
        focusNode: focus,
        autofocus: true,
        hint: 'Tell Buddy',
        sendTooltip: 'Send',
        onSend: () => sends++,
      ),
    );
    IconButton send() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(FbIcons.send),
        matching: find.byType(IconButton),
      ),
    );
    expect(send().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(send().onPressed, isNull);
    await tester.enterText(find.byType(TextField), '2 eggs');
    await tester.pump();
    expect(send().onPressed, isNotNull);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(sends, 1);
    expect(focus.hasFocus, isTrue);
  });

  // rule: A22 count-up
  testWidgets('UX-025 counting big number counts to the new value', (
    tester,
  ) async {
    Widget number(double count) => FbBigNumber.counting(
      count: count,
      format: (v) => v.round().toString(),
      caption: 'kcal eaten',
    );
    await pumpFb(tester, number(100), disableAnimations: false);
    expect(find.text('100'), findsOneWidget);
    await pumpFb(tester, number(200), disableAnimations: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('200'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
    expect(tester.widget<FbBigNumber>(find.byType(FbBigNumber)).value, '200');
  });
}
