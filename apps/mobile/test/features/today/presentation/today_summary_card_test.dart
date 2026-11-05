// Covers: HM-001, HM-002, HM-003, HM-004, HM-009, AI-045
import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/buddy/presentation/buddy_sheet.dart';
import 'package:fb_mobile/features/today/presentation/day_page.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';

Future<void> _pumpToday(WidgetTester tester, List<Override> overrides) async {
  usePhone(tester);
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: phoneApp(const TodayScreen())),
  );
  await tester.pump();
}

const ValueKey<String> _card = ValueKey('today-summary-card');

void main() {
  testWidgets('HM-001 A57 T-T1 Today has one calories card and no pager '
      'inside the day page', (tester) async {
    await _pumpToday(tester, fakeToday());
    final page = find.byType(DayPage);
    expect(find.descendant(of: page, matching: find.byKey(_card)), findsOne);
    expect(
      find.descendant(of: page, matching: find.byType(PageView)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: page,
        matching: find.byKey(const ValueKey('today-glance-line')),
      ),
      findsOne,
    );
  });

  testWidgets('HM-009 A57 T-T2 a swipe that starts on the card changes the '
      'day', (tester) async {
    await _pumpToday(tester, fakeToday());
    final start = tester.getCenter(find.byKey(_card));
    await tester.dragFrom(start, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<DayPage>(find.byType(DayPage)).date, testYesterday);
  });

  testWidgets('HM-004 AI-045 A57 T-B2 with cards waiting the Buddy bar shows '
      'the count and opens Buddy at them; none hides it', (tester) async {
    await _pumpToday(tester, fakeToday());
    const badge = ValueKey('today-buddy-waiting');
    expect(find.byKey(badge), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _pumpToday(tester, fakeToday(waiting: 2));
    await tester.pump();
    expect(find.byKey(badge), findsOneWidget);
    expect(tester.widget<FbInputBar>(find.byType(FbInputBar)).badge, isNotNull);
    await tester.tap(find.byType(FbInputBar));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BuddySheet>(find.byType(BuddySheet)).revealPending,
      isTrue,
    );
  });
}
