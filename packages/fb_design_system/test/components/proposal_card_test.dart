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
}
