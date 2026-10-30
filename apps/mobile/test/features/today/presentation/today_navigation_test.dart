import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/presentation/day_page.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/today_support.dart';

Future<void> pumpToday(WidgetTester tester, List<Override> overrides) async {
  usePhone(tester);
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: phoneApp(const TodayScreen())),
  );
  await tester.pump();
}

LocalDate shownDate(WidgetTester tester) =>
    tester.widget<DayPage>(find.byType(DayPage)).date;

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TodayScreen)));

Finder get skeleton => find.byType(FbSkeleton);

void main() {
  testWidgets('HM-009 swiping on the numbers goes to yesterday; › is '
      'disabled on today', (tester) async {
    await pumpToday(tester, fakeToday());
    IconButton next() => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, FbIcons.next),
    );
    expect(next().onPressed, isNull);
    expect(find.text('Today'), findsOneWidget);

    await tester.drag(find.text('kcal eaten'), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Yesterday'), findsOneWidget);
    expect(shownDate(tester), testYesterday);
    expect(next().onPressed, isNotNull);
    // Back with › ; nothing exists after today.
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    await tester.drag(find.text('kcal eaten'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(shownDate(tester), testToday);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('HM-009 the date tap opens the picker and jumps; no day after '
      'today can be picked', (tester) async {
    await pumpToday(tester, fakeToday());

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsOneWidget);
    // Oct 18 is disabled: tapping it changes nothing.
    await tester.tap(find.text('18'));
    await tester.pump();
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(shownDate(tester), LocalDate(2026, 10, 10));
    expect(find.text('Sat, Oct 10'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
  });

  testWidgets('UX-053 a day that cannot be read shows a calm banner with '
      'Try again', (tester) async {
    var fail = true;
    await pumpToday(tester, [
      ...fakeToday(fakeDays: false),
      dayProvider.overrideWith(
        (ref, date) => fail
            ? Stream<DiaryDay>.error(StateError('boom'))
            : Stream.value(fakeDay(date)),
      ),
      dayViewProvider.overrideWith(
        (ref, date) => ref.watch(dayProvider(date)).whenData(fakeView),
      ),
    ]);
    await tester.pump();

    expect(find.text("Couldn't load this day."), findsOneWidget);
    expect(skeleton, findsNothing);

    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't load this day."), findsNothing);
    expect(find.text('Breakfast'), findsOneWidget);
  });

  group('time', () {
    testWidgets('D4 coming back to the front asks for today again', (
      tester,
    ) async {
      var builds = 0;
      await pumpToday(tester, [
        ...fakeToday(liveToday: true),
        todayProvider.overrideWith((ref) {
          builds++;
          return Stream.value(testToday);
        }),
      ]);
      await tester.pump();
      final before = builds;

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(builds, before + 1);
    });
  });
}
