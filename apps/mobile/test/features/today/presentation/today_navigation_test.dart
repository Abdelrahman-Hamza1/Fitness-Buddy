import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/today/presentation/day_page.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';
import '../../diary/support/diary_harness.dart';
import 'support/today_support.dart';
import 'today_actions_test.dart' show pumpRig, settle;

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

  testWidgets('HM-009 date picker starts at the first reachable pager day', (
    tester,
  ) async {
    await pumpToday(tester, fakeToday());
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    final first = DayPager(testToday).dateAt(0);
    expect(picker.firstDate, DateTime(first.year, first.month, first.day));
    expect(picker.lastDate, DateTime(2026, 10, 17));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    containerOf(tester).read(todayControllerProvider.notifier).goTo(first);
    await tester.pumpAndSettle();
    expect(shownDate(tester), first);
    await tester.tap(
      find
          .descendant(
            of: find.byType(FbDateHeader),
            matching: find.byType(Text),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendar.initialDate, picker.firstDate);
    // The first month cannot navigate to an earlier month.
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byType(CalendarDatePicker),
              matching: find.widgetWithIcon(IconButton, Icons.chevron_left),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('D3 swiping to a prefetched day shows no skeleton in any frame '
      '(W2)', (tester) async {
    final rig = TodayRig();
    await pumpRig(tester, rig);
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          newEntry(1, when: atDay(testYesterday), slotId: DefaultSlots.lunchId),
        ]),
      ]),
    );
    await settle(tester);
    expect(skeleton, findsNothing);

    // The incoming page is built from the first frame of the drag.
    final drag = await tester.startGesture(
      tester.getCenter(find.text('kcal eaten')),
    );
    for (var i = 0; i < 8; i++) {
      await drag.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 16));
      expect(skeleton, findsNothing, reason: 'frame $i of the drag');
    }
    await drag.up();
    while (tester.binding.hasScheduledFrame) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(skeleton, findsNothing);
    }
    expect(shownDate(tester), testYesterday);
    expect(find.text('300'), findsOneWidget);
  });

  testWidgets('UX-051 an uncached day shows slot skeletons until its data '
      'and renders it in the next frame (W2)', (tester) async {
    final rig = TodayRig();
    await pumpRig(tester, rig);
    await tester.runAsync(
      () => rig.diary.apply([
        LogEntries([
          newEntry(
            1,
            when: atDay(LocalDate(2026, 10, 10)),
            slotId: DefaultSlots.lunchId,
          ),
        ]),
      ]),
    );
    await settle(tester);

    containerOf(tester)
        .read(todayControllerProvider.notifier)
        .goTo(LocalDate(2026, 10, 10));
    await tester.pump();
    await tester.pump();

    expect(shownDate(tester), LocalDate(2026, 10, 10));
    expect(skeleton, findsWidgets);
    expect(find.text('Lunch'), findsNothing);

    await settle(tester);
    expect(skeleton, findsNothing);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
  });

  testWidgets('D3 the window holds 3 days and drops the others', (
    tester,
  ) async {
    final rig = TodayRig();
    await pumpRig(tester, rig);
    final container = containerOf(tester);
    bool alive(int daysBack) =>
        container.exists(dayViewProvider(testToday.plusDays(-daysBack)));

    // Today and yesterday (no day after today).
    expect(
      [for (var i = -1; i <= 3; i++) alive(i)],
      [false, true, true, false, false],
    );

    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    expect(
      [for (var i = -1; i <= 3; i++) alive(i)],
      [false, true, true, true, false],
    );

    await tester.tap(find.byTooltip('Previous day'));
    await settle(tester);
    expect(
      [for (var i = -1; i <= 4; i++) alive(i)],
      [false, false, true, true, true, false],
    );
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
    testWidgets('DY-001 HM-009 after midnight a viewer on today follows the '
        'new day', (tester) async {
      final clock = ManualClock(DateTime.utc(2026, 10, 17, 23, 59, 58));
      await pumpToday(tester, fakeToday(clock: clock, liveToday: true));
      expect(shownDate(tester), testToday);

      clock.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(shownDate(tester), LocalDate(2026, 10, 18));
      expect(find.text('Today'), findsOneWidget);
      expect(find.byType(DayPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DY-001 HM-009 after midnight a viewer on a past day stays '
        'on it', (tester) async {
      final clock = ManualClock(DateTime.utc(2026, 10, 17, 23, 59, 58));
      await pumpToday(tester, fakeToday(clock: clock, liveToday: true));
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();
      expect(find.text('Yesterday'), findsOneWidget);

      clock.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(shownDate(tester), testYesterday);
      expect(find.byType(DayPage), findsOneWidget);
      expect(find.text('Fri, Oct 16'), findsOneWidget);
      // › is enabled: two days lie between this one and today.
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(shownDate(tester), testToday);
      await tester.tap(find.byTooltip('Next day'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(shownDate(tester), LocalDate(2026, 10, 18));
      await tester.pumpWidget(const SizedBox());
    });

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

  testWidgets('the Today tab keeps the viewed day and shows data '
      'immediately when re-selected', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Today'),
      ),
    );
    await tester.pump();

    // The first frame back: the same day, no skeleton.
    expect(find.text('Yesterday'), findsOneWidget);
    expect(skeleton, findsNothing);
    expect(
      find.text(
        'Nothing logged on this day. Forgot something? Tap + on a meal.',
      ),
      findsOneWidget,
    );
  });
}
