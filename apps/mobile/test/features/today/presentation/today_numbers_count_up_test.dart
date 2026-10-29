import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';
import 'support/today_targets_support.dart';

/// No targets: Today shows kcal eaten.
final List<Override> _overrides = numbersOverrides(weekSat, null);

Widget _block(double kcal, {bool still = false}) => ProviderScope(
  overrides: _overrides,
  child: phoneApp(
    Material(
      child: TodayNumbers(
        date: weekSat,
        isToday: true,
        totals: eatenTotals(kcal),
      ),
    ),
    disableAnimations: still,
  ),
);

/// The big number's text as drawn now.
String _shown(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .firstWhere((t) => RegExp(r'^[0-9,]+$').hasMatch(t));

void main() {
  // rule: A22 count-up
  testWidgets('UX-025 confirming animates the Today number and is instant '
      'with animations off', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_block(1000));
    await tester.pump();
    expect(_shown(tester), '1,000');
    await tester.pumpWidget(_block(1200));
    await tester.pump(const Duration(milliseconds: 100));
    // Counting: between the old and the new total.
    expect(_shown(tester), isNot(anyOf('1,000', '1,200')));
    await tester.pumpAndSettle();
    expect(_shown(tester), '1,200');

    await tester.pumpWidget(_block(1200, still: true));
    await tester.pumpWidget(_block(1500, still: true));
    await tester.pump();
    expect(_shown(tester), '1,500');
  });
}
