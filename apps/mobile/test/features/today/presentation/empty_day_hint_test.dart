import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart'
    show EmptyDayHint;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart' show phoneApp;

void main() {
  for (final isToday in [true, false]) {
    testWidgets("UX-047 UX-050 T-X1 Today's empty day shows an inline helper, "
        'not a card (isToday: $isToday)', (tester) async {
      await tester.pumpWidget(
        phoneApp(Scaffold(body: EmptyDayHint(isToday: isToday))),
      );
      final hint = find.byKey(const ValueKey('today-empty-hint'));
      expect(hint, findsOneWidget);
      expect(find.byType(FbCard), findsNothing);
      expect(
        find.descendant(of: hint, matching: find.byType(Icon)),
        findsOneWidget,
      );
    });
  }
}
