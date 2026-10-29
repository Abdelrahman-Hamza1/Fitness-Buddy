import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('UX-071 FbBrandMark and FbBuddyAvatar add no semantics node; '
      'FbBrandLockup is its own header node announcing the name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    const plain = Key('plain');
    await pumpFb(
      tester,
      const Column(
        children: [
          SizedBox(key: plain, width: 10, height: 10),
          FbBrandMark(key: Key('mark')),
          FbBrandMark(key: Key('cropped'), cropped: true),
          FbBuddyAvatar(key: Key('avatar')),
          Text('More text below'),
          FbBrandLockup(name: 'Fitness Buddy'),
          Text('Version 1'),
        ],
      ),
    );
    // A plain box has no node of its own, so it resolves to the enclosing
    // node; the mark and the avatar must resolve to the very same node.
    final enclosing = tester.getSemantics(find.byKey(plain));
    for (final key in ['mark', 'cropped', 'avatar']) {
      final finder = find.byKey(Key(key));
      expect(tester.getSemantics(finder).id, enclosing.id, reason: key);
    }
    final lockup = find.byType(FbBrandLockup);
    final node = tester.getSemantics(lockup);
    expect(node.id, isNot(enclosing.id));
    expect(node, matchesSemantics(label: 'Fitness Buddy', isHeader: true));
    expect(node.childrenCount, 0);
    expect(find.bySemanticsLabel('Fitness Buddy'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('HM-008 the input bar shows the Buddy avatar at the start, is '
      'at least 52 dp tall and keeps the hint clear of its end', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await pumpFb(
        tester,
        Padding(
          padding: const EdgeInsetsDirectional.all(FbSpace.s4),
          child: FbInputBar(hint: 'Tell Buddy what you ate', onTap: () {}),
        ),
        direction: direction,
      );
      final bar = tester.getRect(find.byType(FbInputBar));
      expect(bar.height, greaterThanOrEqualTo(52));
      final avatar = tester.getRect(find.byType(FbBuddyAvatar));
      final hint = tester.getRect(find.text('Tell Buddy what you ate'));
      // Without trailing buttons the hint keeps 16 dp from the pill's end.
      if (direction == TextDirection.ltr) {
        expect(avatar.right, lessThan(hint.left));
        expect(avatar.left - bar.left, lessThan(FbSpace.s4));
        expect(bar.right - hint.right, greaterThanOrEqualTo(FbSpace.s4));
      } else {
        expect(avatar.left, greaterThan(hint.right));
        expect(bar.right - avatar.right, lessThan(FbSpace.s4));
        expect(hint.left - bar.left, greaterThanOrEqualTo(FbSpace.s4));
      }
      expect(avatar.size, const Size(28, 28));
    }
  });

  testWidgets("A22 UX-071 Buddy's bubble shows the avatar at its start, "
      'outside the read-out label, and the composer is at least 52 dp tall', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final direction in TextDirection.values) {
      await pumpFb(
        tester,
        Column(
          children: [
            const FbMessageBubble(
              text: 'Got it.',
              fromUser: false,
              semanticLabel: 'Buddy: Got it.',
              leading: FbBuddyAvatar(size: 24),
            ),
            FbComposer(
              controller: TextEditingController(),
              hint: 'Message Buddy',
              sendTooltip: 'Send',
              onSend: () {},
            ),
          ],
        ),
        direction: direction,
      );
      final avatar = tester.getRect(find.byType(FbBuddyAvatar));
      final text = tester.getRect(find.text('Got it.'));
      expect(avatar.size, const Size(24, 24));
      if (direction == TextDirection.ltr) {
        expect(avatar.right, lessThan(text.left));
      } else {
        expect(avatar.left, greaterThan(text.right));
      }
      expect(
        tester.getSemantics(find.byType(FbMessageBubble)),
        matchesSemantics(label: 'Buddy: Got it.'),
      );
      expect(
        tester.getSize(find.byType(FbComposer)).height,
        greaterThanOrEqualTo(FbInputBar.minHeight),
      );
    }
    handle.dispose();
  });
}
