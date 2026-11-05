import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Map<String, Object?> body, {
  FoodNameLanguage? names,
}) async {
  final h = BuddyHarness(
    overrides: [
      if (names != null)
        foodNameSettingProvider.overrideWith((ref) => Stream.value(names)),
    ],
  )..answer(body);
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

  // T-N2 (Buddy part): names are data, not UI copy.
  testWidgets('A57 T-N2 LC-007 Buddy rows, Less/More labels and the removed '
      'line follow the Arabic setting; Both shows two lines', (tester) async {
    final body = f.message([
      f.intent([
        f.item(),
        f.item(match: {..._named('usda:bread', 'Bread'), 'nameAr': 'خبز'}),
      ]),
    ]);
    var h = await _showCard(tester, body, names: FoodNameLanguage.arabic);
    expect(find.text('خبز'), findsOneWidget);
    expect(find.text('Bread'), findsNothing);
    await tester.ensureVisible(find.text('خبز'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('خبز'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    final removed = tester.widget<FbProposalResolvedRow>(
      find.byType(FbProposalResolvedRow),
    );
    expect(removed.text, contains('\u2068خبز\u2069'));
    expect(removed.text, isNot(contains('Bread')));
    await unmountBuddy(tester, h);

    h = await _showCard(tester, body, names: FoodNameLanguage.both);
    final line = tester.widget<FbProposalLine>(
      find.ancestor(
        of: find.text('Bread'),
        matching: find.byType(FbProposalLine),
      ),
    );
    expect(line.name, 'Bread');
    expect(line.secondaryName, 'خبز');
    await unmountBuddy(tester, h);
  });
}
