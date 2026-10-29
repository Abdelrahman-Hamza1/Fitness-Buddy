import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/buddy_fixtures.dart';
import 'support/buddy_harness.dart';
import 'support/buddy_widgets.dart';

/// Scrolls [finder] into the sheet's view, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Sends [text] in the sheet with its recorded answer and settles.
Future<BuddyHarness> _journey(WidgetTester tester, String text) async {
  final h = BuddyHarness()..answer(buddyFixtureFor(text)!);
  await pumpBuddyHost(tester, h);
  await openBuddySheet(tester);
  await sendInSheet(tester, text);
  await settleBuddy(tester);
  return h;
}

void main() {
  // rule: A22 recorded-fixtures
  test('A22 recorded fixtures are contract valid and build without '
      'issues', () async {
    for (final text in [j1Text, j2Text, j3Text]) {
      final body = buddyFixtureFor(text)!;
      // The generated model accepts it (contract-valid).
      expect(BuddyInterpretation.fromJson(body).intents, isNotEmpty);
      // The real send path turns it into cards with no issue.
      final h = BuddyHarness()..answer(body);
      await h.thread.send(text, texts);
      final turn = h.state.turns.single;
      expect(turn.cards, isNotEmpty, reason: text);
      for (final card in turn.cards) {
        expect(card.card.issues, isEmpty, reason: text);
        expect(card.card.canConfirm, isTrue, reason: text);
      }
      expect(h.issues, isEmpty, reason: text);
    }
  });

  // rule: A22 journey-j1
  testWidgets('AI-030 J1 home-cooked weighed meal asks two questions then '
      'logs', (tester) async {
    final h = await _journey(tester, j1Text);
    expect(find.text('Rice with chicken'), findsOneWidget);
    expect(find.textContaining('weighed?'), findsOneWidget);
    expect(find.text('Any cooking oil?'), findsOneWidget);
    expect(find.text('Default'), findsNWidgets(2));
    // Answer: the rice was weighed cooked.
    await _tap(tester, find.widgetWithText(FbAnswerChip, 'Cooked'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Log it'));
    await settleBuddy(tester);
    final entries = await h.entries();
    expect(entries, hasLength(2));
    expect(
      entries.map((e) => e.foodId),
      containsAll([
        'usda:rice_white_long_grain_cooked',
        'usda:chicken_breast_roasted',
      ]),
    );
    expect(find.textContaining('Logged '), findsOneWidget);
    await unmountBuddy(tester, h);
  });

  // rule: A22 journey-j2
  testWidgets('AI-032 J2 family plate is an estimate with a range then logs', (
    tester,
  ) async {
    final h = await _journey(tester, j2Text);
    await _tap(tester, find.byType(FbEstimateMarker).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('–'), findsWidgets);
    expect(
      find.text("Buddy's estimate: no close match in the food database."),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Log it'));
    await settleBuddy(tester);
    final entries = await h.entries();
    expect(entries.single.isEstimate, isTrue);
    expect(entries.single.estimateRangeJson, isNotNull);
    await unmountBuddy(tester, h);
  });

  // rule: A22 journey-j3
  testWidgets('AI-140 AI-143 J3 eating out in Arabic logs with an English '
      'reply', (tester) async {
    final h = await _journey(tester, j3Text);
    expect(find.text(j3Text, skipOffstage: false), findsOneWidget);
    // The reply is the fixed English line (stored; not drawn above cards).
    expect(
      (await h.chat()).singleWhere((r) => r.role == 'assistant').messageText,
      "Here's your meal. Check it, then tap Log it.",
    );
    await _tap(tester, find.text('Log it'));
    await settleBuddy(tester);
    expect(await h.entries(), hasLength(2));
    expect(find.textContaining('Logged '), findsOneWidget);
    expect(find.textContaining('eaten today'), findsOneWidget);
    // The user's row records what they wrote (ar), the reply is English.
    final rows = await h.chat();
    expect(rows.firstWhere((r) => r.role == 'user').language, 'ar');
    expect(rows.firstWhere((r) => r.role == 'assistant').language, 'en');
    await unmountBuddy(tester, h);
  });
}
