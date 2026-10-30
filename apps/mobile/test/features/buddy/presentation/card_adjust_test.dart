import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    as f;
import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

Map<String, Object?> _named(String key, String name, {double kcal = 144}) => {
  ...f.food(key: key, kcal: kcal),
  'nameEn': name,
};

Future<BuddyHarness> _showCard(
  WidgetTester tester,
  Map<String, Object?> body,
) async {
  final h = BuddyHarness()..answer(body);
  await pumpBuddyHost(tester, h);
  await openBuddySheet(tester);
  await sendInSheet(tester, '2 eggs');
  await settleBuddy(tester);
  return h;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  // rule: A22b stepper
  testWidgets('AI-040 stepper on assumed lines updates totals live', (
    tester,
  ) async {
    final h = await _showCard(
      tester,
      f.message([
        f.intent([
          f.item(explicit: false),
          f.item(match: _named('usda:bread', 'Bread', kcal: 250)),
        ]),
      ]),
    );
    // Only the assumed amount gets − / +; at 1 piece − still halves it.
    expect(find.byTooltip('More Synthetic food'), findsOneWidget);
    expect(find.byTooltip('More Bread'), findsNothing);
    final before = h.state.turns.single.cards.single.card.totals.kcal;
    await _tap(tester, find.byTooltip('More Synthetic food'));
    final card = h.state.turns.single.cards.single;
    expect(card.card.lines.first.entry.amount.input.amount, 2);
    expect(card.card.totals.kcal, before + 72);
    expect(card.changeToken, isNotNull);
    expect(card.card.lines.first.amountAssumed, isTrue);
    // Nothing is written by an adjustment (AI-036).
    expect(h.applied, hasLength(2));
    await unmountBuddy(tester, h);
  });

  // rule: A22b swipe-remove
  testWidgets('AI-042 swipe removes a line and undo restores it', (
    tester,
  ) async {
    final h = await _showCard(
      tester,
      f.message([
        f.intent([
          f.item(),
          f.item(match: _named('usda:bread', 'Bread', kcal: 250)),
        ]),
      ]),
    );
    await tester.ensureVisible(find.text('Bread'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Bread'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Removed Bread'), findsOneWidget);
    expect(h.state.turns.single.cards.single.card.lines, hasLength(1));
    await _tap(tester, find.text('Undo'));
    expect(find.text('Removed Bread'), findsNothing);
    expect(find.text('Bread'), findsOneWidget);
    expect(h.state.turns.single.cards.single.card.lines, hasLength(2));
    await unmountBuddy(tester, h);
  });

  // rule: A22b swap
  testWidgets('AI-041 name tap offers at most three distinct alternatives '
      'and UX-022 never opens a full-screen form', (tester) async {
    final h = await _showCard(
      tester,
      f.message([
        f.intent([
          f.item(
            alternatives: [
              _named('usda:brown_egg', 'Brown egg'),
              _named('usda:duck_egg', 'Duck egg', kcal: 185),
            ],
          ),
        ]),
      ]),
    );
    final routes = find.byType(Scaffold).evaluate().length;
    await _tap(tester, find.text('Synthetic food'));
    expect(find.text('Swap Synthetic food for'), findsOneWidget);
    expect(find.text('Brown egg'), findsOneWidget);
    expect(find.text('Duck egg'), findsOneWidget);
    // A small sheet over the card, not a new screen.
    expect(find.byType(Scaffold).evaluate().length, routes);
    await _tap(tester, find.text('Duck egg'));
    final line = h.state.turns.single.cards.single.card.lines.single;
    expect(line.entry.food.names.en, 'Duck egg');
    expect(find.text('Duck egg'), findsOneWidget);
    await unmountBuddy(tester, h);
  });

  // rule: A22b when
  testWidgets('AI-043 slot and time can be changed on the card', (
    tester,
  ) async {
    final h = await _showCard(tester, f.message());
    await _tap(tester, find.text('Breakfast · 8:00 AM'));
    expect(find.text('Meal and time'), findsOneWidget);
    await _tap(tester, find.text('Lunch').last);
    expect(find.text('Lunch · 8:00 AM'), findsOneWidget);
    final card = h.state.turns.single.cards.single.card;
    expect(card.lines.single.entry.slotId, isNot(isEmpty));
    expect(h.applied, hasLength(2));
    await unmountBuddy(tester, h);
  });

  // rule: A22b amount-pad-ui
  testWidgets('AI-040 tapping an amount opens the number pad inside the card '
      'and UX-022 no form', (tester) async {
    final h = await _showCard(tester, f.message());
    final routes = find.byType(Scaffold).evaluate().length;
    await _tap(tester, find.text('1 piece (50 g)'));
    final pad = find.byType(FbNumberPad);
    expect(pad, findsOneWidget);
    expect(find.byType(FbUnitPicker), findsOneWidget);
    expect(find.byType(Scaffold).evaluate().length, routes);
    await _tap(tester, find.descendant(of: pad, matching: find.text('3')));
    final line = h.state.turns.single.cards.single.card.lines.single;
    expect(line.entry.amount.input.amount, 3);
    // An incomplete value shows as typed; the card keeps the last valid one.
    await _tap(tester, find.descendant(of: pad, matching: find.text('.')));
    expect(find.textContaining('3. '), findsOneWidget);
    expect(
      h
          .state
          .turns
          .single
          .cards
          .single
          .card
          .lines
          .single
          .entry
          .amount
          .input
          .amount,
      3,
    );
    expect(h.applied, hasLength(2));
    await unmountBuddy(tester, h);
  });

  // rule: A22b add-item-ui
  testWidgets('AI-042 the card offers Add item', (tester) async {
    final h = await _showCard(tester, f.message());
    expect(find.text('Add item'), findsOneWidget);
    await unmountBuddy(tester, h);
  });
}
