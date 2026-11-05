import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../features/foods/presentation/support/personal_food_support.dart'
    show settle, useWindow;
import '../helpers/pump_app.dart';
import 'support/acceptance_app.dart';

void main() {
  // A57 P1 (Patrol app_test): reproduced on the host first.
  testWidgets('A57 P1 UX-050 a fresh install shows the calories chart empty '
      'state on Progress, below the fold of a phone', (tester) async {
    useWindow(tester, width: 411, height: 914);
    final container = await pumpApp(
      tester,
      overrides: [...acceptanceOverrides()],
    );
    container.read(appRouterProvider).go(const ProgressRoute());
    await settle(tester);
    expect(find.byType(ProgressScreen), findsOneWidget);
    final calories = find.byKey(const ValueKey('progress-calories-chart'));
    await tester.scrollUntilVisible(
      calories,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.descendant(of: calories, matching: find.byIcon(FbIcons.chart)),
      findsOneWidget,
    );
  });
}
