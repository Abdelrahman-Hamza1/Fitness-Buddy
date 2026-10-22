import 'package:fb_design_system/fb_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump.dart';

void main() {
  testWidgets('FD-022 AI-040 amount display: reads as one labelled '
      'node and taps', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpFb(
      tester,
      FbAmountDisplay(
        amount: '1.5',
        unit: 'loaves',
        semanticLabel: 'Amount, 1.5 loaves',
        active: true,
        onTap: () => taps++,
      ),
    );

    final node = tester.getSemantics(find.byType(FbAmountDisplay));
    expect(node.label, 'Amount, 1.5 loaves');
    expect(find.textContaining('1.5', findRichText: true), findsOneWidget);

    await tester.tap(find.byType(FbAmountDisplay));
    expect(taps, 1);
    expect(find.byIcon(FbIcons.edit), findsOneWidget);
    await pumpFb(
      tester,
      const FbAmountDisplay(
        amount: '100',
        unit: 'g',
        semanticLabel: 'Amount, 100 g',
      ),
    );
    expect(find.byIcon(FbIcons.edit), findsNothing);
    handle.dispose();
  });
}
