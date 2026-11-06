import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('UX-047 A63 D5 a notice row runs its action from the button or '
      'the row, and its × separately', (tester) async {
    final log = <String>[];
    await pumpFb(
      tester,
      FbNoticeRow(
        icon: FbIcons.info,
        text: 'Weekly check-in · new target 2,050',
        actionLabel: 'Review',
        onAction: () => log.add('action'),
        dismissTooltip: 'Not now',
        onDismiss: () => log.add('dismiss'),
      ),
    );
    await tester.tap(find.text('Review'));
    await tester.tap(find.byIcon(FbIcons.info));
    await tester.tap(find.byTooltip('Not now'));
    expect(log, ['action', 'action', 'dismiss']);
  });

  testWidgets('UX-047 A63 D5 onTap replaces the action for a row tap; the row '
      'is at least 48 dp and one line at 1.0, two at 2.0', (tester) async {
    final log = <String>[];
    Widget row() => FbNoticeRow(
      key: const ValueKey('row'),
      icon: FbIcons.info,
      text: 'A notice that is much too long to fit on a single line here',
      actionLabel: 'Review',
      onAction: () => log.add('action'),
      onTap: () => log.add('tap'),
    );
    await pumpFb(tester, row());
    await tester.tap(find.byIcon(FbIcons.info));
    expect(log, ['tap']);
    expect(
      tester.getSize(find.byKey(const ValueKey('row'))).height,
      greaterThanOrEqualTo(48),
    );
    Text text() => tester.widget<Text>(find.textContaining('A notice'));
    expect(text().maxLines, 1);

    await pumpFb(tester, row(), textScale: 2);
    expect(text().maxLines, 2);
    expect(tester.takeException(), isNull);
  });
}
