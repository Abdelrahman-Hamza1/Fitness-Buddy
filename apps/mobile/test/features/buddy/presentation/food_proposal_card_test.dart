import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/buddy/application/food_card_view.dart';
import 'package:fb_mobile/features/buddy/presentation/cards/food_proposal_card.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    as f;
import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

/// An unmatched item Buddy estimated: 50 g at 100–200 kcal per 100 g.
Map<String, Object?> estimateItem() => f.item(amount: 50, unit: 'g')
  ..['match'] = null
  ..['estimate'] = {
    'range': {'low': f.n(100), 'high': f.n(200)},
    'reason': 'noMatch',
  };

/// Two weighed rice lines and an egg that may have been cooked in oil: two
/// questions (the rice states) and one assumption chip (the oil).
Map<String, Object?> riceAndEgg() => f.message([
  f.intent([
    f.riceItem(),
    f.item(dimensions: [f.fatDimension()]),
    f.riceItem(amount: 100),
  ]),
]);

/// Sends [body]'s message through the sheet and settles.
Future<BuddyHarness> showCard(
  WidgetTester tester,
  Map<String, Object?> body, {
  double textScale = 1,
}) async {
  final h = BuddyHarness()..answer(body);
  await pumpBuddyHost(tester, h, textScale: textScale);
  await openBuddySheet(tester);
  await sendInSheet(tester, '2 eggs');
  await settleBuddy(tester);
  return h;
}

/// Scrolls [finder] into the sheet's view, then taps it.
Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  // rule: A22 assumption-chip
  testWidgets('AI-033 tapping an assumption chip shows alternatives and '
      'recomputes', (tester) async {
    final h = await showCard(tester, riceAndEgg());
    expect(find.byType(FbAssumptionChip), findsOneWidget);
    // The pencil says it can be changed; a screen reader hears what it is
    // and what a tap does.
    final chip = tester.widget<FbAssumptionChip>(find.byType(FbAssumptionChip));
    expect(chip.semanticLabel, 'Assumption: ${chip.label}');
    expect(chip.tapHint, 'change it');
    expect(
      find.descendant(
        of: find.byType(FbAssumptionChip),
        matching: find.byIcon(FbIcons.edit),
      ),
      findsOneWidget,
    );
    final before = h.state.turns.single.cards.single.card.totals.kcal;
    await tapInSheet(tester, find.byType(FbAssumptionChip));
    await tester.pumpAndSettle();
    expect(find.text('Change the assumption'), findsOneWidget);
    expect(find.text('No oil'), findsWidgets);
    expect(find.text('1 tbsp of oil'), findsOneWidget);
    await tester.tap(find.text('1 tbsp of oil'));
    await tester.pumpAndSettle();
    final after = h.state.turns.single.cards.single.card.totals.kcal;
    expect(after, isNot(before));
    expect(find.text('1 tbsp of oil'), findsOneWidget); // The chip now.
    expect(await h.entries(), isEmpty); // AI-036: nothing written.
    await unmountBuddy(tester, h);
  });

  // rule: A22 log-collapse
  testWidgets('AI-035 log it collapses the card with a one-line reply and '
      'undo', (tester) async {
    final h = await showCard(tester, message());
    await tapInSheet(tester, find.text('Log it'));
    await settleBuddy(tester);
    expect(find.text('Log it'), findsNothing);
    expect(find.text('Logged 72 kcal · 72 eaten today'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Undo'), findsOneWidget);
    expect(await h.entries(), hasLength(1));
    await unmountBuddy(tester, h);
  });

  // rule: A23 undo-reopens
  testWidgets('A23 undo opens the logged card again with Log it', (
    tester,
  ) async {
    final h = await showCard(tester, message());
    await tapInSheet(tester, find.text('Log it'));
    await settleBuddy(tester);
    await tapInSheet(tester, find.text('Undo'));
    await settleBuddy(tester);
    // A23 D10: pending again, as it was before Log it.
    expect(find.text('Log it'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    expect((await h.entries()).where((e) => e.deletedAt == null), isEmpty);
    await tapInSheet(tester, find.text('Log it'));
    await settleBuddy(tester);
    expect(find.text('Logged 72 kcal · 72 eaten today'), findsOneWidget);
    await unmountBuddy(tester, h);
  });

  // rule: A22 confirm-disabled
  testWidgets('A22 concurrent confirm applies once: log it is disabled while '
      'confirming', (tester) async {
    final h = await showCard(tester, message());
    final card = h.state.turns.single.cards.single;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          theme: FbTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FbLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: SingleChildScrollView(
              child: FoodProposalCard(
                view: FoodCardView.of(
                  card.copyWith(resolution: CardResolution.confirming),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final logIt = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Log it').first,
    );
    expect(logIt.onPressed, isNull);
    expect(find.text('Logging…'), findsOneWidget);
    final discard = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Discard').first,
    );
    expect(discard.onPressed, isNull);
    await unmountBuddy(tester, h);
  });
}
