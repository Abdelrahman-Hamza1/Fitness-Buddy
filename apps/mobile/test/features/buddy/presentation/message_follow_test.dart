import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/buddy/presentation/composer.dart';
import 'package:fb_mobile/features/buddy/presentation/message_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../packages/fb_domain/test/proposals/proposal_fixtures.dart'
    as f;
import '../../../helpers/layout_stability.dart';
import '../support/buddy_harness.dart';
import '../support/buddy_widgets.dart';

// A57 WP6 (T-B3, T-B4): the thread follows only a reader at the bottom,
// reopens at the latest turn, and the follow-up chip never moves the
// composer.

/// The sheet open with three cards in the thread, none followed up.
Future<BuddyHarness> _threeCards(WidgetTester tester) async {
  final h = BuddyHarness()..answer(f.message());
  await pumpBuddyHost(tester, h);
  await openBuddySheet(tester);
  for (var i = 0; i < 3; i++) {
    await sendInSheet(tester, 'egg $i');
    await settleBuddy(tester);
    h.thread.clearFollowUp();
    await tester.pumpAndSettle();
  }
  return h;
}

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(BuddyMessageList),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

bool _atBottom(WidgetTester tester) {
  final p = _position(tester);
  return p.maxScrollExtent - p.pixels <= BuddyMessageList.followSlack;
}

/// Whether the new-message button is shown (not just kept for its exit).
bool _pillShown(WidgetTester tester) => find
    .byKey(BuddyMessageList.newMessagesKey)
    .hitTestable()
    .evaluate()
    .isNotEmpty;

void main() {
  testWidgets('A57 T-B3 A66 reopening the sheet shows the latest turn', (
    tester,
  ) async {
    final h = await _threeCards(tester);
    // Closed (back) and opened again: the in-memory thread is kept.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BuddyMessageList), findsNothing);
    await openBuddySheet(tester);
    await settleBuddy(tester);
    expect(_position(tester).maxScrollExtent, greaterThan(0));
    expect(_atBottom(tester), isTrue);
    await unmountBuddy(tester, h);
  });

  testWidgets('A57 T-B3 A67 a reply while the reader is scrolled up does '
      'not move the thread; New message jumps down', (tester) async {
    final h = await _threeCards(tester);

    // Sending follows the reader's own message.
    await sendInSheet(tester, 'one more egg');
    await tester.pump();
    await tester.pump();
    expect(_atBottom(tester), isTrue);

    // The reader scrolls up before the reply lands.
    _position(tester).jumpTo(0);
    await tester.pump();
    await settleBuddy(tester);
    expect(_position(tester).pixels, 0, reason: 'not followed');
    expect(_pillShown(tester), isTrue);

    await tester.tap(find.byKey(BuddyMessageList.newMessagesKey));
    await tester.pumpAndSettle();
    await tester.pump();
    expect(_atBottom(tester), isTrue);
    expect(_pillShown(tester), isFalse);
    await unmountBuddy(tester, h);
  });

  testWidgets('A57 T-B4 A08 UX-045 the follow-up chip reveals above the '
      'composer without moving it', (tester) async {
    for (final scale in stabilityScales) {
      final h = BuddyHarness()..answer(f.message());
      await pumpBuddyHost(tester, h, textScale: scale);
      await openBuddySheet(tester);
      expect(find.byType(FbTargetChip).hitTestable(), findsNothing);
      await expectStable(
        tester,
        find.byType(BuddyComposer),
        () async {
          await sendInSheet(tester, '2 eggs');
          await settleBuddy(tester);
          expect(find.byType(FbTargetChip), findsOneWidget);
        },
        anchor: find.byType(BuddyComposer),
        reason: 'chip shows at $scale',
      );
      await expectStable(
        tester,
        find.byType(BuddyComposer),
        () async {
          h.thread.clearFollowUp();
          await tester.pumpAndSettle();
          expect(find.byType(FbTargetChip), findsNothing);
        },
        anchor: find.byType(BuddyComposer),
        reason: 'chip hides at $scale',
      );
      await unmountBuddy(tester, h);
    }
  });
}
