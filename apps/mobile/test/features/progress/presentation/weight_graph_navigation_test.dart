import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('UX-013 the Progress tab Weight row opens the weight graph, and '
      'Back returns to Progress', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weight graph'));
    await tester.pumpAndSettle();
    expect(find.byType(WeightGraphScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WeightGraphScreen), findsNothing);
    expect(find.byType(ProgressScreen), findsOneWidget);
    await unmountApp(tester, container);
  });
}
