import 'package:fb_mobile/app/router/tab_tap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UX-010 A45 tab tap decision table', () {
    const goRoot = TabTapAction.goRoot;
    const keepStack = TabTapAction.keepStack;
    const confirm = TabTapAction.confirmThenRoot;
    const scrollTop = TabTapAction.scrollTop;
    // (sameTab, atRoot, holdsEdits) → action.
    final table = {
      (false, false, false): goRoot,
      (false, true, false): goRoot,
      (false, false, true): keepStack,
      (false, true, true): keepStack,
      (true, true, false): scrollTop,
      (true, true, true): scrollTop,
      (true, false, false): goRoot,
      (true, false, true): confirm,
    };
    expect(table, hasLength(8));
    for (final MapEntry(key: (sameTab, atRoot, holdsEdits), value: action)
        in table.entries) {
      expect(
        tabTapAction(sameTab: sameTab, atRoot: atRoot, holdsEdits: holdsEdits),
        action,
        reason: 'sameTab $sameTab, atRoot $atRoot, holdsEdits $holdsEdits',
      );
    }
  });
}
