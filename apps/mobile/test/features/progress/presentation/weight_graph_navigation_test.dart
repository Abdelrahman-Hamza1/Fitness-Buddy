import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('UX-013 the Progress tab weight section opens the weight graph, '
      'and Back returns to Progress', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();
    // The weight section sits below the calories and macros charts (A16).
    final link = find.byKey(const ValueKey('progress-full-graph'));
    await tester.scrollUntilVisible(
      link,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(link);
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
