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
}
